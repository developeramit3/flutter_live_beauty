# Third-Party License Audit & Open-Source Compliance

The `flutter_live_beauty` SDK strictly adheres to open-source licensing principles. It **does NOT use** any proprietary, commercial, or paid beauty engines (e.g. Banuba, DeepAR, FaceUnity, Tencent Effect SDK). All components are fully permissive for commercial use and redistribution without recurring fees or cloud dependencies.

---

## 1. Computer Vision & Landmark Tracking

### Google MediaPipe Tasks Vision
- **Component**: `com.google.mediapipe:tasks-vision`
- **Models**: `face_landmarker.task` (MediaPipe 468 3D landmarks + 10 iris points)
- **License**: **Apache License, Version 2.0**
- **Commercial Redistribution**: Permitted without royalty fees.
- **Privacy & Telemetry**: Runs 100% on-device; no data is transmitted over the network.
- **Reference**: [https://developers.google.com/mediapipe](https://developers.google.com/mediapipe)

---

## 2. Native Graphics & Shaders

### Custom OpenGL ES 3.0 Shaders (Android)
- **Component**: High-pass bilateral filter, coordinate warp grid, and procedural color filters.
- **License**: **BSD-3-Clause** (Authored directly within this package).
- **Commercial Redistribution**: Free for use in commercial products.

### Custom Metal Shading Language (MSL) Shaders (iOS)
- **Component**: Compute and render pipelines for Metal on Apple devices.
- **License**: **BSD-3-Clause** (Authored directly within this package).
- **Commercial Redistribution**: Free for use in commercial products.

---

## 3. Native Platform Frameworks

### Android Platform Libraries
- `androidx.camera:camera-core` (Apache 2.0)
- `androidx.camera:camera-camera2` (Apache 2.0)
- `org.jetbrains.kotlinx:kotlinx-coroutines-android` (Apache 2.0)

### Apple iOS Platform Frameworks
- `AVFoundation` (Apple SDK System Framework - Standard iOS developer license)
- `Metal` / `CoreVideo` / `CoreMedia` (Apple SDK System Frameworks)

---

## 4. Streaming SDK Adapters

The streaming adapters (`AgoraBeautyVideoAdapter`, `ZegoBeautyVideoAdapter`, `LiveKitBeautyVideoAdapter`, `WebRtcBeautyVideoAdapter`) are modular, provider-independent integration shims licensed under **BSD-3-Clause**.
They do not bundle the third-party streaming binaries; users include their preferred streaming SDKs in their respective host applications.
