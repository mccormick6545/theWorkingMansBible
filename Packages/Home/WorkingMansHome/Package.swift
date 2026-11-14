// swift-tools-version: 5.9
import PackageDescription

// Home improvement and trades: calculators and appliance/fixture lookups. Kept separate from vehicles.
let package = Package(
    name: "WorkingMansHome",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "WorkingMansHome", targets: ["WorkingMansHome"])],
    dependencies: [.package(path: "../../Shared/WorkingMansCore")],
    targets: [
        .target(name: "WorkingMansHome", dependencies: ["WorkingMansCore"]),
        .testTarget(name: "WorkingMansHomeTests", dependencies: ["WorkingMansHome"])
    ]
)
