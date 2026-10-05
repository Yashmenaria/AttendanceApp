import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileSettingsViewModel()
    @State private var isShowingAISettings: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Employee Header Card
                    employeeProfileCard
                    
                    // Work Shift Settings Card
                    shiftSettingsCard
                    
                    // AI Multi-Provider Engine Settings
                    aiSettingsNavigationCard
                    
                    // Production & Performance Diagnostics Section
                    diagnosticsNavigationCard
                    
                    // App Information
                    appInfoSection
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingAISettings) {
                AISettingsSheetView()
            }
            .overlay(alignment: .top) {
                if let toast = viewModel.toastMessage {
                    ToastNotificationView(message: toast, isSuccess: true)
                        .padding(.top, 10)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    viewModel.toastMessage = nil
                                }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Profile Card
    private var employeeProfileCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 74, height: 74)
                Image(systemName: viewModel.employee.avatarSystemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(viewModel.employee.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(viewModel.employee.role) • \(viewModel.employee.department)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("ID: \(viewModel.employee.id)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppTheme.cardBackground)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Shift Settings Card
    private var shiftSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Work Shift & Schedule")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Button(action: {
                    viewModel.saveProfile()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Save & Sync")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            
            VStack(spacing: 12) {
                settingRow(icon: "clock.badge.checkmark", title: "Target Daily Hours", value: "\(Int(viewModel.employee.targetDailyHours)) Hours / Day")
                Divider()
                settingRow(icon: "sun.max.fill", title: "Expected Check-In", value: viewModel.employee.expectedCheckInTime)
                Divider()
                settingRow(icon: "moon.fill", title: "Expected Check-Out", value: viewModel.employee.expectedCheckOutTime)
                Divider()
                settingRow(icon: "building.2.fill", title: "Assigned Campus", value: "San Francisco HQ")
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(18)
            
            // Offline Sync Button
            Button(action: {
                viewModel.syncOfflineQueue()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                        .foregroundColor(AppTheme.aiAccent)
                    Text("Sync Queued Offline Check-Ins")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    if viewModel.isSyncing {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(AppTheme.cardBackground)
                .cornerRadius(14)
            }
        }
    }
    
    private func settingRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary)
                .font(.system(size: 15))
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
    
    // MARK: - AI Multi-Provider Settings Card
    private var aiSettingsNavigationCard: some View {
        Button(action: {
            isShowingAISettings = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.primary)
                        .font(.system(size: 18, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("AI Engine & Providers")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(AIConfigManager.shared.config.activeProvider.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AIConfigManager.shared.config.activeProvider.badgeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AIConfigManager.shared.config.activeProvider.badgeColor.opacity(0.12))
                            .cornerRadius(4)
                    }
                    Text("Configure Gemini, OpenAI, Claude, or Local heuristics")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Diagnostics Navigation
    private var diagnosticsNavigationCard: some View {
        NavigationLink(destination: PerformanceDiagnosticView(viewModel: viewModel)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.aiAccent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "speedometer")
                        .foregroundColor(AppTheme.aiAccent)
                        .font(.system(size: 18, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Performance & Architecture")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("View production metrics & incident fixes")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }
    
    // MARK: - App Info
    private var appInfoSection: some View {
        VStack(spacing: 4) {
            Text("Smart Attendance AI v1.2.0")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Text("SwiftUI MVVM Clean Architecture • URLSession & Cache")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(.top, 10)
    }
}

#Preview {
    ProfileView()
}

