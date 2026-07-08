//
//  TextToSpeechService.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import AVFoundation
import Observation

@MainActor
@Observable
final class TextToSpeechService {

    private let synthesizer = AVSpeechSynthesizer()
    private var completionTask: Task<Void, Never>?
    private(set) var isSpeaking = false

    func toggle(text: String, language: AppLanguage) {
        if synthesizer.isSpeaking {
            stop()
            return
        }

        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: cleanedText)
        utterance.voice = AVSpeechSynthesisVoice(
            language: speechLanguageCode(for: language)
        )
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
        isSpeaking = true
        scheduleCompletionReset(for: cleanedText)
    }

    func stop() {
        completionTask?.cancel()
        completionTask = nil
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func scheduleCompletionReset(for text: String) {
        completionTask?.cancel()
        let seconds = max(1.5, Double(text.count) / 13.0)

        completionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.isSpeaking = false
            }
        }
    }

    private func speechLanguageCode(for language: AppLanguage) -> String {
        switch language {
        case .german: "de-DE"
        case .english: "en-US"
        }
    }
}
