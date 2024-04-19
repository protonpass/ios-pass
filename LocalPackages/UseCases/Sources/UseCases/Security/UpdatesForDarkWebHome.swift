//
//
// UpdatesForDarkWebHome.swift
// Proton Pass - Created on 19/04/2024.
// Copyright (c) 2024 Proton Technologies AG
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

@preconcurrency import Combine
import Entities

public enum DarkWeSectionToUpdate: Equatable {
    case customEmails([CustomEmail])
    case protonAddresses
    case aliases
    case all
}

public protocol UpdatesForDarkWebHomeUseCase: Sendable {
    func execute() -> PassthroughSubject<DarkWeSectionToUpdate, Never>
    func execute(updateSection: DarkWeSectionToUpdate)
}

public extension UpdatesForDarkWebHomeUseCase {
    func callAsFunction() -> PassthroughSubject<DarkWeSectionToUpdate, Never> {
        execute()
    }

    func callAsFunction(updateSection: DarkWeSectionToUpdate) {
        execute(updateSection: updateSection)
    }
}

public final class UpdatesForDarkWebHome: UpdatesForDarkWebHomeUseCase {
    private let updateForDarkWebHome: PassthroughSubject<DarkWeSectionToUpdate, Never> = .init()

    public init() {}

    public func execute() -> PassthroughSubject<DarkWeSectionToUpdate, Never> {
        updateForDarkWebHome
    }

    public func execute(updateSection: DarkWeSectionToUpdate) {
        updateForDarkWebHome.send(updateSection)
    }
}
