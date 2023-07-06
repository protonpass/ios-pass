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

enum FeedbackChannel: Int, CaseIterable, Identifiable {
    case bugReport = 0, reddit, uservoice

    var id: Int { rawValue }
}

struct FeedbackChannelsView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectChannel: (FeedbackChannel) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(FeedbackChannel.allCases) { channel in
                        OptionRow(action: {
                                      dismiss()
                                      onSelectChannel(channel)
                                  },
                                  height: .short,
                                  horizontalPadding: 0,
                                  content: {
                                      Label(title: {
                                          Text(channel.description)
                                      }, icon: {
                                          Image(uiImage: channel.icon)
                                              .resizable()
                                              .scaledToFit()
                                              .frame(maxWidth: 20, maxHeight: 20)
                                      })
                                      .foregroundColor(Color(uiColor: PassColor.textNorm))
                                  })

                        PassDivider()
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Feedback")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

extension FeedbackChannel {
    var icon: UIImage {
        switch self {
        case .bugReport:
            return IconProvider.bug
        case .reddit:
            return PassIcon.brandReddit
        case .uservoice:
            return PassIcon.brandPass
        }
    }

    var description: String {
        switch self {
        case .bugReport:
            return "Report a problem"
        case .reddit:
            return "Write us on Reddit"
        case .uservoice:
            return "Vote for new features"
        }
    }

    var urlString: String? {
        switch self {
        case .bugReport:
            return nil
        case .reddit:
            return "https://www.reddit.com/r/ProtonPass"
        case .uservoice:
            return "https://protonmail.uservoice.com/forums/953584-proton-pass"
        }
    }
}
