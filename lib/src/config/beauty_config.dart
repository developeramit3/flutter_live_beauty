import '../models/beauty_color.dart';
import '../models/beauty_feature.dart';
import '../models/beauty_filter.dart';
import '../models/beauty_performance_profile.dart';
import '../models/makeup_type.dart';

/// Full immutable configuration containing all beauty, face reshaping,
/// makeup, and color filter parameters.
class BeautyConfig {
  const BeautyConfig({
    this.enabled = true,
    this.featureIntensities = const {},
    this.featureEnabled = const {},
    this.activeFilter = BeautyFilter.original,
    this.filterIntensity = 80,
    this.makeupColors = const {
      MakeupType.lipstick: BeautyColor.lipstickRed,
      MakeupType.blush: BeautyColor.blushPink,
      MakeupType.eyeshadow: BeautyColor.eyeshadowBrown,
      MakeupType.eyeliner: BeautyColor.eyelinerBlack,
      MakeupType.eyebrow: BeautyColor.eyebrowBrown,
      MakeupType.highlighter: BeautyColor.highlighterChampagne,
    },
    this.performanceProfile = BeautyPerformanceProfile.balanced,
    this.maxFaces = 1,
    this.activePresetId,
  });

  /// Master switch for all beauty and filter processing.
  final bool enabled;

  /// Intensity per feature (0 - 100).
  final Map<BeautyFeature, int> featureIntensities;

  /// Individual enable/disable switch per feature.
  final Map<BeautyFeature, bool> featureEnabled;

  /// Active GPU color grade filter.
  final BeautyFilter activeFilter;

  /// Color filter strength (0 - 100).
  final int filterIntensity;

  /// Selected colors for makeup layers.
  final Map<MakeupType, BeautyColor> makeupColors;

  /// Runtime performance profile.
  final BeautyPerformanceProfile performanceProfile;

  /// Maximum simultaneous face tracking slots.
  final int maxFaces;

  /// ID of currently applied preset (null if custom or unmodified).
  final String? activePresetId;

  /// Get intensity for a specific feature (defaults to 0).
  int getIntensity(BeautyFeature feature) {
    return featureIntensities[feature] ?? 0;
  }

  /// Check whether an individual feature is active and has non-zero intensity.
  bool isFeatureActive(BeautyFeature feature) {
    final isExplicitlyEnabled = featureEnabled[feature] ?? true;
    return enabled && isExplicitlyEnabled && (getIntensity(feature) > 0);
  }

  /// Return makeup color for a specific makeup type.
  BeautyColor getMakeupColor(MakeupType type) {
    return makeupColors[type] ?? type.supportedColors.first;
  }

