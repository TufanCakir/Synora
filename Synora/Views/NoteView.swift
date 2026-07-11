//
//  NoteView.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import StoreKit
import SwiftUI

struct NoteView: View {

    let viewModel: NotesViewModel
    let storeViewModel: StoreViewModel
    let reviewPromptManager: ReviewPromptManager
    var onShowSubscriptionPlans: () -> Void = {}

    @Environment(\.requestReview) private var requestReview

    @State private var path = NavigationPath()
    @State private var isRenamingTab = false
    @State private var isRenamingNote = false
    @State private var renamedTabTitle = ""
    @State private var renamedNoteTitle = ""
    @State private var renamedNoteID: Note.ID?
    @State private var renamedNoteTabID: NoteTab.ID?
    @State private var searchText = ""
    @State private var limitAlertMessage = ""
    @State private var isShowingLimitAlert = false
    @State private var isShowingSettings = false
    @State private var isShowingOnboarding = false

    private enum Route: Hashable {
        case editor(Note.ID)
        case tabs
        case notes
    }

    var body: some View {
        NavigationStack(path: $path) {
            StartView(
                viewModel: viewModel,
                noteRows: allNoteRows,
                onNewNote: {
                    addNoteIfAllowed()
                },
                onNewTab: {
                    addTabIfAllowed()
                },
                onSelectNote: selectNote,
                onRenameNote: prepareRenameNote,
                onDeleteNote: deleteNote,
                onMoveNotes: moveStartNotes,
                onSettings: {
                    isShowingSettings = true
                },
                onShowOnboarding: {
                    isShowingOnboarding = true
                },
                onShowTabs: {
                    path.append(Route.tabs)
                }
            )
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(
                viewModel: viewModel,
                reviewPromptManager: reviewPromptManager,
                onShowSubscriptionPlans: {
                    isShowingSettings = false
                    onShowSubscriptionPlans()
                }
            )
        }
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView(
                onFinish: {
                    isShowingOnboarding = false
                },
                language: viewModel.language
            )
        }
        .alert(viewModel.language.text(.rename), isPresented: $isRenamingTab) {
            TextField(viewModel.language.text(.title), text: $renamedTabTitle)
            Button(viewModel.language.text(.save)) {
                viewModel.renameSelectedTab(to: renamedTabTitle)
            }
            Button(viewModel.language.text(.cancel), role: .cancel) {}
        }
        .alert(viewModel.language.text(.rename), isPresented: $isRenamingNote) {
            TextField(viewModel.language.text(.title), text: $renamedNoteTitle)
            Button(viewModel.language.text(.save)) {
                if let renamedNoteID, let renamedNoteTabID {
                    viewModel.renameNote(
                        id: renamedNoteID,
                        in: renamedNoteTabID,
                        to: renamedNoteTitle
                    )
                }
            }
            Button(viewModel.language.text(.cancel), role: .cancel) {}
        }
        .alert(
            storeViewModel.limitTitle(language: viewModel.language),
            isPresented: $isShowingLimitAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(limitAlertMessage)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .editor:
            editor
        case .tabs:
            tabList
        case .notes:
            noteList
        }
    }

    private var tabList: some View {
        List {
            Section(viewModel.language.text(.tabs)) {
                ForEach(viewModel.document.tabs) { tab in
                    Button {
                        viewModel.selectedTabID = tab.id
                        path.append(Route.notes)
                    } label: {
                        Label(
                            viewModel.displayTitle(for: tab),
                            systemImage: "folder"
                        )
                    }
                    .contextMenu {
                        renameTabButton(tab)
                        Button(
                            viewModel.language.text(.delete),
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            if let index = viewModel.document.tabs.firstIndex(
                                where: { $0.id == tab.id })
                            {
                                viewModel.deleteTabs(
                                    at: IndexSet(integer: index)
                                )
                            }
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        renameTabButton(tab)
                            .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteTab(id: tab.id)
                        } label: {
                            Label(
                                viewModel.language.text(.delete),
                                systemImage: "trash"
                            )
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteTabs)
                .onMove(perform: viewModel.moveTabs)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addTabIfAllowed()
                } label: {
                    Label(viewModel.language.text(.addTab), systemImage: "plus")
                }
            }
        }
    }

    private var noteList: some View {
        List {
            Section(selectedTabTitle) {
                ForEach(filteredSelectedNotes) { note in
                    Button {
                        selectNote(note)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.displayTitle(for: note))
                                .font(.headline)
                                .foregroundStyle(note.style.textColor.color)
                            let displayBody = viewModel.displayBody(for: note)
                            if !displayBody.isEmpty {
                                Text(displayBody)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(
                        note.style.isMarked
                            ? note.style.markerColor.color.opacity(0.18)
                            : Color.clear
                    )
                    .contextMenu {
                        Button(
                            viewModel.language.text(.rename),
                            systemImage: "pencil"
                        ) {
                            prepareRenameNote(note)
                        }
                        moveNoteMenu(note)
                        Button(
                            viewModel.language.text(.delete),
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            viewModel.deleteNote(id: note.id)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            prepareRenameNote(note)
                        } label: {
                            Label(
                                viewModel.language.text(.rename),
                                systemImage: "pencil"
                            )
                        }
                        .tint(.blue)

                        moveNoteMenu(note)
                            .tint(.indigo)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteNote(id: note.id)
                        } label: {
                            Label(
                                viewModel.language.text(.delete),
                                systemImage: "trash"
                            )
                        }
                    }
                }
                .onDelete(perform: deleteDisplayedNotes)
                .onMove(perform: moveDisplayedNotes)

                if filteredSelectedNotes.isEmpty, !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.language.text(.search)
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Section(viewModel.language.text(.allNotes)) {
                        ForEach(allNoteRows) { row in
                            Button {
                                selectNote(row)
                            } label: {
                                Label(row.noteTitle, systemImage: "note.text")
                            }
                        }
                    }
                } label: {
                    Label(
                        viewModel.language.text(.chooseNote),
                        systemImage: "list.bullet.rectangle"
                    )
                }

                Button {
                    addNoteIfAllowed()
                } label: {
                    Label(
                        viewModel.language.text(.addNote),
                        systemImage: "square.and.pencil"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var editor: some View {
        if let note = viewModel.selectedNote {
            NoteEditorView(
                note: displayNote(note),
                settings: viewModel.settings
            ) { title, body, style in
                let storageAfterUpdate =
                    viewModel.storageMegabytesAfterUpdatingSelectedNote(
                        title: title,
                        body: body
                    )
                guard
                    storeViewModel.canStore(
                        storageMegabytes: storageAfterUpdate
                    )
                else {
                    showLimitAlert(for: .storage)
                    return
                }

                viewModel.updateSelectedNote(
                    title: title,
                    body: body,
                    style: style
                )
                requestReviewIfNeeded(title: title, body: body)
            }
        } else {
            ContentUnavailableView(
                viewModel.language.text(.empty),
                systemImage: "note.text",
                description: Text(viewModel.language.text(.addNote))
            )
        }
    }

    private var filteredSelectedNotes: [Note] {
        let notes = viewModel.selectedTab?.notes ?? []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return notes }

        return notes.filter { note in
            viewModel.displayTitle(for: note).localizedCaseInsensitiveContains(
                query
            )
                || viewModel.displayBody(for: note)
                    .localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedTabTitle: String {
        guard let selectedTab = viewModel.selectedTab else {
            return viewModel.language.text(.notes)
        }

        return viewModel.displayTitle(for: selectedTab)
    }

    private var allNoteRows: [NoteMenuRow] {
        viewModel.document.tabs.flatMap { tab in
            tab.notes.map { note in
                NoteMenuRow(
                    tabID: tab.id,
                    tabTitle: viewModel.displayTitle(for: tab),
                    noteTitle: viewModel.displayTitle(for: note),
                    note: note
                )
            }
        }
    }

    private func displayNote(_ note: Note) -> Note {
        var displayNote = note
        displayNote.title = viewModel.displayTitle(for: note)
        displayNote.body = viewModel.displayBody(for: note)
        return displayNote
    }

    private func renameTabButton(_ tab: NoteTab) -> some View {
        Button(
            viewModel.language.text(.rename),
            systemImage: "pencil"
        ) {
            renamedTabTitle = viewModel.displayTitle(for: tab)
            viewModel.selectedTabID = tab.id
            isRenamingTab = true
        }
    }

    private func moveNoteMenu(_ note: Note) -> some View {
        Menu {
            ForEach(viewModel.document.tabs) { tab in
                Button {
                    viewModel.selectedNoteID = note.id
                    viewModel.moveSelectedNote(to: tab.id)
                } label: {
                    Label(
                        viewModel.displayTitle(for: tab),
                        systemImage: tab.id == viewModel.selectedTabID
                            ? "checkmark" : "folder"
                    )
                }
                .disabled(tab.id == viewModel.selectedTabID)
            }
        } label: {
            Label(
                viewModel.language == .german ? "Verschieben" : "Move",
                systemImage: "folder"
            )
        }
    }

    private func deleteDisplayedNotes(at offsets: IndexSet) {
        let notes = filteredSelectedNotes
        for index in offsets where notes.indices.contains(index) {
            viewModel.deleteNote(id: notes[index].id)
        }
    }

    private func moveDisplayedNotes(from source: IndexSet, to destination: Int)
    {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        viewModel.moveNotes(from: source, to: destination)
    }

    private func prepareRenameNote(_ row: NoteMenuRow) {
        renamedNoteID = row.note.id
        renamedNoteTabID = row.tabID
        renamedNoteTitle = row.noteTitle
        isRenamingNote = true
    }

    private func prepareRenameNote(_ note: Note) {
        renamedNoteID = note.id
        renamedNoteTabID = viewModel.selectedTabID
        renamedNoteTitle = viewModel.displayTitle(for: note)
        isRenamingNote = true
    }

    private func deleteNote(_ row: NoteMenuRow) {
        viewModel.deleteNote(id: row.note.id, in: row.tabID)
    }

    private func moveStartNotes(from source: IndexSet, to destination: Int) {
        var displayedRows = Array(allNoteRows.prefix(8))
        let movingRows = source.sorted().compactMap { index in
            displayedRows.indices.contains(index) ? displayedRows[index] : nil
        }
        guard let movingRow = movingRows.first else { return }

        for index in source.sorted(by: >)
        where displayedRows.indices.contains(index) {
            displayedRows.remove(at: index)
        }

        let removedBeforeDestination = source.filter { $0 < destination }.count
        let insertionIndex = max(
            0,
            min(displayedRows.count, destination - removedBeforeDestination)
        )
        let targetRow =
            displayedRows.indices.contains(insertionIndex)
            ? displayedRows[insertionIndex]
            : nil
        let fallbackTargetTabID = displayedRows.last?.tabID ?? movingRow.tabID

        viewModel.moveNote(
            id: movingRow.note.id,
            from: movingRow.tabID,
            to: targetRow?.tabID ?? fallbackTargetTabID,
            before: targetRow?.note.id
        )
    }

    private func selectNote(_ row: NoteMenuRow) {
        viewModel.selectedTabID = row.tabID
        viewModel.selectedNoteID = row.note.id
        path.append(Route.editor(row.note.id))
    }

    private func selectNote(_ note: Note) {
        viewModel.selectedNoteID = note.id
        path.append(Route.editor(note.id))
    }

    private func addTabIfAllowed() {
        guard storeViewModel.canCreateTab(currentTabs: viewModel.tabCount)
        else {
            showLimitAlert(for: .tabs)
            return
        }

        viewModel.addTab()
        path.append(Route.notes)
    }

    private func addNoteIfAllowed() {
        guard canCreateNote() else {
            return
        }

        viewModel.addNote()
        if let selectedNoteID = viewModel.selectedNoteID {
            path.append(Route.editor(selectedNoteID))
        }
    }

    private func canCreateNote() -> Bool {
        guard
            storeViewModel.canCreateNote(
                currentNotes: viewModel.noteCount,
                currentStorageMegabytes: viewModel.storageMegabytesUsed
            )
        else {
            let resource: SynoraLimitResource =
                viewModel.noteCount >= storeViewModel.effectiveLimits.notes
                ? .notes : .storage
            showLimitAlert(for: resource)
            return false
        }

        return true
    }

    private func showLimitAlert(for resource: SynoraLimitResource) {
        limitAlertMessage = storeViewModel.limitMessage(
            for: resource,
            language: viewModel.language
        )
        isShowingLimitAlert = true
    }

    private func requestReviewIfNeeded(title: String, body: String) {
        guard isMeaningfulWrittenNote(title: title, body: body) else {
            return
        }

        guard reviewPromptManager.shouldRequestReviewAfterFirstWrittenNote()
        else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            requestReview()
        }
    }

    private func isMeaningfulWrittenNote(title: String, body: String) -> Bool {
        let cleanedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedBody.count >= 3 {
            return true
        }

        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultTitles = Set(AppContent.shared.texts(for: .newNote))
        return cleanedTitle.count >= 3 && !defaultTitles.contains(cleanedTitle)
    }
}

private struct NoteMenuRow: Identifiable {
    let tabID: NoteTab.ID
    let tabTitle: String
    let noteTitle: String
    let note: Note

    var id: Note.ID { note.id }
}

private struct StartView: View {
    let viewModel: NotesViewModel
    let noteRows: [NoteMenuRow]
    let onNewNote: () -> Void
    let onNewTab: () -> Void
    let onSelectNote: (NoteMenuRow) -> Void
    let onRenameNote: (NoteMenuRow) -> Void
    let onDeleteNote: (NoteMenuRow) -> Void
    let onMoveNotes: (IndexSet, Int) -> Void
    let onSettings: () -> Void
    let onShowOnboarding: () -> Void
    let onShowTabs: () -> Void

    var body: some View {
        List {
            Section(viewModel.language.text(.beginNew)) {
                Button(action: onNewNote) {
                    Label(
                        viewModel.language.text(.addNote),
                        systemImage: "square.and.pencil"
                    )
                }

                Button(action: onNewTab) {
                    Label(
                        viewModel.language.text(.addTab),
                        systemImage: "folder.badge.plus"
                    )
                }
            }

            Section(viewModel.language.text(.recentNotes)) {
                ForEach(displayedRows) { row in
                    Button {
                        onSelectNote(row)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.noteTitle)
                                .font(.headline)
                            Text(row.tabTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(
                            viewModel.language.text(.rename),
                            systemImage: "pencil"
                        ) {
                            onRenameNote(row)
                        }

                        Button(
                            viewModel.language.text(.delete),
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            onDeleteNote(row)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            onRenameNote(row)
                        } label: {
                            Label(
                                viewModel.language.text(.rename),
                                systemImage: "pencil"
                            )
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDeleteNote(row)
                        } label: {
                            Label(
                                viewModel.language.text(.delete),
                                systemImage: "trash"
                            )
                        }
                    }
                }
                .onDelete { offsets in
                    let rows = displayedRows
                    for index in offsets where rows.indices.contains(index) {
                        onDeleteNote(rows[index])
                    }
                }
                .onMove(perform: onMoveNotes)

                if noteRows.isEmpty {
                    ContentUnavailableView(
                        viewModel.language.text(.empty),
                        systemImage: "note.text",
                        description: Text(viewModel.language.text(.addNote))
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: onShowOnboarding) {
                    Label(
                        viewModel.language == .german
                            ? "Einführung" : "Onboarding",
                        systemImage: "questionmark.circle"
                    )
                }

                Button(action: onShowTabs) {
                    Label(
                        viewModel.language.text(.tabs),
                        systemImage: "folder"
                    )
                }

                Button(action: onSettings) {
                    Label(
                        viewModel.language.text(.settings),
                        systemImage: "gear"
                    )
                }
            }
        }
    }

    private var displayedRows: [NoteMenuRow] {
        Array(noteRows.prefix(8))
    }
}

#Preview {
    NoteView(
        viewModel: NotesViewModel(),
        storeViewModel: StoreViewModel(configuration: .fallback),
        reviewPromptManager: ReviewPromptManager(),
        onShowSubscriptionPlans: {}
    )
}
