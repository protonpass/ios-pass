//
// NoteDetailViewModel.swift
// Proton Pass - Created on 07/09/2022.
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

protocol NoteDetailViewModelDelegate: AnyObject {
    func noteDetailViewModelBeginsLoading()
    func noteDetailViewModelStopsLoading()
    func noteDetailViewModelDidFailWithError(error: Error)
}

final class NoteDetailViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var name = ""
    @Published private(set) var note = ""

    private let itemContent: ItemContent
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: NoteDetailViewModelDelegate?

    init(itemContent: ItemContent,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.itemContent = itemContent
        self.itemRevisionRepository = itemRevisionRepository

        switch itemContent.contentData {
        case .note:
            self.name = itemContent.name
            self.note = itemContent.note

        default:
            fatalError("Expecting note type")
        }

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.noteDetailViewModelBeginsLoading()
                } else {
                    self.delegate?.noteDetailViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.noteDetailViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)
    }
}
