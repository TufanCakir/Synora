//
//  OnboardingView.swift
//  Synora
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct OnboardingView: View {

    var onFinish: () -> Void
    var language: AppLanguage = .german

    @State private var page = 0

    private var onboardingConfig: OnboardingConfiguration {
        let resourceSuffix = language == .german ? "de" : "en"

        guard
            let url = Bundle.main.url(
                forResource: "Onboarding_\(resourceSuffix)",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let config = try? JSONDecoder().decode(
                OnboardingConfiguration.self,
                from: data
            )
        else {

            return OnboardingConfiguration(
                title: "Synora",
                subtitle: "",
                sections: [
                    OnboardingSection(
                        title: language == .german ? "Notizen" : "Notes",
                        text: language == .german
                            ? "Erstelle und organisiere deine Notizen."
                            : "Create and organize your notes."
                    )
                ]
            )
        }
        return config
    }

    var body: some View {
        let sections = onboardingConfig.sections
        let maxPage = max(0, sections.count - 1)

        VStack {
            TabView(selection: $page) {
                ForEach(0..<sections.count, id: \.self) { index in
                    OnboardingPage(
                        // Weist jeder JSON-Sektion ein passendes Icon zu
                        icon: getIcon(for: index),
                        title: sections[index].title,
                        text: sections[index].text
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .animation(.easeInOut, value: page)

            Button(action: { advance(maxPage: maxPage) }) {
                Text(
                    page < maxPage
                        ? (language == .german
                            ? "Weiter" : "Continue")
                        : (language == .german
                            ? "\(onboardingConfig.title) starten"
                            : "Start using \(onboardingConfig.title)")
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
    }

    private func advance(maxPage: Int) {
        if page < maxPage {
            page += 1
        } else {
            onFinish()
        }
    }

    private func getIcon(for index: Int) -> OnboardingIcon {
        switch index {
        case 0: return .system("note.text")
        case 1: return .system("folder")
        case 2: return .system("mic.fill")
        default: return .system("square.and.arrow.up")
        }
    }
}
