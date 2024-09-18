//
// OneTimeCodesViewModel.swift
// Proton Pass - Created on 18/09/2024.
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

@preconcurrency import AuthenticationServices
import Entities

enum OneTimeCodesViewModelState {
    case loading
    case loaded
    case error(any Error)
}

final class OneTimeCodesViewModel: AutoFillViewModel<CredentialsForOneTimeCodeAutoFill> {
    private let serviceIdentifiers: [ASCredentialServiceIdentifier]

    init(users: [UserUiModel],
         serviceIdentifiers: [ASCredentialServiceIdentifier],
         context: ASCredentialProviderExtensionContext,
         onCancel: @escaping () -> Void,
         onSelectUser: @escaping ([UserUiModel]) -> Void,
         onLogOut: @escaping () -> Void,
         onCreate: @escaping (LoginCreationInfo) -> Void,
         userForNewItemSubject: UserForNewItemSubject) {
        self.serviceIdentifiers = serviceIdentifiers
        super.init(context: context,
                   onCreate: onCreate,
                   onSelectUser: onSelectUser,
                   onCancel: onCancel,
                   onLogOut: onLogOut,
                   users: users,
                   userForNewItemSubject: userForNewItemSubject)
    }
}
