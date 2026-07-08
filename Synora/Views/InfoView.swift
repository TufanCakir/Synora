//
//  InfoView.swift
//  Synora
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct InfoView: View {

    @AppStorage("language")

    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    private var content: InfoContent {
        Bundle.main.loadInfo(language: language)
    }

    var body: some View {
        List {
            headerSection

            ForEach(content.sections) { section in
                infoSection(section)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(content.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
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
}

#Preview {
    InfoView()
}
