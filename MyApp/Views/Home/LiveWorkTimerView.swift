import SwiftUI

struct LiveWorkTimerView: View {
    let workingSeconds: TimeInterval
    let targetHours: Double
    let isWorking: Bool
    let hasCompleted: Bool
    
    private var progress: Double {
        let targetSec = targetHours * 3600.0
        guard targetSec > 0 else { return 0 }
        return min(1.0, workingSeconds / targetSec)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 170, height: 170)
                
                // Active Progress Ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        isWorking ? AppTheme.primaryGradient : (hasCompleted ? AppTheme.successGradient : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 170, height: 170)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                
                // Center Digital Timer
                VStack(spacing: 4) {
                    Image(systemName: isWorking ? "bolt.fill" : (hasCompleted ? "checkmark.circle.fill" : "moon.stars.fill"))
                        .font(.system(size: 20))
                        .foregroundColor(isWorking ? AppTheme.primary : (hasCompleted ? AppTheme.success : .secondary))
                    
                    Text(workingSeconds.formattedDuration)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text(isWorking ? "Active Shift" : (hasCompleted ? "Shift Ended" : "Not Started"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .padding(.top, 8)
            
            HStack(spacing: 16) {
                Label {
                    Text("Target: \(Int(targetHours))h 00m")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                }
                
                Divider()
                    .frame(height: 14)
                
                Label {
                    Text("\(Int(progress * 100))% Achieved")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(progress >= 1.0 ? AppTheme.success : AppTheme.primary)
                } icon: {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(progress >= 1.0 ? AppTheme.success : AppTheme.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    LiveWorkTimerView(workingSeconds: 18450, targetHours: 8.0, isWorking: true, hasCompleted: false)
        .padding()
        .background(AppTheme.background)
}
