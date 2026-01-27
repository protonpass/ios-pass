//
// MoveVaultListView.swift
// Proton Pass - Created on 29/03/2023.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct MoveVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MoveVaultListViewModel
    @State private var containersExtended = Set<String>()

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .center) {
                Text("Select a vault")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm)

                if viewModel.showWarning {
                    // swiftlint:disable:next line_length
                    Label("When moving items between vaults we will preserve up to the last 50 modifications performed to each item",
                          systemImage: "info.circle.fill")
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(PassColor.backgroundNorm)
                        .cornerRadius(12)

                    Divider()
                        .padding(.top, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.top, 30)

            if viewModel.isFreeUser {
                LimitedVaultOperationsBanner(onUpgrade: { viewModel.upgrade() })
                    .padding([.horizontal, .top])
            }

//            ScrollView {
//                VStack(spacing: 0) {
//                    ForEach(viewModel.allSharesContent) { vault in
//
//                        if let vaultContent = vault.share.vaultContent {
//                            vaultRow(for: vault, vaultContent: vaultContent)
//                            if vault != viewModel.allVaults.last {
//                                PassDivider()
//                            }
//                        }
//
//
//                    }
//                }
//                .padding(.horizontal)
//            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.allSharesContent) { shareContent in
                        fullRow(content: shareContent)
                        if shareContent != viewModel.allSharesContent.last {
                            PassDivider()
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 16) {
                CapsuleTextButton(title: #localized("Cancel"),
                                  titleColor: PassColor.textWeak,
                                  backgroundColor: PassColor.textDisabled,
                                  height: 44,
                                  action: dismiss.callAsFunction)

                DisablableCapsuleTextButton(title: #localized("Confirm"),
                                            titleColor: PassColor.textInvert,
                                            disableTitleColor: PassColor.textHint,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: viewModel.selectedContainer == nil,
                                            height: 44,
                                            action: { dismiss(); viewModel.doMove() })
            }
            .padding([.bottom, .horizontal])
        }
        .background(PassColor.backgroundWeak)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.default, value: viewModel.isFreeUser)
    }

//    private func vaultRow(for vault: ShareContent, vaultContent: VaultContent) -> some View {
//        Button(action: {
//            viewModel.selectedVault = vault
//        }, label: {
//            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
//                     title: vaultContent.name,
//                     itemCount: vault.itemCount,
//                     mode: .view(isSelected: viewModel.selectedVault == vault,
//                                 isHidden: vault.share.hidden,
//                                 action: nil))
//        })
//        .buttonStyle(.plain)
//        .opacityReduced(!vault.share.canEdit)
//    }
//
    @ViewBuilder
    private func fullRow(content: ShareContent) -> some View {
        if let vaultContent = content.share.vaultContent {
            HStack {
                if let folders = content.folders(in: content.id), !folders.isEmpty {
                    Button { toggleDisplayContainerContent(containerId: content.id) } label: {
                        (containersExtended.contains(content.id) ?
                            IconProvider.chevronDownFilled : IconProvider.chevronRightFilled)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(PassColor.textWeak)
                    }
                    .buttonStyle(.plain)
                }
                view(for: content, vaultContent: vaultContent)
            }

            if let folders = content.folders(in: content.id),
               !folders.isEmpty, containersExtended.contains(content.id) {
                SmallFolderTreeRowBis(content: content,
                                      share: content.share,
                                      folders: folders,
                                      containersExtended: $containersExtended,
                                      selectedContainer: $viewModel.selectedContainer)
            }
        }
    }

    private func toggleDisplayContainerContent(containerId: String) {
        if containersExtended.contains(containerId) {
            print("Woot remove container: \(containerId)")
            containersExtended.remove(containerId)
        } else {
            print("Woot add container: \(containerId)")
            containersExtended.insert(containerId)
        }
    }

    private func view(for vaultInfos: ShareContent, vaultContent: VaultContent) -> some View {
        Button(action: {
            viewModel
                .selectedContainer = ShareSelectionPayload(share: vaultInfos.share,
                                                           folder: nil) // vaultInfos.share
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vaultInfos.itemCount,
                     mode: .view(isSelected: viewModel.selectedContainer?.share == vaultInfos.share,
                                 isHidden: vaultInfos.share.hidden,
                                 action: nil),
                     height: 74)
        })
        .buttonStyle(.plain)
    }
}

