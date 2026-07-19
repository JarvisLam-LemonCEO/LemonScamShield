import Foundation

struct ScamExplanation {
    let headline: String
    let explanation: String
    let recommendations: [String]
    let detectedPattern: ScamPatternMatch?
    let confidence: Int
}
