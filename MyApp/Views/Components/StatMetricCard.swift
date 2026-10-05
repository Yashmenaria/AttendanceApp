import SwiftUI

struct StatMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let iconName: String
    let accentColor: Color
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        iconName: String,
        accentColor: Color = AppTheme.primary
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.iconName = iconName
        self.accentColor = accentColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(accentColor)
                }
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(accentColor)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
}

#Preview {
    HStack {
        StatMetricCard(title: "This Week", value: "34.5 hrs", subtitle: "+2.5h vs last week", iconName: "clock.fill", accentColor: AppTheme.primary)
        StatMetricCard(title: "Punctuality", value: "96%", subtitle: "Top 5% in team", iconName: "target", accentColor: AppTheme.success)
    }
    .padding()
    .background(AppTheme.background)
}
