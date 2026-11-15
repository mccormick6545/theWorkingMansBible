# Dataset licensing

The repository's Apache-2.0 code license **does not** relicense third-party datasets.

Each imported dataset must document:
- exact origin URL and publisher
- license and version
- redistribution and offline caching permission
- attribution / share-alike requirements
- update timestamp and validation process

Until reviewed, source candidates are links, not bundled datasets.

## Catalog data files (`Data/`)

Each record in a `Data/*.json` catalog carries its own `source` (publisher, https URL, license identifier,
attribution, retrieval date). The app refuses a catalog that has any record without them. Licensed or paid content
is never stored in this repository; it is served to signed-in customers by a separate private service.
