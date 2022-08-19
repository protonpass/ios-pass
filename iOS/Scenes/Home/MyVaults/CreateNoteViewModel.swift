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

import Client
import Core
import SwiftUI

final class CreateNoteViewModel: BaseCreateItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var name = ""
    @Published var note = ""

    override init(shareId: String,
                  addressKey: AddressKey,
                  shareKeysRepository: ShareKeysRepositoryProtocol,
                  itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        super.init(shareId: shareId,
                   addressKey: addressKey,
                   shareKeysRepository: shareKeysRepository,
                   itemRevisionRepository: itemRevisionRepository)

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.createItemViewModelBeginsLoading()
                } else {
                    self.delegate?.createItemViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.createItemViewModelDidFailWithError(error)
                }
            }
            .store(in: &cancellables)
    }

    override func itemContentType() -> ItemContentType { .note }

    override func generateItemContent() -> ItemContentProtobuf {
        ItemContentProtobuf(name: name,
                            note: note,
                            data: ItemContentData.note)
    }
}
