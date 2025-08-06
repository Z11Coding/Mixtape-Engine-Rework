# HScript Archipelago Integration

The Mixtape Engine now supports HScript-based Archipelago integration through the CustomAPLogic system. This allows mod developers to define custom items and### Advanced Features

### Accessing Player Settings

You can access all the player's YAML settings to make decisions based on their configuration:

```haxe
// Check player's unlock method preference
if (playerSettings.unlock_method == "Song Completion") {
    // Create easier locations for song completion only
    addSimpleLocation("Easy Clear", "easy-song", null, ["Basic Item"], true);
} else if (playerSettings.unlock_method == "Both") {
    // Create more challenging locations for both note checks and completion
    addLocationWithCounts("Ultimate Challenge", "hard-song", null, [
        { name: "Skill Item", count: 3 },
        { name: "Perfect Item", count: 1 }
    ], true);
}

// Scale content based on song limit
var songLimit = playerSettings.song_limit;
if (songLimit >= 50) {
    // Player wants lots of content, add extra songs
    addSongs(["bonus-track-1", "bonus-track-2", "bonus-track-3"]);
    defineCustomWeek("Bonus Content", ["bonus-track-1", "bonus-track-2", "bonus-track-3"]);
} else if (songLimit <= 20) {
    // Player wants minimal content, exclude optional songs
    excludeSongs(["optional-song", "extra-content"]);
}

// Adjust trap frequency based on player's trap amount setting
var trapAmount = playerSettings.trapAmount;
if (trapAmount >= 30) {
    // Player likes lots of traps
    addTrapItem("Extra Chaos");
    addTrapItem("Maximum Confusion");
} else if (trapAmount <= 10) {
    // Player prefers fewer traps, make them less frequent
    setDataValue("reduced_trap_chance", true);
}

// Use accessibility settings
if (playerSettings.accessibility == "minimal") {
    // Create more accessible content
    setDataValue("easy_mode", true);
    excludeSongs(["extremely-difficult", "accessibility-nightmare"]);
}

// Check deathlink preference
if (playerSettings.deathlink) {
    addTrapItem("Deathlink Trigger");
    setDataValue("deathlink_enabled", true);
}
```

### Conditional Logic Based on Available Modscations using HScript syntax with full access to mod context and validation.

## Setup

1. Create an `ap/` folder in your mod directory
2. Add `.hx` files containing your Archipelago logic
3. The system will automatically scan and execute these scripts when generating the YAML, creating a python file which will be generated with it.

## Mod Structure
```
mods/
  your-mod/
    ap/
      items.hx          # Define your items
      locations.hx      # Define your locations
      traps.hx          # Define trap items
      special.hx        # Any other AP logic
    data/
    images/
    ...
```

## Available Variables

When your HScript runs, these variables are automatically available:

- `modName`: String - Display name of your mod
- `modFolderName`: String - Folder name of your mod  
- `songList`: Array<String> - List of songs in your mod
- `availableMods`: Array<ModInfo> - Information about all available mods
- `playerSettings`: Dynamic - All player settings from the YAML generation (APEntryState.gameSettings.FNF)

## Song Discovery and Management

By default, the system only discovers songs that are defined in week files (`mods/your-mod/weeks/*.json`). This ensures that only intended, properly configured songs are included in Archipelago.

### Song Exclusion and Addition

Sometimes you may want to:
- **Exclude** songs that are in weeks but shouldn't be in AP (e.g., tutorial songs, or "alternative menus")
- **Include** songs that aren't in weeks but should be available (e.g., bonus tracks)

```haxe
// Remove songs from the discovered list
excludeSong("tutorial");
excludeSongs(["debug-song", "test-mode"]);

// Add songs that weren't discovered automatically
addSong("hidden-bonus");
addSongs(["secret-track", "easter-egg"]);

// Target specific mods for song modifications
excludeSong("tutorial", "SomeMod"); // Remove tutorial from SomeMod
addSong("bonus-track", "AnotherMod"); // Add bonus track to AnotherMod

// Check what the final list looks like
var finalList = getFinalSongList();
trace("Songs available for AP: " + finalList.join(", "));
```

### Cross-Mod Song Management

The system supports adding or removing songs from other mods:

