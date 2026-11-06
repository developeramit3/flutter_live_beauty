import 'dart:async';
import '../beauty_video_source.dart';
import '../../models/beauty_video_frame.dart';

/// Adapter demonstrating zero-copy / buffer-based integration with the
/// LiveKit Flutter SDK (`livekit_client`).
///
/// ### LiveKit Integration Architecture
///
/// LiveKit Flutter SDK uses WebRTC under the hood. For custom video capture:
/// 1. Create a custom video track or hook into the native `LocalVideoTrack`.
/// 2. Supply beauty-processed frames directly into the track capturer.
///
/// ```dart
/// final liveKitAdapter = LiveKitBeautyVideoAdapter(
///   videoSource: controller.videoSource,
///   onFrameCaptured: (LiveKitCustomFrame frame) {
///     // customCapturer.captureFrame(
///     //   frame.buffer,
///     //   frame.width,
///     //   frame.height,
///     //   rotation: frame.rotation,
///     //   timestampUs: frame.timestampUs,
///     // );
///   },
/// );
/// await liveKitAdapter.start();
/// ```
class LiveKitBeautyVideoAdapter {
  LiveKitBeautyVideoAdapter({
    required this.videoSource,
    this.onFrameCaptured,
  });

  final BeautyVideoSource videoSource;
  final void Function(LiveKitCustomFrame frame)? onFrameCaptured;

  StreamSubscription<BeautyVideoFrame>? _subscription;
  bool _isRunning = false;
  int _capturedCount = 0;

  bool get isRunning => _isRunning;
  int get capturedCount => _capturedCount;

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

    final lkFrame = LiveKitCustomFrame(
      buffer: frame.bytes,
      width: frame.width,
      height: frame.height,
      rotation: frame.rotation,
      timestampUs: frame.timestampNs ~/ 1000,
      stride: frame.stride ?? (frame.width * 4),
      textureId: frame.textureId,
    );

    _capturedCount++;
    onFrameCaptured?.call(lkFrame);
  }
}

class LiveKitCustomFrame {
  const LiveKitCustomFrame({
    required this.buffer,
    required this.width,
    required this.height,
    required this.rotation,
    required this.timestampUs,
    required this.stride,
    this.textureId,
  });

  final dynamic buffer;
  final int width;
  final int height;
  final int rotation;
  final int timestampUs;
  final int stride;
  final int? textureId;
}
