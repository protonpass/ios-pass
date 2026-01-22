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
import Macro
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
                    .frame(height: 60)
            } else {
                viewModeView
            }
        }
        .animation(.default, value: isEditMode)
    }
}

private extension ItemsTabTopBar {
    var viewModeView: some View {
        VStack {
            HStack {
                // TODO: need to take into account container selected for icon and title
                // Vault selector button
                if viewModel.shareSelection.isFolderSelection {
                    CircleButton(icon: IconProvider.folderFilled,
                                 iconColor: Color(hex: "#E9A944"),
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 action: onShowVaultList)
                } else {
                    let uiModel = viewModel.shareSelection.uiModel
                    CircleButton(icon: uiModel.icon,
                                 iconColor: uiModel.iconColor,
                                 backgroundColor: uiModel.backgroundColor,
                                 action: onShowVaultList)
                        .accessibilityLabel(viewModel.shareSelection.accessibilityLabel)
                }
                if viewModel.shareSelection.isFolderSelection {
                    let uiModel = viewModel.shareSelection.uiModel
                    let title = viewModel.shareSelection.preciseSelectionPayload?.share.vaultContent?.name ?? ""
                    VStack {
                        HStack(alignment: .center) {
                            Spacer()
                            uiModel.icon
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(uiModel.iconColor)
                            Text(title)
                                .font(.footnote)
                            Spacer()
                        }
                        Text("\(viewModel.shareSelection.title)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Text("\(viewModel.shareSelection.title)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }

                if showPromoBadge {
                    PassIcon.promoBadge
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 46)
                        .buttonEmbeded(action: onPromoBadgeTapped)
                } else if viewModel.shouldUpsell {
                    PassIcon.diamond
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
                selectable: viewModel.selectable,
                folder: viewModel.shareSelection.preciseSelectionPayload?.folder)
            }
            .frame(height: 48)
            .padding(.horizontal, showButtonShapes ? 0 : nil)
            .padding(.vertical, 16)
            .animation(.default, value: showPromoBadge)
            .animation(.default, value: viewModel.shouldUpsell)

            if searchMode == nil {
                // Search bar
                ZStack {
                    PassColor.backgroundStrong
                    HStack {
                        IconProvider.magnifier
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(viewModel.shareSelection.searchBarPlaceholder)
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
                .frame(height: 48)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
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

                switch viewModel.shareSelection {
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
                                           Label(option.title, image: option.icon)
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
                icon: Image,
                color: Color = PassColor.textNorm) -> some View {
        Button(action: action) {
            icon
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
    let icon: Image
    let iconColor: Color
    let backgroundColor: Color
}

private extension ShareSelection {
    var uiModel: VautlSelectionUiModel {
        switch self {
        case .all:
            .init(icon: PassIcon.brandPass,
                  iconColor: ShareSelection.all.color,
                  backgroundColor: ShareSelection.all.color.opacity(0.16))

        case .sharedByMe:
            .init(icon: IconProvider.userArrowRight,
                  iconColor: ShareSelection.all.color,
                  backgroundColor: ShareSelection.all.color.opacity(0.16))

        case .sharedWithMe:
            .init(icon: IconProvider.userArrowLeft,
                  iconColor: ShareSelection.all.color,
                  backgroundColor: ShareSelection.all.color.opacity(0.16))

        // TODO: maybe take into account items
        case let .precise(selection):
            if let vaultContent = selection.share.vaultContent {
                .init(icon: vaultContent.vaultBigIcon,
                      iconColor: vaultContent.mainColor,
                      backgroundColor: vaultContent.backgroundColor)
            } else {
                .init(icon: PassIcon.brandPass,
                      iconColor: ShareSelection.all.color,
                      backgroundColor: ShareSelection.all.color.opacity(0.16))
            }

        case .trash:
            .init(icon: IconProvider.trash,
                  iconColor: ShareSelection.trash.color,
                  backgroundColor: ShareSelection.trash.color.opacity(0.16))
        }
    }
}
