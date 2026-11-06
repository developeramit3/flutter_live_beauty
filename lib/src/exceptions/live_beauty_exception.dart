/// Exception classes thrown by the flutter_live_beauty SDK.
library;

/// Base exception for flutter_live_beauty.
class LiveBeautyException implements Exception {
  const LiveBeautyException(this.message, {this.code, this.details});

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() {
    if (code != null) {
      return 'LiveBeautyException[$code]: $message';
    }
    return 'LiveBeautyException: $message';
  }
}

/// Thrown when camera operations fail (e.g. permission denied, camera disconnected).
class BeautyCameraException extends LiveBeautyException {
  const BeautyCameraException(super.message, {super.code, super.details});
}

/// Thrown when MediaPipe face landmarker initialization or inference fails.
class BeautyInferenceException extends LiveBeautyException {
  const BeautyInferenceException(super.message, {super.code, super.details});
}

/// Thrown when GPU shader compilation or rendering fails.
class BeautyRenderException extends LiveBeautyException {
  const BeautyRenderException(super.message, {super.code, super.details});
}

/// Thrown when streaming frame acquisition or adapter pipe encounters an error.
class BeautyStreamingException extends LiveBeautyException {
  const BeautyStreamingException(super.message, {super.code, super.details});
}
