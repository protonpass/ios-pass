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

import ProtonCore_UIFoundations
import SwiftUI

protocol UserInfoProvider {
    var displayName: String { get }
    var email: String { get }
}

struct SidebarCurrentUserView: View {
    let userInfoProvider: UserInfoProvider
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("AA")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color(ColorProvider.BrandNorm))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading) {
                    Text(userInfoProvider.displayName)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text(userInfoProvider.email)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(uiImage: IconProvider.chevronDown)
                    .foregroundColor(.white)
            }
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.sidebarCurrentUser)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PreviewUserInfo: UserInfoProvider {
    let displayName = "John Doe"
    let email = "john.doe@example.com"
}

extension UserInfoProvider where Self == PreviewUserInfo {
    static var preview: PreviewUserInfo { .init() }
}

struct SidebarCurrentUserView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(ColorProvider.SidebarBackground)
                .ignoresSafeArea(.all)
            SidebarCurrentUserView(userInfoProvider: .preview) {}
                .padding()
        }
    }
}
