//
//  EitherResponses.swift
//  ProtonCore-Authentication - Created on 25/05/2023.
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

import ProtonCore_Services
import ProtonCore_Networking
import ProtonCore_Utilities

final class EitherResponses: Response, APIDecodableResponse {
    var response: Either<AuthInfoResponse, SSOResponse>
    
    required init(from decoder: Decoder) throws {
        do {
            let authInfoResponse = try AuthInfoResponse(from: decoder)
            response = .left(authInfoResponse)
        } catch {
            try response = .right(SSOResponse(from: decoder))
        }
    }
    
    required init() {
        response = .left(AuthInfoResponse(modulus: "", serverEphemeral: "", version: 0, salt: "", srpSession: ""))
    }
}