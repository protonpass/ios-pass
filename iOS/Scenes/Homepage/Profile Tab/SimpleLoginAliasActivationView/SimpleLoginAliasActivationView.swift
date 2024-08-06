//
//
// SimpleLoginAliasActivationView.swift
// Proton Pass - Created on 05/08/2024.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct SimpleLoginAliasActivationView: View {
    @StateObject private var viewModel = SimpleLoginAliasActivationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showVaultSelectionSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            SelectedSyncVaultRow(vault: viewModel.selectedVault?.vault) {
                showVaultSelectionSheet.toggle()
            }
//            .padding(.horizontal)
//            Button(action: {
//                showVaultSelectionSheet.toggle()
//            }, label: {
//                SelectedSyncVaultRow(vault: viewModel.selectedVault?.vault)
//                    .padding(.horizontal)
//            })
//            .buttonStyle(.plain)
//            .roundedEditableSection()
//            .padding(.bottom, 10)

            Text("SimpleLogin aliases will be imported into this vault.")
                .font(.footnote)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
//        .animation(.default, value: viewModel.selectedVault)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .navigationTitle("Sync Aliases")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .sheet(isPresented: $showVaultSelectionSheet) {
            VaultSelectionView(selectedVault: $viewModel.selectedVault,
                               vaults: viewModel.vaults)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .showSpinner(viewModel.loading)
        .navigationStackEmbeded()
    }

//    func selectedVault(vault: Vault?) -> some View {
//        HStack(spacing: 16) {
//            if let vault {
//                VaultThumbnail(vault: vault)
//            }
//
//            VStack(alignment: .leading) {
//                Text("Default SimpleLogin vault")
//                    .font(.callout)
//                    .foregroundStyle(PassColor.textWeak.toColor)
//
//                Text(vault?.name ?? "None")
//                    .foregroundStyle(PassColor.textNorm.toColor)
//            }
//            Spacer()
//
//            Image(uiImage: IconProvider.chevronRight)
//                .resizable()
//                .scaledToFit()
//                .foregroundStyle(PassColor.textWeak.toColor)
//                .frame(maxHeight: 20)
//        }
//        .frame(maxWidth: .infinity)
//        .frame(height: 70)
//        .contentShape(.rect)
//    }
}

private extension SimpleLoginAliasActivationView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor1,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Confirm"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canActiveSync,
                                        height: 44) {
                Task {
                    do {
                        try await viewModel.activateSync()
                        dismiss()
                    } catch {
                        return
                    }
                }
            }
        }
    }
}

struct SimpleLoginAliasActivationView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleLoginAliasActivationView()
    }
}

// import DesignSystem
// import Entities
// import Factory
// import ProtonCoreUIFoundations
// import SwiftUI

// MailboxSelectionView(mailboxSelection: mailboxSelection,
//                     title: title)

// public struct VaultSelectionView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Binding var selectedVault: VaultListUiModel?
//    public let vaults: [VaultListUiModel]
//
//    public init(selectedVault: Binding<VaultListUiModel?>, vaults: [VaultListUiModel]) {
//        _selectedVault = selectedVault
//        self.vaults = vaults
//    }
//
//    public var body: some View {
//        NavigationStack {
//            // ZStack instead of VStack because of SwiftUI bug.
//            // See more in "CreateAliasLiteView.swift"
////            ZStack(alignment: .bottom) {
//            ScrollView {
//                LazyVStack(spacing: 0) {
//                    ForEach(vaults, id: \.vault.id) { vault in
//                        let isSelected = vault == selectedVault
//                        Button(action: {
//                            selectedVault = vault
//                            dismiss()
//                        }, label: {
//                            VaultRow(thumbnail: { VaultThumbnail(vault: vault.vault) },
//                                     title: vault.vault.name,
//                                     itemCount: vault.itemCount,
//                                     isShared: vault.vault.shared,
//                                     isSelected: isSelected,
//                                     height: 74)
//                                .padding(.horizontal)
//                        })
//                        .buttonStyle(.plain)
//
////                            let isSelected = mailboxSelection.selectedMailboxes.contains(mailbox)
////                            HStack {
////                                Text(mailbox.email)
////                                    .foregroundStyle(isSelected ?
////                                        PassColor.loginInteractionNormMajor2.toColor : PassColor
////                                        .textNorm.toColor)
////                                Spacer()
////
////                                if isSelected {
////                                    Image(uiImage: IconProvider.checkmark)
////                                        .foregroundStyle(PassColor.loginInteractionNormMajor2.toColor)
////                                }
////                            }
////                            .contentShape(.rect)
////                            .background(Color.clear)
////                            .padding(.horizontal)
////                            .frame(height: OptionRowHeight.compact.value)
////                            .onTapGesture {
////                                mailboxSelection.selectedMailboxes.insertOrRemove(mailbox, minItemCount: 1)
////                            }
////
////                            PassDivider()
////                                .padding(.horizontal)
//                    }
//
//                    // Gimmick view to take up space
//                    closeButton
//                        .opacity(0)
//                        .padding()
//                        .disabled(true)
//                }
//            }
//
////                closeButton
////                    .padding()
////            }
//            .background(PassColor.backgroundWeak.toColor)
//            .navigationBarTitleDisplayMode(.inline)
//            .animation(.default, value: selectedVault)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Select a default vault for aliases sync")
//                        .adaptiveForegroundStyle(PassColor.textNorm.toColor)
//
////                        .navigationTitleText()
//                }
//            }
//        }
//    }
//
//    private var closeButton: some View {
//        Button(action: dismiss.callAsFunction) {
//            Text("Close")
//                .foregroundStyle(PassColor.textNorm.toColor)
//        }
//    }
// }

