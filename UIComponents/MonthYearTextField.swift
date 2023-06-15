//
// MonthYearTextField.swift
// Proton Pass - Created on 14/06/2023.
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

import SwiftUI

private let kTwoComponentsMessage = "Must have 2 components"
private let kNumberOfYearsAhead = 30

/// TextField that has month year picker as keyboard
public struct MonthYearTextField: UIViewRepresentable {
    let placeholder: String
    let textColor: UIColor
    let tintColor: UIColor
    let font: UIFont
    let currentYear: Int
    @Binding var month: Int?
    @Binding var year: Int?

    public init(placeholder: String,
                tintColor: UIColor,
                month: Binding<Int?>,
                year: Binding<Int?>,
                textColor: UIColor = PassColor.textNorm,
                font: UIFont = .preferredFont(forTextStyle: .body),
                currentYear: Int = Calendar.current.component(.year, from: .now)) {
        self.placeholder = placeholder
        self.textColor = textColor
        self.tintColor = tintColor
        self.font = font
        self.currentYear = currentYear
        self._month = month
        self._year = year
    }

    public func makeUIView(context: Context) -> UITextField {
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        selectDefaultMonthAndYear(picker: picker)

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.tintColor = tintColor

        let textField = UITextField()
        textField.placeholder = placeholder
        textField.textColor = textColor
        textField.tintColor = tintColor
        textField.font = font
        textField.inputView = picker
        textField.inputAccessoryView = toolbar

        let doneButon = UIBarButtonItem(systemItem: .done,
                                        primaryAction: .init(handler: { _ in
            if month == nil {
                month = Calendar.current.component(.month, from: .now)
            }
            if year == nil {
                year = Calendar.current.component(.year, from: .now)
            }
            textField.resignFirstResponder()
        }))
        toolbar.items = [.flexibleSpace(), doneButon]

        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        if let month, let year {
            uiView.text = "\(String(format: "%02d", month)) / \(year)"
        }
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func selectDefaultMonthAndYear(picker: UIPickerView) {
        assert(picker.numberOfComponents == 2, kTwoComponentsMessage)

        // Default to current month
        assert(picker.numberOfRows(inComponent: 0) == 12, "Must have 12 months")
        if let month {
            picker.selectRow(month - 1, inComponent: 0, animated: false)
        }

        // Default to current year
        assert(picker.numberOfRows(inComponent: 1) == kNumberOfYearsAhead,
               "Must have \(kNumberOfYearsAhead) years")
        if let year {
            picker.selectRow(year - currentYear, inComponent: 1, animated: false)
        }
    }
}

public extension MonthYearTextField {
    final class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var parent: MonthYearTextField

        init(_ parent: MonthYearTextField) {
            self.parent = parent
        }

        public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0:
                // Month
                parent.month = row + 1
            case 1:
                // Year
                parent.year = parent.currentYear + row
            default:
                assertionFailure(kTwoComponentsMessage)
            }
        }

        public func numberOfComponents(in pickerView: UIPickerView) -> Int {
            2
        }

        public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0:
                // Month
                return 12
            case 1:
                // Year
                return kNumberOfYearsAhead
            default:
                assertionFailure(kTwoComponentsMessage)
                return 0
            }
        }

        public func pickerView(_ pickerView: UIPickerView,
                               titleForRow row: Int,
                               forComponent component: Int) -> String? {
            switch component {
            case 0:
                // Month
                return String(format: "%02d", row + 1)
            case 1:
                // Year
                return "\(parent.currentYear + row)"
            default:
                assertionFailure(kTwoComponentsMessage)
                return nil
            }
        }
    }
}
