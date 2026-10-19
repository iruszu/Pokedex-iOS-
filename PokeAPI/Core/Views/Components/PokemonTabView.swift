//
//  PokemonTabView.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import SwiftUI

struct PokemonTabView: View {
    let pokemon: PokemonListItem
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: pokemon.spriteURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            .background(Circle().fill(.quaternary))
            VStack(alignment: .leading) {
                Text(pokemon.name.capitalized)
                    .bold()
                Text(String(format: "#%03d", pokemon.id))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PokemonTabView(
        pokemon: PokemonListItem(
            name: "pikachu",
            url: URL(string: "https://pokeapi.co/api/v2/pokemon/25/")!
        )
    )
}