```haxe
// Add a song to another mod's collection
addSong("Cross-Mod Song", "Target Mod");

// Remove a problematic song from another mod
excludeSong("Broken Song", "Problem Mod");

// Use null or empty string for current mod
addSong("Local Song"); // Adds to current mod
excludeSong("Local Song", ""); // Removes from base game
```

### Use Cases

**Excluding Songs:**
- Tutorial or practice songs
- Debug/test tracks
- Songs that break AP logic
- Incomplete or placeholder content

**Adding Songs:**
- Bonus tracks not tied to story progression
- Secret songs unlocked through special means
- Songs from other mods that this mod references
- Custom challenge tracks

## Available Functions

### Item Management
```haxe
// Add a basic item
addItem("Item Name");

// Add an item that requires another mod to be present
addItem("Cross-Mod Item", "Required Mod Name");
```

### Trap Item Management
```haxe
// Add a basic trap item (affects current mod)
addTrapItem("Confusion Trap");

// Add a trap item that targets a specific mod
addTrapItem("Speed Trap", "Target Mod");

// Add trap items that work across multiple mods
addTrapItem("Universal Freeze", ""); // Empty string = affects base game
addTrapItem("Mod-Specific Chaos", "Psych Engine"); // Only affects Psych Engine
```

### Location Management
```haxe
// Basic location with custom access rule
addLocation("Location Name", "origin-song", "target-mod", accessRule, true);

// Simple location requiring specific items (count of 1 each)
addSimpleLocation("Simple Location", "song-name", "target-mod", ["Item 1", "Item 2"], true);

// Location for base game content (empty string or null = base game)
addSimpleLocation("Base Game Location", "bopeebo", "", ["Item"], false);

// Location with specific item counts
addLocationWithCounts("Complex Location", "song-name", "target-mod", [
    { name: "Item 1", count: 2 },
    { name: "Item 2", count: 1 }
], true);

// Location that doesn't require the target mod to exist (useful for cross-mod content)
addSimpleLocation("Cross-Mod Location", "song", "Other Mod", ["Item"], false);
```

### Song List Management
```haxe
// Exclude songs from the mod's song list (e.g., tutorial songs)
excludeSong("tutorial");
excludeSongs(["debug-song", "test-track"]);

// Add songs that aren't in weeks but should be available for AP
addSong("bonus-track");
addSongs(["secret-song", "easter-egg-track"]);

// Cross-mod song management
excludeSong("problematic-song", "Other Mod");
addSong("bonus-content", "Target Mod");

// Get the final processed song list
var finalSongs = getFinalSongList();
trace("Available songs: " + finalSongs.join(", "));
```

### Python Generation and Data Storage

The CustomAPLogic system automatically generates Python code that mirrors your HScript definitions. This ensures that your AP world generation has access to the same data structures you define in HScript.

```haxe
// Set data that will be available during Python generation
setDataValue("special_config", "some_value");
setDataValue("item_multiplier", 2);

// These values will be accessible in the generated Python as:
// self.custom_data["special_config"]
// self.custom_data["item_multiplier"]

// Check if a value exists
if (hasDataValue("special_config")) {
    trace("Special config is set");
}

// Get a value with a default fallback
var multiplier = getDataValue("item_multiplier", 1);
```

### Custom Week Integration

The system supports creating temporary custom weeks during Archipelago sessions without modifying files on disk:

```haxe
// Define custom weeks that will be created dynamically
// These are added to the slot data and created in-memory during the AP session
defineCustomWeek("AP Special Week", ["song1", "song2", "song3"]);
defineCustomWeek("Cross-Mod Week", ["base-song", "mod-song"], "Cross Mod");

// Check if custom weeks are supported in the current configuration
if (supportsCustomWeeks()) {
    defineCustomWeek("Dynamic Content", ["adaptive-song"]);
}
```

## Advanced Features

### Conditional Logic Based on Available Mods

```haxe
// Check if specific mods are available
if (isModEnabled("Psych Engine")) {
    addItem("Psych Engine Integration");
    addSimpleLocation("Psych Engine Song", "song-name", "Psych Engine", ["Item"], true);
}

// Create content that works across multiple mods
var supportedMods = ["Psych Engine", "Forever Engine", "Kade Engine"];
for (mod in supportedMods) {
    if (isModEnabled(mod)) {
        addItem(mod + " Compatibility Item");
        addTrapItem(mod + " Specific Trap", mod);
    }
}
```

