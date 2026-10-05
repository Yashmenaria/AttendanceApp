import Foundation

final class AnthropicAPIService: AIServiceProviderProtocol {
    static let shared = AnthropicAPIService()
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func generateInsights(context: AIContext, config: AIConfiguration) async throws -> [AIInsight] {
        let apiKey = config.apiKey(for: .anthropic).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw NetworkError.unknown("Anthropic Claude API Key is missing. Please configure it in AI Settings.")
        }
        
        let baseURL = config.activeProvider.defaultBaseURL
        let model = config.selectedModel.isEmpty ? "claude-3-5-haiku-20241022" : config.selectedModel
        
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw NetworkError.invalidURL
        }
        
        let systemPrompt = AIPromptBuilder.buildSystemInstruction()
        let userPrompt = AIPromptBuilder.buildUserPrompt(context: context)
        
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ],
            "temperature": config.temperature
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 15.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Invalid response from Anthropic Claude API.")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unknown("Anthropic API Authentication Error (401): Invalid API Key.")
            } else if httpResponse.statusCode == 429 {
                throw NetworkError.unknown("Anthropic Claude API Rate Limit Exceeded.")
            } else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
        }
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contents = jsonObject["content"] as? [[String: Any]],
              let firstContent = contents.first,
              let text = firstContent["text"] as? String else {
            throw NetworkError.decodingError
        }
        
        return try parseInsightsFromRawText(text)
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
