// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v8)
]

let swiftSettings: [SwiftSetting] = [
]

let package = Package(name: "Core",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Core",
                                   targets: ["Core"]),
                          .library(name: "CoreMocks",
                                   targets: ["CoreMocks"])
                      ],
                      dependencies: [
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "32.8.0"),
                          .package(name: "Entities", path: "../Entities"),
                          .package(name: "DesignSystem", path: "../DesignSystem"),
                          .package(name: "Macro", path: "../Macro")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "Core",
                                  dependencies: [
                                      .product(name: "ProtonCoreDataModel", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreDoh", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreKeymaker", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreLogin", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreLoginUI", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreNetworking", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreSettings", package: "protoncore_ios"),
                                      .product(name: "Entities", package: "Entities"),
                                      .product(name: "DesignSystem", package: "DesignSystem"),
                                      .product(name: "Macro", package: "Macro")
                                  ],
                                  swiftSettings: swiftSettings
                                 ),
                          .target(
                              name: "CoreMocks",
                              dependencies: ["Core"]),
                          .testTarget(name: "CoreTests",
                                      dependencies: [
                                          "Core",
                                          "CoreMocks",
                                          .product(name: "EntitiesMocks", package: "Entities"),
                                          .product(name: "ProtonCoreTestingToolkitUnitTestsCore",
                                                   package: "protoncore_ios")

                                      ])
                      ],
                      swiftLanguageModes: [.version("6")]
)
