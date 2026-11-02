//
// ContainerTraits.swift
// Proton Pass - Created on 15/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

@testable import DIComposition
import FactoryTesting
import Testing

// Each trait gives a test its own container (and singleton cache) through the container's
// `@TaskLocal` `shared`, so registrations never leak between tests running in parallel.

extension Trait where Self == ContainerTrait<ToolingContainer> {
    static var toolingContainer: Self {
        .init(shared: ToolingContainer.$shared, container: .init())
    }
}

extension Trait where Self == ContainerTrait<RepositoryContainer> {
    static var repositoryContainer: Self {
        .init(shared: RepositoryContainer.$shared, container: .init())
    }
}

extension Trait where Self == ContainerTrait<UseCasesContainer> {
    static var useCasesContainer: Self {
        .init(shared: UseCasesContainer.$shared, container: .init())
    }
}
