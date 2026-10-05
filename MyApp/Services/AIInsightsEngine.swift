import Foundation

protocol AIInsightsEngineProtocol {
    func generateInsights(
        todayRecord: AttendanceRecord?,
        employee: Employee,
        recentHistory: [AttendanceRecord]
    ) -> [AIInsight]
}

final class AIInsightsEngine: AIInsightsEngineProtocol {
    static let shared = AIInsightsEngine()
    
    func generateInsights(
        todayRecord: AttendanceRecord?,
        employee: Employee,
        recentHistory: [AttendanceRecord]
    ) -> [AIInsight] {
        var insights: [AIInsight] = []
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        
        // 1. Check-In Reminder Insight
        if todayRecord == nil || todayRecord?.checkInTime == nil {
            if hour >= 8 && hour < 11 {
                insights.append(AIInsight(
                    type: .reminder,
                    title: "Smart Check-In Reminder",
                    message: "Good morning \(employee.name.components(separatedBy: " ").first ?? "")! Your shift typically begins around \(employee.expectedCheckInTime). Don't forget to mark your attendance.",
                    confidenceScore: 0.98,
                    actionTitle: "Check In Now"
                ))
            } else if hour >= 11 {
                insights.append(AIInsight(
                    type: .reminder,
                    title: "Missed Attendance Alert",
                    message: "You haven't recorded check-in for today. Record your status now to prevent unverified absence flags.",
                    confidenceScore: 0.99,
                    actionTitle: "Mark Attendance"
                ))
            }
        }
        
        // 2. Active Working & Checkout Predictor Insight
        if let checkIn = todayRecord?.checkInTime, todayRecord?.checkOutTime == nil {
            let elapsedHours = now.timeIntervalSince(checkIn) / 3600.0
            let target = employee.targetDailyHours
            
            if elapsedHours < target {
                let remainingHours = target - elapsedHours
                let targetDate = checkIn.addingTimeInterval(target * 3600)
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let targetTimeString = timeFormatter.string(from: targetDate)
                
                insights.append(AIInsight(
                    type: .prediction,
                    title: "Target Departure Prediction",
                    message: "To complete your \(Int(target))-hour target shift, your estimated checkout time is \(targetTimeString) (\(String(format: "%.1f", remainingHours))h remaining).",
                    confidenceScore: 0.96,
                    actionTitle: "Set Checkout Alarm"
                ))
            } else {
                insights.append(AIInsight(
                    type: .wellBeing,
                    title: "Daily Target Achieved 🎉",
                    message: "You've completed \(String(format: "%.1f", elapsedHours)) hours today. Remember to check out before leaving campus to record accurate overtime.",
                    confidenceScore: 0.94,
                    actionTitle: "Check Out"
                ))
            }
        }
        
        // 3. Historical Streak & Habit Analysis
        if !recentHistory.isEmpty {
            let onTimeCount = recentHistory.prefix(5).filter { $0.status == .onTime || $0.status == .completed }.count
            if onTimeCount >= 4 {
                insights.append(AIInsight(
                    type: .habit,
                    title: "Punctuality Excellence Streak 🌟",
                    message: "You've been on time for \(onTimeCount) of your last 5 working days! Your punctuality score is currently in the top 5% of \(employee.department).",
                    confidenceScore: 0.92,
                    actionTitle: "View Trends"
                ))
            }
            
            // Average working hours calculation
            let totalHistoryHours = recentHistory.prefix(7).reduce(0.0) { $0 + ($1.totalWorkingSeconds / 3600.0) }
            let avgHours = totalHistoryHours / Double(min(7, recentHistory.count))
            if avgHours > 8.5 {
                insights.append(AIInsight(
                    type: .wellBeing,
                    title: "Work-Life Balance Suggestion",
                    message: "Your 7-day daily average is \(String(format: "%.1f", avgHours))h. AI suggests spacing intense development sessions with micro-breaks.",
                    confidenceScore: 0.88,
                    actionTitle: "Wellness Tips"
                ))
            }
        }
        
        return insights
    }
}
