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

import Client
import DesignSystem
import Entities
import Factory
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
            }
    }
}

private extension AliasContactsView {
    var mainContainer: some View {
        LazyVStack {
            mainTitle
                .padding(.top)

            // swiftlint:disable:next line_length
            Text("A contact is created for every email address that sends emails to or receives emails from \(viewModel.alias.email)")
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.bottom, viewModel.aliasName.isEmpty ? DesignConstant.sectionPadding : 0)

            if viewModel.hasNoContact {
                AliasContactsEmptyView { sheetState = .explanation }
            } else {
                contactList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.aliasName)
        .animation(.default, value: viewModel.hasNoContact)
        .animation(.default, value: viewModel.contactsInfos)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .showSpinner(viewModel.loading)
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
    }
}

private extension AliasContactsView {
    @ViewBuilder
    var contactList: some View {
        if !viewModel.contactsInfos.activeContacts.isEmpty {
            Section {
                ForEach(viewModel.contactsInfos.activeContacts, id: \.id) { contact in
                    itemRow(for: contact)
                }
            }
            .padding(.top, 20)
        }

        if !viewModel.contactsInfos.blockContacts.isEmpty {
            Section {
                ForEach(viewModel.contactsInfos.blockContacts, id: \.id) { contact in
                    itemRow(for: contact)
                }
            } header: {
                Text("Blocked addresses")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func itemRow(for contact: AliasContact) -> some View {
        ContactRow(contact: contact,
                   onSend: { viewModel.openMail(emailTo: contact.reverseAlias) },
                   onCopyAddress: { viewModel.copyContact(contact) },
                   onToggleState: { viewModel.toggleContactState(contact) },
                   onDelete: { viewModel.delete(contact: contact) })
    }
}

@MainActor
private struct ContactRow: View, @preconcurrency Equatable {
    let contact: AliasContact
    let onSend: () -> Void
    let onCopyAddress: () -> Void
    let onToggleState: () -> Void
    let onDelete: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.contact.hashValue == rhs.contact.hashValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding) {
            HStack {
                Text(verbatim: contact.email)
                    .foregroundStyle(PassColor.textNorm.toColor)

                Spacer()

                if !contact.blocked {
                    Button(action: onSend) {
                        Image(uiImage: IconProvider.paperPlane)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    }
                    .padding(.trailing, DesignConstant.sectionPadding)
                }

                Menu(content: {
                    if !contact.blocked {
                        button(title: "Send email",
                               icon: IconProvider.paperPlane,
                               action: onSend)
                    }

                    button(title: "Copy address",
                           icon: IconProvider.squares,
                           action: onCopyAddress)

                    Divider()

                    button(title: contact.actionTitle,
                           icon: contact.actionIcon,
                           action: onToggleState)

                    button(title: "Delete",
                           icon: IconProvider.trash,
                           action: onDelete)
                }, label: {
                    IconProvider.threeDotsVertical
                        .foregroundStyle(PassColor.textWeak.toColor)
                })
            }

            VStack(alignment: .leading) {
                Text("Created \(contact.createTime.fullDateString)")
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
                .buttonEmbeded(action: onToggleState)
                .overlay(Capsule()
                    .stroke(PassColor.aliasInteractionNormMinor1.toColor, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.inputBorderNorm.toColor)
        .cornerRadius(16)
    }

    func button(title: LocalizedStringKey,
                icon: UIImage,
                action: @escaping () -> Void) -> some View {
        Button { action() } label: {
            Label(title: { Text(title) }, icon: { Image(uiImage: icon) })
        }
    }
}

private extension AliasContact {
    var actionTitle: LocalizedStringKey {
        blocked ? "Unblock contact" : "Block contact"
    }

    var actionIcon: UIImage {
        blocked ? IconProvider.envelopeOpenText : IconProvider.circleSlash
    }

    var activityText: String {
        let forwarded = #localized("%lld forwarded", forwardedEmails)
        let replies = #localized("%lld replies", repliedEmails)
        let blocked = #localized("%lld blocked", blockedEmails)
        return noActivity ? #localized("No activity in the last 14 days.") :
            #localized("%1$@, %2$@, %3$@ in the last 14 days.", forwarded, replies, blocked)
    }
}

private extension AliasContactsView {
    @ViewBuilder
    func sheetContent(for state: AliasContactsSheetState) -> some View {
        switch state {
        case .creation:
            CreateContactView(viewModel: .init(itemIds: viewModel.itemIds))
        case .explanation:
            AliasExplanationView(email: viewModel.displayName)
        }
    }

    func presentationDetents(for state: AliasContactsSheetState) -> Set<PresentationDetent> {
        switch state {
        case .creation:
            [.large]
        case .explanation:
            [.medium, .large]
        }
    }
}

private extension AliasContactsView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.aliasInteractionNormMajor2,
                         backgroundColor: PassColor.aliasInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                CapsuleTextButton(title: #localized("Create contact"),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.aliasInteractionNormMajor1,
                                  action: {
                                      if viewModel.canManageAliases {
                                          sheetState = .creation
                                      } else {
                                          viewModel.upsell()
                                      }
                                  })
                                  .padding(.vertical, 8)
                if !viewModel.canManageAliases {
                    passPlusBadge
                }
            }
        }
    }

