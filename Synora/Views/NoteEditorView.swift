//
//  NoteEditorView.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

struct NoteEditorView: View {

    @Environment(\.colorScheme) private var colorScheme

    let note: Note
    let settings: UserSettings
    let onChange: (String, String, NoteStyle) -> Void

    @State private var title: String
    @State private var bodyText: String
    @State private var style: NoteStyle
    @State private var undoHistory: [NoteEditorSnapshot] = []
    @State private var isRestoringSnapshot = false
    @State private var textToSpeechService = TextToSpeechService()
    @State private var dictationService = SpeechNoteService()
    @State private var dictationBaseText = ""
    @State private var isFocusMode = false
    @State private var textSelection: TextSelection?
    @State private var hapticTrigger = 0

    init(
        note: Note,
        settings: UserSettings,
        onChange: @escaping (String, String, NoteStyle) -> Void
    ) {
        self.note = note
        self.settings = settings
        self.onChange = onChange
        _title = State(initialValue: note.title)
        _bodyText = State(initialValue: note.body)
        _style = State(initialValue: note.style)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isFocusMode {
                styleBar
            }

            VStack(alignment: .leading, spacing: isFocusMode ? 18 : 10) {
                TextField(language.text(.title), text: $title)
                    .font(titleFont)
                    .fontDesign(fontDesign)
                    .tracking(readingTracking)
                    .textFieldStyle(.plain)
                    .foregroundStyle(style.textColor.color)
                    .padding(.horizontal, isFocusMode ? 20 : 14)
                    .padding(.top, isFocusMode ? 24 : 12)

                TextEditor(text: $bodyText, selection: $textSelection)
                    .font(.system(size: effectiveFontSize, design: fontDesign))
                    .foregroundStyle(style.textColor.color)
                    .lineSpacing(settings.lineSpacing.value)
                    .tracking(readingTracking)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, isFocusMode ? 16 : 8)
                    .background(
                        style.isMarked
                            ? style.markerColor.color.opacity(markerOpacity)
                            : editorBackground
                    )
                    .overlay {
                        if settings.highContrast {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    contrastTheme.editorBorderColor,
                                    lineWidth: 1.5
                                )
                                .padding(.horizontal, 8)
                        }
                    }
            }
            .background(editorBackground)
        }
        .background(editorBackground)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isFocusMode.toggle()
                    triggerHaptic()
                } label: {
                    Label(
                        isFocusMode
                            ? language.text(.exitFocusMode)
                            : language.text(.focusMode),
                        systemImage: isFocusMode
                            ? "rectangle.compress.vertical"
                            : "rectangle.expand.vertical"
                    )
                }

                Menu {
                    Button {
                        textToSpeechService.toggle(
                            text: shareText,
                            language: language
                        )
                        triggerHaptic()
                    } label: {
                        Label(
                            textToSpeechService.isSpeaking
                                ? language.text(.stopSpeaking)
                                : language.text(.speakNote),
                            systemImage: textToSpeechService.isSpeaking
                                ? "speaker.slash.fill"
                                : "speaker.wave.2.fill"
                        )
                    }
                    .disabled(shareText.isEmpty)

                    Button {
                        textToSpeechService.toggle(
                            text: selectedOrRemainingSpeechText,
                            language: language
                        )
                        triggerHaptic()
                    } label: {
                        Label(
                            language.text(.speakSelection),
                            systemImage: "selection.pin.in.out"
                        )
                    }
                    .disabled(selectedOrRemainingSpeechText.isEmpty)

                    Button {
                        textToSpeechService.toggle(
                            text: summarySpeechText,
                            language: language
                        )
                        triggerHaptic()
                    } label: {
                        Label(
                            language.text(.speakSummary),
                            systemImage: "text.quote"
                        )
                    }
                    .disabled(summarySpeechText.isEmpty)

                    Button {
                        toggleDictation()
                    } label: {
                        Label(
                            dictationService.isRecording
                                ? language.text(.stopDictation)
                                : language.text(.dictateNote),
                            systemImage: dictationService.isRecording
                                ? "waveform.circle.fill"
                                : "mic.fill"
                        )
                    }
                } label: {
                    Label(
                        language.text(.voiceActions),
                        systemImage: voiceActionsIcon
                    )
                }
                .tint(
                    dictationService.isRecording
                        ? .red
                        : (textToSpeechService.isSpeaking ? .orange : nil)
                )
                .accessibilityLabel(language.text(.voiceActions))
                .accessibilityHint(language.text(.dictateNote))

                Button {
                    undoLastChange()
                    triggerHaptic()
                } label: {
                    Label(
                        language.text(.undo),
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .disabled(undoHistory.isEmpty)

                ShareLink(item: shareText) {
                    Label(
                        language.text(.shareNote),
                        systemImage: "square.and.arrow.up"
                    )
                }

                Button(role: .destructive) {
                    clearNoteText()
                    triggerHaptic()
                } label: {
                    Label(language.text(.clearNote), systemImage: "eraser")
                }
                .disabled(bodyText.isEmpty)
            }
        }
        .id(note.id)
        .sensoryFeedback(.selection, trigger: hapticTrigger) { _, _ in
            settings.hapticFeedback
        }
        .alert(language.text(.voice), isPresented: dictationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dictationService.lastError ?? "")
        }
        .onChange(of: title) { oldValue, _ in
            recordUndoSnapshot(
                title: oldValue,
                bodyText: bodyText,
                style: style
            )
            publishChange()
        }
        .onChange(of: bodyText) { oldValue, _ in
            recordUndoSnapshot(title: title, bodyText: oldValue, style: style)
            publishChange()
        }
        .onChange(of: style) { oldValue, _ in
            recordUndoSnapshot(
                title: title,
                bodyText: bodyText,
                style: oldValue
            )
            publishChange()
        }
    }

    private var styleBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                styleTitle
                Spacer(minLength: 4)
                compactStyleControls
            }

            VStack(alignment: .leading, spacing: 8) {
                styleTitle
                compactStyleControls
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            settings.highContrast
                ? contrastTheme.toolbarBackgroundColor : Color.clear
        )
        .background(.bar)
        .overlay(alignment: .bottom) {
            if settings.highContrast {
                Rectangle()
                    .fill(.primary)
                    .frame(height: 2)
            }
        }
    }

    private var styleTitle: some View {
        Label(language.text(.style), systemImage: "paintpalette")
            .font(.subheadline.weight(.semibold))
            .labelStyle(.iconOnly)
            .accessibilityLabel(language.text(.style))
    }

    @ViewBuilder
    private var compactStyleControls: some View {
        if settings.largeControls {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    colorMenu(
                        title: language.text(.textColor),
                        shortTitle: "Text",
                        systemImage: "pencil.tip",
                        selection: $style.textColor,
                        colors: ColorPaletteStore.shared.penColors
                    )
                    .frame(maxWidth: .infinity)

                    colorMenu(
                        title: language.text(.marker),
                        shortTitle: language.text(.marker),
                        systemImage: "highlighter",
                        selection: $style.markerColor,
                        colors: ColorPaletteStore.shared.markerColors
                    )
                    .frame(maxWidth: .infinity)
                }

                HStack(spacing: 10) {
                    markerToggle
                        .frame(maxWidth: .infinity)

                    fontSizeMenu
                        .frame(maxWidth: .infinity)
                }
            }
        } else {
            HStack(spacing: 8) {
                colorMenu(
                    title: language.text(.textColor),
                    shortTitle: "Text",
                    systemImage: "pencil.tip",
                    selection: $style.textColor,
                    colors: ColorPaletteStore.shared.penColors
                )
                .accessibilityValue(style.textColor.label(for: language))

                colorMenu(
                    title: language.text(.marker),
                    shortTitle: language.text(.marker),
                    systemImage: "highlighter",
                    selection: $style.markerColor,
                    colors: ColorPaletteStore.shared.markerColors
                )
                .accessibilityValue(style.markerColor.label(for: language))

                markerToggle

                fontSizeMenu
            }
        }
    }

    @ViewBuilder
    private var markerToggle: some View {
        if settings.largeControls {
            Toggle(isOn: $style.isMarked) {
                Label(language.text(.marker), systemImage: "highlighter")
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(settings.highContrast ? .primary : nil)
            .accessibilityLabel(language.text(.marker))
            .accessibilityValue(
                style.isMarked ? language.text(.system) : language.text(.off)
            )
        } else {
            Toggle(isOn: $style.isMarked) {
                Image(systemName: "highlighter")
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(settings.highContrast ? .primary : nil)
            .accessibilityLabel(language.text(.marker))
        }
    }

    private var fontSizeMenu: some View {
        Menu {
            Stepper(value: $style.fontSize, in: 14...30, step: 1) {
                Text("\(language.text(.fontSize)): \(Int(style.fontSize))")
            }
        } label: {
            Label("\(Int(style.fontSize))", systemImage: "textformat.size")
        }
        .buttonStyle(.bordered)
        .controlSize(settings.largeControls ? .large : .small)
        .tint(settings.highContrast ? .primary : nil)
        .accessibilityLabel(language.text(.fontSize))
        .accessibilityValue("\(Int(style.fontSize))")
    }

    private func colorMenu(
        title: String,
        shortTitle: String,
        systemImage: String,
        selection: Binding<NoteColor>,
        colors: [NoteColor]
    ) -> some View {
        Menu {
            ForEach(colors) { color in
                Button {
                    selection.wrappedValue = color
                } label: {
                    HStack {
                        colorDot(color)
                        Text(color.label(for: language))
                        if selection.wrappedValue == color {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label {
                HStack(spacing: 8) {
                    Text(shortTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    colorDot(selection.wrappedValue)
                }
            } icon: {
                Image(systemName: systemImage)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(settings.largeControls ? .large : .small)
        .tint(settings.highContrast ? .primary : nil)
        .accessibilityLabel(title)
        .accessibilityValue(selection.wrappedValue.label(for: language))
    }

    private func colorDot(_ color: NoteColor) -> some View {
        Circle()
            .fill(color.color)
            .frame(width: 14, height: 14)
            .overlay {
                Circle()
                    .stroke(.secondary.opacity(0.35), lineWidth: 1)
            }
            .overlay {
                if settings.highContrast {
                    Circle()
                        .stroke(.primary, lineWidth: 1)
                }
            }
    }

    private func publishChange() {
        onChange(title, bodyText, style)
    }

    private var shareText: String {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedBody = bodyText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if cleanedTitle.isEmpty {
            return cleanedBody
        }

        if cleanedBody.isEmpty {
            return cleanedTitle
        }

        return "\(cleanedTitle)\n\n\(cleanedBody)"
    }

    private var language: AppLanguage {
        settings.language
    }

    private var effectiveFontSize: Double {
        style.fontSize + (settings.largeEditorText ? 6 : 0)
            + (isFocusMode ? 2 : 0)
    }

    private var fontDesign: Font.Design {
        settings.dyslexiaFriendlyFont ? .rounded : .default
    }

    private var readingTracking: CGFloat {
        settings.dyslexiaFriendlyFont ? 0.8 : 0
    }

    private var titleFont: Font {
        if isFocusMode {
            return settings.largeEditorText
                ? .largeTitle.weight(.semibold)
                : .title.weight(.semibold)
        }

        return settings.largeEditorText
            ? .title2.weight(.semibold)
            : .title3.weight(.semibold)
    }

    private var editorBackground: Color {
        settings.highContrast
            ? contrastTheme.editorBackgroundColor : Color.clear
    }

    private var contrastTheme: ContrastTheme {
        ContrastThemeStore.shared.theme(for: colorScheme)
    }

    private var markerOpacity: Double {
        settings.highContrast ? contrastTheme.markerOpacity : 0.18
    }

    private var voiceActionsIcon: String {
        if dictationService.isRecording {
            return "waveform.circle.fill"
        }

        if textToSpeechService.isSpeaking {
            return "speaker.wave.2.fill"
        }

        return "waveform.and.mic"
    }

    private var dictationErrorBinding: Binding<Bool> {
        Binding(
            get: { dictationService.lastError != nil },
            set: { isPresented in
                if !isPresented {
                    dictationService.lastError = nil
                }
            }
        )
    }

    private var selectedOrRemainingSpeechText: String {
        guard let indices = textSelection?.indices else {
            return shareText
        }

        switch indices {
        case .selection(let range):
            if range.isEmpty {
                let remainingText = String(bodyText[range.lowerBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return remainingText.isEmpty ? shareText : remainingText
            }

            return String(bodyText[range])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        case .multiSelection(let ranges):
            return ranges.ranges
                .map { String(bodyText[$0]) }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        @unknown default:
            return shareText
        }
    }

    private var summarySpeechText: String {
        let cleanedBody =
            bodyText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let source = cleanedBody.isEmpty ? shareText : cleanedBody
        guard !source.isEmpty else { return "" }

        let separators = CharacterSet(charactersIn: ".!?")
        let sentences =
            source
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if sentences.isEmpty {
            return String(source.prefix(220))
        }

        return sentences.prefix(2).joined(separator: ". ") + "."
    }

    private func clearNoteText() {
        guard !bodyText.isEmpty else { return }
        recordUndoSnapshot(title: title, bodyText: bodyText, style: style)
        bodyText = ""
    }

    private func toggleDictation() {
        if dictationService.isRecording {
            dictationService.stop()
            triggerHaptic()
            return
        }

        dictationBaseText = bodyText
        triggerHaptic()
        dictationService.start(language: language) { spokenText in
            let separator =
                dictationBaseText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                ? ""
                : "\n"
            bodyText = dictationBaseText + separator + spokenText
        }
    }

    private func triggerHaptic() {
        hapticTrigger += 1
    }

    private func undoLastChange() {
        guard let snapshot = undoHistory.popLast() else { return }
        isRestoringSnapshot = true
        title = snapshot.title
        bodyText = snapshot.bodyText
        style = snapshot.style
        publishChange()

        Task { @MainActor in
            isRestoringSnapshot = false
        }
    }

    private func recordUndoSnapshot(
        title: String,
        bodyText: String,
        style: NoteStyle
    ) {
        guard !isRestoringSnapshot else { return }

        let snapshot = NoteEditorSnapshot(
            title: title,
            bodyText: bodyText,
            style: style
        )
        if undoHistory.last != snapshot {
            undoHistory.append(snapshot)
        }

        if undoHistory.count > 40 {
            undoHistory.removeFirst(undoHistory.count - 40)
        }
    }
}

private struct NoteEditorSnapshot: Equatable {
    let title: String
    let bodyText: String
    let style: NoteStyle
}

#Preview {
    NavigationStack {
        NoteEditorView(
            note: Note(
                title: "Preview Note",
                body:
                    "This is a preview note with editable text, color, marker, and font size controls.",
                style: NoteStyle(
                    textColor: .blue,
                    markerColor: .yellow,
                    isMarked: true,
                    fontSize: 18
                )
            ),
            settings: UserSettings(language: .english, theme: .system)
        ) { _, _, _ in }
    }
}
