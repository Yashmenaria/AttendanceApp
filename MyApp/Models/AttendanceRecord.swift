import SwiftUI

enum AttendanceStatus: String, Codable, CaseIterable {
    case notCheckedIn = "Not Checked In"
    case checkedIn = "Checked In (Active)"
    case completed = "Completed"
    case late = "Late Arrival"
    case onTime = "On Time"
    case halfDay = "Half Day"
    case overtime = "Overtime"
    case absent = "Absent"
    
    var color: Color {
        switch self {
        case .notCheckedIn, .absent:
            return .gray
        case .checkedIn:
            return AppTheme.primary
        case .completed, .onTime:
            return AppTheme.success
        case .late:
            return AppTheme.warning
        case .halfDay:
            return .orange
        case .overtime:
            return AppTheme.aiAccent
        }
    }
    
    var icon: String {
        switch self {
        case .notCheckedIn:
            return "clock.badge.questionmark"
        case .checkedIn:
            return "figure.walk.arrival"
        case .completed, .onTime:
            return "checkmark.circle.fill"
        case .late:
            return "exclamationmark.circle.fill"
        case .halfDay:
            return "hourglass.bottomhalf.filled"
        case .overtime:
            return "bolt.badge.clock.fill"
        case .absent:
            return "xmark.circle.fill"
        }
    }
}

struct AttendanceRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    var checkInTime: Date?
    var checkOutTime: Date?
    var status: AttendanceStatus
    var notes: String?
    var location: String?
    var isSyncedWithServer: Bool
    
    init(
        id: UUID = UUID(),
        date: Date,
        checkInTime: Date? = nil,
        checkOutTime: Date? = nil,
        status: AttendanceStatus = .notCheckedIn,
        notes: String? = nil,
        location: String? = "San Francisco HQ",
        isSyncedWithServer: Bool = true
    ) {
        self.id = id
        self.date = date
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.status = status
        self.notes = notes
        self.location = location
        self.isSyncedWithServer = isSyncedWithServer
    }
    
    var totalWorkingSeconds: TimeInterval {
        guard let checkIn = checkInTime else { return 0 }
        if let checkOut = checkOutTime {
            return max(0, checkOut.timeIntervalSince(checkIn))
        } else if date.isToday {
            return max(0, Date().timeIntervalSince(checkIn))
        }
        return 0
    }
    
    var totalWorkingHoursString: String {
        guard checkInTime != nil else { return "--" }
        return totalWorkingSeconds.formattedShortDuration
    }
    
    var checkInTimeString: String {
        checkInTime?.formattedTime ?? "--:--"
    }
    
    var checkOutTimeString: String {
        checkOutTime?.formattedTime ?? "--:--"
    }
    
    var dateString: String {
        date.formattedDate
    }
}
