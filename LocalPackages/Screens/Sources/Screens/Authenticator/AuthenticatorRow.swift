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

import Client
import Combine
import DesignSystem
import Entities
import Factory
import Foundation
import ProtonCoreUIFoundations
import SwiftUI

@MainActor
private final class AuthenticatorRowViewModel: ObservableObject {
    @Published private(set) var state = TOTPState.empty

    private let totpManager: any TOTPManagerProtocol
    private var cancellable = Set<AnyCancellable>()

    var code: String? {
        totpManager.totpData?.code
    }

    init(totpManager: any TOTPManagerProtocol) {
        self.totpManager = totpManager
        totpManager.currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else {
                    return
                }
                state = newState
            }.store(in: &cancellable)
    }

    func bind(uri: String) {
        totpManager.bind(uri: uri)
    }
}

public struct AuthenticatorRow<ThumbnailView: View>: View {
    @StateObject private var viewModel: AuthenticatorRowViewModel
    private let thumbnailView: ThumbnailView
    private let uri: String
    private let title: String
    private let onCopyTotpToken: (String) -> Void

    public init(@ViewBuilder thumbnailView: () -> ThumbnailView,
                uri: String,
                title: String,
                totpManager: any TOTPManagerProtocol,
                onCopyTotpToken: @escaping (String) -> Void) {
        _viewModel = .init(wrappedValue: .init(totpManager: totpManager))
        self.onCopyTotpToken = onCopyTotpToken
        self.uri = uri
        self.thumbnailView = thumbnailView()
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack {
                Spacer()
                thumbnailView
                    .frame(width: 60)
                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .lineLimit(1)
                    .foregroundStyle(PassColor.textWeak.toColor)
                switch viewModel.state {
                case .empty:
                    TOTPText(code: "", textColor: PassColor.textNorm, font: .title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .loading:
                    ProgressView()
                case let .valid(data):
                    TOTPText(code: data.code, textColor: PassColor.textNorm, font: .title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .invalid:
                    Text("Invalid TOTP URI")
                        .font(.caption)
                        .foregroundStyle(PassColor.signalDanger.toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if let code = viewModel.code {
                    onCopyTotpToken(code)
                }
            }
            switch viewModel.state {
            case let .valid(data):
                TOTPCircularTimer(data: data.timerData)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .padding(DesignConstant.sectionPadding / 2)
        .roundedEditableSection()
        .onAppear {
            viewModel.bind(uri: uri)
        }
    }
}
