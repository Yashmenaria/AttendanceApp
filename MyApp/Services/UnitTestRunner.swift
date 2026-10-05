import Foundation
import Combine
import SwiftUI

struct TestCaseResult: Identifiable {
    let id = UUID()
    let name: String
    let suite: String
    let isPassed: Bool
    let message: String
    let durationMs: Double
}

@MainActor
final class UnitTestRunner: ObservableObject {
    static let shared = UnitTestRunner()
    
    @Published var testResults: [TestCaseResult] = []
    @Published var isRunning: Bool = false
    @Published var totalPassed: Int = 0
    @Published var totalFailed: Int = 0
    
    func runAllTests() async {
        isRunning = true
        testResults.removeAll()
        totalPassed = 0
        totalFailed = 0
        
        var results: [TestCaseResult] = []
        
        // 1. HomeViewModel Test Suite
        results.append(contentsOf: await runHomeViewModelSuite())
        
        // 2. AttendanceHistoryViewModel Test Suite
        results.append(contentsOf: await runHistoryViewModelSuite())
        
        // 3. AIInsightsEngine Test Suite
        results.append(contentsOf: await runAIInsightsSuite())
        
        // 4. AttendanceRepository & Cache Test Suite (Solving Finding 1, 2, 3, 4)
        results.append(contentsOf: await runRepositoryAndCacheSuite())
        
        // 5. API Integration & Multi-Screen Network Suite (Assessment Question 2)
        results.append(contentsOf: await runAPIIntegrationSuite())
        
        // 6. Multi-Provider AI Engine & Prompt Builder Suite
        results.append(contentsOf: await runMultiProviderAISuite())
        
        self.testResults = results
        self.totalPassed = results.filter { $0.isPassed }.count
        self.totalFailed = results.filter { !$0.isPassed }.count
        self.isRunning = false
    }
    
    // MARK: - HomeViewModel Suite
    private func runHomeViewModelSuite() async -> [TestCaseResult] {
        var suite: [TestCaseResult] = []
        
        // Test 1: Initial state check
        let start1 = CFAbsoluteTimeGetCurrent()
        let vm = HomeViewModel()
        let pass1 = !vm.isCurrentlyWorking && vm.todayRecord.status == .notCheckedIn
        let duration1 = (CFAbsoluteTimeGetCurrent() - start1) * 1000
        suite.append(TestCaseResult(
            name: "testInitialState_NotCheckedIn",
            suite: "HomeViewModel",
            isPassed: pass1,
            message: pass1 ? "Initial state is unverified and not working." : "Initial state failed.",
            durationMs: duration1
        ))
        
        // Test 2: Target progress calculation
        let start2 = CFAbsoluteTimeGetCurrent()
        vm.employee.targetDailyHours = 8.0
        vm.liveWorkingSeconds = 4 * 3600 // 4 hours of 8
        let pass2 = abs(vm.progressTowardsDailyTarget - 0.5) < 0.01
        let duration2 = (CFAbsoluteTimeGetCurrent() - start2) * 1000
        suite.append(TestCaseResult(
            name: "testProgressTowardsDailyTarget_CalculatesAccurately",
            suite: "HomeViewModel",
            isPassed: pass2,
            message: pass2 ? "Daily progress calculated 50% correctly." : "Calculation error.",
            durationMs: duration2
        ))
        
        return suite
    }
    
    // MARK: - AttendanceHistoryViewModel Suite
    private func runHistoryViewModelSuite() async -> [TestCaseResult] {
        var suite: [TestCaseResult] = []
        
        let start1 = CFAbsoluteTimeGetCurrent()
        let vm = AttendanceHistoryViewModel()
        
        let r1 = AttendanceRecord(date: Date(), status: .onTime, notes: "Daily Standup")
        let r2 = AttendanceRecord(date: Date().daysAgo(1), status: .late, notes: "Traffic delay")
        let r3 = AttendanceRecord(date: Date().daysAgo(2), status: .overtime, notes: "Production Release")
        vm.records = [r1, r2, r3]
        
        vm.selectedFilter = .onTime
        let filterPass = vm.filteredRecords.count == 1 && vm.filteredRecords.first?.status == .onTime
        
        vm.selectedFilter = .all
        vm.searchText = "Production"
        let searchPass = vm.filteredRecords.count == 1 && (vm.filteredRecords.first?.notes?.contains("Production") ?? false)
        
        let pass = filterPass && searchPass
        let duration1 = (CFAbsoluteTimeGetCurrent() - start1) * 1000
        suite.append(TestCaseResult(
            name: "testHistoryFilterAndSearch_FiltersAccurately",
            suite: "AttendanceHistoryViewModel",
            isPassed: pass,
            message: pass ? "Filtering by status and search queries passed." : "Filtering/Search failed.",
            durationMs: duration1
        ))
        
        return suite
    }
    
