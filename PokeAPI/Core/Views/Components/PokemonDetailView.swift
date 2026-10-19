//
//  PokemonDetailView.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import SwiftUI

struct PokemonDetailView: View {
    @Environment(FavoritesStore.self) private var favorites
    let pokemonListItem: PokemonListItem
    var service: PokemonService = .shared
    @State private var pokemon: Pokemon?
    @State private var errorMessage: String?

    var body: some View {

            VStack(spacing: 24) {
                HoloCardView { tilt in
                    PokemonCardView(item: pokemonListItem, pokemon: pokemon, tilt: tilt)
                }

                // kept outside the card so its drag gesture doesn't swallow the button
                if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load Details", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") {
                            Task { await loadPokemon() }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GrassBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    favoriteButton
                }
            }
            .task {
                await loadPokemon()
            }
    }
       

    private var isFavorite: Bool {
        favorites.contains(pokemonListItem.id)
    }

    private var favoriteButton: some View {
        Button {
            favorites.toggle(pokemonListItem.id)
        } label: {
            Label(
                isFavorite ? "Remove from Favourites" : "Add to Favourites",
                systemImage: isFavorite ? "heart.fill" : "heart"
            )
            .foregroundStyle(isFavorite ? .red : .primary)
            .contentTransition(.symbolEffect(.replace))
        }
        .sensoryFeedback(.impact, trigger: isFavorite)
    }

    private func loadPokemon() async {
        errorMessage = nil
        do {
            pokemon = try await service.fetchPokemon(id: pokemonListItem.id)
        } catch is CancellationError {
            // view went away, nothing to show
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        PokemonDetailView(
            pokemonListItem: PokemonListItem(
                name: "pikachu",
                url: URL(string: "https://pokeapi.co/api/v2/pokemon/25/")!
            )
        )
    }
    .environment(FavoritesStore())
}