  /// Create a modified copy of this configuration.
  BeautyConfig copyWith({
    bool? enabled,
    Map<BeautyFeature, int>? featureIntensities,
    Map<BeautyFeature, bool>? featureEnabled,
    BeautyFilter? activeFilter,
    int? filterIntensity,
    Map<MakeupType, BeautyColor>? makeupColors,
    BeautyPerformanceProfile? performanceProfile,
    int? maxFaces,
    String? activePresetId,
  }) {
    return BeautyConfig(
      enabled: enabled ?? this.enabled,
      featureIntensities: featureIntensities ?? this.featureIntensities,
      featureEnabled: featureEnabled ?? this.featureEnabled,
      activeFilter: activeFilter ?? this.activeFilter,
      filterIntensity: filterIntensity ?? this.filterIntensity,
      makeupColors: makeupColors ?? this.makeupColors,
      performanceProfile: performanceProfile ?? this.performanceProfile,
      maxFaces: maxFaces ?? this.maxFaces,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  /// Set intensity for a specific feature, clamping between 0 and 100.
  BeautyConfig withFeatureIntensity(BeautyFeature feature, int intensity) {
    final updated = Map<BeautyFeature, int>.from(featureIntensities);
    updated[feature] = intensity.clamp(0, 100);
    return copyWith(featureIntensities: updated);
  }

  /// Set enabled state for an individual feature.
  BeautyConfig withFeatureEnabled(BeautyFeature feature, bool isEnabled) {
    final updated = Map<BeautyFeature, bool>.from(featureEnabled);
    updated[feature] = isEnabled;
    return copyWith(featureEnabled: updated);
  }

  /// Set color for a specific makeup element.
  BeautyConfig withMakeupColor(MakeupType type, BeautyColor color) {
    final updated = Map<MakeupType, BeautyColor>.from(makeupColors);
    updated[type] = color;
    return copyWith(makeupColors: updated);
  }

  /// Reset all feature intensities and filters back to zero/original.
  static BeautyConfig naturalDefault() {
    return const BeautyConfig(
      enabled: true,
      featureIntensities: {
        BeautyFeature.skinSmoothing: 30,
        BeautyFeature.skinWhitening: 20,
        BeautyFeature.naturalEnhancement: 25,
      },
    );
  }

  /// Clean zeroed configuration.
  static BeautyConfig zero() {
    return const BeautyConfig(
      enabled: true,
      featureIntensities: {},
      activeFilter: BeautyFilter.original,
      filterIntensity: 0,
    );
  }

  Map<String, dynamic> toMap() {
    final intensitiesMap = <String, int>{};
    featureIntensities.forEach((k, v) => intensitiesMap[k.name] = v);

    final enabledMap = <String, bool>{};
    featureEnabled.forEach((k, v) => enabledMap[k.name] = v);

    final colorsMap = <String, int>{};
    makeupColors.forEach((k, v) => colorsMap[k.name] = v.value);

    return {
      'enabled': enabled,
      'featureIntensities': intensitiesMap,
      'featureEnabled': enabledMap,
      'activeFilter': activeFilter.id,
      'filterIntensity': filterIntensity,
      'makeupColors': colorsMap,
      'performanceProfile': performanceProfile.name,
      'maxFaces': maxFaces,
      'activePresetId': activePresetId,
    };
  }

  factory BeautyConfig.fromMap(Map<String, dynamic> map) {
    final intensities = <BeautyFeature, int>{};
    final rawIntensities = map['featureIntensities'] as Map<dynamic, dynamic>?;
    if (rawIntensities != null) {
      for (final entry in rawIntensities.entries) {
        final feature = BeautyFeature.values.cast<BeautyFeature?>().firstWhere(
              (f) => f?.name == entry.key,
              orElse: () => null,
            );
        if (feature != null && entry.value is num) {
          intensities[feature] = (entry.value as num).toInt();
        }
      }
    }

    final enabledFeatures = <BeautyFeature, bool>{};
    final rawEnabled = map['featureEnabled'] as Map<dynamic, dynamic>?;
    if (rawEnabled != null) {
      for (final entry in rawEnabled.entries) {
        final feature = BeautyFeature.values.cast<BeautyFeature?>().firstWhere(
              (f) => f?.name == entry.key,
              orElse: () => null,
            );
        if (feature != null && entry.value is bool) {
          enabledFeatures[feature] = entry.value as bool;
        }
      }
    }

    final colors = <MakeupType, BeautyColor>{};
    final rawColors = map['makeupColors'] as Map<dynamic, dynamic>?;
    if (rawColors != null) {
      for (final entry in rawColors.entries) {
        final type = MakeupType.values.cast<MakeupType?>().firstWhere(
              (t) => t?.name == entry.key,
              orElse: () => null,
            );
        if (type != null && entry.value is int) {
          colors[type] = BeautyColor(entry.value as int);
        }
      }
    }

    final filterId = map['activeFilter'] as String?;
    final filter = filterId != null
        ? BeautyFilter.fromId(filterId)
        : BeautyFilter.original;

    final profileName = map['performanceProfile'] as String?;
    final profile = BeautyPerformanceProfile.values.firstWhere(
      (p) => p.name == profileName,
      orElse: () => BeautyPerformanceProfile.balanced,
    );

    return BeautyConfig(
      enabled: map['enabled'] as bool? ?? true,
      featureIntensities: intensities,
      featureEnabled: enabledFeatures,
      activeFilter: filter,
      filterIntensity: (map['filterIntensity'] as num?)?.toInt() ?? 80,
      makeupColors: colors.isEmpty
          ? {
              MakeupType.lipstick: BeautyColor.lipstickRed,
              MakeupType.blush: BeautyColor.blushPink,
              MakeupType.eyeshadow: BeautyColor.eyeshadowBrown,
              MakeupType.eyeliner: BeautyColor.eyelinerBlack,
              MakeupType.eyebrow: BeautyColor.eyebrowBrown,
              MakeupType.highlighter: BeautyColor.highlighterChampagne,
            }
          : colors,
      performanceProfile: profile,
      maxFaces: (map['maxFaces'] as num?)?.toInt() ?? 1,
      activePresetId: map['activePresetId'] as String?,
    );
  }
}
