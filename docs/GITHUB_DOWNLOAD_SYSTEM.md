# GitHub Mod Download System

This system allows you to download GitHub mod content upfront to solve performance issues with real-time GitHub API requests.

## Overview

The system consists of two main components:

1. **DownloadState**: A loading screen state that handles downloading content with progress feedback
2. **GitHubDownloadManager**: Backend system that downloads and caches GitHub content locally

## Basic Usage

### Download All Configured GitHub Mods

```haxe
// Simply download everything that's been configured
var downloadState = DownloadState.downloadAllConfiguredGitHubMods(new MainMenuState());
FlxG.switchState(downloadState);
```

### Download Specific GitHub Repository

```haxe
// Download a single mod repository
var downloadState = DownloadState.downloadGitHubMod("Z11Coding", "Mixtape-Engine", new MainMenuState());
FlxG.switchState(downloadState);
```

### Download Multiple Repositories

```haxe
var repos = [
    {owner: "Z11Coding", repo: "Mixtape-Engine", isFolder: false},
    {owner: "SomeUser", repo: "FNF-ModPack", isFolder: true}
];

var downloadState = DownloadState.downloadMultipleGitHub(repos, new MainMenuState());
FlxG.switchState(downloadState);
```

## Setting Up GitHub Mods

Before downloading, configure your GitHub mods:

```haxe
// Add individual mods
GitHubAPI.addGitHubMod("mixtape-core", "Z11Coding/Mixtape-Engine", "main", "", 0);

// Add mod folders (repositories containing multiple mods)
GitHubAPI.addGitHubModsFolder("community-mods", "FridayNightFunkin/Community-Mods", "main", "", 1);

// Control individual mods within folders
GitHubAPI.setGitHubFolderModEnabled("community-mods", "week8", true);
GitHubAPI.setGitHubFolderModEnabled("community-mods", "bonus-week", true);
GitHubAPI.setGitHubFolderModEnabled("community-mods", "old-mod", false);
```

## DownloadState Arguments

The DownloadState constructor accepts:

- `downloads`: Array of download items
- `targetState`: State to go to after downloading (optional)
- `previousState`: Previous state to return to (optional, used as fallback for targetState)

If no target state is specified, it defaults to the previous state or MainMenuState.

## Download Types

- `GITHUB_MOD`: Single GitHub repository as a mod
- `GITHUB_FOLDER`: GitHub repository containing multiple mods
- `EXTERNAL_URL`: External download URL (placeholder for future expansion)
- `CUSTOM`: Custom download logic (placeholder for future expansion)

## Features

- **Progress Feedback**: Shows download progress and current file being downloaded
- **Offline Access**: Downloaded content is cached locally for offline use
- **Smart Caching**: Checks if content is already downloaded before re-downloading
- **Cancellation**: Press ESC to cancel download and proceed to target state
- **Error Handling**: Continues downloading other files if individual files fail

## Integration with Engine Startup

You can integrate GitHub mod downloading into your engine startup:

```haxe
// In Main.hx or your initialization code
public static function initializeGitHubMods():Void
{
    // Check if GitHub mods are already downloaded
    if (GitHubDownloadManager.areGitHubModsDownloaded()) {
        trace('GitHub mods already available offline');
        return;
    }

    // Download if needed
    var downloadState = DownloadState.downloadAllConfiguredGitHubMods();
    FlxG.switchState(downloadState);
}
```

## File Structure

Downloaded GitHub content is stored in:
- `github_mods/[mod-name]/` - Individual GitHub mods
- `github_mods/folder-[folder-name]/` - GitHub mod folders

The GitHubAPI will automatically check offline content first before making online requests, significantly improving performance.

## Example Full Setup

```haxe
import states.DownloadState;
import backend.GitHubAPI;

// Configure your GitHub mods
GitHubAPI.addGitHubMod("mixtape-core", "Z11Coding/Mixtape-Engine", "main", "", 0);
GitHubAPI.addGitHubModsFolder("community-mods", "FridayNightFunkin/Community-Mods", "main", "", 1);

// Enable specific mods
GitHubAPI.setGitHubFolderModEnabled("community-mods", "week8", true);
GitHubAPI.setGitHubFolderModEnabled("community-mods", "bonus-week", true);

// Download everything
var downloadState = DownloadState.downloadAllConfiguredGitHubMods(new MainMenuState());
FlxG.switchState(downloadState);
```

This will download all configured mods with a nice loading screen, then proceed to the main menu once complete.
