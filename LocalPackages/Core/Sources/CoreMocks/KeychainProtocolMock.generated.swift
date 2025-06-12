// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

import Core
import Foundation
import ProtonCoreKeymaker

public final class KeychainProtocolMock: @unchecked Sendable, KeychainProtocol {

    public init() {}

    // MARK: - dataOrError
    public var dataOrErrorForKeyAttributesThrowableError1: Error?
    public var closureDataOrError: () -> () = {}
    public var invokedDataOrErrorfunction = false
    public var invokedDataOrErrorCount = 0
    public var invokedDataOrErrorParameters: (key: String, attributes: [CFString: Any]?)?
    public var invokedDataOrErrorParametersList = [(key: String, attributes: [CFString: Any]?)]()
    public var stubbedDataOrErrorResult: Data?

    public func dataOrError(forKey key: String, attributes: [CFString: Any]?) throws -> Data? {
        invokedDataOrErrorfunction = true
        invokedDataOrErrorCount += 1
        invokedDataOrErrorParameters = (key, attributes)
        invokedDataOrErrorParametersList.append((key, attributes))
        if let error = dataOrErrorForKeyAttributesThrowableError1 {
            throw error
        }
        closureDataOrError()
        return stubbedDataOrErrorResult
    }
    // MARK: - stringOrError
    public var stringOrErrorForKeyAttributesThrowableError2: Error?
    public var closureStringOrError: () -> () = {}
    public var invokedStringOrErrorfunction = false
    public var invokedStringOrErrorCount = 0
    public var invokedStringOrErrorParameters: (key: String, attributes: [CFString: Any]?)?
    public var invokedStringOrErrorParametersList = [(key: String, attributes: [CFString: Any]?)]()
    public var stubbedStringOrErrorResult: String?

    public func stringOrError(forKey key: String, attributes: [CFString: Any]?) throws -> String? {
        invokedStringOrErrorfunction = true
        invokedStringOrErrorCount += 1
        invokedStringOrErrorParameters = (key, attributes)
        invokedStringOrErrorParametersList.append((key, attributes))
        if let error = stringOrErrorForKeyAttributesThrowableError2 {
            throw error
        }
        closureStringOrError()
        return stubbedStringOrErrorResult
    }
    // MARK: - setOrErrorDataKeyAttributes
    public var setOrErrorForKeyAttributesThrowableError3: Error?
    public var closureSetOrErrorDataKeyAttributes3: () -> () = {}
    public var invokedSetOrErrorDataKeyAttributes3 = false
    public var invokedSetOrErrorDataKeyAttributesCount3 = 0
    public var invokedSetOrErrorDataKeyAttributesParameters3: (data: Data, key: String, attributes: [CFString: Any]?)?
    public var invokedSetOrErrorDataKeyAttributesParametersList3 = [(data: Data, key: String, attributes: [CFString: Any]?)]()

    public func setOrError(_ data: Data, forKey key: String, attributes: [CFString: Any]?) throws {
        invokedSetOrErrorDataKeyAttributes3 = true
        invokedSetOrErrorDataKeyAttributesCount3 += 1
        invokedSetOrErrorDataKeyAttributesParameters3 = (data, key, attributes)
        invokedSetOrErrorDataKeyAttributesParametersList3.append((data, key, attributes))
        if let error = setOrErrorForKeyAttributesThrowableError3 {
            throw error
        }
        closureSetOrErrorDataKeyAttributes3()
    }
    // MARK: - setOrErrorStringKeyAttributes
    public var setOrErrorForKeyAttributesThrowableError4: Error?
    public var closureSetOrErrorStringKeyAttributes4: () -> () = {}
    public var invokedSetOrErrorStringKeyAttributes4 = false
    public var invokedSetOrErrorStringKeyAttributesCount4 = 0
    public var invokedSetOrErrorStringKeyAttributesParameters4: (string: String, key: String, attributes: [CFString: Any]?)?
    public var invokedSetOrErrorStringKeyAttributesParametersList4 = [(string: String, key: String, attributes: [CFString: Any]?)]()

    public func setOrError(_ string: String, forKey key: String, attributes: [CFString: Any]?) throws {
        invokedSetOrErrorStringKeyAttributes4 = true
        invokedSetOrErrorStringKeyAttributesCount4 += 1
        invokedSetOrErrorStringKeyAttributesParameters4 = (string, key, attributes)
        invokedSetOrErrorStringKeyAttributesParametersList4.append((string, key, attributes))
        if let error = setOrErrorForKeyAttributesThrowableError4 {
            throw error
        }
        closureSetOrErrorStringKeyAttributes4()
    }
    // MARK: - removeOrError
    public var removeOrErrorForKeyThrowableError5: Error?
    public var closureRemoveOrError: () -> () = {}
    public var invokedRemoveOrErrorfunction = false
    public var invokedRemoveOrErrorCount = 0
    public var invokedRemoveOrErrorParameters: (key: String, Void)?
    public var invokedRemoveOrErrorParametersList = [(key: String, Void)]()

    public func removeOrError(forKey key: String) throws {
        invokedRemoveOrErrorfunction = true
        invokedRemoveOrErrorCount += 1
        invokedRemoveOrErrorParameters = (key, ())
        invokedRemoveOrErrorParametersList.append((key, ()))
        if let error = removeOrErrorForKeyThrowableError5 {
            throw error
        }
        closureRemoveOrError()
    }
}
