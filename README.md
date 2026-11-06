# flutter_live_beauty

Production-ready Flutter Live Beauty SDK providing real-time beauty filters, facial reshaping, virtual makeup, and color grading for live-streaming applications on **Android** and **iOS**.

Users can preview their appearance in real time, customize individual facial parameters, apply beauty presets, and broadcast the **actual beauty-processed video frames** directly to viewers via **Agora**, **ZegoCloud**, **LiveKit**, or **WebRTC**.

---

## 🌟 Key Features

- **100% Free & Open-Source**: Zero paid SDKs, zero subscriptions, zero proprietary licensing, and zero cloud API dependencies.
- **On-Device Inference**: MediaPipe 468-point 3D Face Landmarker + iris tracking with temporal Kalman/EMA smoothing to eliminate jitter.
- **Hardware-Accelerated GPU Shaders**: Native OpenGL ES 3.0 (Android) and Metal Shading Language (iOS) render pipelines.
- **Dual Pipeline Output**:
  1. Zero-copy local camera preview for the Flutter UI (`LiveBeautyPreview`).
  2. Provider-independent frame dispatch (`BeautyVideoSource`) feeding live-streaming encoders.
- **Live-Streaming Ready**: First-class adapters for **Agora RTC**, **ZegoCloud Express**, **LiveKit**, and **WebRTC**.
- **Real-Time Performance**: Target 30-60 FPS rendering with end-to-end processing latency under 33 ms on supported hardware.
- **Anti-Queue Stalling**: Single-frame ring-buffer policy automatically drops stale frames to prevent stream lag.

---

## 📱 Platform Requirements

| Platform | Minimum Version | Graphics API | ML Inference |
| :--- | :--- | :--- | :--- |
| **Android** | API 24 (Android 7.0+) | OpenGL ES 3.0 | MediaPipe Tasks Vision |
| **iOS** | iOS 13.0+ | Metal | MediaPipe Tasks Vision / CoreVideo |

---

## 📦 Installation & Permissions

Add `flutter_live_beauty` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_live_beauty:
    path: ../flutter_live_beauty # or git/pub dependency
```

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:glEsVersion="0x00030000" android:required="true" />
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We require camera access to apply real-time beauty effects and stream video.</string>
```

---

## 🚀 Quick Start

### 1. Initialize Controller & Preview
```dart
import 'package:flutter/material.dart';
import 'package:flutter_live_beauty/flutter_live_beauty.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final LiveBeautyController _controller = LiveBeautyController();

  @override
  void initState() {
    super.initState();
    _initBeautySDK();
  }

  Future<void> _initBeautySDK() async {
    await _controller.initialize(
      cameraPosition: BeautyCameraPosition.front,
      resolution: BeautyResolution.hd720p,
    );

    // Apply beauty configuration
    await _controller.setBeauty(BeautyFeature.skinSmoothing, 60);
    await _controller.setBeauty(BeautyFeature.skinWhitening, 30);
    await _controller.setBeauty(BeautyFeature.faceSlimming, 25);
    await _controller.setFilter(BeautyFilter.natural, 70);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiveBeautyPreview(
        controller: _controller,
        fit: BoxFit.cover,
      ),
    );
  }
}
```

---

## 🎨 Feature Modules

### 1. Skin Beauty Enhancement (0 - 100 Intensity)
| Feature | Enum Value | Description |
| :--- | :--- | :--- |
| Skin Smoothing | `BeautyFeature.skinSmoothing` | Bilateral guided filter smoothing blemishes while preserving 35% natural micro-texture |
| Skin Whitening | `BeautyFeature.skinWhitening` | Luminance lift and skin tone brightening |
| Skin Glow | `BeautyFeature.skinGlow` | High-point facial highlight and radiance |
| Skin Tone Balance | `BeautyFeature.skinTone` | Cool vs warm complexion tone adjustment |
| Blemish Reduction | `BeautyFeature.blemishReduction` | Local frequency suppression of dark spots |
| Wrinkle Reduction | `BeautyFeature.wrinkleReduction` | Fine crease attenuation around eyes and forehead |
| Dark Circle Reduction | `BeautyFeature.darkCircleReduction` | Periorbital tear trough lightening |
| Skin Texture Preservation | `BeautyFeature.skinTexture` | Prevents over-smoothed "plastic" artificial looks |
| Facial Brightness | `BeautyFeature.facialBrightness` | Gamma adjustment for key facial illumination |
| Natural Enhancement | `BeautyFeature.naturalEnhancement` | Equalization of overall complexion |

### 2. Face Reshaping (0 - 100 Intensity)
| Feature | Enum Value | Description |
| :--- | :--- | :--- |
| Face Slimming | `BeautyFeature.faceSlimming` | Inward cheek compression |
| Small Face | `BeautyFeature.smallFace` | Proportional facial contraction |
| Jawline | `BeautyFeature.jawlineAdjustment` | Mandibular angle contour sharpening |
| Chin Adjustment | `BeautyFeature.chinAdjustment` | Mentalis vertical positioning (lift or lengthen) |
| Cheek Enhancement | `BeautyFeature.cheekEnhancement` | Zygomatic fullness and volume |
| Cheekbone Adjustment | `BeautyFeature.cheekboneAdjustment` | Zygomatic arch narrowing |
| Forehead Adjustment | `BeautyFeature.foreheadAdjustment` | Hairline to brow vertical proportion |
| Face Width | `BeautyFeature.faceWidth` | Mid-face lateral width compression |
| Nose Slimming | `BeautyFeature.noseSlimming` | Nasal ala nostril narrowing |
| Nose Height | `BeautyFeature.noseHeight` | Nasal tip vertical positioning |
| Nose Bridge | `BeautyFeature.noseBridge` | Nasal dorsum narrowing and highlight |

