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

enum TotpState: Equatable {
    case empty
    case valid(TotpData)
    case invalid
}

struct TotpData: Equatable {
    let code: String
    let timerData: OTPCircularTimerData
}

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
    @Published private(set) var totpState = TotpState.empty
    private var timer: Timer?

    override func bindValues() {
        timer?.invalidate()
        if case .login(let data) = itemContent.contentData {
            self.name = itemContent.name
            self.note = itemContent.note
            self.username = data.username
            self.password = data.password
            self.urls = data.urls
            bindTotpUri(data.totpUri)
        } else {
            fatalError("Expecting login type")
        }
    }

    private func bindTotpUri(_ uri: String) {
        guard !uri.isEmpty else {
            totpState = .empty
            return
        }

        guard let url = URL(string: uri) else {
            totpState = .invalid
            return
        }

        do {
            let otpComponents = try URLUtils.OTPParser.parse(url: url)
            guard otpComponents.type == .totp else {
                totpState = .invalid
                return
            }
            let secretData = otpComponents.secret.data(using: .utf8)

            guard let totp = TOTP(secret: secretData ?? .init(),
                                  digits: Int(otpComponents.digits),
                                  timeInterval: Int(otpComponents.period),
                                  algorithm: otpComponents.algorithm.otpAlgorithm) else {
                totpState = .invalid
                return
            }
            beginCaculating(totp: totp)
        } catch {
            logger.error(error)
            totpState = .invalid
        }
    }
}

private extension OTPComponents.Algorithm {
    var otpAlgorithm: OTPAlgorithm {
        switch self {
        case .sha1:
            return .sha1
        case .sha256:
            return .sha256
        case .sha512:
            return .sha512
        }
    }
}

// MARK: - Private operations
private extension LogInDetailViewModel {
    func beginCaculating(totp: TOTP) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let timeInterval = Int(Date().timeIntervalSince1970)
            let remainingSeconds = totp.timeInterval - (timeInterval % totp.timeInterval)
            let code = totp.generate(secondsPast1970: timeInterval) ?? ""
            let timerData = OTPCircularTimerData(total: totp.timeInterval,
                                                 remaining: remainingSeconds)
            self.totpState = .valid(.init(code: code, timerData: timerData))
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
        if case .valid(let data) = totpState {
            copyToClipboard(text: data.code, message: "One-time password copied")
        }
    }

    func showLargePassword() {
        showLarge(password)
    }

    func openUrl(_ urlString: String) {
        delegate?.itemDetailViewModelWantsToOpen(urlString: urlString)
    }
}
