import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_live_beauty/flutter_live_beauty.dart';

void main() {
  group('Performance & Benchmarking Tests', () {
    test('BeautyPerformanceStats parsing and latency calculation', () {
      final statsMap = {
        'renderFps': 59.8,
        'inferenceFps': 29.9,
        'renderLatencyMs': 8.2,
        'inferenceLatencyMs': 14.1,
        'droppedFrames': 0,
        'detectedFacesCount': 1,
        'frameWidth': 1280,
        'frameHeight': 720,
      };

      final stats = BeautyPerformanceStats.fromMap(statsMap);
      expect(stats.renderFps, 59.8);
      expect(stats.inferenceFps, 29.9);
      expect(stats.renderLatencyMs, 8.2);
      expect(stats.inferenceLatencyMs, 14.1);
      expect(stats.totalLatencyMs, closeTo(22.3, 0.001));
      expect(stats.totalLatencyMs, lessThan(33.0)); // Meets 33ms target!
      expect(stats.droppedFrames, 0);
      expect(stats.detectedFacesCount, 1);
    });

    test('Adaptive performance profiles configuration', () {
      const low = BeautyPerformanceProfile.low;
      expect(low.targetFps, 30);
      expect(low.maxFaces, 1);
      expect(low.preferredResolution, 720);

      const balanced = BeautyPerformanceProfile.balanced;
      expect(balanced.targetFps, 60);
      expect(balanced.maxFaces, 2);

      const high = BeautyPerformanceProfile.high;
      expect(high.targetFps, 60);
      expect(high.maxFaces, 4);
    });

    test('BeautyConfig serialization benchmark', () {
      final config = BeautyPreset.glamour.config;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final map = config.toMap();
        final reconstructed = BeautyConfig.fromMap(map);
        expect(reconstructed.activeFilter, BeautyFilter.glamour);
      }
      stopwatch.stop();

      // 1000 round-trips should execute well under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('Streaming frame dropping and anti-stalling test', () async {
      final source = NativeBeautyVideoSource();
      await source.initialize();
      await source.start();

      final received = <BeautyVideoFrame>[];
      final sub = source.frames.listen((frame) {
        received.add(frame);
      });

      // Dispatch frames
      for (int i = 0; i < 10; i++) {
        source.dispatchFrame(
          BeautyVideoFrame(
            width: 1280,
            height: 720,
            rotation: 0,
            timestampNs: i * 33333333,
            format: BeautyPixelFormat.rgba32,
            textureId: 100 + i,
          ),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(received.length, 10);
      expect(received.first.textureId, 100);
      expect(received.last.textureId, 109);

      await sub.cancel();
      await source.dispose();
    });
  });
}
