//
// CreateEditAliasViewModel.swift
// Proton Pass - Created on 05/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Entities
import Factory
import ProtonCoreLogin
import SwiftUI

extension Notification.Name {
    static let addedNewMailbox = Notification.Name(rawValue: "addedNewMailbox")
}

@MainActor
final class CreateEditAliasViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var prefix = ""
    @Published var prefixManuallyEdited = false
    @Published var note = ""
    @Published var simpleLoginNote = ""
    @Published var senderName = ""

    var suffix: String { suffixSelection.selectedSuffixString }
    var mailboxes: String { mailboxSelection.selectedMailboxesString }

    @Published private(set) var aliasEmail = ""
    @Published private(set) var state: State = .loading
    @Published private(set) var prefixError: AliasPrefixError?
    @Published private(set) var canCreateAlias = true
    @Published private(set) var showAdvancedOptionsTipBanner = false
    @Published var mailboxSelection: AliasLinkedMailboxSelection = .defaultEmpty
    @Published var suffixSelection: SuffixSelection = .defaultEmpty

    override var shouldUpgrade: Bool {
        if case .create = mode {
            return !canCreateAlias
        }
        return false
    }

    enum State {
        case loading
        case loaded
        case error(any Error)

        var isLoading: Bool {
            switch self {
            case .loading:
                true
            default:
                false
            }
        }
    }

    private(set) var alias: Alias?
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedRepositoryContainer.localItemDatasource) private var localItemDatasource
    @LazyInjected(\SharedUseCasesContainer.validateAliasPrefix) private var validateAliasPrefix
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) var getFeatureFlagStatus
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router

    let module = resolve(\SharedToolingContainer.module)

    var isAdvancedAliasManagementActive: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passAdvancedAliasManagementV1)
    }

    var isAliasOwner: Bool {
        alias?.mailboxes.isEmpty == false
    }

    var aliasDiscoveryActive: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passAliasDiscovery)
    }

    private var aliasDiscovery: AliasDiscovery {
        preferencesManager.sharedPreferences.unwrapped().aliasDiscovery
    }

    override var isSaveable: Bool {
        guard super.isSaveable else { return false }
        return switch mode {
        case .clone, .create:
            !title.isEmpty && !prefix.isEmpty && !suffix.isEmpty && !mailboxes.isEmpty && prefixError == nil
        case .edit:
            if isAliasOwner {
                !title.isEmpty && !mailboxes.isEmpty
            } else {
                !title.isEmpty
            }
        }
    }

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Share]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)

        if case let .edit(itemContent) = mode {
            title = itemContent.name
            note = itemContent.note
        }
        getAliasAndAliasOptions()
        checkAdvancedOptionsTipsDisplayEligibility()

        $prefix
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                validatePrefix()
            }
            .store(in: &cancellables)

        $title
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] title in
                guard let self, !self.prefixManuallyEdited else {
                    return
                }
                prefix = PrefixUtils.generatePrefix(fromTitle: title)
            }
            .store(in: &cancellables)

        $selectedVault
            .eraseToAnyPublisher()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                getAliasAndAliasOptions()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .addedNewMailbox)
            .sink { [weak self] _ in
                guard let self else { return }
                getAliasAndAliasOptions()
            }
            .store(in: &cancellables)
    }

    override var itemContentType: ItemContentType { .alias }

    override func generateItemContent() async -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: note,
                            itemUuid: UUID().uuidString,
                            data: .alias,
                            customFields: customFieldUiModels.map(\.customField))
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard let selectedSuffix = suffixSelection.selectedSuffix else { return nil }
        return .init(prefix: prefix,
                     suffix: selectedSuffix,
                     mailboxIds: mailboxSelection.selectedMailboxes.map(\.ID))
    }

    override func additionalEdit() async throws -> Bool {
        guard let alias, isAliasOwner, case let .edit(itemContent) = mode else { return false }

        var edited = false
        if Set(alias.mailboxes) != Set(mailboxSelection.selectedMailboxes) {
            let mailboxIds = mailboxSelection.selectedMailboxes.map(\.ID)
            try await changeMailboxes(shareId: itemContent.shareId,
                                      itemId: itemContent.item.itemID,
                                      mailboxIDs: mailboxIds)
            edited = true
        }

        let userId = try await userManager.getActiveUserId()

        if simpleLoginNote != alias.note {
            try await aliasRepository.updateSlAliasNote(userId: userId,
                                                        shareId: itemContent.shareId,
                                                        itemId: itemContent.itemId,
                                                        note: simpleLoginNote)
            edited = true
        }

        if senderName != alias.name {
            try await aliasRepository.updateSlAliasName(userId: userId,
                                                        shareId: itemContent.shareId,
                                                        itemId: itemContent.itemId,
                                                        name: senderName.nilIfEmpty)
            edited = true
        }

        return edited
    }

    private func validatePrefix() {
        do {
            try validateAliasPrefix(prefix: prefix)
            prefixError = nil
        } catch {
            prefixError = error as? AliasPrefixError
        }
    }
}

