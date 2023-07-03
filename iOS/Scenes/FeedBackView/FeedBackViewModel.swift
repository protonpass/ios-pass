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
    case bug = "Bug"
    case newFeature = "New Feature"
}

@MainActor
final class FeedBackViewModel: ObservableObject {
    @Published var title = ""
    @Published var feedBack = ""
    @Published var selectedTag: FeedBackTag = .bug
    @Published private(set) var cantSendFeedBack = true
    @Published private(set) var hasSentFeedBack = false
    @Published private(set) var isSending = false

    private var cancellables = Set<AnyCancellable>()
    private var lastTask: Task<Void, Never>?

    @Injected(\UseCasesContainer.sendUserFeedBack) private var sendUserFeedBack
    @Injected(\UseCasesContainer.sendUserBugReport) private var sendUserBugReport

    init() {
        setUp()
    }

    func send() {
        lastTask?.cancel()
        lastTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                isSending = false
            }
            if Task.isCancelled {
                return
            }
            isSending = true
            do {
                let response = selectedTag == .bug ? try await self.sendUserBugReport(with: self.title,
                                                                                      and: self.feedBack) :
                    try await self
                    .sendUserFeedBack(with: self
                        .title,
                        and: self
                            .feedBack)
                print("woot no error \(response)")
                self.hasSentFeedBack = true
            } catch {
                print("woot error \(error.localizedDescription)")
            }
        }
    }
}

private extension FeedBackViewModel {
    func setUp() {
        $title.combineLatest($feedBack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title, feedBack in
                guard !title.isEmpty, feedBack.count > 10 else {
                    self?.cantSendFeedBack = true
                    return
                }
                self?.cantSendFeedBack = false
            }
            .store(in: &cancellables)
    }
}
