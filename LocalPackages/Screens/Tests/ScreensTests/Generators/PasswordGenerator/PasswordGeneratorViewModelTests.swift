//
// PasswordGeneratorViewModelTests.swift
// Proton Pass - Created on 15/10/2026.
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

@testable import Screens
import Client
import CoreMocks
import DIComposition
import Entities
import FactoryTesting
import Testing
import UseCases

@MainActor
@Suite(.tags(.viewModel),
       .timeLimit(.minutes(1)),
       .toolingContainer,
       .repositoryContainer,
       .useCasesContainer)
struct PasswordGeneratorViewModelTests {
    private let history = PasswordHistoryRepositoryStub()
    private let recorder = ResultRecorder()

    @Test func `confirming stores the password in history and delivers it`() async throws {
        let sut = makeSut()

        sut.handleCta()
        await recorder.waitForResults()

        #expect(history.insertedPasswords == [sut.password])
        let result = try #require(recorder.results.first)
        #expect(try result.get().value == sut.password)
    }

    @Test func `confirming again stores and delivers the password only once`() async {
        let sut = makeSut()

        sut.handleCta()
        sut.handleCta()
        await recorder.waitForResults()

        #expect(history.insertedPasswords.count == 1)
        #expect(recorder.results.count == 1)
    }

    @Test func `a failed history insert delivers the error`() async throws {
        history.insertError = PassError.unexpectedError
        let sut = makeSut()

        sut.handleCta()
        await recorder.waitForResults()

        #expect(history.insertedPasswords.isEmpty)
        let result = try #require(recorder.results.first)
        #expect(throws: PassError.self) { try result.get() }
    }

    @Test func `confirming again after a failed history insert stores and delivers the password`() async throws {
        history.insertError = PassError.unexpectedError
        let sut = makeSut()
        sut.handleCta()
        await recorder.waitForResults()

        history.insertError = nil
        sut.handleCta()
        await recorder.waitForResults(count: 2)

        #expect(history.insertedPasswords == [sut.password])
        let result = try #require(recorder.results.last)
        #expect(try result.get().value == sut.password)
    }
}

private extension PasswordGeneratorViewModelTests {
    func makeSut() -> PasswordGeneratorViewModel {
        ToolingContainer.shared.logManager.register { LogManagerProtocolMock() }
        RepositoryContainer.shared.localPasswordPreferencesDatasource
            .register { PasswordPreferencesDatasourceStub() }
        RepositoryContainer.shared.passwordHistoryRepository.register { [history] in history }
        UseCasesContainer.shared.getOrganizationSettings.register { OrganizationSettingsStub() }
        return PasswordGeneratorViewModel(mode: .random, onResult: recorder.record)
    }
}

/// Every job here runs on the main actor in FIFO order, so a second `handleCta` task (if one were
/// started) has finished by the time `waitForResults()` resumes.
@MainActor
private final class ResultRecorder {
    private(set) var results = [Result<GeneratedPassword, any Error>]()
    private var waiter: CheckedContinuation<Void, Never>?

    func record(_ result: Result<GeneratedPassword, any Error>) {
        results.append(result)
        waiter?.resume()
        waiter = nil
    }

    func waitForResults(count: Int = 1) async {
        while results.count < count {
            await withCheckedContinuation { waiter = $0 }
        }
    }
}

@MainActor
private final class PasswordHistoryRepositoryStub: PasswordHistoryRepositoryProtocol {
    private(set) var insertedPasswords = [String]()
    var insertError: (any Error)?

    @MainActor
    func insertPassword(_ clearPassword: String) async throws {
        if let insertError {
            throw insertError
        }
        insertedPasswords.append(clearPassword)
    }

    func getAllPasswords() async throws -> [PasswordHistoryEntryUiModel] {
        []
    }

    func getClearPassword(id: String) async throws -> String? {
        nil
    }

    func deletePassword(id: String) async throws {}
    func deleteAllPasswords() async throws {}
    func cleanUpOldPasswords() async throws {}
}

private struct PasswordPreferencesDatasourceStub: LocalPasswordPreferencesDatasourceProtocol {
    func save(preferences: PasswordPreferences) {}
    func getPreferences() -> PasswordPreferences {
        .default
    }
}

private struct OrganizationSettingsStub: GetOrganizationSettingsUseCase {
    func execute() async throws -> Organization.Settings? {
        nil
    }
}
