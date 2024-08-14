//
// TOTPRow.swift
// Proton Pass - Created on 06/12/2023.
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
import Combine
import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import Screens
import SwiftUI

@MainActor
final class TOTPRowViewModel: ObservableObject {
    @Published private(set) var state = TOTPState.empty

    private let totpManager = resolve(\SharedServiceContainer.totpManager)
    private var cancellable = Set<AnyCancellable>()

    var code: String? {
        totpManager.totpData?.code
    }

    init() {
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

struct TOTPRow: View {
    @ObservedObject private var viewModel = TOTPRowViewModel()
    let textColor: UIColor
    let tintColor: UIColor
    let onCopyTotpToken: (String) -> Void

    init(uri: String,
         textColor: UIColor = PassColor.textNorm,
         tintColor: UIColor,
         onCopyTotpToken: @escaping (String) -> Void) {
        self.textColor = textColor
        self.tintColor = tintColor
        self.onCopyTotpToken = onCopyTotpToken
        viewModel.bind(uri: uri)
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("2FA token (TOTP)")
                    .sectionTitleText()

                switch viewModel.state {
                case .empty:
                    EmptyView()
                case .loading:
                    ProgressView()
                case let .valid(data):
                    TOTPText(code: data.code, textColor: textColor)
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
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.state)
    }
}
