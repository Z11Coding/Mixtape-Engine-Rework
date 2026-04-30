# Advanced Song Systems & High Quality Trap Integration

## Overview

This document covers the advanced song management systems in Mixtape Engine, focusing on how they integrate with the High Quality Trap system and provide enhanced gameplay experiences in Archipelago mode.

## Song System Architecture

### Core Song Structure (Song.hx)

The foundation of all song systems starts with the `SwagSong` typedef:

```haxe
typedef SwagSong = {
    var song:String;
    var notes:Array<SwagSection>;
    var events:Array<Dynamic>;
    var bpm:Float;
    var needsVoices:Bool;
    var speed:Float;
    var offset:Float;
    var player1:String;
    var player2:String;
    var player4:String;  // Additional players for extended gameplay
    var player5:String;
    var gfVersion:String;
    var stage:String;
    var format:String;
    var mania:Null<Int>;        // Key count system
    var startMania:Null<Int>;   // Starting key count

    // Dynamic song fields
    @:optional var isDynamic:Bool;
    @:optional var sectionSequence:Array<String>;
    @:optional var dynamicAudio:Dynamic; // Contains stitched FlxSound objects
}
```

### High Quality Trap Integration in Song Loading

The High Quality Trap system integrates directly into the song loading process:

```haxe
// In Song.loadFromJson()
#if ARCHIPELAGO_ALLOWED
// Check for High Quality Trap replacement - only if trap is actively being used
var originalSong = folder;
var replacementSong = HighQualityTrapManager.getReplacementSong(originalSong, backend.Mods.currentModDirectory);
if (replacementSong != originalSong) {
    trace('Song.loadFromJson: High Quality Trap replacing "$originalSong" with "$replacementSong"');
    folder = replacementSong;
    // Also update jsonInput if it matches the original song name
    if (Paths.formatToSongPath(jsonInput) == Paths.formatToSongPath(originalSong)) {
        jsonInput = replacementSong;
    }
}
#end
```

This integration happens **before** any other song processing, ensuring that:
- High Quality content takes precedence over all other systems
- Dynamic songs can be replaced with SiivaGunner versions
- Song variants can be applied to SiivaGunner content
- The replacement is transparent to all downstream systems

## Song Variants System

### Purpose and Design

The Song Variants system allows for randomized chart variations when the High Quality Trap is active, providing additional replay value and surprise elements.

### Directory Structure

```
data/songname/
├── songname.json           # Main chart
├── variants/               # Variants folder (only checked during High Quality Trap)
│   ├── hard_version/      # Variant subfolder
│   │   └── songname.json  # Variant chart with same name
│   ├── easy_remix/
│   │   └── songname.json
│   └── chaotic_mode/
│       └── songname.json
└── other_files...
```

### Variant Selection Algorithm

```haxe
private static function checkForSongVariants(folder:String, jsonInput:String) {
    #if ARCHIPELAGO_ALLOWED
    #if MODS_ALLOWED
    if (!HighQualityTrapManager.isTrapInUse()) return null;

    // 1. Locate variants directory
    var songDataPath = Paths.getPath('data/$folder', TEXT, null, true);
    var songDataDir = haxe.io.Path.directory(songDataPath);
    var variantsDir = haxe.io.Path.join([songDataDir, 'variants']);

    if (sys.FileSystem.exists(variantsDir) && sys.FileSystem.isDirectory(variantsDir)) {
        // 2. Collect all variant folders
        var variantFolders:Array<String> = [];
        for (item in sys.FileSystem.readDirectory(variantsDir)) {
            var itemPath = haxe.io.Path.join([variantsDir, item]);
            if (sys.FileSystem.isDirectory(itemPath)) {
                variantFolders.push(item);
            }
        }

        // 3. Randomize order using FlxG.random
        for (i in 0...variantFolders.length) {
            var j = FlxG.random.int(0, variantFolders.length - 1);
            var temp = variantFolders[i];
            variantFolders[i] = variantFolders[j];
            variantFolders[j] = temp;
        }

        // 4. Find first variant with matching chart file
        for (variantName in variantFolders) {
            var variantPath = haxe.io.Path.join([variantsDir, variantName]);
            var variantJsonPath = haxe.io.Path.join([variantPath, '$jsonInput.json']);

            if (sys.FileSystem.exists(variantJsonPath)) {
                return {
                    folderPath: haxe.io.Path.join([folder, 'variants', variantName]),
                    jsonInput: jsonInput,
                    variantName: variantName
                };
            }
        }
    }
    #end
    #end
    return null;
}
```

### Key Features

- **Conditional Activation**: Only works when High Quality Trap is in use
- **Random Selection**: Ensures different variants each playthrough
- **Failsafe Design**: Falls back to original chart if no variants found
- **Name Matching**: Variant charts must have same filename as original
- **Cross-Platform**: Uses appropriate file system APIs

