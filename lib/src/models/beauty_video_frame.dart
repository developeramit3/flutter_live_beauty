import 'dart:typed_data';

/// Pixel format of the processed video frame.
enum BeautyPixelFormat {
  /// 32-bit packed RGBA (8-bits per component).
  rgba32,

  /// 32-bit packed BGRA (iOS Metal native default).
  bgra32,

  /// Planar YUV 4:2:0 (Y, U, V planes separate).
  i420,

  /// Semi-planar YUV 4:2:0 (Y plane followed by interleaved UV).
  nv21,

  /// Native GPU texture handle (OpenGL ES 2D texture or Metal MTLTexture pointer).
  gpuTexture,
}

/// Represents a single beauty-processed video frame ready for streaming dispatch.
class BeautyVideoFrame {
  const BeautyVideoFrame({
    required this.width,
    required this.height,
    required this.rotation,
    required this.timestampNs,
    required this.format,
    this.bytes,
    this.nativeBufferAddress,
    this.textureId,
    this.stride,
  });

  /// Frame width in pixels.
  final int width;

  /// Frame height in pixels.
  final int height;

  /// Clockwise rotation in degrees (0, 90, 180, 270).
  final int rotation;

  /// Monotonic timestamp in nanoseconds.
  final int timestampNs;

  /// Color format of the frame.
  final BeautyPixelFormat format;

  /// Raw byte payload for CPU buffers (null if zero-copy GPU texture).
  final Uint8List? bytes;

  /// 64-bit native memory address (`uintptr_t`) pointing to direct ByteBuffer,
  /// `AHardwareBuffer`, or `CVPixelBufferRef`.
  final int? nativeBufferAddress;

  /// Native OpenGL ES texture id or Metal texture identifier.
  final int? textureId;

  /// Row stride in bytes (width * 4 for RGBA with no padding).
  final int? stride;

  /// Frame timestamp in milliseconds.
  int get timestampMs => timestampNs ~/ 1000000;

  /// Returns true if this frame resides on the GPU with minimal memory overhead.
  bool get isGpuFrame => textureId != null || (format == BeautyPixelFormat.gpuTexture);

  factory BeautyVideoFrame.fromMap(Map<String, dynamic> map, [Uint8List? rawBytes]) {
    return BeautyVideoFrame(
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      rotation: (map['rotation'] as num?)?.toInt() ?? 0,
      timestampNs: (map['timestampNs'] as num?)?.toInt() ??
          DateTime.now().microsecondsSinceEpoch * 1000,
      format: BeautyPixelFormat.values.firstWhere(
        (f) => f.name == map['format'],
        orElse: () => BeautyPixelFormat.rgba32,
      ),
      bytes: rawBytes ?? map['bytes'] as Uint8List?,
      nativeBufferAddress: (map['nativeBufferAddress'] as num?)?.toInt(),
      textureId: (map['textureId'] as num?)?.toInt(),
      stride: (map['stride'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'width': width,
        'height': height,
        'rotation': rotation,
        'timestampNs': timestampNs,
        'format': format.name,
        'nativeBufferAddress': nativeBufferAddress,
        'textureId': textureId,
        'stride': stride,
      };

  @override
  String toString() {
    return 'BeautyVideoFrame(${width}x$height, rot: $rotation, fmt: ${format.name}, '
        'ts: ${timestampMs}ms, hasGpu: $isGpuFrame)';
  }
}
