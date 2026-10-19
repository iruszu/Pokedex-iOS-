//
//  PokemonService.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-04.
//

import Foundation

nonisolated enum PokemonServiceError: LocalizedError {
    case invalidResponse
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server sent an invalid response."
        case .badStatus(let code): "The server returned an error (\(code))."
        }
    }
}

actor PokemonService {
    /// shared instance so the detail cache is reused across screens
    static let shared = PokemonService()

    private let baseURL = URL(string: "https://pokeapi.co/api/v2/")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private var detailCache: [Int: Pokemon] = [:]

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    /// initial fetch for the home screen list
    func fetchPokemonList(limit: Int = 151) async throws -> [PokemonListItem] {
        let response: PokemonListResponse = try await request(
            "pokemon",
            query: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
        return response.results
    }

    /// fetch for the details of a specific pokemon, cached after the first load
    func fetchPokemon(id: Int) async throws -> Pokemon {
        if let cached = detailCache[id] { return cached }
        let pokemon: Pokemon = try await request("pokemon/\(id)")
        detailCache[id] = pokemon
        return pokemon
    }

    private func request<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var url = baseURL.appending(path: path)
        if !query.isEmpty { url.append(queryItems: query) }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw PokemonServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PokemonServiceError.badStatus(http.statusCode)
        }
        return try decoder.decode(T.self, from: data)
    }
}
