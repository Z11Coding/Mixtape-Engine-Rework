// Example HScript for Archipelago integration
// Place this file in your mod's "ap/" folder as "example.hx"
// This script will be automatically executed when generating the Archipelago world

// Available variables:
// - modName: String - Name of this mod
// - modFolderName: String - Folder name of this mod
// - songList: Array<String> - Songs available in this mod
// - availableMods: Array<ModInfo> - All available mods and their info

// Available functions:
// - addItem(name:String, ?requiredMod:String)
// - addLocation(name:String, originSong:String, ?targetMod:String, accessRule:APAccessRule, requireTargetMod:Bool = true)
// - addSimpleLocation(name:String, originSong:String, ?targetMod:String, requiredItems:Array<String>, requireTargetMod:Bool = true)
// - addLocationWithCounts(name:String, originSong:String, ?targetMod:String, requiredItems:Array<APRequiredItem>, requireTargetMod:Bool = true)
// - isModEnabled(modName:String): Bool
// - getModInfo(modName:String): ModInfo
// - excludeSong(songName:String): Void
// - addSong(songName:String): Void
// - excludeSongs(songNames:Array<String>): Void
// - addSongs(songNames:Array<String>): Void
// - getFinalSongList(): Array<String>
// - trace(message:String) - for debugging

trace("Processing AP data for mod: " + modName);
trace("Available songs: " + songList.join(", "));

// Modify the song list if needed
// Exclude songs that shouldn't be included in AP
excludeSongs(["tutorial", "debug-song"]);

// Add songs that aren't in weeks but should be available
addSongs(["bonus-track", "secret-song"]);

// Show the final song list
trace("Final song list: " + getFinalSongList().join(", "));

// Add items for this mod
addItem("Song 1 Access");
addItem("Song 2 Access");
addItem("Bonus Track Access");

// Add a simple location (requires just one item)
addSimpleLocation("Song 1 FC", "song1", null, ["Song 1 Access"]);

// Add a location with multiple requirements
addSimpleLocation("Song 2 Perfect", "song2", null, ["Song 1 Access", "Song 2 Access"]);

// Add a location that requires items from another mod (if it exists)
if (isModEnabled("Psych Engine")) {
    addSimpleLocation("Cross-Mod Achievement", "song1", "Psych Engine", ["BF Icon", "Song 1 Access"], true);
}

// Add a location for a base game song (empty string or null = base game)
addSimpleLocation("Base Game Achievement", "tutorial", "", ["Tutorial Complete"], false);

// Add a location with specific item counts
addLocationWithCounts("Ultimate Challenge", "bonus-track", null, [
    { name: "Song 1 Access", count: 1 },
    { name: "Song 2 Access", count: 1 },
    { name: "Perfect Scores", count: 5 }
], true); // Require the target mod (current mod in this case)

// Check what other mods are available
trace("Available mods:");
for (mod in availableMods) {
    if (mod.enabled) {
        trace("  - " + mod.name + " (" + mod.folderName + ") - Songs: " + mod.songList.length);
    }
}

// Conditional content based on other mods
if (isModEnabled("Psych Engine")) {
    addItem("Psych Compatibility");
    addSimpleLocation("Psych Engine Crossover", "special-song", "Psych Engine", ["Psych Compatibility"], true);
}

// Add items that work with base game content (empty string = base game)
addItem("Base Game Mastery");
addSimpleLocation("Base Game Expert", "bopeebo", "", ["Base Game Mastery"], false);

trace("Finished processing AP data for " + modName);

// Optional callback functions (these are optional and not required)

function onGenYAML() {
    // Called after all processing is complete and the final song list is ready
    trace("onGenYAML callback: Final validation for " + modName);
    
    var finalSongs = getFinalSongList();
    trace("Final song count after all processing: " + finalSongs.length);
    
    // You can add final items or locations here based on the complete state
    if (finalSongs.length >= 5) {
        addItem("Completionist Reward");
        setDataValue("completion_bonus_available", true);
    }
}

function onAfterGen() {
    // Called after everything is completely finished
    trace("onAfterGen callback: Generation complete for " + modName);
    
    // Final logging or cleanup operations
    if (hasDataValue("completion_bonus_available")) {
        trace("Completion bonus was added for " + modName);
    }
    
    trace("Total processing complete for " + modName);
}
