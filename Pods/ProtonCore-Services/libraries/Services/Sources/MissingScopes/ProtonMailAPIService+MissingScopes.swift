//
//  ProtonMailAPIService+MissingScopes.swift
//  ProtonCore-Services - Created on 20.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import ProtonCore_Log
import ProtonCore_Networking

extension PMAPIService {
    func missingScopesHandler<T>(username: String,
                                 responseHandler: PMResponseHandlerData,
                                 completion: PMAPIService.APIResponseCompletion<T>) where T: Decodable {
        missingScopesDelegate?.getAuthInfo(username: username) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let authInfo):
                if !self.isPasswordVerifyUIPresented.transform({ $0 }) {
                    self.missingPasswordScopesUIHandler(
                        authInfo: authInfo,
                        username: username,
                        responseHandlerData: responseHandler,
                        completion: completion
                    )
                }
            case .failure(AuthErrors.networkingError(let error)):
                self.missingScopesDelegate?.showAlert(title: "Error", message: error.localizedDescription)
                PMLog.info(String(describing: error))
            case .failure(AuthErrors.apiMightBeBlocked(let message, let originalError)):
                self.missingScopesDelegate?.showAlert(title: "API might be blocked", message: message)
                PMLog.info(String(describing: originalError))
            case .failure(let authErrors):
                PMLog.info(String(describing: authErrors))
            }
        }
    }
    
    private func missingPasswordScopesUIHandler<T>(authInfo: AuthInfoResponse,
                                                   username: String,
                                                   responseHandlerData: PMResponseHandlerData,
                                                   completion: APIResponseCompletion<T>) where T: Decodable {
        self.isPasswordVerifyUIPresented.mutate { $0 = true }

        missingScopesDelegate?.onMissingScopesHandling(authInfo: authInfo, username: username, responseHandlerData: responseHandlerData) { [weak self] reason in
            
            guard let self else { return }
            
            if self.isPasswordVerifyUIPresented.transform({ $0 }) {
                self.isPasswordVerifyUIPresented.mutate { $0 = false }
            }
            
            switch reason {
            case .unlocked:
                self.verificationHandler(
                    responseHandlerData: responseHandlerData,
                    completion: completion
                )
            case .closed:
                completion.call(task: responseHandlerData.task, error: NSError())
            case .closedWithError(let code, let description):
                let newResponseError = APIError.protonMailError(code, localizedDescription: description)
                completion.call(task: responseHandlerData.task, error: newResponseError as NSError)
            }
        }
    }
    
    // swiftlint:disable function_parameter_count
    private func verificationHandler<T>(responseHandlerData: PMResponseHandlerData,
                                        completion: APIResponseCompletion<T>) where T: Decodable {
        startRequest(
            method: responseHandlerData.method,
            path: responseHandlerData.path,
            parameters: responseHandlerData.parameters,
            headers: responseHandlerData.headers,
            nonDefaultTimeout: responseHandlerData.nonDefaultTimeout,
            retryPolicy: responseHandlerData.retryPolicy,
            completion: completion
        )
    }
}
