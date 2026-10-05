import SwiftUI
import Combine

@MainActor
final class ProfileSettingsViewModel: ObservableObject {
    @Published var employee: Employee
    @Published var performanceMetrics: PerformanceMetrics
    @Published var simulateSlowNetwork: Bool = false
    @Published var simulateRandomErrors: Bool = false
    @Published var isOfflineMode: Bool = false
    @Published var isLoading: Bool = false
    @Published var isSyncing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var toastMessage: String? = nil
    
    private let repository: AttendanceRepositoryProtocol
    private let cacheService: AttendanceCacheServiceProtocol
    
    init(
        repository: AttendanceRepositoryProtocol? = nil,
        cacheService: AttendanceCacheServiceProtocol? = nil
    ) {
        let repo = repository ?? AttendanceRepository.shared
        let cache = cacheService ?? AttendanceCacheService.shared
        self.repository = repo
        self.cacheService = cache
        self.employee = cache.loadEmployeeProfile() ?? Employee.sample
        self.performanceMetrics = repo.getMetrics()
    }
    
    func refreshMetrics() {
        self.performanceMetrics = repository.getMetrics()
    }
    
    /// Dummy API call to fetch employee profile: `GET /api/v1/employees/{id}`
    func fetchProfile() async {
        isLoading = true
        do {
            let fetched = try await repository.getEmployeeProfile(forceRefresh: true)
            self.employee = fetched
            self.isLoading = false
            self.toastMessage = "Profile synced with server."
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
    }
    
    /// Dummy API call to update employee profile: `PUT /api/v1/employees/{id}`
    func saveProfile() {
        isLoading = true
        Task {
            do {
                let updated = try await repository.updateEmployeeProfile(employee)
                self.employee = updated
                self.isLoading = false
                self.toastMessage = "Profile settings saved and synced successfully."
                HapticManager.shared.notification(type: .success)
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                HapticManager.shared.notification(type: .error)
            }
        }
    }
    
    /// Dummy API call to flush queued offline records: `POST /api/v1/attendance/sync-offline`
    func syncOfflineQueue() {
        isSyncing = true
        Task {
            do {
                let count = try await repository.syncPendingOfflineRecords()
                self.isSyncing = false
                if count > 0 {
                    self.toastMessage = "Successfully synced \(count) offline records to server."
                } else {
                    self.toastMessage = "All attendance records are up to date."
                }
                HapticManager.shared.notification(type: .success)
            } catch {
                self.isSyncing = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    func clearLocalCache() {
        cacheService.clearCache()
        repository.resetMetrics()
        refreshMetrics()
        toastMessage = "Local cache cleared. Fresh data will be fetched on next request."
        HapticManager.shared.notification(type: .warning)
    }
    
    func toggleSlowNetwork(enabled: Bool) {
        simulateSlowNetwork = enabled
        AttendanceAPIService.shared.simulateNetworkLatency = enabled ? 2.5 : 0.35
    }
    
    func toggleRandomErrors(enabled: Bool) {
        simulateRandomErrors = enabled
        AttendanceAPIService.shared.shouldSimulateRandomFailure = enabled
    }
}

