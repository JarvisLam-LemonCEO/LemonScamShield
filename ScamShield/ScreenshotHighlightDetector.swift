import Foundation
import CoreGraphics

struct ScreenshotHighlightDetector {
    func highlights(
        from regions: [RecognizedTextRegion]
    ) -> [ScreenshotHighlight] {
        var highlights: [ScreenshotHighlight] = []

        for region in regions {
            let normalizedText =
                region.text.lowercased()

            if containsAny(
                urgencyPhrases,
                in: normalizedText
            ) {
                highlights.append(
                    makeHighlight(
                        region,
                        category: .urgency
                    )
                )
            }

            if containsAny(
                credentialPhrases,
                in: normalizedText
            ) {
                highlights.append(
                    makeHighlight(
                        region,
                        category: .credentials
                    )
                )
            }

            if containsAny(
                paymentPhrases,
                in: normalizedText
            ) {
                highlights.append(
                    makeHighlight(
                        region,
                        category: .payment
                    )
                )
            }

            if containsAny(
                threatPhrases,
                in: normalizedText
            ) {
                highlights.append(
                    makeHighlight(
                        region,
                        category: .threat
                    )
                )
            }

            if containsAny(
                prizePhrases,
                in: normalizedText
            ) {
                highlights.append(
                    makeHighlight(
                        region,
                        category: .prize
                    )
                )
            }

            if containsAny(
                impersonationPhrases,
                in: normalizedText
            ) {
                highlights.append(
                    makeHighlight(
                        region,
                        category: .impersonation
                    )
                )
            }

            if containsLinkIndicator(
                in: normalizedText
            ) {
                highlights.append(
                    makeHighlight(
                        region,
                        category: .link
                    )
                )
            }
        }

        return removeDuplicates(
            highlights
        )
    }

    private let urgencyPhrases = [
        "urgent",
        "immediately",
        "act now",
        "final warning",
        "within 24 hours",
        "right away",
        "expires today",
        "do not delay"
    ]

    private let credentialPhrases = [
        "password",
        "verification code",
        "security code",
        "one-time code",
        "one time code",
        "otp",
        "login details",
        "credit card number",
        "bank account",
        "social security",
        "confirm your identity"
    ]

    private let paymentPhrases = [
        "gift card",
        "bitcoin",
        "cryptocurrency",
        "wire transfer",
        "western union",
        "send money",
        "payment required",
        "pay a fee",
        "cash app",
        "zelle"
    ]

    private let threatPhrases = [
        "account suspended",
        "account locked",
        "account closed",
        "legal action",
        "arrest warrant",
        "you will be arrested",
        "service disconnected",
        "service will be disconnected",
        "access will be blocked"
    ]

    private let prizePhrases = [
        "you won",
        "winner",
        "claim your prize",
        "lottery",
        "cash prize",
        "free reward",
        "selected to receive"
    ]

    private let impersonationPhrases = [
        "apple support",
        "microsoft support",
        "amazon support",
        "paypal support",
        "your bank",
        "fraud department",
        "irs",
        "social security administration",
        "government agency"
    ]

    private func containsAny(
        _ phrases: [String],
        in text: String
    ) -> Bool {
        phrases.contains {
            text.contains($0)
        }
    }

    private func containsLinkIndicator(
        in text: String
    ) -> Bool {
        let indicators = [
            "http://",
            "https://",
            "www.",
            "bit.ly",
            "tinyurl",
            ".com/",
            ".net/",
            ".org/",
            ".xyz/",
            ".click/",
            "click here",
            "tap here"
        ]

        return containsAny(
            indicators,
            in: text
        )
    }

    private func makeHighlight(
        _ region: RecognizedTextRegion,
        category: ScreenshotHighlightCategory
    ) -> ScreenshotHighlight {
        ScreenshotHighlight(
            text: region.text,
            category: category,
            boundingBox: region.boundingBox
        )
    }

    private func removeDuplicates(
        _ highlights: [ScreenshotHighlight]
    ) -> [ScreenshotHighlight] {
        var seen = Set<String>()

        return highlights.filter {
            highlight in

            let box = highlight.boundingBox

            let key = [
                highlight.category.rawValue,
                highlight.text.lowercased(),
                String(format: "%.4f", box.minX),
                String(format: "%.4f", box.minY),
                String(format: "%.4f", box.width),
                String(format: "%.4f", box.height)
            ]
            .joined(separator: "|")

            return seen.insert(key).inserted
        }
    }
}
