import SwiftUI
import UIKit

struct AnnotatedScreenshotView: View {
    let image: UIImage
    let highlights: [ScreenshotHighlight]

    var body: some View {
        GeometryReader { geometry in
            let fittedRect =
                aspectFitRect(
                    imageSize: image.size,
                    containerSize:
                        geometry.size
                )

            ZStack(
                alignment: .topLeading
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width:
                            geometry.size.width,
                        height:
                            geometry.size.height
                    )

                ForEach(
                    Array(
                        highlights.enumerated()
                    ),
                    id: \.offset
                ) { _, highlight in
                    let highlightRect =
                        convertedRect(
                            highlight
                                .boundingBox,
                            inside: fittedRect
                        )

                    RoundedRectangle(
                        cornerRadius: 4
                    )
                    .fill(
                        color(
                            for:
                                highlight.category
                        )
                        .opacity(0.22)
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 4
                        )
                        .stroke(
                            color(
                                for:
                                    highlight
                                        .category
                            ),
                            lineWidth: 2
                        )
                    }
                    .frame(
                        width:
                            highlightRect.width,
                        height:
                            highlightRect.height
                    )
                    .position(
                        x:
                            highlightRect.midX,
                        y:
                            highlightRect.midY
                    )
                    .accessibilityLabel(
                        "\(highlight.category.title): \(highlight.text)"
                    )
                }
            }
        }
        .aspectRatio(
            image.size.width
            / max(image.size.height, 1),
            contentMode: .fit
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }

    private func aspectFitRect(
        imageSize: CGSize,
        containerSize: CGSize
    ) -> CGRect {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0
        else {
            return .zero
        }

        let scale = min(
            containerSize.width
            / imageSize.width,
            containerSize.height
            / imageSize.height
        )

        let fittedSize = CGSize(
            width:
                imageSize.width * scale,
            height:
                imageSize.height * scale
        )

        return CGRect(
            x:
                (
                    containerSize.width
                    - fittedSize.width
                ) / 2,
            y:
                (
                    containerSize.height
                    - fittedSize.height
                ) / 2,
            width:
                fittedSize.width,
            height:
                fittedSize.height
        )
    }

    private func convertedRect(
        _ normalizedBox: CGRect,
        inside fittedRect: CGRect
    ) -> CGRect {
        /*
         Vision's origin is lower-left.
         SwiftUI's origin is upper-left.
         */
        let x =
            fittedRect.minX
            + normalizedBox.minX
            * fittedRect.width

        let y =
            fittedRect.minY
            + (
                1
                - normalizedBox.maxY
            )
            * fittedRect.height

        let width =
            normalizedBox.width
            * fittedRect.width

        let height =
            normalizedBox.height
            * fittedRect.height

        return CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
    }

    private func color(
        for category:
            ScreenshotHighlightCategory
    ) -> Color {
        switch category {
        case .urgency:
            return .orange

        case .credentials:
            return .red

        case .payment:
            return .purple

        case .threat:
            return .red

        case .link:
            return .blue

        case .prize:
            return .yellow

        case .impersonation:
            return .indigo
        }
    }
}