struct SmallFolderTreeRowBis: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: ShareContent
    let share: Share
    let folders: [FolderUiModel]
    @Binding var containersExtended: Set<String>
    @Binding var selectedContainer: ShareSelectionPayload?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(folders) { folder in
                row(for: folder)
                    .padding(.vertical, 12)

                if shouldShowSubfolders(of: folder),
                   let subFolders = content.folders(in: folder.id) {
                    SmallFolderTreeRowBis(content: content,
                                          share: share,
                                          folders: subFolders,
                                          containersExtended: $containersExtended,
                                          selectedContainer: $selectedContainer)
                }
            }
        }
        .padding(.leading, 8)
    }

    private func toggleDisplayContainerContent(containerId: String) {
        if containersExtended.contains(containerId) {
            print("Woot remove container: \(containerId)")
            containersExtended.remove(containerId)
        } else {
            print("Woot add container: \(containerId)")
            containersExtended.insert(containerId)
        }
    }
}

private extension SmallFolderTreeRowBis {
    func row(for folder: FolderUiModel) -> some View {
        HStack {
            disclosureButton(for: folder)
            folderButton(for: folder)
        }
    }

    @ViewBuilder
    func disclosureButton(for folder: FolderUiModel) -> some View {
        if let subfolders = content.folders(in: folder.id), !subfolders.isEmpty {
            Button {
                toggleDisplayContainerContent(containerId: folder.id)
            } label: {
                (containersExtended.contains(folder.id)
                    ? IconProvider.chevronDownFilled
                    : IconProvider.chevronRightFilled)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(PassColor.textWeak)
            }
            .buttonStyle(.plain)
        } else {
            Text("")
                .frame(width: 30, height: 30)
        }
    }

