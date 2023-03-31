//
// LogTypesView.swift
// Proton Pass - Created on 31/03/2023.
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

import Core
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct LogTypesView: View {
    let onSelect: (PassLogModule) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 22) {
                NotchView()
                    .padding(.top, 5)
                Text("View logs")
                    .navigationTitleText()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            ScrollView {
                VStack(spacing: kItemDetailSectionPadding) {
                    VStack(spacing: 0) {
                        ForEach(PassLogModule.allCases, id: \.hashValue) { module in
                            OptionRow(action: { onSelect(module) },
                                      height: CGFloat(kOptionRowCompactHeight),
                                      content: { Text(module.title) },
                                      trailing: { ChevronRight() })

                            if module != PassLogModule.allCases.last {
                                PassDivider()
                            }
                        }
                    }
                    .roundedEditableSection()

                    OptionRow(
                        action: {
                            let modules = PassLogModule.allCases.map(LogManager.init)
                            modules.forEach { $0.removeAllLogs() }
                            onClear()
                        },
                        content: {
                            Text("Clear all logs")
                                .foregroundColor(.passBrand)
                        })
                    .roundedEditableSection()
                }
                .padding([.top, .horizontal])
            }
        }
        .background(Color.passSecondaryBackground)
    }
}
