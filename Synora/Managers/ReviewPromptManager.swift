//
//  ReviewPromptManager.swift
//  Synora
//
//  Created by Tufan Cakir on 26.04.26.
//

import Combine
import Foundation

final class ReviewPromptManager: ObservableObject {

    private static let appStoreID = "6770082322"

    private enum StorageKey {
        static let didPromptAfterFirstWrittenNote =
            "review.didPromptAfterFirstWrittenNote"
        static let automaticPromptCount = "review.automaticPromptCount"
        static let lastPromptedAppVersion = "review.lastPromptedAppVersion"
    }

    private let defaults: UserDefaults
    private let maximumAutomaticPrompts = 3

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var writeReviewURL: URL? {
        guard !Self.appStoreID.isEmpty else { return nil }
        return URL(
            string:
                "https://apps.apple.com/app/id\(Self.appStoreID)?action=write-review"
        )
    }

    func shouldRequestReviewAfterFirstWrittenNote() -> Bool {
        guard !defaults.bool(forKey: StorageKey.didPromptAfterFirstWrittenNote)
        else {
            return false
        }

        guard
            defaults.integer(forKey: StorageKey.automaticPromptCount)
                < maximumAutomaticPrompts
        else {
            return false
        }

        let currentVersion =
            Bundle.main.infoDictionary?[
                "CFBundleShortVersionString"
            ] as? String ?? "1.0"
        guard
            defaults.string(forKey: StorageKey.lastPromptedAppVersion)
                != currentVersion
        else {
            return false
        }

        defaults.set(true, forKey: StorageKey.didPromptAfterFirstWrittenNote)
        defaults.set(
            defaults.integer(forKey: StorageKey.automaticPromptCount) + 1,
            forKey: StorageKey.automaticPromptCount
        )
        defaults.set(currentVersion, forKey: StorageKey.lastPromptedAppVersion)
        return true
    }
}
