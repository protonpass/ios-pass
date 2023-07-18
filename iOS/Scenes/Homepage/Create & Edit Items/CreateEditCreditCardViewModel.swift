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
import SwiftUI

final class CreateEditCreditCardViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var cardholderName = ""
    @Published var cardNumber = ""
    @Published var verificationNumber = ""
    @Published var pin = ""
    @Published var month: Int?
    @Published var year: Int?
    @Published var note = ""

    override func itemContentType() -> ItemContentType { .creditCard }

    override var isSaveable: Bool { !title.isEmpty }

    var shouldUpgrade: Bool {
        // Free users can not create more credit cards but can only update
        if case .create = mode, isFreeUser {
            return true
        }
        return false
    }

    override init(mode: ItemMode,
                  itemRepository: ItemRepositoryProtocol,
                  upgradeChecker: UpgradeCheckerProtocol,
                  vaults: [Vault],
                  preferences: Preferences,
                  logManager: LogManagerProtocol) throws {
        try super.init(mode: mode,
                       itemRepository: itemRepository,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults,
                       preferences: preferences,
                       logManager: logManager)

        $cardNumber
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .receive(on: RunLoop.main)
            .map(transformAndLimit)
            .sink { [weak self] formattedCardNumber in
                guard let self else { return }
                self.cardNumber = formattedCardNumber
            }
            .store(in: &cancellables)

        $verificationNumber
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .receive(on: RunLoop.main)
            .map { $0.prefix(4).toString }
            .sink { [weak self] formattedVerificationNumber in
                guard let self else { return }
                self.verificationNumber = formattedVerificationNumber
            }
            .store(in: &cancellables)

        Publishers
            .CombineLatest($title, $cardholderName)
            .combineLatest($cardNumber)
            .combineLatest($verificationNumber)
            .combineLatest($pin)
            .combineLatest($month)
            .combineLatest($year)
            .combineLatest($note)
            .dropFirst(mode.isEditMode ? 1 : 3)
            .sink(receiveValue: { [weak self] _ in
                self?.didEditSomething = true
            })
            .store(in: &cancellables)
    }

    override func generateItemContent() -> ItemContentProtobuf {
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
                     customFields: customFieldUiModels.map(\.customField))
    }

    override func bindValues() {
        guard case let .edit(itemContent) = mode,
              case let .creditCard(data) = itemContent.contentData else { return }
        title = itemContent.name
        cardholderName = data.cardholderName
        cardNumber = data.number.toCreditCardNumber()
        verificationNumber = data.verificationNumber
        pin = data.pin

        let monthYear = data.expirationDate.components(separatedBy: "-")
        month = Int(monthYear.last ?? "")
        year = Int(monthYear.first ?? "")

        note = itemContent.note
    }
}

private extension CreateEditCreditCardViewModel {
    func transformAndLimit(newNumber: String) -> String {
        newNumber.spacesRemoved.prefix(19).toString.toCreditCardNumber()
    }
}
