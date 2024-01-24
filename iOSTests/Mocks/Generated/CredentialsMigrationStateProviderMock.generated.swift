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

@testable import Proton_Pass
import Foundation

public final class CredentialsMigrationStateProviderMock: @unchecked Sendable, CredentialsMigrationStateProvider {

    public init() {}

    // MARK: - shouldMigrateToSeparatedCredentials
    public var closureShouldMigrateToSeparatedCredentials: () -> () = {}
    public var invokedShouldMigrateToSeparatedCredentialsfunction = false
    public var invokedShouldMigrateToSeparatedCredentialsCount = 0
    public var stubbedShouldMigrateToSeparatedCredentialsResult: Bool!

    public func shouldMigrateToSeparatedCredentials() -> Bool {
        invokedShouldMigrateToSeparatedCredentialsfunction = true
        invokedShouldMigrateToSeparatedCredentialsCount += 1
        closureShouldMigrateToSeparatedCredentials()
        return stubbedShouldMigrateToSeparatedCredentialsResult
    }
    // MARK: - markAsMigratedToSeparatedCredentials
    public var closureMarkAsMigratedToSeparatedCredentials: () -> () = {}
    public var invokedMarkAsMigratedToSeparatedCredentialsfunction = false
    public var invokedMarkAsMigratedToSeparatedCredentialsCount = 0

    public func markAsMigratedToSeparatedCredentials() {
        invokedMarkAsMigratedToSeparatedCredentialsfunction = true
        invokedMarkAsMigratedToSeparatedCredentialsCount += 1
        closureMarkAsMigratedToSeparatedCredentials()
    }
    // MARK: - shouldMigrateCredentialsToShareExtension
    public var closureShouldMigrateCredentialsToShareExtension: () -> () = {}
    public var invokedShouldMigrateCredentialsToShareExtensionfunction = false
    public var invokedShouldMigrateCredentialsToShareExtensionCount = 0
    public var stubbedShouldMigrateCredentialsToShareExtensionResult: Bool!

    public func shouldMigrateCredentialsToShareExtension() -> Bool {
        invokedShouldMigrateCredentialsToShareExtensionfunction = true
        invokedShouldMigrateCredentialsToShareExtensionCount += 1
        closureShouldMigrateCredentialsToShareExtension()
        return stubbedShouldMigrateCredentialsToShareExtensionResult
    }
    // MARK: - markAsMigratedCredentialsToShareExtension
    public var closureMarkAsMigratedCredentialsToShareExtension: () -> () = {}
    public var invokedMarkAsMigratedCredentialsToShareExtensionfunction = false
    public var invokedMarkAsMigratedCredentialsToShareExtensionCount = 0

    public func markAsMigratedCredentialsToShareExtension() {
        invokedMarkAsMigratedCredentialsToShareExtensionfunction = true
        invokedMarkAsMigratedCredentialsToShareExtensionCount += 1
        closureMarkAsMigratedCredentialsToShareExtension()
    }
}
