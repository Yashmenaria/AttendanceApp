import Foundation

final class GeminiAPIService: AIServiceProviderProtocol {
    static let shared = GeminiAPIService()
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func generateInsights(context: AIContext, config: AIConfiguration) async throws -> [AIInsight] {
        let apiKey = config.apiKey(for: .gemini).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw NetworkError.unknown("Google Gemini API Key is missing. Please configure it in AI Settings.")
        }
        
        let model = config.selectedModel.isEmpty ? "gemini-1.5-flash" : config.selectedModel
        let baseURL = config.activeProvider.defaultBaseURL
        let endpointString = "\(baseURL)/models/\(model):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: endpointString) else {
            throw NetworkError.invalidURL
        }
        
        let systemText = AIPromptBuilder.buildSystemInstruction()
        let userText = AIPromptBuilder.buildUserPrompt(context: context)
        
        let requestBody: [String: Any] = [
            "system_instruction": [
                "parts": [
                    ["text": systemText]
                ]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": userText]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": config.temperature,
                "responseMimeType": "application/json"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 15.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Invalid response from Gemini API.")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 403 {
                throw NetworkError.unknown("Gemini API Error (\(httpResponse.statusCode)): Invalid API Key or Permissions.")
            } else if httpResponse.statusCode == 429 {
                throw NetworkError.unknown("Gemini API Rate Limit Exceeded. Operating on fallback.")
            } else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse Gemini JSON structure
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = jsonObject["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
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
        
        // Handle wrapper object e.g. {"insights": [...]}
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
