import Foundation
import UIKit
import Vision
import ImageIO

enum ImageTextRecognizerError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image could not be opened."

        case .noTextFound:
            return "No readable text was found in the image."

        case .recognitionFailed:
            return "The image could not be processed for text recognition."
        }
    }
}

struct ImageTextRecognitionResult {
    let text: String
    let regions: [RecognizedTextRegion]
}

struct ImageTextRecognizer {
    static func recognizeText(
        from imageData: Data
    ) async throws -> String {
        let result =
            try await recognizeTextWithRegions(
                from: imageData
            )

        return result.text
    }

    static func recognizeTextWithRegions(
        from imageData: Data
    ) async throws -> ImageTextRecognitionResult {
        guard let image =
            UIImage(data: imageData)
        else {
            throw ImageTextRecognizerError
                .invalidImage
        }

        return try await recognizeTextWithRegions(
            from: image
        )
    }

    static func recognizeText(
        from image: UIImage
    ) async throws -> String {
        let result =
            try await recognizeTextWithRegions(
                from: image
            )

        return result.text
    }

    static func recognizeTextWithRegions(
        from image: UIImage
    ) async throws -> ImageTextRecognitionResult {
        try await Task.detached(
            priority: .userInitiated
        ) {
            try recognizeSynchronously(
                from: image
            )
        }.value
    }

    static func recognizeText(
        from images: [UIImage]
    ) async throws -> String {
        guard !images.isEmpty else {
            throw ImageTextRecognizerError
                .invalidImage
        }

        return try await Task.detached(
            priority: .userInitiated
        ) {
            var recognizedPages: [String] = []

            for (
                index,
                image
            ) in images.enumerated() {
                do {
                    let result =
                        try recognizeSynchronously(
                            from: image
                        )

                    let labeledPage = """
                    Page \(index + 1)

                    \(result.text)
                    """

                    recognizedPages.append(
                        labeledPage
                    )
                } catch ImageTextRecognizerError
                    .noTextFound {
                    continue
                }
            }

            let combinedText =
                recognizedPages
                    .joined(
                        separator: "\n\n"
                    )
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard !combinedText.isEmpty else {
                throw ImageTextRecognizerError
                    .noTextFound
            }

            return combinedText
        }.value
    }

    private static func recognizeSynchronously(
        from image: UIImage
    ) throws -> ImageTextRecognitionResult {
        guard let cgImage = image.cgImage else {
            throw ImageTextRecognizerError
                .invalidImage
        }

        let request =
            VNRecognizeTextRequest()

        request.recognitionLevel =
            .accurate

        request.usesLanguageCorrection =
            true

        request.minimumTextHeight =
            0.01

        let requestHandler =
            VNImageRequestHandler(
                cgImage: cgImage,
                orientation:
                    image.imageOrientation
                        .cgImageOrientation,
                options: [:]
            )

        do {
            try requestHandler.perform([
                request
            ])
        } catch {
            throw ImageTextRecognizerError
                .recognitionFailed
        }

        guard let observations =
            request.results
        else {
            throw ImageTextRecognizerError
                .noTextFound
        }

        var lines: [String] = []
        var regions:
            [RecognizedTextRegion] = []

        for observation in observations {
            guard let candidate =
                observation
                    .topCandidates(1)
                    .first
            else {
                continue
            }

            let text = candidate.string
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard !text.isEmpty else {
                continue
            }

            lines.append(text)

            regions.append(
                RecognizedTextRegion(
                    text: text,
                    boundingBox:
                        observation.boundingBox
                )
            )
        }

        let recognizedText =
            lines
                .joined(separator: "\n")
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !recognizedText.isEmpty else {
            throw ImageTextRecognizerError
                .noTextFound
        }

        return ImageTextRecognitionResult(
            text: recognizedText,
            regions: regions
        )
    }
}

private extension UIImage.Orientation {
    var cgImageOrientation:
        CGImagePropertyOrientation {

        switch self {
        case .up:
            return .up

        case .upMirrored:
            return .upMirrored

        case .down:
            return .down

        case .downMirrored:
            return .downMirrored

        case .left:
            return .left

        case .leftMirrored:
            return .leftMirrored

        case .right:
            return .right

        case .rightMirrored:
            return .rightMirrored

        @unknown default:
            return .up
        }
    }
}
