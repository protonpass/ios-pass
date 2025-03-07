//
// TimestampPicker.swift
// Proton Pass - Created on 04/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import SwiftUI

public struct TimestampPicker: View {
    @State private var date: Date
    @Binding var value: String
    private let displayedComponents: DatePickerComponents

    public init(value: Binding<String>,
                displayedComponents: DatePickerComponents = [.date]) {
        if let intValue = Int(value.wrappedValue) {
            _date = .init(initialValue: .init(timeIntervalSince1970: TimeInterval(intValue)))
        } else {
            _date = .init(initialValue: .now)
        }
        _value = value
        self.displayedComponents = displayedComponents
    }

    public var body: some View {
        DatePicker(selection: $date, displayedComponents: displayedComponents) {
            EmptyView()
        }
        .labelsHidden()
        .onChange(of: date) { newValue in
            value = String(Int(newValue.timeIntervalSince1970))
        }
    }
}
