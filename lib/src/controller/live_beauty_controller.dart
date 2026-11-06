import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../flutter_live_beauty_platform_interface.dart';
import '../config/beauty_config.dart';
import '../exceptions/live_beauty_exception.dart';
import '../models/beauty_camera_position.dart';
import '../models/beauty_color.dart';
import '../models/beauty_feature.dart';
import '../models/beauty_filter.dart';
import '../models/beauty_performance_profile.dart';
import '../models/beauty_performance_stats.dart';
import '../models/beauty_resolution.dart';
import '../models/beauty_video_frame.dart';
import '../models/makeup_type.dart';
import '../presets/beauty_preset.dart';
import '../presets/preset_manager.dart';
import '../streaming/beauty_video_source.dart';

/// Primary controller governing native camera capture, MediaPipe face processing,
/// GPU beauty rendering, and live-streaming frame output.
class LiveBeautyController extends ChangeNotifier {
  LiveBeautyController({
    BeautyConfig? initialConfig,
    PresetManager? presetManager,
    FlutterLiveBeautyPlatform? platform,
  })  : _config = initialConfig ?? const BeautyConfig(),
        _presetManager = presetManager ?? PresetManager(),
        _platform = platform ?? FlutterLiveBeautyPlatform.instance;

  final FlutterLiveBeautyPlatform _platform;
  final PresetManager _presetManager;

  BeautyConfig _config;
  BeautyConfig get config => _config;

  PresetManager get presetManager => _presetManager;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  int? _textureId;
  int? get textureId => _textureId;

  int _previewWidth = 1280;
  int get previewWidth => _previewWidth;

  int _previewHeight = 720;
  int get previewHeight => _previewHeight;

  double get aspectRatio => _previewHeight > 0 ? _previewWidth / _previewHeight : 9 / 16;

  BeautyCameraPosition _cameraPosition = BeautyCameraPosition.front;
  BeautyCameraPosition get cameraPosition => _cameraPosition;

  BeautyResolution _resolution = BeautyResolution.hd720p;
  BeautyResolution get resolution => _resolution;

  bool _isFlashEnabled = false;
  bool get isFlashEnabled => _isFlashEnabled;

  double _zoomLevel = 1.0;
  double get zoomLevel => _zoomLevel;

  bool _isBeforeAfterActive = false;
  bool get isBeforeAfterActive => _isBeforeAfterActive;

  BeautyPerformanceStats? _lastStats;
  BeautyPerformanceStats? get lastStats => _lastStats;

  StreamSubscription<BeautyPerformanceStats>? _statsSubscription;
  StreamSubscription<BeautyVideoFrame>? _nativeFramesSubscription;

  late final NativeBeautyVideoSource _videoSource = NativeBeautyVideoSource();
  BeautyVideoSource get videoSource => _videoSource;

  Stream<BeautyPerformanceStats> get performanceStatsStream =>
      _platform.performanceStatsStream;

  /// Checks if camera hardware permission is currently granted by the system.
  Future<bool> hasCameraPermission() async {
    return await _platform.hasCameraPermission();
  }

  /// Explicitly requests camera permission from the operating system.
  Future<bool> requestCameraPermission() async {
    return await _platform.requestCameraPermission();
  }

  /// Initializes the camera, MediaPipe landmark pipeline, and GPU shaders.
  /// Automatically requests camera permission if not already granted.
  Future<void> initialize({
    BeautyCameraPosition cameraPosition = BeautyCameraPosition.front,
    BeautyResolution resolution = BeautyResolution.hd720p,
    BeautyConfig? config,
    bool autoRequestPermission = true,
  }) async {
    if (_isInitialized) return;

    if (autoRequestPermission) {
      final hasPermission = await _platform.hasCameraPermission();
      if (!hasPermission) {
        final granted = await _platform.requestCameraPermission();
        if (!granted) {
          throw const BeautyCameraException(
            'Camera permission was denied. Please grant camera permission in system settings.',
            code: 'PERMISSION_DENIED',
          );
        }
      }
    }

    if (config != null) {
      _config = config;
    }
    _cameraPosition = cameraPosition;
    _resolution = resolution;

    try {
      final result = await _platform.initializeCamera(
        position: _cameraPosition,
        resolution: _resolution,
        config: _config,
      );

      _textureId = result.textureId;
      _previewWidth = result.previewWidth;
      _previewHeight = result.previewHeight;
      _cameraPosition = result.cameraPosition;
      _isInitialized = true;

      // Subscribe to real-time performance telemetry
      _statsSubscription = _platform.performanceStatsStream.listen(
        (stats) {
          _lastStats = stats;
          notifyListeners();
        },
        onError: (_) {},
      );

      // Connect native frames stream to BeautyVideoSource
      _nativeFramesSubscription = _platform.videoFramesStream.listen(
        (frame) {
          _videoSource.dispatchFrame(frame);
        },
        onError: (_) {},
      );

      await _presetManager.loadCustomPresets();
      notifyListeners();
    } catch (e) {
      _isInitialized = false;
      if (e is LiveBeautyException) rethrow;
      throw BeautyCameraException('Failed to initialize beauty controller: $e');
    }
  }

