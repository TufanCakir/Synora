//
//  NoteView.swift
//  Synora
//
//  Created by Tufan Cakir on 16.05.26.
//

import SwiftUI

struct NoteView: View {
    let viewModel: NotesViewModel
    @State private var speechService = SpeechNoteService()
    @State private var isRenamingTab = false
    @State private var isShowingStart = true
    @State private var renamedTabTitle = ""
    @State private var searchText = ""
    @State private var voiceDraft = ""

    var body: some View {
        NavigationSplitView {
            tabList
        } content: {
            noteList
        } detail: {
            if isShowingStart {
                StartView(
                    viewModel: viewModel,
                    noteRows: allNoteRows,
                    onNewNote: {
                        viewModel.addNote()
                        isShowingStart = false
                    },
                    onNewTab: {
                        viewModel.addTab()
                        isShowingStart = false
                    },
                    onSelectNote: selectNote
                )
            } else {
                editor
            }
        }
        .navigationTitle(viewModel.language.text(.appTitle))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleVoiceInput()
                } label: {
                    Label(
                        viewModel.language.text(.voice),
                        systemImage: speechService.isRecording
                            ? "waveform.circle.fill" : "mic"
                    )
                }
                .tint(speechService.isRecording ? .red : nil)
            }
        }
        .alert(viewModel.language.text(.rename), isPresented: $isRenamingTab) {
            TextField(viewModel.language.text(.title), text: $renamedTabTitle)
            Button(viewModel.language.text(.save)) {
                viewModel.renameSelectedTab(to: renamedTabTitle)
            }
            Button(viewModel.language.text(.cancel), role: .cancel) {}
        }
        .alert(viewModel.language.text(.voice), isPresented: voiceErrorBinding)
        {
            Button("OK", role: .cancel) {}
        } message: {
            Text(speechService.lastError ?? "")
        }
    }

    private var tabList: some View {
        List(selection: selectedTabBinding) {
            Section {
                Button {
                    isShowingStart = true
                    viewModel.selectedNoteID = nil
                } label: {
                    Label(viewModel.language.text(.start), systemImage: "house")
                }
            }

            Section(viewModel.language.text(.tabs)) {
                ForEach(viewModel.document.tabs) { tab in
                    Label(
                        viewModel.displayTitle(for: tab),
                        systemImage: "folder"
                    )
                    .tag(tab.id)
                    .contextMenu {
                        Button(
                            viewModel.language.text(.rename),
                            systemImage: "pencil"
                        ) {
                            renamedTabTitle = viewModel.displayTitle(for: tab)
                            viewModel.selectedTabID = tab.id
                            isRenamingTab = true
                        }
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
                }
                .onDelete(perform: viewModel.deleteTabs)
                .onMove(perform: viewModel.moveTabs)
            }
        }
        .navigationTitle(viewModel.language.text(.tabs))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.addTab()
                } label: {
                    Label(viewModel.language.text(.addTab), systemImage: "plus")
                }
            }
        }
    }

    private var noteList: some View {
        List(selection: selectedNoteBinding) {
            Section(selectedTabTitle) {
                ForEach(filteredSelectedNotes) { note in
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
                    .padding(.vertical, 4)
                    .background(
                        note.style.isMarked
                            ? note.style.markerColor.color.opacity(0.18)
                            : Color.clear
                    )
                    .tag(note.id)
                    .onTapGesture {
                        viewModel.selectedNoteID = note.id
                        isShowingStart = false
                    }
                }
                .onDelete(perform: viewModel.deleteNotes)
                .onMove(perform: viewModel.moveNotes)

                if filteredSelectedNotes.isEmpty, !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .navigationTitle(viewModel.language.text(.notes))
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
                    Button {
                        isShowingStart = true
                    } label: {
                        Label(
                            viewModel.language.text(.start),
                            systemImage: "house"
                        )
                    }

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
                    viewModel.addNote()
                    isShowingStart = false
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
                viewModel.updateSelectedNote(
                    title: title,
                    body: body,
                    style: style
                )
            }
        } else {
            ContentUnavailableView(
                viewModel.language.text(.empty),
                systemImage: "note.text",
                description: Text(viewModel.language.text(.addNote))
            )
        }
    }

    private var voiceErrorBinding: Binding<Bool> {
        Binding(
            get: { speechService.lastError != nil },
            set: { isPresented in
                if !isPresented {
                    speechService.lastError = nil
                }
            }
        )
    }

    private var selectedTabBinding: Binding<NoteTab.ID?> {
        Binding(
            get: { viewModel.selectedTabID },
            set: { viewModel.selectedTabID = $0 }
        )
    }

    private var selectedNoteBinding: Binding<Note.ID?> {
        Binding(
            get: { viewModel.selectedNoteID },
            set: {
                viewModel.selectedNoteID = $0
                if $0 != nil {
                    isShowingStart = false
                }
            }
        )
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
        .sorted { $0.note.updatedAt > $1.note.updatedAt }
    }

    private func displayNote(_ note: Note) -> Note {
        var displayNote = note
        displayNote.title = viewModel.displayTitle(for: note)
        displayNote.body = viewModel.displayBody(for: note)
        return displayNote
    }

    private func selectNote(_ row: NoteMenuRow) {
        viewModel.selectedTabID = row.tabID
        viewModel.selectedNoteID = row.note.id
        isShowingStart = false
    }

    private func toggleVoiceInput() {
        if speechService.isRecording {
            speechService.stop()
            viewModel.addVoiceNote(text: voiceDraft)
            isShowingStart = false
            voiceDraft = ""
        } else {
            voiceDraft = ""
            speechService.start(language: viewModel.language) { text in
                voiceDraft = text
            }
        }
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
                ForEach(noteRows.prefix(8)) { row in
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
                }

                if noteRows.isEmpty {
                    ContentUnavailableView(
                        viewModel.language.text(.empty),
                        systemImage: "note.text",
                        description: Text(viewModel.language.text(.addNote))
                    )
                }
            }
        }
        .navigationTitle(viewModel.language.text(.start))
    }
}

#Preview {
    NoteView(viewModel: NotesViewModel())
}
