//
// VaultSyncProgressView.swift
// Proton Pass - Created on 13/09/2023.
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
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct VaultSyncProgressView: View {
    let progress: VaultSyncProgress

    var body: some View {
        HStack {
            if let vaultContent = progress.vault?.vaultContent {
                content(vaultContent: vaultContent, itemsState: progress.itemsState)
            } else {
                skeleton
            }
        }
    }
}

private extension VaultSyncProgressView {
    var skeleton: some View {
        HStack {
            SkeletonBlock()
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                SkeletonBlock()
                    .frame(width: 170, height: 16)
                    .clipShape(Capsule())
                Spacer()
                SkeletonBlock()
                    .frame(height: 16)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shimmering()
    }
}

private extension VaultSyncProgressView {
    func content(vaultContent: VaultContent, itemsState: VaultSyncProgress.ItemsState) -> some View {
        HStack(spacing: 16) {
            thumbnail(for: vaultContent)
            detail(vaultContent: vaultContent, itemsState: itemsState)
            Spacer()
            if progress.isDone {
                Image(uiImage: IconProvider.checkmark)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PassColor.interactionNorm.toColor)
                    .frame(maxHeight: 20)
            }
        }
        .animation(.default, value: progress.isDone)
    }
}

private extension VaultSyncProgressView {
    @ViewBuilder
    func thumbnail(for vaultContent: VaultContent) -> some View {
        CircleButton(icon: vaultContent.vaultBigIcon,
                     iconColor: vaultContent.mainColor,
                     backgroundColor: vaultContent.backgroundColor,
                     type: .big)
    }
}

private extension VaultSyncProgressView {
    func detail(vaultContent: VaultContent, itemsState: VaultSyncProgress.ItemsState) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(vaultContent.name)
                .font(.headline)
                .foregroundStyle(PassColor.textNorm.toColor)

            Spacer()

            switch itemsState {
            case .loading:
                spinnerLabel(text: #localized("Preparing..."))

            case let .download(downloaded, total):
                if progress.isEmpty {
                    emptyText
                } else {
                    spinnerLabel(text: #localized("%@%% downloaded...",
                                                  percentage(done: downloaded, total: total)))
                }

            case let .decrypt(decrypted, total):
                if progress.isEmpty {
                    emptyText
                } else if progress.isDone {
                    Text("\(total) item(s)")
                        .foregroundStyle(PassColor.textWeak.toColor)
                } else {
                    spinnerLabel(text: #localized("%@%% decrypted...",
                                                  percentage(done: decrypted, total: total)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension VaultSyncProgressView {
    var emptyText: some View {
        Text("Empty")
            .font(.body.italic())
            .foregroundStyle(PassColor.textWeak.toColor)
    }
}

private extension VaultSyncProgressView {
    func spinnerLabel(text: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
            Text(text)
        }
        .foregroundStyle(PassColor.textWeak.toColor)
    }
}

private extension VaultSyncProgressView {
    func percentage(done: Int, total: Int) -> String {
        String(format: "%.0f", Float(done) / Float(total) * 100)
    }
}
