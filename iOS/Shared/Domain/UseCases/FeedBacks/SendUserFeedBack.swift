//
//
// SendUserFeedBack.swift
// Proton Pass - Created on 29/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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
//
import Foundation

protocol SendUserFeedBackUseCase: Sendable {
    func execute(with title: String, and description: String, more information: Data?)
}

extension SendUserFeedBackUseCase {
    func callAsFunction(with title: String, and description: String, more information: Data?) {
        execute(with: title, and: description, more: information)
    }
}

final class SendUserFeedBack: SendUserFeedBackUseCase {
    private let feedBackService: FeedBackServiceProtocol

    init(feedBackService: FeedBackServiceProtocol) {
        self.feedBackService = feedBackService
    }

    func execute(with title: String, and description: String, more information: Data?) {
        feedBackService.send(with: title, and: description, more: information)
    }
}
