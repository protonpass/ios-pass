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

/// TextField that has month year picker as keyboard
public struct MonthYearTextField: UIViewRepresentable {
    let placeholder: String
    let textColor: UIColor
    let tintColor: UIColor
    let font: UIFont
    let months: [Int]
    let years: [Int]
    @Binding var month: Int?
    @Binding var year: Int?

    public init(placeholder: String,
                tintColor: UIColor,
                month: Binding<Int?>,
                year: Binding<Int?>,
                textColor: UIColor = PassUIColor.textNorm,
                font: UIFont = .preferredFont(forTextStyle: .body)) {
        self.placeholder = placeholder
        self.textColor = textColor
        self.tintColor = tintColor
        self.font = font
        months = Array(1...12)

        let currentYear = Calendar.current.component(.year, from: .now)
        var startYear = currentYear - 10
        var endYear = currentYear + 30
        if let year = year.wrappedValue {
            startYear = min(year, startYear)
            endYear = max(year, endYear)
        }
        years = Array(startYear...endYear)

        _month = month
        _year = year
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
            uiView.text = "\(String(format: "%02d", month)) / \(String(format: "%02d", year % 100))"
        }
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func selectDefaultMonthAndYear(picker: UIPickerView) {
        // Default to current month & year when no selected month & no selected year
        let month = month ?? Calendar.current.component(.month, from: .now)
        if let monthIndex = months.firstIndex(of: month) {
            picker.selectRow(monthIndex, inComponent: 0, animated: false)
        }

        let year = year ?? Calendar.current.component(.year, from: .now)
        if let yearIndex = years.firstIndex(of: year) {
            picker.selectRow(yearIndex, inComponent: 1, animated: false)
        }
    }
}

public extension MonthYearTextField {
    final class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        private let formatter = DateFormatter()
        var parent: MonthYearTextField

        init(_ parent: MonthYearTextField) {
            self.parent = parent
        }

        public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0:
                // Month
                parent.month = parent.months[row]
            case 1:
                // Year
                parent.year = parent.years[row]
            default:
                break
            }
        }

        public func numberOfComponents(in pickerView: UIPickerView) -> Int {
            2
        }

        public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0:
                // Month
                parent.months.count
            case 1:
                // Year
                parent.years.count
            default:
                0
            }
        }

        public func pickerView(_ pickerView: UIPickerView,
                               titleForRow row: Int,
                               forComponent component: Int) -> String? {
            switch component {
            case 0:
                // Month
                String(format: "%02d - %@", row + 1, formatter.monthSymbols[row])
            case 1:
                // Year
                "\(parent.years[row])"
            default:
                nil
            }
        }
    }
}
