// Example HScript for Custom Archipelago Song Requirements
// This script demonstrates how to make certain songs require specific items to be accessible
// Place this file in your mod's /ap/ folder (e.g., mods/YourMod/ap/song_requirements.hx)

// Available functions for song requirements:
// - addSongRequirement(songName:String, targetMod:String, accessRule:APAccessRule, requireTargetMod:Bool = true)
// - addSimpleSongRequirement(songName:String, targetMod:String, requiredItems:Array<String>, requireTargetMod:Bool = true)
// - addSongRequirementWithCounts(songName:String, targetMod:String, requiredItems:Array<APRequiredItem>, requireTargetMod:Bool = true)
// - hasSongRequirement(songName:String, targetMod:String): Bool
// - getSongRequirement(songName:String, targetMod:String): APSongRequirement

trace("Setting up song requirements for mod: " + modName);

// Example 1: Simple song requirement (single item)
// Make "Boss Battle" song require the "Power Boost" item to be accessible
addSimpleSongRequirement("Boss Battle", null, ["Power Boost"]);

// Example 2: Multiple items required for a song
// Make "Final Boss" song require both "Magic Key" and "Super Shield" to be accessible
addSimpleSongRequirement("Final Boss", null, ["Magic Key", "Super Shield"]);

// Example 3: Song requirement with specific item counts
// Make "Ultimate Challenge" song require 3 "Energy Crystals" to be accessible
var ultimateRequirements = [
    { name: "Energy Crystal", count: 3 },
    { name: "Master Key", count: 1 }
];
addSongRequirementWithCounts("Ultimate Challenge", null, ultimateRequirements);

// Example 4: Cross-mod song requirement
// Make a song from another mod require items from this mod
if (isModEnabled("Other Mod")) {
    addSimpleSongRequirement("Cross Mod Song", "Other Mod", ["Special Item (${modFolderName})"]);
}

// Example 5: Base game song requirement
// Make a base game song require items from this mod
addSimpleSongRequirement("Roses", "", ["Thorns Protection"]);

// Example 6: Progressive song unlocking
// Create a chain of songs where each requires the previous + an item
addSimpleSongRequirement("Tutorial Plus", null, ["Basic Training"]);
addSimpleSongRequirement("Beginner Challenge", null, ["Basic Training", "Tutorial Plus Access"]);
addSimpleSongRequirement("Advanced Test", null, ["Basic Training", "Advanced Techniques"]);
addSimpleSongRequirement("Expert Trial", null, ["Basic Training", "Advanced Techniques", "Expert Knowledge"]);

// Example 7: Conditional song requirements based on player settings
var playerSettings = playerSettings.FNF; // Access to AP player settings
if (playerSettings && playerSettings.unlock_method == "Note Checks") {
    // If using note checks, make some songs require accuracy items
    addSimpleSongRequirement("Precision Song", null, ["Accuracy Boost", "Perfect Timing"]);
}

// Example 8: Adding items that songs will require
// These items should be created as normal AP items
addItem("Power Boost");
addItem("Magic Key");
addItem("Super Shield");
addItem("Energy Crystal");
addItem("Master Key");
addItem("Thorns Protection");
addItem("Basic Training");
addItem("Advanced Techniques");
addItem("Expert Knowledge");
addItem("Accuracy Boost");
addItem("Perfect Timing");

// Example 9: Creating locations that give the required items
// This creates a progression where players must complete certain challenges to unlock songs
addSimpleLocation("Training Completed", "tutorial", null, []); // Give "Basic Training" item here
addSimpleLocation("Power Core", "bopeebo", null, ["Basic Training"]); // Give "Power Boost" item here
addSimpleLocation("Magic Vault", "fresh", null, ["Power Boost"]); // Give "Magic Key" item here
addSimpleLocation("Shield Master", "dad-battle", null, ["Magic Key"]); // Give "Super Shield" item here

// You can also check if songs have requirements
if (hasSongRequirement("Boss Battle", null)) {
    trace("Boss Battle has access requirements");
    var requirement = getSongRequirement("Boss Battle", null);
    if (requirement != null) {
        trace("Boss Battle requires " + requirement.accessRule.requiredItems.length + " items");
    }
}

trace("Song requirements setup complete!");

// Note: The actual implementation of these requirements in the game client
// will depend on how the Archipelago integration handles song access.
// This system provides the logical requirements that can be used by:
// 1. The randomizer to determine when songs become accessible
// 2. The game client to lock/unlock songs based on received items
// 3. Progression logic to ensure proper item distribution
