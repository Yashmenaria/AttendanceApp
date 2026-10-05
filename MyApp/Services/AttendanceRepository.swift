import Foundation

protocol AttendanceRepositoryProtocol {
    // 1. Home Screen API Calls
    func getTodayAttendance(forceRefresh: Bool) async throws -> AttendanceRecord
    func checkIn(location: String?, notes: String?) async throws -> AttendanceRecord
    func checkIn(location: String?) async throws -> AttendanceRecord
    func checkOut(location: String?, notes: String?) async throws -> AttendanceRecord
    func checkOut(location: String?) async throws -> AttendanceRecord
    
    // 2. Attendance History Screen API Calls
    func getAttendanceHistory(page: Int, pageSize: Int, forceRefresh: Bool) async throws -> [AttendanceRecord]
    func getAttendanceHistory(page: Int, pageSize: Int, forceRefresh: Bool, status: String?, search: String?) async throws -> [AttendanceRecord]
    
    // 3. AI Insights Service API Calls
    func getAIInsights(forceRefresh: Bool) async throws -> [AIInsight]
    func updateAIPreferences(autoReminder: Bool, departurePredictor: Bool) async throws -> Bool
    
    // 4. Profile & Diagnostic API Calls
    func getEmployeeProfile(forceRefresh: Bool) async throws -> Employee
    func updateEmployeeProfile(_ employee: Employee) async throws -> Employee
    func syncPendingOfflineRecords() async throws -> Int
    
    // 5. Diagnostics
    func getMetrics() -> PerformanceMetrics
    func resetMetrics()
}

final class AttendanceRepository: AttendanceRepositoryProtocol {
    static let shared = AttendanceRepository()
    
    private let apiService: AttendanceAPIServiceProtocol
    private let cacheService: AttendanceCacheServiceProtocol
    
    // In-flight task deduplication to prevent duplicate parallel requests (Finding 4)
    private var inFlightTodayTask: Task<AttendanceRecord, Error>?
    private var inFlightHistoryTasks: [Int: Task<[AttendanceRecord], Error>] = [:]
    private var inFlightInsightsTask: Task<[AIInsight], Error>?
    
    // Metrics tracking
    private var cachedRequests: Int = 0
    private var networkRequests: Int = 0
    private var totalResponseTimeMs: Double = 0
    private var isOptimized: Bool = true
    
    init(
        apiService: AttendanceAPIServiceProtocol = AttendanceAPIService.shared,
        cacheService: AttendanceCacheServiceProtocol = AttendanceCacheService.shared
    ) {
        self.apiService = apiService
        self.cacheService = cacheService
    }
    
    // MARK: - 1. Home Screen Methods
    func getTodayAttendance(forceRefresh: Bool = false) async throws -> AttendanceRecord {
        let employee = cacheService.loadEmployeeProfile() ?? Employee.sample
        
        // 1. If cache is valid and not forced, return cached record immediately (Finding 1 & 3)
        if !forceRefresh, !cacheService.isCacheExpired(for: "cached_today_record", ttlSeconds: 180) {
            if let cached = cacheService.loadTodayRecord() {
                cachedRequests += 1
                return cached
            }
        }
        
        // 2. Request deduplication: if already fetching, reuse the in-flight task (Finding 4)
        if let ongoing = inFlightTodayTask {
            return try await ongoing.value
        }
        
        let task = Task<AttendanceRecord, Error> {
            let startTime = CFAbsoluteTimeGetCurrent()
            defer { self.inFlightTodayTask = nil }
            
            do {
                let record = try await self.apiService.fetchTodayAttendance(for: employee.id)
                let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                self.networkRequests += 1
                self.totalResponseTimeMs += elapsedMs
                self.cacheService.saveTodayRecord(record)
                return record
            } catch {
                // Offline fallback
                if let fallback = self.cacheService.loadTodayRecord() {
                    self.cachedRequests += 1
                    return fallback
                }
                throw error
            }
        }
        
        self.inFlightTodayTask = task
        return try await task.value
    }
    
