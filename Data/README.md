# Data files

The app loads its catalogs from versioned JSON files in this folder. The format is defined in
`Packages/Shared/WorkingMansCore/Sources/WorkingMansCore/CatalogDataset.swift`.

## Rules

1. **Every record needs a source and a license.** `source.publisher`, `source.url` (https), `source.license`
   and `source.retrievedOn` are required. A file with one bad record is rejected whole.
2. **Only add data whose license you've checked** for this use. Note the exact license identifier and any
   attribution text it requires.
3. **No licensed or paid content goes in this folder.** Licensed manuals, diagrams, videos and parts data are
   served by the private backend to signed-in customers, never committed here.
4. **Unknown years are allowed** (`yearFrom`/`yearTo` set to `null`). The app labels them as unknown.
5. **Bump `schemaVersion`** only when the format changes in a way older apps can't read.

## Files

| File | Contents | Status |
|---|---|---|
| `vehicle-catalog/catalog.json` | Vehicles by make, model and years | Empty placeholder. No records added yet. |

## Adding a record

```json
{
  "id": "example-make-model-1990",
  "category": "car",
  "make": "Example",
  "model": "Model A",
  "yearFrom": 1990,
  "yearTo": 1995,
  "source": {
    "publisher": "Name of the publisher",
    "url": "https://publisher.example/page-the-data-came-from",
    "license": "CC0-1.0",
    "attribution": "",
    "retrievedOn": "2026-11-14"
  }
}
```

Run the package tests after any change: `cd Packages/Shared/WorkingMansCore && swift test`.
