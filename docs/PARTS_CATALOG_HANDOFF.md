# Parts Catalog — Agent handoff

Package: `Packages/Shared/WorkingMansPartsCatalog` (standalone Swift package).

## Current functionality
- Part, asset, specification, provenance and live-result models.
- Offline in-memory search and category filtering.
- JSON import/export, atomic import checks and unit tests.
- Provider protocol for future authorized live supplier APIs.
- No live supplier API, bundled product catalog, user interface, SQLite database, or CAD rendering yet.

## Immediate tasks
1. Run `swift test` on macOS with Xcode command line tools. Linux Swift 6.2.1 passed all four tests.
2. Ensure PR #1 (initial core package) is merged before or alongside the parts-catalog PR, since this branch builds on `feature/initial-swift-package`.
3. Create a universal SwiftUI iPhone/iPad/Mac catalog interface with category filters, search, part details, provenance and asset links.
4. Add SQLite or GRDB persistence behind a protocol, migration logic, full-text search, and scalable pagination.
5. Add tests for invalid/missing provenance, malformed URLs, categories, duplicate imports, large files and escaping.
6. Add a source-license registry with documented approvals and review workflow. A Boolean is not legal proof.
7. Implement provider adapters only when API agreement authorizes the intended public use. Avoid scraping or replicating protected catalogs.
8. Add a Mac CAD conversion pipeline (for appropriately licensed models) to USDZ; use native Apple 3D viewing on iPhone, iPad and Mac. Retain original file metadata.
9. Add macOS CI test workflow, then run platform simulator tests.

## Licensing
Apache-2.0 applies to original code only. Third-party datasets and CAD assets retain separate licensing. Do not import protected materials or hardcode vendor secrets.
