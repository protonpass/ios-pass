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
        case .autofill: return "Autofill"
        case .autosave: return "Autosave"
        case .aliases: return "Aliases"
        case .syncing: return "Syncing"
        case .featureRequest: return "Feature request"
        case .other: return "Other"
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
            self.isSending = true
            do {
                let plan = try await self.planRepository.getPlan()
                let planName = plan.type.capitalized
                let objectDescription = self.object?.description ?? ""
                let title = "[\(planName)] iOS Proton Pass: \(objectDescription)"
                if try await self.sendUserBugReport(with: title,
                                                    and: self.description,
                                                    shouldSendLogs: self.shouldSendLogs) {
                    self.hasSent = true
                } else {
                    self.error = SendError.failedToSendReport
                }
            } catch {
                self.error = error
            }
            self.isSending = false
        }
    }
}
