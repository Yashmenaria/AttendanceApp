import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var employee: Employee
    @Published var todayRecord: AttendanceRecord
    @Published var isLoading: Bool = false
    @Published var isActionLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var successToastMessage: String? = nil
    
    @Published var liveWorkingSeconds: TimeInterval = 0
    @Published var aiInsights: [AIInsight] = []
    
    // Quick Dashboard Summary Stats
    @Published var weekTotalHours: Double = 34.5
    @Published var punctualityScore: Int = 96
    @Published var daysPresentThisMonth: Int = 18
    
    private let repository: AttendanceRepositoryProtocol
    private let cacheService: AttendanceCacheServiceProtocol
    private let aiEngine: AIInsightsEngineProtocol
    private var timerCancellable: AnyCancellable?
    
    init(
        repository: AttendanceRepositoryProtocol? = nil,
        cacheService: AttendanceCacheServiceProtocol? = nil,
        aiEngine: AIInsightsEngineProtocol? = nil
    ) {
        let repo = repository ?? AttendanceRepository.shared
        let cache = cacheService ?? AttendanceCacheService.shared
        let ai = aiEngine ?? AIInsightsEngine.shared
        
        self.repository = repo
        self.cacheService = cache
        self.aiEngine = ai
        
        let loadedEmployee = cache.loadEmployeeProfile() ?? Employee.sample
        self.employee = loadedEmployee
        
        let initialRecord = cache.loadTodayRecord() ?? AttendanceRecord(
            date: Date(),
            checkInTime: nil,
            checkOutTime: nil,
            status: .notCheckedIn,
            location: "San Francisco HQ"
        )
        self.todayRecord = initialRecord
        
        startLiveTimerIfNeeded()
        updateInsights()
    }
    
    func onAppear() {
        Task {
            await fetchTodayData(forceRefresh: false)
        }
    }
    
    func fetchTodayData(forceRefresh: Bool = false) async {
        // Avoid flashing loader if cache already provided instant UI
        if todayRecord.checkInTime == nil {
            isLoading = true
        }
        
        do {
            let record = try await repository.getTodayAttendance(forceRefresh: forceRefresh)
            self.todayRecord = record
            self.startLiveTimerIfNeeded()
            self.updateInsights()
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
    }
    
    func checkIn() {
        guard todayRecord.checkInTime == nil else { return }
        
        isActionLoading = true
        HapticManager.shared.impact(style: .heavy)
        
        // Optimistic UI update for instantaneous perceived performance
        let optimisticRecord = AttendanceRecord(
            date: Date(),
            checkInTime: Date(),
            checkOutTime: nil,
            status: .checkedIn,
            location: "San Francisco HQ",
            isSyncedWithServer: false
        )
        self.todayRecord = optimisticRecord
        self.startLiveTimerIfNeeded()
        
        Task {
            do {
                let confirmedRecord = try await repository.checkIn(location: "San Francisco HQ")
                self.todayRecord = confirmedRecord
                self.isActionLoading = false
                self.successToastMessage = "Check-In Recorded Successfully! Have a productive day."
                HapticManager.shared.notification(type: .success)
                self.updateInsights()
            } catch {
                self.isActionLoading = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                // Revert optimistic if hard failure
                self.todayRecord.checkInTime = nil
                self.todayRecord.status = .notCheckedIn
                self.stopTimer()
                HapticManager.shared.notification(type: .error)
            }
        }
    }
    
    func checkOut() {
        guard todayRecord.checkInTime != nil, todayRecord.checkOutTime == nil else { return }
        
        isActionLoading = true
        HapticManager.shared.impact(style: .heavy)
        
        let now = Date()
        self.todayRecord.checkOutTime = now
        self.todayRecord.status = .completed
        self.stopTimer()
        
        Task {
            do {
                let confirmedRecord = try await repository.checkOut(location: "San Francisco HQ")
                self.todayRecord = confirmedRecord
                self.isActionLoading = false
                self.successToastMessage = "Check-Out Complete. Shift logged: \(confirmedRecord.totalWorkingHoursString)"
                HapticManager.shared.notification(type: .success)
                self.updateInsights()
            } catch {
                self.isActionLoading = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                HapticManager.shared.notification(type: .error)
            }
        }
    }
    
    private func startLiveTimerIfNeeded() {
        guard let checkIn = todayRecord.checkInTime, todayRecord.checkOutTime == nil else {
            if let checkIn = todayRecord.checkInTime, let checkOut = todayRecord.checkOutTime {
                liveWorkingSeconds = checkOut.timeIntervalSince(checkIn)
            } else {
                liveWorkingSeconds = 0
            }
            stopTimer()
            return
        }
        
        liveWorkingSeconds = max(0, Date().timeIntervalSince(checkIn))
        
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let checkIn = self.todayRecord.checkInTime, self.todayRecord.checkOutTime == nil else {
                    return
                }
                self.liveWorkingSeconds = max(0, Date().timeIntervalSince(checkIn))
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    func updateInsights() {
        let history = cacheService.loadRecentHistory() ?? []
        self.aiInsights = aiEngine.generateInsights(
            todayRecord: todayRecord,
            employee: employee,
            recentHistory: history
        )
    }
    
    var progressTowardsDailyTarget: Double {
        let targetSeconds = employee.targetDailyHours * 3600.0
        guard targetSeconds > 0 else { return 0 }
        return min(1.0, liveWorkingSeconds / targetSeconds)
    }
    
    var isCurrentlyWorking: Bool {
        todayRecord.checkInTime != nil && todayRecord.checkOutTime == nil
    }
    
    var hasCompletedWorkToday: Bool {
        todayRecord.checkInTime != nil && todayRecord.checkOutTime != nil
    }
}
