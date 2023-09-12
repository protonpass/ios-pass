//
// FullSyncProgressView.swift
// Proton Pass - Created on 11/09/2023.
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
import ProtonCoreUIFoundations
import SwiftUI

struct FullSyncProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FullSyncProgressViewModel
    var onContinue: (() -> Void)?

    init(mode: FullSyncProgressViewModel.Mode) {
        _viewModel = .init(wrappedValue: .init(mode: mode))
    }

    var body: some View {
        switch viewModel.mode {
        case .fullSync:
            NavigationView {
                realBody
                    .background(PassColor.backgroundNorm.toColor)
                    .navigationTitle("Syncing items...")
            }
            .navigationViewStyle(.stack)
        case .logIn:
            realBody
        }
    }
}

private extension FullSyncProgressView {
    var realBody: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if !viewModel.mode.isFullSync {
                        Text("Syncing items...")
                            .font(.title3.bold())
                            .foregroundColor(PassColor.textNorm.toColor)
                    }

                    Text("We are downloading and decrypting your items. This might take a few minutes.")
                        .foregroundColor(PassColor.textNorm.toColor)
                        .padding(.vertical, viewModel.mode.isFullSync ? 0 : nil)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.progresses.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.progresses) { progress in
                            VaultSyncProgressView(progress: progress)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .animation(.default, value: viewModel.progresses.count)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            DisablableCapsuleTextButton(title: "Continue".localized,
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.isDoneSynching,
                                        action: handleContinuation)
                .padding()
        }
        .accentColor(PassColor.interactionNorm.toColor)
        .tint(PassColor.interactionNorm.toColor)
    }

    func handleContinuation() {
        switch viewModel.mode {
        case .fullSync:
            dismiss()
        case .logIn:
            onContinue?()
        }
    }
}

// MARK: - VaultSyncProgressView

private struct VaultSyncProgressView: View {
    let progress: VaultSyncProgress

    var body: some View {
        HStack {
            if let vault = progress.vault {
                content(vault: vault, itemsState: progress.itemsState)
            } else {
                skeleton
            }
        }
        .frame(height: 48)
    }
}

private extension VaultSyncProgressView {
    var skeleton: some View {
        HStack {
            AnimatingGradient()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Spacer()
                AnimatingGradient()
                    .frame(width: 170, height: 10)
                    .clipShape(Capsule())
                Spacer()
                AnimatingGradient()
                    .frame(height: 10)
                    .clipShape(Capsule())
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension VaultSyncProgressView {
    func content(vault: Vault, itemsState: VaultSyncProgress.ItemsState) -> some View {
        HStack {
            thumbnail(for: vault)
            detail(vault: vault, itemsState: itemsState)
            Spacer()
            trailingView
        }
    }

    @ViewBuilder
    func thumbnail(for vault: Vault) -> some View {
        let icon = vault.displayPreferences.icon.icon.bigImage
        let color = vault.displayPreferences.color.color.color
        CircleButton(icon: icon,
                     iconColor: color,
                     backgroundColor: color.withAlphaComponent(0.16))
    }

    func detail(vault: Vault, itemsState: VaultSyncProgress.ItemsState) -> some View {
        VStack(alignment: .leading) {
            Text(vault.name)
                .foregroundColor(PassColor.textNorm.toColor)

            switch itemsState {
            case .loading:
                AnimatingGradient()
                    .frame(height: 2)
                    .clipShape(Capsule())

            case let .download(downloaded, total):
                if progress.isEmpty {
                    emptyText
                } else {
                    Text("Downloading (\(min(downloaded, total))/\(total))")
                        .font(.caption)
                        .foregroundColor(PassColor.textNorm.toColor)

                    ProgressView(value: Float(downloaded) / Float(total))
                        .animation(.default, value: downloaded)
                }

            case let .decrypt(decrypted, total):
                if progress.isEmpty {
                    emptyText
                } else if progress.isDone {
                    Text("%d item(s)".localized(total))
                        .font(.caption)
                        .foregroundColor(PassColor.textNorm.toColor)
                } else {
                    Text("Decrypting (\(min(decrypted, total))/\(total))")
                        .font(.caption)
                        .foregroundColor(PassColor.textNorm.toColor)

                    ProgressView(value: Float(decrypted) / Float(total))
                        .animation(.default, value: decrypted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var emptyText: some View {
        Text("Empty")
            .font(.caption.italic())
            .foregroundColor(PassColor.textNorm.toColor)
    }

    @ViewBuilder
    var trailingView: some View {
        if progress.isDone {
            Image(uiImage: IconProvider.checkmark)
                .resizable()
                .scaledToFit()
                .foregroundColor(PassColor.interactionNorm.toColor)
                .frame(maxHeight: 20)
        } else {
            ProgressView()
        }
    }
}
