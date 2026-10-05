import Foundation

struct PerformanceMetrics: Codable {
    var cachedRequestsCount: Int
    var networkRequestsCount: Int
    var totalBandwidthSavedKB: Double
    var averageResponseTimeMs: Double
    var cacheHitRatePercentage: Double
    var isOptimizedModeEnabled: Bool
    
    static let initial = PerformanceMetrics(
        cachedRequestsCount: 14,
        networkRequestsCount: 3,
        totalBandwidthSavedKB: 412.5,
        averageResponseTimeMs: 120.0,
        cacheHitRatePercentage: 82.3,
        isOptimizedModeEnabled: true
    )
}
