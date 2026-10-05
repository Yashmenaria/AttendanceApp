import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Employee Header & Greeting
                    headerSection
                    
                    // 2. AI Smart Insight Banner
                    if let topInsight = viewModel.aiInsights.first {
                        AIInsightBannerView(insight: topInsight) {
                            if topInsight.type == .reminder {
                                viewModel.checkIn()
                            } else if topInsight.type == .wellBeing && viewModel.isCurrentlyWorking {
                                viewModel.checkOut()
                            }
                        }
                    }
                    
                    // 3. Live Work Timer & Shift Ring
                    LiveWorkTimerView(
                        workingSeconds: viewModel.liveWorkingSeconds,
                        targetHours: viewModel.employee.targetDailyHours,
                        isWorking: viewModel.isCurrentlyWorking,
                        hasCompleted: viewModel.hasCompletedWorkToday
                    )
                    
                    // 4. Check-In / Check-Out Actions
                    CheckInOutActionCard(
                        todayRecord: viewModel.todayRecord,
                        isActionLoading: viewModel.isActionLoading,
                        onCheckIn: { viewModel.checkIn() },
                        onCheckOut: { viewModel.checkOut() }
                    )
                    
                    // 5. Quick Performance & Attendance Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Performance Overview")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            StatMetricCard(
                                title: "Weekly Hours",
                                value: String(format: "%.1fh", viewModel.weekTotalHours),
                                subtitle: "Target 40h",
                                iconName: "clock.fill",
                                accentColor: AppTheme.primary
                            )
                            
                            StatMetricCard(
                                title: "Punctuality",
                                value: "\(viewModel.punctualityScore)%",
                                subtitle: "Top 5% in team",
                                iconName: "target",
                                accentColor: AppTheme.success
                            )
                            
                            StatMetricCard(
                                title: "Days Present",
                                value: "\(viewModel.daysPresentThisMonth)d",
                                subtitle: "This Month",
                                iconName: "calendar.badge.checkmark",
                                accentColor: AppTheme.aiAccent
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task { await viewModel.fetchTodayData(forceRefresh: true) }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .refreshable {
                await viewModel.fetchTodayData(forceRefresh: true)
            }
            .overlay(alignment: .top) {
                if let toast = viewModel.successToastMessage {
                    ToastNotificationView(message: toast, isSuccess: true)
                        .padding(.top, 10)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    viewModel.successToastMessage = nil
                                }
                            }
                        }
                }
            }
            .alert("Attendance Notice", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
            }
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 52, height: 52)
                Image(systemName: viewModel.employee.avatarSystemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Welcome back,")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(viewModel.employee.name)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(Date().formattedDate)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadgeView(status: viewModel.todayRecord.status)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        )
    }
}

#Preview {
    HomeView()
}
