//
// UncheckedSendable+Extensions.swift
// Proton Pass - Created on 08/01/2024.
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

import Combine
import Factory
import PhotosUI
import SwiftUI

/// We are regrouping some of the `@unchecked Sendable` extensions in the following file.
/// This should help us keep a eye on what we are not currently checking for strict structured concurrency

extension AnyCancellable: @unchecked Sendable {}
extension PhotosPickerItem: @unchecked Sendable {}
extension CurrentValueSubject: @unchecked Sendable {}
extension PassthroughSubject: @unchecked Sendable {}
