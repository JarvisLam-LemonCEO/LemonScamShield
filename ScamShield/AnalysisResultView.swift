import SwiftUI
import UIKit

struct AnalysisResultView: View {
    let result: ScamAnalysisResult
    let wasSavedToHistory: Bool
    
    @Environment(\.dismiss)
    private var dismiss

    @State private var copiedMessage = ""
    @State private var isShowingCopiedConfirmation = false
    @State private var isShowingSafetyCenter = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {
                    savedNotice
                    analyzedItemSection

                    BrandDetectionCard(
                        analyzedValue: result.analyzedValue,
                        checkType: result.checkType
                    )

                    ScamPatternCard(
                        analyzedValue: result.analyzedValue,
                        checkType: result.checkType
                    )

                    ScamExplanationCard(
                        analyzedValue: result.analyzedValue,
                        checkType: result.checkType
                    )

                    RiskScoreBreakdownCard(
                        analyzedValue: result.analyzedValue,
                        checkType: result.checkType
                    )
                    
                    ReputationLookupCard(
                        analyzedValue: result.analyzedValue,
                        checkType: result.checkType
                    )


                    riskSummary
                    warningSignsSection
                    recommendationSection
                    SecurityReportButton(
                        result: result
                    )
                    actionsSection
                    disclaimerSection
                    
                }
                .padding()
            }
            .navigationTitle("Analysis Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Copied",
                isPresented:
                    $isShowingCopiedConfirmation
            ) {
                Button(
                    "OK",
                    role: .cancel
                ) {}
            } message: {
                Text(copiedMessage)
            }
            .sheet(
                isPresented:
                    $isShowingSafetyCenter
            ) {
                SafetyCenterSheet()
            }
        }
    }

    private var savedNotice: some View {
        HStack(spacing: 10) {
            Image(
                systemName:
                    wasSavedToHistory
                    ? "checkmark.circle.fill"
                    : "clock.badge.xmark"
            )
            .foregroundStyle(
                wasSavedToHistory
                ? Color.green
                : Color.secondary
            )

            Text(
                wasSavedToHistory
                ? "This scan was added to your history."
                : "History saving is turned off. This scan was not saved."
            )
            .font(.subheadline)

            Spacer()
        }
        .padding()
        .background(
            wasSavedToHistory
            ? Color.green.opacity(0.08)
            : Color.secondary.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
    }

    private var analyzedItemSection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Label(
                "Analyzed \(result.checkType.rawValue)",
                systemImage:
                    result.checkType.systemImage
            )
            .font(.headline)

            Text(result.analyzedValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(8)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            Button {
                copyAnalyzedText()
            } label: {
                Label(
                    "Copy Analyzed Text",
                    systemImage: "doc.on.doc"
                )
                .font(.subheadline)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            Color.secondary.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }

    private var riskSummary: some View {
        VStack(spacing: 14) {
            Image(
                systemName:
                    result.riskLevel.iconName
            )
            .font(.system(size: 54))
            .foregroundStyle(
                result.riskLevel.color
            )

            Text(result.riskLevel.title)
                .font(.title2)
                .fontWeight(.bold)

            Text("\(result.score)% risk score")
                .font(.headline)
                .foregroundStyle(
                    result.riskLevel.color
                )

            Text(result.summary)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            result.riskLevel.color.opacity(0.1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private var warningSignsSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Label(
                "Analysis details",
                systemImage:
                    "exclamationmark.triangle"
            )
            .font(.headline)

            if result.warningSigns.isEmpty {
                Text(
                    "No common scam warning signs were detected."
                )
                .foregroundStyle(.secondary)
            } else {
                ForEach(
                    result.warningSigns,
                    id: \.self
                ) { warningSign in
                    HStack(
                        alignment: .top,
                        spacing: 10
                    ) {
                        Image(
                            systemName:
                                warningIconName
                        )
                        .foregroundStyle(
                            warningIconColor
                        )

                        Text(warningSign)

                        Spacer()
                    }
                }
            }
        }
    }

    private var recommendationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Label(
                "Recommended action",
                systemImage: "checklist"
            )
            .font(.headline)

            Text(result.recommendation)
                .font(.body)

            contextSafetyTip
        }
        .padding()
        .background(
            Color.blue.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }

    private var contextSafetyTip: some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(
                systemName:
                    contextSafetyIcon
            )
            .foregroundStyle(.blue)

            Text(contextSafetyText)
                .font(.subheadline)

            Spacer()
        }
        .padding(.top, 4)
    }

    private var actionsSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Label(
                "Actions",
                systemImage:
                    "square.and.arrow.up"
            )
            .font(.headline)

            Button {
                copyFullResult()
            } label: {
                Label(
                    "Copy Full Result",
                    systemImage:
                        "doc.on.doc.fill"
                )
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(.borderedProminent)

            ShareLink(
                item: shareText,
                subject: Text(
                    "ScamShield Analysis"
                ),
                message: Text(
                    "Here is a ScamShield risk analysis."
                )
            ) {
                Label(
                    "Share Result",
                    systemImage:
                        "square.and.arrow.up"
                )
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(.bordered)

            Button {
                isShowingSafetyCenter = true
            } label: {
                Label(
                    "Open Safety Center",
                    systemImage:
                        "cross.case.fill"
                )
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            Color.secondary.opacity(0.06)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var disclaimerSection: some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)

            Text(disclaimerText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var shareText: String {
        ResultTextBuilder.fullResult(
            from: result
        )
    }

    private var warningIconName: String {
        result.riskLevel == .low
            ? "info.circle.fill"
            : "exclamationmark.circle.fill"
    }

    private var warningIconColor: Color {
        result.riskLevel == .low
            ? .blue
            : .orange
    }

    private var contextSafetyIcon: String {
        switch result.checkType {
        case .message:
            return "bubble.left.and.exclamationmark.bubble.right"

        case .website:
            return "globe.badge.chevron.backward"

        case .phone:
            return "phone.down.fill"
        }
    }

    private var contextSafetyText: String {
        switch result.checkType {
        case .message:
            return """
            Preserve the original message before blocking or reporting the sender.
            """

        case .website:
            return """
            Visit the organization by opening its official app or typing its trusted address yourself.
            """

        case .phone:
            return """
            Hang up and call the organization using a phone number from an official source.
            """
        }
    }

    private var disclaimerText: String {
        switch result.checkType {
        case .message:
            return """
            ScamShield provides guidance only. A low-risk result does not guarantee that a message is legitimate.
            """

        case .website:
            return """
            This check examines the website address but does not open or inspect the website's contents.
            """

        case .phone:
            return """
            This check examines the phone-number format but does not search a live scam-number database.
            """
        }
    }

    private func copyAnalyzedText() {
        UIPasteboard.general.string =
            result.analyzedValue

        copiedMessage =
            "The analyzed \(result.checkType.rawValue.lowercased()) was copied."

        isShowingCopiedConfirmation = true
    }

    private func copyFullResult() {
        UIPasteboard.general.string =
            shareText

        copiedMessage =
            "The complete ScamShield analysis was copied."

        isShowingCopiedConfirmation = true
    }
}

private struct SafetyCenterSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            SafetyCenterView()
                .toolbar {
                    ToolbarItem(
                        placement:
                            .topBarTrailing
                    ) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    AnalysisResultView(
        result: ScamAnalysisResult(
            checkType: .website,
            analyzedValue:
                "https://secure-paypa1-login.com/verify",
            score: 85,
            riskLevel: .high,
            summary:
                "This website contains several warning signs commonly associated with scams.",
            warningSigns: [
                "The domain may be imitating PayPal.",
                "The hostname contains several hyphens.",
                "The path requests account verification."
            ],
            recommendation:
                "Do not open the website or enter any information."
        ),
        wasSavedToHistory: true
    )
}
