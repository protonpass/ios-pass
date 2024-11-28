//
// CreateEditVaultViewModel.swift
// Proton Pass - Created on 23/03/2023.
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
import Entities
import Factory
import Macro
import ProtonCoreLogin
import Screens

enum VaultColorIcon {
    case color(VaultColor)
    case icon(VaultIcon)

    static var allCases: [VaultColorIcon] {
        let colors = VaultColor.allCases.map { VaultColorIcon.color($0) }
        let icons = VaultIcon.allCases.map { VaultColorIcon.icon($0) }
        return colors + icons
    }
}

enum VaultMode {
    case create
    case editExistingVault(Vault)
    case editNewVault(VaultContent, ItemContent)

    var isCreation: Bool {
        if case .create = self {
            return true
        }
        return false
    }
}

@MainActor
protocol CreateEditVaultViewModelDelegate: AnyObject {
    func createEditVaultViewModelDidEditVault()
}

@MainActor
final class CreateEditVaultViewModel: ObservableObject {
    @Published private(set) var canCreateOrEdit = true
    @Published var selectedColor: VaultColor
    @Published var selectedIcon: VaultIcon
    @Published var title: String
    @Published private(set) var loading = false
    @Published private(set) var finishSaving = false

    private let mode: VaultMode
    private let logger = resolve(\SharedToolingContainer.logger)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let createVaultUseCase = resolve(\UseCasesContainer.createVault)
    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    weak var delegate: (any CreateEditVaultViewModelDelegate)?

    var saveButtonTitle: String {
        switch mode {
        case .create:
            #localized("Create vault")
        case .editExistingVault:
            #localized("Save")
        case .editNewVault:
            #localized("Update vault")
        }
    }

    init(mode: VaultMode) {
        self.mode = mode
        switch mode {
        case .create:
            selectedColor = .color1
            selectedIcon = .icon1
            title = ""
        case let .editExistingVault(vault):
            selectedColor = vault.displayPreferences.color.color
            selectedIcon = vault.displayPreferences.icon.icon
            title = vault.name
        case let .editNewVault(vault, _):
            selectedColor = vault.display.color.color
            selectedIcon = vault.display.icon.icon
            title = vault.name
        }
        verifyLimitation()
    }
}

// MARK: - Private APIs

private extension CreateEditVaultViewModel {
    func verifyLimitation() {
        Task { [weak self] in
            guard let self, mode.isCreation else { return }
            do {
                canCreateOrEdit = try await upgradeChecker.canCreateMoreVaults()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func generateVaultProtobuf() -> VaultContent {
        .init(name: title,
              description: "",
              color: selectedColor.protobufColor,
              icon: selectedIcon.protobufIcon)
    }

    func editVault(_ oldVault: Vault) {
        Task { [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                logger.trace("Editing vault \(oldVault.id)")
                loading = true
                try await shareRepository.edit(oldVault: oldVault,
                                               newVault: generateVaultProtobuf())
                delegate?.createEditVaultViewModelDidEditVault()
                logger.info("Edited vault \(oldVault.id)")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func createVault() {
        Task { [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                logger.trace("Creating vault")
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await createVaultUseCase(userId: userId, with: generateVaultProtobuf())
                router.display(element: .successMessage(#localized("Vault created"),
                                                        config: .dismissAndRefresh))
                logger.info("Created vault")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

// MARK: - Public APIs

extension CreateEditVaultViewModel {
    func save() {
        switch mode {
        case .create:
            createVault()
        case let .editExistingVault(vault):
            editVault(vault)
        case let .editNewVault(_, itemContent):
            setShareInviteVault(with: .new(generateVaultProtobuf(), itemContent))
            finishSaving = true
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }
}

extension VaultColorIcon: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case let .color(color):
            hasher.combine(color)
        case let .icon(icon):
            hasher.combine(icon)
        }
    }
}

extension VaultColor {
    var protobufColor: ProtonPassVaultV1_VaultColor {
        switch self {
        case .color1: .color1
        case .color2: .color2
        case .color3: .color3
        case .color4: .color4
        case .color5: .color5
        case .color6: .color6
        case .color7: .color7
        case .color8: .color8
        case .color9: .color9
        case .color10: .color10
        }
    }
}

extension VaultIcon {
    var protobufIcon: ProtonPassVaultV1_VaultIcon {
        switch self {
        case .icon1: .icon1
        case .icon2: .icon2
        case .icon3: .icon3
        case .icon4: .icon4
        case .icon5: .icon5
        case .icon6: .icon6
        case .icon7: .icon7
        case .icon8: .icon8
        case .icon9: .icon9
        case .icon10: .icon10
        case .icon11: .icon11
        case .icon12: .icon12
        case .icon13: .icon13
        case .icon14: .icon14
        case .icon15: .icon15
        case .icon16: .icon16
        case .icon17: .icon17
        case .icon18: .icon18
        case .icon19: .icon19
        case .icon20: .icon20
        case .icon21: .icon21
        case .icon22: .icon22
        case .icon23: .icon23
        case .icon24: .icon24
        case .icon25: .icon25
        case .icon26: .icon26
        case .icon27: .icon27
        case .icon28: .icon28
        case .icon29: .icon29
        case .icon30: .icon30
        }
    }
}
