//
//
// AuthenticatorView.swift
// Proton Pass - Created on 15/03/2024.
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

import Client
import DesignSystem
import Entities
import SwiftUI

struct AuthenticatorView: View {
    @StateObject private var viewModel = AuthenticatorViewModel()

    var body: some View {
        mainContent
            .animation(.default, value: viewModel.displayedItems)
            .navigationTitle("Authenticator")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
//            .showSpinner(viewModel.loading)
            .navigationStackEmbeded()
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Look for something")
            .task {
                await viewModel.load()
            }
    }
}

private extension AuthenticatorView {
    var mainContent: some View {
        LazyVStack {
            itemsList(items: viewModel.displayedItems)
        }
        .padding(DesignConstant.sectionPadding)
    }

    func itemsList(items: [ItemContent]) -> some View {
        ForEach(items) { item in
            itemRow(for: item)
                .roundedEditableSection()
        }
    }

    func itemRow(for item: ItemContent) -> some View {
//        GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
//                       title: item.title,
//                       description: item.toItemUiModel.description)
//            .frame(maxWidth: .infinity, alignment: .leading)

        AuthenticatorRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                         uri: item.loginItem?.totpUri ?? "",
                         onCopyTotpToken: { _ in })
            .frame(maxWidth: .infinity, alignment: .leading)
//        TOTPRowTest(uri: item.loginItem?.totpUri ?? "", tintColor: PassColor.loginInteractionNorm,
//                    onCopyTotpToken: { _ in /* viewModel.copyTotpToken($0)*/ })
//        TOTPRow(totpManager: viewModel.totpManager,
//                textColor: .green,
//                tintColor: PassColor.loginInteractionNorm,
//                onCopyTotpToken: { _ in /* viewModel.copyTotpToken($0)*/ })
//        Button {
//            viewModel.showDetail(item: item)
//        } label: {
//            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
//                           title: item.title,
//                           description: item.toItemUiModel.description)
//                .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .buttonStyle(.plain)
    }
}

struct AuthenticatorView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatorView()
    }
}

// TOTPRow(totpManager: viewModel.totpManager,
//        textColor: textColor(for: \.loginItem?.totpUri),
//        tintColor: PassColor.loginInteractionNorm,
//        onCopyTotpToken: { viewModel.copyTotpToken($0) })

// totpManager.bind(uri: totpUri)

import Core
import DesignSystem
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct AuthenticatorRow<ThumbnailView: View>: View {
    @ObservedObject private var totpManager = resolve(\ServiceContainer.totpManager)
    private let thumbnailView: ThumbnailView
    private let uri: String
    private let onCopyTotpToken: (String) -> Void

    init(@ViewBuilder thumbnailView: () -> ThumbnailView,
         uri: String,
         onCopyTotpToken: @escaping (String) -> Void) {
        self.onCopyTotpToken = onCopyTotpToken
        self.uri = uri
        self.thumbnailView = thumbnailView()
        totpManager.bind(uri: uri)
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack {
                Spacer()
                thumbnailView
                    .frame(width: 40)
                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(TotpUriSanitizer().uriForEditing(originalUri: uri))
                    .sectionTitleText()

                switch totpManager.state {
                case .empty:
                    EmptyView()
                case .loading:
                    ProgressView()
                case let .valid(data):
                    TOTPText(code: data.code, textColor: .white, font: .title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .invalid:
                    Text("Invalid TOTP URI")
                        .font(.caption)
                        .foregroundStyle(PassColor.signalDanger.toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if let data = totpManager.totpData {
                    onCopyTotpToken(data.code)
                }
            }

            switch totpManager.state {
            case let .valid(data):
                TOTPCircularTimer(data: data.timerData)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .padding(.horizontal)
        .animation(.default, value: totpManager.state)
    }
}

import PassRustCore
