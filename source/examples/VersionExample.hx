// Example usage of the enhanced Version macro system
// This demonstrates how to access version information and perform comparisons at runtime

import backend.Version;

class VersionExample {
    public static function demonstrateVersionInfo() {
        // Basic version strings
        trace("Engine Version: " + Version.ENGINE_VERSION);
        trace("Beta Version: " + Version.ENGINE_BETA);

        // Build information
        trace("Build Number: " + Version.BUILD_NUMBER);
        trace("Build Date: " + Version.BUILD_DATE);

        // Formatted version strings
        trace("Version with build: " + Version.getVersionString(true));
        trace("Version without build: " + Version.getVersionString(false));

        // Complete version info
        trace("Full version info: " + Version.getFullVersionInfo());

        // Individual version components
        trace("Major: " + Version.getMajor());
        trace("Minor: " + Version.getMinor());
        trace("Patch: " + Version.getPatch());
        trace("Beta: " + Version.getBeta());

        // Version comparisons
        trace("Is newer than 4.8.0: " + Version.isNewerThan("4.8.0"));
        trace("Is older than 5.0.0: " + Version.isOlderThan("5.0.0"));
        trace("Is equal to current: " + Version.isEqualTo(Version.getVersionString(false)));

        // Direct comparison (returns -1, 0, or 1)
        trace("Compare with 4.7.0: " + Version.compareVersion("4.7.0"));

        // Semantic version usage
        var currentSemVer = Version.SEMANTIC_VERSION;
        trace("Semantic version: " + currentSemVer.toString());
        trace("Major from semantic: " + currentSemVer.major);

        // Usage examples for UI elements:
        // var titleText = "Friday Night Funkin': Mixtape Engine " + Version.getVersionString(true);
        // var creditsText = "Built on " + Version.BUILD_DATE + " (Build " + Version.BUILD_NUMBER + ")";
        // var debugInfo = "Engine: " + Version.getFullVersionInfo();

        // Version validation example:
        // if (Version.isOlderThan("4.8.0")) {
        //     trace("WARNING: This version is older than the minimum required!");
        // }
    }

    public static function demonstrateVersionComparison() {
        // Example of checking version compatibility
        var requiredVersion = "4.8.0";

        if (Version.isOlderThan(requiredVersion)) {
            trace("Current version " + Version.getVersionString(false) + " is older than required " + requiredVersion);
        } else if (Version.isNewerThan(requiredVersion)) {
            trace("Current version " + Version.getVersionString(false) + " is newer than required " + requiredVersion);
        } else {
            trace("Current version matches required version " + requiredVersion);
        }

        // Check for beta versions
        if (Version.getBeta() != "") {
            trace("This is a beta version: " + Version.getBeta());
        } else {
            trace("This is a stable release");
        }
    }
}
