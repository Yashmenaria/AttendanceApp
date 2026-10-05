import XCTest
@testable import MyApp

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var mockAPI: MockAttendanceAPIService!
    private var mockCache: MockAttendanceCacheService!
    private var repository: AttendanceRepository!
    private var aiEngine: AIInsightsEngine!
    private var sut: HomeViewModel!
    
    override func setUp() {
        super.setUp()
        mockAPI = MockAttendanceAPIService()
        mockCache = MockAttendanceCacheService()
        repository = AttendanceRepository(apiService: mockAPI, cacheService: mockCache)
        aiEngine = AIInsightsEngine()
        sut = HomeViewModel(repository: repository, cacheService: mockCache, aiEngine: aiEngine)
    }
    
    override func tearDown() {
        sut = nil
        repository = nil
        mockCache = nil
        mockAPI = nil
        super.tearDown()
    }
    
    func testInitialState_NotCheckedIn() {
        XCTAssertFalse(sut.isCurrentlyWorking)
        XCTAssertFalse(sut.hasCompletedWorkToday)
        XCTAssertNil(sut.todayRecord.checkInTime)
        XCTAssertEqual(sut.todayRecord.status, .notCheckedIn)
    }
    
    func testCheckIn_UpdatesStateOptimisticallyAndSucceeds() async {
        let expectedRecord = AttendanceRecord(
            date: Date(),
            checkInTime: Date(),
            checkOutTime: nil,
            status: .onTime,
            location: "San Francisco HQ"
        )
        mockAPI.checkInResult = expectedRecord
        
        sut.checkIn()
        
        // Check optimistic update
        XCTAssertTrue(sut.isCurrentlyWorking)
        XCTAssertNotNil(sut.todayRecord.checkInTime)
        
        // Wait for async task
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(sut.todayRecord.status, .onTime)
        XCTAssertFalse(sut.showErrorAlert)
        XCTAssertNotNil(sut.successToastMessage)
    }
    
    func testCheckIn_FailureRevertsOptimisticState() async {
        mockAPI.shouldFail = true
        
        sut.checkIn()
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(sut.showErrorAlert)
        XCTAssertFalse(sut.isCurrentlyWorking)
        XCTAssertNil(sut.todayRecord.checkInTime)
    }
    
    func testCheckOut_UpdatesShiftCompletion() async {
        // Set checked in first
        sut.todayRecord.checkInTime = Date().hoursAgo(8)
        sut.todayRecord.status = .checkedIn
        
        sut.checkOut()
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(sut.hasCompletedWorkToday)
        XCTAssertEqual(sut.todayRecord.status, .completed)
        XCTAssertNotNil(sut.todayRecord.checkOutTime)
    }
    
    func testProgressTowardsDailyTarget_CalculatesAccurately() {
        sut.employee.targetDailyHours = 8.0
        sut.liveWorkingSeconds = 4 * 3600 // 4 hours = 50%
        
        XCTAssertEqual(sut.progressTowardsDailyTarget, 0.5, accuracy: 0.01)
    }
}
