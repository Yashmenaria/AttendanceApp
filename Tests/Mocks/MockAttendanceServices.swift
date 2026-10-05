import Foundation
import XCTest
@testable import MyApp

// MARK: - Mock API Service
final class MockAttendanceAPIService: AttendanceAPIServiceProtocol {
    var shouldFail: Bool = false
    var checkInResult: AttendanceRecord?
    var checkOutResult: AttendanceRecord?
    var historyResult: [AttendanceRecord] = []
    var fetchTodayCallCount: Int = 0
    var checkInCallCount: Int = 0
    var checkOutCallCount: Int = 0
    var historyCallCount: Int = 0
    
    func fetchTodayAttendance(for employeeId: String) async throws -> AttendanceRecord {
        fetchTodayCallCount += 1
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        return AttendanceRecord(
            date: Date(),
            checkInTime: nil,
            checkOutTime: nil,
            status: .notCheckedIn
        )
    }
    
    func checkIn(employeeId: String, location: String?, notes: String?) async throws -> AttendanceRecord {
        checkInCallCount += 1
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        if let result = checkInResult {
            return result
        }
        return AttendanceRecord(
            date: Date(),
            checkInTime: Date(),
            checkOutTime: nil,
            status: .onTime,
            notes: notes,
            location: location ?? "Office HQ"
        )
    }
    
    func checkIn(employeeId: String, location: String?) async throws -> AttendanceRecord {
        try await checkIn(employeeId: employeeId, location: location, notes: nil)
    }
    
    func checkOut(employeeId: String, location: String?, notes: String?) async throws -> AttendanceRecord {
        checkOutCallCount += 1
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        if let result = checkOutResult {
            return result
        }
        return AttendanceRecord(
            date: Date(),
            checkInTime: Date().hoursAgo(8),
            checkOutTime: Date(),
            status: .completed,
            notes: notes,
            location: location ?? "Office HQ"
        )
    }
    
    func checkOut(employeeId: String, location: String?) async throws -> AttendanceRecord {
        try await checkOut(employeeId: employeeId, location: location, notes: nil)
    }
    
    func fetchAttendanceHistory(employeeId: String, page: Int, pageSize: Int) async throws -> [AttendanceRecord] {
        try await fetchAttendanceHistory(employeeId: employeeId, page: page, pageSize: pageSize, status: nil, search: nil)
    }
    
    func fetchAttendanceHistory(employeeId: String, page: Int, pageSize: Int, status: String?, search: String?) async throws -> [AttendanceRecord] {
        historyCallCount += 1
        if shouldFail {
            throw NetworkError.timeout
        }
        return historyResult
    }
    
    func fetchAIInsights(for employeeId: String) async throws -> [AIInsight] {
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        return [
            AIInsight(type: .reminder, title: "Mock Smart Reminder", message: "Time to check in.", confidenceScore: 0.95),
            AIInsight(type: .prediction, title: "Mock Departure", message: "Ready to check out.", confidenceScore: 0.90)
        ]
    }
    
    func updateAIPreferences(employeeId: String, autoReminder: Bool, departurePredictor: Bool) async throws -> Bool {
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        return true
    }
    
    func fetchEmployeeProfile(for employeeId: String) async throws -> Employee {
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        return Employee.sample
    }
    
    func updateEmployeeProfile(_ employee: Employee) async throws -> Employee {
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        return employee
    }
    
    func syncOfflineAttendanceRecords(_ records: [AttendanceRecord]) async throws -> Int {
        if shouldFail {
            throw NetworkError.serverError(statusCode: 500)
        }
        return records.count
    }
}

// MARK: - Mock Cache Service
final class MockAttendanceCacheService: AttendanceCacheServiceProtocol {
    var storedTodayRecord: AttendanceRecord?
    var storedHistory: [AttendanceRecord]?
    var storedEmployee: Employee?
    var storedInsights: [AIInsight]?
    var isExpiredReturnValue: Bool = true
    var clearCacheCallCount: Int = 0
    
    func saveTodayRecord(_ record: AttendanceRecord) {
        storedTodayRecord = record
    }
    
    func loadTodayRecord() -> AttendanceRecord? {
        storedTodayRecord
    }
    
    func saveRecentHistory(_ records: [AttendanceRecord]) {
        storedHistory = records
    }
    
    func loadRecentHistory() -> [AttendanceRecord]? {
        storedHistory
    }
    
    func saveEmployeeProfile(_ employee: Employee) {
        storedEmployee = employee
    }
    
    func loadEmployeeProfile() -> Employee? {
        storedEmployee ?? Employee.sample
    }
    
    func saveAIInsights(_ insights: [AIInsight]) {
        storedInsights = insights
    }
    
    func loadAIInsights() -> [AIInsight]? {
        storedInsights
    }
    
    func isCacheExpired(for key: String, ttlSeconds: TimeInterval) -> Bool {
        isExpiredReturnValue
    }
    
    func clearCache() {
        clearCacheCallCount += 1
        storedTodayRecord = nil
        storedHistory = nil
        storedInsights = nil
    }
}
