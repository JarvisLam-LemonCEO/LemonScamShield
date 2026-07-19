import SwiftUI
import SwiftData
import UIKit

struct HistoryDetailView: View {
    let item: ScanHistoryItem

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @State private var isShowingDeleteConfirmation = false
    @State private var deletionErrorMessage: String?
    @State private var isShowingDeletionError = false

    @State private var copiedMessage = ""
    @State private var isShowingCopiedConfirmation = false
    @State private var isShowingSafetyCenter = false

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                dateSection
                analyzedItemSection

                BrandDetectionCard(
                    analyzedValue: item.analyzedValue,
                    checkType: item.checkType
                )

                ScamPatternCard(
                    analyzedValue: item.analyzedValue,
                    checkType: item.checkType
                )

                ScamExplanationCard(
                    analyzedValue: item.analyzedValue,
                    checkType: item.checkType
                )

                RiskScoreBreakdownCard(
                    analyzedValue: item.analyzedValue,
                    checkType: item.checkType
                )

                ReputationLookupCard(
                    analyzedValue: item.analyzedValue,
                    checkType: item.checkType
                )

                riskSummary
                warningSignsSection
                recommendationSection
                SecurityReportButton(
                    result: item.analysisResult,
                    createdAt: item.createdAt
                )
                actionsSection
                disclaimerSection
            }
            .padding()
        }
        .navigationTitle("Scan Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button(
                    role: .destructive
                ) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete scan")
            }
        }
        .confirmationDialog(
            "Delete this scan?",
            isPresented:
                $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Delete Scan",
                role: .destructive
            ) {
                deleteItem()
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}
        } message: {
            Text(
                "This action cannot be undone."
            )
        }
        .alert(
            "Scan Could Not Be Deleted",
            isPresented:
                $isShowingDeletionError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                deletionErrorMessage
                ?? "An unknown storage error occurred."
            )
        }
        .alert(
            "Copied",
            isPresented:
                $isShowingCopiedConfirmation
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(copiedMessage)
        }
        .sheet(
            isPresented:
                $isShowingSafetyCenter
        ) {
            HistorySafetyCenterSheet()
        }
    }

    private var dateSection: some View {
        Label {
            Text(
                item.createdAt,
                format: .dateTime
                    .weekday(.wide)
                    .month(.wide)
                    .day()
                    .year()
                    .hour()
                    .minute()
            )
        } icon: {
            Image(systemName: "calendar")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var analyzedItemSection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Label(
                "Analyzed \(item.checkType.rawValue)",
                systemImage:
                    item.checkType.systemImage
            )
            .font(.headline)

            Text(item.analyzedValue)
                .font(.body)
                .textSelection(.enabled)
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
                    item.riskLevel.iconName
            )
            .font(.system(size: 54))
            .foregroundStyle(
                item.riskLevel.color
            )

            Text(item.riskLevel.title)
                .font(.title2)
                .fontWeight(.bold)

            Text("\(item.score)% risk score")
                .font(.headline)
                .foregroundStyle(
                    item.riskLevel.color
                )

            Text(item.summary)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            item.riskLevel.color.opacity(0.1)
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

            if item.warningSigns.isEmpty {
                Text(
                    "No common scam warning signs were detected."
                )
                .foregroundStyle(.secondary)
            } else {
                ForEach(
                    item.warningSigns,
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

            Text(item.recommendation)
                .font(.body)

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
        }
        .padding()
        .background(
            Color.blue.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
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
                    "Here is a saved ScamShield risk analysis."
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
            from: item
        )
    }

    private var warningIconName: String {
        item.riskLevel == .low
            ? "info.circle.fill"
            : "exclamationmark.circle.fill"
    }

    private var warningIconColor: Color {
        item.riskLevel == .low
            ? .blue
            : .orange
    }

    private var contextSafetyIcon: String {
        switch item.checkType {
        case .message:
            return "bubble.left.and.exclamationmark.bubble.right"

        case .website:
            return "globe.badge.chevron.backward"

        case .phone:
            return "phone.down.fill"
        }
    }

    private var contextSafetyText: String {
        switch item.checkType {
        case .message:
            return """
            Preserve the original message before blocking or reporting the sender.
            """

        case .website:
            return """
            Visit the organization through its official app or by typing its trusted address yourself.
            """

        case .phone:
            return """
            Hang up and contact the organization using an independently verified phone number.
            """
        }
    }

    private var disclaimerText: String {
        switch item.checkType {
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
            item.analyzedValue

        copiedMessage =
            "The analyzed \(item.checkType.rawValue.lowercased()) was copied."

        isShowingCopiedConfirmation = true
    }

    private func copyFullResult() {
        UIPasteboard.general.string =
            shareText

        copiedMessage =
            "The complete ScamShield analysis was copied."

        isShowingCopiedConfirmation = true
    }

    private func deleteItem() {
        modelContext.delete(item)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()

            deletionErrorMessage =
                error.localizedDescription

            isShowingDeletionError = true
        }
    }
}

private struct HistorySafetyCenterSheet: View {
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
