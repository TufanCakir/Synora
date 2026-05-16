//
//  RootView.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

struct RootView: View {
    @State private var viewModel = NotesViewModel()

    var body: some View {
        TabView {
            NoteView(viewModel: viewModel)
                .tabItem {
                    Label(
                        viewModel.language.text(.notes),
                        systemImage: "note.text"
                    )
                }

            SettingsView(viewModel: viewModel, showsDoneButton: false)
                .tabItem {
                    Label(
                        viewModel.language.text(.settings),
                        systemImage: "gearshape"
                    )
                }
        }
        .preferredColorScheme(viewModel.settings.theme.colorScheme)
    }
}

#Preview {
    RootView()
}
