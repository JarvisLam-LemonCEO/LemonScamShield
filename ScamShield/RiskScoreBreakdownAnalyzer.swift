import Foundation

struct RiskScoreBreakdownAnalyzer {
    func analyze(
        _ value: String,
        as checkType: ScamCheckType
    ) -> RiskScoreBreakdown {
        let text = value.lowercased()

        var contributions: [RiskScoreContribution] = []

        if let patternContribution =
            scamPatternContribution(
                value,
                checkType: checkType
            ) {
            contributions.append(
                patternContribution
            )
        }

        if let urlContribution =
            suspiciousURLContribution(
                value,
                checkType: checkType
            ) {
            contributions.append(
                urlContribution
            )
        }

        if let contribution =
            credentialsContribution(text) {
            contributions.append(contribution)
        }

        if let contribution =
            paymentContribution(text) {
            contributions.append(contribution)
        }

        if let contribution =
            urgencyContribution(text) {
            contributions.append(contribution)
        }

        if let contribution =
            threatContribution(text) {
            contributions.append(contribution)
        }

        if let contribution =
            brandImpersonationContribution(
                value,
                normalizedText: text
            ) {
            contributions.append(contribution)
        }

        if let contribution =
            secrecyContribution(text) {
            contributions.append(contribution)
        }

        if let contribution =
            remoteAccessContribution(text) {
            contributions.append(contribution)
        }

        if checkType == .phone,
           let contribution =
            phoneContribution(value) {
            contributions.append(contribution)
        }

        let sortedContributions =
            contributions.sorted {
                $0.points > $1.points
            }

        let rawScore =
            sortedContributions.reduce(0) {
                partialResult,
                contribution in

                partialResult
                    + contribution.points
            }

        /*
         Scores can overlap because one phrase may
         trigger more than one category. Applying a
         soft cap keeps the final score readable.
         */
        let adjustedScore =
            adjustedTotalScore(
                from: rawScore
            )

        return RiskScoreBreakdown(
            totalScore: adjustedScore,
            rawScore: rawScore,
            contributions: sortedContributions
        )
    }

    private func scamPatternContribution(
        _ value: String,
        checkType: ScamCheckType
    ) -> RiskScoreContribution? {
        let analysis =
            ScamPatternDetector().analyze(
                value,
                as: checkType
            )

        guard let match =
            analysis.primaryMatch
        else {
            return nil
        }

        let points: Int

        switch match.confidence {
        case 0..<45:
            points = 6

        case 45..<65:
            points = 11

        case 65..<80:
            points = 15

        default:
            points = 20
        }

        return RiskScoreContribution(
            category: .scamPattern,
            points: points,
            maximumPoints: 20,
            explanation:
                "\(match.type.title) matched with \(match.confidence)% pattern confidence."
        )
    }

    private func suspiciousURLContribution(
        _ value: String,
        checkType: ScamCheckType
    ) -> RiskScoreContribution? {
        let containsURL =
            containsAny(
                [
                    "http://",
                    "https://",
                    "www."
                ],
                in: value.lowercased()
            )

        guard containsURL
                || checkType == .website
        else {
            return nil
        }

        let urlResult =
            URLRiskAnalyzer().analyze(value)

        guard urlResult.score > 0 else {
            return nil
        }

        let points =
            min(
                max(
                    Int(
                        round(
                            Double(urlResult.score)
                                * 0.25
                        )
                    ),
                    3
                ),
                25
            )

        return RiskScoreContribution(
            category: .suspiciousURL,
            points: points,
            maximumPoints: 25,
            explanation:
                urlExplanation(
                    score: urlResult.score
                )
        )
    }

    private func credentialsContribution(
        _ text: String
    ) -> RiskScoreContribution? {
        let criticalPhrases = [
            "password",
            "passcode",
            "verification code",
            "security code",
            "one-time code",
            "one time code",
            "otp",
            "login details",
            "pin number",
            "social security number"
        ]

        let generalPhrases = [
            "verify your identity",
            "confirm your identity",
            "account number",
            "personal information",
            "banking information",
            "date of birth"
        ]

        let criticalMatches =
            matchCount(
                criticalPhrases,
                in: text
            )

        let generalMatches =
            matchCount(
                generalPhrases,
                in: text
            )

        guard criticalMatches > 0
                || generalMatches > 0
        else {
            return nil
        }

        let points =
            min(
                criticalMatches * 8
                    + generalMatches * 4,
                20
            )

        return RiskScoreContribution(
            category: .credentials,
            points: max(points, 6),
            maximumPoints: 20,
            explanation:
                "The content refers to credentials, verification codes, or personal identity information."
        )
    }

