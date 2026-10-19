//
//  PokemonListViewModel.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import Foundation
import Observation

@Observable
@MainActor
class PokemonListViewModel {
    private let service: PokemonService
    private(set) var list: [PokemonListItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(service: PokemonService = .shared) {
        self.service = service
    }

    func fetchPokemonList() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            list = try await service.fetchPokemonList()
        } catch is CancellationError {
            // view went away, nothing to show
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
