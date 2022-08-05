//
// CreateNoteViewModel.swift
// Proton Pass - Created on 25/07/2022.
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

import Combine
import Core
import SwiftUI

protocol CreateNoteViewModelDelegate: AnyObject {
    func createNoteViewModelBeginsLoading()
    func createNoteViewModelStopsLoading()
    func createNoteViewModelDidFailWithError(error: Error)
}

final class CreateNoteViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var name = ""
    @Published var note = ""

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: CreateNoteViewModelDelegate?

    init() {
        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.createNoteViewModelBeginsLoading()
                } else {
                    self.delegate?.createNoteViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.createNoteViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)
    }

    func saveAction() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.error = AppCoordinatorError.noSessionData
            }
        }
    }
}
