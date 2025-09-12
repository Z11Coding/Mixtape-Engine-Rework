package examples;

import backend.GitHubAPI;
import flixel.FlxG;
import states.DownloadState;
import states.MainMenuState;

/**
 * Example usage of the DownloadState for GitHub mod downloading
 */
class GitHubDownloadExample
{
    /**
     * Example: Download all configured GitHub mods before going to main menu
     */
    public static function downloadAllGitHubMods():Void
    {
        // This will download all mods configured via GitHubAPI.addGitHubMod() and GitHubAPI.addGitHubModsFolder()
        var downloadState = DownloadState.downloadAllConfiguredGitHubMods(new MainMenuState());
        FlxG.switchState(downloadState);
    }

    /**
     * Example: Download specific GitHub repositories
     */
    public static function downloadSpecificMods():Void
    {
        var repos = [
            {owner: "Z11Coding", repo: "Mixtape-Engine", isFolder: false},
            {owner: "SomeUser", repo: "FNF-ModPack", isFolder: true}
        ];

        var downloadState = DownloadState.downloadMultipleGitHub(repos, new MainMenuState());
        FlxG.switchState(downloadState);
    }

    /**
     * Example: Download a single GitHub mod
     */
    public static function downloadSingleMod():Void
    {
        var downloadState = DownloadState.downloadGitHubMod("Z11Coding", "Mixtape-Engine", new MainMenuState());
        FlxG.switchState(downloadState);
    }

    /**
     * Example: Download external files only (non-GitHub)
     */
    public static function downloadExternalFiles():Void
    {
        var downloads:Array<DownloadState.DownloadItem> = [
            {
                type: EXTERNAL_URL,
                url: "https://www.soundjay.com/misc/sounds/bell-ringing-05.wav",
                description: "Downloading sound effect...",
                destination: "sounds/bell.wav"
            },
            {
                type: EXTERNAL_URL,
                url: "https://picsum.photos/800/600",
                description: "Downloading random image...",
                destination: "images/random.jpg"
            },
            {
                type: EXTERNAL_URL,
                url: "https://httpbin.org/json",
                description: "Downloading test JSON...",
                destination: "data/test.json"
            }
        ];

        var downloadState = DownloadState.downloadCustomQueue(downloads, new MainMenuState());
        FlxG.switchState(downloadState);
    }

    /**
     * Example: Custom download queue with mixed sources
     */
    public static function downloadCustomMixed():Void
    {
        var downloads:Array<DownloadState.DownloadItem> = [
            {
                type: GITHUB_MOD,
                url: "https://github.com/Z11Coding/Mixtape-Engine",
                description: "Downloading Mixtape Engine core..."
            },
            {
                type: GITHUB_FOLDER,
                url: "https://github.com/SomeUser/FNF-ModPack",
                description: "Downloading FNF Mod Pack..."
            },
            {
                type: EXTERNAL_URL,
                url: "https://example.com/custom-assets.zip",
                description: "Downloading custom assets...",
                destination: "custom-assets.zip"
            },
            {
                type: EXTERNAL_URL,
                url: "https://api.github.com/repos/user/repo/releases/latest",
                description: "Downloading latest release...",
                destination: "releases/latest.json",
                metadata: {
                    headers: {
                        "Accept": "application/vnd.github.v3+json",
                        "Authorization": "Bearer your_token_here"
                    }
                }
            },
            {
                type: CUSTOM,
                url: "https://custom-api.example.com/data",
                description: "Downloading custom data...",
                metadata: {
                    downloadUrl: "https://actual-download-url.com/file.dat",
                    headers: {
                        "API-Key": "your_api_key_here"
                    }
                }
            }
        ];

        var downloadState = DownloadState.downloadCustomQueue(downloads, new MainMenuState());
        FlxG.switchState(downloadState);
    }    /**
     * Example: Setup GitHub mods and then download them
     */
    public static function setupAndDownloadGitHubMods():Void
    {
        // Configure GitHub mods first
        GitHubAPI.addGitHubMod("mixtape-core", "Z11Coding/Mixtape-Engine", "main", "", 0);
        GitHubAPI.addGitHubModsFolder("community-mods", "FridayNightFunkin/Community-Mods", "main", "", 1);

        // Enable specific mods in the folder
        GitHubAPI.setGitHubFolderModEnabled("community-mods", "week8", true);
        GitHubAPI.setGitHubFolderModEnabled("community-mods", "bonus-week", true);
        GitHubAPI.setGitHubFolderModEnabled("community-mods", "old-mod", false);

        // Now download everything
        downloadAllGitHubMods();
    }

    /**
     * Example: Advanced external downloads with authentication and custom headers
     */
    public static function downloadAdvancedExternal():Void
    {
        var downloads:Array<DownloadState.DownloadItem> = [
            // Simple file download
            {
                type: EXTERNAL_URL,
                url: "https://example.com/public-file.zip",
                description: "Downloading public asset...",
                destination: "assets/public-file.zip"
            },

            // API download with authentication
            {
                type: EXTERNAL_URL,
                url: "https://api.example.com/protected/data.json",
                description: "Downloading protected API data...",
                destination: "data/api-data.json",
                metadata: {
                    headers: {
                        "Authorization": "Bearer your_api_token_here",
                        "Accept": "application/json",
                        "User-Agent": "Mixtape-Engine-Bot/1.0"
                    }
                }
            },

            // Custom download with redirect handling
            {
                type: CUSTOM,
                url: "https://redirect-service.example.com/file",
                description: "Downloading with custom logic...",
                metadata: {
                    downloadUrl: "https://actual-cdn.example.com/final-file.dat",
                    headers: {
                        "X-API-Key": "custom_key_here",
                        "Content-Type": "application/octet-stream"
                    }
                }
            }
        ];

        var downloadState = DownloadState.downloadCustomQueue(downloads, new MainMenuState());
        FlxG.switchState(downloadState);
    }
}
