//
//  FavoritesStore.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-18.
//

import Foundation
import Observation

/// The ids of favourited Pokémon, saved to UserDefaults so they survive relaunches.
/// Shared through the environment so the home filter and detail heart stay in sync.
@Observable
final class FavoritesStore {
    private static let key = "favoritePokemonIDs"
    private let defaults: UserDefaults
    private(set) var ids: Set<Int>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = Set(defaults.array(forKey: Self.key) as? [Int] ?? [])
    }

    func contains(_ id: Int) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: Int) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        defaults.set(Array(ids), forKey: Self.key)
    }
}
