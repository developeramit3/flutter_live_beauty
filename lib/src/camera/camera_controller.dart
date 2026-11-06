import '../models/beauty_camera_position.dart';
import '../models/beauty_resolution.dart';

/// Low-level camera configuration options.
class CameraOptions {
  const CameraOptions({
    this.position = BeautyCameraPosition.front,
    this.resolution = BeautyResolution.hd720p,
    this.fps = 30,
    this.enableAutoFocus = true,
  });

  final BeautyCameraPosition position;
  final BeautyResolution resolution;
  final int fps;
  final bool enableAutoFocus;
}
