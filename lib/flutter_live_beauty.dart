/// Production-ready Flutter Live Beauty SDK for real-time facial enhancement,
/// face reshaping, makeup, color filters, and live-streaming frame output.
library;

import 'flutter_live_beauty_platform_interface.dart';

export 'flutter_live_beauty_platform_interface.dart'
    show CameraInitResult, FlutterLiveBeautyPlatform;
export 'src/camera/camera_controller.dart';
export 'src/config/beauty_config.dart';
export 'src/controller/live_beauty_controller.dart';
export 'src/exceptions/live_beauty_exception.dart';
export 'src/models/beauty_camera_position.dart';
export 'src/models/beauty_color.dart';
export 'src/models/beauty_feature.dart';
export 'src/models/beauty_filter.dart';
export 'src/models/beauty_performance_profile.dart';
export 'src/models/beauty_performance_stats.dart';
export 'src/models/beauty_resolution.dart';
export 'src/models/beauty_video_frame.dart';
export 'src/models/makeup_type.dart';
export 'src/presets/beauty_preset.dart';
export 'src/presets/preset_manager.dart';
export 'src/streaming/adapters/agora_adapter.dart';
export 'src/streaming/adapters/livekit_adapter.dart';
export 'src/streaming/adapters/webrtc_adapter.dart';
export 'src/streaming/adapters/zego_adapter.dart';
export 'src/streaming/beauty_video_source.dart';
export 'src/widgets/live_beauty_preview.dart';

/// Top-level entry point for flutter_live_beauty.
class FlutterLiveBeauty {
  const FlutterLiveBeauty._();

  /// SDK version.
  static const String version = '1.0.0';

  /// Queries the underlying platform OS version.
  static Future<String?> getPlatformVersion() {
    return FlutterLiveBeautyPlatform.instance.getPlatformVersion();
  }
}

