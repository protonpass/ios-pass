//
// View+AssociateUrlAlert.swift
// Proton Pass - Created on 19/09/2024.
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
import SwiftUI

private struct AssociateUrlAlertModifier: ViewModifier {
    @Binding var information: UnmatchedItemAlertInformation?
    let onAssociateAndAutofill: (any ItemIdentifiable) -> Void
    let onJustAutofill: (any ItemIdentifiable) -> Void

    func body(content: Content) -> some View {
        content
            .alert("Associate URL?",
                   isPresented: $information.mappedToBool(),
                   actions: {
                       if let information {
                           Button(action: {
                               onAssociateAndAutofill(information.item)
                           }, label: {
                               Text("Associate and autofill")
                           })

                           Button(action: {
                               onJustAutofill(information.item)
                           }, label: {
                               Text("Just autofill")
                           })
                       }

                       Button(role: .cancel) {
                           Text("Cancel")
                       }
                   },
                   message: {
                       if let information {
                           // swiftlint:disable:next line_length
                           Text("Would you want to associate « \(information.url) » with « \(information.item.itemTitle) »?")
                       }
                   })
    }
}

extension View {
    func associateUrlAlert(information: Binding<UnmatchedItemAlertInformation?>,
                           onAssociateAndAutofill: @escaping (any ItemIdentifiable) -> Void,
                           onJustAutofill: @escaping (any ItemIdentifiable) -> Void) -> some View {
        modifier(AssociateUrlAlertModifier(information: information,
                                           onAssociateAndAutofill: onAssociateAndAutofill,
                                           onJustAutofill: onJustAutofill))
    }
}
