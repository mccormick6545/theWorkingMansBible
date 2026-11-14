# The Working Man's Bible

**A free, open-source, offline-first reference and project toolkit for the people who build, maintain, and repair things.**

One universal SwiftUI application for **iPhone, iPad, and Mac**. Planned coverage includes home improvement (plumbing, electrical, masonry, concrete, foundations, framing, carpentry, welding, fabrication, HVAC, solar, flooring, drywall, and gardening) and vehicle maintenance (cars, trucks, motorcycles, ATVs, and more).

## Project status

Early development. This repository currently contains a starter Swift package, project documentation, and initial calculators. **It is not yet a released app or verified engineering reference.**

## Principles

- Free to use; source code openly available.
- Offline-first features; optional synchronization later.
- A shared cross-platform Swift core for macOS, iOS, and iPadOS.
- Separate source-code licensing from third-party dataset and document rights.
- Show provenance, units, assumptions, and safety warnings for technical specifications.
- Never present inferred fastener torque values or structural/electrical designs as OEM or engineer-approved.

## Start developing

Open the repository in Xcode on macOS. Every package is a Swift Package Manager library; add them to a universal SwiftUI app target using **File → Add Package Dependencies → Add Local**.

Packages are grouped by side of the app:

```
Packages/
├── Home/                      Home improvement & trades only
│   └── WorkingMansHome
├── Vehicles/                  Vehicles & equipment only
│   └── WorkingMansVehicles
└── Shared/                    Used by both sides
    ├── WorkingMansCore
    ├── WorkingMansDocuments
    └── WorkingMansPartsCatalog
```

| Package | What it holds | Platforms |
|---|---|---|
| `Home/WorkingMansHome` | Trade calculators (wire size, voltage drop, solar, battery bank, concrete, block/brick, stairs) and appliance rating-plate lookup with CPSC recalls | iOS 16+, macOS 13+ |
| `Vehicles/WorkingMansVehicles` | VIN validation and check digit, NHTSA vPIC decoding, NHTSA recalls | iOS 16+, macOS 13+ |
| `Shared/WorkingMansCore` | Basic calculators, unit conversions, `SourceLink` | iOS 16+, macOS 13+ |
| `Shared/WorkingMansDocuments` | On-device document archive and PDF export (each owner's records stay separate) | iOS 17+, macOS 14+ |
| `Shared/WorkingMansPartsCatalog` | Offline parts catalog that only imports records with recorded redistribution rights | iOS 16+, macOS 13+ |

Rules: Home and Vehicles packages never depend on each other – only on `Shared`. New home features go in `Packages/Home`, new vehicle features in `Packages/Vehicles`, and only code both sides need goes in `Packages/Shared`.

Run the tests for a package from its folder:

```
cd Packages/Home/WorkingMansHome && swift test
```

### Repository roadmap

1. Universal SwiftUI app shell, searchable trades catalog, local project storage.
2. Tested material calculators and unit conversions.
3. Vehicle/product model identification and license-reviewed data connectors.
4. Offline documents, model viewing, plans, and community contributions.
5. Additional CAD and simulation adapters where technically and legally feasible.

## Data rights

No third-party manuals, torque databases, proprietary plans, or copyrighted diagrams are bundled without an applicable license or permission. See `docs/DATA_SOURCES.md` and `DATA_LICENSES.md`.

## Contributing

See `CONTRIBUTING.md` and `SECURITY.md`. Technical content requires a reliable source and review before appearing as verified guidance.

## License

Original code is licensed under Apache License 2.0 (see `LICENSE`). Third-party datasets keep their independent licenses.
