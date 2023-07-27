//
// InviteBannerView.swift
// Proton Pass - Created on 27/07/2023.
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

import Entities
import Factory
import SwiftUI
import UIComponents

struct InviteBannerView: View {
    private let router = resolve(\RouterContainer.mainUIKitSwiftUIRouter)
    let invite: UserInvite

    static let height: CGFloat = 160

    var body: some View {
        Button { router.presentSheet(for: .acceptRejectInvite(invite)) } label: {
            HStack(alignment: .center, spacing: 16) {
                VStack {
                    Text("Shared vault invitation")
                        .font(.title2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Text("You’ve been invited to a vault. Tap here to see the invitation.")
                        .font(.body)
                }
                .foregroundColor(PassColor.textNorm.toColor)
                Image(uiImage: PassIcon.inviteBannerIcon)
                    .frame(width: 76, height: 76)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .frame(height: Self.height)
        .background(Color(uiColor: PassColor.backgroundMedium))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .buttonStyle(.plain)
    }
}
