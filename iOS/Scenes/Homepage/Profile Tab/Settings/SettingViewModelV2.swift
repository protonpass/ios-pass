//
// SettingViewModelV2.swift
// Proton Pass - Created on 31/03/2023.
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

import Combine
import Core
import SwiftUI

protocol SettingViewModelDelegateV2: AnyObject {
    func settingViewModelWantsToGoBack()
    func settingViewModelWantsToEditDefaultBrowser(supportedBrowsers: [Browser])
}

final class SettingViewModelV2: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let preferences: Preferences

    let supportedBrowsers: [Browser]
    @Published private(set) var selectedBrowser: Browser

    weak var delegate: SettingViewModelDelegateV2?
    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences) {
        self.preferences = preferences
        let installedBrowsers = Browser.thirdPartyBrowsers.filter { browser in
            guard let appScheme = browser.appScheme,
                  let testUrl = URL(string: appScheme + "proton.me") else {
                return false
            }
            return UIApplication.shared.canOpenURL(testUrl)
        }
        // Double check selected browser here. If it's no more avaible (uninstalled).
        // Fallback to Safari
        self.selectedBrowser = installedBrowsers.contains(preferences.browser) ?
        preferences.browser : .safari
        self.supportedBrowsers = [.safari, .inAppSafari] + installedBrowsers

        preferences
            .objectWillChange
            .sink { [unowned self] in
                self.selectedBrowser = self.preferences.browser
            }
            .store(in: &cancellables)
    }
}

// MARK: - Public APIs
extension SettingViewModelV2 {
    func goBack() {
        delegate?.settingViewModelWantsToGoBack()
    }

    func editDefaultBrowser() {
        delegate?.settingViewModelWantsToEditDefaultBrowser(supportedBrowsers: supportedBrowsers)
    }
}
