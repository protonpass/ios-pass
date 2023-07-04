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

enum FeedbackTag: String, CaseIterable {
    case bug = "Bug"
    case feedback = "Feedback"
}

@MainActor
final class FeedbackViewModel: ObservableObject {
    @Published var title = ""
    @Published var feedback = ""
    @Published var selectedTag: FeedbackTag = .bug
    @Published var error: Error?
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

            if Task.isCancelled {
                return
            }
            self.isSending = true
            do {
                let response = selectedTag == .bug ? try await self.sendUserBugReport(with: self.title,
                                                                                      and: self.feedback) :
                    try await self.sendUserFeedBack(with: self.title, and: self.feedback)
                self.hasSentFeedBack = true
            } catch {
                self.error = error
            }
            self.isSending = false
        }
    }
}

private extension FeedbackViewModel {
    func setUp() {
        $title.combineLatest($feedback)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title, feedback in
                self?.cantSendFeedBack = title.isEmpty || feedback.count < 10
            }
            .store(in: &cancellables)
    }
}
