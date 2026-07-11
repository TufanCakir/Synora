//
//  NotesViewModel.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotesViewModel {

    private(set) var document: NotesDocument

    var settings: UserSettings {
        didSet { settingsStore.save(settings) }
    }
    var selectedTabID: NoteTab.ID?
    var selectedNoteID: Note.ID?

    private let notesStore = JSONStore(
        fileName: "notes.json",
        defaultValue: NotesDocument.defaults
    )
    private let settingsStore = JSONStore(
        fileName: "settings.json",
        defaultValue: UserSettings.defaults
    )

    init() {
        let loadedDocument = notesStore.load()
        document =
            loadedDocument.tabs.isEmpty
            ? NotesDocument.defaults : loadedDocument
        settings = settingsStore.load()
        selectedTabID = document.tabs.first?.id
        selectedNoteID = document.tabs.first?.notes.first?.id
    }

    var language: AppLanguage { settings.language }

    var tabCount: Int {
        document.tabs.count
    }

    var noteCount: Int {
        document.tabs.reduce(0) { $0 + $1.notes.count }
    }

    var storageMegabytesUsed: Int {
        storageMegabytes(for: document)
    }

    func storageMegabytesAfterUpdatingSelectedNote(
        title: String,
        body: String
    ) -> Int {
        guard let location = selectedNoteLocation else {
            return storageMegabytesUsed
        }

        var updatedDocument = document
        updatedDocument.tabs[location.tab].notes[location.note].title = title
        updatedDocument.tabs[location.tab].notes[location.note].body = body
        return storageMegabytes(for: updatedDocument)
    }

    var selectedTab: NoteTab? {
        guard let selectedTabID else { return nil }
        return document.tabs.first { $0.id == selectedTabID }
    }

    var selectedNote: Note? {
        guard let selectedTab, let selectedNoteID else { return nil }
        return selectedTab.notes.first { $0.id == selectedNoteID }
    }

    func addTab() {
        let tab = NoteTab(title: uniqueTabTitle())
        document.tabs.append(tab)
        selectedTabID = tab.id
        selectedNoteID = nil
        saveNotes()
    }

    func displayTitle(for tab: NoteTab) -> String {
        if let titleKey = tab.titleKey {
            return language.text(titleKey)
        }

        return localizedGeneratedTitle(tab.title, key: .newTab)
    }

    func displayTitle(for note: Note) -> String {
        if let titleKey = note.titleKey {
            return language.text(titleKey)
        }

        if isDefaultWelcomeTitle(note.title) {
            return language.text(.defaultWelcomeTitle)
        }

        return localizedGeneratedTitle(note.title, key: .newNote)
    }

    func displayBody(for note: Note) -> String {
        if let bodyKey = note.bodyKey {
            return language.text(bodyKey)
        }

        if isDefaultWelcomeBody(note.body) {
            return language.text(.defaultWelcomeBody)
        }

        return note.body
    }

    func deleteTabs(at offsets: IndexSet) {
        let removedIDs = offsets.compactMap {
            document.tabs.indices.contains($0) ? document.tabs[$0].id : nil
        }
        removeItems(from: &document.tabs, at: offsets)

        if document.tabs.isEmpty {
            document.tabs = [NoteTab(title: language.text(.newTab))]
        }

        if let selectedTabID, removedIDs.contains(selectedTabID) {
            self.selectedTabID = document.tabs.first?.id
            selectedNoteID = selectedTab?.notes.first?.id
        }

        saveNotes()
    }

    func deleteTab(id: NoteTab.ID) {
        guard
            let index = document.tabs.firstIndex(where: { $0.id == id })
        else {
            return
        }

        deleteTabs(at: IndexSet(integer: index))
    }

    func moveTabs(from source: IndexSet, to destination: Int) {
        moveItems(in: &document.tabs, from: source, to: destination)
        saveNotes()
    }

    func renameSelectedTab(to title: String) {
        guard let tabIndex = selectedTabIndex else { return }
        document.tabs[tabIndex].title = clean(
            title,
            fallback: language.text(.newTab)
        )
        saveNotes()
    }

    func addNote() {
        guard let tabIndex = selectedTabIndex else { return }
        let note = Note(title: language.text(.newNote))
        document.tabs[tabIndex].notes.insert(note, at: 0)
        selectedNoteID = note.id
        saveNotes()
    }

    func addVoiceNote(text: String) {
        let trimmedText = clean(text, fallback: language.text(.newNote))
        let title = trimmedText.split(separator: " ").prefix(6).joined(
            separator: " "
        )
        let note = Note(
            title: title.isEmpty ? language.text(.newNote) : title,
            body: trimmedText
        )

        if selectedTabID == nil {
            addTab()
        }

        guard let tabIndex = selectedTabIndex else { return }
        document.tabs[tabIndex].notes.insert(note, at: 0)
        selectedNoteID = note.id
        saveNotes()
    }

    func deleteNotes(at offsets: IndexSet) {
        guard let tabIndex = selectedTabIndex else { return }
        let notes = document.tabs[tabIndex].notes
        let removedIDs = offsets.compactMap {
            notes.indices.contains($0) ? notes[$0].id : nil
        }
        removeItems(from: &document.tabs[tabIndex].notes, at: offsets)

        if let selectedNoteID, removedIDs.contains(selectedNoteID) {
            self.selectedNoteID = document.tabs[tabIndex].notes.first?.id
        }

        saveNotes()
    }

    func deleteNote(id: Note.ID) {
        guard
            let tabIndex = selectedTabIndex,
            let noteIndex = document.tabs[tabIndex].notes.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        deleteNotes(at: IndexSet(integer: noteIndex))
    }

    func deleteNote(id: Note.ID, in tabID: NoteTab.ID) {
        guard
            let tabIndex = document.tabs.firstIndex(where: { $0.id == tabID }),
            let noteIndex = document.tabs[tabIndex].notes.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        document.tabs[tabIndex].notes.remove(at: noteIndex)
        if selectedNoteID == id {
            selectedNoteID = document.tabs[tabIndex].notes.first?.id
        }
        saveNotes()
    }

    func renameNote(id: Note.ID, in tabID: NoteTab.ID, to title: String) {
        guard
            let tabIndex = document.tabs.firstIndex(where: { $0.id == tabID }),
            let noteIndex = document.tabs[tabIndex].notes.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        document.tabs[tabIndex].notes[noteIndex].title = clean(
            title,
            fallback: language.text(.newNote)
        )
        document.tabs[tabIndex].notes[noteIndex].titleKey = nil
        document.tabs[tabIndex].notes[noteIndex].updatedAt = .now
        saveNotes()
    }

    func moveNote(
        id: Note.ID,
        from sourceTabID: NoteTab.ID,
        to targetTabID: NoteTab.ID,
        before targetNoteID: Note.ID?
    ) {
        guard
            let sourceTabIndex = document.tabs.firstIndex(
                where: { $0.id == sourceTabID }
            ),
            let sourceNoteIndex = document.tabs[sourceTabIndex].notes
                .firstIndex(
                    where: { $0.id == id }
                ),
            let targetTabIndex = document.tabs.firstIndex(
                where: { $0.id == targetTabID }
            )
        else {
            return
        }

        let note = document.tabs[sourceTabIndex].notes.remove(
            at: sourceNoteIndex
        )
        let insertionIndex: Int
        if let targetNoteID,
            let targetIndex = document.tabs[targetTabIndex].notes.firstIndex(
                where: { $0.id == targetNoteID }
            )
        {
            insertionIndex = targetIndex
        } else {
            insertionIndex = document.tabs[targetTabIndex].notes.endIndex
        }

        document.tabs[targetTabIndex].notes.insert(note, at: insertionIndex)
        selectedTabID = targetTabID
        selectedNoteID = note.id
        saveNotes()
    }

    func moveSelectedNote(to targetTabID: NoteTab.ID) {
        guard
            let sourceTabIndex = selectedTabIndex,
            let selectedNoteID,
            let sourceNoteIndex = document.tabs[sourceTabIndex].notes
                .firstIndex(
                    where: { $0.id == selectedNoteID }
                ),
            let targetTabIndex = document.tabs.firstIndex(
                where: { $0.id == targetTabID }
            )
        else {
            return
        }

        guard sourceTabIndex != targetTabIndex else { return }

        let note = document.tabs[sourceTabIndex].notes.remove(
            at: sourceNoteIndex
        )
        document.tabs[targetTabIndex].notes.insert(note, at: 0)
        selectedTabID = targetTabID
        self.selectedNoteID = note.id
        saveNotes()
    }

    func moveNotes(from source: IndexSet, to destination: Int) {
        guard let tabIndex = selectedTabIndex else { return }
        moveItems(
            in: &document.tabs[tabIndex].notes,
            from: source,
            to: destination
        )
        saveNotes()
    }

    func updateSelectedNote(
        title: String? = nil,
        body: String? = nil,
        style: NoteStyle? = nil
    ) {
        guard let location = selectedNoteLocation else { return }

        if let title {
            document.tabs[location.tab].notes[location.note].title = clean(
                title,
                fallback: language.text(.newNote)
            )
            document.tabs[location.tab].notes[location.note].titleKey = nil
        }

        if let body {
            document.tabs[location.tab].notes[location.note].body = body
            document.tabs[location.tab].notes[location.note].bodyKey = nil
        }

        if let style {
            document.tabs[location.tab].notes[location.note].style = style
        }

        document.tabs[location.tab].notes[location.note].updatedAt = .now
        saveNotes()
    }

    func setLanguage(_ language: AppLanguage) {
        settings.language = language
    }

    func setTheme(_ theme: AppTheme) {
        settings.theme = theme
    }

    func setHighContrast(_ isEnabled: Bool) {
        settings.highContrast = isEnabled
    }

    func setLargeEditorText(_ isEnabled: Bool) {
        settings.largeEditorText = isEnabled
    }

    func setLargeControls(_ isEnabled: Bool) {
        settings.largeControls = isEnabled
    }

    func setLineSpacing(_ lineSpacing: AppLineSpacing) {
        settings.lineSpacing = lineSpacing
    }

    func setDyslexiaFriendlyFont(_ isEnabled: Bool) {
        settings.dyslexiaFriendlyFont = isEnabled
    }

    func setHapticFeedback(_ isEnabled: Bool) {
        settings.hapticFeedback = isEnabled
    }

    private var selectedTabIndex: Int? {
        guard let selectedTabID else { return nil }
        return document.tabs.firstIndex { $0.id == selectedTabID }
    }

    private var selectedNoteLocation: (tab: Int, note: Int)? {
        guard let tabIndex = selectedTabIndex, let selectedNoteID else {
            return nil
        }
        guard
            let noteIndex = document.tabs[tabIndex].notes.firstIndex(where: {
                $0.id == selectedNoteID
            })
        else { return nil }
        return (tabIndex, noteIndex)
    }

    private func uniqueTabTitle() -> String {
        let baseTitle = language.text(.newTab)
        var title = baseTitle
        var counter = 2
        let existingTitles = Set(document.tabs.map(\.title))

        while existingTitles.contains(title) {
            title = "\(baseTitle) \(counter)"
            counter += 1
        }

        return title
    }

    private func localizedGeneratedTitle(_ title: String, key: TextKey)
        -> String
    {
        AppContent.shared.texts(for: key).contains(title)
            ? language.text(key) : title
    }

    private func isDefaultWelcomeTitle(_ title: String) -> Bool {
        title == "Willkommen" || title == "Welcome"
            || AppContent.shared.texts(for: .defaultWelcomeTitle).contains(
                title
            )
    }

    private func isDefaultWelcomeBody(_ body: String) -> Bool {
        body
            == "Starte hier mit deiner ersten Notiz. Du kannst Textfarbe, Marker und Schriftgröße ändern."
            || AppContent.shared.texts(for: .defaultWelcomeBody).contains(body)
    }

    private func clean(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func removeItems<T>(from values: inout [T], at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where values.indices.contains(index)
        {
            values.remove(at: index)
        }
    }

    private func moveItems<T>(
        in values: inout [T],
        from source: IndexSet,
        to destination: Int
    ) {
        let moving = source.sorted().compactMap {
            values.indices.contains($0) ? values[$0] : nil
        }
        removeItems(from: &values, at: source)
        let removedBeforeDestination = source.filter { $0 < destination }.count
        let insertionIndex = max(
            0,
            min(values.count, destination - removedBeforeDestination)
        )
        values.insert(contentsOf: moving, at: insertionIndex)
    }

    private func saveNotes() {
        notesStore.save(document)
    }

    private func storageMegabytes(for document: NotesDocument) -> Int {
        let bytes = document.tabs.reduce(0) { total, tab in
            total + tab.title.utf8.count
                + tab.notes.reduce(0) { noteTotal, note in
                    noteTotal + note.title.utf8.count + note.body.utf8.count
                }
        }
        return max(Int(ceil(Double(bytes) / 1_000_000)), bytes > 0 ? 1 : 0)
    }
}
