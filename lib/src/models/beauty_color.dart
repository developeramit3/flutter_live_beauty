/// 32-bit RGBA color representation for makeup overlays and color grading.
class BeautyColor {
  const BeautyColor(this.value);

  /// Construct from individual 0-255 RGB and 0.0-1.0 alpha.
  const BeautyColor.fromARGB(int a, int r, int g, int b)
      : value = (((a & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;

  factory BeautyColor.fromRGBO(int r, int g, int b, double opacity) {
    final a = (opacity * 255.0).round().clamp(0, 255);
    return BeautyColor.fromARGB(a, r, g, b);
  }

  final int value;

  int get alpha => (value >> 24) & 0xff;
  int get red => (value >> 16) & 0xff;
  int get green => (value >> 8) & 0xff;
  int get blue => value & 0xff;
  double get opacity => alpha / 255.0;

  double get redF => red / 255.0;
  double get greenF => green / 255.0;
  double get blueF => blue / 255.0;

  Map<String, dynamic> toMap() => {
        'value': value,
        'r': redF,
        'g': greenF,
        'b': blueF,
        'a': opacity,
      };

  factory BeautyColor.fromMap(Map<String, dynamic> map) {
    return BeautyColor(map['value'] as int? ?? 0xFF000000);
  }

  // --- Lipstick Colors ---
  static const BeautyColor lipstickRed = BeautyColor(0xCCDC143C); // Crimson
  static const BeautyColor lipstickPink = BeautyColor(0xCCFF69B4); // HotPink
  static const BeautyColor lipstickRose = BeautyColor(0xCCC71585); // MediumVioletRed
  static const BeautyColor lipstickPeach = BeautyColor(0xCCFF7F50); // Coral Peach
  static const BeautyColor lipstickNude = BeautyColor(0xCCBC8F8F); // RosyBrown
  static const BeautyColor lipstickCoral = BeautyColor(0xCCFF6F61); // Living Coral
  static const BeautyColor lipstickBerry = BeautyColor(0xCC8B004F); // Dark Berry

  // --- Blush Colors ---
  static const BeautyColor blushPink = BeautyColor(0x88FFB6C1);
  static const BeautyColor blushPeach = BeautyColor(0x88FFA07A);
  static const BeautyColor blushRose = BeautyColor(0x88DB7093);
  static const BeautyColor blushNatural = BeautyColor(0x66E9967A);

  // --- Eyeshadow Colors ---
  static const BeautyColor eyeshadowBrown = BeautyColor(0x998B5A2B);
  static const BeautyColor eyeshadowPink = BeautyColor(0x99FFC0CB);
  static const BeautyColor eyeshadowPurple = BeautyColor(0x99800080);
  static const BeautyColor eyeshadowGold = BeautyColor(0x99DAA520);
  static const BeautyColor eyeshadowSmokey = BeautyColor(0x992F4F4F);
  static const BeautyColor eyeshadowNatural = BeautyColor(0x77CD853F);

  // --- Eyeliner & Eyebrow ---
  static const BeautyColor eyelinerBlack = BeautyColor(0xEE1A1A1A);
  static const BeautyColor eyelinerBrown = BeautyColor(0xEE3E2723);
  static const BeautyColor eyebrowBrown = BeautyColor(0xCC4E342E);
  static const BeautyColor eyebrowDark = BeautyColor(0xCC212121);

  // --- Highlighter ---
  static const BeautyColor highlighterChampagne = BeautyColor(0x88FFF8DC);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeautyColor &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BeautyColor(0x${value.toRadixString(16).padLeft(8, '0')})';
}
