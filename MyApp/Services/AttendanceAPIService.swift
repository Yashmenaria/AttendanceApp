import Foundation

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case serverError(statusCode: Int)
    case decodingError
    case timeout
    case offline
    case alreadyCheckedIn
    case notCheckedIn
    case unauthorized
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server endpoint URL."
        case .serverError(let code):
            return "Server responded with HTTP error code \(code)."
        case .decodingError:
            return "Failed to parse API response payload."
        case .timeout:
            return "Network request timed out. Please check your internet connection."
        case .offline:
            return "No internet connection. Operating in cached offline mode."
        case .alreadyCheckedIn:
            return "You have already checked in for today."
        case .notCheckedIn:
            return "You must check in first before checking out."
        case .unauthorized:
            return "Session expired. Please re-authenticate."
        case .unknown(let msg):
            return msg
        }
    }
}

// MARK: - API Endpoint Definitions
enum APIEndpoint {
    case getTodayAttendance(employeeId: String)
    case checkIn(employeeId: String, location: String?, notes: String?)
    case checkOut(employeeId: String, location: String?, notes: String?)
    case getAttendanceHistory(employeeId: String, page: Int, pageSize: Int, status: String?, search: String?)
    case getAIInsights(employeeId: String)
    case updateAIPreferences(employeeId: String, autoReminder: Bool, departurePredictor: Bool)
    case getEmployeeProfile(employeeId: String)
    case updateEmployeeProfile(employee: Employee)
    case syncOfflineRecords(records: [AttendanceRecord])
    
    var path: String {
        switch self {
        case .getTodayAttendance:
            return "/api/v1/attendance/today"
        case .checkIn:
            return "/api/v1/attendance/check-in"
        case .checkOut:
            return "/api/v1/attendance/check-out"
        case .getAttendanceHistory:
            return "/api/v1/attendance/history"
        case .getAIInsights:
            return "/api/v1/ai/insights"
        case .updateAIPreferences:
            return "/api/v1/ai/preferences"
        case .getEmployeeProfile(let id):
            return "/api/v1/employees/\(id)"
        case .updateEmployeeProfile(let emp):
            return "/api/v1/employees/\(emp.id)"
        case .syncOfflineRecords:
            return "/api/v1/attendance/sync-offline"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .getTodayAttendance, .getAttendanceHistory, .getAIInsights, .getEmployeeProfile:
            return "GET"
        case .checkIn, .checkOut, .updateAIPreferences, .syncOfflineRecords:
            return "POST"
        case .updateEmployeeProfile:
            return "PUT"
        }
    }
}

// MARK: - API Protocol
protocol AttendanceAPIServiceProtocol {
    // 1. Home Screen API Calls
    func fetchTodayAttendance(for employeeId: String) async throws -> AttendanceRecord
    func checkIn(employeeId: String, location: String?, notes: String?) async throws -> AttendanceRecord
    func checkIn(employeeId: String, location: String?) async throws -> AttendanceRecord
    func checkOut(employeeId: String, location: String?, notes: String?) async throws -> AttendanceRecord
    func checkOut(employeeId: String, location: String?) async throws -> AttendanceRecord
    
    // 2. Attendance History Screen API Calls
    func fetchAttendanceHistory(employeeId: String, page: Int, pageSize: Int) async throws -> [AttendanceRecord]
    func fetchAttendanceHistory(employeeId: String, page: Int, pageSize: Int, status: String?, search: String?) async throws -> [AttendanceRecord]
    
    // 3. AI Insights & Reminders Service API Calls
    func fetchAIInsights(for employeeId: String) async throws -> [AIInsight]
    func updateAIPreferences(employeeId: String, autoReminder: Bool, departurePredictor: Bool) async throws -> Bool
    
    // 4. Profile & Diagnostic API Calls
    func fetchEmployeeProfile(for employeeId: String) async throws -> Employee
    func updateEmployeeProfile(_ employee: Employee) async throws -> Employee
    func syncOfflineAttendanceRecords(_ records: [AttendanceRecord]) async throws -> Int
}

// MARK: - API Service Implementation
final class AttendanceAPIService: AttendanceAPIServiceProtocol {
    static let shared = AttendanceAPIService()
    
    private let baseURLString = "https://api.smartattendance.enterprise.io"
    private let session: URLSession
    
    // Configurable latency and failure injection for assessment diagnostic demo
    var simulateNetworkLatency: Double = 0.35 // 350ms optimized (or 2.5s incident simulation)
    var shouldSimulateRandomFailure: Bool = false
    
