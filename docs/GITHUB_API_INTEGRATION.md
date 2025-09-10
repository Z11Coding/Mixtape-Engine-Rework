# GitHub API Integration for Mixtape Engine

## Overview

The GitHub API integration allows Mixtape Engine to load assets directly from GitHub repositories, treating them as virtual mod folders. This enables dynamic asset loading, easy content sharing, and simplified mod distribution.

The system supports two types of GitHub integration:
1. **Individual Mod Repositories**: Each repository is treated as a single mod
2. **Mods Folder Repositories**: Repositories containing multiple mod directories

## Features

- **Virtual Mod Folders**: GitHub repositories act like local mod directories
- **Priority System**: Configure loading order for multiple GitHub sources
- **Caching**: Local file caching with configurable expiration
- **Authentication**: Support for private repositories via GitHub tokens
- **Seamless Integration**: Works with existing Paths system
- **Multi-Repository Support**: Load from multiple GitHub sources
- **Two Repository Types**: Individual mods or collections of mods
- **Automatic Discovery**: Automatic detection of mods in folder-type repositories

## Quick Start

### Method 1: Individual Mod Repository

```haxe
import backend.GitHubAPI;

// Add a GitHub repository as a single mod
GitHubAPI.addGitHubMod(
    "my-mod",                    // Virtual mod name
    "username/my-fnf-mod",       // GitHub repository
    "main",                      // Branch (optional)
    "",                          // Auth token (optional)
    0                           // Priority (0 = highest)
);

// Now use normal Paths functions - they'll check GitHub first
var sprite = Paths.image("characters/boyfriend");
```

### Method 2: Mods Folder Repository

```haxe
import backend.GitHubAPI;

// Add a repository containing multiple mods
GitHubAPI.addGitHubModsFolder(
    "community-pack",            // Virtual folder name
    "username/mods-collection",  // Repository with multiple mods
    "main",                      // Branch (optional)
    "",                          // Auth token (optional)
    5                           // Priority
);

// The system will discover all mod directories automatically
// Access assets using: github://community-pack/mod-name/path
```

## Repository Structure

### Individual Mod Repository Structure
```
my-fnf-mod/
├── images/
│   ├── characters/
│   │   ├── boyfriend.png
│   │   └── girlfriend.png
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
```

### Mods Folder Repository Structure
```
mods-collection/
├── awesome-mod/
│   ├── images/
│   │   └── characters/
│   │       └── newcharacter.png
│   ├── sounds/
│   │   └── music/
│   │       └── newsong.ogg
│   └── data/
│       └── songs/
│           └── newsong/
│               └── newsong.json
├── another-mod/
│   ├── images/
│   │   └── stages/
│   │       └── coolstage.png
│   └── scripts/
│       └── stage.hx
└── third-mod/
    ├── data/
    │   └── characters/
    │       └── newcharacter.json
    └── images/
        └── characters/
            └── newcharacter.png
```

## API Reference

### GitHubAPI Class

#### Static Properties
- `useCache: Bool` - Enable/disable file caching (default: true)
- `maxCacheAge: Int` - Cache expiration time in seconds (default: 3600)
- `cacheDirectory: String` - Cache directory name (default: "github_cache")

#### Individual Mod Methods

##### `addGitHubMod(name: String, repository: String, branch: String = "main", token: String = "", priority: Int = 0): Void`
Add a GitHub repository as a virtual mod.

**Parameters:**
- `name`: Virtual mod name for referencing
- `repository`: GitHub repository in "owner/repo" format
- `branch`: Git branch to use (default: "main")
- `token`: GitHub personal access token for private repos
- `priority`: Loading priority (lower = higher priority)

##### `removeGitHubMod(name: String): Void`
Remove a GitHub mod from the system.

##### `setGitHubModEnabled(name: String, enabled: Bool): Void`
Enable or disable a specific GitHub mod.

##### `getEnabledGitHubMods(): Array<GitHubMod>`
Get list of enabled GitHub mods.

