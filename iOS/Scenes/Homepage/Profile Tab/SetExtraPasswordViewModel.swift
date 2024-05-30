//
// SetExtraPasswordViewModel.swift
// Proton Pass - Created on 30/05/2024.
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

import Combine
import Foundation
import Macro

enum SetExtraPasswordViewState {
    case defining, repeating

    var navigationTitle: String {
        switch self {
        case .defining:
            #localized("Set extra password")
        case .repeating:
            #localized("Repeat extra password")
        }
    }

    var placeholder: String {
        switch self {
        case .defining:
            #localized("Extra password")
        case .repeating:
            #localized("Confirm extra password")
        }
    }
}

@MainActor
final class SetExtraPasswordViewModel: ObservableObject {
    @Published private(set) var canContinue = false
    @Published private(set) var canSetExtraPassword = false
    @Published private(set) var state: SetExtraPasswordViewState = .defining
    @Published var showLogOutAlert = false
    @Published var showWrongProtonPasswordAlert = false
    @Published var showProtonPasswordConfirmationAlert = true
    @Published var protonPassword = ""
    @Published var extraPassword = ""

    private var definedExtraPassword = ""
    private var cancellables = Set<AnyCancellable>()

    init() {
        $extraPassword
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] password in
                guard let self else { return }
                switch state {
                case .defining:
                    canContinue = password.count >= 8
                case .repeating:
                    canContinue = password.count >= 8 && password == definedExtraPassword
                }
            }
            .store(in: &cancellables)
    }
}

extension SetExtraPasswordViewModel {
    func verifyProtonPassword() {
        guard protonPassword.count >= 8 else { return }
        if Bool.random() {
            canSetExtraPassword = true
        } else {
            showWrongProtonPasswordAlert = true
        }
    }

    func retryVerifyingProtonPassword() {
        protonPassword = ""
        showProtonPasswordConfirmationAlert = true
    }

    func `continue`() {
        switch state {
        case .defining:
            definedExtraPassword = extraPassword
            extraPassword = ""
            state = .repeating
        case .repeating:
            showLogOutAlert = true
        }
    }

    func proceedSetUp() {
        print(#function)
    }
}
