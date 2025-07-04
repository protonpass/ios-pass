//
// WifiDetailView.swift
// Proton Pass - Created on 10/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct WifiDetailView: View {
    @StateObject private var viewModel: WifiDetailViewModel
    @State private var showPassword = false
    @State private var showQrCode = false
    @Namespace private var bottomID

    init(viewModel: WifiDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: 0) {
                ItemDetailTitleView(itemContent: viewModel.itemContent,
                                    vault: viewModel.vault?.vault)
                    .padding(.bottom, 40)

                ssidAndPasswordSection

                if !viewModel.isFreeUser,
                   !viewModel.ssid.isEmpty,
                   !viewModel.password.isEmpty {
                    showQrCodeButton
                }

                CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                    fields: viewModel.customFields,
                                    isFreeUser: viewModel.isFreeUser,
                                    showIcon: false,
                                    onSelectHiddenText: viewModel.copyHiddenText,
                                    onSelectTotpToken: viewModel.copyTOTPToken,
                                    onUpgrade: { viewModel.upgrade() })

                CustomSectionsSection(sections: viewModel.extraSections,
                                      contentType: viewModel.itemContentType,
                                      isFreeUser: viewModel.isFreeUser,
                                      showIcon: false,
                                      onCopyHiddenText: viewModel.copyHiddenText,
                                      onCopyTotpToken: viewModel.copyTOTPToken,
                                      onUpgrade: viewModel.upgrade)

                if viewModel.showFileAttachmentsSection {
                    FileAttachmentsViewSection(files: viewModel.fileUiModels,
                                               isFetching: viewModel.files.isFetching,
                                               fetchError: viewModel.files.error,
                                               handler: viewModel)
                        .padding(.top, 8)
                }

                ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                         action: viewModel.showItemHistory)

                ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                          itemContent: viewModel.itemContent,
                                          vault: viewModel.vault?.vault,
                                          onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
                    .padding(.top, 24)
                    .id(bottomID)
            }
            .padding()
            .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
            }
            .scrollViewEmbeded()
        }
        .itemDetailSetUp(viewModel)
        .navigationStackEmbeded()
        .sheet(isPresented: $showQrCode) {
            WifiQrCodeView(ssid: viewModel.ssid,
                           password: viewModel.password,
                           security: viewModel.security)
        }
    }
}

private extension WifiDetailView {
    var ssidAndPasswordSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            ssidRow
            PassSectionDivider()
            passwordRow
            PassSectionDivider()
            securityTypeRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    var ssidRow: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Name (SSID)")
                .sectionTitleText()

            if viewModel.ssid.isEmpty {
                Text("Empty")
                    .placeholderText()
            } else {
                Text(viewModel.ssid)
                    .sectionContentText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture(perform: viewModel.copySsid)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button { viewModel.copySsid() } label: {
                Text("Copy")
            }
        }
    }

    var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()

                if viewModel.password.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    if showPassword {
                        Text(viewModel.password)
                            .font(.body.monospaced())
                            .sectionContentText()
                    } else {
                        Text(String(repeating: "•", count: 12))
                            .sectionContentText()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: viewModel.copyPassword)

            Spacer()

            if !viewModel.password.isEmpty {
                CircleButton(icon: showPassword ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             accessibilityLabel: showPassword ? "Hide password" : "Show password",
                             action: { showPassword.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button(action: {
                withAnimation {
                    showPassword.toggle()
                }
            }, label: {
                Text(showPassword ? "Conceal" : "Reveal")
            })

            Button(action: viewModel.copyPassword) {
                Text("Copy")
            }

            Button(action: viewModel.showLargePassword) {
                Text("Show large")
            }
        }
    }

    var securityTypeRow: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Security type")
                .sectionTitleText()

            Text(verbatim: viewModel.security.displayName)
                .sectionContentText()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var showQrCodeButton: some View {
        OptionRow(action: { showQrCode.toggle() },
                  height: .medium,
                  content: {
                      Text("Show Network QR Code")
                          .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                  })
                  .roundedDetailSection()
                  .padding(.top, DesignConstant.sectionPadding / 2)
    }
}

private struct WifiQrCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let ssid: String
    let uri: String

    init(ssid: String,
         password: String,
         security: WifiData.Security) {
        self.ssid = ssid
        uri = "WIFI:T:\(security.protocolName);S:\(ssid);P:\(password);;"
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            VStack(alignment: .center) {
                Text("Scan the QR code to join")
                Text(verbatim: "\"\(ssid)\"")
                Spacer()
            }
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top)

            QrCodeView(text: uri)
                .frame(maxWidth: 400)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)
            }
        }
        .navigationStackEmbeded()
    }
}
