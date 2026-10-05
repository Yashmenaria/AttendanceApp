import SwiftUI

struct AttendanceRecordRow: View {
    let record: AttendanceRecord
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.date.formattedShortDate)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(record.date.formattedDate.components(separatedBy: ",").first ?? "")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadgeView(status: record.status)
            }
            
            Divider()
                .background(Color.gray.opacity(0.15))
            
            HStack {
                // Check-in
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right.circle.fill")
                        .foregroundColor(AppTheme.success)
                        .font(.system(size: 13))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("In")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(record.checkInTimeString)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Check-out
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.circle.fill")
                        .foregroundColor(AppTheme.danger)
                        .font(.system(size: 13))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Out")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(record.checkOutTimeString)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Working Hours
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .foregroundColor(AppTheme.primary)
                        .font(.system(size: 13))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Total")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(record.totalWorkingHoursString)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    AttendanceRecordRow(
        record: AttendanceRecord(
            date: Date(),
            checkInTime: Date().hoursAgo(8),
            checkOutTime: Date(),
            status: .completed
        )
    )
    .padding()
    .background(AppTheme.background)
}
