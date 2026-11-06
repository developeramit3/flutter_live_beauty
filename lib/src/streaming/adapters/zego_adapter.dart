import 'dart:async';
import '../beauty_video_source.dart';
import '../../models/beauty_video_frame.dart';

/// Adapter demonstrating zero-copy / buffer-based integration with the
/// ZegoCloud Express Video SDK (`zego_express_engine`).
///
/// ### ZegoCloud Integration Architecture
///
/// In Zego Express Engine:
/// 1. Configure custom video capture before preview/publishing:
///    `ZegoCustomVideoCaptureConfig config = ZegoCustomVideoCaptureConfig(ZegoVideoBufferType.RawData);`
///    `ZegoExpressEngine.instance.enableCustomVideoCapture(true, config: config);`
/// 2. In frame loop, forward raw data or GPU texture:
///    `ZegoExpressEngine.instance.sendCustomVideoCaptureRawData(frame.data, frame.length, frame.param, frame.timestampMs);`
///
/// ```dart
/// final zegoAdapter = ZegoBeautyVideoAdapter(
///   videoSource: controller.videoSource,
///   onSendRawFrame: (ZegoRawFrame frame) {
///     // ZegoExpressEngine.instance.sendCustomVideoCaptureRawData(
///     //   frame.data,
///     //   frame.length,
///     //   frame.param,
///     //   frame.timestampMs,
///     // );
///   },
/// );
/// await zegoAdapter.start();
/// ```
class ZegoBeautyVideoAdapter {
  ZegoBeautyVideoAdapter({
    required this.videoSource,
    this.onSendRawFrame,
    this.onSendTextureFrame,
  });

  final BeautyVideoSource videoSource;
  final void Function(ZegoRawFrame frame)? onSendRawFrame;
  final void Function(ZegoTextureFrame frame)? onSendTextureFrame;

  StreamSubscription<BeautyVideoFrame>? _subscription;
  bool _isRunning = false;
  int _sentFramesCount = 0;

  bool get isRunning => _isRunning;
  int get sentFramesCount => _sentFramesCount;

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

    if (frame.isGpuFrame && frame.textureId != null && onSendTextureFrame != null) {
      onSendTextureFrame?.call(
        ZegoTextureFrame(
          textureId: frame.textureId!,
          width: frame.width,
          height: frame.height,
          timestampMs: frame.timestampMs,
        ),
      );
    } else if (frame.bytes != null && onSendRawFrame != null) {
      onSendRawFrame?.call(
        ZegoRawFrame(
          data: frame.bytes!,
          length: frame.bytes!.lengthInBytes,
          width: frame.width,
          height: frame.height,
          rotation: frame.rotation,
          timestampMs: frame.timestampMs,
          pixelFormat: _mapZegoPixelFormat(frame.format),
        ),
      );
    }
    _sentFramesCount++;
  }

  int _mapZegoPixelFormat(BeautyPixelFormat format) {
    switch (format) {
      case BeautyPixelFormat.rgba32:
        return 3; // ZegoVideoFrameFormat.RGBA32
      case BeautyPixelFormat.bgra32:
        return 4; // ZegoVideoFrameFormat.BGRA32
      case BeautyPixelFormat.i420:
        return 1; // ZegoVideoFrameFormat.I420
      case BeautyPixelFormat.nv21:
        return 2; // ZegoVideoFrameFormat.NV21
      case BeautyPixelFormat.gpuTexture:
        return 0; // Unknown/Texture
    }
  }
}

class ZegoRawFrame {
  const ZegoRawFrame({
    required this.data,
    required this.length,
    required this.width,
    required this.height,
    required this.rotation,
    required this.timestampMs,
    required this.pixelFormat,
  });

  final List<int> data;
  final int length;
  final int width;
  final int height;
  final int rotation;
  final int timestampMs;
  final int pixelFormat;
}

class ZegoTextureFrame {
  const ZegoTextureFrame({
    required this.textureId,
    required this.width,
    required this.height,
    required this.timestampMs,
  });

  final int textureId;
  final int width;
  final int height;
  final int timestampMs;
}