    init(session: URLSession = .shared) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.requestCachePolicy = .reloadRevalidatingCacheData
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "X-App-Version": "1.2.0",
            "X-Platform": "iOS"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - URLRequest Builder Helper
    private func buildRequest(for endpoint: APIEndpoint, queryItems: [URLQueryItem] = [], body: Data? = nil) throws -> URLRequest {
        guard var components = URLComponents(string: baseURLString + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_token", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - 1. Home Screen API Calls
    
    /// `GET /api/v1/attendance/today?employee_id={id}`
    func fetchTodayAttendance(for employeeId: String) async throws -> AttendanceRecord {
        // Construct standard URLSession request
        let _ = try buildRequest(
            for: .getTodayAttendance(employeeId: employeeId),
            queryItems: [URLQueryItem(name: "employee_id", value: employeeId)]
        )
        
        // Simulate network latency (0.35s normal / 2.5s slow)
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 1_000_000_000))
        
        if shouldSimulateRandomFailure && Double.random(in: 0...1) < 0.20 {
            throw NetworkError.serverError(statusCode: 503)
        }
        
        // Return dummy today's status payload
        return AttendanceRecord(
            date: Date(),
            checkInTime: nil,
            checkOutTime: nil,
            status: .notCheckedIn,
            location: "San Francisco HQ",
            isSyncedWithServer: true
        )
    }
    
