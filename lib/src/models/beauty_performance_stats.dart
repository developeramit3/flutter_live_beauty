/// Real-time runtime performance statistics reported by the native GPU engine.
class BeautyPerformanceStats {
  const BeautyPerformanceStats({
    required this.renderFps,
    required this.inferenceFps,
    required this.renderLatencyMs,
    required this.inferenceLatencyMs,
    required this.droppedFrames,
    required this.detectedFacesCount,
    required this.frameWidth,
    required this.frameHeight,
  });

  /// Current rendering frame rate dispatched to preview and streaming output.
  final double renderFps;

  /// MediaPipe Face Landmarker inference frame rate.
  final double inferenceFps;

  /// Time spent in native GPU shader passes for the most recent frame (in milliseconds).
  final double renderLatencyMs;

  /// Time taken by MediaPipe ML face landmark inference (in milliseconds).
  final double inferenceLatencyMs;

  /// Total count of frames dropped by the anti-queue stalling mechanism.
  final int droppedFrames;

  /// Number of currently tracked faces in the active frame.
  final int detectedFacesCount;

  /// Rendered frame width in pixels.
  final int frameWidth;

  /// Rendered frame height in pixels.
  final int frameHeight;

  /// Total end-to-end processing latency.
  double get totalLatencyMs => renderLatencyMs + inferenceLatencyMs;

  factory BeautyPerformanceStats.fromMap(Map<String, dynamic> map) {
    return BeautyPerformanceStats(
      renderFps: (map['renderFps'] as num?)?.toDouble() ?? 0.0,
      inferenceFps: (map['inferenceFps'] as num?)?.toDouble() ?? 0.0,
      renderLatencyMs: (map['renderLatencyMs'] as num?)?.toDouble() ?? 0.0,
      inferenceLatencyMs:
          (map['inferenceLatencyMs'] as num?)?.toDouble() ?? 0.0,
      droppedFrames: (map['droppedFrames'] as num?)?.toInt() ?? 0,
      detectedFacesCount: (map['detectedFacesCount'] as num?)?.toInt() ?? 0,
      frameWidth: (map['frameWidth'] as num?)?.toInt() ?? 0,
      frameHeight: (map['frameHeight'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'renderFps': renderFps,
        'inferenceFps': inferenceFps,
        'renderLatencyMs': renderLatencyMs,
        'inferenceLatencyMs': inferenceLatencyMs,
        'droppedFrames': droppedFrames,
        'detectedFacesCount': detectedFacesCount,
        'frameWidth': frameWidth,
        'frameHeight': frameHeight,
      };

  @override
  String toString() {
    return 'BeautyPerformanceStats(renderFps: ${renderFps.toStringAsFixed(1)}, '
        'renderLatency: ${renderLatencyMs.toStringAsFixed(1)}ms, '
        'inferenceLatency: ${inferenceLatencyMs.toStringAsFixed(1)}ms, '
        'faces: $detectedFacesCount, dropped: $droppedFrames)';
  }
}