### 3. Eye Enhancement
- **Eye Enlargement**: Radial coordinate warping centered on iris coordinates (`BeautyFeature.eyeEnlargement`).
- **Eye Brightness**: Pupil reflection and corneal highlight boost (`BeautyFeature.eyeBrightness`).
- **Eye Whitening**: Sclera redness removal (`BeautyFeature.eyeWhitening`).
- **Under-Eye Smoothing**: Infraorbital crease smoothing (`BeautyFeature.underEyeSmoothing`).

### 4. Virtual Makeup Module
- **Lipstick**: Soft-light blending with specular highlight (`MakeupType.lipstick`). Supported colors: Red, Pink, Rose, Peach, Nude, Coral, Berry, and custom colors.
- **Blush**: Radial Gaussian feathering across cheek bones (`MakeupType.blush`).
- **Eyeshadow**: Gradient eyelid shading (`MakeupType.eyeshadow`).
- **Highlighter**: Nasal tip and cheekbone illumination (`MakeupType.highlighter`).

### 5. 15 Predefined GPU Color Grading Filters
1. `BeautyFilter.original`: Clean camera feed.
2. `BeautyFilter.natural`: Balanced contrast and warm vibrance.
3. `BeautyFilter.warm`: Golden hour amber tones.
4. `BeautyFilter.cool`: Crisp azure and cyan tones.
5. `BeautyFilter.vintage`: Nostalgic film curve and sepia undertones.
6. `BeautyFilter.pink`: Delicate pastel magenta highlights.
7. `BeautyFilter.fresh`: High-key brightness and saturated pop.
8. `BeautyFilter.glamour`: Studio rim contrast.
9. `BeautyFilter.soft`: Diffused glow and muted contrast.
10. `BeautyFilter.bright`: Lifted midtones.
11. `BeautyFilter.cinematic`: Teal & orange dual-tone grade.
12. `BeautyFilter.retro`: Faded blacks and 80s VHS warmth.
13. `BeautyFilter.blackAndWhite`: High-contrast monochrome.
14. `BeautyFilter.golden`: Rich honey highlights.
15. `BeautyFilter.dreamy`: Ethereal lavender haze.

### 6. Beauty Presets & Custom Presets
Apply 8 built-in studio presets with one method call:
- `BeautyPreset.natural`
- `BeautyPreset.glamour`
- `BeautyPreset.cute`
- `BeautyPreset.soft`
- `BeautyPreset.fresh`
- `BeautyPreset.professional`
- `BeautyPreset.fair`
- `BeautyPreset.korean`

```dart
// Apply a preset
await controller.applyPreset(BeautyPreset.korean);

// Save current settings as a custom preset
final custom = await controller.saveAsPreset('My Summer Vibe');

// Delete a custom preset
await controller.presetManager.deleteCustomPreset(custom.id);
```

---

## 📡 Live Streaming Integrations

The SDK exposes `controller.videoSource`, delivering beauty-processed frames directly to live-streaming SDKs:

- **Agora RTC**: `AgoraBeautyVideoAdapter` -> `pushExternalVideoFrame`
- **ZegoCloud**: `ZegoBeautyVideoAdapter` -> `sendCustomVideoCaptureRawData`
- **LiveKit**: `LiveKitBeautyVideoAdapter` -> `captureFrame`
- **Flutter WebRTC**: `WebRtcBeautyVideoAdapter` -> `captureByteFrame`

See [STREAMING_INTEGRATIONS.md](STREAMING_INTEGRATIONS.md) for complete copy-paste code snippets and setup instructions.

---

## ⚡ Adaptive Performance Profiles

To adapt to devices of varying GPU tiers:

```dart
// Low profile: 720p, 1 face, face inference at 15 FPS
await controller.setPerformanceProfile(BeautyPerformanceProfile.low);

// Balanced profile: 1080p, 2 faces, face inference at 30 FPS
await controller.setPerformanceProfile(BeautyPerformanceProfile.balanced);

// High profile: 1080p 60 FPS, 4 faces, multi-pass filtering
await controller.setPerformanceProfile(BeautyPerformanceProfile.high);
```

Listen to real-time performance telemetry:
```dart
controller.performanceStatsStream.listen((stats) {
  print('Render FPS: ${stats.renderFps}');
  print('Shader Latency: ${stats.renderLatencyMs} ms');
  print('Inference Latency: ${stats.inferenceLatencyMs} ms');
  print('Dropped Frames: ${stats.droppedFrames}');
});
```

---

## 🔒 Privacy & Security

- All video frames and face landmarks are processed **strictly on-device**.
- No facial geometry, biometric signatures, or video frames are ever recorded or uploaded to the cloud.
- Zero network permissions required by the core beauty engine.

---

## 📄 License & Third-Party Audit

This SDK is released under the **BSD-3-Clause License**. See [LICENSE](LICENSE) and [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
- **Google MediaPipe**: Apache 2.0 (Commercial use permitted).
- **Custom Shaders**: BSD-3-Clause.
- **Zero Paid Dependencies**: Strictly free of Banuba, DeepAR, FaceUnity, or Tencent Effect SDK.
