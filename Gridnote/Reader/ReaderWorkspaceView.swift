import SwiftUI
import SwiftData

struct ReaderWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    var body: some View { ReaderWorkspaceContent(context: modelContext) }
}

private struct ReaderWorkspaceContent: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ReaderViewModel
    @State private var showsSearch = false
    @State private var showsBookmarks = false
    @State private var searchQuery = ""

    init(context: ModelContext) { _viewModel = StateObject(wrappedValue: ReaderViewModel(context: context)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if showsSearch { searchBar }
            ScrollView {
                Text(viewModel.currentText)
                    .font(.system(size: viewModel.fontSize))
                    .lineSpacing(viewModel.lineHeight)
                    .foregroundStyle(viewModel.textColor.opacity(viewModel.textOpacity))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(32)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("reader-text")
                    .accessibilityLabel(viewModel.currentText)
            }
            .accessibilityIdentifier("reader-workspace")
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(readerBackground)
        .task(id: appState.selectedBookID) { viewModel.load(bookID: appState.selectedBookID) }
        .onDisappear { viewModel.saveProgress() }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteWillEnterOffice)) { _ in viewModel.saveProgress() }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteReaderSettingsDidChange)) { _ in viewModel.reloadSettings() }
        .onExitCommand { appState.showOffice() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title).font(.headline).lineLimit(1)
                Text(viewModel.progressText).font(.caption).foregroundStyle(.secondary)
                    .accessibilityIdentifier("reader-progress")
            }
            Spacer()
            Button { showsSearch.toggle() } label: { Image(systemName: "magnifyingglass") }
                .keyboardShortcut("f", modifiers: .command).help("Search")
            Button(action: viewModel.toggleBookmark) {
                Image(systemName: viewModel.isCurrentLocationBookmarked ? "bookmark.fill" : "bookmark")
            }
            .keyboardShortcut("b", modifiers: .command).help("Toggle bookmark")
            Button { showsBookmarks.toggle() } label: { Image(systemName: "bookmark.square") }
                .popover(isPresented: $showsBookmarks) { bookmarkList }
            Button("Office") { viewModel.saveProgress(); appState.showOffice() }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("return-to-office")
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField("Search current book", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .onSubmit { viewModel.search(for: searchQuery) }
            Button("Go") { viewModel.search(for: searchQuery) }
            Text(viewModel.searchResultText).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Previous") { viewModel.previousBlock() }
                .keyboardShortcut(.leftArrow, modifiers: []).disabled(!viewModel.canGoPrevious)
                .accessibilityIdentifier("reader-previous")
            Button("Next") { viewModel.nextBlock() }
                .keyboardShortcut(.rightArrow, modifiers: []).disabled(!viewModel.canGoNext)
                .accessibilityIdentifier("reader-next")
            Button { viewModel.nextBlock() } label: { Image(systemName: "space") }
                .keyboardShortcut(.space, modifiers: []).help("Next paragraph")
            Slider(value: Binding(get: { viewModel.progressFraction }, set: { viewModel.seek(to: $0) }), in: 0...1)
                .frame(minWidth: 120)
            Text("\(Int((viewModel.progressFraction * 100).rounded()))%")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            Spacer()
            Text("Font").foregroundStyle(.secondary)
            Slider(value: Binding(get: { viewModel.fontSize }, set: { viewModel.updateFontSize($0) }), in: 13...28, step: 1)
                .frame(width: 160).accessibilityIdentifier("reader-font-size")
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var bookmarkList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bookmarks").font(.headline)
            if viewModel.bookmarks.isEmpty { Text("No bookmarks").foregroundStyle(.secondary) }
            else {
                List(viewModel.bookmarks) { bookmark in
                    HStack {
                        Button(bookmark.excerpt) { showsBookmarks = false; viewModel.jump(to: bookmark) }
                            .buttonStyle(.plain).lineLimit(1)
                        Spacer()
                        Button(role: .destructive) { viewModel.deleteBookmark(bookmark) } label: { Image(systemName: "trash") }
                            .buttonStyle(.plain)
                    }
                }
                .frame(height: min(CGFloat(viewModel.bookmarks.count) * 38, 220))
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    private var readerBackground: Color {
        switch viewModel.theme {
        case "paper": Color(red: 0.96, green: 0.93, blue: 0.84)
        case "dark": Color(red: 0.11, green: 0.12, blue: 0.12)
        default: Color(nsColor: .windowBackgroundColor)
        }
    }
}
