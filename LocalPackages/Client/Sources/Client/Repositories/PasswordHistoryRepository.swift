//
// PasswordHistoryRepository.swift
// Proton Pass - Created on 09/04/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import CryptoKit
import Entities
import Foundation

extension SymmetricKey: @unchecked @retroactive Sendable {}

public protocol PasswordHistoryRepositoryProtocol: Sendable {
    func insertPassword(_ clearPassword: String) async throws
    func getAllPasswords() async throws -> [GeneratedPasswordUiModel]
    func getClearPassword(id: String) async throws -> String?
    func deletePassword(id: String) async throws
    func deleteAllPasswords() async throws
    func cleanUpOldPasswords() async throws
}

public actor PasswordHistoryRepository: PasswordHistoryRepositoryProtocol {
    let datasource: any LocalPasswordDatasourceProtocol
    let currentDateProvider: any CurrentDateProviderProtocol
    let randomUuidProvider: any RandomUuidProviderProtocol
    let symmetricKeyProvider: any SymmetricKeyProvider
    let logger: Logger
    let retentionDayCount: Int

    public init(datasource: any LocalPasswordDatasourceProtocol,
                currentDateProvider: any CurrentDateProviderProtocol,
                randomUuidProvider: any RandomUuidProviderProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                logManager: any LogManagerProtocol,
                retentionDayCount: Int = 14) {
        self.datasource = datasource
        self.currentDateProvider = currentDateProvider
        self.randomUuidProvider = randomUuidProvider
        self.symmetricKeyProvider = symmetricKeyProvider
        logger = .init(manager: logManager)
        self.retentionDayCount = retentionDayCount
    }
}

public extension PasswordHistoryRepository {
    func insertPassword(_ clearPassword: String) async throws {
        logger.trace("Inserting password")
        let id = randomUuidProvider.randomUuid()
        let currentDate = currentDateProvider.getCurrentDate()
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let encryptedPassword = try symmetricKey.encrypt(clearPassword)
        try await datasource.insertPassword(id: id,
                                            symmetricallyEncryptedValue: encryptedPassword,
                                            creationTime: currentDate.timeIntervalSince1970)
        logger.debug("Inserted password")
    }

    func getAllPasswords() async throws -> [GeneratedPasswordUiModel] {
        logger.trace("Getting all passwords")
        let passwords = try await datasource.getAllPasswords()
        logger.trace("Found \(passwords.count) passwords")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let relativeDateFormatter = RelativeDateTimeFormatter()

        return passwords.map { password in
            let date = Date(timeIntervalSince1970: TimeInterval(password.creationTimestamp))
            let dateString = dateFormatter.string(from: date)
            let relativeString = relativeDateFormatter.localizedString(for: date, relativeTo: .now)
            return .init(id: password.id,
                         relativeCreationDate: "\(dateString) (\(relativeString))",
                         visibility: .masked)
        }
    }

    func getClearPassword(id: String) async throws -> String? {
        logger.trace("Getting clear password for id \(id)")
        guard let encryptedPassword = try await datasource.getEncryptedPassword(id: id) else {
            logger.warning("No encrypted password found for id \(id)")
            return nil
        }
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let clearPassword = try symmetricKey.decrypt(encryptedPassword)
        logger.trace("Got clear password for id \(id)")
        return clearPassword
    }

    func deletePassword(id: String) async throws {
        logger.trace("Deleting password for id \(id)")
        try await datasource.deletePassword(id: id)
        logger.trace("Deleted password for id \(id)")
    }

    func deleteAllPasswords() async throws {
        logger.trace("Deleting all passwords")
        try await datasource.deleteAllPasswords()
        logger.trace("Deleted all passwords")
    }

    func cleanUpOldPasswords() async throws {
        logger.trace("Cleaning up old passwords")
        let currentDate = currentDateProvider.getCurrentDate()
        let cutOffDate = currentDate.adding(component: .day, value: -retentionDayCount)
        try await datasource.deletePasswords(cutOffTimestamp: Int(cutOffDate.timeIntervalSince1970))
        logger.trace("Cleaned up old passwords")
    }
}
