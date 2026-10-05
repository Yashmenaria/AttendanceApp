import Foundation
import SwiftUI
import Combine

// MARK: - AI Provider Types
enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case gemini = "Google Gemini"
    case openAI = "OpenAI"
    case anthropic = "Anthropic Claude"
    case custom = "Custom LLM API"
    case localHeuristic = "Local Smart Engine"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .gemini: return "sparkle"
        case .openAI: return "brain.head.profile"
        case .anthropic: return "atom"
        case .custom: return "server.rack"
        case .localHeuristic: return "cpu"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .gemini: return Color.blue
        case .openAI: return Color.green
        case .anthropic: return Color.orange
        case .custom: return Color.purple
        case .localHeuristic: return Color.gray
        }
    }
    
    var defaultBaseURL: String {
        switch self {
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .custom: return "https://api.openai.com/v1"
        case .localHeuristic: return ""
        }
    }
    
    var supportedModels: [String] {
        switch self {
        case .gemini:
            return ["gemini-1.5-flash", "gemini-2.0-flash", "gemini-1.5-pro"]
        case .openAI:
            return ["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-5-haiku-20241022", "claude-3-5-sonnet-20241022"]
        case .custom:
            return ["custom-model", "llama3", "mistral-7b"]
        case .localHeuristic:
            return ["On-Device Rule Engine v1.2"]
        }
    }
    
    var defaultModel: String {
        supportedModels.first ?? ""
    }
    
    var requiresAPIKey: Bool {
        return self != .localHeuristic
    }
    
    var keyPlaceholder: String {
        switch self {
        case .gemini: return "AIzaSy..."
        case .openAI: return "sk-proj-..."
        case .anthropic: return "sk-ant-..."
        case .custom: return "Bearer token or key..."
        case .localHeuristic: return "No key required"
        }
    }
}

// MARK: - AI Configuration Model
struct AIConfiguration: Codable, Equatable {
    var activeProvider: AIProvider
    var geminiAPIKey: String
    var openAIAPIKey: String
    var anthropicAPIKey: String
    var customAPIKey: String
    var customBaseURL: String
    var selectedModel: String
    var temperature: Double
    var isLiveAIEnabled: Bool
    
    static var `default`: AIConfiguration {
        AIConfiguration(
            activeProvider: .gemini,
            geminiAPIKey: "",
            openAIAPIKey: "",
            anthropicAPIKey: "",
            customAPIKey: "",
            customBaseURL: "https://api.openai.com/v1",
            selectedModel: "gemini-1.5-flash",
            temperature: 0.7,
            isLiveAIEnabled: true
        )
    }
    
    func apiKey(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return geminiAPIKey
        case .openAI: return openAIAPIKey
        case .anthropic: return anthropicAPIKey
        case .custom: return customAPIKey
        case .localHeuristic: return ""
        }
    }
    
    mutating func setAPIKey(_ key: String, for provider: AIProvider) {
        switch provider {
        case .gemini: geminiAPIKey = key
        case .openAI: openAIAPIKey = key
        case .anthropic: anthropicAPIKey = key
        case .custom: customAPIKey = key
        case .localHeuristic: break
        }
    }
}

// MARK: - AI Configuration Manager
final class AIConfigManager: ObservableObject {
    static let shared = AIConfigManager()
    
    private let userDefaults: UserDefaults
    private let key = "app_ai_configuration_v1"
    
    @Published var config: AIConfiguration {
        didSet {
            save()
        }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: key),
           let loaded = try? JSONDecoder().decode(AIConfiguration.self, from: data) {
            self.config = loaded
        } else {
            self.config = .default
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func updateProvider(_ provider: AIProvider) {
        config.activeProvider = provider
        if !provider.supportedModels.contains(config.selectedModel) {
            config.selectedModel = provider.defaultModel
        }
    }
    
    func activeAPIKey() -> String {
        config.apiKey(for: config.activeProvider)
    }
    
    var hasValidActiveKey: Bool {
        if !config.activeProvider.requiresAPIKey { return true }
        return !activeAPIKey().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
