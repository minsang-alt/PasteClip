import SwiftUI

@MainActor
@Observable
final class SearchState {
    var searchText: String = ""
    var debouncedSearchText: String = ""
    var selectedContentTypes: Set<ContentType> = []
    var dateFilter: DateFilter = .all
    var selectedIndex: Int? = nil

    private var debounceTask: Task<Void, Never>?

    enum DateFilter: String, CaseIterable, Sendable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .all: return nil
            case .today: return calendar.startOfDay(for: Date())
            case .thisWeek:
                return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))
            case .thisMonth:
                return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))
            }
        }
    }

    var isActive: Bool {
        !searchText.isEmpty || !selectedContentTypes.isEmpty || dateFilter != .all
    }

    func updateSearch(_ text: String) {
        searchText = text
        selectedIndex = nil
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            debouncedSearchText = text
        }
    }

    func reset() {
        searchText = ""
        debouncedSearchText = ""
        selectedContentTypes = []
        dateFilter = .all
        selectedIndex = nil
        debounceTask?.cancel()
    }

    func clearSearch() {
        searchText = ""
        debouncedSearchText = ""
        selectedIndex = nil
        debounceTask?.cancel()
    }

    func toggleContentType(_ type: ContentType) {
        if selectedContentTypes.contains(type) {
            selectedContentTypes.remove(type)
        } else {
            selectedContentTypes.insert(type)
        }
        selectedIndex = nil
    }

    func filteredItems(from items: [ClipboardItem]) -> [ClipboardItem] {
        var result = items

        if let startDate = dateFilter.startDate {
            result = result.filter { $0.copiedAt >= startDate }
        }

        if !selectedContentTypes.isEmpty {
            result = result.filter { selectedContentTypes.contains($0.contentType) }
        }

        if !debouncedSearchText.isEmpty {
            let query = debouncedSearchText
            result = result.filter { item in
                (item.textContent?.localizedCaseInsensitiveContains(query) ?? false) ||
                (item.sourceAppName?.localizedCaseInsensitiveContains(query) ?? false) ||
                (item.userTitle?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }

        return result
    }

    func moveSelection(by offset: Int, maxIndex: Int) {
        guard maxIndex >= 0 else { selectedIndex = nil; return }
        if let current = selectedIndex {
            selectedIndex = max(0, min(current + offset, maxIndex))
        } else {
            selectedIndex = offset > 0 ? 0 : maxIndex
        }
    }
}
