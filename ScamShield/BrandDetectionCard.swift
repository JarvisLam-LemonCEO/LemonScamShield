import SwiftUI

struct BrandDetectionCard: View {
    let analyzedValue: String
    let checkType: ScamCheckType

    private var detection: BrandDetectionResult {
        BrandDetector().analyze(
            analyzedValue,
            as: checkType
        )
    }

    var body: some View {
        if let brand = detection.brand {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                Label(
                    "Company and domain check",
                    systemImage:
                        "building.2.crop.circle"
                )
                .font(.headline)

                informationRow(
                    title: "Claimed company",
                    value: brand.name,
                    systemImage: "building.2"
                )

                if detection.detectedHosts.isEmpty {
                    informationRow(
                        title: "Destination",
                        value:
                            "No website address was detected.",
                        systemImage:
                            "link.badge.plus"
                    )
                } else {
                    informationRow(
                        title: destinationTitle,
                        value:
                            detection.detectedHosts
                                .joined(
                                    separator: "\n"
                                ),
                        systemImage: "globe"
                    )
                }

                Divider()

                verdictSection(
                    brand: brand
                )

                officialDomainsSection(
                    brand: brand
                )
            }
            .padding()
            .background(
                statusColor.opacity(0.09)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    statusColor.opacity(0.25),
                    lineWidth: 1
                )
            }
        }
    }

    private func informationRow(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .textSelection(.enabled)
            }

            Spacer()
        }
    }

    private func verdictSection(
        brand: BrandProfile
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(
                systemName:
                    detection.status.systemImage
            )
            .foregroundStyle(statusColor)

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(detection.status.title)
                    .font(.headline)
                    .foregroundStyle(
                        statusColor
                    )

                Text(
                    verdictText(
                        for: brand
                    )
                )
                .font(.subheadline)
            }

            Spacer()
        }
    }

    private func officialDomainsSection(
        brand: BrandProfile
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            Text("Known official domains")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                brand.officialDomains
                    .joined(separator: ", ")
            )
            .font(.caption)
            .textSelection(.enabled)
        }
    }

    private var destinationTitle: String {
        detection.detectedHosts.count == 1
            ? "Actual destination"
            : "Actual destinations"
    }

    private var statusColor: Color {
        switch detection.status {
        case .official:
            return .green

        case .mismatch:
            return .red

        case .mixed:
            return .orange

        case .noLinkFound:
            return .blue

        case .noBrandDetected:
            return .secondary
        }
    }

    private func verdictText(
        for brand: BrandProfile
    ) -> String {
        switch detection.status {
        case .official:
            return """
            The detected destination matches one of \(brand.name)'s known official domains.
            """

        case .mismatch:
            return """
            The detected destination does not match \(brand.name)'s known official domains. Treat the link as suspicious.
            """

        case .mixed:
            return """
            The content contains both official and non-official destinations. Review every link carefully.
            """

        case .noLinkFound:
            return """
            The content mentions \(brand.name), but no website address was available for comparison.
            """

        case .noBrandDetected:
            return """
            No supported company or brand was detected.
            """
        }
    }
}

#Preview {
    BrandDetectionCard(
        analyzedValue:
            "PayPal: Verify your account at https://secure-paypa1-login.com/verify",
        checkType: .message
    )
    .padding()
}
