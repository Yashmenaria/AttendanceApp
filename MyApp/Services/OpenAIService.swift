import Foundation

final class OpenAIService: AIServiceProviderProtocol {
    static let shared = OpenAIService()
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func generateInsights(context: AIContext, config: AIConfiguration) async throws -> [AIInsight] {
        let isCustom = config.activeProvider == .custom
        let provider = isCustom ? AIProvider.custom : AIProvider.openAI
        let apiKey = config.apiKey(for: provider).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !apiKey.isEmpty else {
            throw NetworkError.unknown("\(isCustom ? "Custom LLM" : "OpenAI") API Key is missing. Please configure it in AI Settings.")
        }
        
        let baseURL = isCustom ? config.customBaseURL : config.activeProvider.defaultBaseURL
        let model = config.selectedModel.isEmpty ? (isCustom ? "custom-model" : "gpt-4o-mini") : config.selectedModel
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw NetworkError.invalidURL
        }
        
        let systemPrompt = AIPromptBuilder.buildSystemInstruction()
        let userPrompt = AIPromptBuilder.buildUserPrompt(context: context)
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": config.temperature,
            "response_format": ["type": "json_object"]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 15.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Invalid response from OpenAI API.")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unknown("OpenAI Authentication Error (401): Invalid API Key.")
            } else if httpResponse.statusCode == 429 {
                throw NetworkError.unknown("OpenAI Rate Limit Exceeded. Using smart local fallback.")
            } else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse Chat Completion Response
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let rawContent = message["content"] as? String else {
            throw NetworkError.decodingError
        }
        
        return try parseInsightsFromRawText(rawContent)
    }
    
    func testConnection(config: AIConfiguration) async throws -> Bool {
        let dummyEmployee = Employee.sample
        let context = AIContext(employee: dummyEmployee, todayRecord: nil, recentHistory: [])
        let insights = try await generateInsights(context: context, config: config)
        return !insights.isEmpty
    }
    
    private func parseInsightsFromRawText(_ rawText: String) throws -> [AIInsight] {
        var cleanText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.hasPrefix("```json") {
            cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
        }
        if cleanText.hasPrefix("```") {
            cleanText = cleanText.replacingOccurrences(of: "```", with: "")
        }
        if cleanText.hasSuffix("```") {
            cleanText = String(cleanText.dropLast(3))
        }
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanText.data(using: .utf8) else {
            throw NetworkError.decodingError
        }
        
        let decoder = JSONDecoder()
        if let directList = try? decoder.decode([AIInsightRawDTO].self, from: jsonData) {
            return directList.map { $0.toAIInsight() }
        }
        
        if let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            for (_, value) in jsonDict {
                if let arrayData = try? JSONSerialization.data(withJSONObject: value),
                   let nestedList = try? decoder.decode([AIInsightRawDTO].self, from: arrayData) {
                    return nestedList.map { $0.toAIInsight() }
                }
            }
        }
        
        throw NetworkError.decodingError
    }
}