## Dynamic Song System

### Architecture Overview

The Dynamic Song System allows songs to be constructed from multiple interchangeable sections, creating unique experiences each time a song is played.

### Core Data Structures

```haxe
typedef DynamicSongConfig = {
    var format:String; // "mixtape_dynamic_v1"
    var songName:String;
    var sections:Map<String, DynamicSection>;
    var flow:DynamicFlow;
    @:optional var fallback:DynamicFallback;
    @:optional var metadata:DynamicMetadata;
}

typedef DynamicSection = {
    var chartFile:String;
    var audioFiles:DynamicAudioFiles;
    var duration:Float; // Duration in milliseconds
    @:optional var canRepeat:Bool;
    @:optional var weight:Float; // Selection weight for random sections
}

typedef DynamicAudioFiles = {
    var inst:String;
    @:optional var vocals:String; // Legacy single vocals file
    @:optional var vocalsPlayer:String; // New multi-track vocals
    @:optional var vocalsOpponent:String;
    @:optional var vocalsGF:String;
}

typedef DynamicFlow = {
    var generationMode:String; // "programmatic", "simple_random", "custom"
    @:optional var generator:String; // Function name for programmatic generation
    @:optional var simpleRandom:DynamicSimpleRandom; // Config for simple random mode
}
```

### Integration with High Quality Trap

Dynamic songs are processed **before** High Quality Trap replacement:

```haxe
// In Song.loadFromJson()
// Check for dynamic song first
if (DynamicSongManager.isDynamicSong(folder)) {
    // Process dynamic song...
    if (DynamicSongManager.instance.loadDynamicSong(folder)) {
        PlayfieldManager.SONG = DynamicSongManager.instance.getStitchedSong();
        // Set flags for later High Quality Trap processing
        PlayfieldManager.SONG.isDynamic = true;
        PlayfieldManager.SONG.sectionSequence = currentSections;
        return PlayfieldManager.SONG;
    }
}

// Then High Quality Trap replacement happens
#if ARCHIPELAGO_ALLOWED
var replacementSong = HighQualityTrapManager.getReplacementSong(originalSong, ...);
#end
```

This means:
- Dynamic songs can be replaced entirely by SiivaGunner content
- Individual dynamic sections cannot be replaced (all-or-nothing approach)
- Fallback songs can also be subject to High Quality Trap replacement

### Generation Modes

1. **Programmatic**: Uses custom script functions for section selection
2. **Simple Random**: Basic random selection with start/middle/end structure
3. **Custom**: Advanced scripting with conditional transitions

## APFreeplayManager Integration

### High Quality Trap Filtering

The APFreeplayManager provides specialized handling for High Quality Trap content:

```haxe
// Filter songs to only show SiivaGunner compatible content
if (HighQualityTrapManager.isTrapInUse()) {
    var filteredSongs = HighQualityTrapManager.filterUnlockedSongsForSiiva(convertedSongs);

    if (filteredSongs.length == 0) {
        // No compatible songs found - provide random SiivaGunner song
        var randomSiivaSong = HighQualityTrapManager.getRandomSiivaSong();
        if (randomSiivaSong != null) {
            // Use random SiivaGunner content as fallback
        }
    }
}
```

### Difficulty Management

```haxe
// Get difficulties from SiivaGunner week data instead of original files
if (HighQualityTrapManager.isTrapInUse()) {
    var siivaDiffs = HighQualityTrapManager.getAvailableDifficulties(songName, modName);
    // Filter original difficulties to only include available ones
    return HighQualityTrapManager.filterDifficulties(originalDifficulties, songName, modName);
}
```

### Song Replacement Pipeline

```haxe
// Multi-step replacement process
public static function getProcessedSongName(originalSong:String, modName:String):String {
    if (HighQualityTrapManager.isTrapInUse()) {
        return HighQualityTrapManager.getReplacementSong(originalSong, modName);
    }
    return originalSong;
}
```

## File Path Redirection (Paths.hx Integration)

### Automatic Path Redirection

The High Quality Trap system integrates deeply with the Paths system for transparent file redirection:

```haxe
// In Paths.hx file lookup functions
if (HighQualityTrapManager.isTrapInUse()) {
    // Try current mod directory in SiivaGunner temp folder
    if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
        var siivaFile:String = HighQualityTrapManager.getTempPath() + '/' +
                              Mods.currentModDirectory + '/' + key;
        var result = checkForRandomFileInFolder(siivaFile);
        if (result != null) return result;
    }

    // Try other enabled mods
    for (mod in Mods.getGlobalMods()) {
        var siivaFile:String = HighQualityTrapManager.getTempPath() + '/' + mod + '/' + key;
        var result = checkForRandomFileInFolder(siivaFile);
        if (result != null) return result;
    }

    // Try base game replacement (marked with __mixtape__)
    var siivaBaseFile:String = HighQualityTrapManager.getTempPath() + '/__mixtape__/' + key;
    var result = checkForRandomFileInFolder(siivaBaseFile);
    if (result != null) return result;
}
```