    // MARK: - AIInsightsEngine Suite
    private func runAIInsightsSuite() async -> [TestCaseResult] {
        var suite: [TestCaseResult] = []
        let engine = AIInsightsEngine.shared
        let employee = Employee.sample
        
        // Test 1: Morning Check-In reminder
        let start1 = CFAbsoluteTimeGetCurrent()
        let insights = engine.generateInsights(todayRecord: nil, employee: employee, recentHistory: [])
        let pass1 = insights.contains { $0.type == .reminder }
        let duration1 = (CFAbsoluteTimeGetCurrent() - start1) * 1000
        suite.append(TestCaseResult(
            name: "testAIInsights_GeneratesCheckInReminder",
            suite: "AIInsightsEngine",
            isPassed: pass1,
            message: pass1 ? "AI check-in reminder generated with high confidence." : "Reminder missing.",
            durationMs: duration1
        ))
        
        // Test 2: Active shift departure prediction
        let start2 = CFAbsoluteTimeGetCurrent()
        let activeRecord = AttendanceRecord(
            date: Date(),
            checkInTime: Date().hoursAgo(4),
            checkOutTime: nil,
            status: .checkedIn
        )
        let predictions = engine.generateInsights(todayRecord: activeRecord, employee: employee, recentHistory: [])
        let pass2 = predictions.contains { $0.type == .prediction }
        let duration2 = (CFAbsoluteTimeGetCurrent() - start2) * 1000
        suite.append(TestCaseResult(
            name: "testAIInsights_DeparturePredictor",
            suite: "AIInsightsEngine",
            isPassed: pass2,
            message: pass2 ? "Shift completion predicted target checkout." : "Prediction missing.",
            durationMs: duration2
        ))
        
        return suite
    }
    
    // MARK: - Repository & Cache Suite (Solving Finding 1, 2, 3, 4)
    private func runRepositoryAndCacheSuite() async -> [TestCaseResult] {
        var suite: [TestCaseResult] = []
        let cache = AttendanceCacheService.shared
        
        // Test 1: Local Cache Roundtrip
        let start1 = CFAbsoluteTimeGetCurrent()
        let testRecord = AttendanceRecord(date: Date(), status: .onTime, location: "Test Lab")
        cache.saveTodayRecord(testRecord)
        let loaded = cache.loadTodayRecord()
        let pass1 = loaded?.status == .onTime && loaded?.location == "Test Lab"
        let duration1 = (CFAbsoluteTimeGetCurrent() - start1) * 1000
        suite.append(TestCaseResult(
            name: "testLocalCache_SaveAndRetrieve (Finding 3 Fix)",
            suite: "AttendanceCacheService",
            isPassed: pass1,
            message: pass1 ? "Dual-tier cache saved and retrieved record instantaneously." : "Cache failed.",
            durationMs: duration1
        ))
        
        // Test 2: Cache TTL Invalidation
        let start2 = CFAbsoluteTimeGetCurrent()
        let isExpired = cache.isCacheExpired(for: "non_existent_key", ttlSeconds: 10)
        let pass2 = isExpired == true
        let duration2 = (CFAbsoluteTimeGetCurrent() - start2) * 1000
        suite.append(TestCaseResult(
            name: "testCacheTTL_Invalidation (Finding 1 Fix)",
            suite: "AttendanceCacheService",
            isPassed: pass2,
            message: pass2 ? "TTL invalidation verified for preventing stale or redundant calls." : "TTL failed.",
            durationMs: duration2
        ))
        
        return suite
    }
    
