import SwiftUI

struct AIInsightsDashboardView: View {
    @StateObject private var viewModel = AIInsightsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 0. Active AI Engine Status Banner
                    aiEngineStatusBanner
                    
                    // 1. Health Score & Punctuality Rating
                    PunctualityScoreCard(
                        healthScore: viewModel.healthScore,
                        rating: viewModel.punctualityRating
                    )
                    
                    // 2. Weekly Trend Chart
                    TrendChartView()
                    
                    if viewModel.isLoading && viewModel.insights.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView("Generating AI Insights with \(viewModel.activeProviderName)...")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.top, 40)
                        }
                    } else {
                        // 3. AI Generated Insights & Recommendations
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppTheme.aiAccent)
                                    .font(.system(size: 16))
                                Text("AI Insights & Predictive Advice")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                Button(action: {
                                    viewModel.regenerateInsights()
                                }) {
                                    HStack(spacing: 4) {
                                        if viewModel.isRegenerating {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        Text("Regenerate")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(AppTheme.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .disabled(viewModel.isRegenerating)
                            }
                            
                            ForEach(viewModel.insights) { insight in
                                AIInsightCard(insight: insight) {
                                    viewModel.executeAction(for: insight)
                                }
                            }
                        }
                    }
                    
                    // 4. Smart Automation Preferences Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("AI Automation Preferences")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            Toggle(isOn: $viewModel.isAutoReminderEnabled) {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Smart Check-In Reminders")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Predicts morning arrival based on commute")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                            .tint(AppTheme.primary)
                            .onChange(of: viewModel.isAutoReminderEnabled) { _ in
                                viewModel.updatePreferences()
                            }
                            
                            Divider()
                            
                            Toggle(isOn: $viewModel.isSmartPredictionActive) {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Departure Time Predictor")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Notifies when 8-hour target is reached")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "clock.badge.checkmark.fill")
                                        .foregroundColor(AppTheme.success)
                                }
                            }
                            .tint(AppTheme.success)
                            .onChange(of: viewModel.isSmartPredictionActive) { _ in
                                viewModel.updatePreferences()
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isShowingSettingsSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .semibold))
                            Text("AI Engine")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingSettingsSheet) {
                AISettingsSheetView {
                    viewModel.regenerateInsights()
                }
            }
            .alert("AI Service Notice", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
            }
            .overlay(alignment: .top) {
                if let toast = viewModel.actionToast {
                    ToastNotificationView(message: toast, isSuccess: true)
                        .padding(.top, 10)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    viewModel.actionToast = nil
                                }
                            }
                        }
                }
            }
            .refreshable {
                await viewModel.fetchAIInsightsFromAPI(forceRefresh: true)
            }
        }
    }
    
    // MARK: - AI Engine Status Banner
    private var aiEngineStatusBanner: some View {
        Button(action: {
            viewModel.isShowingSettingsSheet = true
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(viewModel.isUsingLocalFallback ? AppTheme.warning.opacity(0.15) : AppTheme.aiAccent.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: viewModel.isUsingLocalFallback ? "bolt.slash.fill" : "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.isUsingLocalFallback ? AppTheme.warning : AppTheme.aiAccent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(viewModel.activeProviderName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if viewModel.isUsingLocalFallback {
                            Text("Local Fallback")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.warning)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppTheme.warning.opacity(0.15))
                                .cornerRadius(4)
                        } else {
                            Text(viewModel.activeModelName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(viewModel.isUsingLocalFallback ? "API key not set. Tap to configure live cloud AI." : (viewModel.lastInferenceDurationMs > 0 ? "Response latency: \(Int(viewModel.lastInferenceDurationMs))ms • Real-time inference" : "Ready for live contextual inference"))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(AppTheme.cardBackground)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct AIInsightCard: View {
    let insight: AIInsight
    let onAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(insight.type.accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: insight.type.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(insight.type.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(insight.type.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(insight.type.accentColor)
                }
                
                Spacer()
                
                Text("\(Int(insight.confidenceScore * 100))% AI Match")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppTheme.tertiaryBackground)
                    .cornerRadius(6)
            }
            
            Text(insight.message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            if let action = insight.actionTitle {
                Button(action: onAction) {
                    HStack(spacing: 4) {
                        Text(action)
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(insight.type.accentColor)
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    AIInsightsDashboardView()
}
