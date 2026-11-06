import 'dart:async';
import '../models/beauty_video_frame.dart';

/// Provider-independent streaming video source interface.
/// Exposes real-time beauty-processed camera frames to downstream streaming SDKs
/// (such as Agora, ZegoCloud, LiveKit, WebRTC).
abstract class BeautyVideoSource {
  /// Prepares internal frame buffers, pixel format converters, and native streams.
  Future<void> initialize();

  /// Starts frame capture and begins streaming beauty-processed frames to [frames].
  Future<void> start();

  /// Temporarily halts frame generation without releasing GPU resources.
  Future<void> stop();

  /// Completely releases native buffers, textures, and stream subscriptions.
  Future<void> dispose();

  /// Stream of processed video frames arriving at the camera render rate (e.g. 30/60 FPS).
  Stream<BeautyVideoFrame> get frames;

  /// Returns true if the video source is actively emitting frames.
  bool get isStreaming;

  /// Output pixel format desired by the downstream video encoder/streaming adapter.
  BeautyPixelFormat get targetPixelFormat;
}

/// Default implementation of [BeautyVideoSource] that receives native frames
/// from the platform channel or direct FFI hook.
class NativeBeautyVideoSource implements BeautyVideoSource {
  NativeBeautyVideoSource({
    this.targetPixelFormat = BeautyPixelFormat.rgba32,
  });

  @override
  final BeautyPixelFormat targetPixelFormat;

  final StreamController<BeautyVideoFrame> _frameController =
      StreamController<BeautyVideoFrame>.broadcast();

  bool _isStreaming = false;
  bool _isDisposed = false;

  @override
  Stream<BeautyVideoFrame> get frames => _frameController.stream;

  @override
  bool get isStreaming => _isStreaming;

  @override
  Future<void> initialize() async {
    _isDisposed = false;
  }

  @override
  Future<void> start() async {
    if (_isDisposed) return;
    _isStreaming = true;
  }

  @override
  Future<void> stop() async {
    _isStreaming = false;
  }

  @override
  Future<void> dispose() async {
    _isStreaming = false;
    _isDisposed = true;
    await _frameController.close();
  }

  /// Internal hook called by the native frame pipeline when a new beauty frame is ready.
  void dispatchFrame(BeautyVideoFrame frame) {
    if (!_isStreaming || _isDisposed) return;
    if (!_frameController.isClosed) {
      _frameController.add(frame);
    }
  }
}
