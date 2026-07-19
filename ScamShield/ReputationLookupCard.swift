import SwiftUI

struct ReputationLookupCard: View {
    let analyzedValue: String
    let checkType: ScamCheckType

    @StateObject private var viewModel =
        ReputationLookupViewModel()

    var body: some View {
        if checkType != .phone {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                header

                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage =
                    viewModel.errorMessage {
                    errorView(errorMessage)
                } else if viewModel
                    .results.isEmpty {
                    noURLsView
                } else {
                    resultsView
                }
            }
            .padding()
            .background(
                Color.secondary.opacity(0.06)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    overallColor.opacity(0.2),
                    lineWidth: 1
                )
            }
            .task(id: lookupIdentifier) {
                await viewModel.load(
                    analyzedValue:
                        analyzedValue,
                    checkType:
                        checkType
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Label(
                "Reputation check",
                systemImage:
                    "checkmark.shield"
            )
            .font(.headline)

            Spacer()

            Text("DEMO")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Color.orange.opacity(0.12)
                )
                .clipShape(Capsule())
        }
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    "Checking reputation…"
                )
                .font(.subheadline)
                .fontWeight(.medium)

                Text(
                    "Using the local mock provider."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func errorView(
        _ message: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Label(
                "Lookup failed",
                systemImage:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await viewModel.load(
                        analyzedValue:
                            analyzedValue,
                        checkType:
                            checkType,
                        forceRefresh: true
                    )
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var noURLsView: some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(
                systemName: "link.badge.plus"
            )
            .foregroundStyle(.secondary)

            Text(
                "No website address was available for a reputation lookup."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var resultsView: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            ForEach(
                viewModel.results
            ) { result in
                resultSection(result)

                if result.id
                    != viewModel.results.last?.id {
                    Divider()
                }
            }

            Text(
                "This is simulated reputation data. It is not currently checking a live security provider."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func resultSection(
        _ result: URLReputationResult
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack(
                alignment: .top,
                spacing: 10
            ) {
                Image(
                    systemName:
                        systemImage(
                            for: result.verdict
                        )
                )
                .font(.title3)
                .foregroundStyle(
                    color(
                        for: result.verdict
                    )
                )

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(
                        result.verdict.title
                    )
                    .font(.headline)
                    .foregroundStyle(
                        color(
                            for: result.verdict
                        )
                    )

                    Text(result.host)
                        .font(.subheadline)
                        .textSelection(.enabled)

                    Text(
                        "\(result.confidence)% confidence"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            confidenceBar(
                confidence:
                    result.confidence,
                verdict:
                    result.verdict
            )

            ForEach(
                result.findings
            ) { finding in
                HStack(
                    alignment: .top,
                    spacing: 9
                ) {
                    Image(
                        systemName:
                            "circle.fill"
                    )
                    .font(.system(size: 6))
                    .padding(.top, 6)
                    .foregroundStyle(
                        color(
                            for:
                                result.verdict
                        )
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text(finding.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(finding.detail)
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    Spacer()
                }
            }

            if let reportCount =
                result.reportCount {
                Label(
                    "\(reportCount) simulated reports",
                    systemImage:
                        "person.3.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let lastReportedAt =
                result.lastReportedAt {
                Label {
                    Text(
                        "Last simulated report \(lastReportedAt.formatted(.relative(presentation: .named)))"
                    )
                } icon: {
                    Image(
                        systemName: "clock"
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(
                "Source: \(result.providerName)"
            )
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    private func confidenceBar(
        confidence: Int,
        verdict: URLReputationVerdict
    ) -> some View {
        GeometryReader { geometry in
            ZStack(
                alignment: .leading
            ) {
                Capsule()
                    .fill(
                        Color.secondary
                            .opacity(0.15)
                    )

                Capsule()
                    .fill(
                        color(for: verdict)
                    )
                    .frame(
                        width:
                            geometry.size.width
                            * CGFloat(confidence)
                            / 100
                    )
            }
        }
        .frame(height: 8)
    }

    private var lookupIdentifier: String {
        "\(checkType.rawValue)|\(analyzedValue)"
    }

    private var overallColor: Color {
        if viewModel.results.contains(
            where: {
                $0.verdict == .malicious
            }
        ) {
            return .red
        }

        if viewModel.results.contains(
            where: {
                $0.verdict == .suspicious
            }
        ) {
            return .orange
        }

        if !viewModel.results.isEmpty {
            return .green
        }

        return .secondary
    }

    private func color(
        for verdict:
            URLReputationVerdict
    ) -> Color {
        switch verdict {
        case .safe:
            return .green

        case .unknown:
            return .blue

        case .suspicious:
            return .orange

        case .malicious:
            return .red
        }
    }

    private func systemImage(
        for verdict:
            URLReputationVerdict
    ) -> String {
        switch verdict {
        case .safe:
            return "checkmark.shield.fill"

        case .unknown:
            return "questionmark.diamond.fill"

        case .suspicious:
            return "exclamationmark.shield.fill"

        case .malicious:
            return "xmark.shield.fill"
        }
    }
}

#Preview {
    ReputationLookupCard(
        analyzedValue:
            "Verify at https://secure-paypa1-login.com/verify",
        checkType: .message
    )
    .padding()
}
