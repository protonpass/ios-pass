// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v14),
    .tvOS(.v15),
    .watchOS(.v8)
]

let package = Package(name: "FeatureFlags",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, making them visible
                          // to other packages.
                          .library(name: "FeatureFlags",
                                   targets: ["FeatureFlags"])
                      ],
                      dependencies: [
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "11.0.1")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package, defining a module or a test suite.
                          // Targets can depend on other targets in this package and products from dependencies.
                          .target(name: "FeatureFlags",
                                  dependencies: [
                                      .product(name: "ProtonCoreNetworking", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreServices", package: "protoncore_ios")
                                  ]),
                          .testTarget(name: "FeatureFlagsTests",
                                      dependencies: ["FeatureFlags"],
                                      resources: [.process("Query")])
                      ])
