//
// LogInDetailViewModel.swift
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

protocol LogInDetailViewModelDelegate: AnyObject {
    func logInDetailViewModelBeginsLoading()
    func logInDetailViewModelStopsLoading()
    func logInDetailViewModelDidFailWithError(error: Error)
}

enum LogInDetailViewModelError: Error {
    case itemRevisionNotFound(shareId: String, itemId: String)
}

final class LogInDetailViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var name = ""
    @Published private(set) var username = ""
    @Published private(set) var urls: [String] = []
    @Published private(set) var password = ""
    @Published private(set) var note = ""

    private let itemContent: ItemContent
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: LogInDetailViewModelDelegate?

    init(itemContent: ItemContent,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.itemContent = itemContent
        self.itemRevisionRepository = itemRevisionRepository

        switch itemContent.contentData {
        case let .login(username, password, urls):
            self.name = itemContent.name
            self.username = username
            self.urls = urls
            self.password = password
            self.note = itemContent.note
        default:
            fatalError("Expecting login type")
        }

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.logInDetailViewModelBeginsLoading()
                } else {
                    self.delegate?.logInDetailViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.logInDetailViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)
    }
}
