# High Quality Trap Integration Points

## Overview

This document provides a comprehensive technical reference for all High Quality Trap integration points throughout the Mixtape Engine codebase, detailing how the system integrates with various engine components.

## Core Integration Points

### 1. Song.hx - Primary Song Loading

**File**: `source/backend/Song.hx`
**Integration Type**: Direct replacement during load process

```haxe
// Lines 291-300: Primary replacement logic in loadFromJson()
#if ARCHIPELAGO_ALLOWED
var originalSong = folder;
var replacementSong = HighQualityTrapManager.getReplacementSong(originalSong, backend.Mods.currentModDirectory);
if (replacementSong != originalSong) {
    trace('Song.loadFromJson: High Quality Trap replacing "$originalSong" with "$replacementSong"');
    folder = replacementSong;
    if (Paths.formatToSongPath(jsonInput) == Paths.formatToSongPath(originalSong)) {
        jsonInput = replacementSong;
    }
}
#end
```

**Features**:
- Happens before any other song processing
- Updates both folder path and JSON input name
- Preserves original song name in logs for debugging
- Conditional compilation for Archipelago builds only

### 2. Song Variants System

**File**: `source/backend/Song.hx`
**Function**: `checkForSongVariants()`
**Lines**: 356-418

```haxe
// Variant system only activates during High Quality Trap
if (!HighQualityTrapManager.isTrapInUse()) return null;

// Directory structure: data/songname/variants/variant_name/songname.json
var variantsDir = haxe.io.Path.join([songDataDir, 'variants']);

// Randomization algorithm
for (i in 0...variantFolders.length) {
    var j = FlxG.random.int(0, variantFolders.length - 1);
    var temp = variantFolders[i];
    variantFolders[i] = variantFolders[j];
    variantFolders[j] = temp;
}
```

**Features**:
- Only works when High Quality Trap is active
- Random variant selection each playthrough
- Fisher-Yates shuffle for fair randomization
- Requires exact chart filename matching

### 3. Paths.hx - File System Redirection

**File**: `source/backend/Paths.hx`
**Integration Type**: Transparent file path redirection

```haxe
// Lines 1429-1452: Comprehensive file redirection
if (HighQualityTrapManager.isTrapInUse()) {
    // 1. Try current mod in SiivaGunner temp folder
    if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
        var siivaFile:String = HighQualityTrapManager.getTempPath() + '/' +
                              Mods.currentModDirectory + '/' + key;
        var result = checkForRandomFileInFolder(siivaFile);
        if (result != null) return result;
    }

    // 2. Try all enabled mods
    for (mod in Mods.getGlobalMods()) {
        if (!Mods.enabledMods.contains(mod) && Mods.enabledMods.contains(mod.toLowerCase())) continue;
        var siivaFile:String = HighQualityTrapManager.getTempPath() + '/' + mod + '/' + key;
        var result = checkForRandomFileInFolder(siivaFile);
        if (result != null) return result;
    }

    // 3. Try base game replacement
    var siivaBaseFile:String = HighQualityTrapManager.getTempPath() + '/__mixtape__/' + key;
    var result = checkForRandomFileInFolder(siivaBaseFile);
    if (result != null) return result;
}
```

**Affected File Types**:
- Audio files: `songs/*/Inst.ogg`, `songs/*/Voices.ogg`
- Chart data: `data/*/*.json`
- Graphics: `images/**/*`
- Scripts: `scripts/*.lua`, `scripts/*.hx`
- Week definitions: `weeks/*.json`

## Archipelago-Specific Integrations

### 4. APFreeplayManager.hx - Freeplay System

**File**: `source/managers/APFreeplayManager.hx`
**Integration Points**: Multiple functions with High Quality Trap awareness

#### Difficulty Management (Lines 368-370)
```haxe
if (HighQualityTrapManager.isTrapInUse()) {
    var siivaDiffs = HighQualityTrapManager.getAvailableDifficulties(songName, modName);
    // Use SiivaGunner week data for difficulties instead of file scanning
}
```

#### Song Availability Checking (Lines 383-385)
```haxe
if (HighQualityTrapManager.isTrapInUse()) {
    return HighQualityTrapManager.isDifficultyAvailable(songName, modName, difficulty);
}
```

#### Song Name Processing (Lines 394-396)
```haxe
if (HighQualityTrapManager.isTrapInUse()) {
    return HighQualityTrapManager.getReplacementSong(originalSong, modName);
}
```

