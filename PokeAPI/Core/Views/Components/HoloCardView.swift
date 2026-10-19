//
//  HoloCardView.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-17.
//

import SwiftUI

/// A card you can drag to tilt in 3D. The content gets the current tilt so it can
/// put `.holoFoil(tilt:)` on whichever parts should shimmer.
struct HoloCardView<Content: View>: View {
    var width: CGFloat = 300
    /// defaults to a real Pokémon TCG card: 3 mm corners on a 63 mm wide card
    var cornerRadius: CGFloat?
    /// how far the card rotates at full tilt, in degrees
    var maxTilt: Double = 15
    /// the card's face, given the tilt (-1...1 on each axis)
    @ViewBuilder var content: (_ tilt: CGSize) -> Content

    @State private var tilt: CGSize = .zero
    @State private var isDragging = false

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius ?? width * 3 / 63)
    }

    var body: some View {
        content(tilt)
            .frame(width: width)
            .clipShape(cardShape)
            .shadow(
                color: .black.opacity(0.35),
                radius: 12,
                x: -tilt.width * 14,
                y: 10 - tilt.height * 14
            )
        .rotation3DEffect(.degrees(maxTilt * tilt.width), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(-maxTilt * tilt.height), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .scaleEffect(isDragging ? 1.04 : 1)
        .contentShape(cardShape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let range = width / 2
                    withAnimation(.interactiveSpring) {
                        isDragging = true
                        tilt = CGSize(
                            width: (value.translation.width / range).clamped(to: -1...1),
                            height: (value.translation.height / range).clamped(to: -1...1)
                        )
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.45)) {
                        isDragging = false
                        tilt = .zero
                    }
                }
        )
    }
}

/// Animatable so the foil follows the spring back to rest, not just the rotation.
private struct HoloFoilEffect: ViewModifier, Animatable {
    var tilt: CGSize
    let intensity: Double

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(tilt.width, tilt.height) }
        set { tilt = CGSize(width: newValue.first, height: newValue.second) }
    }

    func body(content: Content) -> some View {
        content
            .colorEffect(ShaderLibrary.holoFoil(
                .boundingRect,
                .float2(tilt.width, tilt.height),
                .float(intensity)
            ))
    }
}

extension View {
    /// Holo foil driven by a card's tilt (-1...1 on each axis); animates with it.
    func holoFoil(tilt: CGSize, intensity: Double = 0.6) -> some View {
        modifier(HoloFoilEffect(tilt: tilt, intensity: intensity))
    }

    /// Holo foil that shifts as the view scrolls across its scroll view, for places
    /// where a drag gesture would fight with scrolling.
    func scrollHoloFoil(intensity: Double = 0.6) -> some View {
        visualEffect { content, proxy in
            let frame = proxy.frame(in: .scrollView)
            let halfWidth = max((proxy.bounds(of: .scrollView)?.width ?? frame.width) / 2, 1)
            // -1 at the left edge of the scroll view, 0 in the center, 1 at the right edge
            let tilt = min(max((frame.midX - halfWidth) / halfWidth, -1), 1)
            return content.colorEffect(ShaderLibrary.holoFoil(
                .boundingRect,
                .float2(tilt, 0),
                .float(intensity)
            ))
        }
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    HoloCardView { tilt in
        Color.gray
            .holoFoil(tilt: tilt)
            .aspectRatio(63 / 88, contentMode: .fit)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(PokeYellowBackground())
}
