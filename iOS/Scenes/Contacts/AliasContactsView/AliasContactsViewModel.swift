//
//
// AliasContactsViewModel.swift
// Proton Pass - Created on 03/10/2024.
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
import DesignSystem
import Entities
import Factory
import Foundation
import Macro
import Screens
import UIKit

struct AliasContactsModel {
    let activeContacts: [AliasContact]
    let blockContacts: [AliasContact]

    static var `default`: AliasContactsModel {
        AliasContactsModel(activeContacts: [], blockContacts: [])
    }
}

@MainActor
final class AliasContactsViewModel: ObservableObject, Sendable {
    @Published var aliasName = ""
    @Published private(set) var displayName = ""
    @Published private(set) var showExplanation = false
    @Published private(set) var contactsInfos = AliasContactsModel.default
    @Published private(set) var updatingName = false
    @Published private(set) var loading = false

    var hasNoContact: Bool {
        contacts.contacts.isEmpty
    }

    private var contacts: PaginatedAliasContacts
    private var previousName = ""
    private(set) var alias: Alias
    private let infos: ContactsInfos
    @Published private(set) var plan: Plan?

    @LazyInjected(\SharedToolingContainer.preferencesManager) private var preferencesManager
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedRepositoryContainer.accessRepository) private var accessRepository

    private var cancellables = Set<AnyCancellable>()

    var itemIds: IDs {
        IDs(shareId: infos.shareId, itemId: infos.itemId)
    }

    var canManageAliases: Bool {
        plan?.manageAlias ?? false
    }

    init(infos: ContactsInfos) {
        contacts = infos.contacts
        self.infos = infos
        alias = infos.alias
        aliasName = alias.name ?? ""
        displayName = alias.displayName
        previousName = aliasName
        setUp()
        parseContacts()
    }

    func copyContact(_ contact: AliasContact) {
        router.action(.copyToClipboard(text: contact.email, message: #localized("Contact copied")))
    }

    // https://stackoverflow.com/questions/71260260/what-method-do-i-call-to-open-the-ios-mail-app-with-swiftui
    func openMail(emailTo: String) {
        let url = if let name = infos.alias.name {
            "\(name)<\(emailTo)>"
        } else {
            emailTo
        }
        if let url = URL(string: "mailto:\(url)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func delete(contact: AliasContact) {
        Task { [weak self] in
            guard let self else {
                return
            }
            
            defer {
                loading = false
            }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                _ = try await aliasRepository.deleteContact(userId: userId,
                                                            shareId: infos.shareId,
                                                            itemId: infos.itemId,
                                                            contactId: "\(contact.ID)")
                try await reloadContact()
            } catch {
                handle(error)
            }
        }
    }

    func toggleContactState(_ contact: AliasContact) {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                loading = false
            }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                _ = try await aliasRepository.updateContact(userId: userId,
                                                            shareId: infos.shareId,
                                                            itemId: infos.itemId,
                                                            contactId: "\(contact.ID)",
                                                            blocked: !contact.blocked)
                try await reloadContact()
            } catch {}
        }
    }

    func updateAliasName() {
        guard previousName != aliasName else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                updatingName = false
            }
            do {
                updatingName = true
                let userId = try await userManager.getActiveUserId()
                try await aliasRepository.updateSlAliasName(userId: userId,
                                                            shareId: infos.shareId,
                                                            itemId: infos.itemId,
                                                            name: aliasName.nilIfEmpty)
                previousName = aliasName
                router.display(element: .infosMessage(#localized("Your sender name was updated to %@", aliasName)))
            } catch {
                aliasName = previousName
                handle(error)
            }
        }
    }

    func timeSinceCreation(from timestamp: Int) -> String {
        // Convert timestamp (in seconds) to Date
        let creationDate = Date(timeIntervalSince1970: TimeInterval(timestamp))

        let currentDate = Date()

        // Define the calendar and components
        let calendar = Calendar.current

        // Calculate the difference between the two dates
        let components = calendar.dateComponents([.year, .month, .day], from: creationDate, to: currentDate)

        // Localized string components
        let yearsString = if let years = components.year {
            #localized("%lld years", years)
        } else {
            ""
        }
        let monthsString = if let months = components.month {
            #localized("%lld months", months)
        } else {
            ""
        }

        let daysString = if let days = components.day {
            #localized("%lld day(s)", days)
        } else {
            ""
        }

        let timeComponents = [yearsString, monthsString, daysString].filter { !$0.isEmpty }.joined(separator: ", ")

        return #localized("Contact created %@ ago.", timeComponents)
    }

    func upsell() {
        let config = UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                                title: #localized("Manage your aliases"),
                                                description: UpsellEntry.aliasManagement.description,
                                                upsellElements: UpsellEntry.aliasManagement.upsellElements,
                                                ctaTitle: #localized("Get Pass Unlimited"))
        router
            .present(for: .upselling(config, .none))
    }
}

private extension AliasContactsViewModel {
    func setUp() {
        let access = accessRepository.access.value?.access
        plan = access?.plan

        if !preferencesManager.appPreferences.unwrapped().hasVisitedContactPage {
            Task { [weak self] in
                guard let self else { return }
                try? await preferencesManager.updateAppPreferences(\.hasVisitedContactPage, value: true)
                showExplanation = true
            }
        }

        aliasRepository.contactsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else {
                    return
                }
                Task { [weak self] in
                    guard let self else {
                        return
                    }
                    try? await reloadContact()
                }
            }
            .store(in: &cancellables)

        accessRepository.access
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedAccess in
                guard let self else {
                    return
                }
                plan = updatedAccess.access.plan
            }
            .store(in: &cancellables)
    }

    func reloadContact() async throws {
        let userId = try await userManager.getActiveUserId()
        contacts = try await aliasRepository.getContacts(userId: userId,
                                                         shareId: infos.shareId,
                                                         itemId: infos.itemId,
                                                         lastContactId: nil)
        parseContacts()
    }

    func parseContacts() {
        var activeContacts: [AliasContact] = []
        var blockContacts: [AliasContact] = []

        for contact in contacts.contacts {
            if contact.blocked {
                blockContacts.append(contact)
            } else {
                activeContacts.append(contact)
            }
        }

        contactsInfos = AliasContactsModel(activeContacts: activeContacts, blockContacts: blockContacts)
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
