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

enum ItemsTabTopBarAction {
    case onSearch
    case onShowVaultList
    case onPin
    case onUnpin
    case onMove
    case onTrash
    case onRestore
    case onPermanentlyDelete
    case onDisableAliases
    case onEnableAliases
    case onPromoBadgeTapped
}

struct ItemsTabTopBar: View {
    @StateObject private var viewModel = ItemsTabTopBarViewModel()

    let animationNamespace: Namespace.ID
    @Binding var isEditMode: Bool
    let showPromoBadge: Bool
    let action: (ItemsTabTopBarAction) -> Void

    var body: some View {
        ZStack {
            if isEditMode {
                EditModeView(viewModel: viewModel,
                             isEditMode: $isEditMode,
                             action: action)
                    .frame(height: 60)
            } else {
                ViewModeView(viewModel: viewModel,
                             isEditMode: $isEditMode,
                             showPromoBadge: showPromoBadge,
                             animationNamespace: animationNamespace,
                             action: action)
            }
        }
        .animation(.default, value: isEditMode)
    }
}

private struct ViewModeView: View {
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @ObservedObject var viewModel: ItemsTabTopBarViewModel
    @Binding var isEditMode: Bool
    let showPromoBadge: Bool
    let animationNamespace: Namespace.ID
    let action: (ItemsTabTopBarAction) -> Void

    var body: some View {
        HStack {
            leadingIconContainerButton
                .accessibilityLabel(viewModel.shareSelection.accessibilityLabel)
            if #available(iOS 26.0, *) {
                title
            } else {
                HStack {
                    searchIcon
                    title
                    searchIcon.opacity(0)
                }
                .frame(height: DesignConstant.searchBarHeight)
                .matchedGeometryEffect(id: SearchEffectID.searchbar.id,
                                       in: animationNamespace)
                .padding(.horizontal, 16)
                .background(PassColor.backgroundStrong)
                .clipShape(.capsule)
                .buttonEmbeded {
                    action(.onSearch)
                }
                .accessibilityLabel("Start search")
            }
            upsellView
            sortAndFilterMenu
        }
        .frame(height: 48)
        .padding(.horizontal, showButtonShapes ? 0 : nil)
        .padding(.vertical, 16)
        .animation(.default, value: viewModel.shouldUpsell)
    }

    @ViewBuilder
    var leadingIconContainerButton: some View {
        if viewModel.shareSelection.isFolderSelection {
            CircleButton(icon: IconProvider.folderFilled,
                         iconColor: PassColor.folderIcon,
                         backgroundColor: PassColor.interactionNormMinor1) {
                action(.onShowVaultList)
            }
        } else {
            let uiModel = viewModel.shareSelection.uiModel
            CircleButton(icon: uiModel.icon,
                         iconColor: uiModel.iconColor,
                         backgroundColor: uiModel.backgroundColor) {
                action(.onShowVaultList)
            }
        }
    }

    var searchIcon: some View {
        IconProvider.magnifier
            .resizable()
            .scaledToFit()
            .frame(width: 20)
            .foregroundStyle(PassColor.textWeak)
    }

    var title: some View {
        Text(verbatim: "\(viewModel.shareSelection.title)")
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var upsellView: some View {
        if showPromoBadge {
            PassIcon.promoBadge
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 46)
                .buttonEmbeded { action(.onPromoBadgeTapped) }
        } else if viewModel.shouldUpsell {
            if #available(iOS 26.0, *) {
                Button(action: viewModel.upgradeSubscription) {
                    upsellIcon
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: 40, maxHeight: 40)
                .buttonStyle(.glass)
                .buttonBorderShape(.roundedRectangle(radius: 10))
            } else {
                Button(action: viewModel.upgradeSubscription) {
                    upsellIcon
                        .frame(width: 40, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .inset(by: 0.5)
                            .stroke(PassColor.interactionNormMinor1, lineWidth: 1))
                }
            }
        }
    }

    var upsellIcon: some View {
        PassIcon.diamond
            .resizable()
            .frame(width: 20, height: 20)
            .scaledToFit()
            .foregroundStyle(PassColor.interactionNormMajor2)
    }

    var sortAndFilterMenu: some View {
        SortFilterItemsMenu(options: [
            .selectItems { isEditMode.toggle() },
            .filter(viewModel.selectedFilterOption, viewModel.itemCount, viewModel.update(_:)),
            .sort(viewModel.selectedSortType) { viewModel.selectedSortType = $0 },
            .resetFilters { viewModel.resetFilters() }
        ],
        highlighted: viewModel.highlighted,
        selectable: viewModel.selectable)
    }
}

private struct EditModeView: View {
    @ObservedObject var viewModel: ItemsTabTopBarViewModel
    @Binding var isEditMode: Bool
    let action: (ItemsTabTopBarAction) -> Void

    var body: some View {
        editModeView
    }

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

                mainActions

                extraOptionsMenu
            }
            .padding(.horizontal)
            .animation(.default, value: viewModel.selectedItemsCount)
            .animation(.default, value: viewModel.extraOptions.isEmpty)

            Spacer()

            PassDivider()
        }
    }

    @ViewBuilder
    var mainActions: some View {
        switch viewModel.shareSelection {
        case .all, .precise:
            button(action: { action(.onMove) }, icon: IconProvider.folderArrowIn)
                .padding(.horizontal)
            button(action: { action(.onTrash) }, icon: IconProvider.trash)

        case .trash:
            button(action: { action(.onRestore) }, icon: IconProvider.clockRotateLeft)
                .padding(.horizontal)
            button(action: { action(.onPermanentlyDelete) },
                   icon: IconProvider.trashCross,
                   color: PassColor.signalDanger)

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    var extraOptionsMenu: some View {
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
            action(.onPin)
        case .unpin:
            action(.onUnpin)
        case .disableAliases:
            action(.onDisableAliases)
        case .enableAliases:
            action(.onEnableAliases)
        }
    }
}

private struct VautlSelectionUiModel {
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
