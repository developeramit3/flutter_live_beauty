import 'dart:async';
import '../beauty_video_source.dart';
import '../../models/beauty_video_frame.dart';

/// Adapter demonstrating zero-copy / buffer-based integration with the
/// Flutter WebRTC package (`flutter_webrtc`).
///
/// ### WebRTC Integration Architecture
///
/// With `flutter_webrtc` or standard WebRTC C++ bindings:
/// 1. Initialize a custom `RTCVideoSource` capturer.
/// 2. Inject beauty frames through `RTCVideoCapturer` or custom native frame observer.
///
/// ```dart
/// final webrtcAdapter = WebRtcBeautyVideoAdapter(
///   videoSource: controller.videoSource,
///   onPushWebRtcFrame: (WebRtcBeautyFrame frame) {
///     // customSource.capturer.captureByteFrame(
///     //   frame.data,
///     //   frame.width,
///     //   frame.height,
///     //   frame.rotation,
///     //   frame.timestampUs,
///     // );
///   },
/// );
/// await webrtcAdapter.start();
/// ```
class WebRtcBeautyVideoAdapter {
  WebRtcBeautyVideoAdapter({
    required this.videoSource,
    this.onPushWebRtcFrame,
  });

  final BeautyVideoSource videoSource;
  final void Function(WebRtcBeautyFrame frame)? onPushWebRtcFrame;

  StreamSubscription<BeautyVideoFrame>? _subscription;
  bool _isRunning = false;
  int _pushedCount = 0;

  bool get isRunning => _isRunning;
  int get pushedCount => _pushedCount;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    _subscription = videoSource.frames.listen(_handleBeautyFrame);
  }

  Future<void> stop() async {
    _isRunning = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleBeautyFrame(BeautyVideoFrame frame) {
    if (!_isRunning) return;

    final rtcFrame = WebRtcBeautyFrame(
      data: frame.bytes,
      width: frame.width,
      height: frame.height,
      rotation: frame.rotation,
      timestampUs: frame.timestampNs ~/ 1000,
      stride: frame.stride ?? (frame.width * 4),
      textureId: frame.textureId,
    );

    _pushedCount++;
    onPushWebRtcFrame?.call(rtcFrame);
  }
}

class WebRtcBeautyFrame {
  const WebRtcBeautyFrame({
    required this.data,
    required this.width,
    required this.height,
    required this.rotation,
    required this.timestampUs,
    required this.stride,
    this.textureId,
  });

  final dynamic data;
  final int width;
  final int height;
  final int rotation;
  final int timestampUs;
  final int stride;
  final int? textureId;
}
