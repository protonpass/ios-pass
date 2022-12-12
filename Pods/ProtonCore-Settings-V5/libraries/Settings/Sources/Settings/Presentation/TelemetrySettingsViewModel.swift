//
//  TelemetrySettingsViewModel.swift
//  ProtonCore-Settings - Created on 16.11.22.
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

@available(iOS 13.0, *)
class TelemetrySettingsViewModel: ObservableObject, PMSwitcher {
    func changeValue(to value: Bool, success: @escaping (Bool) -> Void) {
        isActive = value
        success(value)
    }
    
    weak var delegate: TelemetrySettingsDelegate?
    private let telemetrySettingsService: TelemetrySettingsServiceProtocol
    
    @Published var isActive: Bool {
        didSet {
            guard isActive != oldValue else { return }
            telemetrySettingsService.setIsTelemetryEnabled(state: isActive)
            delegate?.didSetTelemetry(isEnabled: isActive)
        }
    }
    
    init(delegate: TelemetrySettingsDelegate?, telemetrySettingsService: TelemetrySettingsServiceProtocol) {
        self.telemetrySettingsService = telemetrySettingsService
        self.isActive = telemetrySettingsService.isTelemetryEnabled
        self.delegate = delegate
    }
}
