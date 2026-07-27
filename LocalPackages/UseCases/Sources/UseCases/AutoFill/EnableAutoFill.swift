//
// EnableAutoFill.swift
// Proton Pass - Created on 17/07/2026.
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

import Client
import UIKit

public enum EnableAutoFillOutcome: Sendable, Equatable {
    /// iOS app on Mac: programmatic enablement unavailable, caller must present manual instructions.
    case instructionsRequired
    /// iOS 18+: system flow ran; `enabled` is the user's actual choice.
    case completed(enabled: Bool)
    /// Pre-iOS 18: deep-linked to password settings; real outcome unknowable.
    case redirectedToSettings
}

public extension EnableAutoFillOutcome {
    /// Preserves the legacy `Bool` semantics of `execute()`.
    var handled: Bool {
        switch self {
        case .instructionsRequired, .redirectedToSettings: true
        case let .completed(enabled): enabled
        }
    }

    var needsInstructions: Bool {
        self == .instructionsRequired
    }
}

public protocol EnableAutoFillUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction() async -> EnableAutoFillOutcome
}

public struct EnableAutoFill: EnableAutoFillUseCase {
    private let credentialManager: any CredentialManagerProtocol
    private let isiOSAppOnMac: Bool

    public init(credentialManager: any CredentialManagerProtocol,
                isiOSAppOnMac: Bool = ProcessInfo.processInfo.isiOSAppOnMac) {
        self.credentialManager = credentialManager
        self.isiOSAppOnMac = isiOSAppOnMac
    }

    @MainActor
    @discardableResult
    public func callAsFunction() async -> EnableAutoFillOutcome {
        if isiOSAppOnMac {
            return .instructionsRequired
        }
        if #available(iOS 18, *) {
            return await .completed(enabled: credentialManager.enableAutoFill())
        } else {
            UIApplication.shared.openPasswordSettings()
            return .redirectedToSettings
        }
    }
}
