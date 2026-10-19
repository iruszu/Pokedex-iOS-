//
//  Grass.metal
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-18.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float grassHash(float n) {
    return fract(sin(n * 127.1) * 43758.5453);
}

/// A meadow swaying in the wind: sky, hazy hills on the horizon, then many
/// overlapping rows of grass that get bigger, darker and windier toward the viewer.
/// bounds = (x, y, width, height) of the view, time = seconds elapsed.
[[ stitchable ]] half4 grassField(float2 position, half4 color, float4 bounds, float time) {
    float2 p = position - bounds.xy;
    float width = bounds.z;
    float height = bounds.w;
    float horizonY = height * 0.36;

    half3 haze = half3(0.78, 0.88, 0.70);

    // Sky: blue at the top, warm haze at the horizon, soft sun glow top right
    float skyT = clamp(p.y / horizonY, 0.0, 1.0);
    half3 c = mix(half3(0.52, 0.76, 0.98), half3(0.90, 0.95, 0.88), half(skyT * skyT));
    float sun = exp(-length(p - float2(width * 0.82, height * 0.06)) / (width * 0.35));
    c += half3(1.0, 0.95, 0.8) * half(sun * 0.35);

    // Rolling hills along the horizon
    float hill = horizonY - 18.0
        - sin(p.x * 0.012 + 1.3) * 10.0
        - sin(p.x * 0.031 + 4.0) * 5.0;
    if (p.y > hill) {
        c = mix(half3(0.55, 0.72, 0.52), haze, 0.45h);
    }

    // Ground between the blades: hazy near the horizon, deep shadow up close
    if (p.y > horizonY) {
        float g = clamp((p.y - horizonY) / (height - horizonY), 0.0, 1.0);
        c = mix(half3(0.50, 0.68, 0.38), half3(0.07, 0.20, 0.05), half(sqrt(g)));
    }

    // Rows of grass from the horizon (back) to the bottom edge (front).
    // Rows are spaced by depth squared so they bunch up in the distance like perspective.
    const int rows = 16;
    float range = height * 1.08 - horizonY;
    for (int i = 0; i < rows; i++) {
        float depth = float(i + 1) / float(rows);
        float baseY = horizonY + range * depth * depth;
        float near = baseY - horizonY;

        float spacing = mix(2.5, 15.0, depth);
        float bladeH  = 10.0 + near * 0.5;
        // distance to the next row, used to stagger roots so rows don't form lines
        float rowGap = range * 2.0 * depth / float(rows);

        // Shared wind for the whole row: a gust rolling across the screen, bigger up close
        float t0 = clamp((baseY - p.y) / bladeH, 0.0, 1.0);
        float gust = sin(time * 0.9 - p.x * 0.006 + float(i) * 0.15) * 0.7
                   + sin(time * 2.1 - p.x * 0.017) * 0.2;
        float windX = gust * bladeH * 0.16 * t0 * t0;

        // Work in "unbent" space so tall bending blades don't need many neighbour checks
        float x = p.x - windX + float(i) * 37.31;
        float cell = floor(x / spacing);

        for (int d = -1; d <= 1; d++) {
            float column = cell + float(d);
            float id = column * 1.618 + float(i) * 113.0;
            float r1 = grassHash(id);
            float r2 = grassHash(id + 1.7);
            float r3 = grassHash(id + 3.3);
            float r4 = grassHash(id + 5.9);
            float r5 = grassHash(id + 8.1);

            float rootY = baseY + (r5 - 0.5) * rowGap * 1.5;
            float h = bladeH * mix(0.5, 1.0, r1);
            float t = (rootY - p.y) / h;                 // 0 at the root, 1 at the tip
            if (t < 0.0 || t > 1.0) continue;

            // Each blade leans its own way, curving more toward the tip
            float lean = (r3 - 0.5) * spacing * 1.4 * t * t;
            float centerX = (column + 0.5 + (r2 - 0.5) * 0.8) * spacing + lean;
            float halfWidth = spacing * mix(0.32, 0.5, r4) * pow(1.0 - t, 0.85);
            float dx = x - centerX;
            if (abs(dx) > halfWidth) continue;

            // Colour varies between yellow-green and blue-green per blade
            half3 baseCol = mix(half3(0.30, 0.55, 0.12), half3(0.16, 0.50, 0.22), half(r2));
            half3 tipCol  = mix(half3(0.62, 0.80, 0.30), half3(0.45, 0.75, 0.38), half(r2));
            half3 blade = mix(baseCol, tipCol, half(t));

            // Darker at the roots where light can't reach
            blade *= half(mix(0.5, 1.0, smoothstep(0.0, 0.5, t)));

            // Light from the left, plus a faint midrib highlight
            float s = dx / halfWidth;                    // -1 left edge, 1 right edge
            blade *= half(1.05 - 0.25 * s);
            blade += half3(0.06) * half(1.0 - abs(s)) * half(t);

            // Distant rows fade into the haze
            float fog = pow(1.0 - depth, 2.2) * 0.85;
            blade = mix(blade, haze, half(fog));

            // Soft, anti-aliased edges
            float edge = clamp((halfWidth - abs(dx)) / 0.8, 0.0, 1.0);
            c = mix(c, blade, half(edge));
        }
    }

    return half4(c, 1.0);
}
