# Smart Attendance App — AI-Powered Daily Attendance & Check-In

A complete, production oriented iOS application built with **SwiftUI** and **MVVM Architecture** addressing all requirements and production incident investigations from the **AI Use Case Assessment for Associate iOS Developer**.

---

## 📱 Features & Highlights

### 1. Home Dashboard Screen
- **Employee Header**: Displays employee profile avatar, name, and today's formatted date.
- **Attendance Status Badge**: Real-time status indicator (`Checked In`, `Completed`, `Late Arrival`, `On Time`, `Overtime`, `Not Checked In`).
- **AI Smart Reminder & Insight Banner**: Contextual dynamic banners for morning check-in reminders, departure time predictions, and streak acknowledgments.
- **Live Work Timer Ring**: Dynamic circular gauge computing elapsed shift time, completion percentage towards daily 8-hour target, and active status.
- **Interactive Check-In / Check-Out Card**: Quick action buttons with spring haptic feedback, timestamps breakdown, location badge, and optimistic sync status.
- **Weekly Performance Summary**: Glanceable metric cards for weekly hours, punctuality score, and monthly days present.

### 2. Attendance History Screen
- **Record Breakdown**: Displays formatted Date, Check-In Time, Check-Out Time, Total Working Hours, and Status.
- **Smart Filtering**: Segmented control (`All`, `On Time`, `Late`, `Overtime`) + instant text search for dates and notes.
- **Summary Metrics**: Total cumulative shift hours, team on-time rate, and average daily hours.
- **Lazy Loading & Pagination**: Loads 15 records per page with automatic scroll threshold detection to avoid downloading entire multi-year histories upfront.
- **Detail Modal**: Interactive sheet inspecting check-in details, geolocation campus, notes, and cloud synchronization status.

### 3. AI Insights & Predictions Dashboard
- **Attendance Health Score**: Dynamic circular score gauge (0–100) reflecting punctuality, regularity, and shift consistency.
- **Weekly Shift Hours Chart**: Visual bar graph comparing actual daily hours against standard targets.
- **AI Predictive Recommendations**: Commute arrival window suggestions, work-life balance advice, and Friday trend analysis.
- **Automated Reminder Triggers**: Configurable background notification alerts for morning check-ins and end-of-shift checkouts.

### 4. Automated Unit Test Suite & Diagnostics
- **Built-in Test Runner**: An interactive in-app test engine (`UnitTestRunner`) in [`PerformanceDiagnosticView.swift`](file:///Users/yashish/Desktop/AI%20codebase/MyApp/Views/Profile/PerformanceDiagnosticView.swift) to execute and verify test assertions with millisecond duration tracking.
- **Standalone XCTest Test Files**: Located in [`Tests/`](file:///Users/yashish/Desktop/AI%20codebase/Tests) covering:
  - [`HomeViewModelTests.swift`](file:///Users/yashish/Desktop/AI%20codebase/Tests/HomeViewModelTests.swift): Initial state, optimistic Check-In/Check-Out, error rollback, and target shift percentage calculations.
  - [`AttendanceHistoryViewModelTests.swift`](file:///Users/yashish/Desktop/AI%20codebase/Tests/AttendanceHistoryViewModelTests.swift): Paginated cursor loading, status filtering, case-insensitive query searching, and on-time rate calculations.
  - [`AIInsightsEngineTests.swift`](file:///Users/yashish/Desktop/AI%20codebase/Tests/AIInsightsEngineTests.swift): Morning reminder triggers, departure time predictions, and streak detection.
  - [`AttendanceRepositoryTests.swift`](file:///Users/yashish/Desktop/AI%20codebase/Tests/AttendanceRepositoryTests.swift): Cache-first validation (Finding 1), TTL invalidation (Finding 3), in-flight task deduplication (Finding 4), and telemetry logging.
  - [`MockAttendanceServices.swift`](file:///Users/yashish/Desktop/AI%20codebase/Tests/Mocks/MockAttendanceServices.swift): Dependency injection mock doubles for isolated unit testing.

### 5. Production Performance Diagnostics
- **Incident Resolution Benchmarks**: Compares pre-optimization vs post-optimization metrics (Launch time: 4.0s → 0.8s; API response time: 2.5s → 120ms; Crash rate: 3% → 0.05%).
- **Active Runtime Telemetry**: Real-time tracking of cache hits, network requests, bandwidth saved, and average latency.
- **Diagnostic Testing Controls**: Toggles to simulate 2.5s network lag, 503 server errors, and local cache purging.

---

## 🏗 MVVM Clean Architecture

```
MyApp/
├── MyApp.swift                           # App Lifecycle & Notification setup
├── Models/
│   ├── Employee.swift                    # Employee profile data model
│   ├── AttendanceRecord.swift            # Attendance records & status enum
│   ├── AIInsight.swift                   # AI insight item & category types
│   └── PerformanceMetrics.swift          # Production telemetry metrics
├── Services/
│   ├── AttendanceAPIService.swift        # URLSession async/await API client
│   ├── AttendanceCacheService.swift      # Dual-tier cache (NSCache + UserDefaults)
│   ├── AttendanceRepository.swift        # Single Source of Truth + Request Deduplication
│   ├── AIInsightsEngine.swift            # Rule & ML-based recommendation engine
│   └── NotificationService.swift         # UserNotifications local alert manager
├── ViewModels/
│   ├── HomeViewModel.swift               # Home state, live timer, optimistic updates
│   ├── AttendanceHistoryViewModel.swift  # Paginated loading, filtering & search
│   ├── AIInsightsViewModel.swift         # AI health score & automation preferences
│   └── ProfileSettingsViewModel.swift    # Diagnostics & profile configuration
├── Views/
│   ├── MainTabView.swift                 # Bottom Tab Bar navigation
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── LiveWorkTimerView.swift
│   │   ├── AIInsightBannerView.swift
│   │   └── CheckInOutActionCard.swift
│   ├── History/
│   │   ├── AttendanceHistoryView.swift
│   │   ├── AttendanceRecordRow.swift
│   │   └── AttendanceDetailSheet.swift
│   ├── AIInsights/
│   │   ├── AIInsightsDashboardView.swift
│   │   ├── PunctualityScoreCard.swift
│   │   └── TrendChartView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── PerformanceDiagnosticView.swift
│   └── Components/
│       ├── StatusBadgeView.swift
│       ├── StatMetricCard.swift
│       ├── CustomButton.swift
│       ├── ToastNotificationView.swift
│       └── SkeletonLoadingView.swift
└── Utilities/
    ├── ColorTheme.swift                  # Color tokens & gradients
    ├── DateExtensions.swift              # Date & duration formatters
    └── HapticManager.swift               # UI feedback generator
```

---

