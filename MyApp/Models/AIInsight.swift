import SwiftUI

enum AIInsightType: String, Codable, CaseIterable {
    case reminder = "Reminder"
    case habit = "Habit Analysis"
    case prediction = "Checkout Predictor"
    case punctuality = "Punctuality Alert"
    case wellBeing = "Work-Life Balance"
    
    var icon: String {
        switch self {
        case .reminder: return "bell.badge.fill"
        case .habit: return "chart.line.uptrend.xyaxis"
        case .prediction: return "sparkles"
        case .punctuality: return "target"
        case .wellBeing: return "heart.text.square.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .reminder: return AppTheme.warning
        case .habit: return AppTheme.primary
        case .prediction: return AppTheme.aiAccent
        case .punctuality: return AppTheme.success
        case .wellBeing: return Color.pink
        }
    }
}

struct AIInsight: Identifiable, Codable, Hashable {
    let id: UUID
    let type: AIInsightType
    let title: String
    let message: String
    let timestamp: Date
    let confidenceScore: Double // e.g. 0.94
    let actionTitle: String?
    let isDismissed: Bool
    
    init(
        id: UUID = UUID(),
        type: AIInsightType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        confidenceScore: Double = 0.95,
        actionTitle: String? = nil,
        isDismissed: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.confidenceScore = confidenceScore
        self.actionTitle = actionTitle
        self.isDismissed = isDismissed
    }
}
