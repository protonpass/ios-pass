//
//  CardDetails.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import UIKit

public struct CardDetails: Hashable, Identifiable, ScanResponse {
    public let number: String?
    public let name: String?
    public let expiryDate: String?
    public let cvvNumber: String?
    public let type: CardType
    public let industry: CardIndustry
    public let image: UIImage?

    public init(image: UIImage? = nil,
                numberWithDelimiters: String? = nil,
                name: String? = nil,
                expiryDate: String? = nil,
                cvvNumber: String? = nil) {
        number = numberWithDelimiters
        self.name = name
        self.expiryDate = expiryDate
        self.cvvNumber = cvvNumber
        type = CardType(number: numberWithDelimiters?.spaceTrimmed)
        industry = CardIndustry(firstDigit: numberWithDelimiters?.first)
        self.image = image
    }

    public var id: Int { hashValue }

    static var empty: CardDetails {
        CardDetails()
    }
}

// TMI About Credit Card Numbers
// There’s actually a ton of information contained in a credit card number. This information isn’t really necessary
// for understanding how to use a credit card, it’s just here so you can learn for fun. The ISO or the
// International Organization for Standardization categorizes the numbers like so:
// Visa cards begin with a 4 and have 13 or 16 digits
// Mastercard cards begin with a 5 and has 16 digits
// American Express cards begin with a 3, followed by a 4 or a 7 has 15 digits
// Discover cards begin with a 6 and have 16 digits
// Diners Club and Carte Blanche cards begin with a 3, followed by a 0, 6, or 8 and have 14 digits
public enum CardType: String, CaseIterable, Identifiable, Sendable {
    case masterCard = "MasterCard"
    case visa = "Visa"
    case amex = "Amex"
    case discover = "Discover"
    case dinersClubOrCarteBlanche = "Diner's Club/Carte Blanche"
    case unknown

    public init(number: String?) {
        guard let count = number?.count, count >= 13 else {
            self = .unknown
            return
        }
        switch number?.first {
        case "3":
            if count == 15 {
                self = .amex
            } else if count == 14 {
                self = .dinersClubOrCarteBlanche
            } else {
                self = .unknown
            }
        case "4": self = (count == 13 || count == 16) ? .visa : .unknown
        case "5": self = count == 16 ? .masterCard : .unknown
        case "6": self = count == 16 ? .discover : .unknown
        default: self = .unknown
        }
    }

    public var id: Int { hashValue }

    public static var names: [String] {
        CardType.allCases.map(\.rawValue)
    }
}

// First digit: Represents the network that produced the credit card. It is called the Major Industry Identifier
// (MII).
// Each digit represents a different industry.
//
// 0: ISO/TC 68 and other industry assignments
// 1: Airlines
// 2: Airlines, financial and other future industry assignments
// 3: Travel and entertainment
// 4: Banking and financial
// 5: Banking and financial
// 6: Merchandising and banking/financial
// 7: Petroleum and other future industry assignments
// 8: Healthcare, telecommunications and other future industry assignments
// 9: For assignment by national standards bodies
public enum CardIndustry: String, CaseIterable, Identifiable, Sendable {
    case industry = "ISO/TC 68 and other industry assignments"
    case airlines = "Airlines"
    case airlinesFinancialAndFuture = "Airlines, financial and other future industry assignments"
    case travelAndEntertainment = "Travel and entertainment"
    case bankingAndFinancial = "Banking and financial"
    case merchandisingAndBanking = "Merchandising and banking/financial"
    case petroleum = "Petroleum and other future industry assignments"
    case healthcareAndTelecom = "Healthcare, telecommunications and other future industry assignments"
    case national = "For assignment by national standards bodies"
    case unknown

    public init(firstDigit: String.Element?) {
        switch firstDigit {
        case "0": self = .industry
        case "1": self = .airlines
        case "2": self = .airlinesFinancialAndFuture
        case "3": self = .travelAndEntertainment
        case "4", "5": self = .bankingAndFinancial
        case "6": self = .merchandisingAndBanking
        case "7": self = .petroleum
        case "8": self = .healthcareAndTelecom
        case "9": self = .national
        default: self = .unknown
        }
    }

    public var id: Int { hashValue }
}
