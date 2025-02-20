//
// PassModule+Extensions.swift
// Proton Pass - Created on 30/10/2023.
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

import Entities
import Foundation
import Macro

public extension PassModule {
    var logTitle: String {
        switch self {
        case .hostApp:
            #localized("Application logs", bundle: .module)
        case .autoFillExtension:
            #localized("AutoFill extension logs", bundle: .module)
        case .shareExtension:
            #localized("Share extension logs", bundle: .module)
        case .actionExtension:
            #localized("Action extension logs", bundle: .module)
        }
    }

    var logFileName: String {
        switch self {
        case .hostApp:
            "pass_host_application.log"
        case .autoFillExtension:
            "pass_autofill_extension.log"
        case .shareExtension:
            "pass_share_extension.log"
        case .actionExtension:
            "pass_action_extension.log"
        }
    }

    var exportLogFileName: String {
        let hash = Bundle.main.gitCommitHash ?? "?"
        let fileName = switch self {
        case .hostApp:
            "pass_host_application_\(hash).log"
        case .autoFillExtension:
            "pass_autofill_extension\(hash).log"
        case .shareExtension:
            "pass_share_extension\(hash).log"
        case .actionExtension:
            "pass_action_extension\(hash).log"
        }
        return fileName
    }
}
