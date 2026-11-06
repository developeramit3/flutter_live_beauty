/// Enumerates all real-time facial beauty enhancement features.
/// Each feature accepts an intensity level clamped between 0 and 100.
enum BeautyFeature {
  // --- Skin Beauty Enhancement ---
  /// Bilateral high-pass skin smoothing.
  skinSmoothing(category: BeautyCategory.skin, label: 'Skin Smoothing'),

  /// Skin tone whitening and luminance boost.
  skinWhitening(category: BeautyCategory.skin, label: 'Skin Whitening'),

  /// Skin highlight glow and radiance.
  skinGlow(category: BeautyCategory.skin, label: 'Skin Glow'),

  /// Warm/cool skin tone balance (0=Cool, 50=Neutral, 100=Warm).
  skinTone(category: BeautyCategory.skin, label: 'Skin Tone'),

  /// Spot and blemish attenuation via local frequency suppression.
  blemishReduction(category: BeautyCategory.skin, label: 'Blemish Reduction'),

  /// Fine wrinkle reduction around forehead and mouth.
  wrinkleReduction(category: BeautyCategory.skin, label: 'Wrinkle Reduction'),

  /// Periorbital dark circle lightening.
  darkCircleReduction(category: BeautyCategory.skin, label: 'Dark Circle Reduction'),

  /// High-frequency skin micro-texture preservation.
  skinTexture(category: BeautyCategory.skin, label: 'Skin Texture'),

  /// Overall facial key light and brightness.
  facialBrightness(category: BeautyCategory.skin, label: 'Facial Brightness'),

  /// Natural skin tone equalization.
  naturalEnhancement(category: BeautyCategory.skin, label: 'Natural Enhancement'),

  // --- Face Reshaping ---
  /// Cheek and lower jaw slimming.
  faceSlimming(category: BeautyCategory.face, label: 'Face Slimming'),

  /// Proportional overall face contraction.
  smallFace(category: BeautyCategory.face, label: 'Small Face'),

  /// Mandibular angle sharpening and jawline contour.
  jawlineAdjustment(category: BeautyCategory.face, label: 'Jawline'),

  /// Mentalis elongation or shortening (chin).
  chinAdjustment(category: BeautyCategory.face, label: 'Chin'),

  /// Cheek fullness and lift.
  cheekEnhancement(category: BeautyCategory.face, label: 'Cheek Enhancement'),

  /// Zygomatic arch (cheekbone) narrowing.
  cheekboneAdjustment(category: BeautyCategory.face, label: 'Cheekbones'),

  /// Forehead height and width proportion.
  foreheadAdjustment(category: BeautyCategory.face, label: 'Forehead'),

  /// Mid-face lateral width compression.
  faceWidth(category: BeautyCategory.face, label: 'Face Width'),

  /// Nasal ala (nostril width) narrowing.
  noseSlimming(category: BeautyCategory.face, label: 'Nose Slimming'),

  /// Nasal tip vertical positioning.
  noseHeight(category: BeautyCategory.face, label: 'Nose Height'),

  /// Nasal dorsum narrowing and highlight.
  noseBridge(category: BeautyCategory.face, label: 'Nose Bridge'),

  // --- Eye Enhancement ---
  /// Radial eye enlargement centered on iris landmarks.
  eyeEnlargement(category: BeautyCategory.eyes, label: 'Eye Enlargement'),

  /// Pupil and corneal reflection brightness.
  eyeBrightness(category: BeautyCategory.eyes, label: 'Eye Brightness'),

  /// Sclera whitening and redness reduction.
  eyeWhitening(category: BeautyCategory.eyes, label: 'Eye Whitening'),

  /// Canthal tilt and outer corner shape adjustment.
  eyeShape(category: BeautyCategory.eyes, label: 'Eye Shape'),

  /// Interpupillary distance expansion or contraction.
  eyeSpacing(category: BeautyCategory.eyes, label: 'Eye Spacing'),

  /// Eyebrow arch lift and density enhancement.
  eyebrowEnhancement(category: BeautyCategory.eyes, label: 'Eyebrow Enhancement'),

  /// Eyelash dark fringe definition.
  eyelashEnhancement(category: BeautyCategory.eyes, label: 'Eyelash Enhancement'),

  /// Tear trough and infraorbital crease smoothing.
  underEyeSmoothing(category: BeautyCategory.eyes, label: 'Under-Eye Smoothing'),

  // --- Makeup ---
  /// Lip color overlay with soft-light blending.
  lipstick(category: BeautyCategory.makeup, label: 'Lipstick'),

  /// Zygomatic blush tint with radial feathering.
  blush(category: BeautyCategory.makeup, label: 'Blush'),

  /// Upper eyelid gradient eyeshadow.
  eyeshadow(category: BeautyCategory.makeup, label: 'Eyeshadow'),

  /// Upper lid eyeliner contouring.
  eyeliner(category: BeautyCategory.makeup, label: 'Eyeliner'),

  /// Eyebrow color tinting.
  eyebrowColor(category: BeautyCategory.makeup, label: 'Eyebrow Color'),

  /// Full facial skin tone foundation base.
  foundation(category: BeautyCategory.makeup, label: 'Foundation'),

  /// High-point facial illumination (nasal tip, cheekbones, cupid bow).
  highlighter(category: BeautyCategory.makeup, label: 'Highlighter');

  const BeautyFeature({required this.category, required this.label});

  final BeautyCategory category;
  final String label;
}

/// Categorization of beauty features for UI and processing passes.
enum BeautyCategory {
  skin('Skin'),
  face('Face'),
  eyes('Eyes'),
  makeup('Makeup');

  const BeautyCategory(this.displayName);
  final String displayName;
}
