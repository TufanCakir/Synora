//
//  SpeechNoteService.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import AVFoundation
import Foundation
import Observation
import Speech

@MainActor
@Observable
final class SpeechNoteService {
    private(set) var isRecording = false
    var lastError: String?

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var onText: ((String) -> Void)?

    func start(language: AppLanguage, onText: @escaping (String) -> Void) {
        self.onText = onText
        lastError = nil

        Task {
            let allowed = await requestPermissions()
            guard allowed else {
                lastError = language.text(.voiceDenied)
                return
            }

            do {
                try beginRecognition()
            } catch {
                lastError = error.localizedDescription
                stop()
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
    }

    private func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAllowed else { return false }

        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission {
                    allowed in
                    continuation.resume(returning: allowed)
                }
            }
        }
    }

    private func beginRecognition() throws {
        stop()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .record,
            mode: .measurement,
            options: .duckOthers
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        task = recognizer?.recognitionTask(with: request) {
            [weak self] result, error in
            guard let self else { return }

            if let text = result?.bestTranscription.formattedString,
                !text.isEmpty
            {
                Task { @MainActor in
                    self.onText?(text)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.stop()
                }
            }
        }
    }
}
