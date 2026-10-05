import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.28, green: 0.38, blue: 0.95) // Vibrant Indigo
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.28, green: 0.38, blue: 0.95), Color(red: 0.45, green: 0.22, blue: 0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let success = Color(red: 0.13, green: 0.77, blue: 0.48) // Emerald green
    static let successGradient = LinearGradient(
        colors: [Color(red: 0.13, green: 0.77, blue: 0.48), Color(red: 0.05, green: 0.65, blue: 0.60)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warning = Color(red: 0.98, green: 0.62, blue: 0.15) // Amber
    static let danger = Color(red: 0.95, green: 0.28, blue: 0.35) // Coral red
    static let dangerGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.28, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let aiAccent = Color(red: 0.58, green: 0.25, blue: 0.98) // Electric Violet
    static let aiGradient = LinearGradient(
        colors: [Color(red: 0.58, green: 0.25, blue: 0.98), Color(red: 0.18, green: 0.62, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let background = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemGroupedBackground)
}
