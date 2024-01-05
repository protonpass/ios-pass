// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v8)
]

let package = Package(name: "DesignSystem",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "DesignSystem",
                                   targets: ["DesignSystem"])
                      ],
                      dependencies: [
                          // Dependencies declare other packages that this package depends on.
                        .package(url: "https://gitlab.protontech.ch/apple/shared/protoncore.git", exact: "16.3.2")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "DesignSystem",
                                  dependencies: [
                                    .product(name: "ProtonCoreLoginUI", package: "protoncore")
                                  ],
                                  resources: [.process("Resources")]),
                          .testTarget(name: "DesignSystemTests",
                                      dependencies: ["DesignSystem"])
                      ])
