import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_live_beauty_platform_interface.dart';
import 'src/config/beauty_config.dart';
import 'src/exceptions/live_beauty_exception.dart';
import 'src/models/beauty_camera_position.dart';
import 'src/models/beauty_feature.dart';
import 'src/models/beauty_filter.dart';
import 'src/models/beauty_performance_profile.dart';
import 'src/models/beauty_performance_stats.dart';
import 'src/models/beauty_resolution.dart';
import 'src/models/beauty_video_frame.dart';

/// Platform implementation using Flutter [MethodChannel] and [EventChannel].
class MethodChannelFlutterLiveBeauty extends FlutterLiveBeautyPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('com.livebeauty.sdk/methods');

  @visibleForTesting
  final statsChannel = const EventChannel('com.livebeauty.sdk/stats');

  @visibleForTesting
  final framesChannel = const EventChannel('com.livebeauty.sdk/frames');

  Stream<BeautyPerformanceStats>? _cachedStatsStream;
  Stream<BeautyVideoFrame>? _cachedFramesStream;

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      final res = await methodChannel.invokeMethod<bool>('hasCameraPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final res =
          await methodChannel.invokeMethod<bool>('requestCameraPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CameraInitResult> initializeCamera({
    required BeautyCameraPosition position,
    required BeautyResolution resolution,
    required BeautyConfig config,
  }) async {
    try {
      final res = await methodChannel.invokeMapMethod<String, dynamic>(
        'initializeCamera',
        {
          'position': position.name,
          'width': resolution.width,
          'height': resolution.height,
          'config': config.toMap(),
        },
      );

      if (res == null) {
        throw const BeautyCameraException('Failed to initialize camera: null response');
      }

      return CameraInitResult(
        textureId: (res['textureId'] as num).toInt(),
        previewWidth: (res['previewWidth'] as num).toInt(),
        previewHeight: (res['previewHeight'] as num).toInt(),
        cameraPosition: position,
      );
    } on PlatformException catch (e) {
      throw BeautyCameraException(e.message ?? 'Camera initialization failed', code: e.code);
    }
  }

  @override
  Future<void> disposeCamera() async {
    try {
      await methodChannel.invokeMethod<void>('disposeCamera');
    } on PlatformException catch (e) {
      throw BeautyCameraException(e.message ?? 'Camera disposal failed', code: e.code);
    }
  }

  @override
  Future<BeautyCameraPosition> switchCamera() async {
    try {
      final res = await methodChannel.invokeMethod<String>('switchCamera');
      return res == 'rear' ? BeautyCameraPosition.rear : BeautyCameraPosition.front;
    } on PlatformException catch (e) {
      throw BeautyCameraException(e.message ?? 'Failed to switch camera', code: e.code);
    }
  }

  @override
  Future<void> setZoom(double zoom) async {
    try {
      await methodChannel.invokeMethod<void>('setZoom', {'zoom': zoom});
    } on PlatformException catch (e) {
      throw BeautyCameraException(e.message ?? 'Failed to set zoom', code: e.code);
    }
  }

  @override
  Future<void> setFlash(bool enable) async {
    try {
      await methodChannel.invokeMethod<void>('setFlash', {'enable': enable});
    } on PlatformException catch (e) {
      throw BeautyCameraException(e.message ?? 'Failed to set flash', code: e.code);
    }
  }

  @override
  Future<void> updateBeautyConfig(BeautyConfig config) async {
    try {
      await methodChannel.invokeMethod<void>('updateBeautyConfig', config.toMap());
    } on PlatformException catch (e) {
      throw BeautyRenderException(e.message ?? 'Failed to update beauty config', code: e.code);
    }
  }

  @override
  Future<void> setFeatureIntensity(BeautyFeature feature, int intensity) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setFeatureIntensity',
        {
          'feature': feature.name,
          'intensity': intensity.clamp(0, 100),
        },
      );
    } on PlatformException catch (e) {
      throw BeautyRenderException(e.message ?? 'Failed to set feature intensity', code: e.code);
    }
  }

  @override
  Future<void> setBeautyEnabled(bool enabled) async {
    try {
      await methodChannel.invokeMethod<void>('setBeautyEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      throw BeautyRenderException(e.message ?? 'Failed to toggle beauty', code: e.code);
    }
  }

  @override
  Future<void> setFilter(BeautyFilter filter, int intensity) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setFilter',
        {
          'filterId': filter.id,
          'intensity': intensity.clamp(0, 100),
        },
      );
    } on PlatformException catch (e) {
      throw BeautyRenderException(e.message ?? 'Failed to set filter', code: e.code);
    }
  }

  @override
  Future<void> setPerformanceProfile(BeautyPerformanceProfile profile) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setPerformanceProfile',
        {'profile': profile.name},
      );
    } on PlatformException catch (e) {
      throw BeautyRenderException(e.message ?? 'Failed to set profile', code: e.code);
    }
  }

  @override
  Future<void> startStreamingOutput({required BeautyPixelFormat format}) async {
    try {
      await methodChannel.invokeMethod<void>(
        'startStreamingOutput',
        {'format': format.name},
      );
    } on PlatformException catch (e) {
      throw BeautyStreamingException(e.message ?? 'Failed to start streaming', code: e.code);
    }
  }

  @override
  Future<void> stopStreamingOutput() async {
    try {
      await methodChannel.invokeMethod<void>('stopStreamingOutput');
    } on PlatformException catch (e) {
      throw BeautyStreamingException(e.message ?? 'Failed to stop streaming', code: e.code);
    }
  }

  @override
  Stream<BeautyPerformanceStats> get performanceStatsStream {
    _cachedStatsStream ??= statsChannel
        .receiveBroadcastStream()
        .map((event) => BeautyPerformanceStats.fromMap(
            Map<String, dynamic>.from(event as Map? ?? {})));
    return _cachedStatsStream!;
  }

  @override
  Stream<BeautyVideoFrame> get videoFramesStream {
    _cachedFramesStream ??= framesChannel
        .receiveBroadcastStream()
        .map((event) => BeautyVideoFrame.fromMap(
            Map<String, dynamic>.from(event as Map? ?? {})));
    return _cachedFramesStream!;
  }
}