//
//
// import DesignSystem
// import Entities
// import Factory
// import SwiftUI
//
// struct VaultSelectorView: View {
//    @Environment(\.dismiss) private var dismiss
//    let viewModel: VaultSelectorViewModel
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                if viewModel.isFreeUser {
//                    LimitedVaultOperationsBanner(onUpgrade: { viewModel.upgrade() })
//                        .padding([.horizontal, .top])
//                }
//
//                ScrollView {
//                    VStack(spacing: 0) {
//                        ForEach(viewModel.allVaults, id: \.hashValue) { vault in
//                            view(for: vault)
//                            PassDivider()
//                                .padding(.horizontal)
//                        }
//                    }
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .background(PassColor.backgroundWeak.toColor)
//            .animation(.default, value: viewModel.isFreeUser)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Select a vault")
//                        .navigationTitleText()
//                }
//            }
//        }
//    }
//
//    @MainActor
//    private func view(for vault: VaultListUiModel) -> some View {
//        Button(action: {
//            viewModel.select(vault: vault.vault)
//            dismiss()
//        }, label: {
//            VaultRow(thumbnail: { VaultThumbnail(vault: vault.vault) },
//                     title: vault.vault.name,
//                     itemCount: vault.itemCount,
//                     isShared: vault.vault.shared,
//                     isSelected: viewModel.isSelected(vault: vault.vault),
//                     height: 74)
//                .padding(.horizontal)
//        })
//        .buttonStyle(.plain)
//        .opacityReduced(!vault.vault.canEdit)
//    }
// }
//
//
//
// import Client
// import Combine
// import Core
// import Entities
// import Factory
//
// @MainActor
// final class VaultSelectorViewModel: ObservableObject, DeinitPrintable {
//    deinit { print(deinitMessage) }
//
//    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
//    private let logger = resolve(\SharedToolingContainer.logger)
//    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
//    private let getMainVault = resolve(\SharedUseCasesContainer.getMainVault)
//    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
//
//    let allVaults: [VaultListUiModel]
//
//    @Published private(set) var selectedVault: Vault?
//    @Published private(set) var isFreeUser = false
//
//    init() {
//        allVaults = vaultsManager.getAllEditableVaultContents().map { .init(vaultContent: $0) }
//        selectedVault = vaultsManager.vaultSelection.preciseVault
//
//        setup()
//    }
//
//    nonisolated func select(vault: Vault) {
//        vaultsManager.select(.precise(vault))
//    }
//
//    func isSelected(vault: Vault) -> Bool {
//        vault.shareId == selectedVault?.shareId
//    }
//
//    func upgrade() {
//        router.present(for: .upgradeFlow)
//    }
// }
//
// private extension VaultSelectorViewModel {
//    func setup() {
//        Task { [weak self] in
//            guard let self else { return }
//            guard allVaults.count > 1 else { return }
//            do {
//                isFreeUser = try await upgradeChecker.isFreeUser()
//                if isFreeUser, let mainVault = await getMainVault() {
//                    selectedVault = mainVault
//                }
//            } catch {
//                logger.error(error)
//                router.display(element: .displayErrorBanner(error))
//            }
//        }
//    }
// }
