import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_live_beauty/flutter_live_beauty.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiveBeautyExampleApp());
}

class LiveBeautyExampleApp extends StatelessWidget {
  const LiveBeautyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Live Beauty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF10121A),
        primaryColor: const Color(0xFFFF2A6D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2A6D),
          secondary: Color(0xFFFF5E7E),
          surface: Color(0xFF1B1D28),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFFFF2A6D),
          thumbColor: Colors.white,
          inactiveTrackColor: Color(0x33FFFFFF),
          trackHeight: 3.5,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
        ),
      ),
      home: const CameraMainScreen(),
    );
  }
}

// Preset model with portrait image asset/URL
class PresetItem {
  final String id;
  final String name;
  final String imageUrl;
  final BeautyPreset preset;

  const PresetItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.preset,
  });
}

const List<PresetItem> kPresetItems = [
  PresetItem(
    id: 'natural',
    name: 'Natural',
    imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    preset: BeautyPreset.natural,
  ),
  PresetItem(
    id: 'glamour',
    name: 'Glamour',
    imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80',
    preset: BeautyPreset.glamour,
  ),
  PresetItem(
    id: 'cute',
    name: 'Cute',
    imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80',
    preset: BeautyPreset.cute,
  ),
  PresetItem(
    id: 'soft',
    name: 'Soft',
    imageUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400&q=80',
    preset: BeautyPreset.soft,
  ),
  PresetItem(
    id: 'fresh',
    name: 'Fresh',
    imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
    preset: BeautyPreset.fresh,
  ),
  PresetItem(
    id: 'professional',
    name: 'Professional',
    imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80',
    preset: BeautyPreset.professional,
  ),
  PresetItem(
    id: 'fair',
    name: 'Fair',
    imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80',
    preset: BeautyPreset.fair,
  ),
  PresetItem(
    id: 'korean',
    name: 'Korean',
    imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80',
    preset: BeautyPreset.korean,
  ),
];

class SafePortraitImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const SafePortraitImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C2F42), Color(0xFF1B1D28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.face, color: Colors.white54, size: 28),
      ),
    );

    if (isCircle) {
      return ClipOval(child: image);
    }
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

// ============================================================================
// SCREEN 1: CAMERA MAIN SCREEN (Matching UI Screen 1)
// ============================================================================
class CameraMainScreen extends StatefulWidget {
  const CameraMainScreen({super.key});

  @override
  State<CameraMainScreen> createState() => _CameraMainScreenState();
}