### Advanced Trap Item Scenarios

```haxe
// Create trap items with specific targeting
addTrapItem("Speed Chaos", ""); // Affects base game only
addTrapItem("Mod-Specific Glitch", "Target Mod"); // Only affects specific mod
addTrapItem("Universal Confusion"); // Affects current mod (default)

// Create different categories of trap items
var visualTraps = ["Screen Flip", "Color Chaos", "UI Scramble"];
var audioTraps = ["Pitch Shift", "Reverb Chaos", "Speed Fluctuation"];
var gameplayTraps = ["Note Scramble", "Reverse Controls", "Invisible Notes"];

for (trap in visualTraps) {
    addTrapItem(trap);
}

for (trap in audioTraps) {
    addTrapItem(trap);
}

for (trap in gameplayTraps) {
    addTrapItem(trap);
}
```

### Song Management Strategies

```haxe
// Strategy 1: Clean up tutorial and test content
var excludePatterns = ["tutorial", "test", "debug", "practice"];
for (song in songList) {
    for (pattern in excludePatterns) {
        if (song.toLowerCase().indexOf(pattern) != -1) {
            excludeSong(song);
            break;
        }
    }
}

// Strategy 2: Add cross-mod bonus content
var bonusSongs = ["secret-collab", "community-remix", "dev-special"];
for (song in bonusSongs) {
    addSong(song);
}

// Strategy 3: Conditional content based on other mods
if (isModEnabled("Expansion Mod")) {
    addSongs(["expansion-collab-1", "expansion-collab-2"]);
    addSimpleLocation("Expansion Crossover", "expansion-collab-1", "Expansion Mod", 
                     ["Crossover Item"], true);
}
```

### Data Persistence and Configuration

```haxe
// Store configuration data for the Python generation
setDataValue("mod_version", "1.2.0");
setDataValue("difficulty_scaling", true);
setDataValue("cross_mod_support", isModEnabled("Base Expansion"));

// Store song metadata for advanced AP logic
setDataValue("boss_songs", ["final-battle", "secret-boss"]);
setDataValue("easy_songs", ["intro", "warm-up"]);

// This data will be available in the generated Python world as:
// world.custom_data["boss_songs"]
// world.custom_data["difficulty_scaling"]
```

## Best Practices

### Mod Dependencies
Always consider whether you need the target mod to exist:

```haxe
// Require the target mod to exist (default behavior)
if (isModEnabled("Psych Engine")) {
    addSimpleLocation("Psych Engine Reference", "song", "Psych Engine", ["BF Icon"], true);
} else {
    trace("Psych Engine not available, skipping cross-mod content");
}

// Base game content (always available)
addSimpleLocation("Base Game Achievement", "tutorial", "", ["Item"], false);

// Or allow the location even if the target mod doesn't exist (useful for optional content)
addSimpleLocation("Optional Cross-Mod Location", "song", "Optional Mod", ["Item"], false);
```

### Target Mod vs Current Mod
- **targetMod**: The mod that contains the song this location is based on
- **null targetMod**: Uses the current mod (the mod this script belongs to)
- **empty string targetMod**: Refers to base game content
- **requireTargetMod**: Whether the target mod must be enabled for this location to be created

```haxe
// Location for a song in the current mod
addSimpleLocation("Local Song Achievement", "my-song", null, ["Item"], true);

// Location for a song in another mod
addSimpleLocation("Cross-Mod Song Achievement", "their-song", "Their Mod", ["Item"], true);

// Location for base game content (empty string = base game)
addSimpleLocation("Base Game Achievement", "bopeebo", "", ["Item"], false);
```

### Base Game Convention
**Important**: Empty strings (`""`) or `null` values for mod names are treated as referring to base game content:
- `isModEnabled("")` returns `true` (base game is always available)
- `targetMod = ""` refers to base game songs
- Base game songs don't get mod suffixes in the generated Python code

### Debugging and Validation

The system provides several tools for debugging your AP logic:

