import SwiftUI

struct AttendanceHistoryView: View {
    @StateObject private var viewModel = AttendanceHistoryViewModel()
    @State private var selectedRecord: AttendanceRecord? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Segmented Bar
                filterSegmentedControl
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackground)
                
                // Content List
                if viewModel.isLoading && viewModel.records.isEmpty {
                    ScrollView {
                        SkeletonLoadingView()
                            .padding(16)
                    }
                } else if viewModel.filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    recordListView
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search by date or keyword")
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Attendance History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedRecord) { record in
                AttendanceDetailSheet(record: record)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadInitialHistory()
            }
        }
    }
    
    // MARK: - Filter Segmented Bar
    private var filterSegmentedControl: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(HistoryFilterOption.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Record List View
    private var recordListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Header Metrics Summary
                summaryHeader
                    .padding(.top, 8)
                
                ForEach(viewModel.filteredRecords) { record in
                    AttendanceRecordRow(record: record)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRecord = record
                            HapticManager.shared.impact(style: .light)
                        }
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentItem: record)
                        }
                }
                
                if viewModel.isLoadingMore {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading older attendance records...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Summary Header
    private var summaryHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Shift Hours")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f hrs", viewModel.totalHoursWorked))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("On-Time Rate")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f%%", viewModel.onTimePercentage))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.success)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Avg Daily")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f hrs", viewModel.averageDailyHours))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.6))
            Text("No attendance records found")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text("Try changing the filter or search query.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AttendanceHistoryView()
}
