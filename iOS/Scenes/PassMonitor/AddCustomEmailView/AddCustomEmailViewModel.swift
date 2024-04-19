//
//
// AddCustomEmailViewModel.swift
// Proton Pass - Created on 18/04/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Entities
import Factory
import Foundation

@MainActor
final class AddCustomEmailViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published var code = ""
    @Published var isMonitored = false
    @Published var loading = false
    @Published var finishedVerification = false
    @Published var canResendCode = true
    @Published var timeRemaining: Int = 120

    private let breachRepository = resolve(\RepositoryContainer.breachRepository)
    private var timerTask: Task<Void, Never>?
    private var currentCustomEmail: CustomEmail?
    let totalTime: Int = 120

    var canContinue: Bool {
        if isMonitored, !code.isEmpty {
            return true
        } else if !isMonitored, !email.isEmpty, email.isValidEmail() {
            return true
        }
        return false
    }

    init(email: CustomEmail?,
         isMonitored: Bool) {
        currentCustomEmail = email
        self.email = email?.email ?? ""
        self.isMonitored = isMonitored
        setUp()
    }

    deinit {
        timerTask?.cancel()
        timerTask = nil
    }

    func nextStep() {
        if isMonitored {
            verifyCode()
        } else {
            addCustomEmail()
        }
    }

    func sendVerificationCode() {
        guard let currentCustomEmail else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                try await breachRepository.resendEmailVerification(emailId: currentCustomEmail.customEmailID)
                startTimer()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func verifyCode() {
        guard let currentCustomEmail, !code.isEmpty else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                try await breachRepository.verifyCustomEmail(emailId: currentCustomEmail.customEmailID,
                                                             code: code)
                // This is done to update emails displayed in home view
                _ = try await breachRepository.getAllCustomEmailForUser()
                finishedVerification = true
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func addCustomEmail() {
        guard email.isValidEmail() else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                currentCustomEmail = try await breachRepository.addEmailToBreachMonitoring(email: email)
                // This is done to update emails displayed in home view
                _ = try await breachRepository.getAllCustomEmailForUser()
                isMonitored = true
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func startTimer() {
        canResendCode = false
        timerTask = Task { [weak self] in
            guard let self else {
                return
            }
            while timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                timeRemaining -= 1
            }
            stopTimer()
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        canResendCode = true
    }

    func resetTimer() {
        stopTimer() // Ensure any existing timer is stopped before restarting
        timeRemaining = totalTime
        startTimer()
    }
}

private extension AddCustomEmailViewModel {
    func setUp() {
        startTimer()
    }
}
