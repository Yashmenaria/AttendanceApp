import XCTest
@testable import MyApp

final class AIInsightsEngineTests: XCTestCase {
    private var sut: AIInsightsEngine!
    private var sampleEmployee: Employee!
    
    override func setUp() {
        super.setUp()
        sut = AIInsightsEngine()
        sampleEmployee = Employee.sample
    }
    
    override func tearDown() {
        sut = nil
        sampleEmployee = nil
        super.tearDown()
    }
    
    func testGenerateInsights_WhenNotCheckedIn_GeneratesReminder() {
        let insights = sut.generateInsights(
            todayRecord: nil,
            employee: sampleEmployee,
            recentHistory: []
        )
        
        let reminderInsight = insights.first(where: { $0.type == .reminder })
        XCTAssertNotNil(reminderInsight)
        XCTAssertTrue(reminderInsight?.message.contains("shift typically begins") ?? false || reminderInsight?.message.contains("haven't recorded check-in") ?? false)
    }
    
    func testGenerateInsights_WhenWorkingUnderTarget_GeneratesDeparturePrediction() {
        let checkInTime = Date().hoursAgo(4) // 4 hours worked of 8
        let activeRecord = AttendanceRecord(
            date: Date(),
            checkInTime: checkInTime,
            checkOutTime: nil,
            status: .checkedIn
        )
        
        let insights = sut.generateInsights(
            todayRecord: activeRecord,
            employee: sampleEmployee,
            recentHistory: []
        )
        
        let predictionInsight = insights.first(where: { $0.type == .prediction })
        XCTAssertNotNil(predictionInsight)
        XCTAssertEqual(predictionInsight?.actionTitle, "Set Checkout Alarm")
    }
    
    func testGenerateInsights_WhenConsistentOnTimeStreak_GeneratesStreakInsight() {
        let history = (1...5).map { i in
            AttendanceRecord(date: Date().daysAgo(i), status: .onTime)
        }
        
        let insights = sut.generateInsights(
            todayRecord: nil,
            employee: sampleEmployee,
            recentHistory: history
        )
        
        let streakInsight = insights.first(where: { $0.type == .habit })
        XCTAssertNotNil(streakInsight)
        XCTAssertTrue(streakInsight?.title.contains("Streak") ?? false)
    }
}
