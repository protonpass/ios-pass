//
// OpenAutoFillSettings.swift
// Proton Pass - Created on 11/12/2023.
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

import UIKit

@MainActor
protocol OpenAutoFillSettingsUseCase: Sendable {
    func execute()
}

extension OpenAutoFillSettingsUseCase {
    func callAsFunction() {
        execute()
    }
}

@MainActor
final class OpenAutoFillSettings: OpenAutoFillSettingsUseCase {
    private let router: MainUIKitSwiftUIRouter

    init(router: MainUIKitSwiftUIRouter) {
        self.router = router
    }

    func execute() {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            router.present(for: .autoFillInstructions)
        } else {
            UIApplication.shared.openPasswordSettings()
        }
    }
}
