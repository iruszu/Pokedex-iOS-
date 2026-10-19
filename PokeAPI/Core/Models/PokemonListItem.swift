//
//  PokemonListItem.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import Foundation

nonisolated struct PokemonListItem: Decodable, Hashable, Identifiable {
    let name: String
    let url: URL
    /// takes the "/26/" number without the slash
    var id: Int { Int(url.lastPathComponent) ?? 0 }
    var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
}
