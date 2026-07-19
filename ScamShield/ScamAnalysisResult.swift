import Foundation

struct ScamAnalysisResult: Identifiable {
    let id = UUID()

    let checkType: ScamCheckType
    let analyzedValue: String
    let score: Int
    let riskLevel: ScamRiskLevel
    let summary: String
    let warningSigns: [String]
    let recommendation: String
}
