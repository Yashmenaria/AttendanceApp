import XCTest
@testable import MyApp

@MainActor
final class AttendanceHistoryViewModelTests: XCTestCase {
    private var mockAPI: MockAttendanceAPIService!
    private var mockCache: MockAttendanceCacheService!
    private var repository: AttendanceRepository!
    private var sut: AttendanceHistoryViewModel!
    
    override func setUp() {
        super.setUp()
        mockAPI = MockAttendanceAPIService()
        mockCache = MockAttendanceCacheService()
        repository = AttendanceRepository(apiService: mockAPI, cacheService: mockCache)
        sut = AttendanceHistoryViewModel(repository: repository)
    }
    
    override func tearDown() {
        sut = nil
        repository = nil
        mockCache = nil
        mockAPI = nil
        super.tearDown()
    }
    
    func testLoadInitialHistory_SuccessLoadsPage1() async {
        let sampleRecords = (1...15).map { i in
            AttendanceRecord(
                date: Date().daysAgo(i),
                checkInTime: Date().daysAgo(i),
                checkOutTime: Date().daysAgo(i).hoursAgo(-8),
                status: i % 2 == 0 ? .completed : .late
            )
        }
        mockAPI.historyResult = sampleRecords
        
        await sut.loadInitialHistory()
        
        XCTAssertEqual(sut.records.count, 15)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.hasMorePages)
    }
    
    func testFilterByStatus_FiltersAccurately() async {
        let r1 = AttendanceRecord(date: Date(), status: .onTime)
        let r2 = AttendanceRecord(date: Date().daysAgo(1), status: .completed)
        let r3 = AttendanceRecord(date: Date().daysAgo(2), status: .late)
        let r4 = AttendanceRecord(date: Date().daysAgo(3), status: .overtime)
        
        sut.records = [r1, r2, r3, r4]
        
        sut.selectedFilter = .all
        XCTAssertEqual(sut.filteredRecords.count, 4)
        
        sut.selectedFilter = .onTime
        XCTAssertEqual(sut.filteredRecords.count, 2) // r1 & r2
        
        sut.selectedFilter = .late
        XCTAssertEqual(sut.filteredRecords.count, 1)
        XCTAssertEqual(sut.filteredRecords.first?.status, .late)
        
        sut.selectedFilter = .overtime
        XCTAssertEqual(sut.filteredRecords.count, 1)
        XCTAssertEqual(sut.filteredRecords.first?.status, .overtime)
    }
    
    func testSearchText_FiltersMatchingDatesOrNotes() {
        let r1 = AttendanceRecord(date: Date(), notes: "Sprint Planning Day")
        let r2 = AttendanceRecord(date: Date().daysAgo(5), notes: "Remote Work from Coffee Shop")
        
        sut.records = [r1, r2]
        
        sut.searchText = "Sprint"
        XCTAssertEqual(sut.filteredRecords.count, 1)
        XCTAssertEqual(sut.filteredRecords.first?.notes, "Sprint Planning Day")
        
        sut.searchText = "Coffee"
        XCTAssertEqual(sut.filteredRecords.count, 1)
        
        sut.searchText = "NonExistent"
        XCTAssertEqual(sut.filteredRecords.count, 0)
    }
    
    func testOnTimePercentage_CalculatesCorrectly() {
        let r1 = AttendanceRecord(date: Date(), status: .onTime)
        let r2 = AttendanceRecord(date: Date().daysAgo(1), status: .completed)
        let r3 = AttendanceRecord(date: Date().daysAgo(2), status: .late)
        let r4 = AttendanceRecord(date: Date().daysAgo(3), status: .late)
        
        sut.records = [r1, r2, r3, r4]
        
        // 2 out of 4 = 50%
        XCTAssertEqual(sut.onTimePercentage, 50.0)
    }
}
