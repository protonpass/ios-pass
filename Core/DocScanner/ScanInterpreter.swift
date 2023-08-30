//
//  ScanInterpreter.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import NaturalLanguage
import Vision
import VisionKit

/**
 The `ScanInterpreter` actor provides document interpretation functionality for scanned documents and cards.
 It utilizes the Vision and VisionKit frameworks to extract text from scanned images and interprets the text to construct a `ScanResponse`.
 */
public actor ScanInterpreter: ScanInterpreting {
    private let type: DocScanType
    private let ignoredWords: IgnoredWords?

    public init(type: DocScanType = .document) {
        self.type = type
        ignoredWords = ScanInterpreter.loadJson(filename: "ignoredWords")
    }

    /**
     Parses and interprets scanned document pages.

     - Parameter scans: A `VNDocumentCameraScan` object containing scanned document pages.

     - Returns: A `ScanResponse` that represents the interpretation of the scanned document.
     */
    public func parseAndInterpret(scans: VNDocumentCameraScan) async -> any ScanResponse {
        switch type {
        case .card:
            return parseCard(scan: scans)
        case .document:
            return parseDocument(scans: scans)
        }
    }
}

// MARK: - Documents

private extension ScanInterpreter {
    func parseDocument(scans: VNDocumentCameraScan) -> any ScanResponse {
        let scanPages = (0..<scans.pageCount).compactMap { pageNumber -> Page? in
            let image = scans.imageOfPage(at: pageNumber)
            guard let text = extractText(image: image) else {
                return nil
            }

            return Page(pageNumber: pageNumber, image: image, text: text)
        }

        return ScannedDocument(scannedPages: scanPages)
    }
}

// MARK: - Cards

private extension ScanInterpreter {
    /**
     Parses and interprets a scanned card.

     - Parameter scan: A `VNDocumentCameraScan` object containing a scanned card image.

     - Returns: A `ScanResponse` that represents the interpretation of the scanned card.
     */
    func parseCard(scan: VNDocumentCameraScan) -> any ScanResponse {
        let image = scan.imageOfPage(at: 0)
        guard let text = extractText(image: image) else {
            return CardDetails.empty
        }
        return parseCardResults(for: text, and: image)
    }

    func parseCardResults(for recognizedText: [String], and image: UIImage) -> any ScanResponse {
        var expiryDate: String?
        var name: String?
        var creditCardNumber: String?
        var cvv: String?
        if let parsedCard = parseCardNumber(from: recognizedText) {
            creditCardNumber = parsedCard
        }
        for text in recognizedText {
            if let expiryDateString = parseExpiryDate(from: text) {
                expiryDate = expiryDateString
            }

            if let parsedName = parseName(from: text) {
                name = parsedName
            }

            if let parsedCVV = parseCVV(from: text, and: creditCardNumber) {
                cvv = parsedCVV
            }
        }

        return CardDetails(image: image,
                           numberWithDelimiters: creditCardNumber,
                           name: name,
                           expiryDate: expiryDate,
                           cvvNumber: cvv)
    }

    /**
     Parses and extracts the card number from recognized text.

     - Parameter infos: An array of recognized text strings.

     - Returns: The card number as a string.
     */
    func parseCardNumber(from infos: [String]) -> String? {
        if let creditCardNumber = infos.first(where: { $0.spaceTrimmed.isNumber &&
                $0.count >= 13 &&
                ["4", "5", "3", "6"].contains($0.first)
        }) {
            return creditCardNumber
        }

        var creditCardNumber = infos
            .filter { !$0.contains("/") }
            .filter { $0.rangeOfCharacter(from: .letters) == nil && $0.count >= 4 }
            .joined(separator: " ")

        if creditCardNumber.spaceTrimmed.count > 16 {
            creditCardNumber = String(creditCardNumber.spaceTrimmed.prefix(16))
        }
        return creditCardNumber
    }

    /**
     Parses and extracts the expiry date from recognized text.

     - Parameter text: The recognized text string.

     - Returns: The expiry date as a string.
     */
    func parseExpiryDate(from text: String) -> String? {
        let numberRange = 5...7
        let components = text.components(separatedBy: "/")
        guard numberRange.contains(text.count), text.contains("/"),
              components.count == 2 else {
            return nil
        }
        for component in components where !component.isNumber {
            return nil
        }

        return text
    }

    /**
     Parses and extracts the cardholder's name from recognized text.

     - Parameter text: The recognized text string.

     - Returns: The cardholder's name as a string.
     */
    func parseName(from text: String) -> String? {
        if let detectedName = naturalLanguageNameParser(from: text) {
            return detectedName
        }

        let wordsToAvoid = CardType.names + (ignoredWords?.words ?? [])

        guard !wordsToAvoid.contains(text.lowercased()),
              text.isUppercase,
              text.rangeOfCharacter(from: .decimalDigits) == nil,
              text.components(separatedBy: " ").count >= 2,
              text.nameRegexChecked else {
            return nil
        }

        return text
    }

    /**
     Parses and extracts the CVV (Card Verification Value) from recognized text.
     CVV codes are a 3-digit number for Visa, Mastercard, and Discover cards, and a 4-digit number for Amex.

     - Parameter text: The recognized text string.
     - Parameter cardNumber: The card number for validation.

     - Returns: The CVV as a string.
     */
    func parseCVV(from text: String, and cardNumber: String?) -> String? {
        guard let cardNumber else {
            return nil
        }
        let type = CardType(number: cardNumber.spaceTrimmed)
        guard type == .visa || type == .masterCard || type == .amex, text.isNumber else {
            return nil
        }
        if type == .visa || type == .masterCard, text.count != 3 {
            return nil
        }
        if type == .amex, text.count != 4 {
            return nil
        }
        if cardNumber.contains(text) {
            return nil
        }
        return text
    }
}

// MARK: - Utils

private extension ScanInterpreter {
    /**
     Extracts recognized text from an image.

     - Parameter image: A `UIImage` containing text.

     - Returns: An array of recognized text strings, or `nil` if text extraction fails.
     */
    func extractText(image: UIImage?) -> [String]? {
        guard let cgImage = image?.cgImage else { return nil }

        var recognizedText = [String]()

        var textRecognitionRequest = VNRecognizeTextRequest()
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = type == .card ? false : true
        if type == .card {
            textRecognitionRequest.customWords = CardType.allCases.map(\.rawValue) + ["Expiry Date"]
        }
        textRecognitionRequest = VNRecognizeTextRequest { request, _ in
            guard let results = request.results,
                  !results.isEmpty,
                  let requestResults = request.results as? [VNRecognizedTextObservation]
            else { return }
            recognizedText = requestResults.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
            return recognizedText
        } catch {
            return nil
        }
    }

    /**
     Uses Natural Language Processing (NLP) to extract a personal name from text.

     - Parameter text: The text from which to extract a name.

     - Returns: The detected name as a string, or `nil` if no name is detected.
     */
    func naturalLanguageNameParser(from text: String) -> String? {
        var currentName: String?
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        let tags: [NLTag] = [.personalName]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, tokenRange in
            if let tag,
               tags.contains(tag) {
                currentName = String(text[tokenRange])
            }

            return true
        }

        return currentName
    }

    static func loadJson<T: Decodable>(filename fileName: String) -> T? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
}
