package archipelago;

import archipelago.APInfo;
import archipelago.HighQualityTrapManager;
import backend.Mods;
import backend.Paths;
import backend.WeekData;
import hscript.Interp;
import hscript.Parser;
import sys.FileSystem;
import sys.io.File;

typedef APRequiredItem = {
    name: String,
    ?count: Int, // How many of this item are required (default 1)
    ?mod: String, // Optional mod name
    ?isTrap: Bool, // Whether this is a trap item (defaults to false)
    ?targetMod: String // Optional target mod for trap items
};

typedef APAccessRule = {
    requiredItems: Array<APRequiredItem> // All items are required (AND logic)
};

typedef APLocation = {
    name: String,
    originSong: String,
    targetMod: String, // Changed from originMod to targetMod
    accessRule: APAccessRule
};

// Song requirement structure - defines what items a song needs to be accessible
typedef APSongRequirement = {
    songName: String,
    targetMod: String, // Which mod the song belongs to (empty string = base game)
    accessRule: APAccessRule // What items are required to access this song
};

// Mod information structure
typedef ModInfo = {
    name: String,
    folderName: String,
    enabled: Bool,
    songList: Array<String>,
    settings: Map<String, Dynamic>, // Raw settings data from save
    options: Map<String, options.Option>, // Option objects for each setting
    // Add other mod-related info as needed
};

// Class to hold static arrays of items and locations
// Enhanced song addition structure with metadata
typedef APSongAddition = {
    name: String,
    targetMod: String,
    ?icon: String, // Optional icon name (defaults to 'face')
    ?color: Array<Int>, // Optional RGB color array (defaults to [146, 113, 253])
    ?difficulties: Array<String> // Optional difficulties list (lowercase, defaults to week's difficulties)
};

// Enhanced song exclusion structure
typedef APSongExclusion = {
    name: String,
    targetMod: String
};

// Enhanced custom week structure with metadata
typedef APCustomWeek = {
    name: String,
    songs: Array<String>,
    targetMod: String,
    ?difficulties: Array<String>, // Optional difficulties for the week (defaults to global difficulties)
    ?icon: String, // Optional default icon for songs in this week
    ?color: Array<Int>, // Optional default color for songs in this week
    ?songMetadata: Array<{name:String, ?icon:String, ?color:Array<Int>}> // Optional per-song metadata
};

// Error tracking structures
typedef APProcessingError = {
    modName: String,
    scriptPath: String,
    errorType: String, // "parsing", "execution", "validation", etc.
    errorMessage: String,
    timestamp: String
};

typedef APProcessingSuccess = {
    modName: String,
    scriptPath: String,
    itemsAdded: Int,
    locationsAdded: Int,
    songsAdded: Int,
    songsExcluded: Int,
    customWeeksAdded: Int,
    songRequirementsAdded: Int,
    customDataEntries: Int,
    timestamp: String
};

class APDataStore {
    public static var items:Array<APRequiredItem> = [];
    public static var locations:Array<APLocation> = [];
    public static var availableMods:Array<ModInfo> = [];
    public static var songAdditions:Array<APSongAddition> = [];
    public static var songExclusions:Array<APSongExclusion> = [];
    public static var customData:Map<String, Dynamic> = new Map<String, Dynamic>();
    public static var customWeeks:Array<APCustomWeek> = [];
    public static var songRequirements:Array<APSongRequirement> = [];

    // Error and success tracking
    public static var processingErrors:Array<APProcessingError> = [];
    public static var processingSuccesses:Array<APProcessingSuccess> = [];

    // Summary data for export info
    public static function getTotalCustomContent():Int {
        return items.length + locations.length + songAdditions.length +
               songExclusions.length + customWeeks.length + songRequirements.length +
               Lambda.count(customData);
    }

    // Clear all data including errors and successes
    public static function clearAll():Void {
        items = [];
        locations = [];
        songAdditions = [];
        songExclusions = [];
        customData = new Map<String, Dynamic>();
        customWeeks = [];
        songRequirements = [];
        processingErrors = [];
        processingSuccesses = [];
        availableMods = [];
    }
}

// HScript execution context for each mod
class APHScriptContext {
    public var modName:String;
    public var modFolderName:String;
    public var songList:Array<String>;
    public var items:Array<APRequiredItem>;
    public var locations:Array<APLocation>;
    public var availableMods:Array<ModInfo>;
    public var currentModSettings:Map<String, Dynamic>; // Current mod's raw settings
    public var currentModOptions:Map<String, options.Option>; // Current mod's Option objects

    // Song modification arrays (processed after script execution)
    public var excludedSongs:Array<String>;
    public var addedSongs:Array<String>;

    // Enhanced song modification tracking for Python generation
    public var songAdditions:Array<APSongAddition>;
    public var songExclusions:Array<APSongExclusion>;

    // Data storage for Python generation
    public var customData:Map<String, Dynamic>;

    // Enhanced custom week definitions
    public var customWeeks:Array<APCustomWeek>;

    // Song requirement tracking
    public var songRequirements:Array<APSongRequirement>;

    // Current script path being executed (for error reporting)
    public var currentScriptPath:String;

    // Helper function to record specific errors within this script context
    private function recordError(functionName:String, errorMessage:String, ?details:String):Void {
        var fullMessage = 'Function ${functionName}: ${errorMessage}';
        if (details != null && details != "") {
            fullMessage += ' - Details: ${details}';
        }

        var error:APProcessingError = {
            modName: modName,
            scriptPath: currentScriptPath != null ? currentScriptPath : modFolderName + '/ap/unknown.hx',
            errorType: "function_failure",
            errorMessage: fullMessage,
            timestamp: DateTools.format(Date.now(), "%Y-%m-%d %H:%M:%S")
        };
        APDataStore.processingErrors.push(error);
        trace('AP Script Error in ${modName}: ${fullMessage}');
    }

    public function new(modInfo:ModInfo, allMods:Array<ModInfo>) {
        this.modName = modInfo.name;
        this.modFolderName = modInfo.folderName;
        this.songList = modInfo.songList.copy();
        this.items = [];
        this.locations = [];
        this.availableMods = allMods.copy();
        this.currentModSettings = modInfo.settings.copy(); // Copy current mod's raw settings
        this.currentModOptions = modInfo.options.copy(); // Copy current mod's Option objects
        this.excludedSongs = [];
        this.addedSongs = [];
        this.songAdditions = [];
        this.songExclusions = [];
        this.customData = new Map<String, Dynamic>();
        this.customWeeks = [];
        this.songRequirements = [];
        this.currentScriptPath = null; // Will be set during script execution
    }

    // Helper function to check if a mod exists and is enabled
    public function isModEnabled(modName:String):Bool {
        // Empty or null mod name refers to base game (always enabled)
        if (modName == null || modName == "") {
            return true;
        }

        for (mod in availableMods) {
            if (mod.name == modName || mod.folderName == modName) {
                return mod.enabled;
            }
        }
        return false;
    }

    // Helper function to get mod info by name
    public function getModInfo(modName:String):ModInfo {
        // Empty or null mod name refers to base game
        if (modName == null || modName == "") {
            return {
                name: "",
                folderName: "",
                enabled: true,
                songList: [], // Base game songs would be handled separately
                settings: new Map<String, Dynamic>(), // Base game has no settings
                options: new Map<String, options.Option>() // Base game has no options
            };
        }

        for (mod in availableMods) {
            if (mod.name == modName || mod.folderName == modName) {
                return mod;
            }
        }
        return null;
    }

    // Mod settings helper functions (available in HScript)

    /**
     * Get a setting value from the current mod's settings (calls Option.getValue())
     * @param key The setting key to retrieve
     * @param defaultValue Default value if setting doesn't exist
     * @return The setting value or default value
     */
    public function getModSetting(key:String, ?defaultValue:Dynamic):Dynamic {
        if (currentModOptions.exists(key)) {
            var option = currentModOptions.get(key);
            return option.getValue();
        }
        return defaultValue;
    }

    /**
     * Check if a setting Option exists in the current mod
     * @param key The setting key to check
     * @return true if the Option exists, false otherwise
     */
    public function hasModSetting(key:String):Bool {
        return currentModOptions.exists(key);
    }

    /**
     * Get all available mod setting keys
     * @return Array of setting keys that have Option objects
     */
    public function getModSettingKeys():Array<String> {
        var keys:Array<String> = [];
        for (key in currentModOptions.keys()) {
            keys.push(key);
        }
        return keys;
    }

    /**
     * Get the number of mod settings
     * @return Number of Option objects
     */
    public function getModSettingCount():Int {
        var count = 0;
        for (key in currentModOptions.keys()) {
            count++;
        }
        return count;
    }

    /**
     * Get the Option object for a setting (for advanced access)
     * @param key The setting key
     * @return The Option object or null if not found
     */
    public function getModSettingOption(key:String):options.Option {
        return currentModOptions.get(key);
    }

    /**
     * Get the display name of a setting option
     * @param key The setting key
     * @return The display name or the key if option not found
     */
    public function getModSettingDisplayName(key:String):String {
        var option = currentModOptions.get(key);
        return option != null ? option.name : key;
    }

    /**
     * Get the description of a setting option
     * @param key The setting key
     * @return The description or empty string if option not found
     */
    public function getModSettingDescription(key:String):String {
        var option = currentModOptions.get(key);
        return option != null ? option.description : "";
    }

    /**
     * Get the type of a setting option
     * @param key The setting key
     * @return The OptionType as string or "UNKNOWN" if option not found
     */
    public function getModSettingType(key:String):String {
        var option = currentModOptions.get(key);
        if (option == null) return "UNKNOWN";
        return switch(option.type) {
            case BOOL: "BOOL";
            case INT: "INT";
            case FLOAT: "FLOAT";
            case PERCENT: "PERCENT";
            case STRING: "STRING";
            case KEYBIND: "KEYBIND";
            case LABEL: "LABEL";
        }
    }

    /**
     * Get the default value of a setting option
     * @param key The setting key
     * @return The default value or null if option not found
     */
    public function getModSettingDefaultValue(key:String):Dynamic {
        var option = currentModOptions.get(key);
        return option != null ? option.defaultValue : null;
    }

    /**
     * Get the minimum value of a numeric setting option
     * @param key The setting key
     * @return The minimum value or null if option not found or not numeric
     */
    public function getModSettingMinValue(key:String):Dynamic {
        var option = currentModOptions.get(key);
        return option != null ? option.minValue : null;
    }

    /**
     * Get the maximum value of a numeric setting option
     * @param key The setting key
     * @return The maximum value or null if option not found or not numeric
     */
    public function getModSettingMaxValue(key:String):Dynamic {
        var option = currentModOptions.get(key);
        return option != null ? option.maxValue : null;
    }

