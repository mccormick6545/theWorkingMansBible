// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorkingMansCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "WorkingMansCore", targets: ["WorkingMansCore"])],
    targets: [
        .target(name: "WorkingMansCore"),
        .testTarget(name: "WorkingMansCoreTests", dependencies: ["WorkingMansCore"])
    ]
)
