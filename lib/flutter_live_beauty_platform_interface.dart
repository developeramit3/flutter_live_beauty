import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_live_beauty_method_channel.dart';
import 'src/config/beauty_config.dart';
import 'src/models/beauty_camera_position.dart';
import 'src/models/beauty_feature.dart';
import 'src/models/beauty_filter.dart';
import 'src/models/beauty_performance_profile.dart';
import 'src/models/beauty_performance_stats.dart';
import 'src/models/beauty_resolution.dart';
import 'src/models/beauty_video_frame.dart';

/// Camera initialization response holding the Flutter texture ID and dimensions.
class CameraInitResult {
  const CameraInitResult({
    required this.textureId,
    required this.previewWidth,
    required this.previewHeight,
    required this.cameraPosition,
  });

  final int textureId;
  final int previewWidth;
  final int previewHeight;
  final BeautyCameraPosition cameraPosition;

  double get aspectRatio => previewHeight > 0 ? previewWidth / previewHeight : 9 / 16;
}

abstract class FlutterLiveBeautyPlatform extends PlatformInterface {
  FlutterLiveBeautyPlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterLiveBeautyPlatform _instance = MethodChannelFlutterLiveBeauty();

  static FlutterLiveBeautyPlatform get instance => _instance;

  static set instance(FlutterLiveBeautyPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> hasCameraPermission() {
    throw UnimplementedError('hasCameraPermission() has not been implemented.');
  }

  Future<bool> requestCameraPermission() {
    throw UnimplementedError('requestCameraPermission() has not been implemented.');
  }

  Future<CameraInitResult> initializeCamera({
    required BeautyCameraPosition position,
    required BeautyResolution resolution,
    required BeautyConfig config,
  }) {
    throw UnimplementedError('initializeCamera() has not been implemented.');
  }

  Future<void> disposeCamera() {
    throw UnimplementedError('disposeCamera() has not been implemented.');
  }

  Future<BeautyCameraPosition> switchCamera() {
    throw UnimplementedError('switchCamera() has not been implemented.');
  }

  Future<void> setZoom(double zoom) {
    throw UnimplementedError('setZoom() has not been implemented.');
  }

  Future<void> setFlash(bool enable) {
    throw UnimplementedError('setFlash() has not been implemented.');
  }

  Future<void> updateBeautyConfig(BeautyConfig config) {
    throw UnimplementedError('updateBeautyConfig() has not been implemented.');
  }

  Future<void> setFeatureIntensity(BeautyFeature feature, int intensity) {
    throw UnimplementedError('setFeatureIntensity() has not been implemented.');
  }

  Future<void> setBeautyEnabled(bool enabled) {
    throw UnimplementedError('setBeautyEnabled() has not been implemented.');
  }

  Future<void> setFilter(BeautyFilter filter, int intensity) {
    throw UnimplementedError('setFilter() has not been implemented.');
  }

  Future<void> setPerformanceProfile(BeautyPerformanceProfile profile) {
    throw UnimplementedError('setPerformanceProfile() has not been implemented.');
  }

  Future<void> startStreamingOutput({required BeautyPixelFormat format}) {
    throw UnimplementedError('startStreamingOutput() has not been implemented.');
  }

  Future<void> stopStreamingOutput() {
    throw UnimplementedError('stopStreamingOutput() has not been implemented.');
  }

  Stream<BeautyPerformanceStats> get performanceStatsStream {
    throw UnimplementedError('performanceStatsStream has not been implemented.');
  }

  Stream<BeautyVideoFrame> get videoFramesStream {
    throw UnimplementedError('videoFramesStream has not been implemented.');
  }
}
