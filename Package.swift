// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TappCore",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TappCore",
            targets: ["TappCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tapp-so/Tapp-Networking-iOS.git", exact: "1.0.8")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TappCore",
            dependencies: [
                .product(name: "TappNetworking", package: "Tapp-Networking-iOS")
            ]
        ),
        .testTarget(
            name: "TappTests",
            dependencies: ["TappCore"]
        ),
    ]
)
