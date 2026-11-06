/// Adaptive performance profiles to balance GPU/thermal load across device tiers.
enum BeautyPerformanceProfile {
  /// Optimized for budget / thermal-constrained devices:
  /// - Face landmark inference at 15-20 FPS.
  /// - 1-pass fast bilateral filter.
  /// - Target 30 FPS rendering at 720p.
  low(
    maxFaces: 1,
    targetFps: 30,
    inferenceIntervalFrames: 2,
    enableTemporalSmoothing: true,
    enableMultiPassBlur: false,
    preferredResolution: 720,
  ),

  /// Recommended standard profile for modern mid-tier & flagship phones:
  /// - Face landmark inference at 30 FPS.
  /// - 2-pass guided bilateral filter + full mesh deformation.
  /// - Target 30-60 FPS at 720p/1080p.
  balanced(
    maxFaces: 2,
    targetFps: 60,
    inferenceIntervalFrames: 1,
    enableTemporalSmoothing: true,
    enableMultiPassBlur: true,
    preferredResolution: 1080,
  ),

  /// Unconstrained high-fidelity studio profile:
  /// - Full 60 FPS face inference & iris tracking.
  /// - Multi-pass anisotropic blur + 3D mesh warp + multi-face tracking.
  /// - Target 60 FPS at 1080p.
  high(
    maxFaces: 4,
    targetFps: 60,
    inferenceIntervalFrames: 1,
    enableTemporalSmoothing: true,
    enableMultiPassBlur: true,
    preferredResolution: 1080,
  );

  const BeautyPerformanceProfile({
    required this.maxFaces,
    required this.targetFps,
    required this.inferenceIntervalFrames,
    required this.enableTemporalSmoothing,
    required this.enableMultiPassBlur,
    required this.preferredResolution,
  });

  final int maxFaces;
  final int targetFps;
  final int inferenceIntervalFrames;
  final bool enableTemporalSmoothing;
  final bool enableMultiPassBlur;
  final int preferredResolution;
}
