#version 300 es
precision highp float;

in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uTexture;
uniform int uFilterType; // 0=Original, 1=Natural, 2=Warm, 3=Cool, 4=Vintage, 5=Pink, 6=Fresh, 7=Glamour, 8=Soft, 9=Bright, 10=Cinematic, 11=Retro, 12=B&W, 13=Golden, 14=Dreamy
uniform float uFilterIntensity; // 0.0 to 1.0

vec3 adjustBrightnessContrast(vec3 color, float brightness, float contrast) {
    return (color - 0.5) * contrast + 0.5 + brightness;
}

vec3 adjustSaturation(vec3 color, float sat) {
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(lum), color, sat);
}

void main() {
    vec4 baseColor = texture(uTexture, vTexCoord);
    if (uFilterType == 0 || uFilterIntensity <= 0.001) {
        fragColor = baseColor;
        return;
    }

    vec3 c = baseColor.rgb;
    vec3 filtered = c;

    switch (uFilterType) {
        case 1: // Natural: subtle warm vibrance
            filtered = adjustBrightnessContrast(c, 0.03, 1.05);
            filtered = adjustSaturation(filtered, 1.12);
            filtered.r += 0.02;
            break;

        case 2: // Warm: golden hour amber tone
            filtered = adjustSaturation(c, 1.15);
            filtered.r += 0.08;
            filtered.g += 0.04;
            filtered.b -= 0.03;
            break;

        case 3: // Cool: clean cyan / azure tone
            filtered = adjustSaturation(c, 1.08);
            filtered.r -= 0.04;
            filtered.g += 0.02;
            filtered.b += 0.09;
            break;

        case 4: // Vintage: muted shadows, faded sepia
            float lumV = dot(c, vec3(0.299, 0.587, 0.114));
            vec3 sepia = vec3(lumV * 1.1, lumV * 0.95, lumV * 0.82);
            filtered = mix(c, sepia, 0.45);
            filtered = adjustBrightnessContrast(filtered, 0.02, 0.92);
            break;

        case 5: // Pink: soft pastel magenta highlights
            filtered = adjustBrightnessContrast(c, 0.04, 1.02);
            filtered.r += 0.09;
            filtered.b += 0.05;
            filtered = adjustSaturation(filtered, 1.1);
            break;

        case 6: // Fresh: bright daylight with pop
            filtered = adjustBrightnessContrast(c, 0.06, 1.08);
            filtered = adjustSaturation(filtered, 1.25);
            break;

        case 7: // Glamour: dramatic studio lighting, high contrast
            filtered = adjustBrightnessContrast(c, 0.02, 1.2);
            filtered = adjustSaturation(filtered, 1.18);
            filtered.r += 0.03;
            filtered.g += 0.01;
            break;

        case 8: // Soft: diffused high-key glow, low contrast
            filtered = adjustBrightnessContrast(c, 0.07, 0.9);
            filtered = adjustSaturation(filtered, 0.95);
            break;

        case 9: // Bright: lifted midtones and elevated gamma
            filtered = pow(c, vec3(0.85)) + vec3(0.04);
            break;

        case 10: // Cinematic: teal & orange dual-tone
            vec3 tealOrange = c;
            tealOrange.r = pow(tealOrange.r, 0.9) * 1.1; // Orange skin/highlights
            tealOrange.b = pow(tealOrange.b, 1.15) * 1.15; // Teal shadows
            tealOrange.g = pow(tealOrange.g, 1.05);
            filtered = adjustBrightnessContrast(tealOrange, 0.0, 1.15);
            break;

        case 11: // Retro: faded blacks, punchy reds
            filtered = adjustBrightnessContrast(c, 0.05, 1.1);
            filtered.r *= 1.15;
            filtered.b *= 0.88;
            filtered = max(filtered, vec3(0.05)); // Lifted blacks
            break;

        case 12: // Black and White: high dynamic range monochrome
            float bw = dot(c, vec3(0.299, 0.587, 0.114));
            filtered = adjustBrightnessContrast(vec3(bw), 0.02, 1.25);
            break;

        case 13: // Golden: rich honey highlights
            filtered = adjustBrightnessContrast(c, 0.04, 1.06);
            filtered.r += 0.12;
            filtered.g += 0.08;
            filtered.b -= 0.04;
            break;

        case 14: // Dreamy: soft lavender haze
            filtered = adjustBrightnessContrast(c, 0.08, 0.94);
            filtered.r += 0.05;
            filtered.b += 0.08;
            break;

        default:
            filtered = c;
            break;
    }

    vec3 finalColor = mix(c, filtered, uFilterIntensity);
    fragColor = vec4(clamp(finalColor, 0.0, 1.0), baseColor.a);
}