```haxe
// Trace available information
trace("Mod Name: " + modName);
trace("Mod Folder: " + modFolderName);
trace("Available Songs: " + songList.join(", "));

// Check final song list after modifications
var finalList = getFinalSongList();
trace("Final Song List: " + finalList.join(", "));

// Validate mod dependencies
if (!isModEnabled("Required Mod")) {
    trace("Warning: Required Mod is not available!");
}

// Check data storage
if (hasDataValue("important_config")) {
    trace("Config value: " + getDataValue("important_config"));
} else {
    trace("Important config not set, using defaults");
    setDataValue("important_config", "default_value");
}
```

## Temporary Custom Week System

During Archipelago sessions, the system can create temporary custom weeks that exist only in memory and are automatically cleaned up when the session ends. This allows for dynamic content without modifying files on disk.

### How It Works

1. **Definition**: Custom weeks are defined in HScript and stored in slot data
2. **Creation**: When connecting to AP, temporary WeekData objects are created in memory
3. **Integration**: These weeks appear in the game alongside normal weeks
4. **Cleanup**: Temporary weeks are automatically removed when disconnecting or exiting

### Slot Data Integration

Custom weeks are stored in the AP slot data and automatically created:

```haxe
// Define a custom week with specific songs
defineCustomWeek("AP Challenge Week", ["challenge-1", "challenge-2", "finale"]);

// Define a cross-mod week (if the target mod is available)
if (isModEnabled("Collaboration Mod")) {
    defineCustomWeek("Cross-Mod Special", ["collab-song-1", "collab-song-2"], "Collaboration Mod");
}

// The system will:
// 1. Store this in slot data as custom_weeks
// 2. Create temporary WeekData objects during the AP session
// 3. Clean them up when the session ends
```

### Automatic Cleanup

Temporary weeks are cleaned up in multiple scenarios to ensure no permanent changes:

- When disconnecting from Archipelago
- When canceling the AP connection
- When exiting to the main menu
- When the game exits
- If the AP session errors out

This ensures that the game returns to its original state after the Archipelago session.

## Complete Examples

### Basic Mod with Items and Locations
```haxe
// mods/MyMod/ap/basic.hx

// Add some basic items
addItem("BF Skin Unlock");
addItem("GF Costume");
addItem("Special Background");

// Create locations for each song in the mod
for (song in songList) {
    addSimpleLocation(song + " Completion", song, null, ["BF Skin Unlock"], true);
}

// Add a special final location requiring multiple items
addLocationWithCounts("Ultimate Challenge", "final-boss", null, [
    { name: "BF Skin Unlock", count: 1 },
    { name: "GF Costume", count: 1 },
    { name: "Special Background", count: 1 }
], true);
```

### Cross-Mod Integration
```haxe
// mods/MyMod/ap/crossmod.hx

// Check for compatible mods and create cross-content
var compatibleMods = ["Psych Engine", "Forever Engine", "VS Whitty"];

for (mod in compatibleMods) {
    if (isModEnabled(mod)) {
        addItem("Collaboration with " + mod);
        addTrapItem(mod + " Style Chaos", mod);
        
        // Add locations that reference the other mod's content
        addSimpleLocation(mod + " Crossover Achievement", "crossover-song", mod, 
                         ["Collaboration with " + mod], false);
    }
}

// Create a special week if multiple mods are available
var enabledCompatMods = [];
for (mod in compatibleMods) {
    if (isModEnabled(mod)) {
        enabledCompatMods.push(mod);
    }
}

if (enabledCompatMods.length >= 2) {
    defineCustomWeek("Multi-Mod Mashup", ["mashup-1", "mashup-2", "ultimate-collab"]);
    setDataValue("participating_mods", enabledCompatMods);
}
```

