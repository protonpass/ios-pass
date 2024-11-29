//
// TrashItemsSection.swift
// Proton Pass - Created on 05/05/2023.
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
import DesignSystem
import Entities
import Factory
import SwiftUI

struct TrashItemsSection: View {
    init() {}

    var body: some View {
        NavigationLink(destination: {
            TrashItemsView()
        }, label: {
            Text(verbatim: "Trash all items")
        })
    }
}

private struct TrashItemsView: View {
    @StateObject private var viewModel = TrashItemsViewModel()
    @State private var selectedVault: VaultListUiModel?

    init() {}

    var body: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case let .loaded(uiModels):
            vaultList(uiModels)
        case let .error(error):
            RetryableErrorView(errorMessage: error.localizedDescription,
                               onRetry: viewModel.loadVaults)
        }
    }

    @ViewBuilder
    private func vaultList(_ uiModels: [VaultListUiModel]) -> some View {
        let showingAlert = Binding<Bool>(get: {
            selectedVault != nil
        }, set: { newValue in
            if !newValue {
                selectedVault = nil
            }
        })
        Form {
            Section(content: {
                ForEach(uiModels, id: \.hashValue) { uiModel in
                    let vault = uiModel.vault
                    let icon = vault.vaultBigIcon
                    let color = vault.mainColor

                    VStack {
                        Button(action: {
                            selectedVault = uiModel
                        }, label: {
                            VaultRow(thumbnail: {
                                         CircleButton(icon: icon,
                                                      iconColor: color,
                                                      backgroundColor: color.withAlphaComponent(0.16))
                                     },
                                     title: vault.name,
                                     itemCount: uiModel.itemCount,
                                     isShared: uiModel.vault.shared,
                                     isSelected: false,
                                     height: 44)
                        })
                        .buttonStyle(.plain)

                        Text(vault.shareId)
                            .foregroundStyle(PassColor.textWeak.toColor)
                            .font(.caption)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }, header: {
                Text(verbatim: "\(uiModels.count) vault(s) in total")
            })
        }
        .navigationTitle(Text(verbatim: "Select to trash all items"))
        .alert(Text(verbatim: "Trash all items"),
               isPresented: showingAlert,
               actions: {
                   Button(role: .cancel, label: { Text(verbatim: "Cancel") })
                   Button(role: .destructive,
                          action: {
                              if let selectedVault {
                                  viewModel.trashItems(for: selectedVault.vault)
                              }
                          },
                          label: {
                              Text(verbatim: "Yes")
                          })
               },
               message: {
                   if let selectedVault {
                       Text(verbatim: "Vault \"\(selectedVault.vault.name)\" with \(selectedVault.itemCount) item(s)")
                   }
               })
    }
}

@MainActor
private final class TrashItemsViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([VaultListUiModel])
        case error(any Error)
    }

    @Published private(set) var state = State.loading

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let bannerManager = resolve(\SharedViewContainer.bannerManager)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    init() {
        loadVaults()
    }

    func loadVaults() {
        Task { [weak self] in
            guard let self else { return }
            do {
                state = .loading
                let userId = try await userManager.getActiveUserId()
                let items = try await itemRepository.getAllItems(userId: userId)
                let vaults = try await shareRepository.getVaults(userId: userId)

                let vaultListUiModels: [VaultListUiModel] = vaults.map { vault in
                    let activeItems =
                        items.filter { $0.item.itemState == .active && $0.shareId == vault.shareId }
                    return .init(vault: vault, itemCount: activeItems.count)
                }
                state = .loaded(vaultListUiModels)
            } catch {
                state = .error(error)
            }
        }
    }

    func trashItems(for vault: Share) {
        Task { [weak self] in
            guard let self else { return }
            do {
                bannerManager.displayBottomInfoMessage("Trashing all items of \"\(vault.name)\"")
                let items = try await itemRepository.getItems(shareId: vault.shareId,
                                                              state: .active)
                try await itemRepository.trashItems(items)
                loadVaults()
                bannerManager.displayBottomSuccessMessage("Trashed all items of \"\(vault.name)\"")
            } catch {
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }
}
