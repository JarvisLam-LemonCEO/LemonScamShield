import SwiftUI
import SwiftData
import PhotosUI
import VisionKit
import UIKit

struct ScannerView: View {
    @Environment(\.modelContext)
    private var modelContext
    
    @AppStorage(
        AppPreferenceKeys.automaticallySaveHistory
    )
    private var automaticallySaveHistory = true

    @State private var selectedCheckType:
        ScamCheckType = .message

    @State private var inputText = ""

    @State private var analysisResult:
        ScamAnalysisResult?

    // Smart Paste
    @State private var pasteDetectionMessage = ""

    @State private var isShowingPasteDetection = false

    // Screenshot importing
    @State private var selectedPhotoItem:
        PhotosPickerItem?

    @State private var selectedImageData:
        Data?

    @State private var screenshotWasImported = false

    // Camera document scanning
    @State private var isShowingDocumentScanner = false

    @State private var scannedDocumentImages:
        [UIImage] = []

    @State private var documentWasScanned = false

    // Shared text-extraction state
    @State private var isExtractingText = false

    @State private var extractionErrorMessage = ""

    @State private var isShowingExtractionError = false
    @State private var screenshotHighlights:
        [ScreenshotHighlight] = []
    

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {
                    appHeader
                    smartPasteSection
                    checkTypePicker
                    selectedTypeHeader

                    if selectedCheckType == .message {
                        imageImportSection
                    }

                    inputSection
                    analyzeButton
                    privacyNotice
                }
                .padding()
            }
            .navigationTitle("ScamShield")
            .sheet(
                item: $analysisResult
            ) { result in
                AnalysisResultView(
                    result: result,
                    wasSavedToHistory:
                        automaticallySaveHistory
                )
            }
            .fullScreenCover(
                isPresented:
                    $isShowingDocumentScanner
            ) {
                DocumentScannerView(
                    onComplete: {
                        images in

                        handleScannedDocument(
                            images
                        )
                    },
                    onCancel: {
                        isShowingDocumentScanner =
                            false
                    },
                    onError: {
                        error in

                        isShowingDocumentScanner =
                            false

                        showExtractionError(
                            error.localizedDescription
                        )
                    }
                )
                .ignoresSafeArea()
            }
            .alert(
                "Text Could Not Be Read",
                isPresented:
                    $isShowingExtractionError
            ) {
                Button(
                    "OK",
                    role: .cancel
                ) {}
            } message: {
                Text(extractionErrorMessage)
            }
            .alert(
                "Content Detected",
                isPresented:
                    $isShowingPasteDetection
            ) {
                Button(
                    "OK",
                    role: .cancel
                ) {}
            } message: {
                Text(pasteDetectionMessage)
            }
            .onChange(
                of: selectedCheckType
            ) {
                clearImportedMedia()
            }
            .onChange(
                of: selectedPhotoItem
            ) {
                loadSelectedScreenshot()
            }
        }
    }

    private var appHeader: some View {
        HStack(spacing: 14) {
            Image(
                systemName: "shield.checkered"
            )
            .font(.system(size: 44))
            .foregroundStyle(.blue)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text("ScamShield")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Check before you trust")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var smartPasteSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Label(
                "Quick check",
                systemImage: "doc.on.clipboard"
            )
            .font(.headline)

            Text(
                "Copy a suspicious message, website, or phone number from another app, then tap Paste."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            PasteButton(
                payloadType: String.self
            ) { pastedValues in
                guard let pastedValue =
                    pastedValues.first
                else {
                    return
                }

                handlePastedValue(
                    pastedValue
                )
            }
            .labelStyle(
                .titleAndIcon
            )
            .buttonBorderShape(
                .roundedRectangle(
                    radius: 14
                )
            )
            .tint(.blue)
        }
        .padding()
        .background(
            Color.blue.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var checkTypePicker: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text(
                "What would you like to check?"
            )
            .font(.headline)

            Picker(
                "Check type",
                selection: $selectedCheckType
            ) {
                ForEach(
                    ScamCheckType.allCases
                ) { checkType in
                    Label(
                        checkType.rawValue,
                        systemImage:
                            checkType.systemImage
                    )
                    .tag(checkType)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var selectedTypeHeader: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Image(
                systemName:
                    selectedCheckType.systemImage
            )
            .font(.system(size: 38))
            .foregroundStyle(.blue)

            Text(selectedCheckType.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(selectedCheckType.description)
                .foregroundStyle(.secondary)
        }
        .animation(
            .easeInOut,
            value: selectedCheckType
        )
    }

    private var imageImportSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Label(
                "Import or scan text",
                systemImage: "text.viewfinder"
            )
            .font(.headline)

            Text(
                "Choose a screenshot or scan a printed document. ScamShield extracts the visible text directly on this device."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            screenshotPickerButton
            documentScannerButton

            if let previewImage {
                if screenshotWasImported {
                    annotatedImagePreview(
                        image: previewImage
                    )
                } else {
                    imagePreview(
                        image: previewImage
                    )
                }
            }

            if importedTextWasCreated {
                Label(
                    successMessage,
                    systemImage:
                        "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.green)
            }
        }
        .padding()
        .background(
            Color.indigo.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
    
    private func annotatedImagePreview(
        image: UIImage
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            AnnotatedScreenshotView(
                image: image,
                highlights:
                    screenshotHighlights
            )
            .frame(maxHeight: 420)

            if screenshotHighlights.isEmpty {
                Label(
                    "No suspicious phrases were highlighted in the screenshot.",
                    systemImage:
                        "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Label(
                    "\(screenshotHighlights.count) suspicious text regions highlighted",
                    systemImage:
                        "highlighter"
                )
                .font(.caption)
                .foregroundStyle(.orange)

                highlightLegend
            }
        }
    }
    
    private var highlightLegend:
        some View {

        let categories =
            Set(
                screenshotHighlights.map {
                    $0.category
                }
            )

        return ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                ForEach(
                    ScreenshotHighlightCategory
                        .allCases
                ) { category in
                    if categories.contains(
                        category
                    ) {
                        Label(
                            category.title,
                            systemImage:
                                "rectangle.fill"
                        )
                        .font(.caption2)
                        .padding(
                            .horizontal,
                            9
                        )
                        .padding(
                            .vertical,
                            6
                        )
                        .background(
                            Color.secondary
                                .opacity(0.1)
                        )
                        .clipShape(
                            Capsule()
                        )
                    }
                }
            }
        }
    }

    private var screenshotPickerButton:
        some View {

        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            HStack {
                Image(
                    systemName: "photo.badge.plus"
                )

                Text("Choose Screenshot")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.indigo)
            .background(.background)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14
                )
                .stroke(
                    Color.indigo.opacity(0.4),
                    lineWidth: 1
                )
            }
        }
        .disabled(isExtractingText)
    }

    private var documentScannerButton:
        some View {

        Button {
            openDocumentScanner()
        } label: {
            HStack {
                if isExtractingText {
                    ProgressView()
                        .tint(.white)

                    Text("Reading Document...")
                        .fontWeight(.semibold)
                } else {
                    Image(
                        systemName:
                            "doc.viewfinder"
                    )

                    Text(
                        "Scan Printed Document"
                    )
                    .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(
                isExtractingText
                    ? Color.gray
                    : Color.indigo
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .disabled(isExtractingText)
    }

    private var previewImage: UIImage? {
        if let firstDocumentImage =
            scannedDocumentImages.first {
            return firstDocumentImage
        }

        if let selectedImageData {
            return UIImage(
                data: selectedImageData
            )
        }

        return nil
    }

    private var importedTextWasCreated: Bool {
        screenshotWasImported
            || documentWasScanned
    }

    private var successMessage: String {
        if documentWasScanned {
            let pageCount =
                scannedDocumentImages.count

            return pageCount == 1
                ? "Text extracted from 1 scanned page. Review it below before analyzing."
                : "Text extracted from \(pageCount) scanned pages. Review it below before analyzing."
        }

        return """
        Text extracted from the screenshot. Review it below before analyzing.
        """
    }

    private func imagePreview(
        image: UIImage
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)
                .frame(
                    maxWidth: .infinity
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                    .stroke(
                        Color.secondary
                            .opacity(0.2),
                        lineWidth: 1
                    )
                }
                .accessibilityLabel(
                    previewAccessibilityLabel
                )

            if scannedDocumentImages.count > 1 {
                Text(
                    "Showing page 1 of \(scannedDocumentImages.count)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var previewAccessibilityLabel:
        String {

        documentWasScanned
            ? "First scanned document page"
            : "Selected screenshot"
    }

    private var inputSection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text(inputSectionTitle)
                .font(.headline)

            if selectedCheckType == .message {
                messageTextEditor
            } else {
                singleLineTextField
            }

            inputFooter
        }
    }

    private var inputSectionTitle: String {
        if documentWasScanned {
            return "Scanned document text"
        }

        if screenshotWasImported {
            return "Extracted screenshot text"
        }

        return selectedCheckType.inputLabel
    }

    private var messageTextEditor: some View {
        TextEditor(text: $inputText)
            .frame(minHeight: 220)
            .padding(12)
            .background(
                Color.secondary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14
                )
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: 1
                )
            }
            .overlay(
                alignment: .topLeading
            ) {
                if inputText.isEmpty {
                    Text(
                        selectedCheckType
                            .placeholder
                    )
                    .foregroundStyle(.secondary)
                    .padding(
                        .horizontal,
                        17
                    )
                    .padding(
                        .vertical,
                        20
                    )
                    .allowsHitTesting(false)
                }
            }
            .textInputAutocapitalization(
                .sentences
            )
            .autocorrectionDisabled(false)
    }

    private var singleLineTextField:
        some View {

        TextField(
            selectedCheckType.placeholder,
            text: $inputText
        )
        .padding()
        .background(
            Color.secondary.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 14
            )
            .stroke(
                Color.secondary.opacity(0.2),
                lineWidth: 1
            )
        }
        .keyboardType(keyboardType)
        .textInputAutocapitalization(
            .never
        )
        .autocorrectionDisabled()
    }

    private var inputFooter: some View {
        HStack {
            Text(inputStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if hasImportedOrTypedContent {
                Button("Clear") {
                    clearInput()
                }
                .font(.caption)
            }
        }
    }

    private var hasImportedOrTypedContent:
        Bool {

        !inputText.isEmpty
            || selectedImageData != nil
            || !scannedDocumentImages.isEmpty
    }

    private var analyzeButton: some View {
        Button {
            analyzeInput()
        } label: {
            HStack {
                Image(
                    systemName:
                        "magnifyingglass"
                )

                Text(
                    selectedCheckType
                        .buttonTitle
                )
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(
                inputIsValid
                    && !isExtractingText
                    ? Color.blue
                    : Color.gray
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .disabled(
            !inputIsValid
                || isExtractingText
        )
    }

    private var privacyNotice: some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.green)

            Text(
                "Pasting, screenshot recognition, document recognition, and scam analysis happen only after you request them. Images are not stored in scan history."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            Color.green.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }

    private var keyboardType:
        UIKeyboardType {

        switch selectedCheckType {
        case .message:
            return .default

        case .website:
            return .URL

        case .phone:
            return .phonePad
        }
    }

    private var inputStatusText: String {
        switch selectedCheckType {
        case .message:
            if isExtractingText {
                return "Extracting text..."
            }

            return "\(inputText.count) characters"

        case .website:
            return inputText.isEmpty
                ? "Enter a website address"
                : "Website ready to check"

        case .phone:
            return inputText.isEmpty
                ? "Enter a phone number"
                : "\(phoneDigitCount) digits entered"
        }
    }

    private var phoneDigitCount: Int {
        inputText.filter(\.isNumber).count
    }

    private var inputIsValid: Bool {
        let cleanedInput = inputText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedInput.isEmpty else {
            return false
        }

        switch selectedCheckType {
        case .message:
            return cleanedInput.count >= 3

        case .website:
            return cleanedInput.contains(".")
                && cleanedInput.count >= 4

        case .phone:
            return phoneDigitCount >= 7
        }
    }

    private func handlePastedValue(
        _ value: String
    ) {
        let detector =
            SmartInputDetector()

        let detection =
            detector.detect(value)

        clearImportedMedia()

        selectedCheckType =
            detection.checkType

        inputText =
            detection.cleanedValue

        pasteDetectionMessage =
            detection.explanation

        isShowingPasteDetection = true
    }

    private func openDocumentScanner() {
        guard
            VNDocumentCameraViewController
                .isSupported
        else {
            showExtractionError(
                DocumentScannerError
                    .scannerUnavailable
                    .localizedDescription
            )

            return
        }

        dismissKeyboard()
        isShowingDocumentScanner = true
    }

    private func handleScannedDocument(
        _ images: [UIImage]
    ) {
        isShowingDocumentScanner = false

        guard !images.isEmpty else {
            showExtractionError(
                DocumentScannerError
                    .noPagesScanned
                    .localizedDescription
            )

            return
        }

        selectedPhotoItem = nil
        selectedImageData = nil
        screenshotWasImported = false

        scannedDocumentImages = images
        documentWasScanned = false
        inputText = ""
        isExtractingText = true

        Task {
            do {
                let recognizedText =
                    try await
                    ImageTextRecognizer
                        .recognizeText(
                            from: images
                        )

                await MainActor.run {
                    inputText = recognizedText
                    documentWasScanned = true
                    isExtractingText = false
                }
            } catch {
                await MainActor.run {
                    scannedDocumentImages = []
                    documentWasScanned = false
                    inputText = ""
                    isExtractingText = false

                    showExtractionError(
                        error.localizedDescription
                    )
                }
            }
        }
    }

    private func loadSelectedScreenshot() {
        guard let selectedPhotoItem else {
            return
        }

        scannedDocumentImages = []
        documentWasScanned = false

        isExtractingText = true
        screenshotWasImported = false
        selectedImageData = nil
        inputText = ""

        Task {
            do {
                guard let imageData =
                    try await
                    selectedPhotoItem
                        .loadTransferable(
                            type: Data.self
                        )
                else {
                    throw
                        ImageTextRecognizerError
                            .invalidImage
                }

                let recognitionResult =
                    try await
                    ImageTextRecognizer
                        .recognizeTextWithRegions(
                            from: imageData
                        )

                let highlights =
                    ScreenshotHighlightDetector()
                        .highlights(
                            from:
                                recognitionResult
                                    .regions
                        )

                await MainActor.run {
                    selectedImageData =
                        imageData

                    inputText =
                        recognitionResult.text

                    screenshotHighlights =
                        highlights

                    screenshotWasImported =
                        true

                    isExtractingText =
                        false
                }
            } catch {
                await MainActor.run {
                    selectedImageData = nil
                    inputText = ""

                    screenshotWasImported =
                        false

                    isExtractingText =
                        false

                    showExtractionError(
                        error.localizedDescription
                    )
                }
            }
        }
    }

    private func analyzeInput() {
        let cleanedInput = inputText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let analyzer = ScamAnalyzer()

        let result = analyzer.analyze(
            cleanedInput,
            as: selectedCheckType
        )

        if automaticallySaveHistory {
            addToHistory(result)
        }

        analysisResult = result
    }
    
    private func addToHistory(
        _ result: ScamAnalysisResult
    ) {
        let historyItem =
            ScanHistoryItem(
                result: result
            )

        modelContext.insert(
            historyItem
        )
    }

    private func showExtractionError(
        _ message: String
    ) {
        extractionErrorMessage =
            message

        isShowingExtractionError =
            true
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func clearImportedMedia() {
        selectedPhotoItem = nil
        selectedImageData = nil
        screenshotWasImported = false
        screenshotHighlights = []

        scannedDocumentImages = []
        documentWasScanned = false

        isExtractingText = false
    }

    private func clearInput() {
        inputText = ""
        analysisResult = nil
        clearImportedMedia()
    }
}

#Preview {
    ScannerView()
        .modelContainer(
            for: ScanHistoryItem.self,
            inMemory: true
        )
}
