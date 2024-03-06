//
// SecurityCenterRepository.swift
// Proton Pass - Created on 06/03/2024.
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

@preconcurrency import Combine
import Entities
import Foundation
@preconcurrency import PassRustCore

public struct WeaknessAccounts: Equatable {
    public let weakPasswords: Int
    public let reusedPasswords: Int
    public let missing2FA: Int
    public let excludedItems: Int
    public let exposedPasswords: Int

    public static var `default`: WeaknessAccounts {
        WeaknessAccounts(weakPasswords: 0, reusedPasswords: 0, missing2FA: 0, excludedItems: 0,
                         exposedPasswords: 0)
    }
}

public struct SecurityAffectedItem {
    public let item: SymmetricallyEncryptedItem
    public let weaknesses: [SecurityWeakness]
}

public enum SecurityWeakness: Equatable {
    case weakPasswords
    case reusedPasswords
    case exposedEmail
    case exposedPassword
    case missing2FA
    case excludedItems

    public var title: String {
        switch self {
        case .excludedItems:
            "Excluded Items"
        case .weakPasswords:
            "Weak passwords"
        case .reusedPasswords:
            "Reused passwords"
        case .exposedEmail:
            "Exposed emails"
        case .exposedPassword:
            "Exposed passwords"
        case .missing2FA:
            "Missing two-factor authentication"
        }
    }

    public var info: String {
        switch self {
        case .excludedItems:
            "The following items are excluded from "
        case .weakPasswords:
            "Weak passwords are easier to guess. Generate strong passwords to keep your accounts safe."
        case .reusedPasswords:
            "Generate unique passwords to increase your security."
        case .exposedEmail:
            "These accounts appear in data breaches. Update your credentials immediately."
        case .exposedPassword:
            "These password appear in data breaches. Update your credentials immediately."
        case .missing2FA:
            "Logins with sites that have two-factor authentication available but you haven’t set it up yet."
        }
    }
}

public protocol SecurityCenterRepositoryProtocol {
    var weaknessAccounts: CurrentValueSubject<WeaknessAccounts, Never> { get }
    var itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> { get }
    var hasBreachedItems: CurrentValueSubject<Bool, Never> { get }

    func refreshAllSecurityCenterData() async
}

public actor SecurityCenterRepository: SecurityCenterRepositoryProtocol {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let passwordScorer: any PasswordScorerProtocol

    public let weaknessAccounts: CurrentValueSubject<WeaknessAccounts, Never> = .init(.default)
    public let itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> = .init([])
    public let hasBreachedItems: CurrentValueSubject<Bool, Never> = .init(false)

    public init(itemRepository: any ItemRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                passwordScorer: any PasswordScorerProtocol = PasswordScorer()) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.passwordScorer = passwordScorer
        refreshAllSecurityCenterData()
    }

    public func refreshAllSecurityCenterData() {
        Task { [weak self] in
            guard let self,
                  let symmetricKey = try? symmetricKeyProvider.getSymmetricKey(),
                  let encryptedItems = try? await itemRepository.getActiveLogInItems() else {
                return
            }

            let activeLoginItems = encryptedItems
                .compactMap { try? $0.getItemContent(symmetricKey: symmetricKey) }
            // TODO: remove excluded items
            let listOfReusedPasswords = await reusedPasswords(items: activeLoginItems)

            var numberOfWeakPassword = 0
            var numberOfReusedPassword = 0
            var securityAffectedItems = [SecurityAffectedItem]()

            for item in activeLoginItems {
                guard let loginItem = item.loginItem else {
                    continue
                }
                var weaknesses = [SecurityWeakness]()
                if listOfReusedPasswords.contains(loginItem.password) {
                    weaknesses.append(.reusedPasswords)
                    numberOfReusedPassword += 1
                }

                if await weakPassword(password: loginItem.password) {
                    weaknesses.append(.weakPasswords)
                    numberOfWeakPassword += 1
                }
                // TODO: check for missing 2FA and breached passwords /emails

                if !weaknesses.isEmpty, let item = encryptedItems.first(where: { $0.itemId == item.itemId }) {
                    securityAffectedItems.append(SecurityAffectedItem(item: item, weaknesses: weaknesses))
                }
            }

//            let securityAffectedItem = activeLoginItems.compactMap { [passwordScorer] item ->
//            SecurityAffectedItem? in
//                guard let loginItem = item.loginItem else {
//                    return nil
//                }
//                var weaknesses = [SecurityWeakness]()
            //                if listOfReusedPasswords.contains(loginItem.password) {
            //                    weaknesses.append(.reusedPasswords)
            //                }
            //
            //                if passwordScorer.checkScore(password: loginItem.password) != .strong
            //                /*weakPassword(password: loginItem.password)*/ {
            //                    weaknesses.append(.weakPasswords)
            //                }
            //
            //                //TODO: check for missing 2FA and breached passwords /emails
//
//                if !weaknesses.isEmpty, let item = encryptedItems.first(where: { $0.itemId == item.itemId }) {
//                    return SecurityAffectedItem(item: item, weakness: weaknesses)
//                }
//                return nil
//            }
            weaknessAccounts.send(WeaknessAccounts(weakPasswords: numberOfWeakPassword,
                                                   reusedPasswords: numberOfReusedPassword,
                                                   missing2FA: 0,
                                                   excludedItems: 0,
                                                   exposedPasswords: 0))
            itemsWithSecurityIssues.send(securityAffectedItems)
        }
    }

    // TODO: maybe return id of items
    private func reusedPasswords(items: [ItemContent]) -> [String] /* [(password: String, count: Int)] */ {
        var passwordCounts = [String: Int]()

        // Count occurrences of each password
        for item in items {
            guard let loginItem = item.loginItem else { continue }

            passwordCounts[loginItem.password, default: 0] += 1
        }

        // Filter out unique passwords and prepare the result
        let reusedPasswords = passwordCounts.filter { $0.value > 1 }
            .map(\.key)
//                                                 .sorted(by: { $0.count > $1.count }) // Optional sorting

        return reusedPasswords
    }

    func weakPassword(password: String) -> Bool {
        passwordScorer.checkScore(password: password) != .strong
    }
}

//
//
// public init() {
// }
//
// public func execute(password: String) -> PasswordStrength? {
//    guard !password.isEmpty else {
//        return nil
//    }
//    return switch passwordScorer.checkScore(password: password) {
//    case .vulnerable:
//        .vulnerable
//    case .weak:
//        .weak
//    case .strong:
//        .strong
//    }
// }
