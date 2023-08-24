//
// CreditCardDetailViewModel.swift
// Proton Pass - Created on 15/06/2023.
// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import Core
import SwiftUI

final class CreditCardDetailViewModel: BaseItemDetailViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var cardholderName = ""
    @Published private(set) var cardNumber = ""
    @Published private(set) var verificationNumber = ""
    @Published private(set) var pin = ""
    @Published private(set) var month: Int?
    @Published private(set) var year: Int?
    @Published private(set) var note = ""

    var expirationDate: String {
        if let month, let year {
            return String(format: "%02d / %d", month, year)
        } else {
            return ""
        }
    }

    override func bindValues() {
        if case let .creditCard(data) = itemContent.contentData {
            cardholderName = data.cardholderName
            cardNumber = data.number
            verificationNumber = data.verificationNumber
            pin = data.pin

            let monthYear = data.expirationDate.components(separatedBy: "-")
            month = Int(monthYear.last ?? "")
            year = Int(monthYear.first ?? "")

            note = itemContent.note
        } else {
            fatalError("Expecting credit card type")
        }
    }
}

// MARK: - Public APIs

extension CreditCardDetailViewModel {
    func copyCardholderName() {
        guard !cardholderName.isEmpty else { return }
        copyToClipboard(text: cardholderName, message: "Cardholder name copied".localized)
    }

    func copyCardNumber() {
        guard !cardNumber.isEmpty else { return }
        copyToClipboard(text: cardNumber, message: "Card number copied".localized)
    }

    func copyVerificationNumber() {
        guard !verificationNumber.isEmpty else { return }
        copyToClipboard(text: verificationNumber, message: "Verification number copied".localized)
    }
}
