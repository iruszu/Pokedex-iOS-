//
//  RootTabView.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-18.
//

import SwiftUI

struct RootTabView: View {
    enum AppTab: Hashable {
        case pokedex, favorites, teams, settings
    }

    @State private var selectedTab: AppTab = .pokedex

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Pokédex", systemImage: "circle.circle.fill", value: .pokedex, role: .prominent) {
                ContentView()
            }

            // placeholders until we decide what goes here
            Tab("Favorites", systemImage: "heart", value: .favorites) {
                PlaceholderTabView(title: "Favorites", systemImage: "heart")
            }

            Tab("Teams", systemImage: "person.3", value: .teams) {
                PlaceholderTabView(title: "Teams", systemImage: "person.3")
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                PlaceholderTabView(title: "Settings", systemImage: "gearshape")
            }
        }
    }
}

/// Stand-in screen for tabs that don't have content yet.
private struct PlaceholderTabView: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("Coming soon"))
                .navigationTitle(title)
        }
    }
}

#Preview {
    RootTabView()
        .environment(FavoritesStore())
}
