#version 300 es
precision highp float;

in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uTexture;
uniform vec2 uAspectRatio; // vec2(aspect, 1.0)

// Facial Landmark Anchors (normalized [0, 1])
uniform vec2 uLeftEyeCenter;
uniform vec2 uRightEyeCenter;
uniform vec2 uLeftCheek;
uniform vec2 uRightCheek;
uniform vec2 uLeftJaw;
uniform vec2 uRightJaw;
uniform vec2 uChin;
uniform vec2 uNoseCenter;

// Reshape Intensities (0.0 to 1.0)
uniform float uFaceSlimming;
uniform float uSmallFace;
uniform float uJawline;
uniform float uChinAdjustment;
uniform float uNoseSlimming;
uniform float uEyeEnlargement;

// Warping primitive: Local radial expansion/contraction
vec2 warpEnlarge(vec2 coord, vec2 center, float radius, float strength) {
    if (strength <= 0.001) return coord;
    vec2 delta = (coord - center) * uAspectRatio;
    float dist = length(delta);
    if (dist > radius || dist <= 0.0001) return coord;

    float factor = 1.0 - (dist / radius);
    float k = strength * 0.45;
    float offset = 1.0 - k * factor * factor;

    vec2 correctedDelta = (coord - center) * offset;
    return center + correctedDelta;
}

// Warping primitive: Directional push (e.g. slimming inwards towards face center)
vec2 warpPush(vec2 coord, vec2 fromPoint, vec2 toPoint, float radius, float strength) {
    if (strength <= 0.001) return coord;
    vec2 delta = (coord - fromPoint) * uAspectRatio;
    float dist = length(delta);
    if (dist > radius || dist <= 0.0001) return coord;

    float weight = 1.0 - (dist / radius);
    vec2 move = (toPoint - fromPoint) * weight * weight * strength * 0.6;
    return coord - move;
}

void main() {
    vec2 warpedCoord = vTexCoord;

    // 1. Eye Enlargement around left & right irises
    if (uEyeEnlargement > 0.0) {
        float eyeRadius = 0.09;
        warpedCoord = warpEnlarge(warpedCoord, uLeftEyeCenter, eyeRadius, uEyeEnlargement);
        warpedCoord = warpEnlarge(warpedCoord, uRightEyeCenter, eyeRadius, uEyeEnlargement);
    }

    // 2. Face Slimming (push cheeks inwards)
    if (uFaceSlimming > 0.0) {
        float cheekRadius = 0.16;
        vec2 faceMid = (uLeftCheek + uRightCheek) * 0.5;
        warpedCoord = warpPush(warpedCoord, uLeftCheek, faceMid, cheekRadius, uFaceSlimming * 0.4);
        warpedCoord = warpPush(warpedCoord, uRightCheek, faceMid, cheekRadius, uFaceSlimming * 0.4);
    }

    // 3. Jawline Sharpening & Small Face
    if (uJawline > 0.0 || uSmallFace > 0.0) {
        float jawRadius = 0.14;
        vec2 chinTarget = uChin + vec2(0.0, -0.02 * (uSmallFace + uJawline));
        warpedCoord = warpPush(warpedCoord, uLeftJaw, chinTarget, jawRadius, (uJawline + uSmallFace) * 0.25);
        warpedCoord = warpPush(warpedCoord, uRightJaw, chinTarget, jawRadius, (uJawline + uSmallFace) * 0.25);
    }

    // 4. Chin Adjustment (lift or lengthen)
    if (abs(uChinAdjustment - 0.5) > 0.02) {
        float chinRadius = 0.08;
        float dir = (uChinAdjustment - 0.5) * 2.0; // -1 (shorter) to +1 (longer)
        vec2 chinDelta = vec2(0.0, dir * 0.03);
        warpedCoord = warpPush(warpedCoord, uChin, uChin + chinDelta, chinRadius, abs(dir) * 0.4);
    }

    // 5. Nose Slimming
    if (uNoseSlimming > 0.0) {
        float noseRadius = 0.06;
        vec2 leftNostril = uNoseCenter + vec2(-0.025, 0.0);
        vec2 rightNostril = uNoseCenter + vec2(0.025, 0.0);
        warpedCoord = warpPush(warpedCoord, leftNostril, uNoseCenter, noseRadius, uNoseSlimming * 0.35);
        warpedCoord = warpPush(warpedCoord, rightNostril, uNoseCenter, noseRadius, uNoseSlimming * 0.35);
    }

    fragColor = texture(uTexture, clamp(warpedCoord, 0.0, 1.0));
}
