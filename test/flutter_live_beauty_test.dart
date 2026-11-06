import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_live_beauty/flutter_live_beauty.dart';
import 'package:flutter_live_beauty/flutter_live_beauty_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLiveBeautyPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLiveBeautyPlatform {
  CameraInitResult lastInitResult = const CameraInitResult(
    textureId: 101,
    previewWidth: 1280,
    previewHeight: 720,
    cameraPosition: BeautyCameraPosition.front,
  );

  BeautyConfig? lastUpdatedConfig;
  BeautyCameraPosition currentPosition = BeautyCameraPosition.front;
  bool isDisposed = false;
  bool isStreaming = false;

  final StreamController<BeautyPerformanceStats> _statsController =
      StreamController<BeautyPerformanceStats>.broadcast();
  final StreamController<BeautyVideoFrame> _framesController =
      StreamController<BeautyVideoFrame>.broadcast();

  @override
  Future<String?> getPlatformVersion() => Future.value('Android 14 / iOS 17');

  @override
  Future<bool> hasCameraPermission() => Future.value(true);

  @override
  Future<bool> requestCameraPermission() => Future.value(true);

  @override
  Future<CameraInitResult> initializeCamera({
    required BeautyCameraPosition position,
    required BeautyResolution resolution,
    required BeautyConfig config,
  }) async {
    lastUpdatedConfig = config;
    currentPosition = position;
    return lastInitResult;
  }

  @override
  Future<void> disposeCamera() async {
    isDisposed = true;
  }

  @override
  Future<BeautyCameraPosition> switchCamera() async {
    currentPosition = currentPosition == BeautyCameraPosition.front
        ? BeautyCameraPosition.rear
        : BeautyCameraPosition.front;
    return currentPosition;
  }

  @override
  Future<void> setZoom(double zoom) async {}

  @override
  Future<void> setFlash(bool enable) async {}

  @override
  Future<void> updateBeautyConfig(BeautyConfig config) async {
    lastUpdatedConfig = config;
  }

  @override
  Future<void> setFeatureIntensity(BeautyFeature feature, int intensity) async {
    lastUpdatedConfig =
        (lastUpdatedConfig ?? const BeautyConfig()).withFeatureIntensity(feature, intensity);
  }

  @override
  Future<void> setBeautyEnabled(bool enabled) async {
    lastUpdatedConfig =
        (lastUpdatedConfig ?? const BeautyConfig()).copyWith(enabled: enabled);
  }

  @override
  Future<void> setFilter(BeautyFilter filter, int intensity) async {
    lastUpdatedConfig = (lastUpdatedConfig ?? const BeautyConfig()).copyWith(
      activeFilter: filter,
      filterIntensity: intensity,
    );
  }

  @override
  Future<void> setPerformanceProfile(BeautyPerformanceProfile profile) async {
    lastUpdatedConfig = (lastUpdatedConfig ?? const BeautyConfig()).copyWith(
      performanceProfile: profile,
    );
  }

  @override
  Future<void> startStreamingOutput({required BeautyPixelFormat format}) async {
    isStreaming = true;
  }

  @override
  Future<void> stopStreamingOutput() async {
    isStreaming = false;
  }

  @override
  Stream<BeautyPerformanceStats> get performanceStatsStream =>
      _statsController.stream;

  @override
  Stream<BeautyVideoFrame> get videoFramesStream =>
      _framesController.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFlutterLiveBeautyPlatform fakePlatform;

  setUp(() {
    fakePlatform = MockFlutterLiveBeautyPlatform();
    FlutterLiveBeautyPlatform.instance = fakePlatform;
  });

  test('$MethodChannelFlutterLiveBeauty is the default platform instance', () {
    expect(
      MethodChannelFlutterLiveBeauty(),
      isInstanceOf<FlutterLiveBeautyPlatform>(),
    );
  });

  test('FlutterLiveBeauty queries platform version', () async {
    expect(await FlutterLiveBeauty.getPlatformVersion(), 'Android 14 / iOS 17');
  });

  group('LiveBeautyController Lifecycle & Controls', () {
    test('initializes with default camera and resolution', () async {
      final controller = LiveBeautyController(platform: fakePlatform);
      expect(controller.isInitialized, isFalse);

      await controller.initialize(
        cameraPosition: BeautyCameraPosition.front,
        resolution: BeautyResolution.hd720p,
      );

      expect(controller.isInitialized, isTrue);
      expect(controller.textureId, 101);
      expect(controller.previewWidth, 1280);
      expect(controller.previewHeight, 720);
      expect(controller.cameraPosition, BeautyCameraPosition.front);
    });

    test('switches camera between front and rear', () async {
      final controller = LiveBeautyController(platform: fakePlatform);
      await controller.initialize();

      expect(controller.cameraPosition, BeautyCameraPosition.front);
      final newPos = await controller.switchCamera();
      expect(newPos, BeautyCameraPosition.rear);
      expect(controller.cameraPosition, BeautyCameraPosition.rear);
    });

    test('updates feature intensity with clamping', () async {
      final controller = LiveBeautyController(platform: fakePlatform);
      await controller.initialize();

      await controller.setBeauty(BeautyFeature.skinSmoothing, 75);
      expect(controller.config.getIntensity(BeautyFeature.skinSmoothing), 75);

      await controller.setBeauty(BeautyFeature.faceSlimming, 150);
      expect(controller.config.getIntensity(BeautyFeature.faceSlimming), 100);

      await controller.setBeauty(BeautyFeature.noseSlimming, -20);
      expect(controller.config.getIntensity(BeautyFeature.noseSlimming), 0);
    });

    test('applies built-in preset properly', () async {
      final controller = LiveBeautyController(platform: fakePlatform);
      await controller.initialize();

      await controller.applyPreset(BeautyPreset.glamour);
      expect(controller.config.activeFilter, BeautyFilter.glamour);
      expect(controller.config.getIntensity(BeautyFeature.skinSmoothing), 65);
      expect(controller.config.getIntensity(BeautyFeature.faceSlimming), 45);
      expect(controller.config.activePresetId, 'preset_glamour');
    });

    test('manages custom presets saving and loading', () async {
      final manager = PresetManager();
      final allInitial = manager.getAllPresets();
      expect(allInitial.length, 8); // 8 built-ins

      const customPreset = BeautyPreset(
        id: 'test_custom_1',
        name: 'My Custom Vibe',
        description: 'Warm natural look',
        config: BeautyConfig(
          featureIntensities: {BeautyFeature.skinSmoothing: 50},
        ),
      );

      final saved = await manager.saveCustomPreset(customPreset);
      expect(saved.isBuiltIn, isFalse);
      expect(manager.getPreset('test_custom_1')?.name, 'My Custom Vibe');

      final renamed = await manager.renameCustomPreset('test_custom_1', 'Updated Vibe');
      expect(renamed, isTrue);
      expect(manager.getPreset('test_custom_1')?.name, 'Updated Vibe');

      final deleted = await manager.deleteCustomPreset('test_custom_1');
      expect(deleted, isTrue);
      expect(manager.getPreset('test_custom_1'), isNull);
    });

    test('before/after comparison toggles beauty bypass', () async {
      final controller = LiveBeautyController(platform: fakePlatform);
      await controller.initialize();

      expect(controller.isBeforeAfterActive, isFalse);
      await controller.setBeforeAfterComparison(true);
      expect(controller.isBeforeAfterActive, isTrue);

      await controller.setBeforeAfterComparison(false);
      expect(controller.isBeforeAfterActive, isFalse);
    });

    test('streaming output lifecycle', () async {
      final controller = LiveBeautyController(platform: fakePlatform);
      await controller.initialize();

      expect(controller.videoSource.isStreaming, isFalse);
      await controller.startStreaming();
      expect(controller.videoSource.isStreaming, isTrue);
      expect(fakePlatform.isStreaming, isTrue);

      await controller.stopStreaming();
      expect(controller.videoSource.isStreaming, isFalse);
      expect(fakePlatform.isStreaming, isFalse);
    });

    test('properly disposes controller and camera', () async {
      final controller = LiveBeautyController(platform: fakePlatform);
      await controller.initialize();

      await controller.dispose();
      expect(controller.isDisposed, isTrue);
      expect(controller.isInitialized, isFalse);
      expect(fakePlatform.isDisposed, isTrue);
    });
  });
}
