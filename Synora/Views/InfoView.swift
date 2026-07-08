//
//  InfoView.swift
//  Synora
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI
import UIKit

struct InfoView: View {

    let language: AppLanguage

    private var content: InfoContent {
        Bundle.main.loadInfo(language: language.resourceCode)
    }

    var body: some View {
        List {
            headerSection

            ForEach(content.sections) { section in
                infoSection(section)
            }

            appDetailsSection
        }
        .listStyle(.insetGrouped)
    }

    private var headerSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.largeTitle)

                Text(content.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func infoSection(_ section: InfoSection) -> some View {
        Section(section.title) {
            Text(section.text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var appDetailsSection: some View {
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

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    InfoView(language: .german)
}

extension AppLanguage {
    fileprivate var resourceCode: String {
        switch self {
        case .german: return "de"
        case .english: return "en"
        }
    }
}