private extension CreateEditAliasViewModel {
    func checkAdvancedOptionsTipsDisplayEligibility() {
        Task { [weak self] in
            guard let self else { return }
            do {
                guard !aliasDiscovery.contains(.advancedOptions) else { return }
                let userId = try await userManager.getActiveUserId()
                let aliasCount = try await localItemDatasource.getAliasCount(userId: userId)
                // We assume that when users have more than 2 aliases, they're more or less
                // familiar with aliases so we can show tips for advanced options
                // Otherwise if users are new, we don't overwhelm them
                showAdvancedOptionsTipBanner = aliasCount > 2
            } catch {
                handle(error)
            }
        }
    }
}

// MARK: - Public actions

extension CreateEditAliasViewModel {
    func getAliasAndAliasOptions() {
        Task { [weak self] in
            guard let self else { return }
            do {
                state = .loading

                let shareId = selectedVault.shareId
                if case let .edit(itemContent) = mode {
                    let alias =
                        try await aliasRepository.getAliasDetails(shareId: shareId,
                                                                  itemId: itemContent.item.itemID)
                    aliasEmail = alias.email
                    simpleLoginNote = alias.note ?? ""
                    self.alias = alias
                    mailboxSelection.selectedMailboxes = alias.mailboxes
                    senderName = alias.name ?? ""
                    logger.info("Get alias successfully \(itemContent.debugDescription)")
                }

                if !mode.isEditMode || isAliasOwner {
                    let aliasOptions = try await getAliasOptions(shareId: shareId)

                    suffixSelection = .init(suffixes: aliasOptions.suffixes)
                    mailboxSelection = .init(allUserMailboxes: aliasOptions.mailboxes)
                    canCreateAlias = aliasOptions.canCreateAlias
                }

                state = .loaded
                logger.info("Get alias options successfully")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }

    func dismissAdvancedOptionsTipBanner() {
        Task { [weak self] in
            guard let self else { return }
            var aliasDiscovery = aliasDiscovery
            guard !aliasDiscovery.contains(.advancedOptions) else { return }
            aliasDiscovery.flip(.advancedOptions)
            do {
                try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                     value: aliasDiscovery)
                showAdvancedOptionsTipBanner = false
            } catch {
                handle(error)
            }
        }
    }

    func addMailbox() {
        if isFreeUser {
            router.present(for: .upselling(.default, .topMost))
        } else {
            router.present(for: .addMailbox)
        }
    }

    func addDomain() {
        router.navigate(to: .urlPage(urlString: "https://pass.proton.me/settings#aliases"))
    }
}

// MARK: - Private supporting tasks

private extension CreateEditAliasViewModel {
    func getAliasOptions(shareId: String) async throws -> AliasOptions {
        try await aliasRepository.getAliasOptions(shareId: shareId)
    }

    func changeMailboxes(shareId: String,
                         itemId: String,
                         mailboxIDs: [Int]) async throws {
        try await aliasRepository.changeMailboxes(shareId: shareId,
                                                  itemId: itemId,
                                                  mailboxIDs: mailboxIDs)
    }
}