  /// Sets intensity for an individual beauty, face reshaping, or makeup feature (0 - 100).
  Future<void> setBeauty(BeautyFeature feature, int intensity) async {
    final clamped = intensity.clamp(0, 100);
    _config = _config.withFeatureIntensity(feature, clamped);
    notifyListeners();

    if (_isInitialized && !_isBeforeAfterActive) {
      await _platform.setFeatureIntensity(feature, clamped);
    }
  }

  /// Master switch to enable or disable all beauty effects.
  Future<void> setBeautyEnabled(bool enabled) async {
    _config = _config.copyWith(enabled: enabled);
    notifyListeners();

    if (_isInitialized) {
      await _platform.setBeautyEnabled(enabled && !_isBeforeAfterActive);
    }
  }

  /// Toggle temporary before/after comparison preview.
  /// When true, all beauty processing is bypassed to reveal the raw camera frame.
  Future<void> setBeforeAfterComparison(bool active) async {
    if (_isBeforeAfterActive == active) return;
    _isBeforeAfterActive = active;
    notifyListeners();

    if (_isInitialized) {
      // If comparing (active=true), temporarily disable GPU beauty passes
      await _platform.setBeautyEnabled(!active && _config.enabled);
    }
  }

  /// Sets an active color filter with an adjustable intensity (0 - 100).
  Future<void> setFilter(BeautyFilter filter, [int intensity = 80]) async {
    final clamped = intensity.clamp(0, 100);
    _config = _config.copyWith(
      activeFilter: filter,
      filterIntensity: clamped,
    );
    notifyListeners();

    if (_isInitialized) {
      await _platform.setFilter(filter, clamped);
    }
  }

  /// Sets the color of a specific makeup element (e.g. lipstick, blush, eyeshadow).
  Future<void> setMakeupColor(MakeupType type, BeautyColor color) async {
    _config = _config.withMakeupColor(type, color);
    notifyListeners();

    if (_isInitialized) {
      await _platform.updateBeautyConfig(_config);
    }
  }

  /// Applies a full beauty preset (built-in or custom).
  Future<void> applyPreset(BeautyPreset preset) async {
    _config = preset.config.copyWith(
      activePresetId: preset.id,
      performanceProfile: _config.performanceProfile,
      maxFaces: _config.maxFaces,
    );
    notifyListeners();

    if (_isInitialized) {
      await _platform.updateBeautyConfig(_config);
    }
  }

  /// Switches between front and rear cameras dynamically without tearing down the preview texture.
  Future<BeautyCameraPosition> switchCamera() async {
    if (!_isInitialized) return _cameraPosition;
    final newPos = await _platform.switchCamera();
    _cameraPosition = newPos;
    notifyListeners();
    return newPos;
  }

  /// Adjusts camera hardware digital/optical zoom factor (>= 1.0).
  Future<void> setZoom(double zoom) async {
    if (!_isInitialized) return;
    _zoomLevel = zoom.clamp(1.0, 10.0);
    await _platform.setZoom(_zoomLevel);
    notifyListeners();
  }

  /// Toggles camera flash torch mode (rear camera only).
  Future<void> setFlash(bool enable) async {
    if (!_isInitialized) return;
    _isFlashEnabled = enable;
    await _platform.setFlash(enable);
    notifyListeners();
  }

  /// Adjusts the active performance profile (low, balanced, high).
  Future<void> setPerformanceProfile(BeautyPerformanceProfile profile) async {
    _config = _config.copyWith(performanceProfile: profile);
    notifyListeners();

    if (_isInitialized) {
      await _platform.setPerformanceProfile(profile);
    }
  }

  /// Starts streaming beauty-processed video frames to [videoSource.frames].
  Future<void> startStreaming({BeautyPixelFormat format = BeautyPixelFormat.rgba32}) async {
    if (!_isInitialized) {
      throw const BeautyStreamingException('Cannot start streaming before initialization');
    }
    await _videoSource.start();
    await _platform.startStreamingOutput(format: format);
  }

  /// Halts streaming output.
  Future<void> stopStreaming() async {
    if (!_isInitialized) return;
    await _platform.stopStreamingOutput();
    await _videoSource.stop();
  }

  /// Resets all beauty features to 0 and filter to Original.
  Future<void> resetAll() async {
    _config = BeautyConfig.zero();
    notifyListeners();

    if (_isInitialized) {
      await _platform.updateBeautyConfig(_config);
    }
  }

  /// Saves the current configuration as a new persistent custom preset.
  Future<BeautyPreset> saveAsPreset(String name, {String description = ''}) async {
    final newPreset = BeautyPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      config: _config,
      isBuiltIn: false,
    );
    final saved = await _presetManager.saveCustomPreset(newPreset);
    _config = _config.copyWith(activePresetId: saved.id);
    notifyListeners();
    return saved;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    await _statsSubscription?.cancel();
    await _nativeFramesSubscription?.cancel();
    await _videoSource.dispose();

    if (_isInitialized) {
      await _platform.disposeCamera();
      _isInitialized = false;
    }
    super.dispose();
  }
}
