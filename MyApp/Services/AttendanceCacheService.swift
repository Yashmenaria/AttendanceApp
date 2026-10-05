import Foundation

protocol AttendanceCacheServiceProtocol {
    func saveTodayRecord(_ record: AttendanceRecord)
    func loadTodayRecord() -> AttendanceRecord?
    func saveRecentHistory(_ records: [AttendanceRecord])
    func loadRecentHistory() -> [AttendanceRecord]?
    func saveEmployeeProfile(_ employee: Employee)
    func loadEmployeeProfile() -> Employee?
    func saveAIInsights(_ insights: [AIInsight])
    func loadAIInsights() -> [AIInsight]?
    func isCacheExpired(for key: String, ttlSeconds: TimeInterval) -> Bool
    func clearCache()
}

final class AttendanceCacheService: AttendanceCacheServiceProtocol {
    static let shared = AttendanceCacheService()
    
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // In-memory cache for fast sub-millisecond access
    private var memoryCache = NSCache<NSString, AnyObject>()
    
    private enum Keys {
        static let todayRecord = "cached_today_record"
        static let recentHistory = "cached_recent_history"
        static let employeeProfile = "cached_employee_profile"
        static let aiInsights = "cached_ai_insights"
        static let lastFetchTimestamp = "cached_last_fetch_timestamp_"
        static let pendingOfflineCheckIns = "cached_pending_offline_checkins"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Today's Record Caching
    func saveTodayRecord(_ record: AttendanceRecord) {
        if let data = try? encoder.encode(record) {
            userDefaults.set(data, forKey: Keys.todayRecord)
            userDefaults.set(Date().timeIntervalSince1970, forKey: Keys.lastFetchTimestamp + Keys.todayRecord)
        }
        memoryCache.setObject(record as AnyObject, forKey: Keys.todayRecord as NSString)
    }
    
    func loadTodayRecord() -> AttendanceRecord? {
        if let memObj = memoryCache.object(forKey: Keys.todayRecord as NSString) as? AttendanceRecord {
            return memObj
        }
        guard let data = userDefaults.data(forKey: Keys.todayRecord),
              let record = try? decoder.decode(AttendanceRecord.self, from: data) else {
            return nil
        }
        memoryCache.setObject(record as AnyObject, forKey: Keys.todayRecord as NSString)
        return record
    }
    
    // MARK: - Recent History Caching
    func saveRecentHistory(_ records: [AttendanceRecord]) {
        if let data = try? encoder.encode(records) {
            userDefaults.set(data, forKey: Keys.recentHistory)
            userDefaults.set(Date().timeIntervalSince1970, forKey: Keys.lastFetchTimestamp + Keys.recentHistory)
        }
    }
    
    func loadRecentHistory() -> [AttendanceRecord]? {
        guard let data = userDefaults.data(forKey: Keys.recentHistory),
              let records = try? decoder.decode([AttendanceRecord].self, from: data) else {
            return nil
        }
        return records
    }
    
    // MARK: - Employee Profile
    func saveEmployeeProfile(_ employee: Employee) {
        if let data = try? encoder.encode(employee) {
            userDefaults.set(data, forKey: Keys.employeeProfile)
        }
    }
    
    func loadEmployeeProfile() -> Employee? {
        guard let data = userDefaults.data(forKey: Keys.employeeProfile),
              let employee = try? decoder.decode(Employee.self, from: data) else {
            return Employee.sample
        }
        return employee
    }
    
    // MARK: - AI Insights Caching
    func saveAIInsights(_ insights: [AIInsight]) {
        if let data = try? encoder.encode(insights) {
            userDefaults.set(data, forKey: Keys.aiInsights)
            userDefaults.set(Date().timeIntervalSince1970, forKey: Keys.lastFetchTimestamp + Keys.aiInsights)
        }
    }
    
    func loadAIInsights() -> [AIInsight]? {
        guard let data = userDefaults.data(forKey: Keys.aiInsights),
              let insights = try? decoder.decode([AIInsight].self, from: data) else {
            return nil
        }
        return insights
    }
    
    // MARK: - TTL Validation
    func isCacheExpired(for key: String, ttlSeconds: TimeInterval = 300) -> Bool {
        let lastTime = userDefaults.double(forKey: Keys.lastFetchTimestamp + key)
        guard lastTime > 0 else { return true }
        let elapsed = Date().timeIntervalSince1970 - lastTime
        return elapsed > ttlSeconds
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        userDefaults.removeObject(forKey: Keys.todayRecord)
        userDefaults.removeObject(forKey: Keys.recentHistory)
        userDefaults.removeObject(forKey: Keys.aiInsights)
    }
}
