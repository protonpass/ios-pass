//
//  PMSettingsViewModel.swift
//  ProtonCore-Settings - Created on 24.09.2020.
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

public final class PMSettingsViewModel: PMSettingsViewModelProtocol {
    public let sections: [PMSettingsSectionViewModel]
    public let version: String

    public init(sections: [PMSettingsSectionViewModel], version: String) {
        self.sections = sections
        self.version = version
    }

    public var pageTitle: String {
        "pmsettings-settings-title".localized
    }

    public var footer: String? {
        String(format: "pmsettings-settings-footer".localized, version)
    }
}
