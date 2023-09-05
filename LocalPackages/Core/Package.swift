// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v8)
]

let package = Package(name: "Core",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Core",
                                   targets: ["Core"])
                      ],
                      dependencies: [
                          .package(url: "https://github.com/protonpass/OneTimePassword", exact: "0.1.1"),
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "10.1.1")
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
                                      .product(name: "ProtonCoreNetworking", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreSettings", package: "protoncore_ios"),
                                      .product(name: "OneTimePassword", package: "OneTimePassword")
                                  ],
                                  resources: [
                                      .process("Resources")
                                  ]),
                          .testTarget(name: "CoreTests",
                                      dependencies: [
                                          "Core",
                                          .product(name: "ProtonCoreTestingToolkitUnitTestsCore",
                                                   package: "protoncore_ios")

                                      ])
                      ])
