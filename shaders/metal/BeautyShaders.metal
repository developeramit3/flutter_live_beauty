#include <metal_stdlib>
using namespace metal;

// 1. Bilateral Skin Smoothing & Whitening Compute Kernel
kernel void skinBilateralFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &smoothIntensity [[buffer(0)]],
    constant float &whiteningIntensity [[buffer(1)]],
    constant float &glowIntensity [[buffer(2)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
        return;
    }

    float4 centerCol = inTexture.read(gid);
    if (smoothIntensity <= 0.01 && whiteningIntensity <= 0.01 && glowIntensity <= 0.01) {
        outTexture.write(centerCol, gid);
        return;
    }

    float centerLum = dot(centerCol.rgb, float3(0.299, 0.587, 0.114));
    float3 accum = float3(0.0);
    float totalW = 0.0;
    int radius = 2;

    for (int y = -radius; y <= radius; y++) {
        for (int x = -radius; x <= radius; x++) {
            int2 coord = int2(gid) + int2(x, y);
            coord.x = clamp(coord.x, 0, int(inTexture.get_width() - 1));
            coord.y = clamp(coord.y, 0, int(inTexture.get_height() - 1));

            float4 s = inTexture.read(uint2(coord));
            float sLum = dot(s.rgb, float3(0.299, 0.587, 0.114));

            float spatialDist = float(x*x + y*y);
            float rangeDist = abs(centerLum - sLum);

            float w = exp(-spatialDist / 6.0) * exp(-rangeDist / 0.2);
            accum += s.rgb * w;
            totalW += w;
        }
    }

    float3 blurred = accum / max(totalW, 0.0001);
    float3 res = mix(centerCol.rgb, blurred + (centerCol.rgb - blurred) * 0.35, smoothIntensity);

    // Whitening
    if (whiteningIntensity > 0.0) {
        res = mix(res, 1.0 - ((1.0 - res) * (1.0 - float3(whiteningIntensity * 0.35))), 0.8);
    }
    // Glow
    if (glowIntensity > 0.0) {
        res += pow(res, float3(1.4)) * 0.25 * glowIntensity;
    }

    outTexture.write(float4(clamp(res, 0.0, 1.0), centerCol.a), gid);
}

// 2. Face Reshaping & Eye Enlargement Compute Kernel
kernel void faceReshapeWarp(
    texture2d<float, access::sample> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float2 &leftEye [[buffer(0)]],
    constant float2 &rightEye [[buffer(1)]],
    constant float &eyeEnlarge [[buffer(2)]],
    constant float &faceSlim [[buffer(3)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    constexpr sampler s(coord::normalized, filter::linear, address::clamp_to_edge);
    float2 uv = float2(gid) / float2(outTexture.get_width(), outTexture.get_height());

    // Eye enlargement
    if (eyeEnlarge > 0.01) {
        float eyeRadius = 0.09;
        float distL = distance(uv, leftEye);
        if (distL < eyeRadius) {
            float f = 1.0 - (distL / eyeRadius);
            uv = leftEye + (uv - leftEye) * (1.0 - eyeEnlarge * 0.4 * f * f);
        }
        float distR = distance(uv, rightEye);
        if (distR < eyeRadius) {
            float f = 1.0 - (distR / eyeRadius);
            uv = rightEye + (uv - rightEye) * (1.0 - eyeEnlarge * 0.4 * f * f);
        }
    }

    float4 color = inTexture.sample(s, uv);
    outTexture.write(color, gid);
}

// 3. Predefined Color Filter Kernel
kernel void colorFilterKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant int &filterType [[buffer(0)]],
    constant float &intensity [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
        return;
    }

    float4 c = inTexture.read(gid);
    if (filterType == 0 || intensity <= 0.01) {
        outTexture.write(c, gid);
        return;
    }

    float3 res = c.rgb;
    if (filterType == 1) res = (res - 0.5) * 1.08 + 0.53; // Natural
    else if (filterType == 2) res += float3(0.08, 0.04, -0.03); // Warm
    else if (filterType == 3) res += float3(-0.04, 0.02, 0.08); // Cool
    else if (filterType == 7) res = (res - 0.5) * 1.2 + 0.52; // Glamour
    else if (filterType == 12) res = float3(dot(res, float3(0.299, 0.587, 0.114))); // B&W

    float3 finalColor = mix(c.rgb, res, intensity);
    outTexture.write(float4(clamp(finalColor, 0.0, 1.0), c.a), gid);
}
