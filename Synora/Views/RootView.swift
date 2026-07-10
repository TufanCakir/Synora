//
//  RootView.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

struct RootView: View {

    @State private var viewModel = NotesViewModel()

    @StateObject private var storeViewModel = StoreViewModel()
    @StateObject private var reviewPromptManager = ReviewPromptManager()

    @State private var selectedTab: RootTab = .notes

    var body: some View {
        TabView(selection: $selectedTab) {
            NoteView(
                viewModel: viewModel,
                storeViewModel: storeViewModel,
                reviewPromptManager: reviewPromptManager,
                onShowSubscriptionPlans: {
                    selectedTab = .subscription
                }
            )
            .tabItem {
                Label(
                    viewModel.language.text(.notes),
                    systemImage: "note.text"
                )
            }
            .tag(RootTab.notes)

            SubscriptionView(
                language: viewModel.language,
                theme: viewModel.settings.theme,
                tabCount: viewModel.tabCount,
                noteCount: viewModel.noteCount,
                storageMegabytesUsed: viewModel.storageMegabytesUsed
            )
            .tabItem {
                Label("Synora Pro", systemImage: "square.stack.3d.up")
            }
            .environmentObject(storeViewModel)
            .tag(RootTab.subscription)

            SettingsView(
                viewModel: viewModel,
                showsDoneButton: false,
                reviewPromptManager: reviewPromptManager,
                onShowSubscriptionPlans: {
                    selectedTab = .subscription
                }
            )
            .tabItem {
                Label(
                    viewModel.language.text(.settings),
                    systemImage: "gear"
                )
            }
            .tag(RootTab.settings)
        }
        .preferredColorScheme(viewModel.settings.theme.colorScheme)
    }
}

private enum RootTab {
    case notes
    case subscription
    case settings
}

#Preview {
    RootView()
}
