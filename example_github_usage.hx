// Example of how to use GitHub integration in Mixtape Engine
// This script demonstrates how to set up GitHub repositories as virtual mod folders
// and also how to use entire repositories as "mods folders" containing multiple mods

import backend.GitHubAPI;
import backend.Paths;

class GitHubIntegrationExample {

    public static function setupGitHubMods():Void {
        // Method 1: Add individual GitHub repositories as single mods
        GitHubAPI.addGitHubMod(
            "example-mod",           // Virtual mod name
            "username/my-fnf-mod",   // GitHub repository (owner/repo)
            "main",                  // Branch (optional, defaults to "main")
            "",                      // Token (optional, for private repos)
            0                        // Priority (lower = higher priority)
        );

        // Method 2: Add a GitHub repository as an entire "mods folder" containing multiple mods
        // This is useful when you have a repository structured like:
        // repo/
        // ├── mod1/
        // │   ├── images/
        // │   ├── sounds/
        // │   └── data/
        // ├── mod2/
        // │   ├── images/
        // │   └── sounds/
        // └── mod3/
        //     └── data/
        GitHubAPI.addGitHubModsFolder(
            "community-mods",        // Virtual mods folder name
            "username/fnf-mods-collection", // Repository containing multiple mods
            "main",                  // Branch
            "",                      // Token (optional)
            5                        // Priority (checked after individual mods)
        );

        // Add another individual mod with lower priority
        GitHubAPI.addGitHubMod(
            "backup-assets",
            "username/backup-assets",
            "stable",
            "",
            10  // Lower priority than both above
        );

        // Add a private mods folder with authentication
        GitHubAPI.addGitHubModsFolder(
            "premium-mods",
            "username/premium-mods-pack",
            "main",
            "your_github_token_here",  // GitHub personal access token
            3
        );

        trace("GitHub mods and mods folders configured!");
    }

    public static function testAssetLoading():Void {
        // These will now automatically check GitHub sources in this order:
        // 1. Individual GitHub mods (by priority)
        // 2. GitHub mods folders (by priority, checking all mods in each folder)
        // 3. Local mods
        // 4. Base assets

        // Load an image - works exactly like normal Paths.image()
        var character = Paths.image("characters/boyfriend");

        // Load a sound - works exactly like normal Paths.sound()
        var music = Paths.sound("music/gameOverEnd");

        // Load text data - works exactly like normal Paths.getTextFromFile()
        var songData = Paths.getTextFromFile("songs/tutorial/tutorial.json");

        // The engine will automatically check:
        // 1. "example-mod" GitHub repo (priority 0)
        // 2. "premium-mods" GitHub folder, checking all discovered mods (priority 3)
        // 3. "community-mods" GitHub folder, checking all discovered mods (priority 5)
        // 4. "backup-assets" GitHub repo (priority 10)
        // 5. Local mods folder
        // 6. Base assets folder

        trace("Assets loaded from GitHub or local sources!");
    }

    public static function manageGitHubMods():Void {
        // Disable a specific GitHub mod temporarily
        GitHubAPI.setGitHubModEnabled("backup-assets", false);

        // Disable an entire GitHub mods folder
        GitHubAPI.setGitHubModsFolderEnabled("community-mods", false);

        // Remove a GitHub mod completely
        GitHubAPI.removeGitHubMod("example-mod");

        // Remove a GitHub mods folder completely
        GitHubAPI.removeGitHubModsFolder("premium-mods");

        // Get list of enabled GitHub mods
        var enabledMods = GitHubAPI.getEnabledGitHubMods();
        for (mod in enabledMods) {
            trace('Enabled GitHub mod: ${mod.name} (${mod.repository})');
        }

        // Get list of enabled GitHub mods folders
        var enabledFolders = GitHubAPI.getEnabledGitHubModsFolders();
        for (folder in enabledFolders) {
            trace('Enabled GitHub mods folder: ${folder.name} (${folder.repository})');
            trace('  Contains mods: ${folder.discoveredMods.join(", ")}');
        }

        // Get all mod names for debugging
        var allMods = GitHubAPI.getAllGitHubModNames();
        trace('All available GitHub mods: ${allMods.join(", ")}');

        // Rediscover mods in a folder (useful if the repository was updated)
        GitHubAPI.discoverModsInFolder("community-mods");

        // Clear GitHub cache to force re-download
        GitHubAPI.clearCache();
    }

    public static function configureSettings():Void {
        // Configure cache settings
        GitHubAPI.useCache = true;           // Enable caching (recommended)
        GitHubAPI.maxCacheAge = 3600;        // Cache files for 1 hour
        GitHubAPI.cacheDirectory = "github_cache";  // Cache directory name

        trace("GitHub settings configured!");
    }
}

/*
USAGE EXAMPLES:

METHOD 1 - Individual Mod Repositories:
1. Call GitHubAPI.addGitHubMod() for each repository
2. Each repository is treated as a single mod
3. Repository structure should be like a normal mod:
   repo/
   ├── images/
   ├── sounds/
   ├── data/
   └── scripts/

METHOD 2 - Mods Folder Repositories:
1. Call GitHubAPI.addGitHubModsFolder() for the repository
2. Repository contains multiple mod directories
3. Repository structure should be:
   repo/
   ├── mod1/
   │   ├── images/
   │   ├── sounds/
   │   └── data/
   ├── mod2/
   │   ├── images/
   │   └── sounds/
   └── mod3/
       └── data/

GITHUB REPOSITORY STRUCTURE EXAMPLES:

Single Mod Repository (use addGitHubMod):
my-fnf-mod/
├── images/
│   ├── characters/
│   │   └── boyfriend.png
│   └── stages/
│       └── stage.png
├── sounds/
│   ├── music/
│   │   └── gameOverEnd.ogg
│   └── sounds/
│       └── confirmMenu.ogg
├── data/
│   └── songs/
│       └── tutorial/
│           └── tutorial.json
└── scripts/
    └── song.hx

Mods Folder Repository (use addGitHubModsFolder):
fnf-mods-collection/
├── my-mod/
│   ├── images/
│   │   └── characters/
│   │       └── newcharacter.png
│   └── sounds/
│       └── music/
│           └── newsong.ogg
├── another-mod/
│   ├── data/
│   │   └── songs/
│   │       └── anothersong/
│   │           └── anothersong.json
│   └── images/
│       └── stages/
│           └── newstage.png
└── third-mod/
    └── scripts/
        └── special.hx

PRIORITY ORDER:
1. Individual GitHub mods (by priority: 0, 5, 10, etc.)
2. Mods within GitHub mods folders (by folder priority, then by discovery order)
3. Local mods (current mod directory, then global mods)
4. Base game assets

This allows you to:
- Mix individual mod repositories with multi-mod repositories
- Override base game assets with GitHub-hosted versions
- Share large collections of mods through a single repository
- Update assets without releasing a new build
- Use private repositories for exclusive content
- Organize mods in whatever way makes sense for your project
*/
