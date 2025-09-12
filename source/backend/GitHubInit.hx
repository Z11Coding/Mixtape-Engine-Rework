package backend;

/**
 * GitHub Integration Initializer
 * Handles automatic GitHub mod setup and downloading during engine startup
 */
class GitHubInit
{
    /**
     * Initializes GitHub integration with example mods
     * This should be called during engine startup (e.g., in Main.hx or TitleState)
     * Add your own GitHub mods here!
     */
    public static function initializeGitHubMods():Void
    {
        trace('Initializing GitHub mods integration...');

        // Example: Add individual GitHub mods
        // GitHubAPI.addGitHubMod("MyAwesomeMod", "username/my-awesome-mod", "main", "", 1);
        // GitHubAPI.addGitHubMod("CoolWeek", "modder/cool-week", "main", "", 2);

        // Example: Add GitHub repositories that contain multiple mods
        // GitHubAPI.addGitHubModsFolder("CommunityMods", "organization/community-mods", "main", "", 0);

        // For testing purposes, let's add a placeholder (you should replace this with real repos)
        // Uncomment and modify these lines to add your GitHub mods:

        /*
        // Single mod example:
        GitHubAPI.addGitHubMod(
            "ExampleMod",              // Virtual mod name
            "username/mod-repository", // GitHub repo (owner/repo)
            "main",                    // Branch
            "",                        // Access token (leave empty for public repos)
            1                          // Priority (lower = higher priority)
        );

        // Multi-mod folder example:
        GitHubAPI.addGitHubModsFolder(
            "ModPack",                 // Virtual folder name
            "username/mod-pack-repo",  // GitHub repo containing multiple mods
            "main",                    // Branch
            "",                        // Access token (leave empty for public repos)
            0                          // Priority (lower = higher priority)
        );
        */

        var enabledMods = GitHubAPI.getEnabledGitHubMods();
        var enabledFolders = GitHubAPI.getEnabledGitHubModsFolders();

        if (enabledMods.length > 0 || enabledFolders.length > 0) {
            trace('GitHub mods configured:');
            for (mod in enabledMods) {
                trace('  - Individual mod: ${mod.name} (${mod.repository}/${mod.branch})');
            }
            for (folder in enabledFolders) {
                trace('  - Mod folder: ${folder.name} (${folder.repository}/${folder.branch})');
                trace('    Discovered mods: ${folder.discoveredMods.join(", ")}');
            }
        } else {
            trace('No GitHub mods configured. Add your GitHub repositories in GitHubInit.initializeGitHubMods()');
        }
    }

    /**
     * Forces a re-download of all GitHub mods
     * Useful for development or when mods have been updated
     */
    public static function forceRedownloadGitHubMods():Void
    {
        trace('Forcing GitHub mod re-download...');
        GitHubDownloadManager.clearDownloadedMods();

        // The next time a loading screen starts, it will re-download everything
        trace('GitHub mod cache cleared. Next loading screen will re-download all mods.');
    }

    /**
     * Gets GitHub mod download status for debugging
     */
    public static function getGitHubModStatus():String
    {
        var stats = GitHubDownloadManager.getDownloadStats();
        var isDownloaded = GitHubDownloadManager.areGitHubModsDownloaded();
        var isDownloading = GitHubDownloadManager.isDownloading;

        var status = "GitHub Mod Status:\n";
        status += '  Downloaded: ${isDownloaded ? "Yes" : "No"}\n';
        status += '  Currently Downloading: ${isDownloading ? "Yes" : "No"}\n';
        status += '  Total Mods: ${stats.totalMods}\n';
        status += '  Total Files: ${stats.totalFiles}\n';
        status += '  Download Size: ${Math.round(stats.downloadSizeMB * 100) / 100} MB\n';

        if (isDownloading) {
            status += '  Progress: ${Math.round(GitHubDownloadManager.downloadProgress * 100)}%\n';
            status += '  Status: ${GitHubDownloadManager.downloadStatus}\n';
        }

        return status;
    }

    /**
     * Test function to verify GitHub integration is working
     * Call this from console/debug menu to test your setup
     */
    public static function testGitHubIntegration():Void
    {
        trace('Testing GitHub integration...');

        var enabledMods = GitHubAPI.getEnabledGitHubMods();
        var enabledFolders = GitHubAPI.getEnabledGitHubModsFolders();

        if (enabledMods.length == 0 && enabledFolders.length == 0) {
            trace('No GitHub mods configured! Add some in GitHubInit.initializeGitHubMods()');
            return;
        }

        trace('Configured GitHub mods:');
        for (mod in enabledMods) {
            trace('  Testing mod: ${mod.name}');
            var testPath = 'github://${mod.name}/meta.json'; // Common mod file
            var content = GitHubAPI.getGitHubFile(testPath);
            if (content != null) {
                trace('    ✓ Successfully loaded file: ${testPath.substring(0, Std.int(Math.min(testPath.length, 50)))}...');
            } else {
                trace('    ✗ Could not load file: ${testPath}');
            }
        }

        for (folder in enabledFolders) {
            trace('  Testing mod folder: ${folder.name}');
            for (modName in folder.discoveredMods) {
                if (folder.enabledMods.get(modName) == true) {
                    var testPath = 'github://folder-${folder.name}/${modName}/meta.json';
                    var content = GitHubAPI.getGitHubFile(testPath);
                    if (content != null) {
                        trace('    ✓ Successfully loaded from ${modName}: ${testPath.substring(0, Std.int(Math.min(testPath.length, 50)))}...');
                    } else {
                        trace('    ✗ Could not load from ${modName}: ${testPath}');
                    }
                }
            }
        }

        trace(getGitHubModStatus());
        trace('GitHub integration test complete!');
    }
}
