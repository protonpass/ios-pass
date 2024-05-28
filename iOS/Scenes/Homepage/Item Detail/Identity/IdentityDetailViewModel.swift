//
//
// IdentityDetailViewModel.swift
// Proton Pass - Created on 27/05/2024.
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
//

import Client
import Combine
import Core
import Entities
import Factory
import Macro
import SwiftUI
import UIKit

@MainActor
final class IdentityDetailViewModel: BaseItemDetailViewModel {
    @Published private(set) var title = ""

    @Published private(set) var fullName = ""
    @Published private(set) var email = ""
    @Published private(set) var phoneNumber = ""
    @Published private(set) var firstName = ""
    @Published private(set) var middleName = ""
    @Published private(set) var lastName = ""
    @Published private(set) var birthdate = ""
    @Published private(set) var gender = ""
    @Published private(set) var extraPersonalDetails: [CustomFieldUiModel] = []
    @Published private(set) var organization = ""
    @Published private(set) var streetAddress = ""
    @Published private(set) var zipOrPostalCode = ""
    @Published private(set) var city = ""
    @Published private(set) var stateOrProvince = ""
    @Published private(set) var countryOrRegion = ""
    @Published private(set) var floor = ""
    @Published private(set) var county = ""
    @Published private(set) var extraAddressDetails: [CustomFieldUiModel] = []
    @Published private(set) var socialSecurityNumber = ""
    @Published private(set) var passportNumber = ""
    @Published private(set) var licenseNumber = ""
    @Published private(set) var website = ""
    @Published private(set) var xHandle = ""
    @Published private(set) var secondPhoneNumber = ""
    @Published private(set) var linkedin = ""
    @Published private(set) var reddit = ""
    @Published private(set) var facebook = ""
    @Published private(set) var yahoo = ""
    @Published private(set) var instagram = ""
    @Published private(set) var extraContactDetails: [CustomFieldUiModel] = []
    @Published private(set) var company = ""
    @Published private(set) var jobTitle = ""
    @Published private(set) var personalWebsite = ""
    @Published private(set) var workPhoneNumber = ""
    @Published private(set) var workEmail = ""
    @Published private(set) var extraWorkDetails: [CustomFieldUiModel] = []

    override func bindValues() {
        super.bindValues()
        guard case let .identity(data) = itemContent.contentData else {
//            assert("Expecting identity type")
            return
        }
        title = itemContent.name
        fullName = data.fullName
        email = data.email
        phoneNumber = data.phoneNumber
        firstName = data.firstName
        middleName = data.middleName
        lastName = data.lastName
        birthdate = data.birthdate
        gender = data.gender
        extraPersonalDetails = data.extraPersonalDetails.map { CustomFieldUiModel(customField: $0) }
        organization = data.organization
        streetAddress = data.streetAddress
        zipOrPostalCode = data.zipOrPostalCode
        city = data.city
        stateOrProvince = data.stateOrProvince
        countryOrRegion = data.countryOrRegion
        floor = data.floor
        county = data.county
        extraAddressDetails = data.extraAddressDetails.map { CustomFieldUiModel(customField: $0) }
        socialSecurityNumber = data.socialSecurityNumber
        passportNumber = data.passportNumber
        licenseNumber = data.licenseNumber
        website = data.website
        xHandle = data.xHandle
        secondPhoneNumber = data.secondPhoneNumber
        linkedin = data.linkedin
        reddit = data.reddit
        facebook = data.facebook
        yahoo = data.yahoo
        instagram = data.instagram
        extraContactDetails = data.extraContactDetails.map { CustomFieldUiModel(customField: $0) }
        company = data.company
        jobTitle = data.jobTitle

        personalWebsite = data.personalWebsite
        workPhoneNumber = data.workPhoneNumber
        workEmail = data.workEmail
        extraWorkDetails = data.extraWorkDetails.map { CustomFieldUiModel(customField: $0) }
//            sections.append(contentsOf: data.extraSections.toCreateEditIdentitySections)
    }
}

extension IdentityDetailViewModel {
    func copyValueToClipboard(value: String, message: String) {
        copyToClipboard(text: value, message: message)
    }

