import Foundation

struct Employee: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String
    var role: String
    var department: String
    var avatarSystemName: String
    var targetDailyHours: Double
    var expectedCheckInTime: String // e.g. "09:00 AM"
    var expectedCheckOutTime: String // e.g. "05:00 PM"
    
    static let sample = Employee(
        id: "EMP-10492",
        name: "Alex Morgan",
        email: "alex.morgan@techcorp.io",
        role: "Senior iOS Engineer",
        department: "Mobile Engineering",
        avatarSystemName: "person.crop.circle.fill",
        targetDailyHours: 8.0,
        expectedCheckInTime: "09:00 AM",
        expectedCheckOutTime: "05:00 PM"
    )
}
