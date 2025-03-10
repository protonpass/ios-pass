//
// CreateEditCreditCardViewModel.swift
// Proton Pass - Created on 13/06/2023.
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

import Client
import Combine
import Core
import DocScanner
import Entities
import SwiftUI

final class CreateEditCreditCardViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var cardholderName = ""
    @Published var cardNumber = ""
    @Published var verificationNumber = ""
    @Published var pin = ""
    @Published var month: Int?
    @Published var year: Int?
    @Published var note = ""

    // For swapping section title color purpose
    // We're only interested in the emptiness of the string, not the format
    var monthYear: String {
        if let month, let year {
            "\(month) / \(year)"
        } else {
            ""
        }
    }

    override var itemContentType: ItemContentType { .creditCard }

    override var isSaveable: Bool {
        super.isSaveable && !title.isEmpty
    }

    override var shouldUpgrade: Bool {
        // Free users can not create more credit cards but can only update
        if case .create = mode, isFreeUser {
            return true
        }
        return false
    }

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Share]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)

        $cardNumber
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .receive(on: RunLoop.main)
            .map(transformAndLimit)
            .sink { [weak self] formattedCardNumber in
                guard let self else { return }
                cardNumber = formattedCardNumber
            }
            .store(in: &cancellables)

        $verificationNumber
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .receive(on: RunLoop.main)
            .map { $0.prefix(4).toString }
            .sink { [weak self] formattedVerificationNumber in
                guard let self else { return }
                verificationNumber = formattedVerificationNumber
            }
            .store(in: &cancellables)

        scanResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] result in
                guard let self, let result else { return }
                if let cardDetails = result as? CardDetails {
                    parse(cardDetails: cardDetails)
                } else {
                    assertionFailure("Expecting CardDetails as result")
                }
            }
            .store(in: &cancellables)
    }

    var interpretor: any ScanInterpreting {
        ScanInterpreter(type: .card)
    }

    override func generateItemContent() async -> ItemContentProtobuf {
        let month = month ?? Calendar.current.component(.month, from: .now)
        let year = year ?? Calendar.current.component(.year, from: .now)
        let data = CreditCardData(cardholderName: cardholderName,
                                  type: .unspecified,
                                  number: cardNumber.spacesRemoved,
                                  verificationNumber: verificationNumber,
                                  expirationDate: String(format: "%d-%02d", year, month),
                                  pin: pin)
        return .init(name: title,
                     note: note,
                     itemUuid: UUID().uuidString,
                     data: .creditCard(data),
                     customFields: customFields)
    }

    override func bindValues() {
        switch mode {
        case let .clone(itemContent), let .edit(itemContent):
            guard case let .creditCard(data) = itemContent.contentData else { return }
            title = itemContent.name
            cardholderName = data.cardholderName
            cardNumber = data.number.toCreditCardNumber()
            verificationNumber = data.verificationNumber
            pin = data.pin

            let monthYear = data.expirationDate.components(separatedBy: "-")
            month = Int(monthYear.last ?? "")
            year = Int(monthYear.first ?? "")

            note = itemContent.note

        case .create:
            break
        }
    }
}

private extension CreateEditCreditCardViewModel {
    func transformAndLimit(newNumber: String) -> String {
        newNumber.spacesRemoved.prefix(19).toString.toCreditCardNumber()
    }

    func parse(cardDetails: CardDetails) {
        if cardDetails.type != .unknown {
            title = cardDetails.type.rawValue
        }
        cardholderName = cardDetails.name ?? ""
        cardNumber = cardDetails.number ?? ""
        verificationNumber = cardDetails.cvvNumber ?? ""

        // expiryDate format "MM/YY"
        if let expiryDate = cardDetails.expiryDate {
            let dateComponents = expiryDate.components(separatedBy: "/")
            if dateComponents.count == 2 {
                month = Int(dateComponents.first ?? "")

                if let year = Int(dateComponents.last ?? "") {
                    if year < 100 {
                        // 2-digit year, assume that it's after the year of 2000
                        self.year = 2_000 + year
                    } else {
                        self.year = year
                    }
                }
            }
        }
    }
}
