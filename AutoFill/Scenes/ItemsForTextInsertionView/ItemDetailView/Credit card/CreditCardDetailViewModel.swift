//
// CreditCardDetailViewModel.swift
// Proton Pass - Created on 09/10/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities
import Foundation

@MainActor
final class CreditCardDetailViewModel: BaseItemDetailViewModel {
    private(set) var cardholderName = ""
    private(set) var cardNumber = ""
    private(set) var verificationNumber = ""
    private(set) var pin = ""
    private(set) var month: Int = 0
    private(set) var year: Int = 0

    var expirationDate: String {
        CreditCardData.expirationDate(month: month, year: year)
    }

    override func bindValues() {
        if case let .creditCard(data) = item.content.contentData {
            cardholderName = data.cardholderName
            cardNumber = data.number
            verificationNumber = data.verificationNumber
            pin = data.pin
            month = data.month
            year = data.year
        } else {
            fatalError("Expecting credit card type")
        }
    }
}
