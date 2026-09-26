//
// FolderForceSyncSection.swift
// Proton Pass - Created on 18/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Core
import DIComposition
import Entities
import FactoryKit
import SwiftUI
import UseCases

struct FolderForceSyncSection: View {
    @State private var viewModel = FolderForceSyncSectionViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Text(verbatim: "Folder force sync: \(viewModel.description)")
            Text(verbatim: "Reset to re-run the one-shot folder repair for the active user")
                .foregroundStyle(.secondary)
                .font(.footnote)

            Button(action: { viewModel.reset() }, label: {
                Text(verbatim: "Reset folder force sync state")
            })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@Observable
@MainActor
private final class FolderForceSyncSectionViewModel {
    private(set) var state = FolderForceSyncState.default

    private let getUserPreferences = dependency(\UseCasesContainer.getUserPreferences)
    private let updateUserPreferences = dependency(\UseCasesContainer.updateUserPreferences)
    private let userManager = dependency(\ServiceContainer.userManager)

    init() {
        state = getUserPreferences().folderForceSync
    }

    var description: String {
        "done \(state.done), attempts \(state.attempts), folders \(state.foldersDetected)"
    }

    /// Resets the whole struct, not just `done`: a stale `lastAttempt` blocks the next attempt for
    /// half an hour, and a stale `foldersDetected` short-circuits the remote check. The AutoFill
    /// banner keeps its own state outside the preferences row, so that has to be cleared too.
    func reset() {
        Task { [weak self] in
            guard let self else { return }
            try? await updateUserPreferences(\.folderForceSync, value: .default)
            if let userId = userManager.activeUserId {
                kSharedUserDefaults.removeObject(forKey: ShouldShowFolderSyncBanner.lastCheckKey(userId))
                kSharedUserDefaults
                    .removeObject(forKey: ShouldShowFolderSyncBanner.foldersFoundKey(userId))
            }
            state = getUserPreferences().folderForceSync
        }
    }
}
