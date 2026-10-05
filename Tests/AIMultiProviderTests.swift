import XCTest
@testable import MyApp

final class AIMultiProviderTests: XCTestCase {
    
    func testAIConfigManager_DefaultsAndSwitching() {
        let configManager = AIConfigManager.shared
        configManager.updateProvider(.gemini)
        
        XCTAssertEqual(configManager.config.activeProvider, .gemini)
        XCTAssertTrue(AIProvider.gemini.supportedModels.contains(configManager.config.selectedModel))
        
        configManager.updateProvider(.openAI)
        XCTAssertEqual(configManager.config.activeProvider, .openAI)
        XCTAssertEqual(configManager.config.selectedModel, "gpt-4o-mini")
    }
    
    func testAIPromptBuilder_ContextGeneration() {
        let employee = Employee.sample
        let todayRecord = AttendanceRecord(
            date: Date(),
            checkInTime: Date().hoursAgo(3),
            checkOutTime: nil,
            status: .checkedIn
        )
        let history = [
            AttendanceRecord(date: Date().daysAgo(1), status: .onTime),
            AttendanceRecord(date: Date().daysAgo(2), status: .onTime)
        ]
        
        let context = AIContext(
            employee: employee,
            todayRecord: todayRecord,
            recentHistory: history
        )
        
        let prompt = AIPromptBuilder.buildUserPrompt(context: context)
        let systemInstruction = AIPromptBuilder.buildSystemInstruction()
        
        XCTAssertTrue(prompt.contains(employee.name))
        XCTAssertTrue(prompt.contains("Currently active!"))
        XCTAssertTrue(prompt.contains("100.0%"))
        XCTAssertTrue(systemInstruction.contains("JSON array matching this exact schema"))
    }
    
    func testAIMultiProviderService_LocalFallbackExecution() async {
        let context = AIContext(
            employee: Employee.sample,
            todayRecord: nil,
            recentHistory: []
        )
        
        let response = await AIMultiProviderService.shared.generateInsights(context: context)
        
        XCTAssertFalse(response.insights.isEmpty)
        XCTAssertGreaterThan(response.insights.count, 0)
        XCTAssertNotNil(response.insights.first?.title)
    }
    
    func testAIInsightRawDTOMapping() {
        let dto = AIInsightRawDTO(
            type: "Reminder",
            title: "Morning Alert",
            message: "Shift is starting soon.",
            confidenceScore: 0.98,
            actionTitle: "Check In"
        )
        
        let insight = dto.toAIInsight()
        XCTAssertEqual(insight.type, .reminder)
        XCTAssertEqual(insight.title, "Morning Alert")
        XCTAssertEqual(insight.confidenceScore, 0.98)
        XCTAssertEqual(insight.actionTitle, "Check In")
    }
}
