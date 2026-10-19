//
//  PokeYellow.metal
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Animated Pokémon-yellow gradient with a moving diagonal shine.
/// bounds = (x, y, width, height) of the view, time = seconds elapsed.
[[ stitchable ]] half4 pokeYellow(float2 position, half4 color, float4 bounds, float time) {
    float2 uv = (position - bounds.xy) / bounds.zw;

    half3 light = half3(1.0, 1.0, 1.0);      // white
    half3 deep  = half3(1.0, 0.867, 0.361);  // #FFDD5C, softened Pokémon yellow

    // Slow wavy blend from white (top) to yellow (bottom)
    float wave = sin(uv.x * 5.0 + time * 0.8) * 0.5 + sin(uv.y * 3.0 - time * 0.6) * 0.5;
    float t = clamp(uv.y + wave * 0.15, 0.0, 1.0);
    half3 c = mix(light, deep, half(t));

    // Diagonal metallic shine sweeping across
    float d = abs(fract(uv.x + uv.y * 0.5 - time * 0.12) - 0.5);
    float shine = 1.0 - smoothstep(0.0, 0.06, d);
    c += half3(shine * 0.25);

    return half4(c, 1.0);
}
