package archipelago;

import sys.FileSystem;
import sys.io.File;
import hscript.Parser;
import hscript.Interp;
import backend.Mods;
import backend.Paths;
import backend.WeekData;
import archipelago.APInfo;

typedef APItem = APRequiredItem;

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

// Mod information structure
typedef ModInfo = {
    name: String,
    folderName: String,
    enabled: Bool,
    songList: Array<String>,
    // Add other mod-related info as needed
};

// Class to hold static arrays of items and locations
class APDataStore {
    public static var items:Array<APItem> = [];
    public static var locations:Array<APLocation> = [];
    public static var availableMods:Array<ModInfo> = [];
    public static var songAdditions:Array<{name:String, targetMod:String}> = [];
    public static var songExclusions:Array<{name:String, targetMod:String}> = [];
    public static var customData:Map<String, Dynamic> = new Map<String, Dynamic>();
    public static var customWeeks:Array<{name:String, songs:Array<String>, targetMod:String}> = [];
}

// HScript execution context for each mod
class APHScriptContext {
    public var modName:String;
    public var modFolderName:String;
    public var songList:Array<String>;
    public var items:Array<APItem>;
    public var locations:Array<APLocation>;
    public var availableMods:Array<ModInfo>;
    
    // Song modification arrays (processed after script execution)
    public var excludedSongs:Array<String>;
    public var addedSongs:Array<String>;
    
    // Detailed song modification tracking for Python generation
    public var songAdditions:Array<{name:String, targetMod:String}>;
    public var songExclusions:Array<{name:String, targetMod:String}>;
    
    // Data storage for Python generation
    public var customData:Map<String, Dynamic>;
    
    // Custom week definitions
    public var customWeeks:Array<{name:String, songs:Array<String>, targetMod:String}>;
    
