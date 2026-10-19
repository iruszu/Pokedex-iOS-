//
//  PokeYellowBackground.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import SwiftUI

struct PokeYellowBackground: View {
    @State private var start = Date.now
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(start)
            Rectangle()
                .colorEffect(ShaderLibrary.pokeYellow(.boundingRect, .float(time)))
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PokeYellowBackground()
}
