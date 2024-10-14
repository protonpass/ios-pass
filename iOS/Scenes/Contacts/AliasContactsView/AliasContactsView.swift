//
//
// AliasContactsView.swift
// Proton Pass - Created on 03/10/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

private enum AliasContactsSheetState {
    case explanation
    case creation
}

struct AliasContactsView: View {
    @StateObject var viewModel: AliasContactsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var sheetState: AliasContactsSheetState?

    var body: some View {
        mainContainer
            .onChange(of: viewModel.showExplanation) { value in
                guard value else {
                    return
                }
                sheetState = .explanation
            }
            .optionalSheet(binding: $sheetState) { state in
                sheetContent(for: state)
                    .presentationDetents(presentationDetents(for: state))
                    .presentationDragIndicator(.visible)
            }
    }
}

private extension AliasContactsView {
    var mainContainer: some View {
        VStack {
            mainTitle
                .padding(.top)

            senderName

            // swiftlint:disable:next line_length
            Text("When sending an email from this alias, the email will have '\(viewModel.aliasName.isEmpty ? "Chosen Name" : viewModel.aliasName) <\(viewModel.alias.email)>' as sender.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)
                .padding(.top, 8)
                .padding(.bottom, DesignConstant.sectionPadding)

            if viewModel.hasNoContact {
                AliasContactsEmptyView { sheetState = .explanation }
            } else {
                contactList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm.toColor, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    var mainTitle: some View {
        Label(title: {
            Text("Contacts")
                .font(.title.bold())
                .foregroundStyle(PassColor.textNorm.toColor)
        }, icon: {
            Button(action: { sheetState = .explanation }, label: {
                Text("?")
                    .fontWeight(.medium)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 11)
                    .foregroundStyle(PassColor.aliasInteractionNormMajor2.toColor)
                    .background(PassColor.aliasInteractionNormMinor1.toColor)
                    .clipShape(Capsule())
            })
            .buttonStyle(.plain)
        })
        .labelStyle(.rightIcon)
        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}

private extension AliasContactsView {
    var senderName: some View {
        HStack {
            VStack(spacing: 0) {
                Text("Sender name")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                    .padding(.vertical, 8)

                TextField("Enter name", text: $viewModel.aliasName, onEditingChanged: { value in
                    guard !value else {
                        return
                    }
                    viewModel.updateAliasName()
                })
                .autocorrectionDisabled()
            }

            ItemDetailSectionIcon(icon: IconProvider.pen,
                                  width: 20)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}

private extension AliasContactsView {
    var contactList: some View {
        LazyVStack(spacing: 25) {
            if !viewModel.contactsInfos.activeContacts.isEmpty {
                Section {
                    ForEach(viewModel.contactsInfos.activeContacts) { contact in
                        itemRow(for: contact)
                    }
                } header: {
                    Text("Forwarding addresses")
                        .font(.callout)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !viewModel.contactsInfos.blockContacts.isEmpty {
                Section {
                    ForEach(viewModel.contactsInfos.blockContacts) { contact in
                        itemRow(for: contact)
                    }
                } header: {
                    Text("Blocked")
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func itemRow(for contact: AliasContact) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding) {
            HStack {
                Text(verbatim: contact.email)
                    .foregroundStyle(PassColor.textNorm.toColor)

                Spacer()

                if !contact.blocked {
                    Button {
                        viewModel.openMail(emailTo: contact.email)
                    } label: {
                        Image(uiImage: IconProvider.paperPlane)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    }
                    .padding(.trailing, DesignConstant.sectionPadding)
                }

                Menu(content: {
                    if !contact.blocked {
                        Label(title: { Text("Send email") }, icon: { Image(uiImage: IconProvider.paperPlane) })
                            .buttonEmbeded {
                                viewModel.openMail(emailTo: contact.email)
                            }
                    }

                    Label(title: { Text("Copy address") }, icon: { Image(uiImage: IconProvider.squares) })
                        .buttonEmbeded {
                            viewModel.copyContact(contact)
                        }

                    Divider()

                    Label(title: { Text(contact.actionTitle) },
                          icon: { Image(uiImage: IconProvider.crossCircle) })
                        .buttonEmbeded {
                            viewModel.toggleContactState(contact)
                        }

                    Label(title: { Text("Delete") },
                          icon: { Image(uiImage: IconProvider.trash) })
                        .buttonEmbeded {
                            viewModel.delete(contact: contact)
                        }
                }, label: {
                    IconProvider.threeDotsVertical
                        .foregroundStyle(PassColor.textWeak.toColor)
                })
            }

            VStack(alignment: .leading) {
                Text(viewModel.timeSinceCreation(from: contact.createTime))
                Text(contact.activityText)
            }
            .font(.footnote)
            .foregroundStyle(PassColor.textWeak.toColor)

            Text(contact.actionTitle)
                .font(.callout)
                .foregroundStyle(PassColor.aliasInteractionNormMajor2.toColor)
                .frame(height: 40)
                .padding(.horizontal, 16)
                .background(contact.blocked ? .clear : PassColor.aliasInteractionNormMinor1.toColor)
                .clipShape(Capsule())
                .buttonEmbeded {
                    sheetState = .creation
                }
                .overlay(Capsule()
                    .stroke(PassColor.aliasInteractionNormMinor1.toColor, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.inputBorderNorm.toColor)
        .cornerRadius(16)
    }
}

private extension AliasContact {
    var actionTitle: String {
        blocked ? #localized("Unblock contact") : #localized("Block contact")
    }

    var activityText: String {
        noActivity ? #localized("No activity in the last 14 days.") :
            #localized("%lld forwarded, %lld replies, %lld blocked in the last 14 days.", forwardedEmails,
                       repliedEmails,
                       blockedEmails)
    }
}

private extension AliasContactsView {
    @ViewBuilder
    func sheetContent(for state: AliasContactsSheetState) -> some View {
        switch state {
        case .creation:
            CreateContactView(viewModel: .init(itemIds: viewModel.itemIds))
        case .explanation:
            AliasExplanationView()
        }
    }

    func presentationDetents(for state: AliasContactsSheetState) -> Set<PresentationDetent> {
        //        let customHeight: CGFloat = switch state {
        //        case .domain:
        //            // +1 for "Not selected" option
        //            OptionRowHeight.compact.value * CGFloat(viewModel.domains.count + 1) + 50
        //        case .mailbox:
        //            OptionRowHeight.compact.value * CGFloat(viewModel.mailboxes.count) + 50
        //        case .vault:
        //            OptionRowHeight.medium.value * CGFloat(viewModel.vaults.count) + 50
        //        }
        //        return [.height(customHeight), .large]
        //    }
        [.medium, .large]
    }
}

private extension AliasContactsView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.aliasInteractionNormMajor2,
                         backgroundColor: PassColor.aliasInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CapsuleTextButton(title: #localized("Create contact"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.aliasInteractionNormMajor1,
                              action: { sheetState = .creation })
                .padding(.vertical, 8)
        }
    }
}

struct AliasContactsEmptyView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            Image(uiImage: PassIcon.stamp)

            VStack(spacing: DesignConstant.sectionPadding) {
                Text("Alias contacts")
                    .font(.headline)
                    .foregroundStyle(PassColor.textNorm.toColor)

                // swiftlint:disable:next line_length
                Text("To keep your personal email address hidden, you can create an alias contact that masks your address.")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .padding(.horizontal, 40)

            CapsuleTextButton(title: #localized("Learn more"),
                              titleColor: PassColor.aliasInteractionNormMajor2,
                              backgroundColor: PassColor.aliasInteractionNormMinor1,
                              maxWidth: nil,
                              action: action)
            Spacer()
        }
    }
}

enum ContactCreationSteps: String, CaseIterable {
    case first = "1"
    case second = "2"
    case third = "3"

    func title(_ element: String? = nil) -> String {
        switch self {
        case .first:
            return #localized("Enter the address you want to email.")
        case .second:
            return #localized("Proton Pass will generate a forwarding address (also referred to as reverse alias).")
        case .third:
            guard let element else {
                return ""
            }
            return #localized("Email this address and it will appear to be sent from %@.", element)
        }
    }

    @ViewBuilder
    func descriptionSubview(info: String? = nil) -> some View {
        switch self {
        case .first:
            Text("first")
        case .third:
            Text("Test")
        default:
            EmptyView()
        }
    }
}

struct AliasExplanationView: View {
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {
                    ZStack {
                        GradientView()
                        //                    RadialGradient(gradient: Gradient(colors: [
                        //                        Color(red: 91 / 255, green: 83 / 255, blue: 237 / 255),
                        //                        Color(red: 146 / 255, green: 81 / 255, blue: 235 / 255)
                        //                    ]), center: .bottom, startRadius: 100, endRadius: 100)
                        ZStack(alignment: .topTrailing) {
                            Rectangle().fill(Color(red: 237 / 255, green: 192 / 255, blue: 101 / 255))

                            Image(uiImage: PassIcon.stamp)
                                .ignoresSafeArea()
                        }
                        .offset(x: -proxy.size.width / 2, y: 100)
                        .rotationEffect(.degrees(-10))
                        .frame(width: 600, height: 312)
                    }
                    .frame(height: 178)
                    .clipped()

                    Text("Alias contacts")
                        .font(.title)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    // swiftlint:disable:next line_length
                    Text("To keep your personal email address hidden, you can create an alias contact that masks your address.")
                        .foregroundStyle(PassColor.textNorm.toColor)
                    Text("Here’s how it works:")
                        .foregroundStyle(PassColor.textNorm.toColor)

                    ForEach(ContactCreationSteps.allCases, id: \.self) { step in
                        ContactStepView(step: step, email: step == .third ? "test@test.com" : nil)
                    }
//
//                HStack(alignment: .center) {
//                    // swiftlint:disable:next todo
//                    // TODO: add numbers
//                    Text("13")
//                      .padding()
//                      .background(
//                        Circle()
//                          .stroke(circleColor, lineWidth: 4)
//                          .padding(6)
//                      )
//                    Divider()
//                }
//
//                Text("Enter the address you want to email.")
//                    .foregroundStyle(PassColor.textNorm.toColor)

                    Spacer()
                }
                /* .frame(maxWidth: .infinity) */
            }
        }
    }
}

struct ContactStepView: View {
    let step: ContactCreationSteps
    let email: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // swiftlint:disable:next todo
                // TODO: add numbers
                Text(step.rawValue)
                    .foregroundStyle(PassColor.aliasInteractionNormMajor2.toColor)
                    .padding()
                    .background(Circle()
                        .stroke(PassColor.aliasInteractionNormMinor1.toColor, lineWidth: 1))
                PassDivider()
            }

            Text(step.title(email))
                .foregroundStyle(PassColor.textNorm.toColor)

            step.descriptionSubview(info: email)
//            if let view = step.descriptionSubview(info: email) {
//                view
//            }
        }
    }
}

struct GradientView: View {
    var body: some View {
        ZStack {
            // 1. First Linear Gradient (essentially a solid color in this case)
            Color(hex: "#D9D9D9")

            // 2. Radial Gradient
            RadialGradient(gradient: Gradient(colors: [
                Color(hex: "#9251EB"),
                Color(hex: "#5B53ED")
            ]),
            center: .init(x: 0.85, y: 0.19), // Custom center (85.42% x, 18.75% y)
            startRadius: 5, // Adjust based on visual result
            endRadius: 300)

            // 3. Linear Gradient with transparency
            LinearGradient(gradient: Gradient(colors: [
                Color(red: 25 / 255, green: 25 / 255, blue: 39 / 255, opacity: 0.48),
                Color(red: 25 / 255, green: 25 / 255, blue: 39 / 255, opacity: 0.48)
            ]),
            startPoint: .top,
            endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

// Helper extension for hex color
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double((rgb >> 0) & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