#### Song List Filtering (Lines 507-558)
```haxe
if (HighQualityTrapManager.isTrapInUse()) {
    // Filter to only SiivaGunner compatible songs
    var filteredSongs = HighQualityTrapManager.filterUnlockedSongsForSiiva(convertedSongs);

    // Provide random SiivaGunner content as fallback
    if (filteredSongs.length == 0) {
        var randomSiivaSong = HighQualityTrapManager.getRandomSiivaSong();
        if (randomSiivaSong != null) {
            // Add random SiivaGunner song to available list
        }
    }

    // Check mod compatibility
    if (allowedSongs.length > 0 && HighQualityTrapManager.hasSiivaContentForMod(leWeek.folder)) {
        var firstSong = allowedSongs[0];
        var siivaDiffs = HighQualityTrapManager.getAvailableDifficulties(firstSong, leWeek.folder);
    }
}
```

### 5. FreeplayState.hx - UI Integration

**File**: `source/states/freeplay/FreeplayState.hx`
**Integration Points**: UI updates and song selection

#### Song Information Display (Line 1332)
```haxe
if (archipelago.HighQualityTrapManager.isTrapInUse() && fpManager.songList[curSelected] != null) {
    // Update UI to show SiivaGunner song information
    // Display replacement song name and mod information
}
```

#### Song Loading (Line 1556)
```haxe
if (archipelago.HighQualityTrapManager.isTrapInUse()) {
    // Use High Quality Trap song replacement logic
    // Update loading parameters for SiivaGunner content
}
```

### 6. APItem.hx - Trap Activation

**File**: `source/archipelago/APItem.hx`
**Lines**: 310-340

```haxe
case "High Quality Trap":
    return new APItem(name, ConditionHelper.Everywhere(), function() {
        // Check if already active to prevent duplicate downloads
        if (HighQualityTrapManager.isTrapActive()) {
            if (!HighQualityTrapManager.isTrapAlreadyInUse()) {
                archipelago.HighQualityTrapManager.startUsingTrap();
                // Handle PlayState reset if in-game
                if (Std.is(FlxG.state, states.PlayState)) {
                    var playState = states.PlayState.instance;
                    if (playState != null && playState.startedSong) {
                        TrapLinkFunctions.doHighQualityTrap();
                        MusicBeatState.resetState();
                        return;
                    }
                }

                // Handle freeplay integration
                if (!Std.is(FlxG.state, FreeplayManager.getFreeplay())) {
                    // Queue trap for later execution
                    APItem.queuedTrap = new APTrap("High Quality Trap - Queued",
                        ConditionHelper.Everywhere(),
                        function() {
                            archipelago.HighQualityTrapManager.startUsingTrap();
                            TrapLinkFunctions.doHighQualityTrap();
                        }, false, false, false, true);
                    return;
                }

                // Execute immediately in freeplay
                TrapLinkFunctions.doHighQualityTrap();
            }
            return;
        }

        // Start using the trap (activates song replacements)
        archipelago.HighQualityTrapManager.startUsingTrap();
        // Additional logic for state handling...
    }, false, false, false, fromTrapLink);
```

**Features**:
- Duplicate activation prevention
- State-aware execution (PlayState vs Freeplay)
- Queued execution for non-freeplay states
- Automatic state reset when appropriate

## Lifecycle Management

### 7. Initialization Points

#### Main.hx (Line 2111)
```haxe
#if ARCHIPELAGO_ALLOWED
archipelago.HighQualityTrapManager.initialize();
#end
```

#### APGameState.hx (Lines 1633, 3638)
```haxe
// Clean up High Quality Trap temporary files on AP session end
archipelago.HighQualityTrapManager.onAPSessionEnd();
```

#### ExitState.hx (Line 58) & Main.hx (Line 487)
```haxe
// Clean up on engine exit
archipelago.HighQualityTrapManager.onEngineExit();
```

### 8. Debug and Testing Integration

#### Main.hx Command System (Lines 2130-2150)
```haxe
// Command prompt integration for testing
case "deactivateTrap":
    archipelago.HighQualityTrapManager.deactivateTrap();

case "siivaStatus":
    print(archipelago.HighQualityTrapManager.getStatusInfo());

case "testTrapLink":
    if (params.length > 0 && params[0] == "highqualitytrap") {
        if (archipelago.HighQualityTrapManager.needsWaitingState()) {
            // Show waiting state for download
        } else {
            // Test trap activation
        }
    }
```

### 9. Waiting State Integration

#### HighQualityTrapWaitingState.hx
**File**: `source/states/HighQualityTrapWaitingState.hx`

