//
//  SettingsView.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import StoreKit
import SwiftUI

struct SettingsView: View {

    let viewModel: NotesViewModel
    var showsDoneButton = true
    var reviewPromptManager = ReviewPromptManager()
    var onShowSubscriptionPlans: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.language == .german ? "App" : "App") {
                    Button(action: onShowSubscriptionPlans) {
                        Label(
                            subscriptionPlansTitle,
                            systemImage: "crown"
                        )
                    }

                    Picker(
                        viewModel.language.text(.language),
                        selection: languageBinding
                    ) {
                        Text("Deutsch").tag(AppLanguage.german)
                        Text("English").tag(AppLanguage.english)
                    }
                    .pickerStyle(.segmented)

                    Picker(
                        viewModel.language.text(.theme),
                        selection: themeBinding
                    ) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label(for: viewModel.language)).tag(
                                theme
                            )
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(
                    viewModel.language == .german
                        ? "Lesen & Bedienung"
                        : "Reading & Controls"
                ) {
                    Toggle(
                        viewModel.language.text(.highContrast),
                        isOn: highContrastBinding
                    )

                    Toggle(
                        viewModel.language.text(.largeEditorText),
                        isOn: largeEditorTextBinding
                    )

                    Toggle(
                        viewModel.language.text(.largeControls),
                        isOn: largeControlsBinding
                    )

                    Toggle(
                        viewModel.language.text(.dyslexiaFriendlyFont),
                        isOn: dyslexiaFriendlyFontBinding
                    )

                    Toggle(
                        viewModel.language.text(.hapticFeedback),
                        isOn: hapticFeedbackBinding
                    )

                    Picker(
                        viewModel.language.text(.lineSpacing),
                        selection: lineSpacingBinding
                    ) {
                        ForEach(AppLineSpacing.allCases) { spacing in
                            Text(spacing.label(for: viewModel.language)).tag(
                                spacing
                            )
                        }
                    }
                }

                Section(
                    viewModel.language == .german
                        ? "Info & Rechtliches" : "Info & Legal"
                ) {
                    NavigationLink {
                        InfoView(language: viewModel.language)
                    } label: {
                        Label(
                            viewModel.language.text(.appInfo),
                            systemImage: "info.circle"
                        )
                    }

                    Button {
                        requestManualReview()
                    } label: {
                        Label(
                            reviewTitle,
                            systemImage: "star.bubble"
                        )
                    }

                    if let appleTermsURL {
                        Link(destination: appleTermsURL) {
                            Label(
                                termsTitle,
                                systemImage: "doc.text"
                            )
                        }
                    }
                }
            }
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(viewModel.language.text(.save)) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var subscriptionPlansTitle: String {
        viewModel.language == .german
            ? "Abo-Pläne ansehen"
            : "View subscription plans"
    }

    private var reviewTitle: String {
        viewModel.language == .german ? "Synora bewerten" : "Rate Synora"
    }

    private var termsTitle: String {
        viewModel.language == .german ? "Nutzungsbedingungen" : "Terms of Use"
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { viewModel.settings.language },
            set: { viewModel.setLanguage($0) }
        )
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(
            get: { viewModel.settings.theme },
            set: { viewModel.setTheme($0) }
        )
    }

    private var highContrastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.highContrast },
            set: { viewModel.setHighContrast($0) }
        )
    }

    private var largeEditorTextBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.largeEditorText },
            set: { viewModel.setLargeEditorText($0) }
        )
    }

    private var largeControlsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.largeControls },
            set: { viewModel.setLargeControls($0) }
        )
    }

    private var lineSpacingBinding: Binding<AppLineSpacing> {
        Binding(
            get: { viewModel.settings.lineSpacing },
            set: { viewModel.setLineSpacing($0) }
        )
    }

    private var dyslexiaFriendlyFontBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.dyslexiaFriendlyFont },
            set: { viewModel.setDyslexiaFriendlyFont($0) }
        )
    }

    private var hapticFeedbackBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.hapticFeedback },
            set: { viewModel.setHapticFeedback($0) }
        )
    }

    private var appleTermsURL: URL? {
        URL(
            string:
                "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        )
    }

    private func requestManualReview() {
        if let writeReviewURL = reviewPromptManager.writeReviewURL {
            openURL(writeReviewURL)
        } else {
            requestReview()
        }
    }
}

#Preview {
    SettingsView(viewModel: NotesViewModel())
}