#### Mods Folder Methods

##### `addGitHubModsFolder(name: String, repository: String, branch: String = "main", token: String = "", priority: Int = 0): Void`
Add a GitHub repository as a mods folder containing multiple mods.

**Parameters:**
- `name`: Virtual folder name for referencing
- `repository`: GitHub repository in "owner/repo" format
- `branch`: Git branch to use (default: "main")
- `token`: GitHub personal access token for private repos
- `priority`: Loading priority (lower = higher priority)

##### `removeGitHubModsFolder(name: String): Void`
Remove a GitHub mods folder from the system.

##### `setGitHubModsFolderEnabled(name: String, enabled: Bool): Void`
Enable or disable a specific GitHub mods folder.

##### `getEnabledGitHubModsFolders(): Array<GitHubModsFolder>`
Get list of enabled GitHub mods folders.

##### `discoverModsInFolder(folderName: String): Void`
Rediscover mods in a GitHub mods folder (useful after repository updates).

#### Utility Methods

##### `getAllGitHubModNames(): Array<String>`
Get names of all available GitHub mods (from both individual and folder sources).

##### `clearCache(): Void`
Clear the GitHub file cache, forcing fresh downloads.

##### `githubModFolders(): Array<String>`
Get list of all GitHub mod folder names for internal path resolution.

##### `getGitHubFile(path: String): String`
Internal method for downloading text files from GitHub.

##### `getGitHubBinary(path: String): Bytes`
Internal method for downloading binary files from GitHub.

## Usage Examples

### Basic Setup
```haxe
import backend.GitHubAPI;

class MyGame {
    static function main() {
        // Configure GitHub integration
        GitHubAPI.useCache = true;
        GitHubAPI.maxCacheAge = 1800; // 30 minutes

        // Add individual mod
        GitHubAPI.addGitHubMod("base-assets", "username/base-assets", "main", "", 10);

        // Add mods folder
        GitHubAPI.addGitHubModsFolder("community", "username/community-mods", "main", "", 5);

        // Now use normal asset loading
        var character = Paths.image("characters/boyfriend");
        var song = Paths.sound("music/gameOverEnd");
    }
}
```

### Advanced Configuration
```haxe
// Multiple GitHub sources with priorities
GitHubAPI.addGitHubMod("priority-mod", "user/priority-mod", "main", "", 0);        // Highest priority
GitHubAPI.addGitHubModsFolder("mid-pack", "user/mid-mods", "main", "", 5);        // Mid priority
GitHubAPI.addGitHubMod("fallback-mod", "user/fallback-mod", "stable", "", 10);    // Lowest priority

// Private repository with authentication
GitHubAPI.addGitHubMod("private-mod", "user/private-mod", "main", "ghp_your_token_here", 3);

// Disable specific sources temporarily
GitHubAPI.setGitHubModEnabled("fallback-mod", false);
GitHubAPI.setGitHubModsFolderEnabled("mid-pack", false);
```

### Loading Priority Order

The system checks sources in this order:
1. **Individual GitHub mods** (by priority: 0, 1, 2, ...)
2. **GitHub mods folders** (by priority, checking all discovered mods)
3. **Local mods** (current mod directory)
4. **Global local mods** (mods folder)
5. **Base game assets**

### Path Resolution Examples

#### Individual Mod Repository
- Repository: `username/my-mod`
- Asset path: `images/characters/boyfriend.png`
- GitHub URL: `https://api.github.com/repos/username/my-mod/contents/images/characters/boyfriend.png`

#### Mods Folder Repository
- Repository: `username/mods-pack`
- Folder name: `community-pack`
- Mod in folder: `awesome-mod`
- Asset path: `images/characters/boyfriend.png`
- Internal path: `github://community-pack/awesome-mod/images/characters/boyfriend.png`
- GitHub URL: `https://api.github.com/repos/username/mods-pack/contents/awesome-mod/images/characters/boyfriend.png`

