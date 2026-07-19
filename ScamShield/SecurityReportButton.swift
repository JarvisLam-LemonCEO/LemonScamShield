import SwiftUI

private struct GeneratedReport:
    Identifiable {

    let id = UUID()
    let url: URL
}

struct SecurityReportButton: View {

    let result: ScamAnalysisResult
    var createdAt: Date = Date()

    @State private var generatedReport:
        GeneratedReport?

    @State private var isGenerating = false

    @State private var errorMessage: String?
    @State private var isShowingError = false

    var body: some View {
        Button {
            generateReport()
        } label: {
            Label(
                isGenerating
                    ? "Creating PDF..."
                    : "Create Security Report",
                systemImage:
                    isGenerating
                    ? "doc.badge.clock"
                    : "doc.richtext.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isGenerating)
        .sheet(
            item: $generatedReport
        ) { report in
            ActivityView(
                activityItems: [
                    report.url
                ]
            )
        }
        .alert(
            "Report Could Not Be Created",
            isPresented: $isShowingError
        ) {
            Button(
                "OK",
                role: .cancel
            ) {}
        } message: {
            Text(
                errorMessage
                    ?? "An unknown PDF error occurred."
            )
        }
    }

    private func generateReport() {
        guard !isGenerating else {
            return
        }

        isGenerating = true

        Task {
            do {
                let url =
                    try SecurityReportPDFGenerator()
                        .generate(
                            result: result,
                            createdAt: createdAt
                        )

                await MainActor.run {
                    generatedReport =
                        GeneratedReport(
                            url: url
                        )

                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage =
                        error.localizedDescription

                    isShowingError = true
                    isGenerating = false
                }
            }
        }
    }
}