    func folderButton(for folder: FolderUiModel) -> some View {
        HStack {
            Button {
                selectedContainer = ShareSelectionPayload(share: share, folder: folder)
            } label: {
                HStack {
                    ZStack(alignment: .bottomTrailing) {
                        IconProvider.foldersFilled
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color(hex: "#E9A944"))
                        if selectedContainer?.folder == folder {
                            IconProvider.checkmark
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(PassColor.textInvert)
                                .padding(1)
                                .background(colorScheme == .dark ?
                                    PassColor.interactionNormMajor2 : PassColor.interactionNorm)
                                .frame(height: 15)
                                .clipShape(Circle())
                                .offset(x: 5, y: 5)
                        }
                    }

                    Text(folder.content.name)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    func shouldShowSubfolders(of folder: FolderUiModel) -> Bool {
        containersExtended.contains(folder.id)
    }
}

//
// if case let .view(isSelected, isHidden, _) = mode, isSelected || isHidden {
//    let icon: Image? = if isSelected {
//        IconProvider.checkmark
//    } else if isHidden {
//        IconProvider.eyeSlash
//    } else {
//        nil
//    }
//
//    if let icon {
//        icon
//            .resizable()
//            .scaledToFit()
//            .foregroundStyle(PassColor.textInvert)
//            .padding(3)
//            .background(colorScheme == .dark ?
//                PassColor.interactionNormMajor2 : PassColor.interactionNorm)
//            .frame(height: 20)
//            .clipShape(Circle())
//            .offset(x: 5, y: 5)
//    }
// }
// }

//
//
////
//// VaultSelectorView.swift
//// Proton Pass - Created on 12/04/2023.
//// Copyright (c) 2023 Proton Technologies AG
////
//// This file is part of Proton Pass.
////
//// Proton Pass is free software: you can redistribute it and/or modify
//// it under the terms of the GNU General Public License as published by
//// the Free Software Foundation, either version 3 of the License, or
//// (at your option) any later version.
////
//// Proton Pass is distributed in the hope that it will be useful,
//// but WITHOUT ANY WARRANTY; without even the implied warranty of
//// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//// GNU General Public License for more details.
////
//// You should have received a copy of the GNU General Public License
//// along with Proton Pass. If not, see https://www.gnu.org/licenses/.
//
// import DesignSystem
// import Entities
// import FactoryKit
// import ProtonCoreUIFoundations
// import Screens
// import SwiftUI
//
// struct VaultSelectorView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Binding var selectedContainer: ShareSelectionPayload
//    let isFreeUser: Bool
//    let onUpgrade: () -> Void
//
//    @State private var containersExtended = Set<String>()
//
//    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
//
//    private var shares: [ShareContent] {
//        appContentManager
//            .getAllEditableVaultContents()
//            .sortedByHidden()
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                if isFreeUser {
//                    LimitedVaultOperationsBanner(onUpgrade: onUpgrade)
//                        .padding([.horizontal, .top])
//                }
//
//                ScrollView {
//                    VStack(spacing: 0) {
//                        ForEach(shares) { shareContent in
//                            fullRow(content: shareContent)
//                                .padding(.horizontal)
//                            if shareContent != shares.last {
//                                PassDivider()
//                                    .padding(.horizontal)
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .background(PassColor.backgroundWeak)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Select a vault")
//                        .navigationTitleText()
//                }
//            }
//        }
//    }
//
//    private func view(for vaultInfos: ShareContent, vaultContent: VaultContent) -> some View {
//        Button(action: {
//            // TODO: prendre en compte les folder
//            selectedContainer = ShareSelectionPayload(share: vaultInfos.share, folder: nil) // vaultInfos.share
//            dismiss()
//        }, label: {
//            // TODO: update view to take into account folder
//            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
//                     title: vaultContent.name,
//                     itemCount: vaultInfos.itemCount,
//                     mode: .view(isSelected: selectedContainer.share == vaultInfos.share,
//                                 isHidden: vaultInfos.share.hidden,
//                                 action: nil),
//                     height: 74)
//        })
//        .buttonStyle(.plain)
//    }
//
//    @ViewBuilder
//    private func fullRow(content: ShareContent) -> some View {
//        if let vaultContent = content.share.vaultContent {
//            HStack {
//                if let folders = content.folders(in: content.id), !folders.isEmpty {
//                    Button { toggleDisplayContainerContent(containerId: content.id) } label: {
//                        (containersExtended.contains(content.id) ?
//                            IconProvider.chevronDownFilled : IconProvider.chevronRightFilled)
//                            .resizable()
//                            .frame(width: 30, height: 30)
//                            .foregroundStyle(PassColor.textWeak)
//                    }
//                    .buttonStyle(.plain)
//                }
//                view(for: content, vaultContent: vaultContent)
//            }
//
//            if let folders = content.folders(in: content.id),
//               !folders.isEmpty, containersExtended.contains(content.id) {
//                SmallFolderTreeRow(content: content,
//                                   share: content.share,
//                                   folders: folders,
//                                   containersExtended: $containersExtended,
//                                   selectedContainer: $selectedContainer)
//            }
//        }
//    }
//
//    private func toggleDisplayContainerContent(containerId: String) {
//        if containersExtended.contains(containerId) {
//            print("Woot remove container: \(containerId)")
//            containersExtended.remove(containerId)
//        } else {
//            print("Woot add container: \(containerId)")
//            containersExtended.insert(containerId)
//        }
//    }
// }
//
// struct SmallFolderTreeRow: View {
//    @Environment(\.dismiss) private var dismiss
//    let content: ShareContent
//    let share: Share
//    let folders: [FolderUiModel]
//    @Binding var containersExtended: Set<String>
//    @Binding var selectedContainer: ShareSelectionPayload?
//
//    var body: some View {
//        VStack(spacing: 0) {
//            ForEach(folders) { folder in
//                row(for: folder)
//                    .padding(.vertical, 12)
//
//                if shouldShowSubfolders(of: folder),
//                   let subFolders = content.folders(in: folder.id) {
//                    SmallFolderTreeRow(content: content,
//                                       share: share,
//                                       folders: subFolders,
//                                       containersExtended: $containersExtended,
//                                       selectedContainer: $selectedContainer)
//                }
//            }
//        }
//        .padding(.leading, 8)
//    }
//
//    private func toggleDisplayContainerContent(containerId: String) {
//        if containersExtended.contains(containerId) {
//            print("Woot remove container: \(containerId)")
//            containersExtended.remove(containerId)
//        } else {
//            print("Woot add container: \(containerId)")
//            containersExtended.insert(containerId)
//        }
//    }
// }
//
// private extension SmallFolderTreeRow {
//    func row(for folder: FolderUiModel) -> some View {
//        HStack {
//            disclosureButton(for: folder)
//            folderButton(for: folder)
//        }
//    }
//
//    @ViewBuilder
//    func disclosureButton(for folder: FolderUiModel) -> some View {
//        if let subfolders = content.folders(in: folder.id), !subfolders.isEmpty {
//            Button {
//                toggleDisplayContainerContent(containerId: folder.id)
//            } label: {
//                (containersExtended.contains(folder.id)
//                    ? IconProvider.chevronDownFilled
//                    : IconProvider.chevronRightFilled)
//                    .resizable()
//                    .frame(width: 30, height: 30)
//                    .foregroundStyle(PassColor.textWeak)
//            }
//            .buttonStyle(.plain)
//        } else {
//            Text("")
//                .frame(width: 30, height: 30)
//        }
//    }
//
//    func folderButton(for folder: FolderUiModel) -> some View {
//        HStack {
//            Button {
//                dismiss()
//                selectedContainer = ShareSelectionPayload(share: share, folder: folder)
//            } label: {
//                HStack {
//                    IconProvider.foldersFilled
//                        .resizable()
//                        .frame(width: 20, height: 20)
//                        .foregroundStyle(Color(hex: "#E9A944"))
//
//                    Text(folder.content.name)
//                        .foregroundStyle(PassColor.textNorm)
//                        .frame(maxWidth: .infinity, alignment: .topLeading)
//                }
//            }
//            .buttonStyle(.plain)
//
//            Spacer()
//        }
//    }
//
//    func shouldShowSubfolders(of folder: FolderUiModel) -> Bool {
//        containersExtended.contains(folder.id)
//    }
// }
