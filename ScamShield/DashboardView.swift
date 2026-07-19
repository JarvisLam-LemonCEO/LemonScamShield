import SwiftUI

struct DashboardView: View {

    let historyItems: [ScanHistoryItem]

    private var stats: DashboardStatistics {
        DashboardAnalyzer().analyze(
            history: historyItems
        )
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("Security Dashboard")
                .font(.largeTitle.bold())

            securityCard

            statisticsGrid

            scanTypeCard

            activityCard
        }
        .padding(.vertical)
    }

    private var securityCard: some View {

        VStack(spacing: 16) {

            ZStack {

                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: 12
                    )

                Circle()
                    .trim(
                        from: 0,
                        to: CGFloat(stats.overallSecurityScore) / 100
                    )
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))

                VStack {

                    Text("\(stats.overallSecurityScore)")
                        .font(.system(size: 34, weight: .bold))

                    Text("Security")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 130, height: 130)

            Text(scoreTitle)
                .font(.headline)
                .foregroundStyle(scoreColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private var statisticsGrid: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 14
        ) {

            statisticCard(
                title: "Total",
                value: "\(stats.totalScans)",
                color: .blue
            )

            statisticCard(
                title: "Average Risk",
                value: "\(stats.averageScore)%",
                color: .orange
            )

            statisticCard(
                title: "High Risk",
                value: "\(stats.highRiskScans)",
                color: .red
            )

            statisticCard(
                title: "Suspicious",
                value: "\(stats.suspiciousScans)",
                color: .orange
            )

            statisticCard(
                title: "Safe",
                value: "\(stats.lowRiskScans)",
                color: .green
            )

            statisticCard(
                title: "Today",
                value: "\(stats.todayScans)",
                color: .blue
            )

            statisticCard(
                title: "This Week",
                value: "\(stats.weekScans)",
                color: .purple
            )

            statisticCard(
                title: "This Month",
                value: "\(stats.monthScans)",
                color: .indigo
            )
        }
    }

    private var scanTypeCard: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Scan Types")
                .font(.headline)

            scanRow(
                title: "Messages",
                value: stats.messageScans
            )

            scanRow(
                title: "Websites",
                value: stats.websiteScans
            )

            scanRow(
                title: "Phone Numbers",
                value: stats.phoneScans
            )
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private var activityCard: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Last 7 Days")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 10) {

                let maxCount = max(
                    stats.lastSevenDays
                        .map(\.count)
                        .max() ?? 1,
                    1
                )

                ForEach(stats.lastSevenDays) { day in

                    VStack {

                        RoundedRectangle(
                            cornerRadius: 5
                        )
                        .fill(Color.blue)
                        .frame(
                            width: 22,
                            height: CGFloat(day.count)
                                / CGFloat(maxCount)
                                * 80
                        )

                        Text(day.day)
                            .font(.caption2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private func statisticCard(
        title: String,
        value: String,
        color: Color
    ) -> some View {

        VStack(alignment: .leading) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private func scanRow(
        title: String,
        value: Int
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text("\(value)")
                .fontWeight(.bold)
        }
    }

    private var scoreColor: Color {

        switch stats.overallSecurityScore {

        case 80...:
            return .green

        case 60..<80:
            return .orange

        default:
            return .red
        }
    }

    private var scoreTitle: String {

        switch stats.overallSecurityScore {

        case 80...:
            return "Excellent"

        case 60..<80:
            return "Good"

        case 40..<60:
            return "Moderate"

        default:
            return "Needs Attention"
        }
    }
}
