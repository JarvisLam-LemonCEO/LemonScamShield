import UIKit

enum SecurityReportPDFError:
    LocalizedError {

    case couldNotCreateDirectory
    case couldNotWriteFile

    var errorDescription: String? {
        switch self {
        case .couldNotCreateDirectory:
            return "ScamShield could not create the report folder."

        case .couldNotWriteFile:
            return "ScamShield could not save the PDF report."
        }
    }
}

struct SecurityReportPDFGenerator {

    func generate(
        result: ScamAnalysisResult,
        createdAt: Date = Date()
    ) throws -> URL {

        let reportData = makeReportData(
            result: result,
            createdAt: createdAt
        )

        let pageBounds = CGRect(
            x: 0,
            y: 0,
            width: 612,
            height: 792
        )

        let renderer = UIGraphicsPDFRenderer(
            bounds: pageBounds
        )

        let data = renderer.pdfData { context in
            let writer = PDFReportWriter(
                context: context,
                pageBounds: pageBounds
            )

            writer.beginPage()

            drawHeader(
                writer: writer,
                reportData: reportData
            )

            drawSummary(
                writer: writer,
                reportData: reportData
            )

            drawPattern(
                writer: writer,
                reportData: reportData
            )

            drawExplanation(
                writer: writer,
                reportData: reportData
            )

            drawRiskBreakdown(
                writer: writer,
                reportData: reportData
            )

            drawWarningSigns(
                writer: writer,
                reportData: reportData
            )

            drawRecommendations(
                writer: writer,
                reportData: reportData
            )

            drawAnalyzedContent(
                writer: writer,
                reportData: reportData
            )

            drawDisclaimer(
                writer: writer
            )

            writer.drawFooterOnCurrentPage()
        }

        let directory = try reportDirectory()

        let fileURL = directory.appendingPathComponent(
            fileName(
                for: reportData.createdAt
            )
        )

        do {
            try data.write(
                to: fileURL,
                options: .atomic
            )
        } catch {
            throw SecurityReportPDFError
                .couldNotWriteFile
        }

        return fileURL
    }

    private func makeReportData(
        result: ScamAnalysisResult,
        createdAt: Date
    ) -> SecurityReportData {

        let patternAnalysis =
            ScamPatternDetector().analyze(
                result.analyzedValue,
                as: result.checkType
            )

        let explanation =
            ScamExplanationGenerator().generate(
                for: result.analyzedValue,
                checkType: result.checkType
            )

        let breakdown =
            RiskScoreBreakdownAnalyzer().analyze(
                result.analyzedValue,
                as: result.checkType
            )

        return SecurityReportData(
            createdAt: createdAt,
            checkType: result.checkType,
            analyzedValue: result.analyzedValue,
            originalScore: result.score,
            riskLevel: result.riskLevel,
            summary: result.summary,
            warningSigns: result.warningSigns,
            originalRecommendation:
                result.recommendation,
            pattern:
                patternAnalysis.primaryMatch,
            explanation: explanation,
            breakdown: breakdown
        )
    }

    private func drawHeader(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawText(
            "ScamShield",
            font: .systemFont(
                ofSize: 27,
                weight: .bold
            ),
            color: .systemBlue,
            spacingAfter: 3
        )

        writer.drawText(
            "Security Analysis Report",
            font: .systemFont(
                ofSize: 17,
                weight: .semibold
            ),
            color: .label,
            spacingAfter: 7
        )

        writer.drawText(
            "Generated \(formattedDate(reportData.createdAt))",
            font: .systemFont(
                ofSize: 10,
                weight: .regular
            ),
            color: .secondaryLabel,
            spacingAfter: 14
        )

        writer.drawDivider()
    }

