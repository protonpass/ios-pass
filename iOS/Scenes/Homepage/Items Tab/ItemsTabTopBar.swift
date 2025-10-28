//
// ItemsTabTopBar.swift
// Proton Pass - Created on 30/11/2023.
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
import ProtonCoreUIFoundations
import SwiftUI

struct ItemsTabTopBar: View {
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @Binding var searchMode: SearchMode?
    let animationNamespace: Namespace.ID
    @StateObject private var viewModel = ItemsTabTopBarViewModel()
    @Binding var isEditMode: Bool
    let showPromoBadge: Bool
    let onSearch: () -> Void
    let onShowVaultList: () -> Void
    let onPin: () -> Void
    let onUnpin: () -> Void
    let onMove: () -> Void
    let onTrash: () -> Void
    let onRestore: () -> Void
    let onPermanentlyDelete: () -> Void
    let onDisableAliases: () -> Void
    let onEnableAliases: () -> Void
    let onPromoBadgeTapped: () -> Void

    var body: some View {
        ZStack {
            if isEditMode {
                editModeView
            } else {
                viewModeView
            }
        }
        .animation(.default, value: isEditMode)
        .frame(height: 60)
    }
}

private extension ItemsTabTopBar {
    var viewModeView: some View {
        HStack {
            // Vault selector button
            let uiModel = viewModel.vaultSelection.uiModel
            CircleButton(icon: uiModel.icon,
                         iconColor: uiModel.iconColor,
                         backgroundColor: uiModel.backgroundColor,
                         action: onShowVaultList)
                .accessibilityLabel(viewModel.vaultSelection.accessibilityLabel)

            if searchMode == nil {
                // Search bar
                ZStack {
                    PassColor.backgroundStrong
                    HStack {
                        Image(uiImage: IconProvider.magnifier)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(viewModel.vaultSelection.searchBarPlaceholder)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(PassColor.textWeak)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .matchedGeometryEffect(id: SearchEffectID.searchbar.id,
                                       in: animationNamespace)
                .contentShape(.rect)
                .frame(height: DesignConstant.searchBarHeight)
                .onTapGesture(perform: onSearch)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }

            if showPromoBadge {
                Image(uiImage: PassIcon.promoBadge)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 46)
                    .buttonEmbeded(action: onPromoBadgeTapped)
            } else if viewModel.shouldUpsell {
                Image(uiImage: PassIcon.diamond)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .scaledToFit()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(height: 44, alignment: .leading)
                    .cornerRadius(10)
                    .foregroundStyle(PassColor.interactionNormMajor2)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .inset(by: 0.5)
                        .stroke(PassColor.interactionNormMinor1, lineWidth: 1))
                    .buttonEmbeded(action: viewModel.upgradeSubscription)
            }

            SortFilterItemsMenu(options: [
                .selectItems { isEditMode.toggle() },
                .filter(viewModel.selectedFilterOption, viewModel.itemCount, viewModel.update(_:)),
                .sort(viewModel.selectedSortType) { viewModel.selectedSortType = $0 },
                .resetFilters { viewModel.resetFilters() }
            ],
            highlighted: viewModel.highlighted,
            selectable: viewModel.selectable)
        }
        .padding(.horizontal, showButtonShapes ? 0 : nil)
        .animation(.default, value: showPromoBadge)
        .animation(.default, value: viewModel.shouldUpsell)
    }
}

private extension ItemsTabTopBar {
    var editModeView: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack {
                Button(action: {
                    isEditMode = false
                    viewModel.deselectAllItems()
                }, label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(PassColor.interactionNormMajor2)
                })

                if viewModel.selectedItemsCount > 0 {
                    Text(verbatim: "\(viewModel.selectedItemsCount)")
                        .font(.title3.bold())
                        .foregroundStyle(PassColor.textNorm)
                        .monospacedDigit()
                }

                Spacer()

                switch viewModel.vaultSelection {
                case .all, .precise:
                    button(action: onMove, icon: IconProvider.folderArrowIn)
                        .padding(.horizontal)
                    button(action: onTrash, icon: IconProvider.trash)

                case .trash:
                    button(action: onRestore, icon: IconProvider.clockRotateLeft)
                        .padding(.horizontal)
                    button(action: onPermanentlyDelete,
                           icon: IconProvider.trashCross,
                           color: PassColor.signalDanger)

                default:
                    EmptyView()
                }

                if !viewModel.extraOptions.isEmpty {
                    Menu(content: {
                        ForEach(viewModel.extraOptions, id: \.self) { option in
                            Section {
                                Button(action: { handle(extraOption: option) },
                                       label: {
                                           Label(option.title, uiImage: option.icon)
                                       })
                            }
                        }
                    }, label: {
                        CircleButton(icon: IconProvider.threeDotsVertical,
                                     iconColor: PassColor.textNorm,
                                     backgroundColor: .clear)
                    })
                }
            }
            .padding(.horizontal)
            .animation(.default, value: viewModel.selectedItemsCount)
            .animation(.default, value: viewModel.extraOptions.isEmpty)

            Spacer()

            PassDivider()
        }
    }

    func button(action: @escaping () -> Void,
                icon: UIImage,
                color: Color = PassColor.textNorm) -> some View {
        Button(action: action) {
            Image(uiImage: icon)
                .foregroundStyle(viewModel.actionsDisabled ? PassColor.textHint : color)
        }
        .disabled(viewModel.actionsDisabled)
        .animation(.default, value: viewModel.actionsDisabled)
    }

    func handle(extraOption: ExtraBulkActionOption) {
        switch extraOption {
        case .pin:
            onPin()
        case .unpin:
            onUnpin()
        case .disableAliases:
            onDisableAliases()
        case .enableAliases:
            onEnableAliases()
        }
    }
}

private struct VautlSelectionUiModel: Sendable {
    let icon: UIImage
    let iconColor: Color
    let backgroundColor: Color
}

private extension VaultSelection {
    var uiModel: VautlSelectionUiModel {
        switch self {
        case .all:
            .init(icon: PassIcon.brandPass,
                  iconColor: VaultSelection.all.color,
                  backgroundColor: VaultSelection.all.color.opacity(0.16))

        case .sharedByMe:
            .init(icon: IconProvider.userArrowRight,
                  iconColor: VaultSelection.all.color,
                  backgroundColor: VaultSelection.all.color.opacity(0.16))

        case .sharedWithMe:
            .init(icon: IconProvider.userArrowLeft,
                  iconColor: VaultSelection.all.color,
                  backgroundColor: VaultSelection.all.color.opacity(0.16))

        case let .precise(vault):
            if let vaultContent = vault.vaultContent {
                .init(icon: vaultContent.vaultBigIcon,
                      iconColor: vaultContent.mainColor,
                      backgroundColor: vaultContent.backgroundColor)
            } else {
                .init(icon: PassIcon.brandPass,
                      iconColor: VaultSelection.all.color,
                      backgroundColor: VaultSelection.all.color.opacity(0.16))
            }

        case .trash:
            .init(icon: IconProvider.trash,
                  iconColor: VaultSelection.trash.color,
                  backgroundColor: VaultSelection.trash.color.opacity(0.16))
        }
    }
}
