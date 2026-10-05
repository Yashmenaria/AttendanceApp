import Foundation

struct AIContext {
    let employee: Employee
    let todayRecord: AttendanceRecord?
    let recentHistory: [AttendanceRecord]
    let currentTime: Date
    
    init(
        employee: Employee,
        todayRecord: AttendanceRecord?,
        recentHistory: [AttendanceRecord],
        currentTime: Date = Date()
    ) {
        self.employee = employee
        self.todayRecord = todayRecord
        self.recentHistory = recentHistory
        self.currentTime = currentTime
    }
}

final class AIPromptBuilder {
    
    static func buildSystemInstruction() -> String {
        return """
        You are an advanced Enterprise Attendance & Work-Life Intelligence AI.
        Your task is to analyze employee attendance, shift schedules, punctuality, and work-life balance patterns, then generate 3 to 4 actionable, highly personalized insights with high confidence.
        
        You MUST respond ONLY with a valid JSON array matching this exact schema:
        [
          {
            "type": "Reminder" | "Habit Analysis" | "Checkout Predictor" | "Punctuality Alert" | "Work-Life Balance",
            "title": "Concise catchy title with 1 emoji",
            "message": "Clear, contextual 1-2 sentence explanation tailored specifically to the employee's live hours and timestamps",
            "confidenceScore": 0.95,
            "actionTitle": "Short 2-3 word button action e.g. Set Alarm, Check In Now, View Trends, Wellness Tips"
          }
        ]
        
        Rules:
        1. "type" MUST be one of: "Reminder", "Habit Analysis", "Checkout Predictor", "Punctuality Alert", "Work-Life Balance".
        2. "confidenceScore" MUST be a float between 0.70 and 0.99.
        3. Do NOT include markdown code blocks (such as ```json), return raw JSON only.
        4. Focus on practical, helpful advice (e.g. smart arrival windows, shift completion predictions, break reminders, streak celebrations).
        """
    }
    
    static func buildUserPrompt(context: AIContext) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy h:mm a"
        let currentDateTimeString = formatter.string(from: context.currentTime)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        var todayStatusDesc = "Not checked in yet today."
        if let record = context.todayRecord {
            if let inTime = record.checkInTime {
                let inStr = timeFormatter.string(from: inTime)
                if let outTime = record.checkOutTime {
                    let outStr = timeFormatter.string(from: outTime)
                    todayStatusDesc = "Checked in at \(inStr), checked out at \(outStr). Status: \(record.status.rawValue)."
                } else {
                    let elapsedHours = context.currentTime.timeIntervalSince(inTime) / 3600.0
                    todayStatusDesc = "Currently active! Checked in at \(inStr) (\(String(format: "%.1f", elapsedHours)) hours logged so far today)."
                }
            }
        }
        
        // Compute history summary
        let historyCount = context.recentHistory.count
        let onTimeCount = context.recentHistory.filter { $0.status == .onTime || $0.status == .completed }.count
        let punctualityRate = historyCount > 0 ? (Double(onTimeCount) / Double(historyCount)) * 100.0 : 95.0
        let totalHours = context.recentHistory.reduce(0.0) { $0 + ($1.totalWorkingSeconds / 3600.0) }
        let avgDailyHours = historyCount > 0 ? (totalHours / Double(historyCount)) : context.employee.targetDailyHours
        
        var historyDetails = ""
        for (idx, rec) in context.recentHistory.prefix(5).enumerated() {
            let dayStr = timeFormatter.string(from: rec.date)
            let inStr = rec.checkInTime.map { timeFormatter.string(from: $0) } ?? "N/A"
            let outStr = rec.checkOutTime.map { timeFormatter.string(from: $0) } ?? "N/A"
            historyDetails += "\n  Day -\(idx + 1) (\(dayStr)): In: \(inStr), Out: \(outStr), Status: \(rec.status.rawValue)"
        }
        
        return """
        Generate real-time AI Insights for this employee based on current attendance data:
        
        - Current Time: \(currentDateTimeString)
        - Employee: \(context.employee.name) (\(context.employee.role), \(context.employee.department))
        - Target Daily Hours: \(String(format: "%.1f", context.employee.targetDailyHours)) hours
        - Expected Shift Window: \(context.employee.expectedCheckInTime) to \(context.employee.expectedCheckOutTime)
        - Today's Live Status: \(todayStatusDesc)
        - 7-Day Punctuality Rate: \(String(format: "%.1f", punctualityRate))% (\(onTimeCount)/\(max(1, historyCount)) days on-time)
        - 7-Day Average Working Hours: \(String(format: "%.1f", avgDailyHours)) hours/day
        - Recent Attendance Sample: \(historyDetails.isEmpty ? "No recent records" : historyDetails)
        
        Provide 3 to 4 distinct insights matching the required JSON format.
        """
    }
}
