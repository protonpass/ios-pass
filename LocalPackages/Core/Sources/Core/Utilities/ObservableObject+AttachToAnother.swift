//
// ObservableObject+AttachToAnother.swift
// Proton Pass - Created on 16/02/2023.
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
import Foundation

public extension ObservableObject {
    /// Trigger `objectWillChange` of another's `ObservableObjectPublisher`
    /// Use to make nested `ObservableObject`s.
    /// E.g: ViewModel1 depends on ViewModel2 and ViewModel1 needs to trigger its `objectWillChange`
    /// whenever ViewModel2 is changed.
    /// This should alway notify on the main queue as it impact UI refreshing
    func attach<T: ObservableObject>(to another: T, storeIn cancellable: inout Set<AnyCancellable>)
        where T.ObjectWillChangePublisher == ObservableObjectPublisher {
        objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [unowned another] _ in
                another.objectWillChange.send()
            }
            .store(in: &cancellable)
    }
}
