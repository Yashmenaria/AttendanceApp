import SwiftUI

struct StatusBadgeView: View {
    let status: AttendanceStatus
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.icon)
                .font(.system(size: 11, weight: .semibold))
            Text(status.rawValue)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadgeView(status: .checkedIn)
        StatusBadgeView(status: .completed)
        StatusBadgeView(status: .late)
        StatusBadgeView(status: .overtime)
        StatusBadgeView(status: .notCheckedIn)
    }
    .padding()
}
