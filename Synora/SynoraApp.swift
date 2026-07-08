//
//  SynoraApp.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

@main
struct SynoraApp: App {

    @AppStorage("hasSeenOnboarding")

    private var hasSeenOnboarding = false

    @StateObject private var storeViewModel = StoreViewModel()
    @StateObject private var reviewPromptManager = ReviewPromptManager()

    var body: some Scene {
        WindowGroup {
            rootContent
                .environmentObject(storeViewModel)
                .environmentObject(reviewPromptManager)
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
            if hasSeenOnboarding {
                RootView()
            } else {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            }
        }
    }
}
