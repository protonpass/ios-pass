//
// SetUpSentry.swift
// Proton Pass - Created on 22/11/2023.
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
//

import Core
import Sentry

public protocol SetUpSentryUseCase {
    func execute(bundle: Bundle)
}

public extension SetUpSentryUseCase {
    func callAsFunction(bundle: Bundle) {
        execute(bundle: bundle)
    }
}

public final class SetUpSentry: SetUpSentryUseCase {
    public init() {}

    public func execute(bundle: Bundle) {
        SentrySDK.start { options in
            options.dsn = bundle.plistString(for: .sentryDSN, in: .prod)
            if ProcessInfo.processInfo.environment["me.proton.pass.SentryDebug"] == "1" {
                options.debug = true
            }
            options.enableAppHangTracking = true
            options.enableFileIOTracing = true
            options.enableCoreDataTracing = true
            options.attachViewHierarchy = true // EXPERIMENTAL
            options.environment = ProtonPassDoH(bundle: bundle).environment.name
        }
    }
}
