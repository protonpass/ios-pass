// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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
// swiftlint:disable all

@testable import Proton_Pass
import Client
import Core
import CryptoKit
import Entities
import Factory
import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking

final class CredentialsMigrationStateProviderMock: @unchecked Sendable, CredentialsMigrationStateProvider {
    // MARK: - shouldMigrateToSeparatedCredentials
    var closureShouldMigrateToSeparatedCredentials: () -> () = {}
    var invokedShouldMigrateToSeparatedCredentials = false
    var invokedShouldMigrateToSeparatedCredentialsCount = 0
    var stubbedShouldMigrateToSeparatedCredentialsResult: Bool!

    func shouldMigrateToSeparatedCredentials() -> Bool {
        invokedShouldMigrateToSeparatedCredentials = true
        invokedShouldMigrateToSeparatedCredentialsCount += 1
        closureShouldMigrateToSeparatedCredentials()
        return stubbedShouldMigrateToSeparatedCredentialsResult
    }
    // MARK: - markAsMigratedToSeparatedCredentials
    var closureMarkAsMigratedToSeparatedCredentials: () -> () = {}
    var invokedMarkAsMigratedToSeparatedCredentials = false
    var invokedMarkAsMigratedToSeparatedCredentialsCount = 0

    func markAsMigratedToSeparatedCredentials() {
        invokedMarkAsMigratedToSeparatedCredentials = true
        invokedMarkAsMigratedToSeparatedCredentialsCount += 1
        closureMarkAsMigratedToSeparatedCredentials()
    }
}
