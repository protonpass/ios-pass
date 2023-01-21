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
import Core
import SwiftOTP
import UIComponents
import UIKit

final class LogInDetailViewModel: BaseItemDetailViewModel, DeinitPrintable, ObservableObject {
    deinit {
        timer?.invalidate()
        print(deinitMessage)
    }

    @Published private(set) var name = ""
    @Published private(set) var username = ""
    @Published private(set) var urls: [String] = []
    @Published private(set) var password = ""
    @Published private(set) var note = ""
    @Published private(set) var totpCode: String?
    @Published private(set) var timerData: OTPCircularTimerData?
    private var timer: Timer?
    private let totp = TOTP(secret: "somesecret".data(using: .utf8) ?? Data(),
                            digits: 6,
                            timeInterval: 30,
                            algorithm: .sha1)

    override func bindValues() {
        if case .login(let data) = itemContent.contentData {
            self.name = itemContent.name
            self.username = data.username
            self.urls = data.urls
            self.password = data.password
            self.note = itemContent.note
            if let totp {
                beginCaculating(totp: totp)
            }
        } else {
            fatalError("Expecting login type")
        }
    }
}

// MARK: - Private operations
private extension LogInDetailViewModel {
    func beginCaculating(totp: TOTP) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let timeInterval = Int(Date().timeIntervalSince1970)
            let remainingSeconds = totp.timeInterval - (timeInterval % totp.timeInterval)
            self.totpCode = totp.generate(secondsPast1970: timeInterval)
            self.timerData = .init(total: totp.timeInterval, remaining: remainingSeconds)
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

    func showLargePassword() {
        showLarge(password)
    }

    func openUrl(_ urlString: String) {
        delegate?.itemDetailViewModelWantsToOpen(urlString: urlString)
    }
}
