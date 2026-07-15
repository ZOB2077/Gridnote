import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LibraryContent(context: modelContext) { bookID in
            appState.selectBook(bookID)
            dismiss()
        }
    }
}

private struct LibraryContent: View {
    @StateObject private var viewModel: LibraryViewModel
    let openBook: (UUID) -> Void

    init(context: ModelContext, openBook: @escaping (UUID) -> Void) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(context: context))
        self.openBook = openBook
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                TextField("Search books", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(12)
                    .accessibilityIdentifier("library-search")
                List(viewModel.filteredItems, selection: $viewModel.selectedBookID) { item in
                    LibraryRowView(item: item).tag(item.id)
                }
                .accessibilityIdentifier("library-list")
            }
            .navigationTitle("Library")
            .frame(minWidth: 260)
        } detail: {
            if let item = viewModel.selectedItem {
                LibraryDetailView(item: item)
                .toolbar {
                    ToolbarItemGroup {
                        Button("Select") { openBook(item.id) }.accessibilityIdentifier("library-read")
                        Button("Relink") { viewModel.beginRelink() }.accessibilityIdentifier("library-relink")
                        Button("Remove", role: .destructive) { viewModel.isConfirmingRemoval = true }.accessibilityIdentifier("library-remove")
                    }
                }
            } else {
                ContentUnavailableView("Select a book", systemImage: "books.vertical")
            }
        }
        .frame(minWidth: 820, minHeight: 560)
        .task { viewModel.reload() }
        .fileImporter(isPresented: $viewModel.isRelinkerPresented, allowedContentTypes: ImportService.supportedContentTypes) { result in
            if case .success(let url) = result { viewModel.relink(to: url) }
        }
        .confirmationDialog("Remove this book from the library?", isPresented: $viewModel.isConfirmingRemoval) {
            Button("Remove from Library", role: .destructive) { viewModel.removeSelectedBook() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The original file will not be deleted.")
        }
        .alert("Library Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
    }
}

private struct LibraryRowView: View {
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.displayTitle)
                .fontWeight(.medium)
                .accessibilityIdentifier("library-row-title")
            HStack {
                Text(item.format.rawValue.uppercased())
                if item.sourceStatus != .available { Text(item.sourceStatus.rawValue) }
            }
            .font(.caption)
            .foregroundStyle(item.sourceStatus == .available ? Color.secondary : Color.red)
        }
    }
}

private struct LibraryDetailView: View {
    let item: LibraryItem

    var body: some View {
        Form {
            LabeledContent("Display name", value: item.displayTitle)
            LabeledContent("Actual title", value: item.actualTitle)
                .accessibilityIdentifier("library-actual-title")
            if let author = item.author { LabeledContent("Author", value: author) }
            LabeledContent("Format", value: item.format.rawValue.uppercased())
            LabeledContent("Source status", value: item.sourceStatus.rawValue)
                .accessibilityIdentifier("library-source-status")
            LabeledContent("File", value: item.sourcePath)
        }
        .formStyle(.grouped)
    }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var items: [LibraryItem] = []
    @Published var searchText = ""
    @Published var selectedBookID: UUID?
    @Published var isRelinkerPresented = false
    @Published var isConfirmingRemoval = false
    @Published var errorMessage: String?

    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    var filteredItems: [LibraryItem] { items.filter { $0.matches(searchText) } }
    var selectedItem: LibraryItem? { items.first { $0.id == selectedBookID } }

    func reload() {
        do {
            items = try LibraryRepository(context: context).fetchItems()
            if selectedBookID == nil || !items.contains(where: { $0.id == selectedBookID }) { selectedBookID = items.first?.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func beginRelink() { isRelinkerPresented = selectedBookID != nil }

    func relink(to url: URL) {
        guard let selectedBookID else { return }
        do {
            guard let record = try BookRepository(context: context).fetch(id: selectedBookID) else { return }
            try ImportService(context: context).relink(record: record, to: url)
            reload()
        } catch { errorMessage = error.localizedDescription }
    }

    func removeSelectedBook() {
        guard let selectedBookID else { return }
        do {
            try LibraryRepository(context: context).removeBook(id: selectedBookID)
            self.selectedBookID = nil
            reload()
        } catch { errorMessage = error.localizedDescription }
    }
}
