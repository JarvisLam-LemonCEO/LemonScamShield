import Foundation
import SwiftData

@Model
final class ScanHistoryItem {
    var createdAt: Date
    var checkTypeRawValue: String
    var analyzedValue: String
    var score: Int
    var riskLevelRawValue: String
    var summary: String
    var warningSigns: [String]
    var recommendation: String

    init(
        createdAt: Date = Date(),
        checkType: ScamCheckType,
        analyzedValue: String,
        score: Int,
        riskLevel: ScamRiskLevel,
        summary: String,
        warningSigns: [String],
        recommendation: String
    ) {
        self.createdAt = createdAt
        self.checkTypeRawValue = checkType.rawValue
        self.analyzedValue = analyzedValue
        self.score = score
        self.riskLevelRawValue = riskLevel.storageValue
        self.summary = summary
        self.warningSigns = warningSigns
        self.recommendation = recommendation
    }

    convenience init(result: ScamAnalysisResult) {
        self.init(
            checkType: result.checkType,
            analyzedValue: result.analyzedValue,
            score: result.score,
            riskLevel: result.riskLevel,
            summary: result.summary,
            warningSigns: result.warningSigns,
            recommendation: result.recommendation
        )
    }

    var checkType: ScamCheckType {
        ScamCheckType(rawValue: checkTypeRawValue) ?? .message
    }

    var riskLevel: ScamRiskLevel {
        ScamRiskLevel(
            storageValue: riskLevelRawValue
        )
    }

    var analysisResult: ScamAnalysisResult {
        ScamAnalysisResult(
            checkType: checkType,
            analyzedValue: analyzedValue,
            score: score,
            riskLevel: riskLevel,
            summary: summary,
            warningSigns: warningSigns,
            recommendation: recommendation
        )
    }
}
