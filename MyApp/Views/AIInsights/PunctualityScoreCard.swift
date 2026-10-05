import SwiftUI

struct PunctualityScoreCard: View {
    let healthScore: Int
    let rating: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Circular Gauge
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(Double(healthScore) / 100.0))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 0) {
                        Text("\(healthScore)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ 100")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                        Text("AI Attendance Health")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    
                    Text(rating)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Calculated from check-in timing consistency, shift duration, and absence rates.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
        }
        .padding(18)
        .background(
            AppTheme.aiGradient
        )
        .cornerRadius(22)
        .shadow(color: AppTheme.aiAccent.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    PunctualityScoreCard(healthScore: 94, rating: "Top Tier (Top 5%)")
        .padding()
}
