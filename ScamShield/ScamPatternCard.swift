import SwiftUI

struct ScamPatternCard: View {
    let analyzedValue: String
    let checkType: ScamCheckType

    private var analysis:
        ScamPatternAnalysis {

        ScamPatternDetector().analyze(
            analyzedValue,
            as: checkType
        )
    }

    var body: some View {
        if let primary =
            analysis.primaryMatch {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                Label(
                    "Scam pattern detection",
                    systemImage:
                        "point.3.connected.trianglepath.dotted"
                )
                .font(.headline)

                primaryPatternSection(
                    primary
                )

                confidenceSection(
                    primary
                )

                evidenceSection(
                    primary
                )

                if !analysis
                    .additionalMatches
                    .isEmpty {
                    additionalPatternsSection
                }

                limitationNotice
            }
            .padding()
            .background(
                confidenceColor(
                    primary.confidence
                )
                .opacity(0.09)
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
                    confidenceColor(
                        primary.confidence
                    )
                    .opacity(0.25),
                    lineWidth: 1
                )
            }
        }
    }

    private func primaryPatternSection(
        _ match: ScamPatternMatch
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 14
        ) {
            Image(
                systemName:
                    match.type.systemImage
            )
            .font(.title)
            .foregroundStyle(
                confidenceColor(
                    match.confidence
                )
            )
            .frame(
                width: 48,
                height: 48
            )
            .background(
                confidenceColor(
                    match.confidence
                )
                .opacity(0.12)
            )
            .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text("Detected pattern")
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Text(match.type.title)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(match.type.summary)
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Spacer()
        }
    }

    private func confidenceSection(
        _ match: ScamPatternMatch
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            HStack {
                Text("Pattern confidence")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(
                    "\(match.confidence)%"
                )
                .font(.headline)
                .foregroundStyle(
                    confidenceColor(
                        match.confidence
                    )
                )
            }

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
                            confidenceColor(
                                match.confidence
                            )
                        )
                        .frame(
                            width:
                                geometry
                                    .size
                                    .width
                                * CGFloat(
                                    match.confidence
                                )
                                / 100
                        )
                }
            }
            .frame(height: 9)
        }
    }

    private func evidenceSection(
        _ match: ScamPatternMatch
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 11
        ) {
            Text("Evidence")
                .font(.headline)

            ForEach(
                match.evidence
            ) { evidence in
                HStack(
                    alignment: .top,
                    spacing: 10
                ) {
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        confidenceColor(
                            match.confidence
                        )
                    )

                    Text(evidence.title)
                        .font(.subheadline)

                    Spacer()
                }
            }
        }
    }

    private var additionalPatternsSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Divider()

            Text("Other possible patterns")
                .font(.headline)

            ForEach(
                analysis.additionalMatches
            ) { match in
                HStack(spacing: 10) {
                    Image(
                        systemName:
                            match.type.systemImage
                    )
                    .foregroundStyle(.orange)

                    Text(match.type.title)
                        .font(.subheadline)

                    Spacer()

                    Text(
                        "\(match.confidence)%"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
    }

    private var limitationNotice:
        some View {

        HStack(
            alignment: .top,
            spacing: 9
        ) {
            Image(
                systemName: "info.circle"
            )
            .foregroundStyle(.secondary)

            Text(
                "Pattern detection is based on local language and URL rules. It is not proof that the content is fraudulent."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private func confidenceColor(
        _ confidence: Int
    ) -> Color {
        switch confidence {
        case 0..<45:
            return .blue

        case 45..<75:
            return .orange

        default:
            return .red
        }
    }
}

#Preview {
    ScamPatternCard(
        analyzedValue:
            """
            URGENT: Your bank account has been suspended. Verify your password and security code immediately at https://secure-bank-login.xyz.
            """,
        checkType: .message
    )
    .padding()
}