class _CameraMainScreenState extends State<CameraMainScreen> {
  final LiveBeautyController _controller = LiveBeautyController();
  bool _permissionDenied = false;
  String _selectedPresetId = 'glamour';
  String _aspectRatio = '9:16';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _permissionDenied = false;
    });

    try {
      final hasPerm = await _controller.hasCameraPermission();
      if (!hasPerm) {
        final granted = await _controller.requestCameraPermission();
        if (!granted) {
          setState(() {
            _permissionDenied = true;
          });
          return;
        }
      }

      await _controller.initialize(
        cameraPosition: BeautyCameraPosition.front,
        resolution: BeautyResolution.hd720p,
        config: BeautyPreset.glamour.config,
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('PERMISSION') || e.toString().contains('permission')) {
          setState(() => _permissionDenied = true);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openBeautySettings({int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BeautySettingsModalSheet(
        controller: _controller,
        initialTab: initialTab,
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltersModalSheet(controller: _controller),
    );
  }

  void _openPresets() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeautyPresetsScreen(
          controller: _controller,
          selectedPresetId: _selectedPresetId,
          onPresetSelected: (id) {
            setState(() => _selectedPresetId = id);
          },
        ),
      ),
    );
  }

  void _openBeforeAfter() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeforeAfterComparisonScreen(controller: _controller),
      ),
    );
  }

  void _openLiveStream() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveStreamBroadcastScreen(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: const Color(0xFF10121A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2A6D).withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.no_photography, size: 56, color: Color(0xFFFF2A6D)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Camera Permission Required',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please grant camera permission to preview beauty effects.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2A6D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  onPressed: _initCamera,
                  child: const Text('Grant & Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          LiveBeautyPreview(
            controller: _controller,
            fit: BoxFit.cover,
            loadingWidget: Container(
              color: const Color(0xFF10121A),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF2A6D)),
              ),
            ),
          ),

          // Top Left 'X' Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () {},
                ),
              ),
            ),
          ),

          // Top Right Vertical Toolbar (Flip, Flash, 9:16 Ratio, Settings)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withAlpha(40), width: 0.8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToolbarItem(
                        icon: Icons.flip_camera_ios,
                        label: 'Flip',
                        onTap: () => _controller.switchCamera(),
                      ),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) => _buildToolbarItem(
                          icon: _controller.isFlashEnabled ? Icons.flash_on : Icons.flash_off,
                          label: 'Flash',
                          onTap: () => _controller.setFlash(!_controller.isFlashEnabled),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildToolbarItem(
                        icon: Icons.crop_portrait,
                        label: _aspectRatio,
                        onTap: () {
                          setState(() {
                            _aspectRatio = _aspectRatio == '9:16' ? '3:4' : '9:16';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildToolbarItem(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () => _openBeautySettings(initialTab: 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Compare Split Button (Top Center Floating Badge)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: GestureDetector(
                  onTap: _openBeforeAfter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(50), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.compare_arrows, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Before / After',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation Pill Bar (Matching Screen 1)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D28).withAlpha(220),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withAlpha(35), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(160),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Preset Avatar Thumbnail Button
                      GestureDetector(
                        onTap: _openPresets,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFF2A6D), width: 2),
                          ),
                          child: const SafePortraitImage(
                            url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
                            isCircle: true,
                          ),
                        ),
                      ),

                      // Beauty Button
                      GestureDetector(
                        onTap: () => _openBeautySettings(initialTab: 0),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_fix_high, color: Colors.white, size: 24),
                            SizedBox(height: 4),
                            Text('Beauty', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),

                      // Big Circular Glowing 'Go Live' Button
                      GestureDetector(
                        onTap: _openLiveStream,
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF2A6D), Color(0xFFFF5E7E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2A6D).withAlpha(150),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.podcasts, color: Colors.white, size: 22),
                              SizedBox(height: 2),
                              Text(
                                'Go Live',
                                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filters Button
                      GestureDetector(
                        onTap: _openFilters,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_vintage, color: Colors.white, size: 24),
                            SizedBox(height: 4),
                            Text('Filters', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),

                      // Presets Button
                      GestureDetector(
                        onTap: _openPresets,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard_customize, color: Colors.white, size: 24),
                            SizedBox(height: 4),
                            Text('Presets', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCREEN 2: BEFORE / AFTER SPLIT SLIDER (Matching UI Screen 2)
// ============================================================================
class BeforeAfterComparisonScreen extends StatefulWidget {
  final LiveBeautyController controller;

  const BeforeAfterComparisonScreen({super.key, required this.controller});

  @override
  State<BeforeAfterComparisonScreen> createState() => _BeforeAfterComparisonScreenState();
}

class _BeforeAfterComparisonScreenState extends State<BeforeAfterComparisonScreen> {
  double _splitRatio = 0.50; // 0.0 = all raw, 1.0 = all filtered

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background filtered camera feed
          LiveBeautyPreview(
            controller: widget.controller,
            fit: BoxFit.cover,
          ),

          // Interactive Draggable Split View
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final splitX = width * _splitRatio;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Left side ("Before" raw/slightly desaturated overlay indicator)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: splitX,
                    child: ClipRect(
                      child: Container(
                        color: Colors.blueGrey.withAlpha(25), // Subtle tone separation
                      ),
                    ),
                  ),

                  // Vertical Divider Line
                  Positioned(
                    left: splitX - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3.0,
                      color: Colors.white,
                    ),
                  ),

                  // Circular Drag Handle with '< >' arrows
                  Positioned(
                    left: splitX - 20,
                    top: constraints.maxHeight * 0.5 - 20,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _splitRatio = (_splitRatio + details.delta.dx / width).clamp(0.05, 0.95);
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(140),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.code,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Full touch listener across screen for effortless dragging
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _splitRatio = (_splitRatio + details.delta.dx / width).clamp(0.05, 0.95);
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          // Top 'X' Button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Top Pill Badge: "Before / After"
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(40), width: 0.8),
                  ),
                  child: const Text(
                    'Before / After',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Left "Before" Pill
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Before',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Right "After" Pill
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 28, bottom: 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'After',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCREENS 3, 4, 5: BEAUTY SETTINGS MODAL SHEET (Matching Screens 3, 4, 5)
// ============================================================================
class BeautySettingsModalSheet extends StatefulWidget {
  final LiveBeautyController controller;
  final int initialTab;

  const BeautySettingsModalSheet({
    super.key,
    required this.controller,
    this.initialTab = 0,
  });

  @override
  State<BeautySettingsModalSheet> createState() => _BeautySettingsModalSheetState();
}

class _BeautySettingsModalSheetState extends State<BeautySettingsModalSheet> {
  late int _selectedTab; // 0=Beauty, 1=Face, 2=Eyes, 3=Makeup
  int _selectedMakeupType = 0; // 0=Lipstick, 1=Blush, 2=Eyeshadow, 3=Eyeliner
  BeautyColor _selectedLipstickColor = BeautyColor.lipstickRose;

  final List<BeautyColor> _lipstickPalette = [
    BeautyColor.lipstickPeach,
    BeautyColor.lipstickRose,
    BeautyColor.lipstickCoral,
    BeautyColor.lipstickNude,
    BeautyColor.lipstickPink,
    BeautyColor.lipstickRed,
    BeautyColor.lipstickBerry,
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: const BoxDecoration(
        color: Color(0xFF141620),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Header: '<', 'Beauty Settings', 'Reset'
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Beauty Settings',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () async {
                    await widget.controller.resetAll();
                    setState(() {});
                  },
                  child: const Text('Reset', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
          ),

          // Main Tabs: Beauty | Face | Eyes | Makeup (Matching Screens 3, 4, 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabItem('Beauty', 0),
                _buildTabItem('Face', 1),
                _buildTabItem('Eyes', 2),
                _buildTabItem('Makeup', 3),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Content body based on active tab
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                switch (_selectedTab) {
                  case 0:
                    return _buildBeautyTab();
                  case 1:
                    return _buildFaceTab();
                  case 2:
                    return _buildEyesTab();
                  case 3:
                    return _buildMakeupTab();
                  default:
                    return _buildBeautyTab();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF2A6D) : Colors.white60,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Container(
            height: 2.5,
            width: 32,
            color: isSelected ? const Color(0xFFFF2A6D) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // SCREEN 3: BEAUTY TAB
  Widget _buildBeautyTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildSliderRow(
          icon: Icons.face_retouching_natural,
          label: 'Skin Smoothing',
          feature: BeautyFeature.skinSmoothing,
          defaultValue: 70,
        ),
        _buildSliderRow(
          icon: Icons.auto_awesome,
          label: 'Skin Whitening',
          feature: BeautyFeature.skinWhitening,
          defaultValue: 40,
        ),
        _buildSliderRow(
          icon: Icons.wb_sunny_outlined,
          label: 'Skin Brightness',
          feature: BeautyFeature.facialBrightness,
          defaultValue: 55,
        ),
        _buildSliderRow(
          icon: Icons.water_drop_outlined,
          label: 'Skin Glow',
          feature: BeautyFeature.skinGlow,
          defaultValue: 50,
        ),
      ],
    );
  }

  // SCREEN 4: FACE TAB
  Widget _buildFaceTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildSliderRow(
          icon: Icons.face,
          label: 'Face Slimming',
          feature: BeautyFeature.faceSlimming,
          defaultValue: 30,
        ),
        _buildSliderRow(
          icon: Icons.radio_button_unchecked,
          label: 'Jawline',
          feature: BeautyFeature.jawlineAdjustment,
          defaultValue: 40,
        ),
        _buildSliderRow(
          icon: Icons.mood,
          label: 'Chin',
          feature: BeautyFeature.chinAdjustment,
          defaultValue: 35,
        ),
        _buildSliderRow(
          icon: Icons.filter_center_focus,
          label: 'Nose Slimming',
          feature: BeautyFeature.noseSlimming,
          defaultValue: 25,
        ),
      ],
    );
  }

  // EYES TAB
  Widget _buildEyesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildSliderRow(
          icon: Icons.remove_red_eye_outlined,
          label: 'Eye Enlargement',
          feature: BeautyFeature.eyeEnlargement,
          defaultValue: 45,
        ),
        _buildSliderRow(
          icon: Icons.visibility,
          label: 'Eye Brightness',
          feature: BeautyFeature.eyeBrightness,
          defaultValue: 50,
        ),
        _buildSliderRow(
          icon: Icons.lens_blur,
          label: 'Eye Whitening',
          feature: BeautyFeature.eyeWhitening,
          defaultValue: 30,
        ),
        _buildSliderRow(
          icon: Icons.hdr_strong,
          label: 'Under-Eye Smoothing',
          feature: BeautyFeature.underEyeSmoothing,
          defaultValue: 40,
        ),
      ],
    );
  }

  // SCREEN 5: MAKEUP TAB
  Widget _buildMakeupTab() {
    final intensity = widget.controller.config.getIntensity(BeautyFeature.lipstick);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Sub-category pills: Lipstick | Blush | Eyeshadow | Eyeliner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSubPill('Lipstick', 0),
            _buildSubPill('Blush', 1),
            _buildSubPill('Eyeshadow', 2),
            _buildSubPill('Eyeliner', 3),
          ],
        ),
        const SizedBox(height: 24),

        // Color Swatches Palette (Matching Screen 5)
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _lipstickPalette.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, idx) {
              final color = _lipstickPalette[idx];
              final isSelected = color == _selectedLipstickColor;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedLipstickColor = color);
                  widget.controller.setMakeupColor(MakeupType.lipstick, color);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(color.value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(color.value).withAlpha(160),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),

        // Intensity Slider Row
        Row(
          children: [
            const Text(
              'Intensity',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: intensity.toDouble(),
                min: 0,
                max: 100,
                onChanged: (val) {
                  widget.controller.setBeauty(BeautyFeature.lipstick, val.round());
                },
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$intensity',
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubPill(String label, int index) {
    final isSelected = _selectedMakeupType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMakeupType = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF2A6D) : const Color(0xFF1E212E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required BeautyFeature feature,
    required int defaultValue,
  }) {
    final val = widget.controller.config.getIntensity(feature);
    final displayVal = val > 0 ? val : defaultValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 14),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Slider(
              value: displayVal.toDouble(),
              min: 0,
              max: 100,
              onChanged: (newVal) {
                widget.controller.setBeauty(feature, newVal.round());
              },
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$displayVal',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCREEN 6: FILTERS PANEL (Matching UI Screen 6)
// ============================================================================
class FiltersModalSheet extends StatefulWidget {
  final LiveBeautyController controller;

  const FiltersModalSheet({super.key, required this.controller});

  @override
  State<FiltersModalSheet> createState() => _FiltersModalSheetState();
}

class _FiltersModalSheetState extends State<FiltersModalSheet> {
  BeautyFilter _activeFilter = BeautyFilter.natural;
  int _intensity = 80;

  final List<Map<String, dynamic>> _filterCards = [
    {
      'filter': BeautyFilter.original,
      'name': 'Original',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
    },
    {
      'filter': BeautyFilter.natural,
      'name': 'Natural',
      'image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
    },
    {
      'filter': BeautyFilter.warm,
      'name': 'Warm',
      'image': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80',
    },
    {
      'filter': BeautyFilter.fresh,
      'name': 'Fresh',
      'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
    },
    {
      'filter': BeautyFilter.glamour,
      'name': 'Glamour',
      'image': 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=200&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.controller.config.activeFilter;
    _intensity = widget.controller.config.filterIntensity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.46,
      decoration: const BoxDecoration(
        color: Color(0xFF141620),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Header: '<', 'Filters', '✓'
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Filters',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Filter Cards Carousel (Matching Screen 6)
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filterCards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
                final item = _filterCards[idx];
                final BeautyFilter filter = item['filter'] as BeautyFilter;
                final isSelected = filter == _activeFilter;

                return GestureDetector(
                  onTap: () {
                    setState(() => _activeFilter = filter);
                    widget.controller.setFilter(filter, _intensity);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF2A6D) : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: SafePortraitImage(
                          url: item['image'] as String,
                          borderRadius: BorderRadius.circular(13.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['name'] as String,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFFF2A6D) : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Intensity Slider Row (Matching Screen 6)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Intensity',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Slider(
                    value: _intensity.toDouble(),
                    min: 0,
                    max: 100,
                    onChanged: (val) {
                      setState(() => _intensity = val.round());
                      widget.controller.setFilter(_activeFilter, _intensity);
                    },
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$_intensity',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCREEN 7: BEAUTY PRESETS SCREEN (Matching UI Screen 7)
// ============================================================================
class BeautyPresetsScreen extends StatefulWidget {
  final LiveBeautyController controller;
  final String selectedPresetId;
  final ValueChanged<String> onPresetSelected;

  const BeautyPresetsScreen({
    super.key,
    required this.controller,
    required this.selectedPresetId,
    required this.onPresetSelected,
  });

  @override
  State<BeautyPresetsScreen> createState() => _BeautyPresetsScreenState();
}

class _BeautyPresetsScreenState extends State<BeautyPresetsScreen> {
  late String _activePresetId;

  @override
  void initState() {
    super.initState();
    _activePresetId = widget.selectedPresetId;
  }

  void _showSaveCustomDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1D28),
        title: const Text('Save Custom Preset', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Preset Name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A6D)),
            child: const Text('Save'),
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                await widget.controller.saveAsPreset(textController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Beauty Presets', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
          childAspectRatio: 0.78,
        ),
        itemCount: kPresetItems.length + 1, // +1 for '+ Custom' card
        itemBuilder: (context, idx) {
          // '+ Custom' card as the last slot
          if (idx == kPresetItems.length) {
            return GestureDetector(
              onTap: _showSaveCustomDialog,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1E2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white70, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Custom',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }

          final item = kPresetItems[idx];
          final isSelected = item.id == _activePresetId;

          return GestureDetector(
            onTap: () async {
              setState(() => _activePresetId = item.id);
              widget.onPresetSelected(item.id);
              await widget.controller.applyPreset(item.preset);
            },
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF2A6D) : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: SafePortraitImage(
                          url: item.imageUrl,
                          borderRadius: BorderRadius.circular(13.5),
                        ),
                      ),
                      // Pink Checkmark Badge on Top Right
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF2A6D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFF2A6D) : Colors.white,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// SCREEN 8: LIVE STREAMING BROADCAST SCREEN (Matching UI Screen 8)
// ============================================================================
class LiveStreamBroadcastScreen extends StatefulWidget {
  final LiveBeautyController controller;

  const LiveStreamBroadcastScreen({super.key, required this.controller});

  @override
  State<LiveStreamBroadcastScreen> createState() => _LiveStreamBroadcastScreenState();
}

class _LiveStreamBroadcastScreenState extends State<LiveStreamBroadcastScreen>
    with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {'user': 'Emily', 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80', 'msg': 'You look so good! 😍'},
    {'user': 'Jason', 'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&q=80', 'msg': 'The filter looks natural! 👍'},
    {'user': 'Sofia', 'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80', 'msg': 'So pretty! 💕'},
  ];

  final List<Widget> _floatingHearts = [];
  bool _isMicOn = true;
  Timer? _liveTimer;
  int _secondsElapsed = 204; // 00:03:24

  @override
  void initState() {
    super.initState();
    widget.controller.startStreaming();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _chatController.dispose();
    widget.controller.stopStreaming();
    super.dispose();
  }

  void _addFloatingHeart() {
    final key = UniqueKey();
    setState(() {
      _floatingHearts.add(
        _FloatingHeartItem(
          key: key,
          onComplete: () {
            setState(() {
              _floatingHearts.removeWhere((item) => item.key == key);
            });
          },
        ),
      );
    });
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({
        'user': 'You',
        'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&q=80',
        'msg': _chatController.text.trim(),
      });
      _chatController.clear();
    });
  }

  String _formatTimer(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final s = totalSecs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Broadcast Camera Preview
          LiveBeautyPreview(
            controller: widget.controller,
            fit: BoxFit.cover,
          ),

          // Top Header: LIVE badge | Timer | Viewers Count (Matching Screen 8)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Red 'LIVE' Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2A6D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Timer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _formatTimer(_secondsElapsed),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Viewers count: '👁 1,248'
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('1,248', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Toolbar: Flip, Mic, Beauty Wand, '···' (Matching Screen 8)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withAlpha(40), width: 0.8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLiveActionIcon(
                        icon: Icons.flip_camera_ios,
                        onTap: () => widget.controller.switchCamera(),
                      ),
                      const SizedBox(height: 18),
                      _buildLiveActionIcon(
                        icon: _isMicOn ? Icons.mic : Icons.mic_off,
                        color: _isMicOn ? Colors.white : Colors.redAccent,
                        onTap: () => setState(() => _isMicOn = !_isMicOn),
                      ),
                      const SizedBox(height: 18),
                      _buildLiveActionIcon(
                        icon: Icons.auto_fix_high,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => BeautySettingsModalSheet(controller: widget.controller),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildLiveActionIcon(
                        icon: Icons.more_horiz,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Hearts Particles
          ..._floatingHearts,

          // Bottom Section: Live Chat stream & Input Bar
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat Messages List
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        reverse: true,
                        itemCount: _chatMessages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final msg = _chatMessages[_chatMessages.length - 1 - idx];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: SafePortraitImage(
                                    url: msg['avatar']!,
                                    isCircle: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  msg['user']!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    msg['msg']!,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bottom Bar: 'Type a message...' + Gift Box + Heart Like Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withAlpha(30), width: 0.8),
                            ),
                            child: TextField(
                              controller: _chatController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Gift Button
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withAlpha(30), width: 0.8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.card_giftcard, color: Color(0xFFFF5E7E), size: 22),
                            onPressed: () {
                              _addFloatingHeart();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Heart Like Button
                        GestureDetector(
                          onTap: _addFloatingHeart,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF2A6D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// Animated Floating Heart Particle
class _FloatingHeartItem extends StatefulWidget {
  final VoidCallback onComplete;

  const _FloatingHeartItem({super.key, required this.onComplete});

  @override
  State<_FloatingHeartItem> createState() => _FloatingHeartItemState();
}

class _FloatingHeartItemState extends State<_FloatingHeartItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  final double _randomX = (math.Random().nextDouble() - 0.5) * 60;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final progress = _anim.value;
        final dy = -280 * progress;
        final dx = _randomX * math.sin(progress * math.pi);
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        final scale = 0.8 + 0.4 * progress;

        return Positioned(
          right: 24 - dx,
          bottom: 70 - dy,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: const Icon(Icons.favorite, color: Color(0xFFFF2A6D), size: 28),
            ),
          ),
        );
      },
    );
  }
}