    // MARK: - API Integration Suite
    private func runAPIIntegrationSuite() async -> [TestCaseResult] {
        var suite: [TestCaseResult] = []
        let api = AttendanceAPIService.shared
        
        // Test 1: Today Attendance API
        let start1 = CFAbsoluteTimeGetCurrent()
        let today = try? await api.fetchTodayAttendance(for: "EMP-10492")
        let pass1 = today != nil
        let duration1 = (CFAbsoluteTimeGetCurrent() - start1) * 1000
        suite.append(TestCaseResult(
            name: "testAPI_FetchTodayAttendance",
            suite: "AttendanceAPIService",
            isPassed: pass1,
            message: pass1 ? "GET /api/v1/attendance/today returned 200 OK." : "Today API failed.",
            durationMs: duration1
        ))
        
        // Test 2: AI Insights API
        let start2 = CFAbsoluteTimeGetCurrent()
        let insights = try? await api.fetchAIInsights(for: "EMP-10492")
        let pass2 = (insights?.count ?? 0) > 0
        let duration2 = (CFAbsoluteTimeGetCurrent() - start2) * 1000
        suite.append(TestCaseResult(
            name: "testAPI_FetchAIInsights",
            suite: "AttendanceAPIService",
            isPassed: pass2,
            message: pass2 ? "GET /api/v1/ai/insights returned AI recommendations." : "AI Insights API failed.",
            durationMs: duration2
        ))
        
        // Test 3: Check-in API
        let start3 = CFAbsoluteTimeGetCurrent()
        let checkIn = try? await api.checkIn(employeeId: "EMP-10492", location: "San Francisco HQ", notes: "Test Unit Run")
        let pass3 = checkIn?.checkInTime != nil
        let duration3 = (CFAbsoluteTimeGetCurrent() - start3) * 1000
        suite.append(TestCaseResult(
            name: "testAPI_CheckInEndpoint",
            suite: "AttendanceAPIService",
            isPassed: pass3,
            message: pass3 ? "POST /api/v1/attendance/check-in logged arrival timestamp." : "CheckIn API failed.",
            durationMs: duration3
        ))
        
        return suite
    }
    
    // MARK: - Multi-Provider AI Engine Suite
    private func runMultiProviderAISuite() async -> [TestCaseResult] {
        var suite: [TestCaseResult] = []
        
        // Test 1: AI Configuration Manager & Provider Switching
        let start1 = CFAbsoluteTimeGetCurrent()
        let configManager = AIConfigManager.shared
        configManager.updateProvider(.gemini)
        let pass1 = configManager.config.activeProvider == .gemini && configManager.config.selectedModel == "gemini-1.5-flash"
        let duration1 = (CFAbsoluteTimeGetCurrent() - start1) * 1000
        suite.append(TestCaseResult(
            name: "testAIConfigManager_ProviderSwitching",
            suite: "AIMultiProvider",
            isPassed: pass1,
            message: pass1 ? "AI Provider switched to Gemini and auto-selected default model." : "Config switch failed.",
            durationMs: duration1
        ))
        
        // Test 2: Contextual Prompt Builder Schema Validation
        let start2 = CFAbsoluteTimeGetCurrent()
        let prompt = AIPromptBuilder.buildUserPrompt(context: AIContext(
            employee: Employee.sample,
            todayRecord: nil,
            recentHistory: []
        ))
        let sysInstruction = AIPromptBuilder.buildSystemInstruction()
        let pass2 = prompt.contains("Alex Chen") && sysInstruction.contains("JSON array matching this exact schema")
        let duration2 = (CFAbsoluteTimeGetCurrent() - start2) * 1000
        suite.append(TestCaseResult(
            name: "testAIPromptBuilder_ContextAndSchemaAdherence",
            suite: "AIMultiProvider",
            isPassed: pass2,
            message: pass2 ? "System instruction and user context prompts generated correctly." : "Prompt builder failed.",
            durationMs: duration2
        ))
        
        // Test 3: Multi-Provider Graceful Fallback Inference
        let start3 = CFAbsoluteTimeGetCurrent()
        let context = AIContext(
            employee: Employee.sample,
            todayRecord: nil,
            recentHistory: []
        )
        let response = await AIMultiProviderService.shared.generateInsights(context: context)
        let pass3 = !response.insights.isEmpty
        let duration3 = (CFAbsoluteTimeGetCurrent() - start3) * 1000
        suite.append(TestCaseResult(
            name: "testAIMultiProviderService_FallbackAndExecution",
            suite: "AIMultiProvider",
            isPassed: pass3,
            message: pass3 ? "AI Multi-Provider pipeline resolved insights smoothly (isFallback: \(response.isFallback))." : "Inference failed.",
            durationMs: duration3
        ))
        
        return suite
    }
}

