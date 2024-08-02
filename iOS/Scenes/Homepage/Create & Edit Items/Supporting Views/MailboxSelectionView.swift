//
// MailboxSelectionView.swift
// Proton Pass - Created on 17/02/2023.
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

// import DesignSystem
// import Entities
// import Factory
// import ProtonCoreUIFoundations
// import SwiftUI
//
//// enum MailboxSelectionMode {
////    case createEditAlias
////    case createAliasLite
////
////    var tintColor: Color {
////        switch self {
////        case .createEditAlias:
////            ItemContentType.alias.normMajor2Color.toColor
////        case .createAliasLite:
////            ItemContentType.login.normMajor2Color.toColor
////        }
////    }
//// }
//
// struct MailboxSelectionView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Binding var mailboxSelection: MailboxSelection
////    let mode: MailboxSelectionMode
//    let title: String
//
//    var body: some View {
//        NavigationStack {
//            // ZStack instead of VStack because of SwiftUI bug.
//            // See more in "CreateAliasLiteView.swift"
//            ZStack(alignment: .bottom) {
//                ScrollView {
//                    LazyVStack(spacing: 0) {
//                        ForEach(mailboxSelection.allUserMailboxes) { mailbox in
//                            let isSelected = mailboxSelection.selectedMailboxes.contains(mailbox)
//                            HStack {
//                                Text(mailbox.email)
//                                    .foregroundStyle(isSelected ?
//                                        ItemContentType.login.normMajor2Color.toColor : PassColor
//                                        .textNorm.toColor)
//                                Spacer()
//
//                                if isSelected {
//                                    Image(uiImage: IconProvider.checkmark)
//                                        .foregroundStyle(ItemContentType.login.normMajor2Color.toColor)
//                                }
//                            }
//                            .contentShape(.rect)
//                            .background(Color.clear)
//                            .padding(.horizontal)
//                            .frame(height: OptionRowHeight.compact.value)
//                            .onTapGesture {
//                                mailboxSelection.selectedMailboxes.insertOrRemove(mailbox, minItemCount: 1)
//                            }
//
//                            PassDivider()
//                                .padding(.horizontal)
//                        }
//
//                        // Gimmick view to take up space
//                        closeButton
//                            .opacity(0)
//                            .padding()
//                            .disabled(true)
//                    }
//                }
//
//                closeButton
//                    .padding()
//            }
//            .background(PassColor.backgroundWeak.toColor)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text(title)
//                        .navigationTitleText()
//                }
//            }
//        }
//    }
//
//    private var closeButton: some View {
//        Button(action: dismiss.callAsFunction) {
//            Text("Close")
//                .foregroundStyle(PassColor.textNorm.toColor)
//        }
//    }
// }