    /**
     * Get the available options for a STRING type setting
     * @param key The setting key
     * @return Array of available options or empty array if option not found
     */
    public function getModSettingOptions(key:String):Array<String> {
        var option = currentModOptions.get(key);
        return option != null && option.options != null ? option.options : [];
    }

    /**
     * Get a boolean setting value with proper type checking
     * @param key The setting key to retrieve
     * @param defaultValue Default value if setting doesn't exist (defaults to false)
     * @return The boolean setting value or default value
     */
    public function getBoolModSetting(key:String, defaultValue:Bool = false):Bool {
        var value = getModSetting(key, defaultValue);
        if (Std.isOfType(value, Bool)) {
            return cast(value, Bool);
        }
        return defaultValue;
    }

    /**
     * Get an integer setting value with proper type checking
     * @param key The setting key to retrieve
     * @param defaultValue Default value if setting doesn't exist (defaults to 0)
     * @return The integer setting value or default value
     */
    public function getIntModSetting(key:String, defaultValue:Int = 0):Int {
        var value = getModSetting(key, defaultValue);
        if (Std.isOfType(value, Int)) {
            return cast(value, Int);
        }
        if (Std.isOfType(value, Float)) {
            return Std.int(cast(value, Float));
        }
        return defaultValue;
    }

    /**
     * Get a float setting value with proper type checking
     * @param key The setting key to retrieve
     * @param defaultValue Default value if setting doesn't exist (defaults to 0.0)
     * @return The float setting value or default value
     */
    public function getFloatModSetting(key:String, defaultValue:Float = 0.0):Float {
        var value = getModSetting(key, defaultValue);
        if (Std.isOfType(value, Float)) {
            return cast(value, Float);
        }
        if (Std.isOfType(value, Int)) {
            return cast(value, Int);
        }
        return defaultValue;
    }

    /**
     * Get a string setting value with proper type checking
     * @param key The setting key to retrieve
     * @param defaultValue Default value if setting doesn't exist (defaults to "")
     * @return The string setting value or default value
     */
    public function getStringModSetting(key:String, defaultValue:String = ""):String {
        var value = getModSetting(key, defaultValue);
        if (value == null) {
            return defaultValue;
        }
        return Std.string(value);
    }

    // Add item function (available in HScript)
    public function addItem(name:String, ?requiredMod:String):Void {
        // Validate item name
        if (name == null || name.trim() == "") {
            recordError("addItem", "Item name cannot be null or empty", 'Attempted name: "${name}"');
            return;
        }

        // Empty or null mod name refers to base game (always available)
        if (requiredMod != null && requiredMod != "" && !isModEnabled(requiredMod)) {
            recordError("addItem", 'Cannot add item "${name}" - required mod "${requiredMod}" is not enabled or does not exist',
                       'Available mods: ${[for (mod in availableMods) if (mod.enabled) mod.name].join(", ")}');
            return;
        }

        // Check for duplicate items
        for (existingItem in items) {
            if (existingItem.name == name && existingItem.mod == requiredMod) {
                recordError("addItem", 'Duplicate item "${name}" already exists',
                           'Original mod: ${existingItem.mod}, Attempted mod: ${requiredMod}');
                return;
            }
        }

        var item:APRequiredItem = {
            name: name,
            isTrap: false
        };
        if (requiredMod != null && requiredMod != "") {
            item.mod = requiredMod;
        }
        // If requiredMod is null or empty, item.mod stays null (base game)

        items.push(item);
        APDataStore.items.push(item);
        trace('Successfully added item: ${name}' + (requiredMod != null && requiredMod != "" ? ' (mod: ${requiredMod})' : ' (base game)'));
    }

    // Add trap item function (available in HScript)
    public function addTrapItem(name:String, ?targetMod:String):Void {
        // Validate trap item name
        if (name == null || name.trim() == "") {
            recordError("addTrapItem", "Trap item name cannot be null or empty", 'Attempted name: "${name}"');
            return;
        }

        // Check for duplicate trap items
        for (existingItem in items) {
            if (existingItem.name == name && existingItem.isTrap == true && existingItem.targetMod == targetMod) {
                recordError("addTrapItem", 'Duplicate trap item "${name}" already exists',
                           'Original target mod: ${existingItem.targetMod}, Attempted target mod: ${targetMod}');
                return;
            }
        }

        // Target mod is optional for trap items and doesn't need to be validated for existence
        // since trap items can target mods that may not be currently enabled

        var item:APRequiredItem = {
            name: name,
            isTrap: true
        };
        if (targetMod != null && targetMod != "") {
            item.targetMod = targetMod;
        }

        items.push(item);
        APDataStore.items.push(item);
        trace('Successfully added trap item: ${name}' + (targetMod != null && targetMod != "" ? ' (target mod: ${targetMod})' : ' (no specific target)'));
    }

    // Add location function with boolean mod requirement (available in HScript)
    public function addLocation(name:String, originSong:String, ?targetMod:String, accessRule:APAccessRule, requireTargetMod:Bool = true):Void {
        // Validate location name
        if (name == null || name.trim() == "") {
            recordError("addLocation", "Location name cannot be null or empty", 'Attempted name: "${name}"');
            return;
        }

        // Validate origin song
        if (originSong == null || originSong.trim() == "") {
            recordError("addLocation", 'Location "${name}" has invalid origin song', 'Origin song cannot be null or empty');
            return;
        }

        // Validate access rule
        if (accessRule == null || accessRule.requiredItems == null) {
            recordError("addLocation", 'Location "${name}" has invalid access rule', 'Access rule or required items cannot be null');
            return;
        }

        // Use current mod as target if not specified
        if (targetMod == null) {
            targetMod = modFolderName;
        }

        // Validate access rule items
        for (i in 0...accessRule.requiredItems.length) {
            var reqItem = accessRule.requiredItems[i];
            if (reqItem == null || reqItem.name == null || reqItem.name.trim() == "") {
                recordError("addLocation", 'Location "${name}" has invalid required item at index ${i}',
                           'Required item name cannot be null or empty');
                return;
            }
        }

        // Check if the origin song is actually available in the target mod's song pool
        if (!isSongAvailableForGeneration(originSong, targetMod)) {
            recordError("addLocation", 'Cannot add location "${name}" - origin song "${originSong}" is not available in target mod "${targetMod}"',
                       'Available songs in ${targetMod}: ${getAvailableSongsInMod(targetMod).join(", ")}');
            return;
        }

        // Empty string means base game (always available)
        if (targetMod == "") {
            requireTargetMod = false; // Base game is always available
        }

        // If mod requirement is enabled and targetMod is not empty, check if the target mod exists and is enabled
        if (requireTargetMod && targetMod != "" && !isModEnabled(targetMod)) {
            recordError("addLocation", 'Cannot add location "${name}" - target mod "${targetMod}" is not enabled or does not exist',
                       'Available enabled mods: ${[for (mod in availableMods) if (mod.enabled) mod.name].join(", ")}');
            return;
        }

        // Check for duplicate locations
        var locationKey = name + '_' + originSong + '_' + targetMod;
        for (existingLocation in locations) {
            var existingKey = existingLocation.name + '_' + existingLocation.originSong + '_' + existingLocation.targetMod;
            if (existingKey == locationKey) {
                recordError("addLocation", 'Duplicate location "${name}" already exists',
                           'Origin song: ${originSong}, Target mod: ${targetMod}');
                return;
            }
        }

        var location:APLocation = {
            name: name + (' (' + (targetMod != null && targetMod != "" ? targetMod : modFolderName) + ')'),
            originSong: originSong,
            targetMod: targetMod,
            accessRule: accessRule
        };

        locations.push(location);
        APDataStore.locations.push(location);
        trace('Successfully added location: ${name} (song: ${originSong}, mod: ${targetMod}, requires: ${accessRule.requiredItems.length} items)');
    }

    // Helper function to get available songs in a mod for error reporting
    private function getAvailableSongsInMod(targetMod:String):Array<String> {
        var songs:Array<String> = [];

        if (targetMod == null || targetMod == "") {
            // Base game songs
            songs = songs.concat(APInfo.baseGame);
            songs = songs.concat(APInfo.baseErect);
            songs = songs.concat(APInfo.basePico);
            songs = songs.concat(APInfo.secrets);
        } else {
            // Mod songs
            var modInfo = getModInfo(targetMod);
            if (modInfo != null) {
                songs = modInfo.songList.copy();
            }
        }

        // Add songs that were added via addSong
        for (addition in songAdditions) {
            if (addition.targetMod == targetMod && !songs.contains(addition.name)) {
                songs.push(addition.name);
            }
        }

        // Remove songs that were excluded via excludeSong
        for (exclusion in songExclusions) {
            if (exclusion.targetMod == targetMod) {
                songs.remove(exclusion.name);
            }
        }

        return songs;
    }

    // Simple location helper (available in HScript)
    public function addSimpleLocation(name:String, originSong:String, ?targetMod:String, requiredItems:Array<String>, requireTargetMod:Bool = true):Void {
        var rule:APAccessRule = {
            requiredItems: [for (item in requiredItems) { name: item, count: 1 }]
        };
        addLocation(name, originSong, targetMod, rule, requireTargetMod);
    }

    // Location with item counts helper (available in HScript)
    public function addLocationWithCounts(name:String, originSong:String, ?targetMod:String, requiredItems:Array<APRequiredItem>, requireTargetMod:Bool = true):Void {
        var rule:APAccessRule = {
            requiredItems: requiredItems
        };
        addLocation(name, originSong, targetMod, rule, requireTargetMod);
    }

