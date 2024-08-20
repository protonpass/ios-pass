//
// CoreDataEntityStructureTests.swift
// Proton Pass - Created on 02/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

@testable import Client
import Core
import CoreData
import XCTest

final class CoreDataEntityStructureTests: XCTestCase {
    var container: NSPersistentContainer!

    override func setUp() {
        super.setUp()
        container = DatabaseService.build(name: kProtonPassContainerName, inMemory: true)
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func verifyAttribute(named name: String,
                         on entity: NSEntityDescription,
                         hasType type: NSAttributeDescription.AttributeType) {
        guard !name.isEmpty else {
            XCTFail("Attribute name can not be empty")
            return
        }
        guard let attribute = entity.attributesByName[name] else {
            XCTFail("\(entity.name ?? "") is missing expected attribute \(name)")
            return
        }
        XCTAssertEqual(attribute.type, type)
    }

    func entity(byName name: String) -> NSEntityDescription {
        guard let entity = container.managedObjectModel.entitiesByName[name] else {
            continueAfterFailure = false
            XCTFail("Entity \(name) not found")

            // fatalError() to trick the compiler.
            // Should not be called because stopped by `continueAfterFailure = false` above
            fatalError("👻🐶😜")
        }
        return entity
    }

    func testShareEntity() {
        let sut = entity(byName: "ShareEntity")
        verifyAttribute(named: "content", on: sut, hasType: .string)
        verifyAttribute(named: "contentFormatVersion", on: sut, hasType: .integer64)
        verifyAttribute(named: "contentKeyRotation", on: sut, hasType: .integer64)
        verifyAttribute(named: "createTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "expireTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "owner", on: sut, hasType: .boolean)
        verifyAttribute(named: "permission", on: sut, hasType: .integer64)
        verifyAttribute(named: "shareID", on: sut, hasType: .string)
        verifyAttribute(named: "symmetricallyEncryptedContent", on: sut, hasType: .string)
        verifyAttribute(named: "targetID", on: sut, hasType: .string)
        verifyAttribute(named: "targetType", on: sut, hasType: .integer64)
        verifyAttribute(named: "vaultID", on: sut, hasType: .string)
        verifyAttribute(named: "addressID", on: sut, hasType: .string)
    }

    func testShareKeyEntity() {
        let sut = entity(byName: "ShareKeyEntity")
        verifyAttribute(named: "createTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "key", on: sut, hasType: .string)
        verifyAttribute(named: "keyRotation", on: sut, hasType: .integer64)
        verifyAttribute(named: "shareID", on: sut, hasType: .string)
        verifyAttribute(named: "symmetricallyEncryptedKey", on: sut, hasType: .string)
        verifyAttribute(named: "userID", on: sut, hasType: .string)
        verifyAttribute(named: "userKeyID", on: sut, hasType: .string)
    }

    func testItemEntity() {
        let sut = entity(byName: "ItemEntity")
        verifyAttribute(named: "aliasEmail", on: sut, hasType: .string)
        verifyAttribute(named: "content", on: sut, hasType: .string)
        verifyAttribute(named: "contentFormatVersion", on: sut, hasType: .integer64)
        verifyAttribute(named: "createTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "isLogInItem", on: sut, hasType: .boolean)
        verifyAttribute(named: "pinned", on: sut, hasType: .boolean)
        verifyAttribute(named: "itemID", on: sut, hasType: .string)
        verifyAttribute(named: "itemKey", on: sut, hasType: .string)
        verifyAttribute(named: "keyRotation", on: sut, hasType: .integer64)
        verifyAttribute(named: "lastUseTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "modifyTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "revision", on: sut, hasType: .integer64)
        verifyAttribute(named: "revisionTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "shareID", on: sut, hasType: .string)
        verifyAttribute(named: "state", on: sut, hasType: .integer64)
        verifyAttribute(named: "symmetricallyEncryptedContent", on: sut, hasType: .string)
        verifyAttribute(named: "flags", on: sut, hasType: .integer64)
    }

    func testShareEventIDEntity() {
        let sut = entity(byName: "ShareEventIDEntity")
        verifyAttribute(named: "userID", on: sut, hasType: .string)
        verifyAttribute(named: "shareID", on: sut, hasType: .string)
        verifyAttribute(named: "lastEventID", on: sut, hasType: .string)
    }

    func testSearchEntryEntity() {
        let sut = entity(byName: "SearchEntryEntity")
        verifyAttribute(named: "itemID", on: sut, hasType: .string)
        verifyAttribute(named: "shareID", on: sut, hasType: .string)
        verifyAttribute(named: "time", on: sut, hasType: .integer64)
        verifyAttribute(named: "userID", on: sut, hasType: .string)
    }

    func testTelemetryEventEntity() {
        let sut = entity(byName: "TelemetryEventEntity")
        verifyAttribute(named: "uuid", on: sut, hasType: .string)
        verifyAttribute(named: "rawValue", on: sut, hasType: .string)
        verifyAttribute(named: "time", on: sut, hasType: .double)
        verifyAttribute(named: "userID", on: sut, hasType: .string)
    }

    func testAccessEntity() {
        let sut = entity(byName: "AccessEntity")
        verifyAttribute(named: "aliasLimit", on: sut, hasType: .integer64)
        verifyAttribute(named: "displayName", on: sut, hasType: .string)
        verifyAttribute(named: "hideUpgrade", on: sut, hasType: .boolean)
        verifyAttribute(named: "internalName", on: sut, hasType: .string)
        verifyAttribute(named: "totpLimit", on: sut, hasType: .integer64)
        verifyAttribute(named: "trialEnd", on: sut, hasType: .integer64)
        verifyAttribute(named: "type", on: sut, hasType: .string)
        verifyAttribute(named: "userID", on: sut, hasType: .string)
        verifyAttribute(named: "vaultLimit", on: sut, hasType: .integer64)
        verifyAttribute(named: "monitorProtonAddress", on: sut, hasType: .boolean)
        verifyAttribute(named: "monitorAliases", on: sut, hasType: .boolean)
        verifyAttribute(named: "pendingInvites", on: sut, hasType: .integer64)
        verifyAttribute(named: "waitingNewUserInvites", on: sut, hasType: .integer64)
        verifyAttribute(named: "minVersionUpgrade", on: sut, hasType: .string)
        verifyAttribute(named: "defaultShareID", on: sut, hasType: .string)
        verifyAttribute(named: "aliasSyncEnabled", on: sut, hasType: .boolean)
        verifyAttribute(named: "pendingAliasToSync", on: sut, hasType: .integer64)
    }

    func testSpotlightVaultEntity() {
        let sut = entity(byName: "SpotlightVaultEntity")
        verifyAttribute(named: "userID", on: sut, hasType: .string)
        verifyAttribute(named: "shareID", on: sut, hasType: .string)
    }

    func testOrganizationEntity() {
        let sut = entity(byName: "OrganizationEntity")
        verifyAttribute(named: "canUpdate", on: sut, hasType: .boolean)
        verifyAttribute(named: "exportMode", on: sut, hasType: .integer64)
        verifyAttribute(named: "forceLockSeconds", on: sut, hasType: .integer64)
        verifyAttribute(named: "shareMode", on: sut, hasType: .integer64)
        verifyAttribute(named: "userID", on: sut, hasType: .string)
    }

    func testUserPreferencesEntity() {
        let sut = entity(byName: "UserPreferencesEntity")
        verifyAttribute(named: "userID", on: sut, hasType: .string)
        verifyAttribute(named: "encryptedContent", on: sut, hasType: .binaryData)
    }

    func testUserProfileEntity() {
        let sut = entity(byName: "UserProfileEntity")
        verifyAttribute(named: "updateTime", on: sut, hasType: .integer64)
        verifyAttribute(named: "userID", on: sut, hasType: .string)
        verifyAttribute(named: "encryptedData", on: sut, hasType: .binaryData)
        verifyAttribute(named: "isActive", on: sut, hasType: .boolean)
    }

    func testItemReadEventEntity() {
        let sut = entity(byName: "ItemReadEventEntity")
        verifyAttribute(named: "shareID", on: sut, hasType: .string)
        verifyAttribute(named: "itemID", on: sut, hasType: .string)
        verifyAttribute(named: "time", on: sut, hasType: .double)
    }
    
    func testAuthCredentialEntity() {
        let sut = entity(byName: "AuthCredentialEntity")
        verifyAttribute(named: "encryptedData", on: sut, hasType: .binaryData)
        verifyAttribute(named: "module", on: sut, hasType: .string)
        verifyAttribute(named: "userID", on: sut, hasType: .string)
    }
}
