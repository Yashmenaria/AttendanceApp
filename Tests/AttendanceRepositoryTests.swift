import XCTest
@testable import MyApp

final class AttendanceRepositoryTests: XCTestCase {
    private var mockAPI: MockAttendanceAPIService!
    private var mockCache: MockAttendanceCacheService!
    private var sut: AttendanceRepository!
    
    override func setUp() {
        super.setUp()
        let api = MockAttendanceAPIService()
        let cache = MockAttendanceCacheService()
        mockAPI = api
        mockCache = cache
        sut = AttendanceRepository(apiService: api, cacheService: cache)
    }
    
    override func tearDown() {
        sut = nil
        mockCache = nil
        mockAPI = nil
        super.tearDown()
    }
    
    func testGetTodayAttendance_WhenCacheValid_ReturnsCachedWithoutAPICall() async throws {
        // Given cache is valid (< TTL)
        mockCache.isExpiredReturnValue = false
        let cachedRecord = AttendanceRecord(date: Date(), status: .onTime)
        mockCache.storedTodayRecord = cachedRecord
        
        // When
        let result = try await sut.getTodayAttendance(forceRefresh: false)
        
        // Then: API should NOT be called (Solving Finding 1)
        XCTAssertEqual(mockAPI.fetchTodayCallCount, 0)
        XCTAssertEqual(result.status, .onTime)
        
        // Metrics should reflect cache hit
        let metrics = sut.getMetrics()
        XCTAssertEqual(metrics.cachedRequestsCount, 1)
        XCTAssertEqual(metrics.networkRequestsCount, 0)
    }
    
    func testGetTodayAttendance_WhenCacheExpired_CallsAPIAndUpdatesCache() async throws {
        // Given cache is expired
        mockCache.isExpiredReturnValue = true
        
        // When
        _ = try await sut.getTodayAttendance(forceRefresh: false)
        
        // Then: API should be called
        XCTAssertEqual(mockAPI.fetchTodayCallCount, 1)
        XCTAssertNotNil(mockCache.storedTodayRecord)
    }
    
    func testCheckIn_UpdatesCacheAndTracksMetrics() async throws {
        let result = try await sut.checkIn(location: "HQ Campus")
        
        XCTAssertEqual(mockAPI.checkInCallCount, 1)
        XCTAssertNotNil(mockCache.storedTodayRecord)
        XCTAssertEqual(result.location, "HQ Campus")
        
        let metrics = sut.getMetrics()
        XCTAssertEqual(metrics.networkRequestsCount, 1)
    }
}
