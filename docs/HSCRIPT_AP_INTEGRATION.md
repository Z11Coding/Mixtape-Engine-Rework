# HScript Archipelago Integration

The Mixtape Engine supports HScript-based Archipelago integration through the CustomAPLogic system. This allows mod developers to define custom items and locations using HScript syntax with full access to mod context and validation.

## Getting Started

### Quick Start Guide

1. **Create the AP folder**: In your mod directory, create an `ap/` folder
2. **Add HScript files**: Create `.hx` files containing your Archipelago logic
3. **Define your content**: Use the available functions to add items, locations, song requirements, and customize songs
4. **Test and iterate**: The system provides automatic validation and helpful error messages

### Basic Example

```haxe
// mods/MyMod/ap/basic.hx

// Add some items that players can receive
addItem("Song Unlock Key");
addItem("Difficulty Modifier");
addItem("Special Effect");

// Make certain songs require items to be accessible
addSimpleSongRequirement("Boss Battle", null, ["Song Unlock Key"]);
addSimpleSongRequirement("Final Boss", null, ["Song Unlock Key", "Difficulty Modifier"]);

// Create locations based on your mod's songs
for (song in songList) {
    // Simple location requiring just the unlock key
    addSimpleLocation(song + " Clear", song, null, ["Song Unlock Key"], true);

    // Advanced location requiring multiple items
    addLocationWithCounts(song + " Perfect", song, null, [
        { name: "Song Unlock Key", count: 1 },
        { name: "Difficulty Modifier", count: 2 }
    ], true);
}

// Add some trap items for extra challenge
addTrapItem("Speed Chaos");
addTrapItem("Reverse Controls");
```

### Recommended Mod Structure

```
mods/
  your-mod/
    ap/
      items.hx          # Define your items
      locations.hx      # Define your locations
      song_requirements.hx # Define song access requirements
      traps.hx          # Define trap items
      special.hx        # Any other AP logic
    data/
    images/
    weeks/
    ...
```

**Organization Tips:**
- Split your AP logic into multiple files for better organization
- Use descriptive file names that indicate their purpose
- Keep related functionality together (e.g., all trap items in `traps.hx`)
- Use comments to document complex logic

## Available Variables

When your HScript runs, these variables are automatically available:

- `modName`: String - Display name of your mod
- `modFolderName`: String - Folder name of your mod
- `songList`: Array<String> - List of songs in your mod
- `availableMods`: Array<ModInfo> - Information about all available mods
- `playerSettings`: Dynamic - All player settings from the YAML generation (APEntryState.gameSettings.FNF)

## Optional Callbacks

Your HScript can define optional callback functions that will be called at specific points during the generation process:

### `onGenYAML()`
Called after all initial HScript processing is complete and the song list has been finalized, but before the Python generation. This is useful for final validation or cleanup operations.
Can also simply be used for people used to having a callback method to execute code in scripts.

```haxe
function onGenYAML() {
    // This runs after all mods have been processed and the final song list is generated
    trace("Final validation for " + modName);

    var finalSongs = getFinalSongList();
    trace("Final song count: " + finalSongs.length);

    // Perform any final adjustments or validation
    if (finalSongs.length == 0) {
        trace("Warning: No songs available for mod " + modName);
    }

    // Final opportunity to add conditional content
    if (finalSongs.length >= 10) {
        addItem("Song Collection Master");
        addSimpleLocation("Complete Collection", finalSongs[finalSongs.length - 1], null, ["Song Collection Master"], true);
    }
}
```

### `onAfterGen()`
Called after the complete generation process, including all processing and data storage. This is the final callback before the process completes.

```haxe
function onAfterGen() {
    // This runs after everything is complete, including all data processing
    trace("Generation complete for " + modName);

    // Log final statistics or perform cleanup
    if (hasDataValue("debug_mode")) {
        trace("Debug info: " + getDataValue("debug_mode"));
    }

    // Final summary
    trace("Total items added: " + getDataValue("item_count", 0));
    trace("Total locations added: " + getDataValue("location_count", 0));
}
```

**Note:** These callbacks are optional - your HScript will work perfectly without them. They're provided for developers who need more control over the generation process.

## Accessing Player Settings

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

## Song Requirements

The system supports making songs require specific items to be accessible. This allows you to gate certain songs behind progression requirements, creating a more structured experience where players must earn access to different content.

### Basic Song Requirements

```haxe
// Make a song require a single item to access
addSimpleSongRequirement("Boss Battle", null, ["Power Boost"]);

// Make a song require multiple items
addSimpleSongRequirement("Final Boss", null, ["Magic Key", "Super Shield"]);

// Make a base game song require items from your mod
addSimpleSongRequirement("Roses", "", ["Thorns Protection"]);

// Make a song from another mod require your items
if (isModEnabled("Other Mod")) {
    addSimpleSongRequirement("Cross Mod Song", "Other Mod", ["Special Item"]);
}
```

### Advanced Song Requirements

