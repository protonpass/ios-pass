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
import SwiftUI

struct CreateEditVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: CreateEditVaultViewModel
    @FocusState private var isFocusedOnTitle

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if !viewModel.canCreateOrEdit {
                    vaultsLimitMessage
                }
                previewAndTitle
                    .fixedSize(horizontal: false, vertical: true)
                colorsAndIcons
            }
            .showSpinner(viewModel.loading)
            .animation(.default, value: viewModel.canCreateOrEdit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DesignConstant.sectionPadding)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: PassColor.backgroundNorm))
            .toolbar { toolbarContent }
            .ignoresSafeArea(.keyboard)
            .gesture(DragGesture().onChanged { _ in isFocusedOnTitle = false })
        }
        .navigationViewStyle(.stack)
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
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
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
        Text("You have reached the limit of vaults you can create. Create unlimited vaults when you upgrade your subscription.")
            .padding()
            .foregroundColor(Color(uiColor: PassColor.textNorm))
            .background(Color(uiColor: PassColor.interactionNormMinor1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var previewAndTitle: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            let previewWidth: CGFloat = UIDevice.current.isIpad ? 60 : 40
            VStack {
                Spacer()
                Image(uiImage: viewModel.selectedIcon.bigImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: viewModel.selectedColor.color))
                    .padding(previewWidth / 4)
                    .frame(width: previewWidth, height: previewWidth)
                    .background(Color(uiColor: viewModel.selectedColor.color).opacity(0.16))
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
                        .tint(Color(uiColor: PassColor.interactionNorm))
                        .submitLabel(.done)
                        .focused($isFocusedOnTitle)
                        .onSubmit { isFocusedOnTitle = false }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !viewModel.title.isEmpty {
                    Button(action: {
                        viewModel.title = ""
                    }, label: {
                        ItemDetailSectionIcon(icon: IconProvider.cross)
                    })
                }
            }
            .padding(DesignConstant.sectionPadding)
            .roundedEditableSection()
            .animation(.default, value: viewModel.title.isEmpty)
        }
    }

    private var colorsAndIcons: some View {
        GeometryReader { proxy in
            let itemPerRow = 5
            let rowSpacing: CGFloat = 16
            let rowWidth = rowWidth(size: proxy.size, itemPerRow: itemPerRow, rowSpacing: rowSpacing)
            VStack(spacing: rowSpacing) {
                ForEach(VaultColorIcon.allCases.chunked(into: itemPerRow), id: \.self) { chunkedColorIcons in
                    HStack {
                        ForEach(chunkedColorIcons, id: \.self) { colorIcon in
                            switch colorIcon {
                            case let .color(color):
                                VaultColorView(color: color, selectedColor: $viewModel.selectedColor)
                                    .frame(width: rowWidth, height: rowWidth)
                            case let .icon(icon):
                                VaultIconView(icon: icon, selectedIcon: $viewModel.selectedIcon)
                                    .frame(width: rowWidth, height: rowWidth)
                            }

                            if colorIcon != chunkedColorIcons.last {
                                Spacer()
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func rowWidth(size: CGSize, itemPerRow: Int, rowSpacing: CGFloat) -> CGFloat {
        let rowSpacing = Int(rowSpacing)
        let rowCount = VaultColorIcon.allCases.count / itemPerRow
        let columSpacing = 26
        let rowHeight = (Int(size.height) - (rowCount - 1) * rowSpacing) / rowCount
        let rowWidth = (Int(size.width) - (itemPerRow - 1) * columSpacing) / itemPerRow
        return CGFloat(min(rowHeight, rowWidth))
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
                Color(uiColor: color.color)
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
                .strokeBorder(Color(uiColor: PassColor.textHint),
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
                    PassColor.inputBackgroundNorm.toColor
                    Image(uiImage: icon.bigImage)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
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
                .strokeBorder(Color(uiColor: PassColor.textHint),
                              style: StrokeStyle(lineWidth: size.width / 20))
        } else {
            EmptyView()
        }
    }
}
