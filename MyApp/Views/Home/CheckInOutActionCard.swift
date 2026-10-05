import SwiftUI

struct CheckInOutActionCard: View {
    let todayRecord: AttendanceRecord
    let isActionLoading: Bool
    let onCheckIn: () -> Void
    let onCheckOut: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Timestamps Breakdown Row
            HStack(spacing: 16) {
                // Check-In Block
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(todayRecord.checkInTime != nil ? AppTheme.success : Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text("Check In")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    Text(todayRecord.checkInTimeString)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.tertiaryBackground)
                .cornerRadius(12)
                
                // Check-Out Block
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(todayRecord.checkOutTime != nil ? AppTheme.danger : Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text("Check Out")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    Text(todayRecord.checkOutTimeString)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.tertiaryBackground)
                .cornerRadius(12)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Check-In Button
                CustomButton(
                    title: "Check In",
                    icon: "figure.walk.arrival",
                    gradient: AppTheme.primaryGradient,
                    isLoading: isActionLoading && todayRecord.checkInTime == nil,
                    isEnabled: todayRecord.checkInTime == nil,
                    action: onCheckIn
                )
                
                // Check-Out Button
                CustomButton(
                    title: "Check Out",
                    icon: "figure.walk.departure",
                    gradient: AppTheme.dangerGradient,
                    isLoading: isActionLoading && todayRecord.checkInTime != nil && todayRecord.checkOutTime == nil,
                    isEnabled: todayRecord.checkInTime != nil && todayRecord.checkOutTime == nil,
                    action: onCheckOut
                )
            }
            
            // Location Badge
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(todayRecord.location ?? "San Francisco HQ Campus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                if !todayRecord.isSyncedWithServer {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                        Text("Optimistic Sync")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(AppTheme.warning)
                }
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    CheckInOutActionCard(
        todayRecord: AttendanceRecord(
            date: Date(),
            checkInTime: Date().hoursAgo(4),
            checkOutTime: nil,
            status: .checkedIn
        ),
        isActionLoading: false,
        onCheckIn: {},
        onCheckOut: {}
    )
    .padding()
    .background(AppTheme.background)
}
