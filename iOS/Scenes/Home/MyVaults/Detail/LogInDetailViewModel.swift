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
import SwiftOTP
import UIComponents
import UIKit

final class LogInDetailViewModel: BaseItemDetailViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var name = ""
    @Published private(set) var username = ""
    @Published private(set) var urls: [String] = []
    @Published private(set) var password = ""
    @Published private(set) var note = ""
    @Published private(set) var totpManager: TotpManager

    private var cancellables = Set<AnyCancellable>()

    override init(itemContent: ItemContent,
                  itemRepository: ItemRepositoryProtocol,
                  logManager: LogManager) {
        self.totpManager = .init(logManager: logManager)
        super.init(itemContent: itemContent,
                   itemRepository: itemRepository,
                   logManager: logManager)
        self.totpManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    override func bindValues() {
        if case .login(let data) = itemContent.contentData {
            self.name = itemContent.name
            self.note = itemContent.note
            self.username = data.username
            self.password = data.password
            self.urls = data.urls
            totpManager.bind(uri: data.totpUri)
        } else {
            fatalError("Expecting login type")
        }
    }
}

// MARK: - Public actions
extension LogInDetailViewModel {
    func copyUsername() {
        copyToClipboard(text: username, message: "Username copied")
    }

    func copyPassword() {
        copyToClipboard(text: password, message: "Password copied")
    }

    func copyTotpCode() {
        if let code = totpManager.getCurrentCode() {
            copyToClipboard(text: code, message: "Two Factor Authentication code copied")
        }
    }

    func showLargePassword() {
        showLarge(password)
    }

    func openUrl(_ urlString: String) {
        delegate?.itemDetailViewModelWantsToOpen(urlString: urlString)
    }
}
