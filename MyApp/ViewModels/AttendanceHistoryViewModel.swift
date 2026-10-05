import SwiftUI
import Combine

enum HistoryFilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case onTime = "On Time"
    case late = "Late"
    case overtime = "Overtime"
    
    var id: String { rawValue }
}

@MainActor
final class AttendanceHistoryViewModel: ObservableObject {
    @Published var records: [AttendanceRecord] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var selectedFilter: HistoryFilterOption = .all
    @Published var searchText: String = ""
    
    private var currentPage: Int = 1
    private let pageSize: Int = 15
    private let repository: AttendanceRepositoryProtocol
    
    init(repository: AttendanceRepositoryProtocol? = nil) {
        self.repository = repository ?? AttendanceRepository.shared
    }
    
    var filteredRecords: [AttendanceRecord] {
        records.filter { record in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .onTime:
                matchesFilter = record.status == .onTime || record.status == .completed
            case .late:
                matchesFilter = record.status == .late
            case .overtime:
                matchesFilter = record.status == .overtime
            }
            
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = record.dateString.localizedCaseInsensitiveContains(searchText) ||
                                (record.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                                (record.location?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            
            return matchesFilter && matchesSearch
        }
    }
    
    var totalHoursWorked: Double {
        records.reduce(0) { $0 + ($1.totalWorkingSeconds / 3600.0) }
    }
    
    var onTimePercentage: Double {
        guard !records.isEmpty else { return 100.0 }
        let onTimeCount = records.filter { $0.status == .onTime || $0.status == .completed }.count
        return (Double(onTimeCount) / Double(records.count)) * 100.0
    }
    
    var averageDailyHours: Double {
        guard !records.isEmpty else { return 8.0 }
        return totalHoursWorked / Double(records.count)
    }
    
    func loadInitialHistory(forceRefresh: Bool = false) async {
        guard records.isEmpty || forceRefresh else { return }
        
        currentPage = 1
        isLoading = true
        errorMessage = nil
        
        do {
            let loaded = try await repository.getAttendanceHistory(page: currentPage, pageSize: pageSize, forceRefresh: forceRefresh)
            self.records = loaded
            self.hasMorePages = loaded.count >= pageSize
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
    }
    
    func loadMoreIfNeeded(currentItem: AttendanceRecord) {
        guard !isLoadingMore, hasMorePages else { return }
        
        // Threshold: trigger pagination when 3 items before the end
        let thresholdIndex = max(0, records.count - 3)
        if let currentIndex = records.firstIndex(where: { $0.id == currentItem.id }), currentIndex >= thresholdIndex {
            loadNextPage()
        }
    }
    
    private func loadNextPage() {
        isLoadingMore = true
        currentPage += 1
        
        Task {
            do {
                let nextRecords = try await repository.getAttendanceHistory(page: currentPage, pageSize: pageSize, forceRefresh: false)
                if nextRecords.isEmpty {
                    self.hasMorePages = false
                } else {
                    self.records.append(contentsOf: nextRecords)
                    self.hasMorePages = nextRecords.count >= self.pageSize
                }
                self.isLoadingMore = false
            } catch {
                self.isLoadingMore = false
                self.currentPage -= 1 // rollback
            }
        }
    }
    
    func refresh() async {
        await loadInitialHistory(forceRefresh: true)
    }
}
