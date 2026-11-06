import 'beauty_color.dart';

/// Available makeup elements with default color palettes and landmarks mapping.
enum MakeupType {
  lipstick(
    label: 'Lipstick',
    supportedColors: [
      BeautyColor.lipstickRed,
      BeautyColor.lipstickPink,
      BeautyColor.lipstickRose,
      BeautyColor.lipstickPeach,
      BeautyColor.lipstickNude,
      BeautyColor.lipstickCoral,
      BeautyColor.lipstickBerry,
    ],
  ),
  blush(
    label: 'Blush',
    supportedColors: [
      BeautyColor.blushPink,
      BeautyColor.blushPeach,
      BeautyColor.blushRose,
      BeautyColor.blushNatural,
    ],
  ),
  eyeshadow(
    label: 'Eyeshadow',
    supportedColors: [
      BeautyColor.eyeshadowBrown,
      BeautyColor.eyeshadowPink,
      BeautyColor.eyeshadowPurple,
      BeautyColor.eyeshadowGold,
      BeautyColor.eyeshadowSmokey,
      BeautyColor.eyeshadowNatural,
    ],
  ),
  eyeliner(
    label: 'Eyeliner',
    supportedColors: [
      BeautyColor.eyelinerBlack,
      BeautyColor.eyelinerBrown,
    ],
  ),
  eyebrow(
    label: 'Eyebrow',
    supportedColors: [
      BeautyColor.eyebrowBrown,
      BeautyColor.eyebrowDark,
    ],
  ),
  foundation(
    label: 'Foundation',
    supportedColors: [
      BeautyColor(0x33FFE4C4), // Fair bisque
      BeautyColor(0x33F5DEB3), // Natural wheat
      BeautyColor(0x33DEB887), // Warm sand
    ],
  ),
  highlighter(
    label: 'Highlighter',
    supportedColors: [
      BeautyColor.highlighterChampagne,
    ],
  );

  const MakeupType({
    required this.label,
    required this.supportedColors,
  });

  final String label;
  final List<BeautyColor> supportedColors;
}
