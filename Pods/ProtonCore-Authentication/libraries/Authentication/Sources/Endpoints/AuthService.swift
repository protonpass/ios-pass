//
//  AuthService.swift
//  ProtonCore-Authentication - Created on 20/02/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Services
import ProtonCore_APIClient
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_FeatureSwitch

public class AuthService: Client {
    public var apiService: APIService
    public init(api: APIService) {
        self.apiService = api
    }
    
    public func info(username: String, complete: @escaping(_ response: AuthInfoResponse) -> Void) {
        let route = InfoEndpoint(username: username)
        let response = EitherResponses()
        switch response.response {
        case .left(let authInfo):
            self.apiService.perform(request: route, response: authInfo, responseCompletion: { _, response in
                complete(response)
            })
        case .right:
            fatalError("not ready, don't use")
        }
    }
    
    // swiftlint:disable function_parameter_count
    func auth(username: String,
              ephemeral: Data,
              proof: Data,
              session: String,
              challenge: ChallengeProperties?,
              complete: @escaping(_ response: Result<AuthService.AuthRouteResponse, ResponseError>) -> Void) {
        let route = AuthEndpoint(data: .left(.init(username: username, ephemeral: ephemeral, proof: proof, session: session, challenge: challenge)))
        guard isSessionUIDValid(session) else { return }
        self.apiService.perform(request: route, decodableCompletion: { _, result in complete(result) })
    }
    
    private func isSessionUIDValid(_ session: String) -> Bool {
        if !FeatureFactory.shared.isEnabled(.ssoSignIn) {
            return true
        }
        
        return session == apiService.sessionUID
    }
}
