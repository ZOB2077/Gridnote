import Foundation

final class AppState: ObservableObject {
    @Published var selectedBookID: UUID?

    func selectBook(_ bookID: UUID) {
        selectedBookID = bookID
    }
}
