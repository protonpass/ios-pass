//
// TrashViewModel.swift
// Proton Pass - Created on 09/09/2022.
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

import Client
import Combine
import Core
import SwiftUI

protocol TrashViewModelDelegate: AnyObject {
    func trashViewModelWantsToToggleSidebar()
    func trashViewModelBeginsLoading()
    func trashViewModelStopsLoading()
    func trashViewModelDidFailWithError(error: Error)
}

final class TrashViewModel: DeinitPrintable, ObservableObject {
    weak var delegate: TrashViewModelDelegate?

    @Published private var isLoading = false
    @Published private var error: Error?

    @Published private(set) var isFetchingItems = false
    @Published private(set) var trashedItem = [PartialItemContent]()

    private var cancellables = Set<AnyCancellable>()

    init() {
        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.trashViewModelBeginsLoading()
                } else {
                    self.delegate?.trashViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.trashViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions
extension TrashViewModel {
    func toggleSidebar() {
        delegate?.trashViewModelWantsToToggleSidebar()
    }

    func restoreAllItems() {
        print(#function)
    }

    func emptyTrash() {
        print(#function)
    }
}
