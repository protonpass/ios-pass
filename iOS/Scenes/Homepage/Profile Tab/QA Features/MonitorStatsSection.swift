//
// MonitorStatsSection.swift
// Proton Pass - Created on 07/10/2026.
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

import Core
import SwiftUI
import UseCases

struct MonitorStatsSection: View {
    @State private var lastSentDate = Self.storedLastSentDate

    var body: some View {
        VStack(alignment: .leading) {
            Text(verbatim: "Monitor stats last sent: \(lastSentDescription)")
            Text(verbatim: "Reset to resend stats on next foreground (business plan only)")
                .foregroundStyle(.secondary)
                .font(.footnote)

            Button(action: reset, label: {
                Text(verbatim: "Reset send monitor stats threshold")
            })
            .disabled(lastSentDate == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension MonitorStatsSection {
    static var storedLastSentDate: Date? {
        kSharedUserDefaults.object(forKey: SendUserMonitoringStats.lastSentTimestampKey) as? Date
    }

    var lastSentDescription: String {
        lastSentDate?.formatted(date: .abbreviated, time: .standard) ?? "never"
    }

    func reset() {
        kSharedUserDefaults.removeObject(forKey: SendUserMonitoringStats.lastSentTimestampKey)
        lastSentDate = Self.storedLastSentDate
    }
}
