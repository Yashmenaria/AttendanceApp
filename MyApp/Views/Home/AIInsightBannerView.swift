import SwiftUI

struct AIInsightBannerView: View {
    let insight: AIInsight
    let onActionTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppTheme.aiAccent.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.aiAccent)
                }
                
                Text(insight.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.aiAccent)
                
                Spacer()
                
                Text("\(Int(insight.confidenceScore * 100))% AI Match")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.aiAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(AppTheme.aiAccent.opacity(0.12))
                    )
            }
            
            Text(insight.message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(2)
            
            if let action = insight.actionTitle {
                Button(action: onActionTap) {
                    HStack(spacing: 4) {
                        Text(action)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(AppTheme.aiAccent)
                    .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.aiAccent.opacity(0.08), AppTheme.primary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(AppTheme.aiAccent.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AIInsightBannerView(
        insight: AIInsight(
            type: .prediction,
            title: "Target Departure Prediction",
            message: "To achieve your 8-hour target shift, your recommended checkout time is 5:30 PM (2.4h remaining).",
            actionTitle: "Set Checkout Alarm"
        ),
        onActionTap: {}
    )
    .padding()
}
