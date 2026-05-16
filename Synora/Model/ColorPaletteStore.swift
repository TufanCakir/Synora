//
//  ColorPaletteStore.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

struct ColorPalettesIndex: Decodable {
    let palettes: [String]
}

struct ColorPaletteFile: Decodable {
    let colors: [ColorDefinition]
}

struct ColorDefinition: Identifiable, Decodable, Equatable {
    let id: String
    let hex: String
    let roles: [ColorRole]
    let labels: [String: String]

    func label(for language: AppLanguage) -> String {
        labels[language.rawValue] ?? id
    }
}

enum ColorRole: String, Decodable {
    case pen
    case marker
}

struct ColorPaletteStore {
    static let shared = ColorPaletteStore()

    let colors: [ColorDefinition]

    var penColors: [NoteColor] {
        colors(for: .pen)
    }

    var markerColors: [NoteColor] {
        colors(for: .marker)
    }

    private init() {
        let index =
            BundleJSONLoader.load(
                ColorPalettesIndex.self,
                resource: "ColorPalettes"
            ) ?? ColorPalettesIndex(palettes: [])
        let loadedColors = index.palettes.flatMap { resource in
            BundleJSONLoader.load(ColorPaletteFile.self, resource: resource)?
                .colors ?? []
        }

        colors = loadedColors.isEmpty ? Self.fallbackColors : loadedColors
    }

    func color(for noteColor: NoteColor) -> Color {
        if noteColor == .primary {
            return .primary
        }

        guard let definition = definition(for: noteColor) else {
            return .primary
        }

        return Color(hex: definition.hex)
    }

    func label(for noteColor: NoteColor, language: AppLanguage) -> String {
        definition(for: noteColor)?.label(for: language) ?? noteColor.rawValue
    }

    private func colors(for role: ColorRole) -> [NoteColor] {
        colors
            .filter { $0.roles.contains(role) }
            .map { NoteColor(rawValue: $0.id) }
    }

    private func definition(for noteColor: NoteColor) -> ColorDefinition? {
        colors.first { $0.id == noteColor.rawValue }
    }

    private static let fallbackColors = [
        ColorDefinition(
            id: "primary",
            hex: "#111827",
            roles: [.pen],
            labels: ["english": "Default", "german": "Standard"]
        ),
        ColorDefinition(
            id: "blue",
            hex: "#3B82F6",
            roles: [.pen],
            labels: ["english": "Blue", "german": "Blau"]
        ),
        ColorDefinition(
            id: "yellow",
            hex: "#FACC15",
            roles: [.marker],
            labels: ["english": "Yellow", "german": "Gelb"]
        ),
    ]
}

extension Color {
    fileprivate init(hex: String) {
        let cleanedHex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var value: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double

        switch cleanedHex.count {
        case 8:
            red = Double((value & 0xFF00_0000) >> 24) / 255
            green = Double((value & 0x00FF_0000) >> 16) / 255
            blue = Double((value & 0x0000_FF00) >> 8) / 255
            opacity = Double(value & 0x0000_00FF) / 255
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
            opacity = 1
        default:
            red = 0
            green = 0
            blue = 0
            opacity = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
