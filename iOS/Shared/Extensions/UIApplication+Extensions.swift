//
// UIApplication+Extensions.swift
// Proton Pass - Created on 08/12/2022.
// Copyright (c) 2022 Proton Technologies AG
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

@available(iOSApplicationExtension, unavailable)
extension UIApplication {
    func openPasswordSettings() {
        open(urlString: "App-prefs:PASSWORDS")
    }

    func openAppSettings() {
        open(urlString: UIApplication.openSettingsURLString)
    }

    private func open(urlString: String) {
        guard let url = URL(string: urlString), canOpenURL(url) else { return }
        open(url)
    }

    var isSplitOrSlideOver: Bool {
        guard let keyWindow else { return false }
        return !(keyWindow.frame.width == keyWindow.screen.bounds.width)
    }

    var keyWindow: UIWindow? {
        // Get connected scenes
        connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .first(where: { $0.activationState == .foregroundActive && $0 is UIWindowScene })
            // Get its associated windows
            .flatMap { $0 as? UIWindowScene }?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
}
