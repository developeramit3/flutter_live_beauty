/// Supported camera and render pipeline resolutions.
enum BeautyResolution {
  /// 640x480 standard definition (low bandwidth/legacy devices).
  sd480p(width: 640, height: 480),

  /// 1280x720 high definition (recommended standard live-streaming default).
  hd720p(width: 1280, height: 720),

  /// 1920x1080 full high definition.
  fhd1080p(width: 1920, height: 1080),

  /// 3840x2160 ultra high definition.
  uhd4k(width: 3840, height: 2160);

  const BeautyResolution({required this.width, required this.height});

  final int width;
  final int height;

  /// Aspect ratio width / height (typically 16:9 for 720p/1080p).
  double get aspectRatio => width / height;

  /// Shorthand aliases
  static const BeautyResolution low = BeautyResolution.sd480p;
  static const BeautyResolution medium = BeautyResolution.hd720p;
  static const BeautyResolution high = BeautyResolution.fhd1080p;
}
