import Foundation

final class AIMultiProviderService {
    static let shared = AIMultiProviderService()
    
    private let configManager: AIConfigManager
    private let geminiService: AIServiceProviderProtocol
    private let openAIService: AIServiceProviderProtocol
    private let anthropicService: AIServiceProviderProtocol
    private let localEngine: AIInsightsEngineProtocol
    
    init(
        configManager: AIConfigManager = .shared,
        geminiService: AIServiceProviderProtocol = GeminiAPIService.shared,
        openAIService: AIServiceProviderProtocol = OpenAIService.shared,
        anthropicService: AIServiceProviderProtocol = AnthropicAPIService.shared,
        localEngine: AIInsightsEngineProtocol = AIInsightsEngine.shared
    ) {
        self.configManager = configManager
        self.geminiService = geminiService
        self.openAIService = openAIService
        self.anthropicService = anthropicService
        self.localEngine = localEngine
    }
    
    func generateInsights(context: AIContext) async -> AIInsightAPIResponse {
        let startTime = CFAbsoluteTimeGetCurrent()
        let config = configManager.config
        let provider = config.activeProvider
        let modelName = config.selectedModel
        
        // If user chose Local Engine or disabled live AI, run on-device heuristic engine directly
        if provider == .localHeuristic || !config.isLiveAIEnabled {
            let localInsights = localEngine.generateInsights(
                todayRecord: context.todayRecord,
                employee: context.employee,
                recentHistory: context.recentHistory
            )
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return AIInsightAPIResponse(
                insights: localInsights,
                provider: .localHeuristic,
                modelName: "On-Device Rule Engine v1.2",
                executionTimeMs: elapsedMs,
                isFallback: false
            )
        }
        
        // If API key is missing, fall back to local heuristic engine
        guard configManager.hasValidActiveKey else {
            let localInsights = localEngine.generateInsights(
                todayRecord: context.todayRecord,
                employee: context.employee,
                recentHistory: context.recentHistory
            )
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return AIInsightAPIResponse(
                insights: localInsights,
                provider: provider,
                modelName: "\(provider.rawValue) (Key not set - Local Fallback)",
                executionTimeMs: elapsedMs,
                isFallback: true,
                errorMessage: "\(provider.rawValue) API key not configured. Using local smart engine."
            )
        }
        
        // Query the live AI API
        do {
            let service: AIServiceProviderProtocol
            switch provider {
            case .gemini:
                service = geminiService
            case .openAI, .custom:
                service = openAIService
            case .anthropic:
                service = anthropicService
            case .localHeuristic:
                service = openAIService // Unused
            }
            
            let insights = try await service.generateInsights(context: context, config: config)
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            return AIInsightAPIResponse(
                insights: insights,
                provider: provider,
                modelName: modelName,
                executionTimeMs: elapsedMs,
                isFallback: false
            )
        } catch {
            // Graceful automatic local fallback on network error, invalid key, or rate limit
            let localInsights = localEngine.generateInsights(
                todayRecord: context.todayRecord,
                employee: context.employee,
                recentHistory: context.recentHistory
            )
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            return AIInsightAPIResponse(
                insights: localInsights,
                provider: provider,
                modelName: "\(modelName) (Fallback)",
                executionTimeMs: elapsedMs,
                isFallback: true,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    func testConnection(for provider: AIProvider) async -> (success: Bool, message: String) {
        if provider == .localHeuristic {
            return (true, "Local Heuristic Rule Engine is active and ready on device.")
        }
        
        let config = configManager.config
        let apiKey = config.apiKey(for: provider).trimmingCharacters(in: .whitespacesAndNewlines)
        if apiKey.isEmpty {
            return (false, "API Key is empty for \(provider.rawValue).")
        }
        
        do {
            let service: AIServiceProviderProtocol
            switch provider {
            case .gemini: service = geminiService
            case .openAI, .custom: service = openAIService
            case .anthropic: service = anthropicService
            case .localHeuristic: return (true, "Local Engine is always online.")
            }
            
            let success = try await service.testConnection(config: config)
            if success {
                return (true, "Successfully connected to \(provider.rawValue) API!")
            } else {
                return (false, "Connected to \(provider.rawValue) but received empty insights.")
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