    private func paymentContribution(
        _ text: String
    ) -> RiskScoreContribution? {
        let highRiskMethods = [
            "gift card",
            "wire transfer",
            "western union",
            "moneygram",
            "bitcoin",
            "cryptocurrency",
            "crypto wallet",
            "cash app",
            "zelle"
        ]

        let generalPaymentPhrases = [
            "send money",
            "pay now",
            "payment required",
            "processing fee",
            "delivery fee",
            "customs fee",
            "release fee",
            "deposit now"
        ]

        let highRiskMatches =
            matchCount(
                highRiskMethods,
                in: text
            )

        let generalMatches =
            matchCount(
                generalPaymentPhrases,
                in: text
            )

        guard highRiskMatches > 0
                || generalMatches > 0
        else {
            return nil
        }

        let points =
            min(
                highRiskMatches * 8
                    + generalMatches * 4,
                18
            )

        let explanation: String

        if highRiskMatches > 0 {
            explanation =
                "It requests money through a payment method that may be difficult to reverse."
        } else {
            explanation =
                "It contains an unexpected fee, deposit, or immediate payment request."
        }

        return RiskScoreContribution(
            category: .payment,
            points: max(points, 5),
            maximumPoints: 18,
            explanation: explanation
        )
    }

    private func urgencyContribution(
        _ text: String
    ) -> RiskScoreContribution? {
        let phrases = [
            "urgent",
            "immediately",
            "act now",
            "right away",
            "within 24 hours",
            "final warning",
            "limited time",
            "today only",
            "do not delay",
            "expires today"
        ]

        let matches =
            matchCount(
                phrases,
                in: text
            )

        guard matches > 0 else {
            return nil
        }

        return RiskScoreContribution(
            category: .urgency,
            points: min(
                4 + matches * 3,
                12
            ),
            maximumPoints: 12,
            explanation:
                "Urgent language pressures the recipient to act before carefully checking the request."
        )
    }

    private func threatContribution(
        _ text: String
    ) -> RiskScoreContribution? {
        let phrases = [
            "account suspended",
            "account locked",
            "account closed",
            "legal action",
            "arrest",
            "arrest warrant",
            "deportation",
            "penalty",
            "service terminated",
            "police",
            "lawsuit",
            "final notice"
        ]

        let matches =
            matchCount(
                phrases,
                in: text
            )

        guard matches > 0 else {
            return nil
        }

        return RiskScoreContribution(
            category: .threat,
            points: min(
                5 + matches * 3,
                12
            ),
            maximumPoints: 12,
            explanation:
                "The sender uses fear, legal consequences, or account restrictions to create pressure."
        )
    }

    private func brandImpersonationContribution(
        _ originalValue: String,
        normalizedText text: String
    ) -> RiskScoreContribution? {
        let brands: [
            (
                name: String,
                keywords: [String],
                officialDomains: [String]
            )
        ] = [
            (
                "Apple",
                ["apple", "icloud"],
                ["apple.com", "icloud.com"]
            ),
            (
                "Microsoft",
                ["microsoft", "outlook"],
                [
                    "microsoft.com",
                    "live.com",
                    "outlook.com"
                ]
            ),
            (
                "Amazon",
                ["amazon"],
                ["amazon.com"]
            ),
            (
                "PayPal",
                ["paypal"],
                ["paypal.com"]
            ),
            (
                "Netflix",
                ["netflix"],
                ["netflix.com"]
            ),
            (
                "USPS",
                ["usps", "postal service"],
                ["usps.com"]
            ),
            (
                "UPS",
                ["ups delivery", "ups package"],
                ["ups.com"]
            ),
            (
                "FedEx",
                ["fedex"],
                ["fedex.com"]
            ),
            (
                "DHL",
                ["dhl"],
                ["dhl.com"]
            ),
            (
                "Google",
                ["google", "gmail"],
                ["google.com", "gmail.com"]
            )
        ]

        guard let detectedBrand =
            brands.first(
                where: { brand in
                    brand.keywords.contains {
                        text.contains($0)
                    }
                }
            )
        else {
            return nil
        }

        guard let detectedHost =
            extractHost(from: originalValue)
        else {
            return RiskScoreContribution(
                category: .brandImpersonation,
                points: 4,
                maximumPoints: 12,
                explanation:
                    "The content references \(detectedBrand.name), but no official destination could be verified."
            )
        }

        let isOfficial =
            detectedBrand.officialDomains
                .contains {
                    detectedHost == $0
                    || detectedHost.hasSuffix(
                        "." + $0
                    )
                }

        guard !isOfficial else {
            return nil
        }

        return RiskScoreContribution(
            category: .brandImpersonation,
            points: 12,
            maximumPoints: 12,
            explanation:
                "The content references \(detectedBrand.name), but the detected host is \(detectedHost)."
        )
    }

