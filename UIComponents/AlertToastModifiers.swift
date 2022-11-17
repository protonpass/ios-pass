//
// AlertToastModifiers.swift
// Proton Pass - Created on 19/08/2022.
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

import AlertToast
import SwiftUI

public let kDefaultToastDuration = 3.5

public extension View {
    func alertToastSuccessMessage(_ message: Binding<String?>,
                                  duration: Double = kDefaultToastDuration) -> some View {
        let binding = Binding<Bool>(get: {
            message.wrappedValue != nil
        }, set: { isPresenting in
            if !isPresenting {
                message.wrappedValue = nil
            }
        })
        return toast(isPresenting: binding, duration: duration) {
            AlertToast(displayMode: .banner(.pop),
                       type: .regular,
                       title: message.wrappedValue,
                       style: .style(backgroundColor: .notificationSuccess,
                                     titleColor: .white,
                                     subTitleColor: nil,
                                     titleFont: .body,
                                     subTitleFont: nil))
        }
    }

    func alertToastInformativeMessage(_ message: Binding<String?>,
                                      duration: Double = kDefaultToastDuration) -> some View {
        let binding = Binding<Bool>(get: {
            message.wrappedValue != nil
        }, set: { isPresenting in
            if !isPresenting {
                message.wrappedValue = nil
            }
        })
        return toast(isPresenting: binding, duration: duration) {
            AlertToast(displayMode: .banner(.pop),
                       type: .regular,
                       title: message.wrappedValue,
                       style: .style(backgroundColor: .primary,
                                     titleColor: Color(.systemBackground),
                                     subTitleColor: nil,
                                     titleFont: .body,
                                     subTitleFont: nil))
        }
    }
}
