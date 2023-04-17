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
import Core
import ProtonCore_Login

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
    case edit(Vault)
}

protocol CreateEditVaultViewModelDelegate: AnyObject {
    func createEditVaultViewModelWantsToShowSpinner()
    func createEditVaultViewModelWantsToHideSpinner()
    func createEditVaultViewModelDidCreateVault()
    func createEditVaultViewModelDidEditVault()
    func createEditVaultViewModelDidEncounter(error: Error)
}

final class CreateEditVaultViewModel: ObservableObject {
    @Published var selectedColor: VaultColor
    @Published var selectedIcon: VaultIcon
    @Published var title: String

    private let mode: VaultMode
    private let logger: Logger
    private let shareRepository: ShareRepositoryProtocol
    let theme: Theme

    weak var delegate: CreateEditVaultViewModelDelegate?

    var saveButtonTitle: String {
        switch mode {
        case .create:
            return "Create vault"
        case .edit:
            return "Save"
        }
    }

    init(mode: VaultMode,
         shareRepository: ShareRepositoryProtocol,
         logManager: LogManager,
         theme: Theme) {
        self.mode = mode
        switch mode {
        case .create:
            selectedColor = .color1
            selectedIcon = .icon1
            title = ""
        case .edit(let vault):
            selectedColor = vault.displayPreferences.color.color
            selectedIcon = vault.displayPreferences.icon.icon
            title = vault.name
        }

        self.logger = .init(manager: logManager)
        self.shareRepository = shareRepository
        self.theme = theme
    }
}

// MARK: - Private APIs
private extension CreateEditVaultViewModel {
    func generateVaultProtobuf() -> VaultProtobuf {
        .init(name: title,
              description: "",
              color: selectedColor.protobufColor,
              icon: selectedIcon.protobufIcon)
    }

    func editVault(_ oldVault: Vault) {
        Task { @MainActor in
            defer { delegate?.createEditVaultViewModelWantsToHideSpinner() }
            do {
                logger.trace("Editing vault \(oldVault.id)")
                delegate?.createEditVaultViewModelWantsToShowSpinner()
                try await shareRepository.edit(oldVault: oldVault, newVault: generateVaultProtobuf())
                delegate?.createEditVaultViewModelDidEditVault()
                logger.info("Edited vault \(oldVault.id)")
            } catch {
                logger.error(error)
                delegate?.createEditVaultViewModelDidEncounter(error: error)
            }
        }
    }

    func createVault() {
        Task { @MainActor in
            defer { delegate?.createEditVaultViewModelWantsToHideSpinner() }
            do {
                logger.trace("Creating vault")
                delegate?.createEditVaultViewModelWantsToShowSpinner()
                try await shareRepository.createVault(generateVaultProtobuf())
                delegate?.createEditVaultViewModelDidCreateVault()
                logger.info("Created vault")
            } catch {
                logger.error(error)
                delegate?.createEditVaultViewModelDidEncounter(error: error)
            }
        }
    }
}

// MARK: - Public APIs
extension CreateEditVaultViewModel {
    func save() {
        switch mode {
        case .edit(let vault):
            editVault(vault)
        case .create:
            createVault()
        }
    }
}

extension VaultColorIcon: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .color(let color):
            hasher.combine(color)
        case .icon(let icon):
            hasher.combine(icon)
        }
    }
}

extension VaultColor {
    var protobufColor: ProtonPassVaultV1_VaultColor {
        switch self {
        case .color1: return .color1
        case .color2: return .color2
        case .color3: return .color3
        case .color4: return .color4
        case .color5: return .color5
        case .color6: return .color6
        case .color7: return .color7
        case .color8: return .color8
        case .color9: return .color9
        case .color10: return .color10
        }
    }
}

extension VaultIcon {
    var protobufIcon: ProtonPassVaultV1_VaultIcon {
        switch self {
        case .icon1: return .icon1
        case .icon2: return .icon2
        case .icon3: return .icon3
        case .icon4: return .icon4
        case .icon5: return .icon5
        case .icon6: return .icon6
        case .icon7: return .icon7
        case .icon8: return .icon8
        case .icon9: return .icon9
        case .icon10: return .icon10
        case .icon11: return .icon11
        case .icon12: return .icon12
        case .icon13: return .icon13
        case .icon14: return .icon14
        case .icon15: return .icon15
        case .icon16: return .icon16
        case .icon17: return .icon17
        case .icon18: return .icon18
        case .icon19: return .icon19
        case .icon20: return .icon20
        case .icon21: return .icon21
        case .icon22: return .icon22
        case .icon23: return .icon23
        case .icon24: return .icon24
        case .icon25: return .icon25
        case .icon26: return .icon26
        case .icon27: return .icon27
        case .icon28: return .icon28
        case .icon29: return .icon29
        case .icon30: return .icon30
        }
    }
}
