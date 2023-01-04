//
// DeviceLogTypesView.swift
// Proton Pass - Created on 02/01/2023.
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

import ProtonCore_UIFoundations
import SwiftUI

enum DeviceLogType: CaseIterable {
    case hostApplication
    case autoFillExtension

    var title: String {
        switch self {
        case .hostApplication:
            return "Host application logs"
        case .autoFillExtension:
            return "AutoFill extension logs"
        }
    }

    var subsystem: String {
        switch self {
        case .hostApplication:
            return "me.proton.pass.ios"
        case .autoFillExtension:
            return "me.proton.pass.ios.autofill"
        }
    }
}

struct DeviceLogTypesView: View {
    var onGoBack: () -> Void
    var onSelect: (DeviceLogType) -> Void

    var body: some View {
        Form {
            ForEach(DeviceLogType.allCases, id: \.hashValue) { type in
                Button(action: {
                    onSelect(type)
                }, label: {
                    Text(type.title)
                })
                .foregroundColor(.interactionNorm)
            }
        }
        .navigationTitle("Device logs")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onGoBack) {
                    Image(uiImage: IconProvider.chevronLeft)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}
