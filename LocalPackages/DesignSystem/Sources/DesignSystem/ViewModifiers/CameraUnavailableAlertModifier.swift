//
// CameraUnavailableAlertModifier.swift
// Proton Pass - Created on 26/12/2024.
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

import SwiftUI

struct CameraUnavailableAlertModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert("Camera Unavailable",
                   isPresented: $isPresented,
                   actions: {
                       Button(role: nil, label: { Text("OK") })
                       Button(role: nil, action: openAppSettings, label: { Text("Settings") })
                   },
                   message: {
                       // swiftlint:disable:next line_length
                       Text("Privacy or Restrictions settings have disabled use of the camera. You can change this in Settings.")
                   })
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

public extension View {
    func cameraUnavailableAlert(isPresented: Binding<Bool>) -> some View {
        modifier(CameraUnavailableAlertModifier(isPresented: isPresented))
    }
}
