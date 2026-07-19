import Foundation

struct DashboardAnalyzer {

    func analyze(
        history: [ScanHistoryItem]
    ) -> DashboardStatistics {

        let calendar = Calendar.current
        let now = Date()

        let total = history.count

        let low = history.filter {
            $0.riskLevel == .low
        }.count

        let suspicious = history.filter {
            $0.riskLevel == .suspicious
        }.count

        let high = history.filter {
            $0.riskLevel == .high
        }.count

        let averageScore: Int

        if history.isEmpty {
            averageScore = 0
        } else {
            averageScore =
                history
                .map(\.score)
                .reduce(0,+)
                / history.count
        }

        let today = history.filter {
            calendar.isDateInToday(
                $0.createdAt
            )
        }.count

        let week = history.filter {

            guard let days =
                calendar.dateComponents(
                    [.day],
                    from: $0.createdAt,
                    to: now
                ).day
            else {
                return false
            }

            return days < 7

        }.count

        let month = history.filter {

            guard let days =
                calendar.dateComponents(
                    [.day],
                    from: $0.createdAt,
                    to: now
                ).day
            else {
                return false
            }

            return days < 30

        }.count

        let messages =
            history.filter {
                $0.checkType == .message
            }.count

        let websites =
            history.filter {
                $0.checkType == .website
            }.count

        let phones =
            history.filter {
                $0.checkType == .phone
            }.count

        let securityScore =
            calculateSecurityScore(
                averageScore: averageScore,
                highRisk: high,
                total: total
            )

        let lastWeek =
            lastSevenDays(
                history: history
            )

        return DashboardStatistics(
            totalScans: total,
            lowRiskScans: low,
            suspiciousScans: suspicious,
            highRiskScans: high,
            averageScore: averageScore,
            todayScans: today,
            weekScans: week,
            monthScans: month,
            messageScans: messages,
            websiteScans: websites,
            phoneScans: phones,
            overallSecurityScore: securityScore,
            lastSevenDays: lastWeek
        )
    }

    private func calculateSecurityScore(
        averageScore: Int,
        highRisk: Int,
        total: Int
    ) -> Int {

        guard total > 0 else {
            return 100
        }

        let riskPenalty =
            averageScore / 2

        let highPenalty =
            Int(
                Double(highRisk)
                / Double(total)
                * 30
            )

        return max(
            0,
            100 - riskPenalty - highPenalty
        )
    }

    private func lastSevenDays(
        history: [ScanHistoryItem]
    ) -> [DailyScanCount] {

        let calendar = Calendar.current

        return (0..<7).reversed().map {

            offset in

            let date =
                calendar.date(
                    byAdding: .day,
                    value: -offset,
                    to: Date()
                )!

            let count =
                history.filter {

                    calendar.isDate(
                        $0.createdAt,
                        inSameDayAs: date
                    )

                }.count

            return DailyScanCount(
                day: shortDay(date),
                count: count
            )
        }
    }

    private func shortDay(
        _ date: Date
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.dateFormat = "EEE"

        return formatter.string(
            from: date
        )
    }
}
