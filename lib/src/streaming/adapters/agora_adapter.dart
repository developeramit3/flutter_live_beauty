import 'dart:async';
import '../beauty_video_source.dart';
import '../../models/beauty_video_frame.dart';

/// Adapter demonstrating zero-copy / buffer-based integration with the
/// Agora RTC Flutter SDK (`agora_rtc_engine`).
///
/// ### Agora Integration Architecture
///
/// In Agora RTC Flutter Engine (v6.x / v4.x), custom video capture is enabled by:
/// 1. Setting `setExternalVideoSource(enabled: true, useTexture: false, sourceType: VideoSourceType.videoSourceCamera)`.
/// 2. Invoking `pushExternalVideoFrame` on the MediaEngine with `ExternalVideoFrame`.
///
/// ```dart
/// // Example Setup:
/// final videoSource = controller.videoSource;
/// await videoSource.initialize();
/// await videoSource.start();
///
/// final agoraAdapter = AgoraBeautyVideoAdapter(
///   videoSource: videoSource,
///   onPushFrame: (AgoraFrame frame) {
///     // agoraEngine.getMediaEngine().pushExternalVideoFrame(
///     //   frame: ExternalVideoFrame(
///     //     type: VideoBufferType.videoBufferRawData,
///     //     format: VideoPixelFormat.videoPixelRgba,
///     //     buffer: frame.buffer,
///     //     stride: frame.stride,
///     //     height: frame.height,
///     //     rotation: frame.rotation,
///     //     timestamp: frame.timestampMs,
///     //   ),
///     // );
///   },
/// );
/// await agoraAdapter.start();
/// ```
class AgoraBeautyVideoAdapter {
  AgoraBeautyVideoAdapter({
    required this.videoSource,
    this.onPushFrame,
  });

  final BeautyVideoSource videoSource;

  /// Callback delivering converted frame data formatted for Agora `pushExternalVideoFrame`.
  final void Function(AgoraFrame frame)? onPushFrame;

  StreamSubscription<BeautyVideoFrame>? _subscription;
  bool _isRunning = false;
  int _pushedFramesCount = 0;

  bool get isRunning => _isRunning;
  int get pushedFramesCount => _pushedFramesCount;

  /// Starts listening to processed beauty frames and dispatching to Agora.
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    _subscription = videoSource.frames.listen(_handleBeautyFrame);
  }

  /// Stops streaming frames to Agora.
  Future<void> stop() async {
    _isRunning = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleBeautyFrame(BeautyVideoFrame frame) {
    if (!_isRunning) return;

    final agoraFrame = AgoraFrame(
      buffer: frame.bytes,
      stride: frame.stride ?? (frame.width * 4),
      height: frame.height,
      width: frame.width,
      rotation: frame.rotation,
      timestampMs: frame.timestampMs,
      textureId: frame.textureId,
      nativeBufferAddress: frame.nativeBufferAddress,
      format: _mapPixelFormat(frame.format),
    );

    _pushedFramesCount++;
    onPushFrame?.call(agoraFrame);
  }

  int _mapPixelFormat(BeautyPixelFormat format) {
    switch (format) {
      case BeautyPixelFormat.rgba32:
        return 4; // Agora VideoPixelFormat.videoPixelRgba
      case BeautyPixelFormat.bgra32:
        return 5; // Agora VideoPixelFormat.videoPixelBgra
      case BeautyPixelFormat.i420:
        return 1; // Agora VideoPixelFormat.videoPixelI420
      case BeautyPixelFormat.nv21:
        return 2; // Agora VideoPixelFormat.videoPixelNv21
      case BeautyPixelFormat.gpuTexture:
        return 8; // Agora Texture format
    }
  }
}

/// Normalized container representing an Agora-compatible external video frame.
class AgoraFrame {
  const AgoraFrame({
    required this.buffer,
    required this.stride,
    required this.height,
    required this.width,
    required this.rotation,
    required this.timestampMs,
    required this.format,
    this.textureId,
    this.nativeBufferAddress,
  });

  final dynamic buffer;
  final int stride;
  final int height;
  final int width;
  final int rotation;
  final int timestampMs;
  final int format;
  final int? textureId;
  final int? nativeBufferAddress;
}
