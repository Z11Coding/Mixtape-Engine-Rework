# High Quality Trap System Documentation

## Overview

The High Quality Trap is a sophisticated music replacement system integrated into Mixtape Engine's Archipelago randomizer mode. The name is a humorous reference to SiivaGunner's "High Quality Video Game Rips" - a popular YouTube channel known for making parody/remix versions of video game music.

## System Purpose

When players receive the "High Quality Trap" item in Archipelago mode, the engine temporarily replaces the original game music with SiivaGunner-style remixes and parodies downloaded from a dedicated repository. This creates an unexpected and entertaining experience where familiar songs become humorous remixes.

## Technical Architecture

### Core Components

1. **HighQualityTrapManager** (`source/archipelago/HighQualityTrapManager.hx`)
   - Main system manager
   - Handles downloading, activation, and song replacement logic
   - Manages temporary file system operations

2. **TrapLinkFunctions** (`source/archipelago/TrapLinkFunctions.hx`)
   - Integration point for trap activation
   - Provides `doHighQualityTrap()` and `stopHighQualityTrap()` functions

3. **APItem Integration** (`source/archipelago/APItem.hx`)
   - Handles trap triggering from Archipelago items
   - Manages queued trap execution

4. **Waiting States**
   - `HighQualityTrapWaitingState`: Shows download progress
   - `HighQualityWaitingState`: AP-specific waiting state

### Key Configuration

```haxe
// Repository containing SiivaGunner content
public static final SIIVA_REPO:String = "Yuta12342/Mixtape-Engine-SiivaGunner-Packs";

// Temporary download location
public static final TEMP_SIIVA_FOLDER:String = "./temp_siivagunner_mods";

// Base game content marker
public static final BASE_GAME_MARKER:String = "__mixtape__";
```

## System Workflow

### 1. Trap Activation

When a player receives the High Quality Trap item:

1. **Download Phase**: System downloads the SiivaGunner repository to `./temp_siivagunner_mods/`
2. **Content Scanning**: Scans downloaded content for:
   - Week files (`weeks/*.json`)
   - Song directories (`songs/*/`)
   - Chart files (`data/*/`)
3. **Mapping Creation**: Creates song replacement mappings
4. **Activation**: Marks trap as ready for use

### 2. Download Process

```haxe
// Uses GitHub API with authentication
GitHubAPI.cloneRepository(SIIVA_REPO, TEMP_SIIVA_FOLDER, null,
    progressCallback,    // File progress updates
    individualProgress,  // Single file progress
    successCallback,     // Download completion
    errorCallback       // Error handling
);
```

### 3. Content Structure

The downloaded repository follows standard Mixtape Engine mod structure:

```
temp_siivagunner_mods/
├── __mixtape__/              # Base game replacements
│   ├── weeks/               # Week definitions
│   ├── songs/              # Audio files
│   └── data/               # Chart files
├── ModName1/               # Mod-specific replacements
│   ├── weeks/
│   ├── songs/
│   └── data/
└── ModName2/
    ├── weeks/
    ├── songs/
    └── data/
```

### 4. Song Replacement Logic

The system uses a hierarchical matching system:

1. **Exact Match**: `modName:songName`
2. **Song-Only Match**: `songName` (for vanilla songs)
3. **Base Game Match**: `__mixtape__:songName`

```haxe
public static function getReplacementSong(originalSong:String, ?modName:String):String {
    if (!isActive || !isUsing) return originalSong;

    // Try exact match first
    var key = modName + ":" + originalSong;
    if (songReplacements.exists(key)) {
        return songReplacements.get(key).replacementSong;
    }

    // Fall back to song-only match
    if (songReplacements.exists(originalSong)) {
        return songReplacements.get(originalSong).replacementSong;
    }

    // Try base game marker
    var baseGameKey = BASE_GAME_MARKER + ":" + originalSong;
    if (songReplacements.exists(baseGameKey)) {
        return songReplacements.get(baseGameKey).replacementSong;
    }

    return originalSong; // No replacement found
}
```

## State Management

### Trap States

The system maintains multiple states for proper operation:

- **isInitialized**: System has been set up
- **isActive**: Trap is downloaded and ready
- **isUsing**: Trap is actively replacing songs
- **isDownloaded**: Content has been downloaded
- **isDownloading**: Download is in progress

### Lifecycle Management

```haxe
// Activation (downloads if needed)
HighQualityTrapManager.activateTrap();

// Start using (enables song replacement)
HighQualityTrapManager.startUsingTrap();

// Stop using (disables replacement but keeps data)
HighQualityTrapManager.stopUsingTrap();

// Deactivation (optionally cleans up files)
HighQualityTrapManager.deactivateTrap(cleanup: true);
```

## Integration Points

### 1. Paths System Integration

The system integrates with `backend.Paths.hx` for automatic file path redirection:

```haxe
// In Paths.hx
if (HighQualityTrapManager.isTrapInUse()) {
    // Check for SiivaGunner replacement files
    var siivaFile:String = HighQualityTrapManager.getTempPath() + '/' +
                          Mods.currentModDirectory + '/' + key;
    var result = checkForRandomFileInFolder(siivaFile);
    if (result != null) return result;
}
```

### 2. Freeplay Integration

The trap works seamlessly with the freeplay system:

- Filters available songs to only show compatible content
- Provides random SiivaGunner songs when no normal songs are available
- Maintains difficulty information from week files

### 3. PlayState Integration

When active during gameplay:

- Songs are replaced transparently
- Audio files (Inst.ogg, Voices.ogg) are redirected
- Chart files are replaced with SiivaGunner versions
- State can be reset to apply changes mid-song