    func copyTotpToken(_ token: String) {
        copyToClipboard(text: token, message: #localized("TOTP copied"))
    }

    func copyHiddenText(_ text: String) {
        copyToClipboard(text: text, message: #localized("Hidden text copied"))
    }
}

private extension IdentityDetailViewModel {
    func setUp() {}
}

//
//
// enum TOTPTokenState {
//    case loading
//    case allowed
//    case notAllowed
// }
//
// @MainActor
// final class LogInDetailViewModel: BaseItemDetailViewModel, DeinitPrintable {
//    deinit { print(deinitMessage) }
//
//    @Published private(set) var passkeys = [Passkey]()
//    @Published private(set) var name = ""
//    @Published private(set) var email = ""
//    @Published private(set) var username = ""
//    @Published private(set) var urls: [String] = []
//    @Published private(set) var password = ""
//    @Published private(set) var totpUri = ""
//    @Published private(set) var note = ""
//    @Published private(set) var passwordStrength: PasswordStrength?
//    @Published private(set) var totpTokenState = TOTPTokenState.loading
//    @Published private var aliasItem: SymmetricallyEncryptedItem?
//    @Published private(set) var securityIssues: [SecurityWeakness]?
//    @Published private(set) var reusedItems: [ItemContent]?
//
//    var isAlias: Bool { aliasItem != nil }
//    let showSecurityIssues: Bool
//
//    private let getPasswordStrength = resolve(\SharedUseCasesContainer.getPasswordStrength)
//    private let getLoginSecurityIssues = resolve(\UseCasesContainer.getLoginSecurityIssues)
//    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
//    private let setUpEmailAndUsername = resolve(\SharedUseCasesContainer.setUpEmailAndUsername)
//
//    let totpManager = resolve(\SharedServiceContainer.totpManager)
//    private var cancellable: AnyCancellable?
//    private var cancellables = Set<AnyCancellable>()
//
//    var coloredPassword: AttributedString {
//        PasswordUtils.generateColoredPassword(password)
//    }
//
//    init(isShownAsSheet: Bool,
//         itemContent: ItemContent,
//         upgradeChecker: any UpgradeCheckerProtocol,
//         showSecurityIssues: Bool) {
//        self.showSecurityIssues = showSecurityIssues
//        super.init(isShownAsSheet: isShownAsSheet,
//                   itemContent: itemContent,
//                   upgradeChecker: upgradeChecker)
//        if showSecurityIssues {
//            cancellable = getLoginSecurityIssues(itemId: itemContent.itemId)
//                .subscribe(on: DispatchQueue.global())
//                .receive(on: DispatchQueue.main)
//                .sink { [weak self] newSecurityIssues in
//                    guard let self else {
//                        return
//                    }
//                    securityIssues = newSecurityIssues
//                }
//
//            $securityIssues.receive(on: DispatchQueue.main)
//                .sink { [weak self] issues in
//                    guard let self, let issues else {
//                        return
//                    }
//                    if issues.contains(.reusedPasswords) {
//                        fetchSimilarPasswordItems()
//                    }
//                }.store(in: &cancellables)
//        }
//    }
//
//    override func bindValues() {
//        super.bindValues()
//        if case let .login(data) = itemContent.contentData {
//            passkeys = data.passkeys
//            name = itemContent.name
//            note = itemContent.note
//            parseAndSetUpEmailAndUsername(data: data)
//            password = data.password
//            passwordStrength = getPasswordStrength(password: password)
//            urls = data.urls
//            totpUri = data.totpUri
//            totpManager.bind(uri: data.totpUri)
//            getAliasItem(email: data.email)
//
//            if !data.totpUri.isEmpty {
//                checkTotpState()
//            } else {
//                totpTokenState = .allowed
//            }
//        } else {
//            fatalError("Expecting login type")
//        }
//    }
// }
//
//// MARK: - Private APIs
//
// private extension LogInDetailViewModel {
//    func getAliasItem(email: String) {
//        Task { [weak self] in
//            guard let self else { return }
//            do {
//                aliasItem = try await itemRepository.getAliasItem(email: email)
//            } catch {
//                handle(error)
//            }
//        }
//    }
//
//    func checkTotpState() {
//        Task { [weak self] in
//            guard let self else { return }
//            do {
//                if try await upgradeChecker.canShowTOTPToken(creationDate: itemContent.item.createTime) {
//                    totpTokenState = .allowed
//                } else {
//                    totpTokenState = .notAllowed
//                }
//            } catch {
//                handle(error)
//            }
//        }
//    }
//
//    func parseAndSetUpEmailAndUsername(data: LogInItemData) {
//        let result = setUpEmailAndUsername(container: data)
//        email = result.email
//        username = result.username
//    }
// }
//
//// MARK: - Public actions
//
// extension LogInDetailViewModel {

//    func viewPasskey(_ passkey: Passkey) {
//        router.present(for: .passkeyDetail(passkey))
//    }
//
//    func copyEmail() {
//        copyToClipboard(text: email, message: #localized("Email copied"))
//    }
//
//    func copyItemUsername() {
//        copyToClipboard(text: username, message: #localized("Username copied"))
//    }
//
//    func copyPassword() {
//        guard !password.isEmpty else { return }
//        copyToClipboard(text: password, message: #localized("Password copied"))
//    }
//

//
//    func showLargePassword() {
//        showLarge(.password(password))
//    }
//
//    func showAliasDetail() {
//        guard let aliasItem else { return }
//        do {
//            let itemContent = try aliasItem.getItemContent(symmetricKey: getSymmetricKey())
//            router.present(for: .itemDetail(itemContent,
//                                            automaticDisplay: true,
//                                            showSecurityIssues: false))
//        } catch {
//            handle(error)
//        }
//    }
//
//    func showDetail(for item: ItemContent) {
//        router.present(for: .itemDetail(item, automaticDisplay: false))
//    }
//
//    func showItemList() {
//        router.present(for: .passwordReusedItemList(itemContent))
//    }
//
//    func openUrl(_ urlString: String) {
//        router.navigate(to: .urlPage(urlString: urlString))
//    }
//
//    func fetchSimilarPasswordItems() {
//        Task { [weak self] in
//            guard let self else {
//                return
//            }
//            do {
//                reusedItems = try await passMonitorRepository.getItemsWithSamePassword(item: itemContent)
//            } catch {
//                handle(error)
//            }
//        }
//    }
// }
//
// extension SecurityWeakness {
//    var secureRowType: SecureRowType {
//        switch self {
//        case .excludedItems, .reusedPasswords, .weakPasswords:
//            .warning
//        case .missing2FA:
//            .info
//        case .breaches:
//            .danger
//        }
//    }
// }
