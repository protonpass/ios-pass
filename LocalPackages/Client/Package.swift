// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v8)
]

let package = Package(name: "Client",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Client",
                                   targets: ["Client"])
                      ],
                      dependencies: [
                          .package(url: "https://github.com/ashleymills/Reachability.swift",
                                   branch: "master"),
                          .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.0.0"),
                          .package(name: "Core", path: "../Core"),
                          .package(name: "Entities", path: "../Entities"),
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "11.0.0")
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
                                      .product(name: "ProtonCoreServices", package: "protoncore_ios"),
                                      .product(name: "Core", package: "Core"),
                                      .product(name: "Entities", package: "Entities"),
                                      .product(name: "Reachability", package: "Reachability.swift"),
                                      .product(name: "SwiftProtobuf", package: "swift-protobuf")
                                  ],
                                  resources: [.process("Resources")]),
                          .testTarget(name: "ClientTests",
                                      dependencies: ["Client"])
                      ])
