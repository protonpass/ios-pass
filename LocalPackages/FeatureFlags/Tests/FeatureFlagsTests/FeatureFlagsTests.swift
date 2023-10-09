@testable import FeatureFlags
import XCTest

enum TestFlagsType: String, FeatureFlagTypeProtocol {
    case blackFirday = "BlackFriday"
    case primaryVault = "PassRemovePrimaryVault"
    case notActivatedFlag = "ShouldNotAppear"
}

enum TestUpdatedFlagsType: String, FeatureFlagTypeProtocol {
    case editEmail = "EditEmailAddress"
    case accountRecovery = "SignedInAccountRecovery"
    case pageSizeSettings = "WebMailPageSizeSetting"
}

enum FeatureFlagsElementFactory {
    static let configuration1 = FeatureFlagsConfiguration(userId: "user", currentBUFlags: TestFlagsType.self)
    static let configuration2 = FeatureFlagsConfiguration(userId: "user2",
                                                          currentBUFlags: TestUpdatedFlagsType.self)
}

final class FeatureFlagsTests: XCTestCase {
    let localDataSource = DefaultLocalFeatureFlagsDatasource()
    let remoteDataSource = DefaultRemoteDatasourceMock()
    var sut: FeatureFlagsRepository!

    override func setUp() {
        super.setUp()
        sut = FeatureFlagsRepository(configuration: FeatureFlagsElementFactory.configuration1,
                                     localDatasource: localDataSource,
                                     remoteDatasource: remoteDataSource)
    }

    func testFilteringOfFeatureFlags_ShouldOnlyReturn2Flags() async throws {
        let flags = try await sut.getFlags()
        XCTAssertEqual(flags.flags.count, 2)
    }

    func testGettingSpecificFlag_ShouldReturnAFlag() async throws {
        let optionalFlag = await sut.getFlag(for: TestFlagsType.blackFirday)
        let flag = try XCTUnwrap(optionalFlag)
        XCTAssertEqual(flag.name, "BlackFriday")
    }

    func testGettingSpecificFlag_ShouldReturnnil() async throws {
        let optionalFlag = await sut.getFlag(for: TestFlagsType.notActivatedFlag)
        XCTAssertNil(optionalFlag)
    }

    func testCheckIfFlagIsEnabled_ShouldBeTrue() async throws {
        let isEnabled = await sut.isFlagEnable(for: TestFlagsType.blackFirday)
        XCTAssertTrue(isEnabled)
    }

    func testCheckIfFlagIsDisabled() async throws {
        let isEnabled = await sut.isFlagEnable(for: TestFlagsType.primaryVault)
        XCTAssertFalse(isEnabled)
    }

    func testCheckUpdateAndRefreshOfFlags_ShouldReturnNewFlags() async throws {
        await sut.update(with: FeatureFlagsElementFactory.configuration2)
        let flags = try await sut.refreshFlags()
        XCTAssertEqual(flags.flags.count, 3)
        let optionalFlag = await sut.getFlag(for: TestUpdatedFlagsType.editEmail)
        let flag = try XCTUnwrap(optionalFlag)
        XCTAssertEqual(flag.name, "EditEmailAddress")
    }

    func testResetAllFlags() async throws {
        await sut.resetFlags()
        let flagsUser1 = try await localDataSource
            .getFeatureFlags(userId: FeatureFlagsElementFactory.configuration2.userId)
        let flagsUser2 = try await localDataSource
            .getFeatureFlags(userId: FeatureFlagsElementFactory.configuration1.userId)
        XCTAssertNil(flagsUser1)
        XCTAssertNil(flagsUser2)
    }
}
