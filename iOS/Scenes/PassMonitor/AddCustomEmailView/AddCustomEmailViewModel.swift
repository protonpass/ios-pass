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
    @Published private var customEmail: CustomEmail?
    @Published private(set) var verificationError: (any Error)?

    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let addCustomEmailToMonitoring = resolve(\UseCasesContainer.addCustomEmailToMonitoring)
    private let verifyCustomEmail = resolve(\UseCasesContainer.verifyCustomEmail)
    private let getAllCustomEmails = resolve(\UseCasesContainer.getAllCustomEmails)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)

    var canContinue: Bool {
        if customEmail != nil {
            !code.isEmpty
        } else {
            !email.isEmpty && email.isValidEmail()
        }
    }

    var isVerificationMode: Bool {
        customEmail != nil
    }

    init(email: CustomEmail?) {
        customEmail = email
        self.email = email?.email ?? ""
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
                if let apiError = error.asPassApiError,
                   case .notAllowed = apiError {
                    // Custom email is removed or too many failed verifications
                    if let customEmails = try? await getAllCustomEmails() {
                        passMonitorRepository.darkWebDataSectionUpdate.send(.customEmails(customEmails))
                    }
                    verificationError = error
                } else {
                    handle(error: error)
                }
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
            } catch {
                handle(error: error)
            }
        }
    }
}

private extension AddCustomEmailViewModel {
    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
