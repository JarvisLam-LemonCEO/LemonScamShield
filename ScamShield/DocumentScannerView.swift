import SwiftUI
import VisionKit
import UIKit

enum DocumentScannerError: LocalizedError {
    case scannerUnavailable
    case noPagesScanned
    case scanningFailed(String)

    var errorDescription: String? {
        switch self {
        case .scannerUnavailable:
            return """
            Document scanning is not available on this device.
            """

        case .noPagesScanned:
            return """
            No document pages were captured.
            """

        case .scanningFailed(let message):
            return """
            The document scanner encountered an error: \(message)
            """
        }
    }
}

struct DocumentScannerView:
    UIViewControllerRepresentable {

    let onComplete: ([UIImage]) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onComplete: onComplete,
            onCancel: onCancel,
            onError: onError
        )
    }

    func makeUIViewController(
        context: Context
    ) -> VNDocumentCameraViewController {
        let scanner =
            VNDocumentCameraViewController()

        scanner.delegate = context.coordinator

        return scanner
    }

    func updateUIViewController(
        _ uiViewController:
            VNDocumentCameraViewController,
        context: Context
    ) {
        // No updates are required.
    }

    final class Coordinator:
        NSObject,
        VNDocumentCameraViewControllerDelegate {

        private let onComplete:
            ([UIImage]) -> Void

        private let onCancel:
            () -> Void

        private let onError:
            (Error) -> Void

        init(
            onComplete:
                @escaping ([UIImage]) -> Void,
            onCancel:
                @escaping () -> Void,
            onError:
                @escaping (Error) -> Void
        ) {
            self.onComplete = onComplete
            self.onCancel = onCancel
            self.onError = onError
        }

        func documentCameraViewController(
            _ controller:
                VNDocumentCameraViewController,
            didFinishWith scan:
                VNDocumentCameraScan
        ) {
            var scannedImages: [UIImage] = []

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(
                    at: pageIndex
                )

                scannedImages.append(image)
            }

            controller.dismiss(
                animated: true
            ) {
                if scannedImages.isEmpty {
                    self.onError(
                        DocumentScannerError
                            .noPagesScanned
                    )
                } else {
                    self.onComplete(
                        scannedImages
                    )
                }
            }
        }

        func documentCameraViewControllerDidCancel(
            _ controller:
                VNDocumentCameraViewController
        ) {
            controller.dismiss(
                animated: true
            ) {
                self.onCancel()
            }
        }

        func documentCameraViewController(
            _ controller:
                VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(
                animated: true
            ) {
                self.onError(
                    DocumentScannerError
                        .scanningFailed(
                            error.localizedDescription
                        )
                )
            }
        }
    }
}
