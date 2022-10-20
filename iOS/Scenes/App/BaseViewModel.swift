//
// BaseViewModel.swift
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

import Combine

protocol BaseViewModelDelegate: AnyObject {
    func viewModelBeginsLoading()
    func viewModelStopsLoading()
    func viewModelDidFailWithError(_ error: Error)
}

class BaseViewModel {
    @Published var isLoading = false
    @Published var error: Error?
    weak var delegate: BaseViewModelDelegate?
    var cancellables = Set<AnyCancellable>()

    init() {
        $isLoading
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    self.delegate?.viewModelBeginsLoading()
                } else {
                    self.delegate?.viewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self else { return }
                if let error {
                    self.delegate?.viewModelDidFailWithError(error)
                }
            }
            .store(in: &cancellables)
    }
}
