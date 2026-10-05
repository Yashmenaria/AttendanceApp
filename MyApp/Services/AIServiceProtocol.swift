import Foundation

// MARK: - AI Response DTO
struct AIInsightRawDTO: Codable {
    let type: String
    let title: String
    let message: String
    let confidenceScore: Double?
    let actionTitle: String?
    
    func toAIInsight() -> AIInsight {
        let mappedType: AIInsightType
        switch type.lowercased() {
        case "reminder", "check-in reminder", "smart check-in reminder":
            mappedType = .reminder
        case "habit analysis", "habit", "trend":
            mappedType = .habit
        case "checkout predictor", "prediction", "predictor":
            mappedType = .prediction
        case "punctuality alert", "punctuality":
            mappedType = .punctuality
        case "work-life balance", "wellbeing", "well-being", "wellness":
            mappedType = .wellBeing
        default:
            mappedType = .habit
        }
        
        return AIInsight(
            type: mappedType,
            title: title,
            message: message,
            timestamp: Date(),
            confidenceScore: min(0.99, max(0.70, confidenceScore ?? 0.94)),
            actionTitle: actionTitle
        )
    }
}

// MARK: - AI Generation Result
struct AIInsightAPIResponse {
    let insights: [AIInsight]
    let provider: AIProvider
    let modelName: String
    let executionTimeMs: Double
    let isFallback: Bool
    let errorMessage: String?
    
    init(
        insights: [AIInsight],
        provider: AIProvider,
        modelName: String,
        executionTimeMs: Double,
        isFallback: Bool = false,
        errorMessage: String? = nil
    ) {
        self.insights = insights
        self.provider = provider
        self.modelName = modelName
        self.executionTimeMs = executionTimeMs
        self.isFallback = isFallback
        self.errorMessage = errorMessage
    }
}

// MARK: - Service Protocol
protocol AIServiceProviderProtocol {
    func generateInsights(context: AIContext, config: AIConfiguration) async throws -> [AIInsight]
    func testConnection(config: AIConfiguration) async throws -> Bool
}
