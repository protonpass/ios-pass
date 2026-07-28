//
// AuthenticatorRow.swift
// Proton Pass - Created on 19/03/2024.
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

import DesignSystem
import Entities
import SwiftUI

public struct AuthenticatorRow<ThumbnailView: View>: View {
    @State private var viewModel = AuthenticatorRowViewModel()
    private let thumbnailView: ThumbnailView
    private let uri: String
    private let title: String
    private let onCopyTotpToken: (String) -> Void

    public init(@ViewBuilder thumbnailView: () -> ThumbnailView,
                uri: String,
                title: String,
                onCopyTotpToken: @escaping (String) -> Void) {
        self.thumbnailView = thumbnailView()
        self.uri = uri
        self.title = title
        self.onCopyTotpToken = onCopyTotpToken
    }

    public var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            thumbnailView
                .frame(width: 60)

            AuthenticatorCodeColumn(viewModel: viewModel,
                                    title: title,
                                    onCopyTotpToken: onCopyTotpToken)

            AuthenticatorRowTimer(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .padding(DesignConstant.sectionPadding / 2)
        .roundedEditableSection()
        .task(id: uri) {
            viewModel.bind(uri: uri)
        }
    }
}

private struct AuthenticatorCodeColumn: View {
    let viewModel: AuthenticatorRowViewModel
    let title: String
    let onCopyTotpToken: (String) -> Void

    var body: some View {
        Button {
            if case let .valid(data) = viewModel.state {
                onCopyTotpToken(data.code)
            }
        } label: {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .lineLimit(1)
                    .foregroundStyle(PassColor.textWeak)

                AuthenticatorCode(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct AuthenticatorCode: View {
    let viewModel: AuthenticatorRowViewModel

    var body: some View {
        switch viewModel.state {
        case .empty:
            code("")

        case .loading:
            ProgressView()

        case let .valid(data):
            code(data.code)

        case .invalid:
            Text("Invalid TOTP URI", bundle: .module)
                .font(.caption)
                .foregroundStyle(PassColor.signalDanger)
        }
    }

    private func code(_ code: String) -> some View {
        TOTPText(code: code, textColor: PassColor.textNorm, font: .title)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AuthenticatorRowTimer: View {
    let viewModel: AuthenticatorRowViewModel

    var body: some View {
        if case let .valid(data) = viewModel.state {
            TOTPCircularTimer(data: data.timerData)
        }
    }
}
