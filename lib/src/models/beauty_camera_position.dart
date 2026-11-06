/// Hardware camera position.
enum BeautyCameraPosition {
  /// Front-facing selfie camera (mirrored by default).
  front,

  /// Rear-facing primary camera.
  rear;

  bool get isFront => this == BeautyCameraPosition.front;
  bool get isRear => this == BeautyCameraPosition.rear;
}
