import SwiftUI

struct AttendanceDetailSheet: View {
    let record: AttendanceRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header status badge
                VStack(spacing: 12) {
                    StatusBadgeView(status: record.status)
                    
                    Text(record.date.formattedDate)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.top, 16)
                
                // Detailed Information Table
                VStack(spacing: 14) {
                    detailRow(title: "Check-In Time", value: record.checkInTimeString, icon: "arrow.down.right.circle.fill", color: AppTheme.success)
                    Divider()
                    detailRow(title: "Check-Out Time", value: record.checkOutTimeString, icon: "arrow.up.left.circle.fill", color: AppTheme.danger)
                    Divider()
                    detailRow(title: "Total Duration", value: record.totalWorkingHoursString, icon: "clock.fill", color: AppTheme.primary)
                    Divider()
                    detailRow(title: "Location", value: record.location ?? "Office HQ", icon: "mappin.and.ellipse", color: .purple)
                    Divider()
                    detailRow(title: "Notes", value: record.notes ?? "Regular shift hours", icon: "note.text", color: .orange)
                    Divider()
                    detailRow(title: "Sync Status", value: record.isSyncedWithServer ? "Synced with Cloud" : "Local Cache", icon: "icloud.and.arrow.up.fill", color: .blue)
                }
                .padding(16)
                .background(AppTheme.cardBackground)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Attendance Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func detailRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}
