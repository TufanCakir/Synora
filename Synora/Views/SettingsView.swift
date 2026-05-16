//
//  SettingsView.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    let viewModel: NotesViewModel
    var showsDoneButton = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.language.text(.language)) {
                    Picker(
                        viewModel.language.text(.language),
                        selection: languageBinding
                    ) {
                        Text("Deutsch").tag(AppLanguage.german)
                        Text("English").tag(AppLanguage.english)
                    }
                    .pickerStyle(.segmented)
                }

                Section(viewModel.language.text(.theme)) {
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

                Section(viewModel.language.text(.accessibility)) {
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

                Section(viewModel.language.text(.info)) {
                    NavigationLink {
                        AppInfoView(language: viewModel.language)
                    } label: {
                        Label(
                            viewModel.language.text(.appInfo),
                            systemImage: "info.circle"
                        )
                    }
                }
            }
            .navigationTitle(viewModel.language.text(.settings))
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
}

private struct AppInfoView: View {
    let language: AppLanguage

    var body: some View {
        List {
            Section(language.text(.features)) {
                ForEach(
                    AppContent.shared.infoBullets(language: language),
                    id: \.self
                ) { detail in
                    Label(detail, systemImage: "checkmark.circle")
                }
            }

            Section(language.text(.appInfo)) {
                LabeledContent(language.text(.appVersion), value: appVersion)
                LabeledContent(language.text(.buildNumber), value: buildNumber)
                LabeledContent(
                    language.text(.iosVersion),
                    value: UIDevice.current.systemVersion
                )
                LabeledContent(
                    language.text(.device),
                    value: UIDevice.current.model
                )
            }
        }
        .navigationTitle(language.text(.appInfo))
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView(viewModel: NotesViewModel())
}
