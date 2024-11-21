//
// CheckAndAutoFill.swift
// Proton Pass - Created on 24/02/2024.
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

import AuthenticationServices
import Client
import Entities
import Foundation
import UseCases

// swiftlint:disable function_parameter_count
protocol CheckAndAutoFillUseCase: Sendable {
    func execute(_ request: AutoFillRequest,
                 userId: String,
                 context: ASCredentialProviderExtensionContext,
                 localAuthenticationMethod: LocalAuthenticationMethod,
                 appLockTime: AppLockTime,
                 lastActiveTimestamp: TimeInterval?) async throws
}

extension CheckAndAutoFillUseCase {
    func callAsFunction(_ request: AutoFillRequest,
                        userId: String,
                        context: ASCredentialProviderExtensionContext,
                        localAuthenticationMethod: LocalAuthenticationMethod,
                        appLockTime: AppLockTime,
                        lastActiveTimestamp: TimeInterval?) async throws {
        try await execute(request,
                          userId: userId,
                          context: context,
                          localAuthenticationMethod: localAuthenticationMethod,
                          appLockTime: appLockTime,
                          lastActiveTimestamp: lastActiveTimestamp)
    }
}

final class CheckAndAutoFill: CheckAndAutoFillUseCase {
    private let credentialProvider: any AuthManagerProtocol
    private let canSkipLocalAuthentication: any CanSkipLocalAuthenticationUseCase
    private let generateAuthorizationCredential: any GenerateAuthorizationCredentialUseCase
    private let cancelAutoFill: any CancelAutoFillUseCase
    private let completeAutoFill: any CompleteAutoFillUseCase
    private let userManager: any UserManagerProtocol
    private let getFeatureFlagStatus: any GetFeatureFlagStatusUseCase

    init(credentialProvider: any AuthManagerProtocol,
         userManager: any UserManagerProtocol,
         canSkipLocalAuthentication: any CanSkipLocalAuthenticationUseCase,
         generateAuthorizationCredential: any GenerateAuthorizationCredentialUseCase,
         cancelAutoFill: any CancelAutoFillUseCase,
         completeAutoFill: any CompleteAutoFillUseCase,
         getFeatureFlagStatus: any GetFeatureFlagStatusUseCase) {
        self.credentialProvider = credentialProvider
        self.canSkipLocalAuthentication = canSkipLocalAuthentication
        self.generateAuthorizationCredential = generateAuthorizationCredential
        self.cancelAutoFill = cancelAutoFill
        self.completeAutoFill = completeAutoFill
        self.userManager = userManager
        self.getFeatureFlagStatus = getFeatureFlagStatus
    }

    func execute(_ request: AutoFillRequest,
                 userId: String,
                 context: ASCredentialProviderExtensionContext,
                 localAuthenticationMethod: LocalAuthenticationMethod,
                 appLockTime: AppLockTime,
                 lastActiveTimestamp: TimeInterval?) async throws {
        let betterAuthentication = getFeatureFlagStatus(for: FeatureFlagType.passIOSBetterAuthentication)
        let canSkip = canSkipLocalAuthentication(appLockTime: appLockTime,
                                                 lastActiveTimestamp: lastActiveTimestamp)
        guard credentialProvider.isAuthenticated(userId: userId),
              localAuthenticationMethod == .none || (canSkip && betterAuthentication) else {
            cancelAutoFill(reason: .userInteractionRequired, context: context)
            return
        }
        let (itemContent, credential) = try await generateAuthorizationCredential(request)
        try await completeAutoFill(quickTypeBar: true,
                                   identifiers: request.serviceIdentifiers,
                                   credential: credential,
                                   itemContent: itemContent,
                                   context: context)
    }
}

// swiftlint:enable function_parameter_count