    private func secrecyContribution(
        _ text: String
    ) -> RiskScoreContribution? {
        let phrases = [
            "keep this secret",
            "do not tell anyone",
            "don't tell anyone",
            "private between us",
            "confidential request",
            "do not contact",
            "tell nobody"
        ]

        guard containsAny(
            phrases,
            in: text
        ) else {
            return nil
        }

        return RiskScoreContribution(
            category: .secrecy,
            points: 8,
            maximumPoints: 8,
            explanation:
                "The sender asks for secrecy, which discourages independent verification."
        )
    }

    private func remoteAccessContribution(
        _ text: String
    ) -> RiskScoreContribution? {
        let phrases = [
            "remote access",
            "anydesk",
            "teamviewer",
            "remote desktop",
            "screen sharing",
            "install software",
            "give me control"
        ]

        let matches =
            matchCount(
                phrases,
                in: text
            )

        guard matches > 0 else {
            return nil
        }

        return RiskScoreContribution(
            category: .remoteAccess,
            points: min(
                8 + matches * 3,
                14
            ),
            maximumPoints: 14,
            explanation:
                "Remote-access software could allow another person to control the device or view private information."
        )
    }

    private func phoneContribution(
        _ value: String
    ) -> RiskScoreContribution? {
        let digits =
            value.filter(\.isNumber)

        guard !digits.isEmpty else {
            return nil
        }

        var points = 0
        var observations: [String] = []

        if digits.count < 7 {
            points += 5
            observations.append(
                "The number is unusually short."
            )
        }

        if digits.count > 15 {
            points += 5
            observations.append(
                "The number is unusually long."
            )
        }

        if value.contains("*")
            || value.contains("#") {
            points += 3
            observations.append(
                "It includes dialing-control characters."
            )
        }

        if value.lowercased()
            .contains("unknown") {
            points += 4
            observations.append(
                "The caller is described as unknown."
            )
        }

        guard points > 0 else {
            return nil
        }

        return RiskScoreContribution(
            category: .phoneRisk,
            points: min(points, 10),
            maximumPoints: 10,
            explanation:
                observations.joined(
                    separator: " "
                )
        )
    }

    private func adjustedTotalScore(
        from rawScore: Int
    ) -> Int {
        guard rawScore > 0 else {
            return 0
        }

        switch rawScore {
        case 0...45:
            return rawScore

        case 46...75:
            return 45
                + Int(
                    Double(rawScore - 45)
                        * 0.8
                )

        default:
            return min(
                69
                    + Int(
                        Double(rawScore - 75)
                            * 0.45
                    ),
                100
            )
        }
    }

    private func urlExplanation(
        score: Int
    ) -> String {
        switch score {
        case 0..<20:
            return "The web address has a small number of characteristics that should be verified."

        case 20..<45:
            return "The web address has multiple suspicious formatting or domain characteristics."

        default:
            return "The web address has several characteristics commonly associated with phishing or impersonation."
        }
    }

    private func extractHost(
        from value: String
    ) -> String? {
        if let directURL = URL(
            string: value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        ),
           let host = directURL.host {
            return normalizedHost(host)
        }

        let pattern =
            #"(?i)\b(?:https?://|www\.)[^\s<>"']+"#

        guard let expression =
            try? NSRegularExpression(
                pattern: pattern
            )
        else {
            return nil
        }

        let range = NSRange(
            value.startIndex..<value.endIndex,
            in: value
        )

        guard let match =
            expression.firstMatch(
                in: value,
                range: range
            ),
            let matchRange =
                Range(
                    match.range,
                    in: value
                )
        else {
            return nil
        }

        var detectedValue =
            String(value[matchRange])

        if detectedValue.hasPrefix("www.") {
            detectedValue =
                "https://" + detectedValue
        }

        while let last =
            detectedValue.last,
            ".,!?;:)".contains(last) {
            detectedValue.removeLast()
        }

        guard let url =
            URL(string: detectedValue),
            let host = url.host
        else {
            return nil
        }

        return normalizedHost(host)
    }

    private func normalizedHost(
        _ host: String
    ) -> String {
        var value = host.lowercased()

        if value.hasPrefix("www.") {
            value.removeFirst(4)
        }

        return value
    }

    private func matchCount(
        _ phrases: [String],
        in text: String
    ) -> Int {
        phrases.reduce(0) {
            partialResult,
            phrase in

            partialResult
                + (text.contains(phrase) ? 1 : 0)
        }
    }

    private func containsAny(
        _ phrases: [String],
        in text: String
    ) -> Bool {
        phrases.contains {
            text.contains($0)
        }
    }
}
