// swift-tools-version: 5.9
import PackageDescription

// On-device document archive (receipts, warranties, service records) and PDF export.
// Shared by the home and vehicle sides; each keeps its own records under its own owner ID.
// iOS 17 / macOS 14 for the Observation framework.
let package = Package(
    name: "WorkingMansDocuments",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "WorkingMansDocuments", targets: ["WorkingMansDocuments"])],
    targets: [
        .target(name: "WorkingMansDocuments"),
        .testTarget(name: "WorkingMansDocumentsTests", dependencies: ["WorkingMansDocuments"])
    ]
)
