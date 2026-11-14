# Third-party data source registry

No third-party data is bundled in this starter project.

## Live services the code calls (nothing is stored in the repository)

| Service | Used by | Sent | Notes |
|---|---|---|---|
| NHTSA vPIC VIN decoder (`vpic.nhtsa.dot.gov`) | `WorkingMansVehicles.NHTSAVINDecoder` | The VIN only | U.S. government service, no key |
| NHTSA recalls API (`api.nhtsa.gov/recalls`) | `WorkingMansVehicles.VehicleRecalls` | Year, make, model | Model-level results; links to NHTSA's per-VIN check for open recalls |
| CPSC Recall Retrieval API (`saferproducts.gov/RestWebServices/Recall`) | `WorkingMansHome.ApplianceLookup` | The model number only | U.S. government service, no key; no pagination, results capped at 25 |

## Link-only sources (opened in the browser when tapped; never scraped, cached or embedded)

| Site | Purpose |
|---|---|
| RepairClinic, PartSelect, Sears PartsDirect | Appliance and fixture parts diagrams by model number – free third-party lookups, labeled "not the manufacturer" |
| NHTSA recalls by VIN, CPSC.gov recalls | Official recall searches |
| Google search | Owner's and installation manuals – labeled "not verified" |

| Candidate | Purpose | Review needed |
|---|---|---|
| NHTSA vPIC | VIN / vehicle identification | Verify relevant reuse conditions and provenance |
| Wikidata | Product and vehicle identifiers | CC0 structured data; check record quality |
| VehiclesDB | Vehicle catalog | License and upstream rights review |
| OBDex | Diagnostic data | Review dataset and code licenses independently |
| Open Products Facts | Home product records | Confirm database, image and contributor licensing |
| PVWatts | Solar estimates | API terms and attribution |
| OEM manuals | Procedures and illustrations | Link only unless redistribution permission confirmed |

Never republish manuals, parts drawings, OEM torque charts or other copyrighted material based merely on public availability.
