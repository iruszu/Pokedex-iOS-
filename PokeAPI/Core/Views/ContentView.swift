//
//  ContentView.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import SwiftUI

enum PokemonFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favourites"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .all: "square.grid.2x2"
        case .favorites: "heart"
        }
    }
}

struct ContentView: View {
    @Environment(FavoritesStore.self) private var favorites
    @State private var viewModel = PokemonListViewModel()
    @State private var filter: PokemonFilter = .all
    /// id of the pokemon snapped to the center of the carousel
    @State private var selectedID: Int?

    private let cardSize: CGFloat = 220

    /// the list after the filter is applied; this is what the carousel shows
    private var displayedList: [PokemonListItem] {
        switch filter {
        case .all: viewModel.list
        case .favorites: viewModel.list.filter { favorites.contains($0.id) }
        }
    }

    private var selectedPokemon: PokemonListItem? {
        displayedList.first { $0.id == selectedID } ?? displayedList.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image("pokedex")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .accessibilityLabel("Pokédex")
                    .padding(.top)
                Spacer()
                if !displayedList.isEmpty {
                    carousel
                    selectedInfo
                } else if filter == .favorites && !viewModel.list.isEmpty {
                    ContentUnavailableView(
                        "No Favourites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on a Pokémon's card to add it here.")
                    )
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PokeYellowBackground())
            // the logo is the title; this is still used as the back button label on the detail screen
            .navigationTitle("Pokédex")
            .toolbar(removing: .title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
            .onChange(of: filter) {
                // the old selection may not be in the new list
                selectedID = displayedList.first?.id
            }
            .overlay {
                if viewModel.list.isEmpty {
                    if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView {
                            Label("Couldn't Load Pokédex", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Try Again") {
                                Task { await viewModel.fetchPokemonList() }
                            }
                        }
                    } else if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationDestination(for: PokemonListItem.self) { pokemon in
                PokemonDetailView(pokemonListItem: pokemon)
            }
            .task {
                await viewModel.fetchPokemonList()
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: $filter) {
                ForEach(PokemonFilter.allCases) { option in
                    Label(option.rawValue, systemImage: option.systemImage)
                        .tag(option)
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: filter == .all
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }

    private var carousel: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(displayedList) { pokemon in
                        NavigationLink(value: pokemon) {
                            PokemonCarouselCard(pokemon: pokemon, size: cardSize)
                        }
                        .buttonStyle(.plain)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.7)
                                .opacity(phase.isIdentity ? 1 : 0.5)
                                .rotation3DEffect(.degrees(phase.value * -30), axis: (x: 0, y: 1, z: 0))
                                .offset(y: phase.isIdentity ? 0 : 24)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            // padding on both sides so the first and last cards can sit in the center
            .safeAreaPadding(.horizontal, (proxy.size.width - cardSize) / 2)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedID, anchor: .center)
            .scrollIndicators(.hidden)
            .sensoryFeedback(.selection, trigger: selectedID)
        }
        .frame(height: cardSize + 40)
    }

    private var selectedInfo: some View {
        VStack(spacing: 4) {
            if let pokemon = selectedPokemon {
                Text(pokemon.name.capitalized)
                    .font(.largeTitle.bold())
                    .id(pokemon.id)
                    .transition(.blurReplace)
                Text(String(format: "#%03d", pokemon.id))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(pokemon.id)))
            }
        }
        .animation(.snappy, value: selectedPokemon?.id)
    }
}

/// The sprite in a circle, sized for the home carousel.
struct PokemonCarouselCard: View {
    let pokemon: PokemonListItem
    var size: CGFloat = 220

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .scrollHoloFoil()
                .shadow(color: .black.opacity(0.15), radius: 10, y: 8)
            AsyncImage(url: pokemon.spriteURL) { image in
                image
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .scrollHoloFoil()
            } placeholder: {
                ProgressView()
            }
            .padding(12)
        }
        .frame(width: size, height: size)
        // same silver frame as the art on the detail card
        .overlay {
            Circle().strokeBorder(.silverFrame, lineWidth: 4)
        }
        .contentShape(Circle())
    }
}

#Preview {
    ContentView()
        .environment(FavoritesStore())
}
