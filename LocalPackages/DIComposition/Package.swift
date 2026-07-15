// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v17),
    .tvOS(.v16),
    .watchOS(.v8)
]

let package = Package(
    name: "DIComposition",
    platforms: platforms,
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DIComposition",
            targets: ["DIComposition"]
        ),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core"),
        .package(name: "Entities", path: "../Entities"),
        .package(name: "UseCases", path: "../UseCases"),
        .package(name: "Client", path: "../Client"),
        .package(url: "https://github.com/ProtonMail/protoncore_ios", from: "37.4.0"),
        .package(url: "https://github.com/hmlongco/Factory", exact: "3.3.1"),
        .package(name: "PassRustCore", path: "../PassRustCore"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DIComposition",
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
                .product(name: "ProtonCoreForceUpgrade", package: "protoncore_ios"),
                .product(name: "Core", package: "Core"),
                .product(name: "Entities", package: "Entities"),
                .product(name: "Client", package: "Client"),
                .product(name: "FactoryKit", package: "Factory"),
                .product(name: "UseCases", package: "UseCases"),
                .product(name: "Stores", package: "UseCases"),
                .product(name: "PassRustCore", package: "PassRustCore"),
            ],
        ),
        .testTarget(
            name: "DICompositionTests",
            dependencies: ["DIComposition"]
        ),
    ],
    swiftLanguageModes: [.v6]
)



