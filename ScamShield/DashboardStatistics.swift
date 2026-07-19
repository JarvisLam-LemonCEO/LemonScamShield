import Foundation

struct DashboardStatistics {

    let totalScans: Int

    let lowRiskScans: Int
    let suspiciousScans: Int
    let highRiskScans: Int

    let averageScore: Int

    let todayScans: Int
    let weekScans: Int
    let monthScans: Int

    let messageScans: Int
    let websiteScans: Int
    let phoneScans: Int

    let overallSecurityScore: Int

    let lastSevenDays: [DailyScanCount]
}

struct DailyScanCount: Identifiable {

    let id = UUID()

    let day: String

    let count: Int
}