    // Song requirement functions (available in HScript)
    public function addSongRequirement(songName:String, ?targetMod:String, accessRule:APAccessRule, requireTargetMod:Bool = true):Void {
        // Validate song name
        if (songName == null || songName.trim() == "") {
            recordError("addSongRequirement", "Song name cannot be null or empty", 'Attempted song name: "${songName}"');
            return;
        }

        // Use current mod as target if not specified
        if (targetMod == null) {
            targetMod = modFolderName;
        }

        // Validate access rule
        if (accessRule == null || accessRule.requiredItems == null) {
            recordError("addSongRequirement", 'Song requirement for "${songName}" has invalid access rule',
                       'Access rule or required items cannot be null');
            return;
        }

        // Validate each required item in the access rule
        for (i in 0...accessRule.requiredItems.length) {
            var reqItem = accessRule.requiredItems[i];
            if (reqItem == null || reqItem.name == null || reqItem.name.trim() == "") {
                recordError("addSongRequirement", 'Song requirement for "${songName}" has invalid required item at index ${i}',
                           'Required item name cannot be null or empty');
                return;
            }
            if (reqItem.count == null || reqItem.count < 1) {
                recordError("addSongRequirement", 'Song requirement for "${songName}" has invalid count for item "${reqItem.name}"',
                           'Count must be at least 1, got: ${reqItem.count}');
                return;
            }
        }

        // Empty string means base game (always available)
        if (targetMod == "") {
            requireTargetMod = false; // Base game is always available
        }

        // If mod requirement is enabled and targetMod is not empty, check if the target mod exists and is enabled
        if (requireTargetMod && targetMod != "" && !isModEnabled(targetMod)) {
            recordError("addSongRequirement", 'Cannot add song requirement for "${songName}" - target mod "${targetMod}" is not enabled or does not exist',
                       'Available enabled mods: ${[for (mod in availableMods) if (mod.enabled) mod.name].join(", ")}');
            return;
        }

        // Check if the song is actually available in the target mod during generation
        if (!isSongAvailableForGeneration(songName, targetMod)) {
            recordError("addSongRequirement", 'Cannot add song requirement for "${songName}" - song is not available in target mod "${targetMod}"',
                       'Available songs in ${targetMod}: ${getAvailableSongsInMod(targetMod).join(", ")}');
            return;
        }

        // Check for duplicate requirements (only within this mod's context)
        var requirementKey = songName + '_' + targetMod;
        for (existingReq in songRequirements) {
            var existingKey = existingReq.songName + '_' + existingReq.targetMod;
            if (existingKey == requirementKey) {
                recordError("addSongRequirement", 'Duplicate song requirement for "${songName}" already exists',
                           'Target mod: ${targetMod}');
                return;
            }
        }

        var songRequirement:APSongRequirement = {
            songName: songName,
            targetMod: targetMod,
            accessRule: accessRule
        };

        songRequirements.push(songRequirement);
        APDataStore.songRequirements.push(songRequirement);
        trace('Successfully added song requirement: "${songName}" in mod "${targetMod}" requires ${accessRule.requiredItems.length} items');
    }

    // Simple song requirement helper (available in HScript)
    public function addSimpleSongRequirement(songName:String, ?targetMod:String, requiredItems:Array<String>, requireTargetMod:Bool = true):Void {
        var rule:APAccessRule = {
            requiredItems: [for (item in requiredItems) { name: item, count: 1 }]
        };
        addSongRequirement(songName, targetMod, rule, requireTargetMod);
    }

    // Song requirement with item counts helper (available in HScript)
    public function addSongRequirementWithCounts(songName:String, ?targetMod:String, requiredItems:Array<APRequiredItem>, requireTargetMod:Bool = true):Void {
        var rule:APAccessRule = {
            requiredItems: requiredItems
        };
        addSongRequirement(songName, targetMod, rule, requireTargetMod);
    }

    // Helper to check if a song has requirements
    public function hasSongRequirement(songName:String, ?targetMod:String):Bool {
        if (targetMod == null) {
            targetMod = modFolderName;
        }

        for (requirement in songRequirements) {
            if (requirement.songName == songName && requirement.targetMod == targetMod) {
                return true;
            }
        }

        return false;
    }

    // Helper to get song requirements
    public function getSongRequirement(songName:String, ?targetMod:String):APSongRequirement {
        if (targetMod == null) {
            targetMod = modFolderName;
        }

        for (requirement in songRequirements) {
            if (requirement.songName == songName && requirement.targetMod == targetMod) {
                return requirement;
            }
        }

        return null;
    }

    // Song modification functions (available in HScript)
    public function excludeSong(songName:String, ?targetMod:String):Void {
        // Validate song name
        if (songName == null || songName.trim() == "") {
            recordError("excludeSong", "Song name cannot be null or empty", 'Attempted song name: "${songName}"');
            return;
        }

        // Use current mod as default target if not specified
        if (targetMod == null) {
            targetMod = modName;
        }

        // Validate target mod if specified
        if (targetMod != "" && !isModEnabled(targetMod)) {
            recordError("excludeSong", 'Cannot exclude song "${songName}" - target mod "${targetMod}" is not enabled or does not exist',
                       'Available enabled mods: ${[for (mod in availableMods) if (mod.enabled) mod.name].join(", ")}');
            return;
        }

        // Check if the song actually exists in the target mod
        if (!isSongAvailableForGeneration(songName, targetMod)) {
            recordError("excludeSong", 'Cannot exclude song "${songName}" - song is not available in target mod "${targetMod}"',
                       'Available songs in ${targetMod}: ${getAvailableSongsInMod(targetMod).join(", ")}');
            return;
        }

        var formattedName = songName + (if (targetMod != null && targetMod != "") '(${targetMod})' else "");

        // Check for duplicates
        if (excludedSongs.contains(formattedName)) {
            recordError("excludeSong", 'Song "${songName}" is already excluded',
                       'Target mod: ${targetMod}');
            return;
        }

        excludedSongs.push(formattedName);
        songExclusions.push({name: songName, targetMod: targetMod});
        APDataStore.songExclusions.push({name: songName, targetMod: targetMod});
        trace('Successfully excluded song: ${songName} from mod ${targetMod}');
    }

    public function addSong(songName:String, ?targetMod:String, ?icon:String, ?color:Array<Int>, ?difficulties:Array<String>):Void {
        // Validate song name
        if (songName == null || songName.trim() == "") {
            recordError("addSong", "Song name cannot be null or empty", 'Attempted song name: "${songName}"');
            return;
        }

        // Use current mod as default target if not specified
        if (targetMod == null) {
            targetMod = modFolderName;
        }

        // Validate target mod if specified
        if (targetMod != "" && !isModEnabled(targetMod)) {
            recordError("addSong", 'Cannot add song "${songName}" - target mod "${targetMod}" is not enabled or does not exist',
                       'Available enabled mods: ${[for (mod in availableMods) if (mod.enabled) mod.name].join(", ")}');
            return;
        }

        // Validate difficulties if provided
        if (difficulties != null) {
            for (i in 0...difficulties.length) {
                var diff = difficulties[i];
                if (diff == null || diff.trim() == "") {
                    recordError("addSong", 'Song "${songName}" has invalid difficulty at index ${i}',
                               'Difficulty name cannot be null or empty');
                    return;
                }
            }
        }

        // Validate color if provided
        if (color != null && color.length != 3) {
            recordError("addSong", 'Song "${songName}" has invalid color array',
                       'Color must be an array of 3 integers [R, G, B], got: ${color}');
            return;
        }

        var formattedName = songName + (if (targetMod != null && targetMod != "") '(${targetMod})' else "");

        // Check for duplicates
        if (addedSongs.contains(formattedName)) {
            recordError("addSong", 'Duplicate song "${songName}" already added',
                       'Target mod: ${targetMod}');
            return;
        }

        addedSongs.push(formattedName);

        // Create enhanced song addition with metadata
        var songAddition:APSongAddition = {
            name: songName,
            targetMod: targetMod
        };

        if (icon != null) songAddition.icon = icon;
        if (color != null) songAddition.color = color;
        if (difficulties != null) {
            // Convert to lowercase for consistency
            songAddition.difficulties = [for (diff in difficulties) diff.toLowerCase()];
        }

        songAdditions.push(songAddition);
        APDataStore.songAdditions.push(songAddition);
        trace('Successfully added song: ${songName} to mod ${targetMod}' +
              (icon != null ? ' with icon: ${icon}' : '') +
              (color != null ? ' with color: ${color}' : '') +
              (difficulties != null ? ' with difficulties: ${difficulties}' : ''));
    }

    // Helper to exclude multiple songs at once
    public function excludeSongs(songNames:Array<String>, ?targetMod:String):Void {
        for (song in songNames) {
            excludeSong(song, targetMod);
        }
    }

    // Helper to add multiple songs at once with individual metadata
    public function addSongs(songNames:Array<String>, ?targetMod:String, ?icon:String, ?color:Array<Int>, ?difficulties:Array<String>):Void {
        for (song in songNames) {
            addSong(song, targetMod, icon, color, difficulties);
        }
    }

    // Enhanced function to add songs with different metadata for each
    public function addSongsWithMetadata(songs:Array<{name:String, ?icon:String, ?color:Array<Int>, ?difficulties:Array<String>}>, ?targetMod:String):Void {
        for (songData in songs) {
            addSong(songData.name, targetMod, songData.icon, songData.color, songData.difficulties);
        }
    }

    // Get the final processed song list (after exclusions and additions)
    public function getFinalSongList():Array<String> {
        var finalList = songList.copy();

        // Remove excluded songs
        for (excludedSong in excludedSongs) {
            finalList.remove(excludedSong);
        }

        // Add new songs (if not already present)
        for (addedSong in addedSongs) {
            if (!finalList.contains(addedSong)) {
                finalList.push(addedSong);
            }
        }

        return finalList;
    }

    // Data storage functions (available in HScript)
    public function setDataValue(key:String, value:Dynamic):Void {
        customData.set(key, value);
        APDataStore.customData.set(key, value);
        trace('Set data: ${key} = ${value}');
    }

    public function getDataValue(key:String, ?defaultValue:Dynamic):Dynamic {
        if (customData.exists(key)) {
            return customData.get(key);
        }
        return defaultValue;
    }

    public function hasDataValue(key:String):Bool {
        return customData.exists(key);
    }

    // Enhanced custom week definition functions (available in HScript)
    public function defineCustomWeek(weekName:String, songs:Array<String>, ?targetMod:String, ?difficulties:Array<String>, ?icon:String, ?color:Array<Int>):Void {
        // Validate week name
        if (weekName == null || weekName.trim() == "") {
            recordError("defineCustomWeek", "Week name cannot be null or empty", 'Attempted week name: "${weekName}"');
            return;
        }

        // Validate songs array
        if (songs == null || songs.length == 0) {
            recordError("defineCustomWeek", 'Custom week "${weekName}" has no songs',
                       'Songs array cannot be null or empty');
            return;
        }

        // Validate each song in the array
        for (i in 0...songs.length) {
            var songName = songs[i];
            if (songName == null || songName.trim() == "") {
                recordError("defineCustomWeek", 'Custom week "${weekName}" has invalid song at index ${i}',
                           'Song name cannot be null or empty');
                return;
            }
        }

        // Use current mod as default target if not specified
        if (targetMod == null) {
            targetMod = modName;
        }

        // Validate target mod if specified
        if (targetMod != "" && !isModEnabled(targetMod)) {
            recordError("defineCustomWeek", 'Cannot define custom week "${weekName}" - target mod "${targetMod}" is not enabled or does not exist',
                       'Available enabled mods: ${[for (mod in availableMods) if (mod.enabled) mod.name].join(", ")}');
            return;
        }

        // Validate difficulties if provided
        if (difficulties != null) {
            for (i in 0...difficulties.length) {
                var diff = difficulties[i];
                if (diff == null || diff.trim() == "") {
                    recordError("defineCustomWeek", 'Custom week "${weekName}" has invalid difficulty at index ${i}',
                               'Difficulty name cannot be null or empty');
                    return;
                }
            }
        }

        // Validate color if provided
        if (color != null && color.length != 3) {
            recordError("defineCustomWeek", 'Custom week "${weekName}" has invalid color array',
                       'Color must be an array of 3 integers [R, G, B], got: ${color}');
            return;
        }

        // Check for duplicate week names
        for (existingWeek in customWeeks) {
            if (existingWeek.name == weekName && existingWeek.targetMod == targetMod) {
                recordError("defineCustomWeek", 'Duplicate custom week "${weekName}" already exists',
                           'Target mod: ${targetMod}');
                return;
            }
        }

        var customWeek:APCustomWeek = {
            name: weekName,
            songs: songs.copy(),
            targetMod: targetMod
        };

        // Add optional metadata
        if (difficulties != null) {
            // Convert to lowercase for consistency
            customWeek.difficulties = [for (diff in difficulties) diff.toLowerCase()];
        }
        if (icon != null) customWeek.icon = icon;
        if (color != null) customWeek.color = color;

        customWeeks.push(customWeek);
        APDataStore.customWeeks.push(customWeek);
        trace('Successfully defined custom week: ${weekName} with ${songs.length} songs for mod ${targetMod}' +
              (difficulties != null ? ' with difficulties: ${difficulties}' : '') +
              (icon != null ? ' with default icon: ${icon}' : '') +
              (color != null ? ' with default color: ${color}' : ''));
    }

