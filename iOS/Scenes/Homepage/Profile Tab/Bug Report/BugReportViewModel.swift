//
// BugReportViewModel.swift
// Proton Pass - Created on 28/06/2023.
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

import Client
import Factory
import Foundation

enum BugReportObject: CaseIterable {
    case autofill, autosave, aliases, syncing, featureRequest, other

    var description: String {
        switch self {
        case .autofill:
            "AutoFill".localized
        case .autosave:
            "Autosave".localized
        case .aliases:
            "Aliases".localized
        case .syncing:
            "Syncing".localized
        case .featureRequest:
            "Feature request".localized
        case .other:
            "Other".localized
        }
    }
}

@MainActor
final class BugReportViewModel: ObservableObject {
    @Published var object: BugReportObject?
    @Published var description = ""
    @Published private(set) var error: Error?
    @Published private(set) var hasSent = false
    @Published private(set) var isSending = false
    @Published var shouldSendLogs = true

    var cantSend: Bool { object == nil || description.count < 10 }

    private let planRepository = resolve(\SharedRepositoryContainer.passPlanRepository)
    private let sendUserBugReport = resolve(\UseCasesContainer.sendUserBugReport)

    enum SendError: Error {
        case failedToSendReport
    }

    init() {}

    func send() {
        assert(object != nil, "An object must be selected")
        Task { [weak self] in
            guard let self else { return }
            isSending = true
            do {
                let plan = try await planRepository.getPlan()
                let planName = plan.type.capitalized
                let objectDescription = object?.description ?? ""
                let title = "[\(planName)] iOS Proton Pass: \(objectDescription)"
                if try await sendUserBugReport(with: title,
                                               and: description,
                                               shouldSendLogs: shouldSendLogs) {
                    hasSent = true
                } else {
                    error = SendError.failedToSendReport
                }
            } catch {
                self.error = error
            }
            isSending = false
        }
    }
}
