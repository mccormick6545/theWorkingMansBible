# WorkingMansPartsCatalog

Foundation-only Swift Package Manager library for iPhone, iPad, and Mac (iOS 16+, macOS 13+).

## Implemented

- Codable product/part, specifications, asset and provenance models
- Actor-backed offline search and category filtering
- Deterministic JSON import/export
- Fail-closed redistribution checks on imported parts and each included asset
- Live provider protocol separating transient supplier results from redistributable data
- Unit tests with fictional items; no proprietary or third-party catalog data included

## Usage

Add `Packages/WorkingMansPartsCatalog` as a local package in Xcode or add as a Git dependency once the branch is merged.

```swift
import WorkingMansPartsCatalog

let catalog = PartCatalog()
let results = await catalog.search("bolt")
```

## Important limitations

- `redistributionApproved` is importer-provided metadata, not a legal determination. Verify documented rights before setting true.
- The package does not download CAD, images, or manuals; URLs are references.
- This initial version is an in-memory actor with JSON import/export, not SQLite, live APIs, CAD conversion, or a SwiftUI interface.
- Never embed supplier secrets in a public app.
- Review rights and per-model attribution for any third-party CAD library before import.

## Testing

From this directory:

```sh
swift test
```

The Foundation-only tests passed on Linux using Swift 6.2.1 (4 tests). Apple platform tests still need to run in Xcode.
