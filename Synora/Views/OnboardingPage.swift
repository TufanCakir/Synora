//
//  OnboardingPage.swift
//  Synora
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

enum OnboardingIcon {
    case system(String)
    case asset(String)
}

struct OnboardingPage: View {

    private let iconSize: CGFloat = 56

    let icon: OnboardingIcon
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 24) {

            Spacer()
            iconView

            VStack(spacing: 10) {
                Text(title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}

extension OnboardingPage {

    fileprivate var iconView: some View {
        Group {
            switch icon {

            case .system(let name):
                Image(systemName: name)
                    .font(.system(size: iconSize, weight: .semibold))

            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            }
        }
        .foregroundStyle(.primary)
        .padding(24)
        .background(
            Circle()
                .fill(.thinMaterial)
        )
        .accessibilityHidden(true)
    }
}