    private func drawSummary(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawSectionTitle(
            "Scan Summary"
        )

        let scoreText =
            "\(reportData.originalScore)%"

        let rows = [
            PDFKeyValueRow(
                key: "Scan type",
                value: reportData.checkType.rawValue
            ),
            PDFKeyValueRow(
                key: "Risk level",
                value: reportData.riskLevel.title
            ),
            PDFKeyValueRow(
                key: "Analysis score",
                value: scoreText
            ),
            PDFKeyValueRow(
                key: "Explainable score",
                value:
                    "\(reportData.breakdown.totalScore)/100"
            )
        ]

        writer.drawKeyValueRows(rows)

        writer.drawCallout(
            title: reportData.riskLevel.title,
            body: reportData.summary,
            color: reportData.riskLevel.uiColor
        )
    }

    private func drawPattern(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawSectionTitle(
            "Detected Scam Pattern"
        )

        guard let pattern =
            reportData.pattern
        else {
            writer.drawBodyText(
                "No supported scam pattern was identified with sufficient confidence."
            )
            return
        }

        writer.drawKeyValueRows([
            PDFKeyValueRow(
                key: "Pattern",
                value: pattern.type.title
            ),
            PDFKeyValueRow(
                key: "Confidence",
                value: "\(pattern.confidence)%"
            )
        ])

        writer.drawBodyText(
            pattern.type.summary
        )

        if !pattern.evidence.isEmpty {
            writer.drawSubheading(
                "Pattern evidence"
            )

            writer.drawBullets(
                pattern.evidence.map(\.title)
            )
        }
    }

    private func drawExplanation(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawSectionTitle(
            "ScamShield Explanation"
        )

        writer.drawText(
            reportData.explanation.headline,
            font: .systemFont(
                ofSize: 13,
                weight: .semibold
            ),
            color: .label,
            spacingAfter: 6
        )

        writer.drawBodyText(
            reportData.explanation.explanation
        )
    }

    private func drawRiskBreakdown(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawSectionTitle(
            "Risk Score Breakdown"
        )

        let contributions =
            reportData.breakdown
                .activeContributions

        guard !contributions.isEmpty else {
            writer.drawBodyText(
                "No strong local risk contributions were detected."
            )
            return
        }

        for contribution in contributions {
            writer.drawScoreContribution(
                title:
                    contribution.category.title,
                points: contribution.points,
                maximum:
                    contribution.maximumPoints,
                explanation:
                    contribution.explanation
            )
        }

        writer.drawText(
            "Raw contribution total: \(reportData.breakdown.rawScore). Adjusted explainable score: \(reportData.breakdown.totalScore)/100.",
            font: .systemFont(
                ofSize: 9,
                weight: .regular
            ),
            color: .secondaryLabel,
            spacingAfter: 6
        )
    }

    private func drawWarningSigns(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawSectionTitle(
            "Warning Signs"
        )

        guard !reportData.warningSigns
            .isEmpty
        else {
            writer.drawBodyText(
                "No warning signs were recorded by the primary analyzer."
            )
            return
        }

        writer.drawBullets(
            reportData.warningSigns
        )
    }

    private func drawRecommendations(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawSectionTitle(
            "Recommended Actions"
        )

        var recommendations =
            reportData.explanation
                .recommendations

        let original =
            reportData.originalRecommendation
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !original.isEmpty,
           !recommendations.contains(original) {
            recommendations.insert(
                original,
                at: 0
            )
        }

        if recommendations.isEmpty {
            recommendations = [
                "Verify the request using contact information obtained from an official source.",
                "Do not send money, passwords, or authentication codes until the request is independently confirmed."
            ]
        }

        writer.drawNumberedItems(
            recommendations
        )
    }

    private func drawAnalyzedContent(
        writer: PDFReportWriter,
        reportData: SecurityReportData
    ) {

        writer.drawSectionTitle(
            "Analyzed Content"
        )

        writer.drawQuotedText(
            reportData.analyzedValue
        )
    }

    private func drawDisclaimer(
        writer: PDFReportWriter
    ) {

        writer.drawSectionTitle(
            "Important Notice"
        )

        writer.drawBodyText(
            """
            This report is generated using local rules and heuristics. It is intended to identify warning signs and does not prove that content is safe, malicious, genuine, or fraudulent. Verify unexpected requests through official contact channels before taking action.
            """
        )

        writer.drawText(
            "The analyzed content was processed on the device when this report was created.",
            font: .systemFont(
                ofSize: 9,
                weight: .regular
            ),
            color: .secondaryLabel,
            spacingAfter: 4
        )
    }