    public function new(modInfo:ModInfo, allMods:Array<ModInfo>) {
        this.modName = modInfo.name;
        this.modFolderName = modInfo.folderName;
        this.songList = modInfo.songList.copy();
        this.items = [];
        this.locations = [];
        this.availableMods = allMods.copy();
        this.excludedSongs = [];
        this.addedSongs = [];
        this.songAdditions = [];
        this.songExclusions = [];
        this.customData = new Map<String, Dynamic>();
        this.customWeeks = [];
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
                songList: [] // Base game songs would be handled separately
            };
        }
        
        for (mod in availableMods) {
            if (mod.name == modName || mod.folderName == modName) {
                return mod;
            }
        }
        return null;
    }
    
    // Add item function (available in HScript)
    public function addItem(name:String, ?requiredMod:String):Void {
        // Empty or null mod name refers to base game (always available)
        if (requiredMod != null && requiredMod != "" && !isModEnabled(requiredMod)) {
            trace('Warning: Cannot add item "${name}" - required mod "${requiredMod}" is not enabled or does not exist');
            return;
        }
        
        var item:APItem = { 
            name: name,
            isTrap: false
        };
        if (requiredMod != null && requiredMod != "") {
            item.mod = requiredMod;
        }
        // If requiredMod is null or empty, item.mod stays null (base game)
        
        items.push(item);
        APDataStore.items.push(item);
    }
    
    // Add trap item function (available in HScript)
    public function addTrapItem(name:String, ?targetMod:String):Void {
        // Validate trap item name
        if (name == null || name.trim() == "") {
            var errorMsg = 'Invalid trap item name: Trap item name cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }
        
        // Target mod is optional for trap items and doesn't need to be validated for existence
        // since trap items can target mods that may not be currently enabled
        
        var item:APItem = { 
            name: name,
            isTrap: true
        };
        if (targetMod != null && targetMod != "") {
            item.targetMod = targetMod;
        }
        
        items.push(item);
        APDataStore.items.push(item);
        trace('Added trap item: ${name}' + (targetMod != null && targetMod != "" ? ' (target mod: ${targetMod})' : ''));
    }
    
    // Add location function with boolean mod requirement (available in HScript)
    public function addLocation(name:String, originSong:String, ?targetMod:String, accessRule:APAccessRule, requireTargetMod:Bool = true):Void {
        // Validate location name
        if (name == null || name.trim() == "") {
            var errorMsg = 'Invalid location name: Location name cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }
        
        // Use current mod as target if not specified
        if (targetMod == null) {
            targetMod = modName;
        }
        
        // Validate origin song and check if it's available in the target mod during generation
        validateOriginSongForGeneration(originSong, name, targetMod);
        
        // Check if the origin song is actually available in the target mod's song pool
        if (!isSongAvailableForGeneration(originSong, targetMod)) {
            trace('Warning: Cannot add location "${name}" - origin song "${originSong}" is not available in target mod "${targetMod}"');
            return;
        }
        
        // Empty string means base game (always available)
        if (targetMod == "") {
            requireTargetMod = false; // Base game is always available
        }
        
        // If mod requirement is enabled and targetMod is not empty, check if the target mod exists and is enabled
        if (requireTargetMod && targetMod != "" && !isModEnabled(targetMod)) {
            trace('Warning: Cannot add location "${name}" - target mod "${targetMod}" is not enabled or does not exist');
            return;
        }
        
        var location:APLocation = {
            name: name,
            originSong: originSong,
            targetMod: targetMod,
            accessRule: accessRule
        };
        
        locations.push(location);
        APDataStore.locations.push(location);
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
    
    // Song modification functions (available in HScript)
    public function excludeSong(songName:String, ?targetMod:String):Void {
        // Use current mod as default target if not specified
        if (targetMod == null) {
            targetMod = modName;
        }
        
        var formattedName = songName + (if (targetMod != null && targetMod != "") '(${targetMod})' else "");
        if (!excludedSongs.contains(formattedName)) {
            excludedSongs.push(formattedName);
            songExclusions.push({name: songName, targetMod: targetMod});
            APDataStore.songExclusions.push({name: songName, targetMod: targetMod});
            trace('Excluded song: ${songName} from mod ${targetMod}');
        }
    }

    public function addSong(songName:String, ?targetMod:String):Void {
        // Use current mod as default target if not specified
        if (targetMod == null) {
            targetMod = modName;
        }
        
        var formattedName = songName + (if (targetMod != null && targetMod != "") '(${targetMod})' else "");
        if (!addedSongs.contains(formattedName)) {
            addedSongs.push(formattedName);
            songAdditions.push({name: songName, targetMod: targetMod});
            APDataStore.songAdditions.push({name: songName, targetMod: targetMod});
            trace('Added song: ${songName} to mod ${targetMod}');
        }
    }
    
    // Helper to exclude multiple songs at once
    public function excludeSongs(songNames:Array<String>, ?targetMod:String):Void {
        for (song in songNames) {
            excludeSong(song, targetMod);
        }
    }
    
    // Helper to add multiple songs at once
    public function addSongs(songNames:Array<String>, ?targetMod:String):Void {
        for (song in songNames) {
            addSong(song, targetMod);
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
    
    // Custom week definition functions (available in HScript)
    public function defineCustomWeek(weekName:String, songs:Array<String>, ?targetMod:String):Void {
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
        
        // Validate songs array
        if (songs == null || songs.length == 0) {
            var errorMsg = 'Invalid custom week songs: Songs array cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }
        
        var customWeek = {
            name: weekName,
            songs: songs.copy(),
            targetMod: targetMod
        };
        
        customWeeks.push(customWeek);
        APDataStore.customWeeks.push(customWeek);
        trace('Defined custom week: ${weekName} with ${songs.length} songs for mod ${targetMod}');
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
        
        return {
            name: modName,
            folderName: folderName,
            enabled: enabled,
            songList: songList
        };
        #else
        return null;
        #end
    }
    
    static function getModSongList(modFolder:String):Array<String> {
        var songs:Array<String> = [];
        
        #if MODS_ALLOWED
        // Only check for songs defined in weeks
        var weeksPath = Paths.mods(modFolder + '/weeks/');
        if (FileSystem.exists(weeksPath) && FileSystem.isDirectory(weeksPath)) {
            for (file in FileSystem.readDirectory(weeksPath)) {
                if (file.endsWith('.json')) {
                    try {
                        var weekData = WeekData.getWeekFile(file.substr(0, file.length - 5));
                        if (weekData != null && weekData.songs != null) {
                            for (song in weekData.songs) {
                                if (!songs.contains(song[0])) {
                                    songs.push(song[0]);
                                }
                            }
                        }
                    } catch (e:Dynamic) {
                        // Ignore invalid week files
                    }
                }
            }
        }
        #end
        
        return songs;
    }
    
    public static function processAllMods():Void {
        // Clear existing data
        APDataStore.items = [];
        APDataStore.locations = [];
        APDataStore.songAdditions = [];
        APDataStore.songExclusions = [];
        APDataStore.customData = new Map<String, Dynamic>();
        APDataStore.customWeeks = [];
        
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
            }
        }
    }
    
    public static function executeHScript(scriptPath:String, modInfo:ModInfo, allMods:Array<ModInfo>):Void {
        if (!FileSystem.exists(scriptPath)) {
            trace('AP script not found: ${scriptPath}');
            return;
        }
        
        var scriptContent = File.getContent(scriptPath);
        var parser = new Parser();
        var interpreter = new Interp();
        
        // Create context for this mod
        var context = new APHScriptContext(modInfo, allMods);
        
        // Set up interpreter variables and functions
        interpreter.variables.set("modName", context.modName);
        interpreter.variables.set("modFolderName", context.modFolderName);
        interpreter.variables.set("songList", context.songList);
        interpreter.variables.set("availableMods", context.availableMods);
        
        // Add player settings access
        interpreter.variables.set("playerSettings", archipelago.APEntryState.gameSettings.FNF);
        
        // Add helper functions
        interpreter.variables.set("addItem", context.addItem);
        interpreter.variables.set("addTrapItem", context.addTrapItem);
        interpreter.variables.set("addLocation", context.addLocation);
        interpreter.variables.set("addSimpleLocation", context.addSimpleLocation);
        interpreter.variables.set("addLocationWithCounts", context.addLocationWithCounts);
        interpreter.variables.set("isModEnabled", context.isModEnabled);
        interpreter.variables.set("getModInfo", context.getModInfo);
        
        // Add song modification functions
        interpreter.variables.set("excludeSong", context.excludeSong);
        interpreter.variables.set("addSong", context.addSong);
        interpreter.variables.set("excludeSongs", context.excludeSongs);
        interpreter.variables.set("addSongs", context.addSongs);
        interpreter.variables.set("getFinalSongList", context.getFinalSongList);
        
        // Add data storage functions
        interpreter.variables.set("setDataValue", context.setDataValue);
        interpreter.variables.set("getDataValue", context.getDataValue);
        interpreter.variables.set("hasDataValue", context.hasDataValue);
        
        // Add custom week functions
        interpreter.variables.set("defineCustomWeek", context.defineCustomWeek);
        interpreter.variables.set("supportsCustomWeeks", context.supportsCustomWeeks);
        
        // Add validation functions (for generation-time validation)
        interpreter.variables.set("validateOriginSongForGeneration", context.validateOriginSongForGeneration);
        interpreter.variables.set("isSongAvailableForGeneration", context.isSongAvailableForGeneration);
        interpreter.variables.set("isBaseSong", context.isBaseSong);
        
        // Add utility functions
        interpreter.variables.set("trace", trace);
        
        try {
            var program = parser.parseString(scriptContent);
            interpreter.execute(program);
            
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
            if (Lambda.count(context.customData) > 0) {
                trace('Stored ${Lambda.count(context.customData)} data values');
            }
            trace('Final song list (${finalSongList.length} songs): ${finalSongList.join(", ")}');
        } catch (e:Dynamic) {
            trace('Error parsing/executing AP script ${scriptPath}: ${e}');
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
        pythonContent += "        # NOTE: Items are now shared across players - no player prefixes needed\n";
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
            pythonContent += "                \"targetMod\": \"" + (week.targetMod != null ? week.targetMod : "") + "\"\n";
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
        pythonContent += "        # Format: {'name': 'song_name', 'targetMod': 'mod_name'}\n";
        pythonContent += "        # targetMod can be empty string for base game\n";
        pythonContent += "        self.song_additions = [\n";
        for (addition in APDataStore.songAdditions) {
            pythonContent += "            {\"name\": \"" + addition.name + "\", \"targetMod\": \"" + (addition.targetMod != null ? addition.targetMod : "") + "\"},\n";
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
        
        pythonContent += "        # Initialize access rules and locations\n";
        pythonContent += "        self._setup_access_rules()\n";
        pythonContent += "        self._setup_custom_locations()\n";
        pythonContent += "    \n";
        pythonContent += "    def _setup_access_rules(self):\n";
        pythonContent += "        \"\"\"Setup access rule functions for custom locations\"\"\"\n";
        pythonContent += "        # Access rule functions for custom locations  \n";
        pythonContent += "        # NOTE: Location names no longer have player prefixes - the system handles player ownership automatically\n";
        
        for (location in APDataStore.locations) {
            if (location.name == null || location.name == "") continue; // Skip locations with invalid names
            
            var ruleName = location.name.replace(" ", "_").replace("-", "_").replace("(", "").replace(")", "").toLowerCase();
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
        pythonContent += "# addSong(songName, targetMod=None):\n";
        pythonContent += "#   - Adds a song to the specified mod's song list\n";
        pythonContent += "#   - If targetMod is None or empty, adds to base game songs\n";
        pythonContent += "#   - Creates internal week files for mods that don't have the song\n";
        pythonContent += "#   - Will NOT add songs that already exist in existing weeks for that mod\n";
        pythonContent += "#   - Example: addSong(\"New Song\") adds to base game\n";
        pythonContent += "#   - Example: addSong(\"Custom Song\", \"MyMod\") adds to MyMod\n";
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
        pythonContent += "# LOCATION FUNCTIONS:\n";
        pythonContent += "# \n";
        pythonContent += "# addLocation(name, originSong, targetMod=None, accessRule, requireTargetMod=True):\n";
        pythonContent += "#   - Creates a custom location tied to a specific song\n";
        pythonContent += "#   - originSong: The song that must be unlocked to access this location\n";
        pythonContent += "#   - targetMod: The mod that provides this location (None = base game)\n";
        pythonContent += "#   - accessRule: Logic for what items are needed to check this location\n";
        pythonContent += "#   - Location will be skipped if originSong gets removed by song limits\n";
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
}
}
