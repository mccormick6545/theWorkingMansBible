# Basic free-source content release checklist

This repository is the **public, app-visible Basic source**. The data decoder now checks a narrow allowlist of license identifiers; the policy is a machine-readable safety gate, **not independent proof** that the asserted license belongs to the specific asset.

## Two-step approval for every source record
1. **Human evidence review before adding a record**: verify the copyright owner or public-domain authority, precise asset/version and license terms; commercial use, redistribution, derivatives, attribution, link/notice and trademarks, sublicensing and share-alike duties; note any third-party photographs/manuals/embedded tables that use different licenses. Keep dated license evidence in the source registry. If uncertain, do not add it to Basic.
2. **Automated format/license check at load**: only identifiers on the reviewed allowlist, HTTPS provenance, mandatory attribution for CC BY, nonblank identifiers, valid years, and duplicate-ID check. Reject the entire pack on failure. Never treat an API being free to query or a repository having an OSS license as permission to copy its data.

## Initial policy
Allowed machine identifiers (not blanket asset approvals): `CC0-1.0`, `MIT`, `Apache-2.0`, `BSD-2-Clause`, `BSD-3-Clause`, `0BSD`, `Unlicense`, and `CC-BY-4.0`. The last requires nonempty attribution and a review of appropriate credit, change notices and license link. Additional asset-level notices may be necessary for others too.

Temporarily **excluded from the automated release gate**: GPL, LGPL, CC BY-SA, CC BY-NC, proprietary, uncertain/unknown, 'all rights reserved', paid contracts, unverified government-work claims and sources whose data rights are not explicitly established. Exclusion is not a finding they can never be used: some are legally usable under the right compliance, but Basic will not distribute them until the conditions can be fulfilled and validated. Commercially reusable share-alike licenses may be approved in a future separately reviewed release.

## Role of other repositories
- **BasicContact**: internal links and metadata for uncertain or contact-required resources; no copied third-party source.
- **Low/Medium/Premium**: disabled private feature stubs and purchased-license integration points, with independent rights review and authorization.
- **Main Xcode app**: consumes vetted Basic code/data only. Do not connect to private libraries, paid APIs, proprietary manuals or premium storage by default.

## Release checks
- Review every source asset against original upstream license evidence; pin its exact version and SHA-256 checksum.
- Verify notices in the App Store build and any redistributable data packs.
- Confirm no user profile, work history, cloud-sync selection, photos, exact address or project data is present in repository content.
- Test no network requests are made when browsing bundled offline data.
- Run `swift test` in `Packages/Shared/WorkingMansCore`, full Xcode app builds, and a privacy/architecture audit before merge.
- Review any applicable App Store terms, export/trademark and supplier restrictions before release.

This change contains no additional vehicle, manual, diagram, video, torque or third-party dataset records.
