// SPDX-License-Identifier: Apache-2.0
import Foundation

/// A restrictive *release gate*, not an automatic legal opinion.
/// Only content licenses pre-reviewed for a freely distributed, potentially
/// commercially sold app may pass. Every specific asset still needs its own
/// provenance review; licensing a repository's code does not license its data.
public enum BasicLicensePolicy {
    /// Consciously smaller than the set of all legally reusable licenses.
    /// Copyleft/share-alike sources require additional asset-level compliance
    /// and should remain in the review queue until support is implemented.
    public static let approvedIdentifiers: Set<String> = [
        "CC0-1.0", "MIT", "Apache-2.0", "BSD-2-Clause",
        "BSD-3-Clause", "0BSD", "Unlicense", "CC-BY-4.0"
    ]

    public static func validate(_ source: DataSource, recordID: String) throws {
        let license = source.license.trimmingCharacters(in: .whitespacesAndNewlines)
        guard approvedIdentifiers.contains(license) else {
            throw CatalogDataError.unsupportedLicense(recordID, license)
        }
        if license == "CC-BY-4.0",
           source.attribution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw CatalogDataError.missingAttribution(recordID)
        }
    }
}
