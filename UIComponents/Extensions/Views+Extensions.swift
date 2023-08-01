//
// Views+Extensions.swift
// Proton Pass - Created on 24/07/2023.
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

import Entities
import SwiftUI

public extension View {
    func navigate(isActive: Binding<Bool>,
                  destination: (some View)?) -> some View {
        background(NavigationLink(destination: destination,
                                  isActive: isActive,
                                  label: EmptyView.init)
                .isDetailLink(false)
                .hidden())
    }

    func errorLocalizedAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        return alert(isPresented: .constant(localizedAlertError != nil), error: localizedAlertError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}

// MARK: - ViewBuilders

public extension View {
    @ViewBuilder
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        if let unwrappedError = error.wrappedValue {
            alert(unwrappedError.localizedDescription,
                  isPresented: .constant(true)) {
                Button(buttonTitle) {
                    error.wrappedValue = nil
                }
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func navigationModifier() -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                self
            }
        } else {
            NavigationView {
                self
            }
            .navigationViewStyle(.stack)
        }
    }
}

// MARK: - Modifier helpers

public extension View {
    func syncLayoutOnDisappear() -> some View {
        modifier(SyncLayoutOnDisappear())
    }
}