    var passPlusBadge: some View {
        Image(uiImage: PassIcon.passSubscriptionUnlimited)
            .resizable()
            .scaledToFit()
            .frame(height: 24)
    }
}

private struct AliasContactsEmptyView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            Image(uiImage: PassIcon.stamp)

            VStack(spacing: DesignConstant.sectionPadding) {
                Text("Alias contacts")
                    .font(.title2.bold())
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

private enum ContactCreationSteps: Hashable {
    case first
    case second
    case third(email: String)

    var number: String {
        switch self {
        case .first: "1"
        case .second: "2"
        case .third: "3"
        }
    }

    var title: String {
        switch self {
        case .first:
            #localized("Enter the address you want to email.")
        case .second:
            #localized("Proton Pass will generate a forwarding address (also referred to as reverse alias).")
        case let .third(title):
            #localized("Email this address and it will appear to be sent from %@.", title)
        }
    }

    @MainActor @ViewBuilder
    var descriptionSubview: some View {
        switch self {
        case .first:
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.aliasInteractionNormMajor2,
                                 backgroundColor: PassColor.aliasInteractionNormMinor1,
                                 accessibilityLabel: "Close")
                    Spacer()

                    Text("Save")
                        .font(.callout)
                        .foregroundStyle(PassColor.textInvert.toColor)
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .background(PassColor.aliasInteractionNormMajor1.toColor)
                        .clipShape(Capsule())
                }
                Text("Create contact")
                    .font(.title.bold())
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .padding(.vertical, 16)

                Text(verbatim: "recipient_address@proton.me")
                    .padding(.top, 16)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .padding(16)
            .background(ZStack {
                PassColor.inputBorderNorm.toColor
                LinearGradient(gradient:
                    Gradient(colors: [
                        Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255, opacity: 0.05),
                        Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255, opacity: 0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing)
            })
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(PassColor.borderWeak.toColor, lineWidth: 1))
        case let .third(info):
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("From")
                                .fontWeight(.semibold)
                            Text("To")
                                .fontWeight(.semibold)
                        }.foregroundStyle(PassColor.textInvert.toColor)

                        VStack(alignment: .leading, spacing: 0) {
                            Label("From your alias <\(info)>",
                                  image: IconProvider.lockFilled)
                                .lineLimit(1)
                            Text("Your recipient")
                        }.foregroundStyle(PassColor.textInvert.toColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(uiImage: PassIcon.halfButtons)
                        .padding(.top, 16)
                }
                .padding(.leading, 18)
                .padding(.top, 12)
                .overlay(CustomBorderShape(cornerRadius: 12)
                    .stroke(PassColor.borderWeak.toColor, lineWidth: 1))
                .padding(.leading, 16)
                .padding(.top, 16)
                .frame(maxWidth: .infinity)
            }
            .background(.white)
            .cornerRadius(12)
        default:
            EmptyView()
        }
    }
}

private struct AliasExplanationView: View {
    @Environment(\.dismiss) private var dismiss

    let email: String

    var body: some View {
        ScrollView {
            VStack {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: PassIcon.envelope)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .edgesIgnoringSafeArea(.all)

                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNorm,
                                 backgroundColor: PassColor.textNorm,
                                 accessibilityLabel: "Close",
                                 action: dismiss.callAsFunction)
                        .padding(16)
                }
                .frame(height: 178)
                .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Alias contacts")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    // swiftlint:disable:next line_length
                    Text("To keep your personal email address hidden, you can create an alias contact that masks your address.")
                        .foregroundStyle(PassColor.textNorm.toColor)
                    Text("Here’s how it works:")
                        .foregroundStyle(PassColor.textNorm.toColor)

                    ForEach([
                        ContactCreationSteps.first,
                        ContactCreationSteps.second,
                        ContactCreationSteps.third(email: email)
                    ], id: \.self) { step in
                        ContactStepView(step: step)
                    }
                }.padding()

                Spacer()
            }.frame(maxWidth: .infinity)
        }.frame(maxWidth: .infinity)
    }
}

private struct ContactStepView: View {
    let step: ContactCreationSteps

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(step.number)
                    .foregroundStyle(PassColor.aliasInteractionNormMajor2.toColor)
                    .fontWeight(.medium)
                    .padding(10)
                    .background(Circle()
                        .stroke(PassColor.aliasInteractionNormMinor1.toColor, lineWidth: 1))
                VStack {
                    Divider()
                }
            }.padding(.top, 10)

            Text(step.title)
                .foregroundStyle(PassColor.textNorm.toColor)

            step.descriptionSubview
        }
    }
}

private struct CustomBorderShape: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start at top-left corner, but account for corner radius
        path.move(to: CGPoint(x: 0, y: cornerRadius))

        // Leading border
        path.addLine(to: CGPoint(x: 0, y: rect.height))

        // Back to top-left corner and create a curve for the top-left corner radius
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        // Top border
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        return path
    }
}
