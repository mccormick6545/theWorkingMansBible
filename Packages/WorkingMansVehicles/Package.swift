// swift-tools-version: 5.9
import PackageDescription

// Vehicle and equipment repair: VIN identification and recalls. Kept separate from home improvement.
let package = Package(
    name: "WorkingMansVehicles",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "WorkingMansVehicles", targets: ["WorkingMansVehicles"])],
    dependencies: [.package(path: "../WorkingMansCore")],
    targets: [
        .target(name: "WorkingMansVehicles", dependencies: ["WorkingMansCore"]),
        .testTarget(name: "WorkingMansVehiclesTests", dependencies: ["WorkingMansVehicles"])
    ]
)
