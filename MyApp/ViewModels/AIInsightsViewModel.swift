import SwiftUI
import Combine

@MainActor
final class AIInsightsViewModel: ObservableObject {
    @Published var insights: [AIInsight] = []
    @Published var healthScore: Int = 94
    @Published var punctualityRating: String = "Top Tier (Top 5%)"
    @Published var isAutoReminderEnabled: Bool = true
    @Published var isSmartPredictionActive: Bool = true
    @Published var isLoading: Bool = false
    @Published var isRegenerating: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var actionToast: String? = nil
    @Published var isShowingSettingsSheet: Bool = false
    @Published var activeProviderName: String = "Google Gemini"
    @Published var activeModelName: String = "gemini-1.5-flash"
    @Published var isUsingLocalFallback: Bool = false
    @Published var lastInferenceDurationMs: Double = 0
    
    private let repository: AttendanceRepositoryProtocol
    private let cacheService: AttendanceCacheServiceProtocol
    private let aiEngine: AIInsightsEngineProtocol
    private let configManager: AIConfigManager
    private var cancellables = Set<AnyCancellable>()
    
    init(
        repository: AttendanceRepositoryProtocol? = nil,
        cacheService: AttendanceCacheServiceProtocol? = nil,
        aiEngine: AIInsightsEngineProtocol? = nil,
        configManager: AIConfigManager = .shared
    ) {
        self.repository = repository ?? AttendanceRepository.shared
        self.cacheService = cacheService ?? AttendanceCacheService.shared
        self.aiEngine = aiEngine ?? AIInsightsEngine.shared
        self.configManager = configManager
        
        syncConfigState()
        
        // Listen to config changes
        configManager.$config
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncConfigState()
            }
            .store(in: &cancellables)
        
        loadInitialInsights()
    }
    
    private func syncConfigState() {
        self.activeProviderName = configManager.config.activeProvider.rawValue
        self.activeModelName = configManager.config.selectedModel
        self.isUsingLocalFallback = !configManager.hasValidActiveKey && configManager.config.activeProvider != .localHeuristic
    }
    
    private func loadInitialInsights() {
        // First check cache or local heuristic fallback
        if let cached = cacheService.loadAIInsights(), !cached.isEmpty {
            self.insights = cached
        } else {
            generateLocalInsights()
        }
        
        // Fetch fresh insights from the active AI Provider
        Task {
            await fetchAIInsightsFromAPI(forceRefresh: false)
        }
    }
    
    func generateLocalInsights() {
        let employee = cacheService.loadEmployeeProfile() ?? Employee.sample
        let todayRecord = cacheService.loadTodayRecord()
        let history = cacheService.loadRecentHistory() ?? []
        
        var generated = aiEngine.generateInsights(
            todayRecord: todayRecord,
            employee: employee,
            recentHistory: history
        )
        
        if generated.count < 3 {
            generated.append(AIInsight(
                type: .prediction,
                title: "Optimal Check-In Window",
                message: "Based on commute traffic patterns and campus access speed, arriving between 8:40 AM – 8:50 AM yields a 99.4% on-time record.",
                confidenceScore: 0.91,
                actionTitle: "Schedule Alarm"
            ))
            
            generated.append(AIInsight(
                type: .habit,
                title: "Consistent Friday Trend",
                message: "On Fridays, your average shift completion is 7.8 hours. Consider adjusting Thursday output to balance weekly requirements.",
                confidenceScore: 0.89,
                actionTitle: "View Weekly Balance"
            ))
        }
        
        self.insights = generated
    }
    
    /// Trigger AI Insight generation across configured provider
    func fetchAIInsightsFromAPI(forceRefresh: Bool = false) async {
        if insights.isEmpty {
            isLoading = true
        } else if forceRefresh {
            isRegenerating = true
        }
        errorMessage = nil
        let start = CFAbsoluteTimeGetCurrent()
        
        do {
            let apiInsights = try await repository.getAIInsights(forceRefresh: forceRefresh)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            self.lastInferenceDurationMs = elapsed
            
            if !apiInsights.isEmpty {
                self.insights = apiInsights
            }
            self.isLoading = false
            self.isRegenerating = false
            self.syncConfigState()
        } catch {
            self.isLoading = false
            self.isRegenerating = false
            self.errorMessage = error.localizedDescription
            if forceRefresh {
                self.showErrorAlert = true
            }
        }
    }
    
    func regenerateInsights() {
        HapticManager.shared.impact(style: .medium)
        Task {
            await fetchAIInsightsFromAPI(forceRefresh: true)
            self.actionToast = "Insights refreshed from \(configManager.config.activeProvider.rawValue)"
        }
    }
    
    /// Sync automation preferences with backend `POST /api/v1/ai/preferences`
    func updatePreferences() {
        Task {
            do {
                let _ = try await repository.updateAIPreferences(
                    autoReminder: isAutoReminderEnabled,
                    departurePredictor: isSmartPredictionActive
                )
                self.actionToast = "AI preferences synced with server"
                HapticManager.shared.impact(style: .light)
            } catch {
                self.errorMessage = "Failed to sync preferences: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
        }
    }
    
    func executeAction(for insight: AIInsight) {
        HapticManager.shared.impact(style: .medium)
        switch insight.type {
        case .reminder:
            NotificationService.shared.scheduleCheckInReminder()
            actionToast = "Smart check-in reminder configured for 8:50 AM"
        case .prediction:
            NotificationService.shared.scheduleCheckOutReminder(targetDate: Date().addingTimeInterval(4 * 3600))
            actionToast = "Checkout alert scheduled for end-of-shift target"
        case .habit, .punctuality, .wellBeing:
            actionToast = "Insight acknowledged and preferences updated"
        }
    }
}

