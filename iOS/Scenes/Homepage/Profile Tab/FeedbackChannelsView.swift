//
// FeedbackChannelsView.swift
// Proton Pass - Created on 01/04/2023.
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
import UIComponents

enum FeedbackChannel: Int, CaseIterable {
    case email = 0, twitter, reddit
}

struct FeedbackChannelsView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectChannel: (FeedbackChannel) -> Void

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 22) {
                NotchView()
                    .padding(.top, 5)
                Text("Feedback")
                    .navigationTitleText()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            ScrollView {
                VStack {
                    ForEach(FeedbackChannel.allCases, id: \.rawValue) { channel in
                        Button(action: {
                            onSelectChannel(channel)
                            dismiss()
                        }, label: {
                            Label(title: {
                                Text(channel.description)
                            }, icon: {
                                Image(uiImage: channel.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 20, maxHeight: 20)
                            })
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        })
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .frame(height: OptionRowHeight.short.value)

                        if channel != FeedbackChannel.allCases.last {
                            PassDivider()
                        }
                    }
                }
            }
        }
        .background(Color.passSecondaryBackground)
    }
}

extension FeedbackChannel {
    var icon: UIImage {
        switch self {
        case .email:
            return IconProvider.paperPlane
        case .twitter:
            return PassIcon.brandTwitter
        case .reddit:
            return PassIcon.brandReddit
        }
    }

    var description: String {
        switch self {
        case .email:
            return "Send us a message"
        case .twitter:
            return "Write us on Twitter"
        case .reddit:
            return "Write us on Reddit"
        }
    }

    var urlString: String {
        switch self {
        case .email:
            return "mailto:pass@proton.me"
        case .twitter:
            return "https://twitter.com/ProtonPrivacy"
        case .reddit:
            return "https://www.reddit.com/r/ProtonMail"
        }
    }
}
