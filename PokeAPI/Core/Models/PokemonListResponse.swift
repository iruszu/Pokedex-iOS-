//
//  PokemonListResponse.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import Foundation

nonisolated struct PokemonListResponse: Decodable {
    let count: Int
    let next: URL?
    let previous: URL?
    let results: [PokemonListItem]
}
