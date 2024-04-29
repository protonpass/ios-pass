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
    @Published private(set) var finishedVerification = false
    @Published private(set) var canResendCode = false
    @Published private(set) var customEmail: CustomEmail?
    @Published private var secondsRemaining: Int

    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let addCustomEmailToMonitoring = resolve(\UseCasesContainer.addCustomEmailToMonitoring)
    private let verifyCustomEmail = resolve(\UseCasesContainer.verifyCustomEmail)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)

    private var timerTask: Task<Void, Never>?
    private let totalSeconds = 30

    var canContinue: Bool {
        if customEmail != nil {
            !code.isEmpty
        } else {
            !email.isEmpty && email.isValidEmail()
        }
    }

    var timeRemaining: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init(email: CustomEmail?) {
        customEmail = email
        self.email = email?.email ?? ""
        secondsRemaining = totalSeconds
        if customEmail != nil {
            startTimer()
        }
    }

    deinit {
        timerTask?.cancel()
        timerTask = nil
    }

    func nextStep() {
        if customEmail != nil {
            verifyCode()
        } else {
            addCustomEmail()
        }
    }

    func sendVerificationCode() {
        guard let customEmail else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                try await passMonitorRepository.resendEmailVerification(emailId: customEmail.customEmailID)
                resetTimer()
            } catch {
                handle(error: error)
            }
        }
    }

    func verifyCode() {
        guard let customEmail, !code.isEmpty else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                try await verifyCustomEmail(email: customEmail, code: code)
                finishedVerification = true
            } catch {
                handle(error: error)
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
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                customEmail = try await addCustomEmailToMonitoring(email: email.lowercased())
                startTimer()
            } catch {
                handle(error: error)
            }
        }
    }

    func startTimer() {
        canResendCode = false
        timerTask = Task { [weak self] in
            guard let self else {
                return
            }
            while secondsRemaining > 0 {
                try? await Task.sleep(seconds: 1)
                secondsRemaining -= 1
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
        secondsRemaining = totalSeconds
        startTimer()
    }
}

private extension AddCustomEmailViewModel {
    func handle(error: Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