```haxe
// Require specific quantities of items
var ultimateRequirements = [
    { name: "Energy Crystal", count: 3 },
    { name: "Master Key", count: 1 }
];
addSongRequirementWithCounts("Ultimate Challenge", null, ultimateRequirements);

// Create progressive song unlocking chains
addSimpleSongRequirement("Tutorial Plus", null, ["Basic Training"]);
addSimpleSongRequirement("Beginner Challenge", null, ["Basic Training", "Tutorial Plus Access"]);
addSimpleSongRequirement("Advanced Test", null, ["Basic Training", "Advanced Techniques"]);
```

### Song Requirement Utilities

```haxe
// Check if a song has requirements
if (hasSongRequirement("Boss Battle", null)) {
    trace("Boss Battle is locked behind items");
}

// Get the full requirement details
var requirement = getSongRequirement("Boss Battle", null);
if (requirement != null) {
    trace("Boss Battle requires " + requirement.accessRule.requiredItems.length + " items");
}
```

### Integration with Game Logic

Song requirements integrate with the randomizer and game client in several ways:

1. **Randomizer Logic**: The AP world generator uses song requirements to ensure proper item distribution
2. **Client Integration**: The game client can lock/unlock songs based on received items
3. **Progression Tracking**: Requirements help create logical progression paths through content

### Use Cases

**Progressive Difficulty**: Lock harder songs behind easier ones plus skill items
```haxe
addSimpleSongRequirement("Expert Mode", null, ["Rhythm Master", "Perfect Timing"]);
```

**Story Progression**: Gate story songs behind narrative items
```haxe
addSimpleSongRequirement("Chapter 2", null, ["Chapter 1 Complete", "Story Key"]);
```

**Cross-Mod Integration**: Make collaboration songs require items from multiple mods
```haxe
addSimpleSongRequirement("Crossover Battle", null, ["Mod A Token", "Mod B Token"]);
```

**Challenge Modes**: Lock special modes behind achievement items
```haxe
addSimpleSongRequirement("Nightmare Mode", null, ["Courage", "Determination", "Skill"]);
```

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

### Song Requirement Management
```haxe
// Make a song require specific items to be accessible
addSimpleSongRequirement("Boss Battle", null, ["Power Boost"]);
addSimpleSongRequirement("Final Boss", null, ["Magic Key", "Super Shield"]);

// Song requirements with specific item counts
addSongRequirementWithCounts("Ultimate Challenge", null, [
    { name: "Energy Crystal", count: 3 },
    { name: "Master Key", count: 1 }
]);

// Cross-mod song requirements
addSimpleSongRequirement("Cross Mod Song", "Other Mod", ["Special Item"]);

// Base game song requirements
addSimpleSongRequirement("Roses", "", ["Thorns Protection"]);

// Check if a song has requirements
if (hasSongRequirement("Boss Battle", null)) {
    trace("Boss Battle is locked");
}

// Get requirement details
var requirement = getSongRequirement("Boss Battle", null);
if (requirement != null) {
    trace("Requirements: " + requirement.accessRule.requiredItems.length + " items");
}
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

The CustomAPLogic system automatically generates Python code that corresponds to your HScript definitions. This ensures that your Archipelago world generation has access to the same data structures you define in HScript.

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
// Basic custom week with default settings
defineCustomWeek("AP Special Week", ["song1", "song2", "song3"]);
defineCustomWeek("Cross-Mod Week", ["base-song", "mod-song"], "Cross Mod");

// Enhanced custom week with metadata
defineCustomWeek("Boss Week", ["Boss1", "Boss2"], "MyMod",
    ["hard", "expert"],  // Custom difficulties
    "boss",              // Default icon for songs
    [255, 0, 0]         // Default color for songs
);

// Custom week with per-song metadata
defineCustomWeekWithSongMetadata("Mixed Week", [
    {name: "Easy Song", icon: "face", color: [0, 255, 0]},
    {name: "Hard Song", icon: "boss", color: [255, 0, 0]},
    {name: "Normal Song"} // Uses week defaults or global defaults
], "MyMod", ["easy", "normal", "hard"]);

// Check if custom weeks are supported in the current configuration
if (supportsCustomWeeks()) {
    defineCustomWeek("Dynamic Content", ["adaptive-song"]);
}
```

### Enhanced Song Management

The system now supports enhanced song management with metadata for icons, colors, and difficulties:

```haxe
// Basic song addition (backwards compatible)
addSong("My New Song", "MyMod");

// Enhanced song addition with metadata
addSong("Boss Battle", "MyMod", "boss", [255, 0, 0], ["hard", "expert"]);

// Parameters: songName, targetMod, icon, color, difficulties
// - icon: Optional icon name (defaults to "face")
// - color: Optional RGB color array (defaults to [146, 113, 253])
// - difficulties: Optional array of difficulty names (defaults to week difficulties)

// Batch song addition with shared metadata
addSongs(["Song1", "Song2"], "MyMod", "boss", [255, 0, 0], ["hard"]);

// Individual song metadata
addSongsWithMetadata([
    {name: "Easy Song", icon: "face", color: [0, 255, 0], difficulties: ["easy"]},
    {name: "Hard Song", icon: "boss", color: [255, 0, 0], difficulties: ["hard", "expert"]}
], "MyMod");
```

