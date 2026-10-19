//
//  GrassBackground.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-18.
//

import SwiftUI

struct GrassBackground: View {
    @State private var start = Date.now
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(start)
            Rectangle()
                .colorEffect(ShaderLibrary.grassField(.boundingRect, .float(time)))
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GrassBackground()
}
