//
// PassMonitorSection.swift
// Proton Pass - Created on 19/04/2024.
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

import Entities
import Factory
import SwiftUI

struct PassMonitorSection: View {
    private let repository = resolve(\SharedRepositoryContainer.passMonitorRepository)

    var body: some View {
        Section(content: {
            Button(action: { updateState(.inactive(.noBreaches)) },
                   label: { Text(verbatim: "Monitor inactive - No breaches") })

            Button(action: { updateState(.inactive(.noBreachesButWeakOrReusedPasswords)) },
                   label: { Text(verbatim: "Monitor inactive - No breaches but weak/reused passwords") })

            Button(action: { updateState(.inactive(.breachesFound)) },
                   label: { Text(verbatim: "Monitor inactive - Breaches found") })

            Button(action: { updateState(.active(.noBreaches)) },
                   label: { Text(verbatim: "Monitor active - No breaches") })

            Button(action: { updateState(.active(.noBreachesButWeakOrReusedPasswords)) },
                   label: { Text(verbatim: "Monitor active - No breaches but weak/reused passwords") })

            Button(action: { updateState(.active(.breachesFound)) },
                   label: { Text(verbatim: "Monitor active - Breaches found") })
        }, header: {
            Text(verbatim: "Pass monitor")
        })
    }

    func updateState(_ newValue: MonitorState) {
        Task {
            await repository.updateState(newValue)
        }
    }
}
