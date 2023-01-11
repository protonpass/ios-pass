//
//  TelemetrySection.swift
//  ProtonCore-Settings - Created on 08.11.2022.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import SwiftUI

@available(iOS 13.0, *)
public struct TelemetrySection: View {
    @ObservedObject private var viewModel: TelemetrySettingsViewModel
    
    public init(delegate: TelemetrySettingsDelegate?,
                telemetrySettingsService: TelemetrySettingsService) {
        viewModel = TelemetrySettingsViewModel(delegate: delegate, telemetrySettingsService: telemetrySettingsService)
    }

    public var body: some View {
        Section(content: {
            Toggle(isOn: $viewModel.isActive) {
                Text("Telemetry")
            }
        }, header: {
            Text("Telemetry")
        })
    }
}

@available(iOS 13.0, *)
struct TelemetrySection_Previews: PreviewProvider {
    static var previews: some View {
        TelemetrySection(delegate: nil,
                         telemetrySettingsService: TelemetrySettingsService())
    }
}
