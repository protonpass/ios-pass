//
// CryptoSetup.swift
// Proton Pass - Created on 05/10/2026.
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

import ProtonCoreCryptoGoImplementation

/// ProtonCore's crypto implementation is a process-wide global that must be installed before any
/// `CryptoGo` call. Swift Testing runs suites in parallel and in random order, so every test that
/// needs it goes through this lazily initialised static, which runs exactly once whichever suite
/// reaches it first.
enum CryptoSetup {
    static let installed: Void = injectDefaultCryptoImplementation()
}
