//
//  Pokemon.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import Foundation

/// Details from /pokemon/{id or name}
/// snake_case keys are converted by the service's decoder
nonisolated struct Pokemon: Decodable, Hashable, Identifiable {
    let id: Int
    let name: String
    /// in decimetres
    let height: Int
    /// in hectograms
    let weight: Int
    let sprites: Sprites
    let types: [TypeEntry]
    let stats: [StatEntry]

    struct Sprites: Decodable, Hashable {
        let frontDefault: URL?
        let frontShiny: URL?
    }

    struct TypeEntry: Decodable, Hashable {
        let slot: Int
        let type: NamedResource
    }

    struct StatEntry: Decodable, Hashable {
        let baseStat: Int
        let stat: NamedResource
    }
}

/// The { "name", "url" } shape PokeAPI uses for links to other resources
nonisolated struct NamedResource: Decodable, Hashable {
    let name: String
    let url: URL
}
