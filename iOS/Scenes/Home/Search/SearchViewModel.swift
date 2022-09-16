//
// SearchViewModel.swift
// Proton Pass - Created on 09/08/2022.
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

import Combine
import Core
import SwiftUI

final class SearchViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    private let searchTermSubject = PassthroughSubject<String, Never>()
    private var lastTask: Task<Void, Never>?

    @Published private var term = ""
    @Published private(set) var state = State.clean

    private var cancellables = Set<AnyCancellable>()

    enum State {
        case clean
        /// Search term is not long enough
        case idle
        case searching
        case results([String])
        case error(Error)
    }

    init() {
        searchTermSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [unowned self] term in
                self.doSearch(term: term)
            }
            .store(in: &cancellables)
    }

    func search(term: String) {
        searchTermSubject.send(term)
    }

    private func doSearch(term: String) {
        if term.isEmpty { state = .clean; return }
        if term.count <= 2 { state = .idle; return }

        lastTask?.cancel()
        lastTask = Task { @MainActor in
            do {
                state = .searching
                print("Searching for \(term)")
                try await Task.sleep(nanoseconds: 500_000_000)
                if Task.isCancelled { return }
                if Bool.random() {
                    state = .results(["Touti", "Den", "Ponyo"])
                } else {
                    state = .results([])
                }
                print("Finished searching for \(term)")
            } catch {
                state = .error(error)
            }
        }
    }
}