    /// `POST /api/v1/attendance/check-in`
    func checkIn(employeeId: String, location: String?, notes: String?) async throws -> AttendanceRecord {
        let payload: [String: Any] = [
            "employee_id": employeeId,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "location": location ?? "San Francisco HQ",
            "notes": notes ?? "Checked in via iOS Mobile App"
        ]
        let bodyData = try? JSONSerialization.data(withJSONObject: payload)
        let _ = try buildRequest(for: .checkIn(employeeId: employeeId, location: location, notes: notes), body: bodyData)
        
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 1_000_000_000))
        
        if shouldSimulateRandomFailure && Double.random(in: 0...1) < 0.15 {
            throw NetworkError.serverError(statusCode: 500)
        }
        
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let isLate = hour >= 9 && Calendar.current.component(.minute, from: now) > 15
        
        return AttendanceRecord(
            date: now,
            checkInTime: now,
            checkOutTime: nil,
            status: isLate ? .late : .onTime,
            notes: notes ?? "Checked in via iOS Mobile App",
            location: location ?? "San Francisco HQ",
            isSyncedWithServer: true
        )
    }
    
    func checkIn(employeeId: String, location: String?) async throws -> AttendanceRecord {
        try await checkIn(employeeId: employeeId, location: location, notes: nil)
    }
    
    /// `POST /api/v1/attendance/check-out`
    func checkOut(employeeId: String, location: String?, notes: String?) async throws -> AttendanceRecord {
        let payload: [String: Any] = [
            "employee_id": employeeId,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "location": location ?? "San Francisco HQ",
            "notes": notes ?? "Day shift completed successfully"
        ]
        let bodyData = try? JSONSerialization.data(withJSONObject: payload)
        let _ = try buildRequest(for: .checkOut(employeeId: employeeId, location: location, notes: notes), body: bodyData)
        
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 1_000_000_000))
        
        if shouldSimulateRandomFailure && Double.random(in: 0...1) < 0.15 {
            throw NetworkError.serverError(statusCode: 502)
        }
        
        let now = Date()
        return AttendanceRecord(
            date: now,
            checkInTime: now.hoursAgo(8),
            checkOutTime: now,
            status: .completed,
            notes: notes ?? "Day shift completed successfully",
            location: location ?? "San Francisco HQ",
            isSyncedWithServer: true
        )
    }
    
    func checkOut(employeeId: String, location: String?) async throws -> AttendanceRecord {
        try await checkOut(employeeId: employeeId, location: location, notes: nil)
    }
    
    // MARK: - 2. Attendance History Screen API Calls
    
    /// `GET /api/v1/attendance/history?employee_id={id}&page={page}&page_size={pageSize}`
    func fetchAttendanceHistory(employeeId: String, page: Int, pageSize: Int = 15) async throws -> [AttendanceRecord] {
        try await fetchAttendanceHistory(employeeId: employeeId, page: page, pageSize: pageSize, status: nil, search: nil)
    }
    
    func fetchAttendanceHistory(employeeId: String, page: Int, pageSize: Int = 15, status: String? = nil, search: String? = nil) async throws -> [AttendanceRecord] {
        var queryItems = [
            URLQueryItem(name: "employee_id", value: employeeId),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let status = status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: search))
        }
        
        let _ = try buildRequest(for: .getAttendanceHistory(employeeId: employeeId, page: page, pageSize: pageSize, status: status, search: search), queryItems: queryItems)
        
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 1_000_000_000))
        
        if shouldSimulateRandomFailure && Double.random(in: 0...1) < 0.08 {
            throw NetworkError.timeout
        }
        
        // Generate realistic historical records paginated
        var records: [AttendanceRecord] = []
        let startIndex = (page - 1) * pageSize
        let calendar = Calendar.current
        
        // Simulate finite history of 60 records (4 pages)
        if startIndex >= 60 {
            return []
        }
        
        let maxIndex = min(startIndex + pageSize, 60)
        
        for i in startIndex..<maxIndex {
            guard let date = calendar.date(byAdding: .day, value: -(i + 1), to: Date()) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            
            // Skip weekends
            if weekday == 1 || weekday == 7 {
                continue
            }
            
            let inHour = i % 4 == 0 ? 9 : 8
            let inMinute = (i * 7) % 60
            let outHour = (i % 5 == 0) ? 17 : 18
            let outMinute = (i * 11) % 60
            
            var inComponents = calendar.dateComponents([.year, .month, .day], from: date)
            inComponents.hour = inHour
            inComponents.minute = inMinute
            let checkIn = calendar.date(from: inComponents)
            
            var outComponents = calendar.dateComponents([.year, .month, .day], from: date)
            outComponents.hour = outHour
            outComponents.minute = outMinute
            let checkOut = calendar.date(from: outComponents)
            
            let recordStatus: AttendanceStatus
            if inHour >= 9 && inMinute > 15 {
                recordStatus = .late
            } else if outHour >= 18 && outMinute >= 30 {
                recordStatus = .overtime
            } else {
                recordStatus = .completed
            }
            
            records.append(AttendanceRecord(
                date: date,
                checkInTime: checkIn,
                checkOutTime: checkOut,
                status: recordStatus,
                notes: "Normal shift logged via mobile client",
                location: "San Francisco HQ - Floor 4",
                isSyncedWithServer: true
            ))
        }
        
        return records
    }
    
    // MARK: - 3. AI Insights & Reminders Service API Calls
    
    /// `GET /api/v1/ai/insights?employee_id={id}` or Direct Multi-Provider AI Inference
    func fetchAIInsights(for employeeId: String) async throws -> [AIInsight] {
        let _ = try? buildRequest(
            for: .getAIInsights(employeeId: employeeId),
            queryItems: [URLQueryItem(name: "employee_id", value: employeeId)]
        )
        
        // Build live context from cache & state
        let employee = AttendanceCacheService.shared.loadEmployeeProfile() ?? Employee.sample
        let todayRecord = AttendanceCacheService.shared.loadTodayRecord()
        let recentHistory = AttendanceCacheService.shared.loadRecentHistory() ?? []
        let context = AIContext(
            employee: employee,
            todayRecord: todayRecord,
            recentHistory: recentHistory
        )
        
        let response = await AIMultiProviderService.shared.generateInsights(context: context)
        return response.insights
    }
    
    /// `POST /api/v1/ai/preferences`
    func updateAIPreferences(employeeId: String, autoReminder: Bool, departurePredictor: Bool) async throws -> Bool {
        let payload: [String: Any] = [
            "employee_id": employeeId,
            "auto_reminder_enabled": autoReminder,
            "departure_predictor_enabled": departurePredictor
        ]
        let bodyData = try? JSONSerialization.data(withJSONObject: payload)
        let _ = try buildRequest(
            for: .updateAIPreferences(employeeId: employeeId, autoReminder: autoReminder, departurePredictor: departurePredictor),
            body: bodyData
        )
        
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 0.8 * 1_000_000_000))
        return true
    }
    
    // MARK: - 4. Profile & Diagnostic API Calls
    
    /// `GET /api/v1/employees/{id}`
    func fetchEmployeeProfile(for employeeId: String) async throws -> Employee {
        let _ = try buildRequest(for: .getEmployeeProfile(employeeId: employeeId))
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 1_000_000_000))
        
        return Employee.sample
    }
    
    /// `PUT /api/v1/employees/{id}`
    func updateEmployeeProfile(_ employee: Employee) async throws -> Employee {
        let encoder = JSONEncoder()
        let bodyData = try? encoder.encode(employee)
        let _ = try buildRequest(for: .updateEmployeeProfile(employee: employee), body: bodyData)
        
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 1_000_000_000))
        return employee
    }
    
    /// `POST /api/v1/attendance/sync-offline`
    func syncOfflineAttendanceRecords(_ records: [AttendanceRecord]) async throws -> Int {
        guard !records.isEmpty else { return 0 }
        
        let encoder = JSONEncoder()
        let bodyData = try? encoder.encode(records)
        let _ = try buildRequest(for: .syncOfflineRecords(records: records), body: bodyData)
        
        try await Task.sleep(nanoseconds: UInt64(simulateNetworkLatency * 1.2 * 1_000_000_000))
        return records.count
    }
}