## Authentication

For private repositories, you need a GitHub Personal Access Token:

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate a new token with "repo" scope
3. Pass the token when adding the mod:

```haxe
GitHubAPI.addGitHubMod("private-mod", "user/private-repo", "main", "ghp_your_token_here", 0);
```

## Caching System

Files are cached locally to improve performance:

- **Cache Location**: `{game_directory}/{cacheDirectory}/`
- **Cache Structure**: `{cacheDirectory}/{mod_name}/{file_path}`
- **Expiration**: Files older than `maxCacheAge` seconds are re-downloaded
- **Management**: Use `GitHubAPI.clearCache()` to force refresh

## Error Handling

The system gracefully handles errors:
- **Network Issues**: Falls back to local assets
- **Missing Files**: Continues to next priority source
- **Invalid Repositories**: Logs warnings and skips
- **Authentication Failures**: Falls back to public access

## Integration with Paths System

The GitHub integration is transparent to existing code:

```haxe
// These work exactly the same, but now check GitHub first
var image = Paths.image("characters/boyfriend");
var sound = Paths.sound("music/gameOverEnd");
var data = Paths.getTextFromFile("data/song.json");
```

## Troubleshooting

### Common Issues

1. **Files not loading from GitHub**
   - Check repository name format: "owner/repo"
   - Verify branch name (case-sensitive)
   - Ensure file paths match exactly

2. **Authentication errors**
   - Verify token has "repo" scope
   - Check token hasn't expired
   - Ensure repository access permissions

3. **Slow loading**
   - Enable caching: `GitHubAPI.useCache = true`
   - Increase cache time: `GitHubAPI.maxCacheAge = 7200`
   - Reduce number of GitHub sources

4. **Mods not discovered in folder**
   - Check repository structure (each mod should be in its own directory)
   - Verify directory names are valid
   - Use `GitHubAPI.discoverModsInFolder()` to refresh

### Debug Information

```haxe
// Check which GitHub sources are active
var mods = GitHubAPI.getEnabledGitHubMods();
for (mod in mods) {
    trace('GitHub mod: ${mod.name} (${mod.repository}:${mod.branch})');
}

var folders = GitHubAPI.getEnabledGitHubModsFolders();
for (folder in folders) {
    trace('GitHub folder: ${folder.name} (${folder.repository}:${folder.branch})');
    trace('  Contains: ${folder.discoveredMods.join(", ")}');
}

// Get all available mod names
var allMods = GitHubAPI.getAllGitHubModNames();
trace('All mods: ${allMods.join(", ")}');
```

## Best Practices

1. **Use Appropriate Repository Types**
   - Individual repositories for single, focused mods
   - Folder repositories for collections or mod packs

2. **Set Meaningful Priorities**
   - Lower numbers = higher priority
   - Leave gaps for future additions (0, 5, 10, 15...)

3. **Enable Caching**
   - Always use caching in production
   - Set reasonable cache times (30min - 2hrs)

4. **Organize Repository Structure**
   - Follow FNF mod conventions
   - Keep file paths consistent
   - Use clear directory names in folder-type repositories

5. **Handle Private Content Carefully**
   - Store tokens securely
   - Don't commit tokens to repositories
   - Consider environment variables for sensitive data

6. **Test Both Repository Types**
   - Verify individual mod loading
   - Test folder-based mod discovery
   - Check priority ordering between types

## Performance Considerations

- **First Load**: Slower due to GitHub API calls
- **Cached Loads**: Fast local file access
- **Multiple Sources**: Checked in priority order (stops at first match)
- **Network Dependency**: Requires internet for uncached files
- **Rate Limits**: GitHub API has rate limits (60 requests/hour without auth, 5000 with auth)

## Security Notes

- Files are downloaded to local cache (potential disk space usage)
- GitHub tokens should be kept secure
- Only download from trusted repositories
- Consider code execution risks with script files