### Affected File Types

- **Audio Files**: `Inst.ogg`, `Voices.ogg`, sound effects
- **Chart Files**: JSON chart data
- **Graphics**: Character sprites, backgrounds, UI elements
- **Data Files**: Week definitions, metadata
- **Scripts**: Lua and HScript files

## Advanced Features

### Mania System Support

The engine supports variable key counts through the mania system:

```haxe
// In song conversion functions
if (songJson.mania == null) {
    songJson.mania = Note.defaultMania;
}
if (songJson.startMania == null) {
    songJson.startMania = songJson.mania;
}

// Note processing adapts to mania count
for (note in section.sectionNotes) {
    var gottaHitNote:Bool = (note[1] < Note.ammo[songJson.mania]) ?
                           section.mustHitSection : !section.mustHitSection;
    note[1] = (note[1] % Note.ammo[songJson.mania]) +
              (gottaHitNote ? 0 : Note.ammo[songJson.mania]);
}
```

High Quality Trap content can include mania-specific charts, allowing for:
- 4K, 6K, 9K chart variants
- Cross-mania compatibility
- Mania-specific SiivaGunner remixes

### Multi-Format Support

The engine handles multiple chart formats with automatic conversion:

```haxe
switch(convertTo) {
    case 'psych_v1':
        if(!fmt.startsWith('psych_v1')) {
            songJson.format = 'psych_v1_convert';
            convert(songJson);
        }

    case 'mixtape_v1':
        if(!fmt.startsWith('mixtape_v1')) {
            songJson.format = 'mixtape_v1_convert';
            convertMixtape(songJson);
        }
}
```

This allows High Quality Trap content to:
- Use any supported chart format
- Be automatically converted to engine-native format
- Maintain compatibility across different mod types

## Performance Considerations

### Memory Management

- **Lazy Loading**: Charts only loaded when needed
- **Path Caching**: File paths cached for repeated access
- **Audio Stitching**: Dynamic songs pre-processed into single audio objects
- **Temp Cleanup**: High Quality Trap content automatically cleaned up

### Processing Order

1. **Dynamic Song Check**: Highest priority, processes entire song structure
2. **High Quality Trap**: Second priority, can replace dynamic or normal songs
3. **Song Variants**: Third priority, works within High Quality Trap context
4. **Normal Loading**: Fallback for standard songs

### Error Handling

```haxe
// Robust fallback chain
if (!loadDynamicSong(folder)) {
    var fallbackSong = DynamicSongManager.instance.getFallbackSong();
    if (fallbackSong != null) {
        PlayfieldManager.SONG = fallbackSong;
        return PlayfieldManager.SONG;
    }
    // Continue with normal loading
}
```

## Integration Testing

### Debug Commands

Via Main.CommandPrompt:

```
testTrapLink highqualitytrap    # Test High Quality Trap activation
testDynamic songname           # Test dynamic song generation
variantInfo songname           # Show available variants
siivaStatus                    # Show High Quality Trap status
```

### Status Information

```haxe
var status = HighQualityTrapManager.getStatusInfo();
// Returns comprehensive system state including:
// - Active/initialized status
// - Available mods and songs
// - Song replacement mappings
// - Week information with difficulties
// - Variant availability
```

## Future Enhancements

### Planned Features

1. **Cross-System Integration**: Dynamic songs with High Quality variants
2. **Smart Caching**: Persistent variant preferences
3. **Scripting Integration**: HScript-based variant selection
4. **Streaming Support**: Real-time content updates
5. **User Preferences**: Player-controlled variant systems

### Compatibility Considerations

- **Mod Compatibility**: Systems designed for maximum mod interoperability
- **Performance Scaling**: Efficient handling of large SiivaGunner repositories
- **Memory Management**: Automatic cleanup and resource management
- **Cross-Platform**: Consistent behavior across Windows/Linux/Mac

## Conclusion

The integration of High Quality Trap with the engine's song systems creates a sophisticated, multi-layered content delivery system that provides:

- **Transparent Operation**: Players experience seamless content replacement
- **Maximum Compatibility**: Works with existing mods and content
- **Enhanced Replay Value**: Variants and dynamic systems increase longevity
- **Robust Fallbacks**: Graceful degradation when content is unavailable
- **Developer Flexibility**: Multiple integration points for custom content

This architecture demonstrates the engine's commitment to extensibility and user experience while maintaining technical excellence and performance optimization.
