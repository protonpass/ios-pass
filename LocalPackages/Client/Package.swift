// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v8)
]

let swiftSettings: [SwiftSetting] = []

let package = Package(name: "Client",
                      defaultLocalization: "en",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Client",
                                   targets: ["Client"]),
                          .library(name: "ClientMocks",
                                   targets: ["ClientMocks"])
                      ],
                      dependencies: [
                          .package(name: "Core", path: "../Core"),
                          .package(name: "Entities", path: "../Entities"),
                          .package(name: "Macro", path: "../Macro"),
                          .package(name: "TestingToolkit", path: "../TestingToolkit"),
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "32.8.0"),
                          .package(name: "PassRustCore", path: "../PassRustCore"),
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "Client",
                                  dependencies: [
                                      .product(name: "ProtonCoreDataModel", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreLogin", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreCrypto", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreNetworking", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreSettings", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreKeyManager", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreCryptoGoInterface", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreFeatureFlags", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreServices", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreFoundations", package: "protoncore_ios"),
                                      .product(name: "Core", package: "Core"),
                                      .product(name: "Entities", package: "Entities"),
                                      .product(name: "PassRustCore", package: "PassRustCore"),
                                      .product(name: "Macro", package: "Macro"),
                                      .product(name: "ProtonCoreForceUpgrade", package: "protoncore_ios"),
                                  ],
                                  resources: [.process("Resources")],
                                  swiftSettings: swiftSettings
                                 ),
                          .target(
                              name: "ClientMocks",
                              dependencies: ["Client"]),
                          .testTarget(name: "ClientTests",
                                      dependencies: ["Client",
                                                     .product(name: "CoreMocks", package: "Core"),
                                                     .product(name: "TestingToolkit", package: "TestingToolkit"),
                                                     .product(name: "EntitiesMocks", package: "Entities"),
                                                     "ClientMocks",
                                                     .product(name: "ProtonCoreCryptoGoImplementation", package: "protoncore_ios"),
                                                     .product(name: "ProtonCoreTestingToolkitUnitTestsCore", package: "protoncore_ios"),
                                                    ])
                      ],
                      swiftLanguageModes: [.version("6")]
)
