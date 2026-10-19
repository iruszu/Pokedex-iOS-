//
//  PokemonCardView.swift
//  PokeAPI
//
//  Created by Kellie Ho on 2026-10-18.
//

import SwiftUI

/// The face of a Pokémon trading card, laid out like the real TCG cards:
/// yellow border, name + HP + type, framed art, info strip, stats as "attacks",
/// then a type / total row and the set number.
struct PokemonCardView: View {
    let item: PokemonListItem
    /// nil while the details are still loading
    let pokemon: Pokemon?
    /// from HoloCardView, drives the foil on the border and art
    var tilt: CGSize = .zero

    private var types: [String] {
        pokemon?.types.sorted { $0.slot < $1.slot }.map(\.type.name) ?? []
    }
    private var style: PokemonTypeStyle { PokemonTypeStyle(types.first) }
    private var rarity: CardRarity { CardRarity(id: item.id) }

    private func stat(_ name: String) -> Int? {
        pokemon?.stats.first { $0.stat.name == name }?.baseStat
    }

    var body: some View {
        VStack(spacing: 6) {
            header
            artWindow
            infoStrip
            attacks
            Spacer(minLength: 0)
            hairline
            bottomRow
            footer
        }
        .padding(8)
        .background(
            LinearGradient(
                colors: [style.color.mix(with: .white, by: 0.55), style.color.mix(with: .white, by: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .padding(10)
        .background {
            // the border: type coloured, or gold / rainbow for special Pokémon
            LinearGradient(colors: borderColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .holoFoil(tilt: tilt, intensity: borderFoil)
        }
        .aspectRatio(63 / 88, contentMode: .fit)
        .foregroundStyle(.black)
    }

    /// mythical cards get the strongest shimmer; gold stays readable as gold
    private var borderFoil: Double {
        switch rarity {
        case .regular: 0.35
        case .legendary: 0.5
        case .mythical: 0.8
        }
    }

    private var borderColors: [Color] {
        switch rarity {
        case .legendary:
            return [0xFFF1A8, 0xE8B530, 0xB8860B, 0xF6D365].map { Color(hex: $0) }
        case .mythical:
            return [0xFFB3D9, 0xC3A6FF, 0x9EE6FF, 0xFFE29E].map { Color(hex: $0) }
        case .regular:
            // plain silver until the type is known
            guard !types.isEmpty else {
                return [0xF4F4F4, 0xBDBDBD, 0x9C9C9C, 0xE2E2E2].map { Color(hex: $0) }
            }
            let c = style.color
            return [c.mix(with: .white, by: 0.45), c, c.mix(with: .black, by: 0.2), c.mix(with: .white, by: 0.3)]
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 4) {
            Text(item.name.capitalized)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text("HP")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(Color(hex: 0xC8302C))
            Text(stat("hp").map(String.init) ?? "--")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(Color(hex: 0xC8302C))
            ForEach(types, id: \.self) { type in
                EnergyIcon(style: PokemonTypeStyle(type), size: 22)
            }
        }
    }

    private var artWindow: some View {
        ZStack {
            LinearGradient(
                colors: [.white, style.color.mix(with: .white, by: 0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .holoFoil(tilt: tilt, intensity: 0.5)

            AsyncImage(url: pokemon?.sprites.frontDefault ?? item.spriteURL) { image in
                image
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .holoFoil(tilt: tilt, intensity: 0.4)
            } placeholder: {
                ProgressView()
            }
            .padding(4)
        }
        .frame(height: 166)
        .clipShape(Rectangle())
        .overlay {
            // silver frame around the art
            Rectangle().strokeBorder(.silverFrame, lineWidth: 4)
        }
        .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
    }

    private var infoStrip: some View {
        Text(infoText)
            .font(.system(size: 9, weight: .semibold).italic())
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xD9D9D9), Color(hex: 0xF5F5F5), Color(hex: 0xC9C9C9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal, 12)
    }

    private var infoText: String {
        var parts = [String(format: "NO. %03d", item.id)]
        if let type = types.first {
            parts.append("\(type.capitalized) Pokémon")
        }
        if let pokemon {
            parts.append(String(format: "HT: %.1f m", Double(pokemon.height) / 10))
            parts.append(String(format: "WT: %.1f kg", Double(pokemon.weight) / 10))
        }
        return parts.joined(separator: "   ")
    }

    /// The stats laid out like a card's attacks: cost, name, damage.
    @ViewBuilder
    private var attacks: some View {
        if let pokemon {
            VStack(spacing: 4) {
                ForEach(pokemon.stats.filter { $0.stat.name != "hp" }, id: \.stat.name) { entry in
                    HStack(spacing: 6) {
                        EnergyIcon(style: style, size: 14)
                        Text(Self.statName(entry.stat.name))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        Spacer()
                        Text("\(entry.baseStat)")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .monospacedDigit()
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 100)
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(.black.opacity(0.25))
            .frame(height: 1)
    }

    /// Where weakness / resistance / retreat go on a real card.
    private var bottomRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                label("type")
                HStack(spacing: 3) {
                    ForEach(types, id: \.self) { type in
                        EnergyIcon(style: PokemonTypeStyle(type), size: 14)
                    }
                }
                .frame(height: 14)
            }
            Spacer()
            VStack(spacing: 2) {
                label("base total")
                Text(pokemon.map { String($0.stats.reduce(0) { $0 + $1.baseStat }) } ?? "--")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .frame(height: 14)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                label("speed")
                Text(stat("speed").map(String.init) ?? "--")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .frame(height: 14)
            }
        }
        .padding(.horizontal, 4)
    }

    private var footer: some View {
        HStack {
            Text("PokéAPI")
                .italic()
            Spacer()
            Text(String(format: "%03d/151", item.id))
            if rarity != .regular {
                // rarity mark, like the star on rare cards
                Image(systemName: "star.fill")
                    .foregroundStyle(.black.opacity(0.8))
            }
        }
        .font(.system(size: 8, weight: .semibold))
        .foregroundStyle(.black.opacity(0.6))
        .padding(.horizontal, 4)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.black.opacity(0.7))
    }

    private static func statName(_ name: String) -> String {
        switch name {
        case "attack": "Attack"
        case "defense": "Defense"
        case "special-attack": "Sp. Attack"
        case "special-defense": "Sp. Defense"
        case "speed": "Speed"
        default: name.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
}

/// Special cards get their own border instead of the type colour.
enum CardRarity {
    case regular, legendary, mythical

    init(id: Int) {
        switch id {
        case 144, 145, 146, 150: self = .legendary   // Articuno, Zapdos, Moltres, Mewtwo
        case 151: self = .mythical                   // Mew
        default: self = .regular
        }
    }
}

/// A type's colour and symbol, used for the card colours and energy icons.
struct PokemonTypeStyle {
    let color: Color
    let symbol: String

    init(_ type: String?) {
        switch type {
        case "fire":     (color, symbol) = (Color(hex: 0xEE8130), "flame.fill")
        case "water":    (color, symbol) = (Color(hex: 0x6390F0), "drop.fill")
        case "grass":    (color, symbol) = (Color(hex: 0x7AC74C), "leaf.fill")
        case "electric": (color, symbol) = (Color(hex: 0xF7D02C), "bolt.fill")
        case "ice":      (color, symbol) = (Color(hex: 0x96D9D6), "snowflake")
        case "fighting": (color, symbol) = (Color(hex: 0xC22E28), "figure.boxing")
        case "poison":   (color, symbol) = (Color(hex: 0xA33EA1), "smoke.fill")
        case "ground":   (color, symbol) = (Color(hex: 0xE2BF65), "mountain.2.fill")
        case "flying":   (color, symbol) = (Color(hex: 0xA98FF3), "wind")
        case "psychic":  (color, symbol) = (Color(hex: 0xF95587), "eye.fill")
        case "bug":      (color, symbol) = (Color(hex: 0xA6B91A), "ladybug.fill")
        case "rock":     (color, symbol) = (Color(hex: 0xB6A136), "hexagon.fill")
        case "ghost":    (color, symbol) = (Color(hex: 0x735797), "moon.fill")
        case "dragon":   (color, symbol) = (Color(hex: 0x6F35FC), "lizard.fill")
        case "dark":     (color, symbol) = (Color(hex: 0x705746), "moon.stars.fill")
        case "steel":    (color, symbol) = (Color(hex: 0xB7B7CE), "shield.fill")
        case "fairy":    (color, symbol) = (Color(hex: 0xD685AD), "sparkles")
        default:         (color, symbol) = (Color(hex: 0xA8A77A), "star.fill")
        }
    }
}

/// A round energy symbol like the ones on TCG cards.
struct EnergyIcon: View {
    let style: PokemonTypeStyle
    var size: CGFloat = 20

    var body: some View {
        Image(systemName: style.symbol)
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(style.color.gradient, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: size / 14))
            .shadow(color: .black.opacity(0.3), radius: 0.5, y: 0.5)
    }
}

extension ShapeStyle where Self == LinearGradient {
    /// the brushed-silver frame around a card's art
    static var silverFrame: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xF4F4F4), Color(hex: 0x9C9C9C), Color(hex: 0xE2E2E2), Color(hex: 0x8A8A8A)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

#Preview {
    HoloCardView { tilt in
        PokemonCardView(
            item: PokemonListItem(name: "pikachu", url: URL(string: "https://pokeapi.co/api/v2/pokemon/25/")!),
            pokemon: nil,
            tilt: tilt
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(GrassBackground())
}
