import SwiftUI

struct ScamExplanationCard: View {
    let analyzedValue: String
    let checkType: ScamCheckType

    @State private var isShowingAllRecommendations = false

    private var explanation: ScamExplanation {
        ScamExplanationGenerator().generate(
            for: analyzedValue,
            checkType: checkType
        )
    }

    private var visibleRecommendations: [String] {
        if isShowingAllRecommendations {
            return explanation.recommendations
        }

        return Array(
            explanation.recommendations.prefix(3)
        )
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            header

            explanationSection

            confidenceSection

            recommendationSection

            limitationNotice
        }
        .padding()
        .background(
            Color.blue.opacity(0.07)
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
                Color.blue.opacity(0.18),
                lineWidth: 1
            )
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(
                systemName: "text.bubble.fill"
            )
            .font(.title2)
            .foregroundStyle(.blue)
            .frame(
                width: 44,
                height: 44
            )
            .background(
                Color.blue.opacity(0.12)
            )
            .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("ScamShield explanation")
                    .font(.headline)

                Text("Generated privately on this device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var explanationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text(explanation.headline)
                .font(.title3)
                .fontWeight(.bold)

            Text(explanation.explanation)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .textSelection(.enabled)
        }
    }

    private var confidenceSection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack {
                Text("Explanation confidence")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(explanation.confidence)%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        confidenceColor
                    )
            }

            GeometryReader { geometry in
                ZStack(
                    alignment: .leading
                ) {
                    Capsule()
                        .fill(
                            Color.secondary
                                .opacity(0.14)
                        )

                    Capsule()
                        .fill(confidenceColor)
                        .frame(
                            width:
                                geometry.size.width
                                * CGFloat(
                                    explanation.confidence
                                )
                                / 100
                        )
                }
            }
            .frame(height: 8)
        }
    }

    private var recommendationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Label(
                "Recommended actions",
                systemImage: "shield.checkered"
            )
            .font(.headline)

            ForEach(
                Array(
                    visibleRecommendations.enumerated()
                ),
                id: \.offset
            ) { _, recommendation in
                HStack(
                    alignment: .top,
                    spacing: 10
                ) {
                    Image(
                        systemName:
                            "checkmark.shield.fill"
                    )
                    .foregroundStyle(.blue)

                    Text(recommendation)
                        .font(.subheadline)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    Spacer()
                }
            }

            if explanation.recommendations.count > 3 {
                Button {
                    withAnimation {
                        isShowingAllRecommendations.toggle()
                    }
                } label: {
                    Label(
                        isShowingAllRecommendations
                            ? "Show fewer actions"
                            : "Show all actions",
                        systemImage:
                            isShowingAllRecommendations
                            ? "chevron.up"
                            : "chevron.down"
                    )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }
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
                "This explanation is generated from local detection rules. It can identify warning signs but cannot prove that content is safe or fraudulent."
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

    private var confidenceColor: Color {
        switch explanation.confidence {
        case 0..<40:
            return .green

        case 40..<70:
            return .orange

        default:
            return .red
        }
    }
}

#Preview {
    ScrollView {
        ScamExplanationCard(
            analyzedValue:
                """
                URGENT: Your bank account has been suspended because of an unauthorized transaction. Verify your password and security code immediately at https://secure-bank-login.xyz.
                """,
            checkType: .message
        )
        .padding()
    }
}