```haxe
// Download monitoring and progress display
override function update(elapsed:Float) {
    super.update(elapsed);

    if (!HighQualityTrapManager.isTrapActive()) {
        statusText.text = "Download failed - returning to previous state";
        return;
    }

    if (!HighQualityTrapManager.needsWaitingState()) {
        // Download complete - transition to appropriate state
        HighQualityTrapManager.startUsingTrap();
        FlxG.switchState(returnState);
        return;
    }

    // Update progress display
    var progress = HighQualityTrapManager.getDownloadProgress();
    progressText.text = "Downloading: " + Math.round(progress * 100) + "%";
}
```

#### HighQualityWaitingState.hx (Archipelago-specific)
**File**: `source/archipelago/states/HighQualityWaitingState.hx`

```haxe
// AP-specific waiting state with game context preservation
if (!manager.needsWaitingState()) {
    // Download complete
    HighQualityTrapManager.startUsingTrap();

    // Return to AP game with proper context
    FlxG.switchState(new APGameState(apGame, client));
}
```

## Advanced Integration Features

### 10. Test State Integration

#### HighQualityTrapTestState.hx
**File**: `source/states/HighQualityTrapTestState.hx`

```haxe
// Comprehensive testing interface for High Quality Trap
if (!HighQualityTrapManager.isTrapActive()) {
    statusText = "HIGH QUALITY TRAP NOT ACTIVE";
    return;
}

var replacements = HighQualityTrapManager.getAllReplacements();
// Display all available replacements with mod/week information

// Test song loading with High Quality content
if (songs[curSelected].folder != null &&
    songs[curSelected].folder != HighQualityTrapManager.BASE_GAME_MARKER) {
    backend.Mods.loadTopMod(songs[curSelected].folder);
}

// Test difficulty filtering
var difficulties = HighQualityTrapManager.getWeekDifficulties(replacement.weekName, replacement.modName);
```

### 11. TrapLinkFunctions Integration

#### TrapLinkFunctions.hx (Lines 203-239)
```haxe
public static function doHighQualityTrap():Void {
    trace("TrapLinkFunctions: Activating High Quality Trap!");

    // Initialize and activate the trap manager
    HighQualityTrapManager.activateTrap();

    // Check if we need to show waiting state
    if (HighQualityTrapManager.needsWaitingState()) {
        // Get AP context and switch to appropriate waiting state
        if (APInfo.apGame != null && APInfo.ap != null) {
            flixel.FlxG.switchState(new archipelago.states.HighQualityWaitingState(APInfo.apGame, APInfo.ap));
        } else {
            flixel.FlxG.switchState(new states.HighQualityTrapWaitingState());
        }
        return;
    }

    // Trap is ready - silent activation
    trace("TrapLinkFunctions: High Quality Trap is ready and active!");
}

public static function stopHighQualityTrap():Void {
    trace("TrapLinkFunctions: Stopping High Quality Trap!");
    HighQualityTrapManager.stopUsingTrap();
    trace("TrapLinkFunctions: High Quality Trap stopped successfully!");
}
```

## Performance and Memory Considerations

### Memory Management Integration

1. **Automatic Cleanup**: Integrated with AP session lifecycle
2. **Lazy Loading**: Files loaded only when requested
3. **Path Caching**: Efficient file system access
4. **Resource Pooling**: Reuses downloaded content across sessions

### File System Optimization

1. **Hierarchical Lookup**: Checks current mod → all mods → base game
2. **Early Exit**: Returns immediately on first match
3. **Existence Checks**: Validates files before attempting load
4. **Error Handling**: Graceful fallbacks on file access failures

## Security and Validation

### Input Validation

1. **Path Sanitization**: Prevents directory traversal attacks
2. **File Type Validation**: Ensures only expected file types
3. **Mod Name Validation**: Validates mod directory names
4. **JSON Parsing**: Safe parsing with error handling

### Access Control

1. **Conditional Compilation**: Only available in Archipelago builds
2. **State Validation**: Ensures proper activation sequence
3. **Permission Checks**: Validates file system permissions
4. **Network Security**: GitHub API token management

## Integration Testing Strategy

### Unit Test Coverage

1. **Song Loading**: Test all song loading paths with trap active/inactive
2. **File Redirection**: Verify correct path resolution
3. **Variant Selection**: Test randomization and fallback logic
4. **State Transitions**: Validate proper state management

### Integration Test Scenarios

1. **Normal → Trapped**: Activate trap mid-session
2. **Trapped → Normal**: Deactivate and verify cleanup
3. **Mixed Content**: Normal mods + SiivaGunner content
4. **Network Failures**: Handle download interruptions
5. **File Corruption**: Handle invalid SiivaGunner content

This comprehensive integration documentation provides the complete technical picture of how the High Quality Trap system integrates throughout the Mixtape Engine codebase, ensuring maintainers and developers can understand the full scope of the system's impact and interactions.
