import SwiftUI

struct TrendChartView: View {
    let days: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    let hours: [Double] = [8.2, 8.5, 7.8, 8.9, 8.1]
    let target: Double = 8.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Weekly Shift Hours Trend")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Target: 8.0 hrs / day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                    Text("Actual")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Bar Chart Representation
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(0..<days.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", hours[index]))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(hours[index] >= target ? AppTheme.primary : AppTheme.warning)
                        
                        ZStack(alignment: .bottom) {
                            // Target guide background
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 32, height: 110)
                            
                            // Bar fill
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    hours[index] >= target ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.warning, AppTheme.warning.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 32, height: CGFloat(hours[index] / 10.0 * 110))
                        }
                        
                        Text(days[index])
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 6)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    TrendChartView()
        .padding()
        .background(AppTheme.background)
}
