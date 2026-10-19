//
//  PokeAPIApp.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import SwiftUI

@main
struct PokeAPIApp: App {
    @State private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(favorites)
        }
    }
}
