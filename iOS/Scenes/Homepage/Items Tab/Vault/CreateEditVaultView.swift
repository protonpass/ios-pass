//
// CreateEditVaultView.swift
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

import DesignSystem
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: CreateEditVaultViewModel
    @FocusState private var isFocusedOnTitle

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !viewModel.canCreateOrEdit {
                    vaultsLimitMessage
                }
                previewAndTitle
                    .fixedSize(horizontal: false, vertical: true)
                colorsAndIcons
            }
            .animation(.default, value: viewModel.canCreateOrEdit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DesignConstant.sectionPadding)
            .showSpinner(viewModel.loading)
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundNorm)
            .toolbar { toolbarContent }
            .ignoresSafeArea(.keyboard)
            .gesture(DragGesture().onChanged { _ in isFocusedOnTitle = false })
        }
        .onAppear {
            isFocusedOnTitle = true
        }
        .onChange(of: viewModel.selectedIcon) { _ in
            isFocusedOnTitle = false
        }
        .onChange(of: viewModel.selectedColor) { _ in
            isFocusedOnTitle = false
        }
        .onChange(of: viewModel.finishSaving) { _ in
            dismiss()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.canCreateOrEdit {
                DisablableCapsuleTextButton(title: viewModel.saveButtonTitle,
                                            titleColor: PassColor.textInvert,
                                            disableTitleColor: PassColor.textHint,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: viewModel.title.isEmpty,
                                            action: { viewModel.save() })
            } else {
                UpgradeButton(backgroundColor: PassColor.interactionNormMajor1,
                              action: { viewModel.upgrade() })
            }
        }
    }

    private var vaultsLimitMessage: some View {
        // swiftlint:disable:next line_length
        TextBanner("You have reached the limit of vaults you can create. Upgrade to a paid plan to create multiple vaults.")
    }

    private var previewAndTitle: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            let previewWidth: CGFloat = UIDevice.current.isIpad ? 60 : 40
            VStack {
                Spacer()
                viewModel.selectedIcon.bigImage
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(viewModel.selectedColor.color)
                    .padding(previewWidth / 4)
                    .frame(width: previewWidth, height: previewWidth)
                    .background(viewModel.selectedColor.color.opacity(0.16))
                    .clipShape(Circle())
                    .animation(.default, value: viewModel.selectedIcon)
                    .animation(.default, value: viewModel.selectedColor)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text("Title")
                        .sectionTitleText()
                    TextField("Untitled", text: $viewModel.title)
                        .font(.title.weight(.bold))
                        .tint(PassColor.interactionNorm)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .focused($isFocusedOnTitle)
                        .onSubmit { isFocusedOnTitle = false }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ClearTextButton(text: $viewModel.title)
            }
            .padding(DesignConstant.sectionPadding)
            .roundedEditableSection()
            .animation(.default, value: viewModel.title.isEmpty)
        }
    }

    private var colorsAndIcons: some View {
        GeometryReader { proxy in
            let itemPerRow = 5
            let rowSpacing: CGFloat = DesignConstant.sectionPadding
            let itemSize = itemSize(size: proxy.size, itemPerRow: itemPerRow, rowSpacing: rowSpacing)
            LazyVGrid(columns: columns, spacing: rowSpacing) {
                ForEach(VaultColorIcon.allCases, id: \.self) { colorIcon in
                    switch colorIcon {
                    case let .color(color):
                        VaultColorView(color: color, selectedColor: $viewModel.selectedColor)
                            .frame(width: itemSize, height: itemSize)
                    case let .icon(icon):
                        VaultIconView(icon: icon, selectedIcon: $viewModel.selectedIcon)
                            .frame(width: itemSize, height: itemSize)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func itemSize(size: CGSize, itemPerRow: Int, rowSpacing: CGFloat) -> CGFloat {
        let rowSpacing = Int(rowSpacing)
        let rowCount = VaultColorIcon.allCases.count / itemPerRow
        let columSpacing = 26
        let rowHeight = (Int(size.height) - (rowCount - 1) * rowSpacing) / rowCount
        let rowWidth = (Int(size.width) - (itemPerRow - 1) * columSpacing) / itemPerRow
        return CGFloat(max(min(rowHeight, rowWidth), 0))
    }
}

private struct VaultColorView: View {
    let color: VaultColor
    @Binding var selectedColor: VaultColor

    var body: some View {
        GeometryReader { proxy in
            Button(action: {
                selectedColor = color
            }, label: {
                color.color
                    .clipShape(Circle())
                    .padding(proxy.size.width / 10)
                    .overlay(overlay(size: proxy.size))
            })
            .buttonStyle(.plain)
            .animation(.default, value: selectedColor)
        }
    }

    @ViewBuilder
    private func overlay(size: CGSize) -> some View {
        if color == selectedColor {
            Circle()
                .strokeBorder(PassColor.textHint,
                              style: StrokeStyle(lineWidth: size.width / 20))
        } else {
            EmptyView()
        }
    }
}

private struct VaultIconView: View {
    let icon: VaultIcon
    @Binding var selectedIcon: VaultIcon

    var body: some View {
        GeometryReader { proxy in
            Button(action: {
                selectedIcon = icon
            }, label: {
                ZStack {
                    PassColor.inputBackgroundNorm
                    icon.bigImage
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textNorm)
                        .padding(proxy.size.width / 6)
                }
                .clipShape(Circle())
                .padding(proxy.size.width / 10)
                .overlay(overlay(size: proxy.size))
            })
            .buttonStyle(.plain)
            .animation(.default, value: selectedIcon)
        }
    }

    @ViewBuilder
    private func overlay(size: CGSize) -> some View {
        if icon == selectedIcon {
            Circle()
                .strokeBorder(PassColor.textHint,
                              style: StrokeStyle(lineWidth: size.width / 20))
        } else {
            EmptyView()
        }
    }
}