### Advanced Trap and Bonus System
```haxe
// mods/MyMod/ap/advanced.hx

// Exclude tutorial content but add hidden songs
excludeSongs(["tutorial", "practice-mode"]);
addSongs(["secret-track", "developer-room", "bonus-remix"]);

// Create different types of trap items
var visualTraps = ["Screen Flip", "Color Chaos", "UI Scramble"];
var audioTraps = ["Pitch Shift", "Reverb Chaos", "Speed Fluctuation"];
var gameplayTraps = ["Note Scramble", "Reverse Controls", "Invisible Notes"];

for (trap in visualTraps) {
    addTrapItem(trap + " (Visual)");
}

for (trap in audioTraps) {
    addTrapItem(trap + " (Audio)");
}

for (trap in gameplayTraps) {
    addTrapItem(trap + " (Gameplay)");
}

// Store configuration for the Python world
setDataValue("trap_duration", 30); // seconds
setDataValue("visual_effects_enabled", true);

// Create dynamic content based on difficulty
var difficulty = getDataValue("selected_difficulty", "normal");
if (difficulty == "expert") {
    addSongs(["expert-only-1", "expert-only-2"]);
    defineCustomWeek("Expert Challenge", ["expert-only-1", "expert-only-2", "ultimate-expert"]);
}
```

This comprehensive system allows mod developers to create rich, interactive Archipelago experiences while maintaining compatibility and providing powerful customization options.

### Mod Validation
```haxe
// Check if a mod is enabled
if (isModEnabled("Psych Engine")) {
    // Add content that requires Psych Engine
}

// Base game is always considered "enabled" (empty string or null)
if (isModEnabled("")) {
    // This will always be true - base game is always available
}

// Get detailed mod information
var modInfo = getModInfo("Some Mod");
if (modInfo != null && modInfo.enabled) {
    trace("Mod has " + modInfo.songList.length + " songs");
}
```

### Debugging
```haxe
// Output debug information
trace("Debug message");
```

## Access Rules

Access rules define what items are needed to access a location:

```haxe
// Manual access rule definition
var rule = {
    requiredItems: [
        { name: "Song Access", count: 1 },
        { name: "Difficulty Unlock", count: 1 },
        { name: "Special Key", count: 3 }
    ]
};
addLocation("Hard Location", "song", null, rule);
```

## Best Practices

### Mod Dependencies
Always check if required mods are enabled before adding cross-mod content:

```haxe
if (isModEnabled("Base Game")) {
    addSimpleLocation("Base Game Reference", "song", null, ["BF Icon"], "Base Game");
} else {
    trace("Base Game not available, skipping cross-mod content");
}
```

### Error Handling
The system will automatically validate mod requirements and warn about missing dependencies:

```haxe
// This will show a warning if "Missing Mod" is not enabled
addItem("Cross Mod Item", "Missing Mod");
```

### Organization
Split your AP logic into multiple files for better organization:

- `items.hx` - All item definitions
- `locations.hx` - All location definitions  
- `cross-mod.hx` - Content that depends on other mods
- `special.hx` - Advanced or conditional logic

### Context Awareness
Use the provided context variables to make smart decisions:

```haxe
// Exclude tutorial songs for all mods
excludeSongs(["tutorial", "how-to-play"]);

// Add different content based on available songs
var finalSongs = getFinalSongList();
if (finalSongs.length > 10) {
    addItem("Song Master");
    addSimpleLocation("Complete Collection", "final-song", null, ["Song Master"], true);
}

// Add bonus content based on song count
if (finalSongs.length > 5) {
    addSong("marathon-mode");
    addSimpleLocation("Marathon Challenge", "marathon-mode", null, finalSongs.map(song -> song + " Access"), true);
}

// Scale difficulty based on other mods
var otherModCount = 0;
for (mod in availableMods) {
    if (mod.enabled && mod.name != modName) {
        otherModCount++;
    }
}

if (otherModCount > 5) {
    addItem("Veteran Player Bonus");
}
```

## Migration from Python

If you were using the old Python-based custom location system:

### Old Python Format
```python
def get_custom_locations():
    return [
        {
            "name": "Song FC",
            "originSong": "song1",
            "originMod": "My Mod",
            "access_rule": {
                "requiredItems": [{"name": "Song Access", "count": 1}]
            }
        }
    ]
```

### New HScript Format
```haxe
// Simple location for current mod's song
addSimpleLocation("Song FC", "song1", null, ["Song Access"], true);

// Cross-mod location
addSimpleLocation("Cross-Mod Achievement", "song1", "Other Mod", ["Song Access"], false);

// Base game location (empty string = base game)
addSimpleLocation("Base Game FC", "bopeebo", "", ["Song Access"], false);
```

The HScript system is more powerful and provides better mod integration while being easier to write and maintain.

## Example Files

See `docs/HScript_AP_Example.hx` for a complete example showing all available features.
