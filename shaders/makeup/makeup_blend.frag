#version 300 es
precision highp float;

in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uTexture;
uniform vec2 uAspectRatio;

// Lip Center and Radius
uniform vec2 uLipCenter;
uniform float uLipRadius;
uniform vec4 uLipstickColor; // RGBA
uniform float uLipstickIntensity;

// Cheek Blush
uniform vec2 uLeftBlushCenter;
uniform vec2 uRightBlushCenter;
uniform vec4 uBlushColor;
uniform float uBlushIntensity;

// Highlighter
uniform vec2 uNoseTip;
uniform vec4 uHighlighterColor;
uniform float uHighlighterIntensity;

// Soft Light Blending Formula
vec3 blendSoftLight(vec3 base, vec3 blend) {
    return mix(
        2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
        sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend),
        step(0.5, blend)
    );
}

void main() {
    vec4 baseColor = texture(uTexture, vTexCoord);
    vec3 result = baseColor.rgb;

    // 1. Lipstick layer
    if (uLipstickIntensity > 0.0 && uLipstickColor.a > 0.0) {
        vec2 lipDelta = (vTexCoord - uLipCenter) * uAspectRatio;
        // Elliptical lip bounding approximation
        float lipDist = dot(lipDelta * vec2(1.0, 1.8), lipDelta * vec2(1.0, 1.8));
        float lipRadiusSq = uLipRadius * uLipRadius;

        if (lipDist < lipRadiusSq) {
            float lipMask = smoothstep(lipRadiusSq, lipRadiusSq * 0.4, lipDist);
            float alpha = lipMask * uLipstickIntensity * uLipstickColor.a;
            vec3 blended = blendSoftLight(result, uLipstickColor.rgb);
            // Specular lip gloss highlight
            float gloss = pow(max(0.0, 1.0 - lipDist / lipRadiusSq), 4.0) * 0.2;
            result = mix(result, blended + vec3(gloss), alpha);
        }
    }

    // 2. Cheek Blush layer
    if (uBlushIntensity > 0.0 && uBlushColor.a > 0.0) {
        float blushRadius = 0.08;
        vec2 leftDelta = (vTexCoord - uLeftBlushCenter) * uAspectRatio;
        vec2 rightDelta = (vTexCoord - uRightBlushCenter) * uAspectRatio;
        float distL = length(leftDelta);
        float distR = length(rightDelta);

        float maskL = smoothstep(blushRadius, 0.0, distL);
        float maskR = smoothstep(blushRadius, 0.0, distR);
        float blushAlpha = max(maskL, maskR) * uBlushIntensity * uBlushColor.a * 0.7;

        result = mix(result, blendSoftLight(result, uBlushColor.rgb), blushAlpha);
    }

    // 3. Highlighter layer
    if (uHighlighterIntensity > 0.0) {
        vec2 noseDelta = (vTexCoord - uNoseTip) * uAspectRatio;
        float noseDist = length(noseDelta);
        if (noseDist < 0.035) {
            float hlMask = smoothstep(0.035, 0.0, noseDist) * uHighlighterIntensity * 0.5;
            result += uHighlighterColor.rgb * hlMask;
        }
    }

    fragColor = vec4(clamp(result, 0.0, 1.0), baseColor.a);
}
