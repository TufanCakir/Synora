//
//  OnboardingConfiguration.swift
//  Synora
//
//  Created by Tufan Cakir on 05.07.26.
//

enum OnboardingIconKind {
    case system(String)
    case custom(String)
}

struct OnboardingConfiguration: Decodable {
    let title: String
    let subtitle: String
    let sections: [OnboardingSection]
}

struct OnboardingSection: Decodable, Identifiable {
    var id: String { title }
    let title: String
    let text: String
}
