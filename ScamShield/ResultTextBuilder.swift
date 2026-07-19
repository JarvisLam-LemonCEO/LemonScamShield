import Foundation

struct ResultTextBuilder {
    static func fullResult(
        from result: ScamAnalysisResult
    ) -> String {
        buildText(
            checkType: result.checkType,
            analyzedValue: result.analyzedValue,
            score: result.score,
            riskLevel: result.riskLevel,
            summary: result.summary,
            warningSigns: result.warningSigns,
            recommendation: result.recommendation,
            date: nil
        )
    }

    static func fullResult(
        from item: ScanHistoryItem
    ) -> String {
        buildText(
            checkType: item.checkType,
            analyzedValue: item.analyzedValue,
            score: item.score,
            riskLevel: item.riskLevel,
            summary: item.summary,
            warningSigns: item.warningSigns,
            recommendation: item.recommendation,
            date: item.createdAt
        )
    }

    private static func buildText(
        checkType: ScamCheckType,
        analyzedValue: String,
        score: Int,
        riskLevel: ScamRiskLevel,
        summary: String,
        warningSigns: [String],
        recommendation: String,
        date: Date?
    ) -> String {
        var sections: [String] = []

        sections.append("ScamShield Analysis")

        if let date {
            sections.append(
                "Scanned: \(formattedDate(date))"
            )
        }

        sections.append(
            """
            Type: \(checkType.rawValue)
            Risk level: \(riskLevel.title)
            Risk score: \(score)%
            """
        )

        sections.append(
            """
            Summary

            \(summary)
            """
        )

        sections.append(
            """
            Analyzed \(checkType.rawValue)

            \(analyzedValue)
            """
        )

        if warningSigns.isEmpty {
            sections.append(
                """
                Analysis Details

                No common scam warning signs were detected.
                """
            )
        } else {
            let warnings = warningSigns
                .map { "• \($0)" }
                .joined(separator: "\n")

            sections.append(
                """
                Analysis Details

                \(warnings)
                """
            )
        }

        sections.append(
            """
            Recommended Action

            \(recommendation)
            """
        )

        sections.append(
            """
            Important

            ScamShield provides general guidance only. A low-risk result does not guarantee that the item is legitimate.
            """
        )

        return sections.joined(
            separator: "\n\n"
        )
    }

    private static func formattedDate(
        _ date: Date
    ) -> String {
        date.formatted(
            date: .long,
            time: .shortened
        )
    }
}