    func checkIn(location: String?, notes: String?) async throws -> AttendanceRecord {
        let employee = cacheService.loadEmployeeProfile() ?? Employee.sample
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let record = try await apiService.checkIn(employeeId: employee.id, location: location, notes: notes)
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            networkRequests += 1
            totalResponseTimeMs += elapsedMs
            
            // Update cache immediately (optimistic consistency)
            cacheService.saveTodayRecord(record)
            return record
        } catch {
            // Save offline record in local cache when disconnected
            let offlineRecord = AttendanceRecord(
                date: Date(),
                checkInTime: Date(),
                checkOutTime: nil,
                status: .checkedIn,
                notes: notes ?? "Offline Check-in pending sync",
                location: location ?? "San Francisco HQ",
                isSyncedWithServer: false
            )
            cacheService.saveTodayRecord(offlineRecord)
            throw error
        }
    }
    
    func checkIn(location: String?) async throws -> AttendanceRecord {
        try await checkIn(location: location, notes: nil)
    }
    
    func checkOut(location: String?, notes: String?) async throws -> AttendanceRecord {
        let employee = cacheService.loadEmployeeProfile() ?? Employee.sample
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let record = try await apiService.checkOut(employeeId: employee.id, location: location, notes: notes)
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        networkRequests += 1
        totalResponseTimeMs += elapsedMs
        
        // Update cache immediately
        cacheService.saveTodayRecord(record)
        return record
    }
    
    func checkOut(location: String?) async throws -> AttendanceRecord {
        try await checkOut(location: location, notes: nil)
    }
    
    // MARK: - 2. Attendance History Methods
    func getAttendanceHistory(page: Int, pageSize: Int = 15, forceRefresh: Bool = false) async throws -> [AttendanceRecord] {
        try await getAttendanceHistory(page: page, pageSize: pageSize, forceRefresh: forceRefresh, status: nil, search: nil)
    }
    
    func getAttendanceHistory(page: Int, pageSize: Int = 15, forceRefresh: Bool = false, status: String? = nil, search: String? = nil) async throws -> [AttendanceRecord] {
        let employee = cacheService.loadEmployeeProfile() ?? Employee.sample
        
        // If page 1 with no custom filter, check cache if fresh (Finding 2: only load recent page first!)
        if page == 1 && !forceRefresh && status == nil && (search == nil || search?.isEmpty == true) && !cacheService.isCacheExpired(for: "cached_recent_history", ttlSeconds: 300) {
            if let cached = cacheService.loadRecentHistory(), !cached.isEmpty {
                cachedRequests += 1
                return cached
            }
        }
        
        if let ongoing = inFlightHistoryTasks[page] {
            return try await ongoing.value
        }
        
        let task = Task<[AttendanceRecord], Error> {
            let startTime = CFAbsoluteTimeGetCurrent()
            defer { self.inFlightHistoryTasks.removeValue(forKey: page) }
            
            do {
                let records = try await self.apiService.fetchAttendanceHistory(employeeId: employee.id, page: page, pageSize: pageSize, status: status, search: search)
                let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                self.networkRequests += 1
                self.totalResponseTimeMs += elapsedMs
                
                if page == 1 && status == nil && (search == nil || search?.isEmpty == true) {
                    self.cacheService.saveRecentHistory(records)
                }
                return records
            } catch {
                if page == 1, let fallback = self.cacheService.loadRecentHistory() {
                    self.cachedRequests += 1
                    return fallback
                }
                throw error
            }
        }
        
        self.inFlightHistoryTasks[page] = task
        return try await task.value
    }
    
    // MARK: - 3. AI Insights Methods
    func getAIInsights(forceRefresh: Bool = false) async throws -> [AIInsight] {
        let employee = cacheService.loadEmployeeProfile() ?? Employee.sample
        
        if !forceRefresh, !cacheService.isCacheExpired(for: "cached_ai_insights", ttlSeconds: 180) {
            if let cached = cacheService.loadAIInsights(), !cached.isEmpty {
                cachedRequests += 1
                return cached
            }
        }
        
        if let ongoing = inFlightInsightsTask {
            return try await ongoing.value
        }
        
        let task = Task<[AIInsight], Error> {
            let startTime = CFAbsoluteTimeGetCurrent()
            defer { self.inFlightInsightsTask = nil }
            
            let insights = try await self.apiService.fetchAIInsights(for: employee.id)
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            self.networkRequests += 1
            self.totalResponseTimeMs += elapsedMs
            self.cacheService.saveAIInsights(insights)
            return insights
        }
        
        self.inFlightInsightsTask = task
        return try await task.value
    }
    
    func updateAIPreferences(autoReminder: Bool, departurePredictor: Bool) async throws -> Bool {
        let employee = cacheService.loadEmployeeProfile() ?? Employee.sample
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let success = try await apiService.updateAIPreferences(
            employeeId: employee.id,
            autoReminder: autoReminder,
            departurePredictor: departurePredictor
        )
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        networkRequests += 1
        totalResponseTimeMs += elapsedMs
        return success
    }
    
    // MARK: - 4. Profile & Diagnostic Methods
    func getEmployeeProfile(forceRefresh: Bool = false) async throws -> Employee {
        if !forceRefresh, let cached = cacheService.loadEmployeeProfile() {
            cachedRequests += 1
            return cached
        }
        
        let sampleId = cacheService.loadEmployeeProfile()?.id ?? Employee.sample.id
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let fetched = try await apiService.fetchEmployeeProfile(for: sampleId)
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            networkRequests += 1
            totalResponseTimeMs += elapsedMs
            cacheService.saveEmployeeProfile(fetched)
            return fetched
        } catch {
            return cacheService.loadEmployeeProfile() ?? Employee.sample
        }
    }
    
    func updateEmployeeProfile(_ employee: Employee) async throws -> Employee {
        let startTime = CFAbsoluteTimeGetCurrent()
        let updated = try await apiService.updateEmployeeProfile(employee)
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        networkRequests += 1
        totalResponseTimeMs += elapsedMs
        
        cacheService.saveEmployeeProfile(updated)
        return updated
    }
    
    func syncPendingOfflineRecords() async throws -> Int {
        // Collect any records needing synchronization
        var pendingRecords: [AttendanceRecord] = []
        if let today = cacheService.loadTodayRecord(), !today.isSyncedWithServer {
            pendingRecords.append(today)
        }
        
        guard !pendingRecords.isEmpty else { return 0 }
        
        let syncedCount = try await apiService.syncOfflineAttendanceRecords(pendingRecords)
        if var today = cacheService.loadTodayRecord() {
            today.isSyncedWithServer = true
            cacheService.saveTodayRecord(today)
        }
        return syncedCount
    }
    
    // MARK: - 5. Diagnostics
    func getMetrics() -> PerformanceMetrics {
        let total = max(1, cachedRequests + networkRequests)
        let hitRate = (Double(cachedRequests) / Double(total)) * 100.0
        let avgTime = networkRequests > 0 ? (totalResponseTimeMs / Double(networkRequests)) : 45.0
        let bandwidthSaved = Double(cachedRequests) * 28.5 // Estimated 28.5 KB payload saved per cached call
        
        return PerformanceMetrics(
            cachedRequestsCount: cachedRequests,
            networkRequestsCount: networkRequests,
            totalBandwidthSavedKB: bandwidthSaved,
            averageResponseTimeMs: avgTime,
            cacheHitRatePercentage: hitRate,
            isOptimizedModeEnabled: isOptimized
        )
    }
    
    func resetMetrics() {
        cachedRequests = 0
        networkRequests = 0
        totalResponseTimeMs = 0
    }
}

