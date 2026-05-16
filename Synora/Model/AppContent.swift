//
//  AppContent.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import Foundation

struct AppContent: Decodable {
    let defaultSettings: UserSettings
    let localizations: [String: [String: String]]
    let appInfoBullets: [String: [String]]

    static let shared =
        BundleJSONLoader.load(AppContent.self, resource: "AppContent")
        ?? AppContent.fallback

    func text(_ key: TextKey, language: AppLanguage) -> String {
        localizations[language.rawValue]?[key.rawValue] ?? key.rawValue
    }

    func texts(for key: TextKey) -> Set<String> {
        Set(localizations.values.compactMap { $0[key.rawValue] })
    }

    func infoBullets(language: AppLanguage) -> [String] {
        appInfoBullets[language.rawValue] ?? []
    }

    private static let fallback = AppContent(
        defaultSettings: UserSettings(language: .german, theme: .system),
        localizations: [:],
        appInfoBullets: [:]
    )
}
