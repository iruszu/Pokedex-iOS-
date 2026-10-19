//
//  HoloFoil.metal
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-17.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static half3 hueToRGB(float h) {
    float3 k = abs(fract(float3(h) + float3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0;
    return half3(clamp(k, 0.0, 1.0));
}

static float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

/// Holographic foil with a diamond pattern, only drawn where the sprite is opaque.
/// bounds = (x, y, width, height), tilt = -1...1 on each axis, intensity = 0...1.
[[ stitchable ]] half4 holoFoil(float2 position, half4 color, float4 bounds, float2 tilt, float intensity) {
    if (color.a < 0.01) return color;
    float2 uv = (position - bounds.xy) / bounds.zw;

    // Diamond grid: a square grid rotated 45°
    float2 grid = float2(uv.x + uv.y, uv.x - uv.y) * 7.0;
    float2 cell = fract(grid) - 0.5;
    float edge = smoothstep(0.38, 0.5, max(abs(cell.x), abs(cell.y)));
    float cellRandom = hash(floor(grid));

    // Rainbow that slides across the sprite as it tilts
    float hue = uv.x * 0.6 + uv.y * 0.4 + tilt.x * 0.5 + tilt.y * 0.3 + cellRandom * 0.15;
    half3 rainbow = hueToRGB(hue);

    // Specular band that follows the tilt
    float band = abs(dot(uv - 0.5 + tilt * 0.6, normalize(float2(1.0, 1.0))));
    float shine = 1.0 - smoothstep(0.0, 0.3, band);

    // Some diamonds sparkle when the band passes over them
    float sparkle = step(0.85, cellRandom) * shine;

    float amount = intensity * (0.2 + 0.6 * shine + 0.4 * edge * shine);
    half3 base = color.rgb / color.a;

    // Multiply a rainbow tint so light areas (even pure white) pick up color
    half3 result = base * mix(half3(1.0), rainbow, half(amount * 0.6));

    // Screen-blend the shine and sparkles so dark areas still light up
    half3 glow = rainbow * half(shine * intensity * 0.4) + half3(sparkle * intensity * 0.6);
    result = 1.0 - (1.0 - result) * (1.0 - clamp(glow, 0.0h, 1.0h));

    // Back to premultiplied alpha
    return half4(result * color.a, color.a);
}
