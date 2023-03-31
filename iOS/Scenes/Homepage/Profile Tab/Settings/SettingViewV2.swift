//
// SettingViewV2.swift
// Proton Pass - Created on 31/03/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct SettingViewV2: View {
    @StateObject var viewModel: SettingViewModelV2

    var body: some View {
        ScrollView {
            VStack(spacing: kItemDetailSectionPadding) {
                untitledSection
                clipboardSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.passBackground)
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden()
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CircleButton(icon: UIDevice.current.isIpad ?
                             IconProvider.chevronLeft : IconProvider.chevronDown,
                             color: .passBrand,
                             action: viewModel.goBack)
            }
        }
    }

    private var untitledSection: some View {
        VStack(spacing: 0) {
            OptionRow(action: viewModel.editDefaultBrowser,
                      title: "Default browser",
                      content: { Text(viewModel.selectedBrowser.description) },
                      trailing: { ChevronRight() })

            PassDivider()

            OptionRow(
                action: viewModel.editTheme,
                title: "Theme",
                content: {
                    Label(title: {
                        Text(viewModel.selectedTheme.description)
                    }, icon: {
                        Image(uiImage: viewModel.selectedTheme.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    })
                },
                trailing: { ChevronRight() })
        }
        .roundedEditableSection()
    }

    private var clipboardSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            Text("Clipboard")
                .sectionHeaderText()
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                OptionRow(action: viewModel.editClipboardExpiration,
                          title: "Clear clipboard",
                          content: { Text(viewModel.selectedClipboardExpiration.description) },
                          trailing: { ChevronRight() })

                PassDivider()

                OptionRow {
                    Toggle(isOn: $viewModel.shareClipboard) {
                        Text("Share clipboard between devices")
                    }
                    .tint(.passBrand)
                }
            }
            .roundedEditableSection()
        }
    }
}
