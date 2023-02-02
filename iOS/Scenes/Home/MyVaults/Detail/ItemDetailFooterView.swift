//
// ItemDetailFooterView.swift
// Proton Pass - Created on 02/02/2023.
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

struct ItemDetailFooterView: View {
    let createTime: String
    let modifyTime: String

    init(createTime: Int, modifyTime: Int) {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        let createDate = Date(timeIntervalSince1970: TimeInterval(createTime))
        let modifyDate = Date(timeIntervalSince1970: TimeInterval(modifyTime))
        self.createTime = formatter.string(from: createDate).capitalizingFirstLetter()
        self.modifyTime = formatter.string(from: modifyDate).capitalizingFirstLetter()
    }

    var body: some View {
        HStack {
            dateCard(icon: IconProvider.clock, title: "Modified", description: modifyTime)
            Spacer()
            dateCard(icon: IconProvider.calendarToday, title: "Created", description: createTime)
        }
    }

    private func dateCard(icon: UIImage,
                          title: String,
                          description: String) -> some View {
        HStack {
            Image(uiImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
            }
        }
        .foregroundColor(.textWeak)
    }
}
