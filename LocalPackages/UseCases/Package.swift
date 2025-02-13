// swift-tools-version: 6.0
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

let package = Package(name: "UseCases",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "UseCases",
                                   targets: ["UseCases"]),
                          .library(name: "UseCasesMocks",
                                   targets: ["UseCasesMocks"])
                      ],
                      dependencies: [
                          // Dependencies declare other packages that this package depends on.
                          .package(name: "Entities", path: "../Entities"),
                          .package(name: "Core", path: "../Core"),
                          .package(name: "Client", path: "../Client"),
                          .package(name: "PassRustCore", path: "../PassRustCore"),
                          .package(url: "https://github.com/getsentry/sentry-cocoa.git", exact: "8.40.1"),
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "29.0.10")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "UseCases",
                                  dependencies: [
                                      .product(name: "Entities", package: "Entities"),
                                      .product(name: "Client", package: "Client"),
                                      .product(name: "Core", package: "Core"),
                                      .product(name: "PassRustCore", package: "PassRustCore"),
                                      .product(name: "Sentry", package: "sentry-cocoa"),
                                      .product(name: "ProtonCoreFeatureFlags", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreTelemetry", package: "protoncore_ios")
                                  ],
                                  resources: [],
                                  swiftSettings: swiftSettings
                                 ),
                          .target(
                              name: "UseCasesMocks",
                              dependencies: ["UseCases"]),
                          .testTarget(name: "UseCasesTests",
                                      dependencies: ["UseCases",
                                                     "UseCasesMocks",
                                                     .product(name: "ClientMocks", package: "Client"),
                                                     .product(name: "CoreMocks", package: "Core"),
                                                     .product(name: "EntitiesMocks", package: "Entities"),
                                                     .product(name: "ProtonCoreForceUpgrade", package: "protoncore_ios")
                                                    ],
                                      path: "Tests")
                      ],
                      swiftLanguageModes: [.version("6")]
)
