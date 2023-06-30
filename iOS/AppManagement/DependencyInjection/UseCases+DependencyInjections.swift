//
// UseCases+DependencyInjections.swift
// Proton Pass - Created on 29/06/2023.
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

import Core
import Factory
import Foundation

final class UseCasesContainer: SharedContainer {
    static let shared = UseCasesContainer()
    let manager = ContainerManager()
}

// MARK: Feedback

extension UseCasesContainer {
    var sendUserFeedBack: Factory<SendUserFeedBackUseCase> {
        self { SendUserFeedBack(feedBackService: ServiceContainer.shared.feedBackService(),
                                extractLogsToData: self.extractLogsToData(),
                                getLogEntries: self.getLogEntries()) }
    }

    var setUserFeedBackIdentity: Factory<SetUserFeedBackIdentityUseCase> {
        self { SetUserFeedBackIdentity(feedBackService: ServiceContainer.shared.feedBackService()) }
    }
}

// MARK: Logs

extension UseCasesContainer {
    var extractLogsToFile: Factory<ExtractLogsToFileUseCase> {
        self { ExtractLogsToFile(logFormatter: SharedToolingContainer.shared.defaultLogFormatter()) }
    }

    var extractLogsToData: Factory<ExtractLogsToDataUseCase> {
        self { ExtractLogsToData(logFormatter: SharedToolingContainer.shared.defaultLogFormatter()) }
    }

    var getLogEntries: Factory<GetLogEntriesUseCase> {
        self { GetLogEntries(mainAppLogManager: ToolingContainer.shared.logManager(),
                             autofillLogManager: SharedToolingContainer.shared.autoFillLogManager(),
                             keyboardLogManager: SharedToolingContainer.shared.keyboardLogManager()) }
    }
}

extension UseCasesContainer: AutoRegistering {
    func autoRegister() {
        manager.defaultScope = .shared
    }
}
