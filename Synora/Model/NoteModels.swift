//
//  NoteModels.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

struct NotesDocument: Codable, Equatable {

    var tabs: [NoteTab]

    static let defaults =
        BundleJSONLoader.load(NotesDocument.self, resource: "DefaultNotes")
        ?? NotesDocument(tabs: [])
}

struct NoteTab: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var titleKey: TextKey?
    var notes: [Note]

    init(
        id: UUID = UUID(),
        title: String,
        titleKey: TextKey? = nil,
        notes: [Note] = []
    ) {
        self.id = id
        self.title = title
        self.titleKey = titleKey
        self.notes = notes
    }
}

struct Note: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var titleKey: TextKey?
    var body: String
    var bodyKey: TextKey?
    var style: NoteStyle
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        titleKey: TextKey? = nil,
        body: String = "",
        bodyKey: TextKey? = nil,
        style: NoteStyle = NoteStyle(),
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.titleKey = titleKey
        self.body = body
        self.bodyKey = bodyKey
        self.style = style
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct NoteStyle: Codable, Equatable {
    var textColor: NoteColor
    var markerColor: NoteColor
    var isMarked: Bool
    var fontSize: Double

    init(
        textColor: NoteColor = .primary,
        markerColor: NoteColor = .yellow,
        isMarked: Bool = false,
        fontSize: Double = 18
    ) {
        self.textColor = textColor
        self.markerColor = markerColor
        self.isMarked = isMarked
        self.fontSize = fontSize
    }
}

struct NoteColor: RawRepresentable, Identifiable, Codable, Equatable, Hashable {
    var rawValue: String

    static let primary = NoteColor(rawValue: "primary")
    static let red = NoteColor(rawValue: "red")
    static let orange = NoteColor(rawValue: "orange")
    static let yellow = NoteColor(rawValue: "yellow")
    static let green = NoteColor(rawValue: "green")
    static let blue = NoteColor(rawValue: "blue")
    static let purple = NoteColor(rawValue: "purple")
    static let pink = NoteColor(rawValue: "pink")

    var id: String { rawValue }

    func label(for language: AppLanguage) -> String {
        ColorPaletteStore.shared.label(for: self, language: language)
    }

    var color: Color {
        ColorPaletteStore.shared.color(for: self)
    }
}

struct UserSettings: Codable, Equatable {
    var language: AppLanguage
    var theme: AppTheme
    var highContrast: Bool
    var largeEditorText: Bool
    var largeControls: Bool
    var lineSpacing: AppLineSpacing
    var dyslexiaFriendlyFont: Bool
    var hapticFeedback: Bool

    static let defaults = AppContent.shared.defaultSettings

    init(
        language: AppLanguage,
        theme: AppTheme,
        highContrast: Bool = false,
        largeEditorText: Bool = false,
        largeControls: Bool = false,
        lineSpacing: AppLineSpacing = .normal,
        dyslexiaFriendlyFont: Bool = false,
        hapticFeedback: Bool = true
    ) {
        self.language = language
        self.theme = theme
        self.highContrast = highContrast
        self.largeEditorText = largeEditorText
        self.largeControls = largeControls
        self.lineSpacing = lineSpacing
        self.dyslexiaFriendlyFont = dyslexiaFriendlyFont
        self.hapticFeedback = hapticFeedback
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language =
            try container.decodeIfPresent(AppLanguage.self, forKey: .language)
            ?? .german
        theme =
            try container.decodeIfPresent(AppTheme.self, forKey: .theme)
            ?? .system
        highContrast =
            try container.decodeIfPresent(Bool.self, forKey: .highContrast)
            ?? false
        largeEditorText =
            try container.decodeIfPresent(Bool.self, forKey: .largeEditorText)
            ?? false
        largeControls =
            try container.decodeIfPresent(Bool.self, forKey: .largeControls)
            ?? false
        lineSpacing =
            try container.decodeIfPresent(
                AppLineSpacing.self,
                forKey: .lineSpacing
            ) ?? .normal
        dyslexiaFriendlyFont =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .dyslexiaFriendlyFont
            ) ?? false
        hapticFeedback =
            try container.decodeIfPresent(Bool.self, forKey: .hapticFeedback)
            ?? true
    }
}

enum AppLineSpacing: String, CaseIterable, Identifiable, Codable {
    case normal
    case large
    case extraLarge

    var id: String { rawValue }

    func label(for language: AppLanguage) -> String {
        switch self {
        case .normal: language.text(.normal)
        case .large: language.text(.large)
        case .extraLarge: language.text(.extraLarge)
        }
    }

    var value: Double {
        switch self {
        case .normal: 2
        case .large: 8
        case .extraLarge: 14
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case german
    case english

    var id: String { rawValue }

    func text(_ key: TextKey) -> String {
        AppContent.shared.text(key, language: self)
    }
}

enum TextKey: String, Codable {
    case appTitle
    case appInfo
    case appVersion
    case defaultWelcomeTitle
    case defaultWelcomeBody
    case notes
    case tabs
    case settings
    case addTab
    case addNote
    case newTab
    case newNote
    case rename
    case delete
    case cancel
    case save
    case title
    case body
    case buildNumber
    case empty
    case features
    case info
    case iosVersion
    case device
    case language
    case theme
    case system
    case light
    case dark
    case style
    case textColor
    case marker
    case fontSize
    case accessibility
    case highContrast
    case largeEditorText
    case largeControls
    case lineSpacing
    case dyslexiaFriendlyFont
    case hapticFeedback
    case normal
    case on
    case off
    case large
    case extraLarge
    case focusMode
    case exitFocusMode
    case voiceActions
    case dictateNote
    case stopDictation
    case speakNote
    case speakSelection
    case speakSummary
    case stopSpeaking
    case shareNote
    case clearNote
    case undo
    case voice
    case recording
    case voiceDenied
    case start
    case chooseNote
    case search
    case allNotes
    case beginNew
    case recentNotes
    case noSearchResults
}

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    func label(for language: AppLanguage) -> String {
        switch self {
        case .system: language.text(.system)
        case .light: language.text(.light)
        case .dark: language.text(.dark)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