    // Enhanced custom week definition with per-song metadata
    public function defineCustomWeekWithSongMetadata(weekName:String, songData:Array<{name:String, ?icon:String, ?color:Array<Int>}>, ?targetMod:String, ?difficulties:Array<String>):Void {
        // Use current mod as default target if not specified
        if (targetMod == null) {
            targetMod = modName;
        }

        // Validate week name
        if (weekName == null || weekName.trim() == "") {
            var errorMsg = 'Invalid custom week name: Week name cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        // Validate song data array
        if (songData == null || songData.length == 0) {
            var errorMsg = 'Invalid custom week song data: Song data array cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        // Extract song names for the basic week structure
        var songs:Array<String> = [for (song in songData) song.name];

        var customWeek:APCustomWeek = {
            name: weekName,
            songs: songs,
            targetMod: targetMod,
            songMetadata: songData.copy() // Store individual song metadata
        };

        // Add optional week-level metadata
        if (difficulties != null) {
            // Convert to lowercase for consistency
            customWeek.difficulties = [for (diff in difficulties) diff.toLowerCase()];
        }

        customWeeks.push(customWeek);
        APDataStore.customWeeks.push(customWeek);
        trace('Defined custom week with song metadata: ${weekName} with ${songs.length} songs for mod ${targetMod}' +
              (difficulties != null ? ' with difficulties: ${difficulties}' : ''));
    }

    public function supportsCustomWeeks():Bool {
        // Custom weeks are always supported in the current implementation
        return true;
    }

    // Generation-time validation functions (for use during HScript processing)

    /**
     * Validate that an origin song exists and is valid for location creation during generation time
     * @param originSong The song name to validate
     * @param locationName The location name for error reporting
     * @param targetMod The target mod to check the song in (null/empty = base game)
     */
    public function validateOriginSongForGeneration(originSong:String, locationName:String = "", targetMod:String = null):Void {
        if (originSong == null || originSong.trim() == "") {
            var errorMsg = 'Invalid origin song for location "${locationName}": Origin song cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        // Check if the song exists in the target mod (targetMod passed as-is)
        if (!isSongAvailableForGeneration(originSong, targetMod)) {
            var modDescription = (targetMod == null || targetMod == "") ? "base game" : targetMod;
            var errorMsg = 'Invalid origin song for location "${locationName}": Origin song "${originSong}" not found in ${modDescription}';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }
    }

    /**
     * Check if a song is available in the specified mod during generation time
     * @param songName The song name to check
     * @param targetMod The target mod to check (null/empty = base game)
     * @return true if the song is available, false otherwise
     */
    public function isSongAvailableForGeneration(songName:String, targetMod:String = null):Bool {
        if (songName == null || songName.trim() == "") {
            return false;
        }

        // Check base game songs (empty string means base game)
        if (targetMod == null || targetMod == "") {
            // First check if this base song was excluded
            for (exclusion in songExclusions) {
                if (exclusion.name == songName && (exclusion.targetMod == null || exclusion.targetMod == "")) {
                    return false; // Base game song was explicitly excluded
                }
            }

            // Check if it's a base game song
            var isBase = isBaseSong(songName);
            if (isBase) {
                return true;
            }

            // Check if song was added to base game via addSong
            for (addition in songAdditions) {
                if (addition.name == songName && (addition.targetMod == null || addition.targetMod == "")) {
                    return true;
                }
            }

            return false; // Not found in base game
        }

        // Check if the target mod exists and is enabled
        var targetModInfo = getModInfo(targetMod);
        if (targetModInfo == null) {
            return false; // Target mod doesn't exist
        }

        if (!targetModInfo.enabled) {
            return false; // Target mod is disabled
        }

        // First check if song was excluded from this mod via excludeSong
        for (exclusion in songExclusions) {
            if (exclusion.name == songName && exclusion.targetMod == targetMod) {
                return false; // Song was explicitly excluded
            }
        }

        // Check if song exists in the target mod's original song list
        for (modSong in targetModInfo.songList) {
            if (modSong == songName) {
                return true;
            }
        }

        // Check if song was added to this mod via addSong
        for (addition in songAdditions) {
            if (addition.name == songName && addition.targetMod == targetMod) {
                return true;
            }
        }

        return false; // Song not found in target mod
    }

    /**
     * Check if a song is a base game song
     * @param songName The song name to check
     * @return true if it's a base game song, false otherwise
     */
    public function isBaseSong(songName:String):Bool {
        if (songName == null || songName.trim() == "") {
            return false;
        }

        // Access base song arrays from APInfo
        var allBaseSongs = APInfo.baseGame.concat(APInfo.baseErect).concat(APInfo.basePico).concat(APInfo.secrets);

        for (baseSong in allBaseSongs) {
            if (baseSong.toLowerCase() == songName.toLowerCase()) {
                return true;
            }
        }

        return false;
    }
}

// Main HScript processor
class APHScriptProcessor {
    public static function loadModData():Array<ModInfo> {
        var mods:Array<ModInfo> = [];

        #if MODS_ALLOWED
        // Get mod list from the Mods class
        var modsList = Mods.parseList();

        // Load enabled mods
        for (modFolder in modsList.enabled) {
            var modInfo = createModInfo(modFolder, true);
            if (modInfo != null) {
                mods.push(modInfo);
            }
        }

        // Load disabled mods (for reference but marked as disabled)
        for (modFolder in modsList.disabled) {
            var modInfo = createModInfo(modFolder, false);
            if (modInfo != null) {
                mods.push(modInfo);
            }
        }
        #end

        return mods;
    }

    static function createModInfo(folderName:String, enabled:Bool):ModInfo {
        #if MODS_ALLOWED
        var modPath = Paths.mods(folderName);
        if (!FileSystem.exists(modPath) || !FileSystem.isDirectory(modPath)) {
            return null;
        }

        // Get mod pack info
        var pack = Mods.getPack(folderName);
        var modName = folderName; // Default to folder name
        if (pack != null && pack.name != null) {
            modName = pack.name;
        }

        // Get song list for this mod
        var songList = getModSongList(folderName);

        // Load mod settings
        var modSettings = loadModSettings(folderName);

        // Load mod options (create Option objects like ModSettingsSubState)
        var modOptions = loadModOptions(folderName, modSettings);

        return {
            name: modName,
            folderName: folderName,
            enabled: enabled,
            songList: songList,
            settings: modSettings,
            options: modOptions
        };
        #else
        return null;
        #end
    }

    /**
     * Load mod settings from save data
     * @param modFolder The mod folder name
     * @return Map containing mod settings
     */
    static function loadModSettings(modFolder:String):Map<String, Dynamic> {
        var settings = new Map<String, Dynamic>();

        #if MODS_ALLOWED
        try {
            // Load mod settings exactly like ModSettingsSubState does
            if (FlxG.save.data.modSettings == null) {
                FlxG.save.data.modSettings = new Map<String, Dynamic>();
            } else {
                var saveMap:Map<String, Dynamic> = FlxG.save.data.modSettings;
                var modSaveData = saveMap[modFolder];
                if (modSaveData != null) {
                    // The save data contains the raw values, but we need to access them like Option objects do
                    // Copy the save data directly - these are the actual setting values
                    if (modSaveData.isMap()) {
                        var modMap:Map<String, Dynamic> = cast modSaveData;
                        for (key in modMap.keys()) {
                            settings.set(key, modMap.get(key));
                        }
                    } else {
                        // Handle case where it might be stored as a dynamic object
                        var fields = Reflect.fields(modSaveData);
                        for (field in fields) {
                            settings.set(field, Reflect.field(modSaveData, field));
                        }
                    }
                }
            }

        } catch (e:Dynamic) {
            trace('Error loading settings for mod ${modFolder}: ${e}');
        }
        #end

        return settings;
    }

    /**
     * Load mod options and create Option objects like ModSettingsSubState does
     * @param modFolder The mod folder name
     * @param save The mod's save data
     * @return Map containing Option objects
     */
    static function loadModOptions(modFolder:String, save:Map<String, Dynamic>):Map<String, options.Option> {
        var options = new Map<String, options.Option>();

        #if MODS_ALLOWED
        try {
            // Try to load the mod's options definition file
            var optionsPath = Paths.mods(modFolder + '/data/settings.json');
            if (FileSystem.exists(optionsPath)) {
                var optionsContent = File.getContent(optionsPath);
                var optionsData:Array<Dynamic> = haxe.Json.parse(optionsContent);

                if (optionsData != null) {
                    // Create Option objects like ModSettingsSubState does
                    for (optionData in optionsData) {
                        var newOption = new options.Option(
                            optionData.name != null ? optionData.name : optionData.save,
                            optionData.description != null ? optionData.description : 'No description provided.',
                            optionData.save,
                            convertOptionType(optionData.type),
                            optionData.options,
                            optionData.translation_key
                        );

                        // Set up the option like ModSettingsSubState does
                        switch(newOption.type) {
                            case KEYBIND:
                                // Handle keybind setup
                                var keyboardStr:String = optionData.keyboard;
                                var gamepadStr:String = optionData.gamepad;
                                if(keyboardStr == null) keyboardStr = 'NONE';
                                if(gamepadStr == null) gamepadStr = 'NONE';

                                newOption.defaultKeys.keyboard = keyboardStr;
                                newOption.defaultKeys.gamepad = gamepadStr;

                                @:privateAccess {
                                    newOption.getValue = function() {
                                        var data = save.get(newOption.variable);
                                        if(data == null) return 'NONE';
                                        return !backend.Controls.instance.controllerMode ? data.keyboard : data.gamepad;
                                    };
                                    newOption.setValue = function(value:Dynamic) {
                                        var data = save.get(newOption.variable);
                                        if(data == null) data = {keyboard: 'NONE', gamepad: 'NONE'};

                                        if(!backend.Controls.instance.controllerMode) data.keyboard = value;
                                        else data.gamepad = value;
                                        save.set(newOption.variable, data);
                                    };
                                }

                            default:
                                if(optionData.value != null)
                                    newOption.defaultValue = optionData.value;

                                @:privateAccess {
                                    newOption.getValue = function() return save.get(newOption.variable);
                                    newOption.setValue = function(value:Dynamic) save.set(newOption.variable, value);
                                }
                        }

                        // Set option properties like ModSettingsSubState does
                        if(optionData.type != "KEYBIND") {
                            if(optionData.format != null) newOption.displayFormat = optionData.format;
                            if(optionData.min != null) newOption.minValue = optionData.min;
                            if(optionData.max != null) newOption.maxValue = optionData.max;
                            if(optionData.step != null) newOption.changeValue = optionData.step;
                            if(optionData.scroll != null) newOption.scrollSpeed = optionData.scroll;
                            if(optionData.decimals != null) newOption.decimals = optionData.decimals;

                            // Set initial value
                            var myValue:Dynamic = null;
                            if(save.get(optionData.save) != null) {
                                myValue = save.get(optionData.save);
                                if(newOption.type != KEYBIND) newOption.setValue(myValue);
                            } else {
                                myValue = newOption.getValue();
                                if(myValue == null) myValue = newOption.defaultValue;
                            }

                            switch(newOption.type) {
                                case STRING:
                                    var num:Int = newOption.options.indexOf(myValue);
                                    if(num > -1) newOption.curOption = num;
                                default:
                            }

                            save.set(optionData.save, myValue);
                        }

                        options.set(optionData.save, newOption);
                    }
                }
            }
        } catch (e:Dynamic) {
            trace('Error loading options for mod ${modFolder}: ${e}');
        }
        #end

        return options;
    }

    /**
     * Convert string option type to OptionType enum (like ModSettingsSubState does)
     */
    static function convertOptionType(str:String):options.Option.OptionType {
        switch(str.toLowerCase().trim()) {
            case 'bool':
                return BOOL;
            case 'int', 'integer':
                return INT;
            case 'float', 'fl':
                return FLOAT;
            case 'percent':
                return PERCENT;
            case 'string', 'str':
                return STRING;
            case 'keybind', 'key':
                return KEYBIND;
        }
        return BOOL;
    }

    static function getModSongList(modFolder:String):Array<String> {
        var songs:Array<String> = [];

        #if MODS_ALLOWED
        // Use the proper WeekData system to get songs from the mod
        // This ensures we use the same logic as the rest of the engine
        for (i in 0...WeekData.weeksList.length) {
            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

            // Check if this week belongs to the specified mod
            if (leWeek != null && leWeek.folder == modFolder) {
                // Add all songs from this week
                for (song in leWeek.songs) {
                    var songName = song[0]; // Song name is the first element
                    if (!songs.contains(songName)) {
                        songs.push(songName);
                    }
                }
            }
        }
        #end

        return songs;
    }

    public static function processAllMods():Void {
        // Clear existing data using the new centralized method
        APDataStore.clearAll();

        // Initialize High Quality Trap Manager
        HighQualityTrapManager.initialize();

        // Add the High Quality Trap item to the global pool
        var highQualityTrapItem:APRequiredItem = {
            name: "High Quality Trap",
            isTrap: true,
            targetMod: "base-game" // Can affect any mod
        };
        APDataStore.items.push(highQualityTrapItem);

        // Load available mods
        var availableMods = loadModData();
        APDataStore.availableMods = availableMods;

        // Process each enabled mod
        for (mod in availableMods) {
            if (mod.enabled) {
                processModScripts(mod, availableMods);
            }
        }
    }

    public static function processModScripts(modInfo:ModInfo, allMods:Array<ModInfo>):Void {
        var apPath = 'mods/${modInfo.folderName}/ap/';

        if (!FileSystem.exists(apPath) || !FileSystem.isDirectory(apPath)) {
            return; // No AP folder, skip this mod
        }

        trace('Processing AP scripts for mod: ${modInfo.name}');

        // Get all .hx files in the ap folder
        var scripts = [];
        for (file in FileSystem.readDirectory(apPath)) {
            if (file.endsWith('.hx')) {
                scripts.push(apPath + file);
            }
        }

        // Process each script
        for (scriptPath in scripts) {
            try {
                executeHScript(scriptPath, modInfo, allMods);
            } catch (e:Dynamic) {
                trace('Error executing AP script ${scriptPath}: ${e}');

                // Record error for scripts that fail during execution
                var error:APProcessingError = {
                    modName: modInfo.name,
                    scriptPath: scriptPath,
                    errorType: "execution",
                    errorMessage: Std.string(e),
                    timestamp: DateTools.format(Date.now(), "%Y-%m-%d %H:%M:%S")
                };
                APDataStore.processingErrors.push(error);
            }
        }
    }

    public static function executeHScript(scriptPath:String, modInfo:ModInfo, allMods:Array<ModInfo>):Void {
        if (!FileSystem.exists(scriptPath)) {
            trace('AP script not found: ${scriptPath}');
            return;
        }

        trace('Executing AP script: ${scriptPath} for mod: ${modInfo.name}');

        var scriptContent = File.getContent(scriptPath);
        var parser = new Parser();
        var interpreter = new Interp();

        // Create context for this mod
        var context = new APHScriptContext(modInfo, allMods);

        // Set the current script path for error reporting
        context.currentScriptPath = scriptPath;

        // Set up interpreter variables and functions
        interpreter.variables.set("modName", context.modName);
        interpreter.variables.set("modFolderName", context.modFolderName);
        interpreter.variables.set("songList", context.songList);
        interpreter.variables.set("availableMods", context.availableMods);

        // Add player settings access
        interpreter.variables.set("playerSettings", archipelago.APEntryState.gameSettings.FNF);

        // Add mod settings access
        interpreter.variables.set("currentModSettings", context.currentModSettings);
        interpreter.variables.set("currentModOptions", context.currentModOptions);

        function addModItem(name:String, ?mod:String)
        {
            if (name != null || name.trim() != "") {
                context.addItem(name + (' (${context.modFolderName})'), mod);
            } else {
                trace('Invalid item name for mod: ${context.modFolderName}');
                throw new haxe.Exception('Invalid Mod Item in mod ${context.modFolderName}');
            }
        }

        function addModTrap(name:String, ?mod:String)
        {
            if (name == null || name.trim() == "") {
                trace('Invalid trap item name for mod: ${context.modFolderName}');
                throw new haxe.Exception('Invalid Mod Trap Item in mod ${context.modFolderName}');
            }
            context.addTrapItem(name + (' (${context.modFolderName})'), mod);
        }



        // Add helper functions
        interpreter.variables.set("addItem", addModItem);
        interpreter.variables.set("addTrapItem", addModTrap);
        interpreter.variables.set("addLocation", context.addLocation);
        interpreter.variables.set("addSimpleLocation", context.addSimpleLocation);
        interpreter.variables.set("addLocationWithCounts", context.addLocationWithCounts);
        interpreter.variables.set("isModEnabled", context.isModEnabled);
        interpreter.variables.set("getModInfo", context.getModInfo);

        // Add mod settings helper functions
        interpreter.variables.set("getModSetting", context.getModSetting);
        interpreter.variables.set("hasModSetting", context.hasModSetting);
        interpreter.variables.set("getModSettingKeys", context.getModSettingKeys);
        interpreter.variables.set("getModSettingCount", context.getModSettingCount);
        interpreter.variables.set("getModSettingOption", context.getModSettingOption);
        interpreter.variables.set("getModSettingDisplayName", context.getModSettingDisplayName);
        interpreter.variables.set("getModSettingDescription", context.getModSettingDescription);
        interpreter.variables.set("getModSettingType", context.getModSettingType);
        interpreter.variables.set("getModSettingDefaultValue", context.getModSettingDefaultValue);
        interpreter.variables.set("getModSettingMinValue", context.getModSettingMinValue);
        interpreter.variables.set("getModSettingMaxValue", context.getModSettingMaxValue);
        interpreter.variables.set("getModSettingOptions", context.getModSettingOptions);
        interpreter.variables.set("getBoolModSetting", context.getBoolModSetting);
        interpreter.variables.set("getIntModSetting", context.getIntModSetting);
        interpreter.variables.set("getFloatModSetting", context.getFloatModSetting);
        interpreter.variables.set("getStringModSetting", context.getStringModSetting);

        // Add enhanced song modification functions
        interpreter.variables.set("excludeSong", context.excludeSong);
        interpreter.variables.set("addSong", context.addSong);
        interpreter.variables.set("excludeSongs", context.excludeSongs);
        interpreter.variables.set("addSongs", context.addSongs);
        interpreter.variables.set("addSongsWithMetadata", context.addSongsWithMetadata);
        interpreter.variables.set("getFinalSongList", context.getFinalSongList);

        // Add song requirement functions
        interpreter.variables.set("addSongRequirement", context.addSongRequirement);
        interpreter.variables.set("addSimpleSongRequirement", context.addSimpleSongRequirement);
        interpreter.variables.set("addSongRequirementWithCounts", context.addSongRequirementWithCounts);
        interpreter.variables.set("hasSongRequirement", context.hasSongRequirement);
        interpreter.variables.set("getSongRequirement", context.getSongRequirement);

        // Add data storage functions
        interpreter.variables.set("setDataValue", context.setDataValue);
        interpreter.variables.set("getDataValue", context.getDataValue);
        interpreter.variables.set("hasDataValue", context.hasDataValue);

        // Add enhanced custom week functions
        interpreter.variables.set("defineCustomWeek", context.defineCustomWeek);
        interpreter.variables.set("defineCustomWeekWithSongMetadata", context.defineCustomWeekWithSongMetadata);
        interpreter.variables.set("supportsCustomWeeks", context.supportsCustomWeeks);

        // Add validation functions (for generation-time validation)
        interpreter.variables.set("validateOriginSongForGeneration", context.validateOriginSongForGeneration);
        interpreter.variables.set("isSongAvailableForGeneration", context.isSongAvailableForGeneration);
        interpreter.variables.set("isBaseSong", context.isBaseSong);

        try {
            var program = parser.parseString(scriptContent);
            interpreter.execute(program);

            // Call onGenYAML callback if it exists
            if (interpreter.variables.exists("onGenYAML")) {
                try {
                    var callback = interpreter.variables.get("onGenYAML");
                    if (Reflect.isFunction(callback)) {
                        trace('Calling onGenYAML callback for ${modInfo.name}');
                        Reflect.callMethod(null, callback, []);
                    }
                } catch (e:Dynamic) {
                    trace('Error calling onGenYAML callback for ${modInfo.name}: ${e}');
                }
            }

            // Update the mod's song list with modifications from the script
            var finalSongList = context.getFinalSongList();

            // Find and update the mod info in availableMods
            for (mod in APDataStore.availableMods) {
                if (mod.folderName == modInfo.folderName) {
                    mod.songList = finalSongList;
                    break;
                }
            }

            // Also update the interpreter's songList variable for subsequent script access
            interpreter.variables.set("songList", finalSongList);

            // Store custom data and weeks globally
            for (key in context.customData.keys()) {
                APDataStore.customData.set(key, context.customData.get(key));
            }

            for (week in context.customWeeks) {
                APDataStore.customWeeks.push(week);
            }

            // Store song requirements globally
            for (requirement in context.songRequirements) {
                APDataStore.songRequirements.push(requirement);
            }

            // Call onAfterGen callback if it exists
            if (interpreter.variables.exists("onAfterGen")) {
                try {
                    var callback = interpreter.variables.get("onAfterGen");
                    if (Reflect.isFunction(callback)) {
                        trace('Calling onAfterGen callback for ${modInfo.name}');
                        Reflect.callMethod(null, callback, []);
                    }
                } catch (e:Dynamic) {
                    trace('Error calling onAfterGen callback for ${modInfo.name}: ${e}');
                }
            }

            trace('Successfully executed AP script: ${scriptPath}');
            trace('Added ${context.items.length} items and ${context.locations.length} locations');
            if (context.excludedSongs.length > 0) {
                trace('Excluded ${context.excludedSongs.length} songs: ${context.excludedSongs.join(", ")}');
            }
            if (context.addedSongs.length > 0) {
                trace('Added ${context.addedSongs.length} songs: ${context.addedSongs.join(", ")}');
            }
            if (context.customWeeks.length > 0) {
                trace('Defined ${context.customWeeks.length} custom weeks');
            }
            if (context.songRequirements.length > 0) {
                trace('Added ${context.songRequirements.length} song requirements');
            }
            if (Lambda.count(context.customData) > 0) {
                trace('Stored ${Lambda.count(context.customData)} data values');
            }
            trace('Final song list (${finalSongList.length} songs): ${finalSongList.join(", ")}');

            // Record success
            var success:APProcessingSuccess = {
                modName: modInfo.name,
                scriptPath: scriptPath,
                itemsAdded: context.items.length,
                locationsAdded: context.locations.length,
                songsAdded: context.addedSongs.length,
                songsExcluded: context.excludedSongs.length,
                customWeeksAdded: context.customWeeks.length,
                songRequirementsAdded: context.songRequirements.length,
                customDataEntries: Lambda.count(context.customData),
                timestamp: DateTools.format(Date.now(), "%Y-%m-%d %H:%M:%S")
            };
            APDataStore.processingSuccesses.push(success);

        } catch (e:Dynamic) {
            trace('Error parsing/executing AP script ${scriptPath}: ${e}');

            // Record error
            var error:APProcessingError = {
                modName: modInfo.name,
                scriptPath: scriptPath,
                errorType: "execution",
                errorMessage: Std.string(e),
                timestamp: DateTools.format(Date.now(), "%Y-%m-%d %H:%M:%S")
            };
            APDataStore.processingErrors.push(error);
        }
    }
}

// Function to generate Python file for Archipelago
class APPythonGenerator {
    public static function generatePythonScript():String {
        var pythonContent = "";

        // Header and imports
        pythonContent += "# Generated Archipelago custom locations and access rules\n";
        pythonContent += "# This file should be named '{playerName}_customFNFData.py' and placed in the same directory as your YAML file\n";
        pythonContent += "# Replace {playerName} with your actual player name from the YAML file\n";
        pythonContent += "# Example: if your player name is \"Alice\", name this file \"Alice_customFNFData.py\"\n\n";
        pythonContent += "from typing import Dict, Callable, Any\n\n";

        // FNFModHandler class definition
        pythonContent += "class FNFModHandler:\n";
        pythonContent += "    \"\"\"Class to handle all custom FNF mod data and logic\"\"\"\n";
        pythonContent += "    \n";
        pythonContent += "    def __init__(self):\n";
        pythonContent += "        self.custom_items = []\n";
        pythonContent += "        self.custom_trap_items = []\n";
        pythonContent += "        self.custom_weeks = []\n";
        pythonContent += "        self.custom_data = {}\n";
        pythonContent += "        self.song_additions = []\n";
        pythonContent += "        self.song_exclusions = []\n";
        pythonContent += "        self.song_requirements = []\n";
        pythonContent += "        self.access_rules = {}\n";
        pythonContent += "        self.custom_locations = {}\n";
        pythonContent += "        \n";
        pythonContent += "        # Initialize all data\n";
        pythonContent += "        self._setup_data()\n";
        pythonContent += "    \n";
        pythonContent += "    def _setup_data(self):\n";
        pythonContent += "        \"\"\"Initialize all custom data\"\"\"\n";

        // Custom items array
        pythonContent += "        # Custom items that can be added to the item pool\n";
        pythonContent += "        # The system will automatically handle which players get which items based on their custom locations\n";
        pythonContent += "        self.custom_items = [\n";
        for (item in APDataStore.items) {
            if (item.name != null && item.name != "" && (item.isTrap == null || !item.isTrap)) {
                pythonContent += "            \"" + item.name + "\",\n";
            }
        }
        pythonContent += "        ]\n\n";

        // Custom trap items array
        pythonContent += "        # Custom trap items that can be added to the item pool\n";
        pythonContent += "        # Trap items don't require associated songs and can target specific mods\n";
        pythonContent += "        self.custom_trap_items = [\n";
        for (item in APDataStore.items) {
            if (item.name != null && item.name != "" && item.isTrap == true) {
                pythonContent += "            \"" + item.name + "\",\n";
            }
        }
        pythonContent += "        ]\n\n";

        // Custom weeks array
        pythonContent += "        # Custom weeks that will be created dynamically during the AP session\n";
        pythonContent += "        # These weeks exist only in memory and are automatically cleaned up\n";
        pythonContent += "        self.custom_weeks = [\n";
        for (week in APDataStore.customWeeks) {
            pythonContent += "            {\n";
            pythonContent += "                \"name\": \"" + week.name + "\",\n";
            pythonContent += "                \"songs\": [";
            for (i in 0...week.songs.length) {
                pythonContent += "\"" + week.songs[i] + "\"";
                if (i < week.songs.length - 1) pythonContent += ", ";
            }
            pythonContent += "],\n";
            pythonContent += "                \"targetMod\": \"" + (week.targetMod != null ? week.targetMod : "") + "\",\n";

            // Add optional week-level metadata
            if (week.difficulties != null) {
                pythonContent += "                \"difficulties\": [";
                for (i in 0...week.difficulties.length) {
                    pythonContent += "\"" + week.difficulties[i] + "\"";
                    if (i < week.difficulties.length - 1) pythonContent += ", ";
                }
                pythonContent += "],\n";
            }

            if (week.icon != null) {
                pythonContent += "                \"icon\": \"" + week.icon + "\",\n";
            }

            if (week.color != null) {
                pythonContent += "                \"color\": [" + week.color.join(", ") + "],\n";
            }

            // Add per-song metadata if available
            if (week.songMetadata != null) {
                pythonContent += "                \"songMetadata\": [\n";
                for (i in 0...week.songMetadata.length) {
                    var songMeta = week.songMetadata[i];
                    pythonContent += "                    {\n";
                    pythonContent += "                        \"name\": \"" + songMeta.name + "\"";

                    if (songMeta.icon != null) {
                        pythonContent += ",\n                        \"icon\": \"" + songMeta.icon + "\"";
                    }

                    if (songMeta.color != null) {
                        pythonContent += ",\n                        \"color\": [" + songMeta.color.join(", ") + "]";
                    }

                    pythonContent += "\n                    }";
                    if (i < week.songMetadata.length - 1) pythonContent += ",";
                    pythonContent += "\n";
                }
                pythonContent += "                ],\n";
            }

            pythonContent += "            },\n";
        }
        pythonContent += "        ]\n\n";

        // Custom data dictionary
        pythonContent += "        # Custom data values set by HScript for use during world generation\n";
        pythonContent += "        self.custom_data = {\n";
        for (key in APDataStore.customData.keys()) {
            var value = APDataStore.customData.get(key);
            pythonContent += "            \"" + key + "\": ";

            // Handle different data types
            if (Std.isOfType(value, String)) {
                pythonContent += "\"" + value + "\"";
            } else if (Std.isOfType(value, Bool)) {
                pythonContent += (value ? "True" : "False");
            } else if (Std.isOfType(value, Array)) {
                pythonContent += "[";
                var arr:Array<Dynamic> = cast value;
                for (i in 0...arr.length) {
                    if (Std.isOfType(arr[i], String)) {
                        pythonContent += "\"" + arr[i] + "\"";
                    } else {
                        pythonContent += Std.string(arr[i]);
                    }
                    if (i < arr.length - 1) pythonContent += ", ";
                }
                pythonContent += "]";
            } else {
                pythonContent += Std.string(value);
            }

            pythonContent += ",\n";
        }
        pythonContent += "        }\n\n";

        // Song modifications
        pythonContent += "        # Song additions - songs that should be added to specific mods\n";
        pythonContent += "        # Format: {'name': 'song_name', 'targetMod': 'mod_name', 'icon': 'icon_name', 'color': [r, g, b], 'difficulties': ['diff1', 'diff2']}\n";
        pythonContent += "        # targetMod can be empty string for base game\n";
        pythonContent += "        # icon, color, and difficulties are optional and will use defaults if not specified\n";
        pythonContent += "        self.song_additions = [\n";
        for (addition in APDataStore.songAdditions) {
            pythonContent += "            {\n";
            pythonContent += "                \"name\": \"" + addition.name + "\",\n";
            pythonContent += "                \"targetMod\": \"" + (addition.targetMod != null ? addition.targetMod : "") + "\"";

            if (addition.icon != null) {
                pythonContent += ",\n                \"icon\": \"" + addition.icon + "\"";
            }

            if (addition.color != null) {
                pythonContent += ",\n                \"color\": [" + addition.color.join(", ") + "]";
            }

            if (addition.difficulties != null) {
                pythonContent += ",\n                \"difficulties\": [";
                for (i in 0...addition.difficulties.length) {
                    pythonContent += "\"" + addition.difficulties[i] + "\"";
                    if (i < addition.difficulties.length - 1) pythonContent += ", ";
                }
                pythonContent += "]";
            }

            pythonContent += "\n            },\n";
        }
        pythonContent += "        ]\n\n";

        pythonContent += "        # Song exclusions - songs that should be removed from specific mods\n";
        pythonContent += "        # Format: {'name': 'song_name', 'targetMod': 'mod_name'}\n";
        pythonContent += "        # targetMod can be empty string for base game\n";
        pythonContent += "        self.song_exclusions = [\n";
        for (exclusion in APDataStore.songExclusions) {
            pythonContent += "            {\"name\": \"" + exclusion.name + "\", \"targetMod\": \"" + (exclusion.targetMod != null ? exclusion.targetMod : "") + "\"},\n";
        }
        pythonContent += "        ]\n\n";

        // Song requirements array
        pythonContent += "        # Song requirements - defines what items are needed to access specific songs\n";
        pythonContent += "        # Format: {'songName': 'song_name', 'targetMod': 'mod_name', 'requiredItems': [{'name': 'item_name', 'count': 1}]}\n";
        pythonContent += "        # targetMod can be empty string for base game\n";
        pythonContent += "        # These requirements are applied as access rules for the songs themselves\n";
        pythonContent += "        self.song_requirements = [\n";
        for (requirement in APDataStore.songRequirements) {
            pythonContent += "            {\n";
            pythonContent += "                \"songName\": \"" + requirement.songName + "\",\n";
            pythonContent += "                \"targetMod\": \"" + (requirement.targetMod != null ? requirement.targetMod : "") + "\",\n";
            pythonContent += "                \"requiredItems\": [\n";
            if (requirement.accessRule != null && requirement.accessRule.requiredItems != null) {
                for (reqItem in requirement.accessRule.requiredItems) {
                    if (reqItem.name != null && reqItem.name != "") {
                        pythonContent += "                    {\"name\": \"" + reqItem.name + "\", \"count\": " + (reqItem.count != null ? reqItem.count : 1) + "},\n";
                    }
                }
            }
            pythonContent += "                ]\n";
            pythonContent += "            },\n";
        }
        pythonContent += "        ]\n\n";

        pythonContent += "        # Initialize access rules and locations\n";
        pythonContent += "        self._setup_access_rules()\n";
        pythonContent += "        self._setup_custom_locations()\n";
        pythonContent += "    \n";
        pythonContent += "    def _setup_access_rules(self):\n";
        pythonContent += "        \"\"\"Setup access rule functions for custom locations\"\"\"\n";
        pythonContent += "        # Access rule functions for custom locations  \n";

        for (location in APDataStore.locations) {
            if (location.name == null || location.name == "") continue; // Skip locations with invalid names

            var ruleName = sanitizePythonFunctionName(location.name);
            pythonContent += "        # Access rule for " + location.name + "\n";
            pythonContent += "        def " + ruleName + "_rule(state, player: int) -> bool:\n";

            // Generate base access rule for origin song
            if (location.originSong != null && location.originSong != "") {
                pythonContent += "            # Requires origin song: " + location.originSong;
                if (location.targetMod != null && location.targetMod != "") {
                    pythonContent += " (" + location.targetMod + ")";
                }
                pythonContent += "\n";

                // Format song name with mod in parentheses if mod is provided
                var songName = location.originSong;
                if (location.targetMod != null && location.targetMod != "") {
                    songName += " (" + location.targetMod + ")";
                }
                // If targetMod is empty, don't add anything (base game songs have no mod suffix)
                pythonContent += "            has_origin_song = state.has(\"" + songName + "\", player)\n";
            } else {
                pythonContent += "            has_origin_song = True  # No origin song requirement\n";
            }

            // Generate access rule based on required items
            if (location.accessRule != null && location.accessRule.requiredItems != null && location.accessRule.requiredItems.length > 0) {
                var itemNames = [for (item in location.accessRule.requiredItems) item.name];
                pythonContent += "            # Required items: " + itemNames.join(", ") + "\n";

                var itemChecks = [];
                for (reqItem in location.accessRule.requiredItems) {
                    if (reqItem.name != null && reqItem.name != "") {
                        if (reqItem.count > 1) {
                            itemChecks.push("state.has(\"" + reqItem.name + "\", player, " + reqItem.count + ")");
                        } else {
                            itemChecks.push("state.has(\"" + reqItem.name + "\", player)");
                        }
                    }
                }

                if (itemChecks.length > 0) {
                    pythonContent += "            has_required_items = " + itemChecks.join(" and ") + "\n";
                    pythonContent += "            return has_origin_song and has_required_items\n\n";
                } else {
                    pythonContent += "            # No valid item requirements found\n";
                    pythonContent += "            return has_origin_song\n\n";
                }
            } else {
                pythonContent += "            # No additional item requirements\n";
                pythonContent += "            return has_origin_song\n\n";
            }

            pythonContent += "        self.access_rules[\"" + location.name + "\"] = " + ruleName + "_rule\n\n";
        }

        pythonContent += "    def _setup_custom_locations(self):\n";
        pythonContent += "        \"\"\"Setup custom location objects with embedded access rules\"\"\"\n";

        for (location in APDataStore.locations) {
            if (location.name == null || location.name == "") continue; // Skip locations with invalid names

            pythonContent += "        self.custom_locations[\"" + location.name + "\"] = {\n";
            pythonContent += "            \"origin_song\": " + (location.originSong != null && location.originSong != "" ? '"' + location.originSong + '"' : "None") + ",\n";
            pythonContent += "            \"target_mod\": " + (location.targetMod != null && location.targetMod != "" ? '"' + location.targetMod + '"' : "None") + ",\n";
            pythonContent += "            \"access_rule\": self.access_rules[\"" + location.name + "\"],\n";
            pythonContent += "        }\n";
        }

        pythonContent += "    \n";
        pythonContent += "    def get_custom_data_for_class(self):\n";
        pythonContent += "        \"\"\"Returns custom data for integration during class setup\"\"\"\n";
        pythonContent += "        return {\n";
        pythonContent += "            'items': self.custom_items,\n";
        pythonContent += "            'trap_items': self.custom_trap_items,\n";
        pythonContent += "            'locations': self.custom_locations,\n";
        pythonContent += "            'song_additions': self.song_additions,\n";
        pythonContent += "            'song_exclusions': self.song_exclusions,\n";
        pythonContent += "            'song_requirements': self.song_requirements,\n";
        pythonContent += "            'custom_weeks': self.custom_weeks,\n";
        pythonContent += "            'custom_data': self.custom_data\n";
        pythonContent += "        }\n";
        pythonContent += "    \n";
        pythonContent += "    def apply_custom_logic(self, world_instance):\n";
        pythonContent += "        \"\"\"Apply custom items and locations to the world instance\"\"\"\n";
        pythonContent += "        # Store in world instance for use during generation\n";
        pythonContent += "        if not hasattr(world_instance, 'custom_location_data'):\n";
        pythonContent += "            world_instance.custom_location_data = {}\n";
        pythonContent += "        if not hasattr(world_instance, 'custom_items'):\n";
        pythonContent += "            world_instance.custom_items = []\n";
        pythonContent += "        \n";
        pythonContent += "        # Apply the custom data\n";
        pythonContent += "        world_instance.custom_location_data.update(self.custom_locations)\n";
        pythonContent += "        world_instance.custom_items.extend(self.custom_items)\n";
        pythonContent += "        \n";
        pythonContent += "        return world_instance\n";
        pythonContent += "\n";
        pythonContent += "# Create the instance that will be accessed by the AP world loader\n";
        pythonContent += "INSTANCE = FNFModHandler()\n";
        pythonContent += "\n";
        pythonContent += "# ============================================================================\n";
        pythonContent += "# LEGACY COMPATIBILITY FUNCTIONS\n";
        pythonContent += "# These maintain compatibility with existing code that expects the old API\n";
        pythonContent += "# ============================================================================\n";
        pythonContent += "\n";
        pythonContent += "def get_custom_data_for_class():\n";
        pythonContent += "    \"\"\"Legacy function - use INSTANCE.get_custom_data_for_class() instead\"\"\"\n";
        pythonContent += "    return INSTANCE.get_custom_data_for_class()\n";
        pythonContent += "\n";
        pythonContent += "def apply_custom_logic(world_instance):\n";
        pythonContent += "    \"\"\"Legacy function - use INSTANCE.apply_custom_logic() instead\"\"\"\n";
        pythonContent += "    return INSTANCE.apply_custom_logic(world_instance)\n";
        pythonContent += "\n";
        pythonContent += "# ============================================================================\n";
        pythonContent += "# DOCUMENTATION\n";
        pythonContent += "# ============================================================================\n";
        pythonContent += "\n";
        pythonContent += "# USAGE:\n";
        pythonContent += "# The INSTANCE variable contains a FNFModHandler object with all your custom data.\n";
        pythonContent += "# Access data through: INSTANCE.custom_items, INSTANCE.custom_locations, etc.\n";
        pythonContent += "# Call INSTANCE.get_custom_data_for_class() to get all data for world setup.\n";
        pythonContent += "\n";
        pythonContent += "# SONG MANAGEMENT FUNCTIONS:\n";
        pythonContent += "# \n";
        pythonContent += "# excludeSong(songName, targetMod=None):\n";
        pythonContent += "#   - Removes a song from the specified mod's song list\n";
        pythonContent += "#   - If targetMod is None or empty, removes from base game songs\n";
        pythonContent += "#   - Example: excludeSong(\"Tutorial\") removes Tutorial from base game\n";
        pythonContent += "#   - Example: excludeSong(\"Boss Fight\", \"MyMod\") removes Boss Fight from MyMod\n";
        pythonContent += "# \n";
        pythonContent += "# addSong(songName, targetMod=None, icon=None, color=None, difficulties=None):\n";
        pythonContent += "#   - Adds a song to the specified mod's song list with optional metadata\n";
        pythonContent += "#   - If targetMod is None or empty, adds to base game songs\n";
        pythonContent += "#   - icon: Custom icon name for the song (defaults to 'face')\n";
        pythonContent += "#   - color: RGB color array for the song [r, g, b] (defaults to [146, 113, 253])\n";
        pythonContent += "#   - difficulties: Array of difficulty names for this song (defaults to week difficulties)\n";
        pythonContent += "#   - Creates internal week files for mods that don't have the song\n";
        pythonContent += "#   - Will NOT add songs that already exist in existing weeks for that mod\n";
        pythonContent += "#   - Example: addSong(\"New Song\") adds to base game with defaults\n";
        pythonContent += "#   - Example: addSong(\"Custom Song\", \"MyMod\", \"boss\", [255, 0, 0], [\"hard\", \"expert\"])\n";
        pythonContent += "# \n";
        pythonContent += "# addSongs(songNames, targetMod=None, icon=None, color=None, difficulties=None):\n";
        pythonContent += "#   - Adds multiple songs with the same metadata to a mod\n";
        pythonContent += "#   - All songs will share the same icon, color, and difficulties\n";
        pythonContent += "#   - Example: addSongs([\"Song1\", \"Song2\"], \"MyMod\", \"boss\", [255, 0, 0], [\"hard\"])\n";
        pythonContent += "# \n";
        pythonContent += "# addSongsWithMetadata(songs, targetMod=None):\n";
        pythonContent += "#   - Adds multiple songs with individual metadata for each song\n";
        pythonContent += "#   - songs: Array of objects with {name, icon?, color?, difficulties?}\n";
        pythonContent += "#   - Example: addSongsWithMetadata([{\"name\": \"Song1\", \"icon\": \"boss\"}, {\"name\": \"Song2\", \"color\": [0, 255, 0]}])\n";
        pythonContent += "# \n";
        pythonContent += "# CUSTOM WEEK FUNCTIONS:\n";
        pythonContent += "# \n";
        pythonContent += "# defineCustomWeek(weekName, songs, targetMod=None, difficulties=None, icon=None, color=None):\n";
        pythonContent += "#   - Creates a custom week with the specified songs and metadata\n";
        pythonContent += "#   - difficulties: Array of difficulty names for this week (defaults to global difficulties)\n";
        pythonContent += "#   - icon: Default icon for songs in this week (individual song icons override this)\n";
        pythonContent += "#   - color: Default color for songs in this week (individual song colors override this)\n";
        pythonContent += "#   - Example: defineCustomWeek(\"Boss Week\", [\"Boss1\", \"Boss2\"], \"MyMod\", [\"hard\", \"expert\"], \"boss\", [255, 0, 0])\n";
        pythonContent += "# \n";
        pythonContent += "# defineCustomWeekWithSongMetadata(weekName, songData, targetMod=None, difficulties=None):\n";
        pythonContent += "#   - Creates a custom week with individual metadata for each song\n";
        pythonContent += "#   - songData: Array of objects with {name, icon?, color?} for each song\n";
        pythonContent += "#   - Individual song metadata takes priority over week defaults\n";
        pythonContent += "#   - Example: defineCustomWeekWithSongMetadata(\"Mixed Week\", [\n";
        pythonContent += "#       {\"name\": \"Easy Song\", \"icon\": \"face\", \"color\": [0, 255, 0]},\n";
        pythonContent += "#       {\"name\": \"Hard Song\", \"icon\": \"boss\", \"color\": [255, 0, 0]}\n";
        pythonContent += "#     ], \"MyMod\", [\"easy\", \"hard\"])\n";
        pythonContent += "# \n";
        pythonContent += "# DIFFICULTY OPTIMIZATION:\n";
        pythonContent += "# \n";
        pythonContent += "# The system automatically optimizes week creation by grouping songs with identical difficulty sets.\n";
        pythonContent += "# Songs with difficulties [\"easy\", \"normal\"] will be grouped together in one week,\n";
        pythonContent += "# while songs with [\"hard\", \"expert\"] will be in a separate week.\n";
        pythonContent += "# This minimizes the number of temporary weeks created and improves performance.\n";
        pythonContent += "# Week names follow the pattern: ap_custom_{mod}_{difficulties} or ap_custom_{mod} for default difficulties.\n";
        pythonContent += "# \n";
        pythonContent += "# TRAP ITEM FUNCTIONS:\n";
        pythonContent += "# \n";
        pythonContent += "# addTrapItem(name, targetMod=None):\n";
        pythonContent += "#   - Creates a custom trap item that can be sent to players\n";
        pythonContent += "#   - targetMod specifies which mod should handle the trap effect\n";
        pythonContent += "#   - If targetMod is None or empty, base game handles the trap\n";
        pythonContent += "#   - Trap items don't require associated songs\n";
        pythonContent += "#   - Example: addTrapItem(\"Confusion Trap\", \"MyMod\")\n";
        pythonContent += "# \n";
        pythonContent += "# SONG REQUIREMENT FUNCTIONS:\n";
        pythonContent += "# \n";
        pythonContent += "# addSongRequirement(songName, targetMod=None, accessRule, requireTargetMod=True):\n";
        pythonContent += "#   - Makes a song require specific items to be accessible/playable\n";
        pythonContent += "#   - songName: The name of the song that should require items\n";
        pythonContent += "#   - targetMod: The mod that contains the song (None = base game)\n";
        pythonContent += "#   - accessRule: What items are needed to access this song\n";
        pythonContent += "#   - This affects song selection in freeplay and progression logic\n";
        pythonContent += "#   - Example: Song becomes locked until player has required items\n";
        pythonContent += "# \n";
        pythonContent += "# addSimpleSongRequirement(songName, targetMod=None, requiredItems, requireTargetMod=True):\n";
        pythonContent += "#   - Simplified version that takes an array of item names\n";
        pythonContent += "#   - All items are required (AND logic) with count=1 each\n";
        pythonContent += "#   - Example: addSimpleSongRequirement(\"Boss Fight\", \"MyMod\", [\"Power Up\", \"Shield\"])\n";
        pythonContent += "# \n";
        pythonContent += "# addSongRequirementWithCounts(songName, targetMod=None, requiredItems, requireTargetMod=True):\n";
        pythonContent += "#   - Advanced version that accepts items with specific counts\n";
        pythonContent += "#   - requiredItems: Array of {name, count} objects\n";
        pythonContent += "#   - Example: addSongRequirementWithCounts(\"Final Boss\", \"MyMod\", [{name: \"Key\", count: 3}])\n";
        pythonContent += "# \n";
        pythonContent += "# hasSongRequirement(songName, targetMod=None):\n";
        pythonContent += "#   - Check if a song has any access requirements\n";
        pythonContent += "#   - Returns true if the song requires items to access\n";
        pythonContent += "# \n";
        pythonContent += "# getSongRequirement(songName, targetMod=None):\n";
        pythonContent += "#   - Get the full requirement object for a song\n";
        pythonContent += "#   - Returns APSongRequirement object or null if no requirements\n";
        pythonContent += "# \n";
        pythonContent += "# LOCATION FUNCTIONS:\n";
        pythonContent += "# \n";
        pythonContent += "# addLocation(name, originSong, targetMod=None, accessRule, requireTargetMod=True):\n";
        pythonContent += "#   - Creates a custom location tied to a specific song\n";
        pythonContent += "#   - originSong: The song that must be unlocked to access this location\n";
        pythonContent += "#   - targetMod: The mod that provides this location (None = base game)\n";
        pythonContent += "#   - accessRule: Logic for what items are needed to check this location\n";
        pythonContent += "#   - Location will be skipped if originSong gets removed by song limits\n";
        pythonContent += "# \n";
        pythonContent += "# MOD SETTINGS FUNCTIONS:\n";
        pythonContent += "# \n";
        pythonContent += "# currentModSettings (variable):\n";
        pythonContent += "#   - Map containing all settings for the current mod\n";
        pythonContent += "#   - Automatically loaded from save data\n";
        pythonContent += "#   - Access directly: currentModSettings.get(\"setting_key\")\n";
        pythonContent += "# \n";
        pythonContent += "# getModSetting(key, defaultValue=null):\n";
        pythonContent += "#   - Get a setting value with optional default\n";
        pythonContent += "#   - Returns the setting value or default if not found\n";
        pythonContent += "#   - Example: getModSetting(\"enable_archipelago\", false)\n";
        pythonContent += "# \n";
        pythonContent += "# CONDITIONAL ARCHIPELAGO FEATURES EXAMPLE:\n";
        pythonContent += "# if (getBoolModSetting(\"enable_archipelago_integration\", true)) {\n";
        pythonContent += "#     addItem(\"Custom Power-Up\");\n";
        pythonContent += "#     addSimpleLocation(\"Secret Area\", \"Boss Fight\", null, [\"Custom Power-Up\"]);\n";
        pythonContent += "# }\n";
        pythonContent += "# \n";
        pythonContent += "# IMPORTANT NOTES:\n";
        pythonContent += "# - Song modifications are processed during world generation\n";
        pythonContent += "# - Custom weeks are auto-generated for mods receiving new songs\n";
        pythonContent += "# - Week names follow pattern: 'ap_custom_{modname}' or 'ap_custom_base' for base game\n";
        pythonContent += "# - Slot data includes information about generated weeks for client initialization\n";

        return pythonContent;
    }

    // Generate Python-compatible data from HScript processing
    public static function generateHScriptData():String {
        // Process all mod scripts first
        APHScriptProcessor.processAllMods();

        var output = new StringBuf();

        // Generate items section
        output.add("def get_custom_items():\n");
        output.add("    return [\n");

        for (item in APDataStore.items) {
            if (item.name != null && item.name != "") {
                output.add('        "${item.name}",\n');
            }
        }

        output.add("    ]\n\n");

        // Generate locations section with embedded access rules
        output.add("def get_custom_locations():\n");
        output.add("    return [\n");

        for (location in APDataStore.locations) {
            if (location.name == null || location.name == "") continue; // Skip invalid locations

            output.add("        {\n");
            output.add('            "name": "${location.name}",\n');
            output.add('            "originSong": ${location.originSong != null && location.originSong != "" ? '"${location.originSong}"' : "None"},\n');
            output.add('            "targetMod": ${location.targetMod != null && location.targetMod != "" ? '"${location.targetMod}"' : "None"},\n');
            output.add('            "access_rule": {\n');
            output.add('                "requiredItems": [\n');

            if (location.accessRule != null && location.accessRule.requiredItems != null) {
                for (reqItem in location.accessRule.requiredItems) {
                    if (reqItem.name != null && reqItem.name != "") {
                        output.add('                    {"name": "${reqItem.name}", "count": ${reqItem.count}},\n');
                    }
                }
            }

            output.add('                ]\n');
            output.add('            }\n');
            output.add("        },\n");
        }

        output.add("    ]\n");

        return output.toString();
    }

    // Export HScript-generated data to file for Python to import
    public static function exportHScriptToPython(filename:String):Void {
        var content = generateHScriptData();

        try {
            File.saveContent(filename, content);
            trace('Successfully exported HScript AP data to: ${filename}');
        } catch (e:Dynamic) {
            trace('Error saving HScript AP data to ${filename}: ${e}');
        }
    }

    // Helper function to sanitize location names for Python function names
    private static function sanitizePythonFunctionName(name:String):String {
        if (name == null || name.trim() == "") {
            return "invalid_location";
        }

        // Convert to lowercase and replace all non-alphanumeric characters with underscores
        var sanitized = ~/[^a-zA-Z0-9_]/g.replace(name.toLowerCase(), "_");

        // Remove consecutive underscores
        sanitized = ~/_{2,}/g.replace(sanitized, "_");

        // Remove leading and trailing underscores
        sanitized = ~/^_+|_+$/g.replace(sanitized, "");

        // Ensure it starts with a letter or underscore (Python requirement)
        if (sanitized.length == 0 || ~/^[0-9]/.match(sanitized)) {
            sanitized = "location_" + sanitized;
        }

        // Ensure minimum length
        if (sanitized.length == 0) {
            sanitized = "location";
        }

        return sanitized;
    }
}