    private func reportDirectory() throws -> URL {

        let fileManager =
            FileManager.default

        let temporaryDirectory =
            fileManager.temporaryDirectory

        let directory =
            temporaryDirectory
                .appendingPathComponent(
                    "ScamShieldReports",
                    isDirectory: true
                )

        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw SecurityReportPDFError
                .couldNotCreateDirectory
        }

        return directory
    }

    private func fileName(
        for date: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.locale =
            Locale(identifier: "en_US_POSIX")
        formatter.dateFormat =
            "yyyy-MM-dd_HH-mm-ss"

        return "ScamShield_Report_\(formatter.string(from: date)).pdf"
    }

    private func formattedDate(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        return formatter.string(
            from: date
        )
    }
}

private struct SecurityReportData {

    let createdAt: Date
    let checkType: ScamCheckType
    let analyzedValue: String
    let originalScore: Int
    let riskLevel: ScamRiskLevel
    let summary: String
    let warningSigns: [String]
    let originalRecommendation: String
    let pattern: ScamPatternMatch?
    let explanation: ScamExplanation
    let breakdown: RiskScoreBreakdown
}

private struct PDFKeyValueRow {

    let key: String
    let value: String
}

private final class PDFReportWriter {

    private let context:
        UIGraphicsPDFRendererContext

    private let pageBounds: CGRect

    private let margin: CGFloat = 42
    private let footerHeight: CGFloat = 30

    private var cursorY: CGFloat = 42
    private var pageNumber = 0

    private var contentWidth: CGFloat {
        pageBounds.width
            - margin * 2
    }

    private var maximumContentY: CGFloat {
        pageBounds.height
            - margin
            - footerHeight
    }

    init(
        context:
            UIGraphicsPDFRendererContext,
        pageBounds: CGRect
    ) {
        self.context = context
        self.pageBounds = pageBounds
    }

    func beginPage() {
        context.beginPage()
        pageNumber += 1
        cursorY = margin
    }

    func drawFooterOnCurrentPage() {

        let text =
            "ScamShield Security Report  |  Page \(pageNumber)"

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font:
                    UIFont.systemFont(
                        ofSize: 8
                    ),
                .foregroundColor:
                    UIColor.secondaryLabel
            ]

        let size = text.size(
            withAttributes: attributes
        )