## Data Structures

### SiivaReplacementData

```haxe
typedef SiivaReplacementData = {
    var originalSong:String;      // Original song name
    var replacementSong:String;   // SiivaGunner replacement
    var modName:String;          // Source mod name
    var weekName:String;         // Week containing the song
}
```

### SiivaWeekData

```haxe
typedef SiivaWeekData = {
    var weekName:String;                    // Week identifier
    var songs:Array<SiivaReplacementData>;  // Songs in this week
    var modName:String;                     // Owning mod
    var availableDifficulties:Array<String>; // Available difficulties
}
```

## Content Discovery

### Week File Processing

The system processes week files similar to the main engine:

1. **Parse JSON**: Load week definition files
2. **Extract Songs**: Get song list from week data
3. **Parse Difficulties**: Extract difficulty string and parse into array
4. **Validate Assets**: Ensure audio and chart files exist

### Fallback Handling

For songs without week files:

1. **Orphaned Songs**: Created in "orphaned-songs" week
2. **Default Difficulties**: Easy, Normal, Hard
3. **Asset Validation**: Still requires Inst.ogg and chart files

## Memory and Performance

### Temporary File Management

- Files are downloaded to temporary directory
- Automatic cleanup on AP session end
- Manual cleanup on engine exit
- Safe deletion with recursive directory removal

### Memory Efficiency

- Song mappings stored in Maps for O(1) lookup
- Lazy loading of content only when needed
- Progress tracking during download
- Background download doesn't block gameplay

## API Reference

### Public Methods

#### Core Control
```haxe
// Initialize the system
HighQualityTrapManager.initialize():Void

// Activate trap (download if needed)
HighQualityTrapManager.activateTrap():Void

// Start using trap (enable replacements)
HighQualityTrapManager.startUsingTrap():Void

// Stop using trap (disable replacements)
HighQualityTrapManager.stopUsingTrap():Void

// Deactivate trap (optionally cleanup)
HighQualityTrapManager.deactivateTrap(?cleanup:Bool = false):Void
```

#### State Queries
```haxe
// Check if trap is active
HighQualityTrapManager.isTrapActive():Bool

// Check if trap is being used
HighQualityTrapManager.isTrapInUse():Bool

// Check if download is needed
HighQualityTrapManager.needsWaitingState():Bool

// Get download progress
HighQualityTrapManager.getDownloadProgress():Float
```

#### Song Information
```haxe
// Get replacement song
HighQualityTrapManager.getReplacementSong(originalSong:String, ?modName:String):String

// Check if replacement exists
HighQualityTrapManager.hasReplacement(originalSong:String, ?modName:String):Bool

// Get available difficulties
HighQualityTrapManager.getAvailableDifficulties(songName:String, ?modName:String):Array<String>

// Get week for song
HighQualityTrapManager.getWeekForSong(songName:String, ?modName:String):String
```

## User Experience

### Visual Feedback

1. **Download Phase**: Custom waiting state with progress indication
2. **Silent Activation**: No popup notifications (trap is "hidden")
3. **Seamless Integration**: Songs change without user awareness
4. **Error Handling**: Graceful fallback to original content

### Performance Characteristics

- **First Activation**: May take several minutes for initial download
- **Subsequent Uses**: Instant activation using cached content
- **Network Requirements**: Requires internet connection for initial download
- **Storage**: Temporary files cleaned up automatically

## Debugging and Development

### Status Information

```haxe
// Get comprehensive status
var status = HighQualityTrapManager.getStatusInfo();
trace(status);
```

Output includes:
- Active/initialized state
- Available mods and songs
- Song replacement mappings
- Week information
- Difficulty data

### Testing Commands

Via Main.CommandPrompt:
```
testTrapLink highqualitytrap    # Test trap activation
sizeState                       # Check memory usage
stateInfo                       # Current state details
```

### Common Issues

1. **Download Failures**: Check internet connection and GitHub API access
2. **Missing Content**: Ensure repository structure follows mod standards
3. **Audio Issues**: Verify Inst.ogg and Voices.ogg files exist
4. **Chart Problems**: Ensure matching JSON files in data/ folder

## Security Considerations

### GitHub API Authentication

- Uses hardcoded GitHub token for repository access
- Token has limited scope for public repository cloning
- Download restricted to specific repository only

### File System Safety

- Downloads only to designated temporary directory
- Automatic cleanup prevents file accumulation
- Safe recursive directory deletion
- No modification of user's actual mod directories

## Future Enhancements

### Potential Improvements

1. **Dynamic Content**: Support for runtime content updates
2. **User Preferences**: Allow user selection of SiivaGunner content
3. **Caching**: Persistent cache between engine sessions
4. **Compression**: Reduce download size with asset compression
5. **Streaming**: Stream audio instead of full download

### Integration Opportunities

1. **Custom AP Logic**: HScript integration for mod-specific SiivaGunner content
2. **Dynamic Songs**: Integration with Dynamic Song System
3. **Video Support**: SiivaGunner video backgrounds
4. **Achievement System**: Achievements for discovering SiivaGunner content

## Conclusion

The High Quality Trap system represents a sophisticated integration of external content with the Archipelago randomizer system. By leveraging GitHub repository downloads and seamless mod system integration, it provides a transparent and entertaining experience that exemplifies the engine's commitment to mod compatibility and user experience innovation.

The system's design prioritizes performance, user experience, and technical robustness while maintaining the humorous spirit of the SiivaGunner community. Its implementation serves as a model for future external content integration features in the Mixtape Engine ecosystem.
