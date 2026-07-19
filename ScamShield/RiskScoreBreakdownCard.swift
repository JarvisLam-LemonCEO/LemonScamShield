import SwiftUI

struct RiskScoreBreakdownCard: View {
    let analyzedValue: String
    let checkType: ScamCheckType

    @State private var isShowingDetails = true

    private var breakdown: RiskScoreBreakdown {
        RiskScoreBreakdownAnalyzer().analyze(
            analyzedValue,
            as: checkType
        )
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            header

            overallScoreSection

            if breakdown.activeContributions.isEmpty {
                emptyState
            } else {
                contributionSummary

                if isShowingDetails {
                    contributionList
                }

                detailsButton
            }

            limitationNotice
        }
        .padding()
        .background(
            scoreColor.opacity(0.07)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18
            )
            .stroke(
                scoreColor.opacity(0.20),
                lineWidth: 1
            )
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(
                systemName:
                    "chart.bar.xaxis.ascending"
            )
            .font(.title2)
            .foregroundStyle(scoreColor)
            .frame(
                width: 44,
                height: 44
            )
            .background(
                scoreColor.opacity(0.12)
            )
            .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("Risk score breakdown")
                    .font(.headline)

                Text(
                    "See what contributed to this result"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var overallScoreSection: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.14),
                        lineWidth: 11
                    )

                Circle()
                    .trim(
                        from: 0,
                        to:
                            CGFloat(
                                breakdown.totalScore
                            )
                            / 100
                    )
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(
                            lineWidth: 11,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(
                        .degrees(-90)
                    )

                VStack(spacing: 0) {
                    Text(
                        "\(breakdown.totalScore)"
                    )
                    .font(.title2)
                    .fontWeight(.bold)

                    Text("/ 100")
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }
            .frame(
                width: 96,
                height: 96
            )

            VStack(
                alignment: .leading,
                spacing: 7
            ) {
                Text(
                    "\(breakdown.riskLabel) risk"
                )
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(scoreColor)

                Text(
                    scoreSummary
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

                Text(
                    "\(breakdown.activeContributions.count) contributing categories"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var contributionSummary: some View {
        VStack(
            alignment: .leading,
            spacing: 9
        ) {
            HStack {
                Text("Strongest signals")
                    .font(.headline)

                Spacer()

                Text(
                    "Raw: \(breakdown.rawScore)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            ForEach(
                breakdown.activeContributions
                    .prefix(3)
            ) { contribution in
                HStack(spacing: 9) {
                    Image(
                        systemName:
                            contribution
                                .category
                                .systemImage
                    )
                    .foregroundStyle(
                        contributionColor(
                            contribution
                        )
                    )
                    .frame(width: 22)

                    Text(
                        contribution
                            .category
                            .title
                    )
                    .font(.subheadline)

                    Spacer()

                    Text(
                        "+\(contribution.points)"
                    )
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        contributionColor(
                            contribution
                        )
                    )
                }
            }
        }
    }

    private var contributionList: some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            Divider()

            Text("All score contributions")
                .font(.headline)

            ForEach(
                breakdown.activeContributions
            ) { contribution in
                contributionRow(
                    contribution
                )
            }
        }
    }

    private func contributionRow(
        _ contribution:
            RiskScoreContribution
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(spacing: 10) {
                Image(
                    systemName:
                        contribution
                            .category
                            .systemImage
                )
                .foregroundStyle(
                    contributionColor(
                        contribution
                    )
                )
                .frame(width: 24)

                Text(
                    contribution.category.title
                )
                .font(.subheadline)
                .fontWeight(.semibold)

                Spacer()

                Text(
                    "+\(contribution.points)"
                )
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(
                    contributionColor(
                        contribution
                    )
                )

                Text(
                    "/ \(contribution.maximumPoints)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(
                    alignment: .leading
                ) {
                    Capsule()
                        .fill(
                            Color.secondary
                                .opacity(0.13)
                        )

                    Capsule()
                        .fill(
                            contributionColor(
                                contribution
                            )
                        )
                        .frame(
                            width:
                                geometry.size.width
                                * contribution
                                    .percentage
                        )
                }
            }
            .frame(height: 7)

            Text(contribution.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .padding(.leading, 34)
        }
    }

    private var detailsButton: some View {
        Button {
            withAnimation(
                .easeInOut(duration: 0.2)
            ) {
                isShowingDetails.toggle()
            }
        } label: {
            HStack {
                Text(
                    isShowingDetails
                        ? "Hide detailed breakdown"
                        : "Show detailed breakdown"
                )

                Spacer()

                Image(
                    systemName:
                        isShowingDetails
                        ? "chevron.up"
                        : "chevron.down"
                )
            }
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        .buttonStyle(.plain)
        .foregroundStyle(scoreColor)
    }

    private var emptyState: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(
                systemName:
                    "checkmark.shield.fill"
            )
            .foregroundStyle(.green)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(
                    "No score contributions detected"
                )
                .font(.subheadline)
                .fontWeight(.semibold)

                Text(
                    "The local rules did not identify strong scam indicators in this submission."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var limitationNotice: some View {
        HStack(
            alignment: .top,
            spacing: 9
        ) {
            Image(
                systemName: "info.circle"
            )

            Text(
                "This score is an explainable local estimate. Categories may overlap, so the raw points are adjusted into a final score from 0 to 100."
            )
            .font(.caption)
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            Spacer()
        }
        .foregroundStyle(.secondary)
    }

    private var scoreColor: Color {
        switch breakdown.totalScore {
        case 0..<20:
            return .green

        case 20..<45:
            return .yellow

        case 45..<70:
            return .orange

        default:
            return .red
        }
    }

    private var scoreSummary: String {
        switch breakdown.totalScore {
        case 0..<20:
            return "Few strong warning signs were found by the local analysis."

        case 20..<45:
            return "Some warning signs were detected. Verify the request independently."

        case 45..<70:
            return "Several suspicious signals were detected. Avoid interacting until verified."

        default:
            return "Multiple high-risk signals were detected. Do not send information or money."
        }
    }

    private func contributionColor(
        _ contribution:
            RiskScoreContribution
    ) -> Color {
        switch contribution.percentage {
        case 0..<0.35:
            return .yellow

        case 0.35..<0.70:
            return .orange

        default:
            return .red
        }
    }
}

#Preview {
    ScrollView {
        RiskScoreBreakdownCard(
            analyzedValue:
                """
                URGENT PayPal security alert. Your account has been suspended. Verify your password and security code immediately at https://paypal-secure-login.xyz.
                """,
            checkType: .message
        )
        .padding()
    }
}
