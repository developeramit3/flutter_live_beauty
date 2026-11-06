import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_live_beauty/flutter_live_beauty.dart';
import 'package:flutter_live_beauty/flutter_live_beauty_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFlutterLiveBeauty();
  const channel = MethodChannel('com.livebeauty.sdk/methods');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'getPlatformVersion':
          return 'Android 14';
        case 'hasCameraPermission':
          return true;
        case 'requestCameraPermission':
          return true;
        case 'initializeCamera':
          return {
            'textureId': 42,
            'previewWidth': 1280,
            'previewHeight': 720,
          };
        case 'switchCamera':
          return 'rear';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion returns platform string', () async {
    expect(await platform.getPlatformVersion(), 'Android 14');
    expect(log.single.method, 'getPlatformVersion');
  });

  test('hasCameraPermission and requestCameraPermission check status', () async {
    expect(await platform.hasCameraPermission(), isTrue);
    expect(log.last.method, 'hasCameraPermission');

    expect(await platform.requestCameraPermission(), isTrue);
    expect(log.last.method, 'requestCameraPermission');
  });

  test('initializeCamera invokes method and parses result', () async {
    final result = await platform.initializeCamera(
      position: BeautyCameraPosition.front,
      resolution: BeautyResolution.hd720p,
      config: const BeautyConfig(),
    );

    expect(result.textureId, 42);
    expect(result.previewWidth, 1280);
    expect(result.previewHeight, 720);
    expect(result.cameraPosition, BeautyCameraPosition.front);
    expect(log.single.method, 'initializeCamera');
  });

  test('switchCamera switches to rear', () async {
    final pos = await platform.switchCamera();
    expect(pos, BeautyCameraPosition.rear);
    expect(log.single.method, 'switchCamera');
  });

  test('setFeatureIntensity and setBeautyEnabled pass correct arguments', () async {
    await platform.setFeatureIntensity(BeautyFeature.skinSmoothing, 85);
    expect(log.last.method, 'setFeatureIntensity');
    expect(log.last.arguments['feature'], 'skinSmoothing');
    expect(log.last.arguments['intensity'], 85);

    await platform.setBeautyEnabled(false);
    expect(log.last.method, 'setBeautyEnabled');
    expect(log.last.arguments['enabled'], false);
  });

  test('setFilter and performance profile invoke methods', () async {
    await platform.setFilter(BeautyFilter.glamour, 70);
    expect(log.last.method, 'setFilter');
    expect(log.last.arguments['filterId'], 'glamour');
    expect(log.last.arguments['intensity'], 70);

    await platform.setPerformanceProfile(BeautyPerformanceProfile.high);
    expect(log.last.method, 'setPerformanceProfile');
    expect(log.last.arguments['profile'], 'high');
  });

  test('streaming output start and stop', () async {
    await platform.startStreamingOutput(format: BeautyPixelFormat.rgba32);
    expect(log.last.method, 'startStreamingOutput');
    expect(log.last.arguments['format'], 'rgba32');

    await platform.stopStreamingOutput();
    expect(log.last.method, 'stopStreamingOutput');
  });
}
