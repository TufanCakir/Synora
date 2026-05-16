//
//  ContrastThemeStore.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

struct ContrastThemeIndex: Decodable {
    let themes: [String: String]
}

struct ContrastTheme: Decodable {
    let editorBackground: String
    let editorBorder: String
    let markerOpacity: Double
    let toolbarBackground: String
}

struct ContrastThemeStore {
    static let shared = ContrastThemeStore()

    private let index: ContrastThemeIndex

    private init() {
        index =
            BundleJSONLoader.load(
                ContrastThemeIndex.self,
                resource: "ContrastThemes"
            )
            ?? ContrastThemeIndex(themes: [:])
    }

    func theme(for scheme: ColorScheme) -> ContrastTheme {
        let key = scheme == .dark ? "dark" : "light"
        let resource = index.themes[key] ?? "HighContrastLight"
        return BundleJSONLoader.load(ContrastTheme.self, resource: resource)
            ?? ContrastTheme(
                editorBackground: scheme == .dark ? "#000000" : "#FFFFFF",
                editorBorder: scheme == .dark ? "#FFFFFF" : "#000000",
                markerOpacity: scheme == .dark ? 0.50 : 0.42,
                toolbarBackground: scheme == .dark ? "#1C1C1E" : "#F2F2F2"
            )
    }
}

extension ContrastTheme {
    var editorBackgroundColor: Color { Color(contrastHex: editorBackground) }
    var editorBorderColor: Color { Color(contrastHex: editorBorder) }
    var toolbarBackgroundColor: Color { Color(contrastHex: toolbarBackground) }
}

extension Color {
    fileprivate init(contrastHex hex: String) {
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
