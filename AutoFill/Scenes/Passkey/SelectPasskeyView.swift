//
// SelectPasskeyView.swift
// Proton Pass - Created on 29/02/2024.
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

import AuthenticationServices
import DesignSystem
import Entities
import SwiftUI

struct SelectPasskeyView: View {
    @StateObject private var viewModel: SelectPasskeyViewModel

    init(info: SelectPasskeySheetInformation,
         context: ASCredentialProviderExtensionContext) {
        _viewModel = .init(wrappedValue: .init(info: info, context: context))
    }

    var body: some View {
        ZStack {
            PassColor.backgroundWeak
                .ignoresSafeArea()
            LazyVStack(spacing: 0) {
                ForEach(viewModel.info.passkeys, id: \.keyID) { passkey in
                    row(for: passkey)
                    if passkey.keyID != viewModel.info.passkeys.last?.keyID {
                        PassDivider()
                            .padding(.vertical, DesignConstant.sectionPadding)
                    }
                }
            }
            .padding(.horizontal)
            .scrollViewEmbeded()
        }
        .navigationTitle("Select Passkey")
        .navigationBarTitleDisplayMode(.inline)
        .navigationStackEmbeded()
    }
}

private extension SelectPasskeyView {
    func row(for passkey: Passkey) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            PassIcon.passkey
                .resizable()
                .scaledToFit()
                .frame(width: 20)
                .foregroundStyle(ItemContentType.login.normColor)

            VStack(alignment: .leading) {
                Text(passkey.userName)
                    .foregroundStyle(PassColor.textNorm)
                Text(passkey.domain)
                    .sectionTitleText() +
                    Text(verbatim: " • ")
                    .sectionTitleText() +
                    Text(verbatim: String(passkey.keyID.prefix(6)))
                    .sectionTitleText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(.rect)
        .onTapGesture {
            viewModel.autoFill(with: passkey)
        }
    }
}
