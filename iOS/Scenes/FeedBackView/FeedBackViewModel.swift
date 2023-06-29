//
// FeedBackViewModel.swift
// Proton Pass - Created on 28/06/2023.
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

import Combine
import Factory
import Foundation

enum FeedBackTag: String, CaseIterable {
    case newFeature = "New Feature"
    case bug = "Bug"
    case other = "Other"
}

@MainActor
final class FeedBackViewModel: ObservableObject {
    @Published var title = ""
    @Published var feedBack = ""
    @Published var selectedTag: FeedBackTag = .newFeature
    @Published private(set) var cantSendFeedBack = true
    @Published private(set) var hasSentFeedBack = false
    @Published private(set) var isSending = false

    private var cancellables = Set<AnyCancellable>()
    private var lastTask: Task<Void, Never>?

    @Injected(\UseCasesContainer.sendUserFeedBack) private var sendUserFeedBack
    @Injected(\UseCasesContainer.setUserFeedBackIdentity) private var setUserFeedBackIdentity

    init() {
        setUp()
    }

    func send() {
        setUserFeedBackIdentity(with: "testemail@test.com")

        lastTask?.cancel()
        lastTask = Task { [weak self] in
            guard let self else {
                return
            }
            if Task.isCancelled {
                return
            }
            isSending = true
            _ = await self.sendUserFeedBack(with: self.title, and: self.feedBack, tag: selectedTag.rawValue)
            isSending = false
            hasSentFeedBack = true
        }
    }
}

private extension FeedBackViewModel {
    func setUp() {
        $title.combineLatest($feedBack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title, feedBack in
                self?.cantSendFeedBack = title.isEmpty || feedBack.isEmpty
            }
            .store(in: &cancellables)
    }
}
