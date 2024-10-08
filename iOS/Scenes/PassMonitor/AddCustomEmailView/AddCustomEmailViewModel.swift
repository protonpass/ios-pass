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
import Macro

@MainActor
final class AddCustomEmailViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published var code = ""
    @Published private(set) var finishedVerification = false
    @Published private(set) var verificationError: (any Error)?

    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let addCustomEmailToMonitoring = resolve(\UseCasesContainer.addCustomEmailToMonitoring)
    private let verifyCustomEmail = resolve(\UseCasesContainer.verifyCustomEmail)
    private let getAllCustomEmails = resolve(\UseCasesContainer.getAllCustomEmails)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    @Published private var type: ValidationEmailType

    var canContinue: Bool {
        if type.isNotEmpty {
            !code.isEmpty
        } else {
            !email.isEmpty && email.isValidEmail()
        }
    }

    var isVerificationMode: Bool {
        type.isNotEmpty
    }

    var isMailbox: Bool {
        type.isMailbox
    }

    init(validationType: ValidationEmailType) {
        type = validationType
        email = type.email ?? ""
    }

    func nextStep() {
        if type.isNotEmpty {
            verifyCode()
        } else {
            addCustomType()
        }
    }

    func sendVerificationCode() {
        guard type.isNotEmpty else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let message: String

                switch type {
                case let .customEmail(customEmail):
                    guard let customEmail else {
                        return
                    }
                    try await passMonitorRepository.resendEmailVerification(email: customEmail)
                case let .mailbox(mailbox):
                    guard let mailbox else {
                        return
                    }
                    let userId = try await userManager.getActiveUserId()
                    _ = try await aliasRepository.resendMailboxVerificationEmail(userId: userId,
                                                                                 mailboxID: mailbox.mailboxID)
                }
                message = #localized("New verification code sent")
                router.display(element: .successMessage(message))
            } catch {
                handle(error: error)
            }
        }
    }

    func verifyCode() {
        guard type.isNotEmpty, !code.isEmpty else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                switch type {
                case let .customEmail(customEmail):
                    guard let customEmail else {
                        return
                    }
                    try await verifyCustomEmail(email: customEmail, code: code)

                case let .mailbox(mailbox):
                    guard let mailbox else {
                        return
                    }
                    let userId = try await userManager.getActiveUserId()
                    _ = try await aliasRepository.verifyMailbox(userId: userId,
                                                                mailboxID: mailbox.mailboxID,
                                                                code: code)
                }
                finishedVerification = true
            } catch {
                if case .customEmail = type,
                   let apiError = error.asPassApiError,
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

    func addCustomType() {
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
                let lowercasedEmail = email.lowercased()
                switch type {
                case .customEmail:
                    let customEmail = try await addCustomEmailToMonitoring(email: lowercasedEmail)
                    type = .customEmail(customEmail)
                case .mailbox:
                    let userId = try await userManager.getActiveUserId()
                    let mailbox = try await aliasRepository.createMailbox(userId: userId, email: lowercasedEmail)
                    type = .mailbox(mailbox)
                }
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
