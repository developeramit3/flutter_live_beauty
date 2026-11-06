#version 300 es
precision highp float;

in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uTexture;
uniform vec2 uTexelSize;
uniform float uSmoothIntensity; // 0.0 to 1.0
uniform float uWhiteningIntensity; // 0.0 to 1.0
uniform float uGlowIntensity; // 0.0 to 1.0
uniform float uToneBalance; // 0.0 (Cool) to 1.0 (Warm), 0.5 is neutral
uniform float uMaskStrength; // 1.0 inside face/skin, 0.0 outside

// Bilateral filter weights for edge-preserving skin smoothing
float getLuminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec4 centerColor = texture(uTexture, vTexCoord);
    if (uSmoothIntensity <= 0.001 && uWhiteningIntensity <= 0.001 && uGlowIntensity <= 0.001) {
        fragColor = centerColor;
        return;
    }

    float centerLum = getLuminance(centerColor.rgb);
    vec3 accumColor = vec3(0.0);
    float totalWeight = 0.0;

    // Spatial + Range bilateral sampling radius
    float radius = 1.0 + uSmoothIntensity * 3.5;
    float rangeSigma = 0.15 + (1.0 - uSmoothIntensity) * 0.1;

    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * uTexelSize * radius;
            vec3 sampleCol = texture(uTexture, vTexCoord + offset).rgb;
            float sampleLum = getLuminance(sampleCol);

            float spatialDist = dot(vec2(x, y), vec2(x, y));
            float rangeDist = abs(centerLum - sampleLum);

            float weight = exp(-spatialDist / (2.0 * radius)) * exp(-rangeDist / (2.0 * rangeSigma));
            accumColor += sampleCol * weight;
            totalWeight += weight;
        }
    }

    vec3 blurred = accumColor / max(totalWeight, 0.0001);

    // High-frequency detail preservation (avoid plastic look)
    vec3 highPass = centerColor.rgb - blurred;
    vec3 smoothed = blurred + highPass * 0.35; // Preserve 35% micro-texture

    // Blend smoothing by user intensity and facial skin mask
    float effectiveSmooth = uSmoothIntensity * uMaskStrength;
    vec3 finalColor = mix(centerColor.rgb, smoothed, effectiveSmooth);

    // Skin Whitening / Luminance boost
    if (uWhiteningIntensity > 0.0) {
        float whiteFactor = uWhiteningIntensity * uMaskStrength * 0.4;
        finalColor = mix(finalColor, 1.0 - ((1.0 - finalColor) * (1.0 - vec3(whiteFactor))), 0.8);
    }

    // Glow / Highlight Radiance
    if (uGlowIntensity > 0.0) {
        vec3 glow = pow(finalColor, vec3(1.4)) * 0.3 * (uGlowIntensity * uMaskStrength);
        finalColor += glow;
    }

    // Tone Balance: cool (blue/cyan boost) or warm (amber/yellow boost)
    if (abs(uToneBalance - 0.5) > 0.01) {
        float toneShift = (uToneBalance - 0.5) * 2.0 * uMaskStrength * 0.25;
        if (toneShift > 0.0) {
            finalColor.r += toneShift * 0.6;
            finalColor.g += toneShift * 0.3;
        } else {
            finalColor.b += abs(toneShift) * 0.7;
        }
    }

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), centerColor.a);
}
