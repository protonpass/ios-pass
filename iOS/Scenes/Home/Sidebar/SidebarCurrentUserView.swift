//
// SidebarCurrentUserView.swift
// Proton Pass - Created on 06/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import SwiftUI
import UIComponents

struct SidebarCurrentUserView: View {
    let user: UserProtocol
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(user.initials)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(8)
                    .frame(minWidth: 36)
                    .background(Color.interactionNorm)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading) {
                    Text(user.finalDisplayName)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text(user.email ?? "?")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                Spacer()
//                Image(uiImage: IconProvider.chevronDown)
//                    .foregroundColor(.white)
            }
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.sidebarCurrentUser)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PreviewUserInfo: UserProtocol {
    let email: String? = "john.doe@example.com"
    let finalDisplayName = "John Doe"
    let initials = "JD"
}

extension UserProtocol where Self == PreviewUserInfo {
    static var preview: PreviewUserInfo { .init() }
}

/*
struct SidebarCurrentUserView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(ColorProvider.SidebarBackground)
                .ignoresSafeArea(.all)
            SidebarCurrentUserView(user: .preview) {}
                .padding()
        }
    }
}
*/
