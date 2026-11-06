import '../config/beauty_config.dart';
import '../models/beauty_color.dart';
import '../models/beauty_feature.dart';
import '../models/beauty_filter.dart';
import '../models/makeup_type.dart';

/// Predefined or user-defined combination of beauty, face, makeup, and filter parameters.
class BeautyPreset {
  const BeautyPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.config,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String description;
  final BeautyConfig config;
  final bool isBuiltIn;

  BeautyPreset copyWith({
    String? id,
    String? name,
    String? description,
    BeautyConfig? config,
    bool? isBuiltIn,
  }) {
    return BeautyPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      config: config ?? this.config,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'config': config.toMap(),
        'isBuiltIn': isBuiltIn,
      };

  factory BeautyPreset.fromMap(Map<String, dynamic> map) {
    return BeautyPreset(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      config: BeautyConfig.fromMap(
          Map<String, dynamic>.from(map['config'] as Map? ?? {})),
      isBuiltIn: map['isBuiltIn'] as bool? ?? false,
    );
  }

  // --- 8 Predefined Built-in Presets ---

  /// 1. Natural: Everyday clean look with gentle skin texture preservation.
  static const BeautyPreset natural = BeautyPreset(
    id: 'preset_natural',
    name: 'Natural',
    description: 'Fresh clean appearance preserving natural skin texture',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_natural',
      activeFilter: BeautyFilter.natural,
      filterIntensity: 40,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 35,
        BeautyFeature.skinWhitening: 20,
        BeautyFeature.naturalEnhancement: 40,
        BeautyFeature.skinTexture: 60,
        BeautyFeature.eyeBrightness: 25,
        BeautyFeature.faceSlimming: 15,
        BeautyFeature.jawlineAdjustment: 10,
      },
    ),
  );

  /// 2. Glamour: Elevated studio lighting, contoured jawline, rich lipstick.
  static const BeautyPreset glamour = BeautyPreset(
    id: 'preset_glamour',
    name: 'Glamour',
    description: 'Dramatic studio lighting with bold lip and defined contour',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_glamour',
      activeFilter: BeautyFilter.glamour,
      filterIntensity: 65,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 65,
        BeautyFeature.skinWhitening: 40,
        BeautyFeature.skinGlow: 50,
        BeautyFeature.faceSlimming: 45,
        BeautyFeature.smallFace: 30,
        BeautyFeature.jawlineAdjustment: 40,
        BeautyFeature.cheekboneAdjustment: 30,
        BeautyFeature.noseSlimming: 35,
        BeautyFeature.noseBridge: 40,
        BeautyFeature.eyeEnlargement: 35,
        BeautyFeature.eyeBrightness: 50,
        BeautyFeature.eyelashEnhancement: 60,
        BeautyFeature.lipstick: 70,
        BeautyFeature.blush: 50,
        BeautyFeature.highlighter: 55,
      },
      makeupColors: {
        MakeupType.lipstick: BeautyColor.lipstickRed,
        MakeupType.blush: BeautyColor.blushRose,
        MakeupType.eyeshadow: BeautyColor.eyeshadowGold,
        MakeupType.highlighter: BeautyColor.highlighterChampagne,
      },
    ),
  );

  /// 3. Cute: Soft rounded face, enlarged eyes, flushed peach cheeks.
  static const BeautyPreset cute = BeautyPreset(
    id: 'preset_cute',
    name: 'Cute',
    description: 'Enlarged bright eyes, youthful round cheeks and peach blush',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_cute',
      activeFilter: BeautyFilter.pink,
      filterIntensity: 50,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 55,
        BeautyFeature.skinWhitening: 35,
        BeautyFeature.skinGlow: 35,
        BeautyFeature.smallFace: 40,
        BeautyFeature.chinAdjustment: 25,
        BeautyFeature.cheekEnhancement: 45,
        BeautyFeature.eyeEnlargement: 55,
        BeautyFeature.eyeBrightness: 60,
        BeautyFeature.eyeWhitening: 30,
        BeautyFeature.lipstick: 50,
        BeautyFeature.blush: 65,
      },
      makeupColors: {
        MakeupType.lipstick: BeautyColor.lipstickPeach,
        MakeupType.blush: BeautyColor.blushPeach,
        MakeupType.eyeshadow: BeautyColor.eyeshadowPink,
      },
    ),
  );

  /// 4. Soft: Dreamy diffusion, low contrast, gentle wrinkle & blemish erasing.
  static const BeautyPreset soft = BeautyPreset(
    id: 'preset_soft',
    name: 'Soft',
    description: 'Dreamy diffusion and muted soft focus lighting',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_soft',
      activeFilter: BeautyFilter.soft,
      filterIntensity: 60,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 50,
        BeautyFeature.skinWhitening: 25,
        BeautyFeature.wrinkleReduction: 45,
        BeautyFeature.blemishReduction: 50,
        BeautyFeature.darkCircleReduction: 40,
        BeautyFeature.facialBrightness: 25,
        BeautyFeature.faceSlimming: 20,
        BeautyFeature.eyeBrightness: 30,
      },
    ),
  );

  /// 5. Fresh: Vibrant, crisp daylight tones with highlighted cheekbones.
  static const BeautyPreset fresh = BeautyPreset(
    id: 'preset_fresh',
    name: 'Fresh',
    description: 'Luminous daytime radiance with subtle coral accents',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_fresh',
      activeFilter: BeautyFilter.fresh,
      filterIntensity: 45,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 40,
        BeautyFeature.skinWhitening: 30,
        BeautyFeature.skinGlow: 35,
        BeautyFeature.facialBrightness: 35,
        BeautyFeature.faceSlimming: 25,
        BeautyFeature.noseSlimming: 20,
        BeautyFeature.eyeEnlargement: 25,
        BeautyFeature.eyeBrightness: 40,
        BeautyFeature.lipstick: 40,
        BeautyFeature.blush: 35,
      },
      makeupColors: {
        MakeupType.lipstick: BeautyColor.lipstickCoral,
        MakeupType.blush: BeautyColor.blushPeach,
      },
    ),
  );

  /// 6. Professional: Crisp business/interview clarity with zero artificial shine.
  static const BeautyPreset professional = BeautyPreset(
    id: 'preset_professional',
    name: 'Professional',
    description: 'Authoritative crisp clarity with shine suppression',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_professional',
      activeFilter: BeautyFilter.original,
      filterIntensity: 0,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 30,
        BeautyFeature.blemishReduction: 40,
        BeautyFeature.darkCircleReduction: 45,
        BeautyFeature.underEyeSmoothing: 40,
        BeautyFeature.skinTexture: 70,
        BeautyFeature.eyeBrightness: 30,
        BeautyFeature.naturalEnhancement: 50,
        BeautyFeature.facialBrightness: 20,
      },
    ),
  );

  /// 7. Fair: High-luminance porcelain skin tones with cool undertones.
  static const BeautyPreset fair = BeautyPreset(
    id: 'preset_fair',
    name: 'Fair',
    description: 'Porcelain bright complexion with cool porcelain tones',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_fair',
      activeFilter: BeautyFilter.cool,
      filterIntensity: 40,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 60,
        BeautyFeature.skinWhitening: 65,
        BeautyFeature.skinTone: 20, // Cooler
        BeautyFeature.skinGlow: 40,
        BeautyFeature.facialBrightness: 45,
        BeautyFeature.blemishReduction: 55,
        BeautyFeature.faceSlimming: 30,
        BeautyFeature.eyeBrightness: 45,
        BeautyFeature.lipstick: 45,
      },
      makeupColors: {
        MakeupType.lipstick: BeautyColor.lipstickRose,
        MakeupType.blush: BeautyColor.blushPink,
      },
    ),
  );

  /// 8. Korean: Dewy glass skin, straight brow definition, gradient pink lip.
  static const BeautyPreset korean = BeautyPreset(
    id: 'preset_korean',
    name: 'Korean',
    description: 'Dewy glass skin, youthful V-line jaw, and gradient pink lips',
    isBuiltIn: true,
    config: BeautyConfig(
      enabled: true,
      activePresetId: 'preset_korean',
      activeFilter: BeautyFilter.dreamy,
      filterIntensity: 40,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 65,
        BeautyFeature.skinWhitening: 50,
        BeautyFeature.skinGlow: 60,
        BeautyFeature.faceSlimming: 40,
        BeautyFeature.jawlineAdjustment: 45,
        BeautyFeature.chinAdjustment: 25,
        BeautyFeature.noseSlimming: 30,
        BeautyFeature.noseBridge: 35,
        BeautyFeature.eyeEnlargement: 40,
        BeautyFeature.eyeBrightness: 50,
        BeautyFeature.underEyeSmoothing: 45,
        BeautyFeature.lipstick: 60,
        BeautyFeature.blush: 40,
        BeautyFeature.highlighter: 45,
      },
      makeupColors: {
        MakeupType.lipstick: BeautyColor.lipstickPink,
        MakeupType.blush: BeautyColor.blushPink,
        MakeupType.highlighter: BeautyColor.highlighterChampagne,
      },
    ),
  );

  /// All 8 built-in presets.
  static const List<BeautyPreset> builtInPresets = [
    natural,
    glamour,
    cute,
    soft,
    fresh,
    professional,
    fair,
    korean,
  ];
}
