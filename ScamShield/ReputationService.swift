import Foundation

struct ReputationService {
    private let provider:
        any URLReputationProviding

    private let cache:
        ReputationCache

    init(
        provider:
            any URLReputationProviding =
                MockReputationProvider(),
        cache:
            ReputationCache =
                ReputationCache()
    ) {
        self.provider = provider
        self.cache = cache
    }

    func check(
        _ url: URL,
        ignoreCache: Bool = false
    ) async throws -> URLReputationResult {
        if !ignoreCache,
           let cachedResult =
            await cache.result(for: url) {
            return cachedResult
        }

        let result =
            try await provider
                .checkReputation(for: url)

        await cache.store(
            result,
            for: url
        )

        return result
    }
}

struct MockReputationProvider:
    URLReputationProviding {

    func checkReputation(
        for url: URL
    ) async throws -> URLReputationResult {
        try await Task.sleep(
            nanoseconds: 700_000_000
        )

        try Task.checkCancellation()

        guard let host =
            url.host?.lowercased()
        else {
            throw ReputationLookupError
                .invalidURL
        }

        if let result =
            maliciousResult(
                for: url,
                host: host
            ) {
            return result
        }

        if let result =
            suspiciousResult(
                for: url,
                host: host
            ) {
            return result
        }

        if isKnownOfficialHost(host) {
            return URLReputationResult(
                urlString:
                    url.absoluteString,
                host: host,
                verdict: .safe,
                confidence: 92,
                providerName:
                    "Mock Reputation Provider",
                findings: [
                    URLReputationFinding(
                        title:
                            "Recognized official domain",
                        detail:
                            "This hostname matches a domain included in the local demonstration allowlist."
                    )
                ]
            )
        }

        return URLReputationResult(
            urlString:
                url.absoluteString,
            host: host,
            verdict: .unknown,
            confidence: 50,
            providerName:
                "Mock Reputation Provider",
            findings: [
                URLReputationFinding(
                    title:
                        "No mock reputation record",
                    detail:
                        "The demonstration provider has no prior reports for this destination."
                )
            ]
        )
    }

    private func maliciousResult(
        for url: URL,
        host: String
    ) -> URLReputationResult? {
        let knownMaliciousHosts = [
            "secure-paypa1-login.com",
            "paypal-login-security.xyz",
            "secure-bank-login.cc",
            "account-verify-login.xyz",
            "apple-security-check.top",
            "bank-account-unlock.click"
        ]

        guard knownMaliciousHosts.contains(
            where: {
                host == $0
                    || host.hasSuffix(
                        ".\($0)"
                    )
            }
        ) else {
            return nil
        }

        return URLReputationResult(
            urlString:
                url.absoluteString,
            host: host,
            verdict: .malicious,
            confidence: 97,
            providerName:
                "Mock Reputation Provider",
            findings: [
                URLReputationFinding(
                    title:
                        "Previously reported phishing",
                    detail:
                        "This hostname is included in the local demonstration blocklist."
                ),
                URLReputationFinding(
                    title:
                        "Credential theft pattern",
                    detail:
                        "The address imitates an account login or verification page."
                )
            ],
            reportCount: 842,
            lastReportedAt:
                Calendar.current.date(
                    byAdding: .hour,
                    value: -8,
                    to: Date()
                )
        )
    }

    private func suspiciousResult(
        for url: URL,
        host: String
    ) -> URLReputationResult? {
        let shortenerDomains = [
            "bit.ly",
            "tinyurl.com",
            "t.co",
            "cutt.ly",
            "is.gd",
            "tiny.cc"
        ]

        if shortenerDomains.contains(
            where: {
                host == $0
                    || host.hasSuffix(
                        ".\($0)"
                    )
            }
        ) {
            return URLReputationResult(
                urlString:
                    url.absoluteString,
                host: host,
                verdict: .suspicious,
                confidence: 82,
                providerName:
                    "Mock Reputation Provider",
                findings: [
                    URLReputationFinding(
                        title:
                            "Hidden final destination",
                        detail:
                            "This shortening service prevents the final hostname from being seen before opening the link."
                    )
                ]
            )
        }

        let suspiciousEndings = [
            ".zip",
            ".click",
            ".top",
            ".xyz",
            ".cc",
            ".tk",
            ".gq"
        ]

        if suspiciousEndings.contains(
            where: {
                host.hasSuffix($0)
            }
        ) {
            return URLReputationResult(
                urlString:
                    url.absoluteString,
                host: host,
                verdict: .suspicious,
                confidence: 74,
                providerName:
                    "Mock Reputation Provider",
                findings: [
                    URLReputationFinding(
                        title:
                            "Higher-risk domain ending",
                        detail:
                            "This domain ending appears in the mock provider's higher-risk category."
                    )
                ],
                reportCount: 12,
                lastReportedAt:
                    Calendar.current.date(
                        byAdding: .day,
                        value: -3,
                        to: Date()
                    )
            )
        }

        return nil
    }

    private func isKnownOfficialHost(
        _ host: String
    ) -> Bool {
        let officialDomains = [
            "apple.com",
            "icloud.com",
            "amazon.com",
            "paypal.com",
            "microsoft.com",
            "google.com",
            "netflix.com",
            "facebook.com",
            "instagram.com",
            "chase.com",
            "bankofamerica.com",
            "wellsfargo.com",
            "usps.com",
            "ups.com",
            "fedex.com",
            "dhl.com"
        ]

        return officialDomains.contains {
            domain in

            host == domain
                || host.hasSuffix(
                    ".\(domain)"
                )
        }
    }
}
