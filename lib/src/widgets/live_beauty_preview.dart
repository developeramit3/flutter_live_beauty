import 'package:flutter/material.dart';
import '../controller/live_beauty_controller.dart';

/// Flutter widget that renders the hardware-accelerated beauty-processed camera feed.
///
/// Automatically listens to [LiveBeautyController], binds to the native GPU texture,
/// and applies correct aspect ratios and front-camera mirroring.
class LiveBeautyPreview extends StatelessWidget {
  const LiveBeautyPreview({
    super.key,
    required this.controller,
    this.fit = BoxFit.cover,
    this.loadingWidget,
    this.mirrorFrontCamera = true,
    this.overlay,
  });

  /// The active beauty controller driving the camera and GPU pipeline.
  final LiveBeautyController controller;

  /// How the camera preview texture should scale within its parent bounds.
  final BoxFit fit;

  /// Optional widget displayed while camera is initializing or texture is unavailable.
  final Widget? loadingWidget;

  /// Whether to horizontally flip (mirror) the preview when front camera is active.
  final bool mirrorFrontCamera;

  /// Optional overlay placed atop the camera preview (e.g. controls, guides).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isInitialized || controller.textureId == null) {
          return loadingWidget ??
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
        }

        final bool shouldMirror =
            mirrorFrontCamera && controller.cameraPosition.isFront;

        Widget previewWidget = Texture(
          textureId: controller.textureId!,
          filterQuality: FilterQuality.medium,
        );

        if (shouldMirror) {
          previewWidget = Transform.scale(
            scaleX: -1.0,
            alignment: Alignment.center,
            child: previewWidget,
          );
        }

        final ov = overlay;
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: FittedBox(
                    fit: fit,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: controller.previewWidth.toDouble(),
                      height: controller.previewHeight.toDouble(),
                      child: previewWidget,
                    ),
                  ),
                ),
                ?ov,
              ],
            );
          },
        );
      },
    );
  }
}