### Difficulty-Based Week Optimization

The system automatically optimizes week creation by grouping songs with identical difficulty sets:

```haxe
// These songs will be grouped into separate optimized weeks automatically
addSong("Easy Song", "MyMod", "face", [0, 255, 0], ["easy"]);
addSong("Normal Song", "MyMod", "face", [0, 0, 255], ["easy", "normal"]);
addSong("Hard Song", "MyMod", "boss", [255, 0, 0], ["hard"]);
addSong("Expert Song", "MyMod", "boss", [255, 0, 0], ["hard", "expert"]);

// Results in optimized weeks:
// - ap_custom_MyMod_easy (contains "Easy Song")
// - ap_custom_MyMod_easy_normal (contains "Normal Song")
// - ap_custom_MyMod_hard (contains "Hard Song")
// - ap_custom_MyMod_hard_expert (contains "Expert Song")
```

**Benefits:**
- **Reduced Week Count**: Songs with identical difficulty sets are grouped together
- **Performance**: Fewer weeks means faster loading and better memory usage
- **Organization**: Songs are logically grouped by their difficulty requirements
- **Per-Song Granularity**: Each song can have its own unique icon and color
- **Compatibility**: All enhancements are optional - existing code continues to work

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

// Strategy 2: Add cross-mod bonus content with metadata
addSongsWithMetadata([
    {name: "secret-collab", icon: "secret", color: [128, 0, 128], difficulties: ["secret"]},
    {name: "community-remix", icon: "community", color: [0, 255, 255], difficulties: ["easy", "normal"]},
    {name: "dev-special", icon: "dev", color: [255, 255, 0], difficulties: ["expert"]}
]);

// Strategy 3: Conditional content based on other mods
if (isModEnabled("Expansion Mod")) {
    addSongs(["expansion-collab-1", "expansion-collab-2"], null, "collab", [100, 200, 255]);
    addSimpleLocation("Expansion Crossover", "expansion-collab-1", "Expansion Mod",
                     ["Crossover Item"], true);
}

// Strategy 4: Create themed weeks with consistent styling
defineCustomWeekWithSongMetadata("Boss Rush Week", [
    {name: "Mini Boss", icon: "miniboss", color: [255, 165, 0]},
    {name: "Main Boss", icon: "boss", color: [255, 0, 0]},
    {name: "Final Boss", icon: "finalboss", color: [128, 0, 0]}
], "MyMod", ["hard", "expert"]);
```

### Complete Enhanced Example

```haxe
// Example showing all enhanced features working together
function setupEnhancedContent() {
    // Individual songs with full metadata
    addSong("Tutorial Song", "MyMod", "tutorial", [0, 255, 0], ["easy"]);
    addSong("Boss Fight", "MyMod", "boss", [255, 0, 0], ["hard", "expert"]);

    // Batch songs with shared metadata
    addSongs(["Chapter1", "Chapter2"], "MyMod", "story", [0, 100, 200], ["normal"]);

    // Songs with individual metadata (auto-optimized by difficulty)
    addSongsWithMetadata([
        {name: "Calm Intro", icon: "calm", color: [100, 200, 255], difficulties: ["easy"]},
        {name: "Epic Finale", icon: "epic", color: [255, 100, 0], difficulties: ["hard"]},
        {name: "Secret Track", icon: "secret", color: [128, 0, 128], difficulties: ["secret"]}
    ], "MyMod");

    // Basic custom week with defaults
    defineCustomWeek("Standard Week", ["Normal1", "Normal2"], "MyMod",
        ["easy", "normal"], "face", [146, 113, 253]);

    // Advanced custom week with per-song metadata
    defineCustomWeekWithSongMetadata("Story Mode", [
        {name: "Prologue", icon: "start", color: [0, 255, 0]},
        {name: "Rising Action", icon: "action", color: [255, 165, 0]},
        {name: "Climax", icon: "boss", color: [255, 0, 0]},
        {name: "Resolution", icon: "end", color: [0, 0, 255]}
    ], "MyMod", ["story"]);

    // Add corresponding locations with proper access rules
    addSimpleLocation("Tutorial Complete", "Tutorial Song", "MyMod", ["Basic Training"], true);
    addSimpleLocation("Boss Defeated", "Boss Fight", "MyMod", ["Boss Key", "Power Upgrade"], true);
    addSimpleLocation("Story Complete", "Resolution", "MyMod", ["Story Progress"], true);
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

// Create song requirements for progression
addSimpleSongRequirement("Hard Song", null, ["BF Skin Unlock"]);
addSimpleSongRequirement("Final Boss", null, ["BF Skin Unlock", "GF Costume"]);

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

## Example Files

See the following files for complete examples:
- `docs/HScript_AP_Example.hx` - Basic AP integration features
- `docs/SongRequirements_AP_Example.hx` - Song requirements system usage
- `docs/Song_Requirements_Documentation.md` - Complete song requirements guide
- `TestSongRequirements_customFNFData.py` - Python implementation example
