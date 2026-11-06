/// 15 GPU-accelerated predefined color grading filters.
enum BeautyFilter {
  original(
    id: 'original',
    name: 'Original',
    description: 'Clean camera feed without color manipulation',
  ),
  natural(
    id: 'natural',
    name: 'Natural',
    description: 'Balanced contrast and subtle warm vibrance',
  ),
  warm(
    id: 'warm',
    name: 'Warm',
    description: 'Golden hour tones with elevated yellow/orange warmth',
  ),
  cool(
    id: 'cool',
    name: 'Cool',
    description: 'Clean cyan and azure tones with crisp highlights',
  ),
  vintage(
    id: 'vintage',
    name: 'Vintage',
    description: 'Nostalgic film look with muted shadows and sepia undertones',
  ),
  pink(
    id: 'pink',
    name: 'Pink',
    description: 'Delicate pastel magenta highlights for soft skin glow',
  ),
  fresh(
    id: 'fresh',
    name: 'Fresh',
    description: 'High key brightness with vibrant greens and blues',
  ),
  glamour(
    id: 'glamour',
    name: 'Glamour',
    description: 'Rich contrast, heightened saturation, and studio rim lighting',
  ),
  soft(
    id: 'soft',
    name: 'Soft',
    description: 'Diffused highlights with lowered shadow contrast',
  ),
  bright(
    id: 'bright',
    name: 'Bright',
    description: 'Elevated gamma and lifted midtones',
  ),
  cinematic(
    id: 'cinematic',
    name: 'Cinematic',
    description: 'Teal and orange dual-tone color grading with film curve',
  ),
  retro(
    id: 'retro',
    name: 'Retro',
    description: 'Faded blacks, saturated reds and 1980s VHS warmth',
  ),
  blackAndWhite(
    id: 'black_and_white',
    name: 'Black & White',
    description: 'High dynamic range monochrome luminance pass',
  ),
  golden(
    id: 'golden',
    name: 'Golden',
    description: 'Amber highlights and rich golden skin tones',
  ),
  dreamy(
    id: 'dreamy',
    name: 'Dreamy',
    description: 'Ethereal bloom, soft diffusion and gentle lavender tint',
  );

  const BeautyFilter({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  static BeautyFilter fromId(String id) {
    return BeautyFilter.values.firstWhere(
      (f) => f.id == id,
      orElse: () => BeautyFilter.original,
    );
  }
}
