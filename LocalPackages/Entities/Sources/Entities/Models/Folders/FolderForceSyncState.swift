//
// FolderForceSyncState.swift
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

import Foundation

/// Tracks the one-shot full sync that repairs data missed by clients predating folder support.
///
/// A client without folder support cannot decrypt items inside a folder, so it drops them. The
/// absence of a completed state is what identifies such a client: any user who has finished a
/// full sync on a folder-aware build has `done == true`, and older builds never wrote this value
/// at all, so they decode to `default`.
///
/// Written only by the main app. `PreferencesManager` persists the whole preferences row from its
/// own in-memory snapshot, so a second process writing here would push its stale copy of every
/// other field back to disk - an extension that wrote `done = false` after the app had set it
/// would trigger another destructive full sync. Extension-side state lives in the shared
/// `UserDefaults` instead.
public struct FolderForceSyncState: Codable, Equatable, Sendable {
    /// Terminal: the repair is over for this user and must never run again.
    ///
    /// Set either because a full sync completed, or because the attempt budget ran out and the
    /// repair was abandoned. `attempts >= maxAttempts` distinguishes the two. Both readings are
    /// deliberate - the extension banner keys off this flag, so a give-up has to silence it the
    /// same way a success does.
    public var done: Bool

    /// Consumed repair attempts. Reaching the maximum abandons the repair and sets `done`.
    public var attempts: Int

    /// When the last attempt was made, used to space attempts out.
    public var lastAttempt: Date?

    /// Sticky cache of "this user has folders somewhere".
    ///
    /// Only ever written `true`: a negative result must not be stored, because another member of
    /// a shared vault can create the first folder at any time and a cached `false` would suppress
    /// the repair for exactly the case it exists to catch.
    public var foldersDetected: Bool

    public init(done: Bool,
                attempts: Int,
                lastAttempt: Date?,
                foldersDetected: Bool) {
        self.done = done
        self.attempts = attempts
        self.lastAttempt = lastAttempt
        self.foldersDetected = foldersDetected
    }
}

extension FolderForceSyncState: Defaultable {
    public static var `default`: Self {
        .init(done: false, attempts: 0, lastAttempt: nil, foldersDetected: false)
    }
}