        text.draw(
            at: CGPoint(
                x:
                    pageBounds.midX
                    - size.width / 2,
                y:
                    pageBounds.height
                    - margin
                    + 10
            ),
            withAttributes: attributes
        )
    }

    func drawSectionTitle(
        _ title: String
    ) {

        ensureSpace(42)

        cursorY += 10

        drawText(
            title,
            font: .systemFont(
                ofSize: 15,
                weight: .bold
            ),
            color: .label,
            spacingAfter: 7
        )

        let lineRect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: 1
        )

        UIColor.systemGray4.setFill()
        UIRectFill(lineRect)

        cursorY += 9
    }

    func drawSubheading(
        _ text: String
    ) {

        drawText(
            text,
            font: .systemFont(
                ofSize: 11,
                weight: .semibold
            ),
            color: .label,
            spacingAfter: 5
        )
    }

    func drawBodyText(
        _ text: String
    ) {

        drawText(
            text,
            font: .systemFont(
                ofSize: 10.5,
                weight: .regular
            ),
            color: .label,
            lineSpacing: 3,
            spacingAfter: 9
        )
    }

    func drawText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        lineSpacing: CGFloat = 2,
        spacingAfter: CGFloat = 4
    ) {

        let cleanText =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanText.isEmpty else {
            return
        }

        let paragraph =
            NSMutableParagraphStyle()

        paragraph.lineSpacing =
            lineSpacing

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]

        let height = textHeight(
            cleanText,
            width: contentWidth,
            attributes: attributes
        )

        ensureSpace(height + spacingAfter)

        let rect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: height
        )

        cleanText.draw(
            in: rect,
            withAttributes: attributes
        )

        cursorY += height
            + spacingAfter
    }

    func drawDivider() {

        ensureSpace(12)

        let rect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: 1
        )

        UIColor.systemGray4.setFill()
        UIRectFill(rect)

        cursorY += 12
    }

    func drawKeyValueRows(
        _ rows: [PDFKeyValueRow]
    ) {

        let rowHeight: CGFloat = 23

        ensureSpace(
            CGFloat(rows.count)
                * rowHeight
                + 8
        )

        for row in rows {
            let keyRect = CGRect(
                x: margin,
                y: cursorY,
                width: contentWidth * 0.38,
                height: rowHeight
            )

            let valueRect = CGRect(
                x:
                    margin
                    + contentWidth * 0.4,
                y: cursorY,
                width:
                    contentWidth * 0.6,
                height: rowHeight
            )

            row.key.draw(
                in: keyRect,
                withAttributes: [
                    .font:
                        UIFont.systemFont(
                            ofSize: 10,
                            weight: .medium
                        ),
                    .foregroundColor:
                        UIColor.secondaryLabel
                ]
            )

            row.value.draw(
                in: valueRect,
                withAttributes: [
                    .font:
                        UIFont.systemFont(
                            ofSize: 10,
                            weight: .semibold
                        ),
                    .foregroundColor:
                        UIColor.label
                ]
            )

            cursorY += rowHeight
        }

        cursorY += 4
    }

    func drawCallout(
        title: String,
        body: String,
        color: UIColor
    ) {

        let bodyFont =
            UIFont.systemFont(
                ofSize: 10,
                weight: .regular
            )

        let bodyAttributes:
            [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor:
                    UIColor.label
            ]

        let bodyHeight =
            textHeight(
                body,
                width:
                    contentWidth - 28,
                attributes:
                    bodyAttributes
            )

        let totalHeight =
            bodyHeight + 48

        ensureSpace(totalHeight + 8)

        let rect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: totalHeight
        )

        let path = UIBezierPath(
            roundedRect: rect,
            cornerRadius: 10
        )

        color.withAlphaComponent(0.09)
            .setFill()

        path.fill()

        color.withAlphaComponent(0.35)
            .setStroke()

        path.lineWidth = 1
        path.stroke()

        title.draw(
            in: CGRect(
                x: rect.minX + 14,
                y: rect.minY + 11,
                width: rect.width - 28,
                height: 18
            ),
            withAttributes: [
                .font:
                    UIFont.systemFont(
                        ofSize: 12,
                        weight: .bold
                    ),
                .foregroundColor: color
            ]
        )

        body.draw(
            in: CGRect(
                x: rect.minX + 14,
                y: rect.minY + 31,
                width: rect.width - 28,
                height: bodyHeight
            ),
            withAttributes: bodyAttributes
        )

        cursorY += totalHeight + 8
    }

    func drawBullets(
        _ items: [String]
    ) {

        for item in items {
            drawListItem(
                prefix: "•",
                text: item
            )
        }
    }

    func drawNumberedItems(
        _ items: [String]
    ) {

        for (
            index,
            item
        ) in items.enumerated() {
            drawListItem(
                prefix: "\(index + 1).",
                text: item
            )
        }
    }

    func drawQuotedText(
        _ text: String
    ) {

        let font =
            UIFont.monospacedSystemFont(
                ofSize: 9.5,
                weight: .regular
            )

        let paragraph =
            NSMutableParagraphStyle()

        paragraph.lineSpacing = 3

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor:
                    UIColor.label,
                .paragraphStyle: paragraph
            ]

        let height =
            textHeight(
                text,
                width:
                    contentWidth - 28,
                attributes: attributes
            )

        let totalHeight =
            max(height + 28, 50)

        ensureSpace(totalHeight + 8)

        let rect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: totalHeight
        )

        let path = UIBezierPath(
            roundedRect: rect,
            cornerRadius: 9
        )

        UIColor.secondarySystemBackground
            .setFill()

        path.fill()

        text.draw(
            in: CGRect(
                x: rect.minX + 14,
                y: rect.minY + 14,
                width: rect.width - 28,
                height: height
            ),
            withAttributes: attributes
        )

        cursorY += totalHeight + 8
    }

    func drawScoreContribution(
        title: String,
        points: Int,
        maximum: Int,
        explanation: String
    ) {

        let estimatedHeight:
            CGFloat = 63

        ensureSpace(estimatedHeight)

        let titleText =
            "\(title)  +\(points)/\(maximum)"

        drawText(
            titleText,
            font: .systemFont(
                ofSize: 10.5,
                weight: .semibold
            ),
            color: .label,
            spacingAfter: 3
        )

        let barWidth =
            contentWidth

        let barRect = CGRect(
            x: margin,
            y: cursorY,
            width: barWidth,
            height: 6
        )

        let backgroundPath =
            UIBezierPath(
                roundedRect: barRect,
                cornerRadius: 3
            )

        UIColor.systemGray5.setFill()
        backgroundPath.fill()

        let percentage: CGFloat

        if maximum > 0 {
            percentage = CGFloat(points)
                / CGFloat(maximum)
        } else {
            percentage = 0
        }

        let fillRect = CGRect(
            x: barRect.minX,
            y: barRect.minY,
            width:
                barRect.width
                * min(
                    max(percentage, 0),
                    1
                ),
            height: barRect.height
        )

        let fillPath = UIBezierPath(
            roundedRect: fillRect,
            cornerRadius: 3
        )

        UIColor.systemOrange.setFill()
        fillPath.fill()

        cursorY += 11

        drawText(
            explanation,
            font: .systemFont(
                ofSize: 9,
                weight: .regular
            ),
            color: .secondaryLabel,
            lineSpacing: 2,
            spacingAfter: 8
        )
    }

    private func drawListItem(
        prefix: String,
        text: String
    ) {

        let font =
            UIFont.systemFont(
                ofSize: 10,
                weight: .regular
            )

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor:
                    UIColor.label
            ]

        let prefixWidth: CGFloat = 22

        let height = textHeight(
            text,
            width:
                contentWidth
                - prefixWidth,
            attributes: attributes
        )

        ensureSpace(height + 7)

        prefix.draw(
            in: CGRect(
                x: margin,
                y: cursorY,
                width: prefixWidth,
                height: height
            ),
            withAttributes: [
                .font:
                    UIFont.systemFont(
                        ofSize: 10,
                        weight: .semibold
                    ),
                .foregroundColor:
                    UIColor.systemBlue
            ]
        )

        text.draw(
            in: CGRect(
                x: margin + prefixWidth,
                y: cursorY,
                width:
                    contentWidth
                    - prefixWidth,
                height: height
            ),
            withAttributes: attributes
        )

        cursorY += height + 7
    }

    private func ensureSpace(
        _ requiredHeight: CGFloat
    ) {

        guard cursorY
                + requiredHeight
                > maximumContentY
        else {
            return
        }

        drawFooterOnCurrentPage()
        beginPage()
    }

    private func textHeight(
        _ text: String,
        width: CGFloat,
        attributes:
            [NSAttributedString.Key: Any]
    ) -> CGFloat {

        let rect = text.boundingRect(
            with: CGSize(
                width: width,
                height:
                    CGFloat.greatestFiniteMagnitude
            ),
            options: [
                .usesLineFragmentOrigin,
                .usesFontLeading
            ],
            attributes: attributes,
            context: nil
        )

        return ceil(rect.height) + 1
    }
}

private extension ScamRiskLevel {

    var uiColor: UIColor {
        switch self {
        case .low:
            return .systemGreen

        case .suspicious:
            return .systemOrange

        case .high:
            return .systemRed
        }
    }
}
