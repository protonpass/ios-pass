//
//  PMAboutConfiguration+Defaults.swift
//  ProtonCore-Settings - Created on 22.10.2020.
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

import UIKit

@available(iOSApplicationExtension, unavailable)
extension PMAboutConfiguration {
    public static var privacy: PMAboutConfiguration {
        PMAboutConfiguration(
            title: "pmsettings-settings-about-privacy",
            action: .perform(openPrivacyPolicy),
            bundle: PMSettings.bundle)
    }

    public static var terms: PMAboutConfiguration {
        PMAboutConfiguration(
            title: "pmsettings-settings-about-terms",
            action: .perform(openTermsOfService),
            bundle: PMSettings.bundle)
    }

    private static func openPrivacyPolicy() {
        guard let url = URL(string: "https://proton.me/legal/privacy") else { return }
        appOpen(url: url)
    }

    private static func openTermsOfService() {
        guard let url = URL(string: "https://proton.me/legal/terms") else { return }
        appOpen(url: url)
    }

    public static func appOpen(url: URL) {
        UIApplication.shared.open(url)
    }
}

extension PMAcknowledgementsConfiguration {
    public static func acknowledgements(url: URL) -> PMAcknowledgementsConfiguration {
        PMAcknowledgementsConfiguration(
            title: "pmsettings-settings-about-acknowledgements",
            url: url,
            bundle: PMSettings.bundle)
    }

    static func assembleAcknowledgmentsScreen(title: String?, url: URL) -> UIViewController {
        let viewModel = PMAcknowledgementsViewModel(title: title, url: url)
        return PMAcknowledgementsViewController(vm: viewModel)
    }
}
