# Changelog

All notable changes to `flutter_live_beauty` will be documented in this file.

## 1.0.0

- **Initial Production Release**.
- Decoupled Native Camera Engine:
  - Android: Native Camera2, zoom, flash torch, front/rear switching, OpenGL ES 3.0 external OES integration.
  - iOS: AVFoundation capture, AVCaptureVideoDataOutput, Metal texture caching.
- MediaPipe Face Landmarker Engine:
  - 468 3D landmarks + iris landmarks.
  - Asynchronous background thread inference decoupled from 60 FPS rendering.
  - Temporal Kalman / Exponential Moving Average landmark smoothing.
  - Multi-face tracking (1 to 4 faces).
- GPU Beauty Processing Pipeline:
  - 10 Skin Beauty Features: Skin smoothing (guided bilateral filter), whitening, glow, skin tone balance, blemish reduction, wrinkle reduction, dark circle reduction, skin texture preservation, facial brightness, and natural enhancement.
  - 11 Face Reshaping Features: Face slimming, small face effect, jawline sharpening, chin adjustment, cheek enhancement, cheekbone narrowing, forehead adjustment, face width, nose slimming, nose height, and nose bridge.
  - 8 Eye Enhancement Features: Eye enlargement, eye brightness, eye whitening, eye shape, eye spacing, eyebrow enhancement, eyelash enhancement, and under-eye smoothing.
  - Makeup Module: Lipstick with customizable colors, blush, eyeshadow, eyeliner, eyebrow tint, and highlighter.
  - 15 Predefined Color Grading Filters (Original, Natural, Warm, Cool, Vintage, Pink, Fresh, Glamour, Soft, Bright, Cinematic, Retro, Black & White, Golden, Dreamy).
  - 8 Predefined Built-in Beauty Presets (Natural, Glamour, Cute, Soft, Fresh, Professional, Fair, Korean).
  - Offline Local Preset Management: Save, load, rename, delete, and restore custom presets.
- Live-Streaming Native Output (`BeautyVideoSource`):
  - Zero-copy / low-overhead video frames dispatched to downstream encoders.
  - Anti-queue stalling policy dropping stale frames to maintain latency < 33ms.
  - Pre-built adapters and guides for Agora RTC, ZegoCloud Express, LiveKit, and WebRTC.
- Adaptive Performance Profiles (`low`, `balanced`, `high`).
- Comprehensive Flutter Example App featuring 4 complete screens.
