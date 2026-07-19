import Foundation

struct SmartInputDetectionResult {
    let checkType: ScamCheckType
    let cleanedValue: String
    let explanation: String
}

struct SmartInputDetector {
    func detect(
        _ value: String
    ) -> SmartInputDetectionResult {
        let cleanedValue = value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if isLikelyPhoneNumber(
            cleanedValue
        ) {
            return SmartInputDetectionResult(
                checkType: .phone,
                cleanedValue: cleanedValue,
                explanation:
                    "ScamShield detected a phone-number format."
            )
        }

        if isLikelyWebsite(
            cleanedValue
        ) {
            return SmartInputDetectionResult(
                checkType: .website,
                cleanedValue: cleanedValue,
                explanation:
                    "ScamShield detected a website address."
            )
        }

        return SmartInputDetectionResult(
            checkType: .message,
            cleanedValue: cleanedValue,
            explanation:
                "ScamShield detected message or email text."
        )
    }

    private func isLikelyPhoneNumber(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        guard value.rangeOfCharacter(
            from: .newlines
        ) == nil else {
            return false
        }

        let lowercasedValue =
            value.lowercased()

        guard !lowercasedValue.contains(
            "http://"
        ),
        !lowercasedValue.contains(
            "https://"
        ),
        !lowercasedValue.contains(
            "www."
        ) else {
            return false
        }

        let digits =
            value.filter(\.isNumber)

        guard digits.count >= 7,
              digits.count <= 15
        else {
            return false
        }

        let permittedCharacters =
            CharacterSet(
                charactersIn:
                    "0123456789+()- ."
            )

        let containsOnlyPhoneCharacters =
            value.unicodeScalars.allSatisfy {
                scalar in

                permittedCharacters.contains(
                    scalar
                )
            }

        return containsOnlyPhoneCharacters
    }

    private func isLikelyWebsite(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        guard value.rangeOfCharacter(
            from: .newlines
        ) == nil else {
            return false
        }

        let lowercasedValue =
            value.lowercased()

        if lowercasedValue.hasPrefix(
            "http://"
        )
            || lowercasedValue.hasPrefix(
                "https://"
            )
            || lowercasedValue.hasPrefix(
                "www."
            ) {
            return true
        }

        guard !value.contains(" ") else {
            return false
        }

        let domainPattern = #"""
        (?ix)
        ^
        (?:
            [a-z0-9]
            (?:[a-z0-9-]{0,61}[a-z0-9])?
            \.
        )+
        [a-z]{2,24}
        (?:
            :\d{1,5}
        )?
        (?:
            /[^\s]*
        )?
        $
        """#

        return value.range(
            of: domainPattern,
            options: .regularExpression
        ) != nil
    }
}
