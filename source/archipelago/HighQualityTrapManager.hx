package archipelago;

import backend.ClientPrefs;
import backend.GitHubAPI.DownloadConfig;
import backend.GitHubAPI;
import backend.Paths;
import backend.WeekData;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import yutautil.TypeUtils.OneOrMore;

typedef SiivaReplacementData = {
    var originalSong:String;
    var replacementSong:String;
    var modName:String;
    var weekName:String; // Track which week this song belongs to
}

typedef SiivaModInfo = {
    var name:String;
    var version:String;
    var description:String;
}

typedef SiivaWeekData = {
    var weekName:String;
    var songs:Array<SiivaReplacementData>;
    var modName:String;
    var availableDifficulties:Array<String>; // Track available difficulties for this week
}

/**
 * HighQualityTrapManager
 * Manages the "High Quality Trap" system for Archipelago mode.
 * Downloads SiivaGunner repo to a temporary folder and treats it like the entire mods directory.
 * The name is a joke reference to SiivaGunner's "High Quality Video Game Rips".
 */
class HighQualityTrapManager {
    // The joke name references SiivaGunner's "High Quality Video Game Rips"
    public static final SIIVA_REPO:String = "Yuta12342/Mixtape-Engine-SiivaGunner-Packs";
    public static final TEMP_SIIVA_FOLDER:String = "./temp_siivagunner_mods";
    public static final BASE_GAME_MARKER:String = "__mixtape__"; // Marker for base game content

    private static var isActive:Bool = false;
    private static var isDownloaded:Bool = false;
    private static var downloadProgress:Float = 0.0;
    private static var isDownloading:Bool = false;
    private static var songReplacements:Map<String, SiivaReplacementData> = new Map();
    private static var availableSiivaMods:Array<String> = [];
    private static var siivaBaseGameSongs:Array<String> = [];
    private static var siivaWeeks:Map<String, SiivaWeekData> = new Map(); // Store week data for each mod
    private static var isInitialized:Bool = false;

    /**
     * Initialize the High Quality Trap system
     * The name is a joke reference to SiivaGunner's "High Quality Video Game Rips"
     */
    public static function initialize():Void {
        if (isInitialized) return;

        trace("HighQualityTrapManager: Initializing High Quality Trap system...");

        // Clean up any existing temporary folder from previous sessions
        cleanupTempFolder();

        // Check if SiivaGunner temp folder is already downloaded (shouldn't be, but just in case)
        checkExistingDownload();

        isInitialized = true;
        trace("HighQualityTrapManager: High Quality Trap system initialized!");
    }

    /**
     * Clean up temporary SiivaGunner folder
     */
    public static function cleanupTempFolder():Void {
        if (FileSystem.exists(TEMP_SIIVA_FOLDER)) {
            try {
                trace("HighQualityTrapManager: Cleaning up temporary SiivaGunner folder...");
                deleteDirectory(TEMP_SIIVA_FOLDER);
                trace("HighQualityTrapManager: Temporary folder cleaned up successfully");
            } catch (e:Dynamic) {
                trace("HighQualityTrapManager: Failed to cleanup temp folder: " + e);
            }
        }
    }

    /**
     * Recursive directory deletion helper
     */
    private static function deleteDirectory(path:String):Void {
        if (!FileSystem.exists(path)) return;

        if (FileSystem.isDirectory(path)) {
            var items = FileSystem.readDirectory(path);
            for (item in items) {
                deleteDirectory(haxe.io.Path.join([path, item]));
            }
            FileSystem.deleteDirectory(path);
        } else {
            FileSystem.deleteFile(path);
        }
    }

    /**
     * Check if SiivaGunner temp folder is already downloaded
     */
    private static function checkExistingDownload():Void {
        if (FileSystem.exists(TEMP_SIIVA_FOLDER) && FileSystem.isDirectory(TEMP_SIIVA_FOLDER)) {
            trace("HighQualityTrapManager: Found existing SiivaGunner temp folder");
            isDownloaded = true;
            // Load SiivaGunner content separately from normal mod system
            loadSiivaContent();
        } else {
            trace("HighQualityTrapManager: No existing SiivaGunner temp folder found");
            isDownloaded = false;
        }
    }

    /**
     * Activate the High Quality Trap
     * Downloads the SiivaGunner repo to temp folder if not already present
     */
    public static function activateTrap():Void {
        if (!isInitialized) initialize();

        trace("HighQualityTrapManager: Activating High Quality Trap!");
        isActive = true;

        // Download the repo to temp folder if not already downloaded
        if (!isDownloaded) {
            downloadSiivaRepo();
        } else {
            // Already downloaded, load SiivaGunner content separately
            loadSiivaContent();
            trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
        }
    }

    /**
     * Deactivate the High Quality Trap and cleanup temp folder
     */
    public static function deactivateTrap():Void {
        trace("HighQualityTrapManager: Deactivating High Quality Trap");
        isActive = false;

        // Clean up temporary folder when deactivating
        cleanupTempFolder();
        isDownloaded = false;
        songReplacements.clear();
        availableSiivaMods = [];
        siivaBaseGameSongs = [];
        siivaWeeks.clear();
    }

    /**
     * Check if the trap is currently active
     */
    public static function isTrapActive():Bool {
        return isActive;
    }

    /**
     * Get replacement song for a given original song
     * This should only be called internally - APFreeplayManager handles the actual mod switching
     */
    public static function getReplacementSong(originalSong:String, ?modName:String):String {
        if (!isActive || !isInitialized) return originalSong;

        // Use the current mod directory if no specific mod is provided
        if (modName == null && backend.Mods.currentModDirectory != null && backend.Mods.currentModDirectory.length > 0) {
            modName = backend.Mods.currentModDirectory;
        }

        // Try exact match first (song + mod)
        var key = originalSong;
        if (modName != null && modName != "") {
            key = modName + ":" + originalSong;
            if (songReplacements.exists(key)) {
                var replacement = songReplacements.get(key);
                trace('HighQualityTrapManager: Replacing "$originalSong" from "$modName" with "${replacement.replacementSong}"');
                return replacement.replacementSong;
            }
        }

        // Try song-only match (vanilla/no mod specified)
        if (songReplacements.exists(originalSong)) {
            var replacement = songReplacements.get(originalSong);
            trace('HighQualityTrapManager: Replacing "$originalSong" with "${replacement.replacementSong}"');
            return replacement.replacementSong;
        }

        // Try base game marker match (for when no mod is specified but base game replacement exists)
        var baseGameKey = BASE_GAME_MARKER + ":" + originalSong;
        if (songReplacements.exists(baseGameKey)) {
            var replacement = songReplacements.get(baseGameKey);
            trace('HighQualityTrapManager: Replacing base game "$originalSong" with "${replacement.replacementSong}"');
            return replacement.replacementSong;
        }

        // No replacement found
        return originalSong;
    }

    /**
     * Check if a song has a replacement available
     */
    public static function hasReplacement(originalSong:String, ?modName:String):Bool {
        if (!isActive || !isInitialized) return false;

        // Use the current mod directory if no specific mod is provided
        if (modName == null && backend.Mods.currentModDirectory != null && backend.Mods.currentModDirectory.length > 0) {
            modName = backend.Mods.currentModDirectory;
        }

        var key = originalSong;
        if (modName != null && modName != "") {
            key = modName + ":" + originalSong;
            if (songReplacements.exists(key)) return true;
        }

        // Check song-only match (vanilla/no mod specified)
        if (songReplacements.exists(originalSong)) return true;

        // Check base game marker match (for when no mod is specified but base game replacement exists)
        var baseGameKey = BASE_GAME_MARKER + ":" + originalSong;
        return songReplacements.exists(baseGameKey);
    }

    /**
     * Get filtered unlocked songs for APFreeplayManager (only SiivaGunner compatible songs)
     */
    public static function filterUnlockedSongsForSiiva(originalUnlocked:Array<{song:String, mod:String}>):Array<{song:String, mod:String}> {
        if (!isActive || !isInitialized) return originalUnlocked;

        var filtered:Array<{song:String, mod:String}> = [];

        for (songObj in originalUnlocked) {
            // Check if this song/mod combination has a SiivaGunner replacement
            if (hasReplacement(songObj.song, songObj.mod) || availableSiivaMods.contains(songObj.mod)) {
                filtered.push(songObj);
            }
        }

        trace('HighQualityTrapManager: Filtered ${originalUnlocked.length} songs to ${filtered.length} SiivaGunner compatible songs');
        return filtered;
    }

    /**
     * Get a random SiivaGunner song for when no songs are available
     */
    public static function getRandomSiivaSong():{song:String, mod:String} {
        if (!isActive || !isInitialized || availableSiivaMods.length == 0) {
            return null;
        }

        // First try base game songs if available
        if (siivaBaseGameSongs.length > 0) {
            var randomSong = siivaBaseGameSongs[Std.random(siivaBaseGameSongs.length)];
            trace('HighQualityTrapManager: Selected random base game SiivaGunner song: $randomSong');
            return {song: randomSong, mod: BASE_GAME_MARKER};
        }

        // Otherwise pick from available mods
        var randomMod = availableSiivaMods[Std.random(availableSiivaMods.length)];
        var modSongs = getModSongs(randomMod);

        if (modSongs.length > 0) {
            var randomSong = modSongs[Std.random(modSongs.length)];
            trace('HighQualityTrapManager: Selected random SiivaGunner song: $randomSong from mod: $randomMod');
            return {song: randomSong, mod: randomMod};
        }

        trace('HighQualityTrapManager: No SiivaGunner songs available');
        return null;
    }

    /**
     * Get all songs from a specific mod
     */
    private static function getModSongs(modName:String):Array<String> {
        var songs:Array<String> = [];
        for (key in songReplacements.keys()) {
            var replacement = songReplacements.get(key);
            if (replacement.modName == modName) {
                songs.push(replacement.replacementSong);
            }
        }
        return songs;
    }

    /**
     * Check if SiivaGunner has content for a specific mod
     */
    public static function hasSiivaContentForMod(modName:String):Bool {
        if (!isActive || !isInitialized) return false;
        return availableSiivaMods.contains(modName) || modName == BASE_GAME_MARKER;
    }

    /**
     * Get the actual mod folder path that should be used for loading
     * This returns the path to the SiivaGunner version if trap is active
     */
    public static function getModPathForLoading(originalModName:String):String {
        if (!isActive || !isInitialized) return originalModName;

        // If this mod has SiivaGunner content, redirect to temp folder
        if (hasSiivaContentForMod(originalModName)) {
            if (originalModName == BASE_GAME_MARKER) {
                return haxe.io.Path.join([TEMP_SIIVA_FOLDER, BASE_GAME_MARKER]);
            } else {
                return haxe.io.Path.join([TEMP_SIIVA_FOLDER, originalModName]);
            }
        }

        return originalModName;
    }

    /**
     * Get path to the SiivaGunner temp folder
     */
    public inline static function getTempPath():String {
        return TEMP_SIIVA_FOLDER;
    }

    /**
     * Load SiivaGunner content using engine-like patterns but separately from normal mod system
     * This replaces normal mod loading when the trap is active
     */
    public static function loadSiivaContent():Void {
        if (!isActive || !isDownloaded) return;

        trace("HighQualityTrapManager: Loading SiivaGunner content...");

        // Use engine-like patterns but scan our temp folder independently
        scanSiivaWeekFiles();

        trace('HighQualityTrapManager: SiivaGunner content loaded - found ${Lambda.count(songReplacements)} song replacements');
    }

    /**
     * Scan for week files in the SiivaGunner temp folder using engine-like patterns
     * This acts like WeekData.reloadWeekFiles() but only for our temp folder
     */
    private static function scanSiivaWeekFiles():Void {
        songReplacements.clear();
        availableSiivaMods = [];
        siivaBaseGameSongs = [];
        siivaWeeks.clear();

        if (!FileSystem.exists(TEMP_SIIVA_FOLDER)) {
            trace("HighQualityTrapManager: Temp SiivaGunner folder not found");
            return;
        }

        try {
            // Scan all subdirectories in temp folder as if they were individual mods
            var modFolders = FileSystem.readDirectory(TEMP_SIIVA_FOLDER);

            for (modFolder in modFolders) {
                var modPath = haxe.io.Path.join([TEMP_SIIVA_FOLDER, modFolder]);
                if (FileSystem.isDirectory(modPath)) {
                    // Check if this is the base game marker
                    if (modFolder == BASE_GAME_MARKER) {
                        scanSiivaModWeeks(modPath, BASE_GAME_MARKER);
                    } else {
                        // Scan this mod folder for weeks (engine-like pattern)
                        scanSiivaModWeeks(modPath, modFolder);
                        if (!availableSiivaMods.contains(modFolder)) {
                            availableSiivaMods.push(modFolder);
                        }
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("HighQualityTrapManager: Error scanning SiivaGunner content: " + e);
        }
    }

    /**
     * Scan week files in a SiivaGunner mod folder (acts like WeekData loading)
     */
    private static function scanSiivaModWeeks(modPath:String, modName:String):Void {
        // Check for weeks folder (engine pattern)
        var weeksPath = haxe.io.Path.join([modPath, "weeks"]);
        if (FileSystem.exists(weeksPath) && FileSystem.isDirectory(weeksPath)) {
            // Scan week files like the engine does
            try {
                var weekFiles = FileSystem.readDirectory(weeksPath);
                for (weekFile in weekFiles) {
                    if (weekFile.endsWith('.json')) {
                        var weekPath = haxe.io.Path.join([weeksPath, weekFile]);
                        loadSiivaWeekFile(weekPath, modName);
                    }
                }
            } catch (e:Dynamic) {
                trace('HighQualityTrapManager: Error scanning weeks in mod "$modName": $e');
            }
        }

        // If no weeks folder, fall back to manual song scanning (for compatibility)
        var songsPath = haxe.io.Path.join([modPath, "songs"]);
        if (FileSystem.exists(songsPath) && FileSystem.isDirectory(songsPath)) {
            scanModSongsDirectory(songsPath, modName);
        }
    }

    /**
     * Load a single week file from SiivaGunner content (acts like WeekData.getWeekFile)
     */
    private static function loadSiivaWeekFile(weekPath:String, modName:String):Void {
        try {
            var rawJson = File.getContent(weekPath);
            if (rawJson != null && rawJson.length > 0) {
                var weekData:WeekFile = cast tjson.TJSON.parse(rawJson);
                if (weekData != null && weekData.songs != null) {
                    var weekName = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(weekPath));
                    
                    // Get difficulties from the week data (like WeekData/Difficulty.hx does)
                    var weekDifficulties:Array<String> = ['Easy', 'Normal', 'Hard']; // Default
                    if (weekData.difficulties != null && weekData.difficulties.length > 0) {
                        // Parse difficulties string just like Difficulty.hx does
                        var diffs:Array<String> = weekData.difficulties.trim().split(',');
                        var i:Int = diffs.length - 1;
                        while (i >= 0) {
                            if (diffs[i] != null) {
                                diffs[i] = diffs[i].trim();
                                if (diffs[i].length < 1) diffs.remove(diffs[i]);
                            }
                            --i;
                        }

                        if (diffs.length > 0 && diffs[0].length > 0) {
                            weekDifficulties = diffs;
                        }
                    }

                    var siivaWeekData:SiivaWeekData = {
                        weekName: weekName,
                        songs: [],
                        modName: modName,
                        availableDifficulties: weekDifficulties.copy() // Store difficulties at week level
                    };
                    siivaWeekData.availableDifficulties = weekDifficulties.copy();

                    // Process songs in this week
                    for (songData in weekData.songs) {
                        var songName:String = null;

                        // Handle different song data formats (like the engine does)
                        if (Std.isOfType(songData, String)) {
                            songName = cast(songData, String);
                        } else if (Std.isOfType(songData, Array)) {
                            var songArray = cast(songData, Array<Dynamic>);
                            if (songArray.length > 0 && Std.isOfType(songArray[0], String)) {
                                songName = cast(songArray[0], String);
                            }
                        }

                        if (songName != null && songName.length > 0) {
                            // Create song replacement data (difficulties are stored at week level)
                            var replacementData:SiivaReplacementData = {
                                originalSong: songName,
                                replacementSong: songName,
                                modName: modName,
                                weekName: weekName
                            };

                            songReplacements.set(modName + ":" + songName, replacementData);
                            siivaWeekData.songs.push(replacementData);

                            // Track base game vs mod songs
                            if (modName == BASE_GAME_MARKER) {
                                if (!siivaBaseGameSongs.contains(songName)) {
                                    siivaBaseGameSongs.push(songName);
                                }
                            }

                            trace('HighQualityTrapManager: Added song "$songName" from SiivaGunner week file in mod "$modName" for week "$weekName"');
                        }
                    }

                    // Store the week data
                    var weekKey = modName + ":" + weekName;
                    siivaWeeks.set(weekKey, siivaWeekData);
                    trace('HighQualityTrapManager: Added week "$weekName" for mod "$modName" with ${siivaWeekData.songs.length} songs');
                }
            }
        } catch (e:Dynamic) {
            trace('HighQualityTrapManager: Error loading week file "$weekPath": $e');
        }
    }

    /**
     * Get difficulties from week data (like WeekData does) instead of scanning file names
     */
    private static function getDifficultiesFromWeek(weekData:SiivaWeekData):Array<String> {
        // Try to find the original WeekData to get difficulties string
        var weekKey = weekData.modName + ":" + weekData.weekName;

        // Look for the week in our loaded SiivaGunner weeks
        if (siivaWeeks.exists(weekKey)) {
            var siivaWeek = siivaWeeks.get(weekKey);

            // Get difficulties from the week data (not individual songs)
            if (siivaWeek.availableDifficulties != null && siivaWeek.availableDifficulties.length > 0) {
                return siivaWeek.availableDifficulties.copy();
            }
        }

        // Fallback: check if there's a corresponding WeekData with difficulties string
        try {
            var modBasePath = haxe.io.Path.join([TEMP_SIIVA_FOLDER, weekData.modName]);
            var weekFilePath = haxe.io.Path.join([modBasePath, "weeks", weekData.weekName + ".json"]);

            if (FileSystem.exists(weekFilePath)) {
                var rawJson = File.getContent(weekFilePath);
                if (rawJson != null && rawJson.length > 0) {
                    var weekFile:WeekFile = cast tjson.TJSON.parse(rawJson);
                    if (weekFile != null && weekFile.difficulties != null && weekFile.difficulties.length > 0) {
                        // Parse difficulties string just like Difficulty.hx does
                        var diffs:Array<String> = weekFile.difficulties.trim().split(',');
                        var i:Int = diffs.length - 1;
                        while (i >= 0) {
                            if (diffs[i] != null) {
                                diffs[i] = diffs[i].trim();
                                if (diffs[i].length < 1) diffs.remove(diffs[i]);
                            }
                            --i;
                        }

                        if (diffs.length > 0 && diffs[0].length > 0) {
                            return diffs;
                        }
                    }
                }
            }
        } catch (e:Dynamic) {
            trace('HighQualityTrapManager: Error reading week file for difficulties: $e');
        }

        // Final fallback: return default difficulties
        return ['Easy', 'Normal', 'Hard'];
    }

    /**
     * Download SiivaGunner repository to temp folder (treats it like entire mods directory)
     */
    private static function downloadSiivaRepo():Void {
        trace("HighQualityTrapManager: Starting download of SiivaGunner repo to temp folder...");

        isDownloading = true;
        downloadProgress = 0.0;

        // Use background-friendly clone repository method
        GitHubAPI.cloneRepository(SIIVA_REPO, TEMP_SIIVA_FOLDER, null,
            function(current:Int, total:Int, fileName:String) {
                downloadProgress = current / Math.max(total, 1);
                trace('HighQualityTrapManager: Downloading file ${current}/${total}: $fileName (${Math.round(downloadProgress * 100)}%)');
            },
            function(progress:Float, fileName:String) {
                // Individual file progress - could be used for UI updates
            },
            function(path:String) {
                trace("HighQualityTrapManager: SiivaGunner repo downloaded to temp folder: " + path);
                isDownloaded = true;
                isDownloading = false;
                downloadProgress = 1.0;
                // Load content after download completes
                loadSiivaContent();
                trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
            },
            function(error:String) {
                trace("HighQualityTrapManager: Download failed: " + error);
                // Set flags to indicate download failed
                isDownloaded = false;
                isDownloading = false;
                downloadProgress = 0.0;
            }
        );
    }    /**
     * Scan the temp folder for mods (treats temp folder like the entire mods directory)
     */
    private static function scanTempModsFolder():Void {
        trace("HighQualityTrapManager: Scanning temp SiivaGunner folder (treating as mods directory)...");

        songReplacements.clear();
        availableSiivaMods = [];
        siivaBaseGameSongs = [];

        if (!FileSystem.exists(TEMP_SIIVA_FOLDER)) {
            trace("HighQualityTrapManager: Temp SiivaGunner folder not found");
            return;
        }

        try {
            // Scan all subdirectories in temp folder as if they were individual mods
            var modFolders = FileSystem.readDirectory(TEMP_SIIVA_FOLDER);

            for (modFolder in modFolders) {
                var modPath = haxe.io.Path.join([TEMP_SIIVA_FOLDER, modFolder]);
                if (FileSystem.isDirectory(modPath)) {
                    // Check if this is the base game marker
                    if (modFolder == BASE_GAME_MARKER) {
                        scanBaseGameContent(modPath);
                    } else {
                        // Scan this mod folder for songs
                        var songsPath = haxe.io.Path.join([modPath, "songs"]);
                        if (FileSystem.exists(songsPath) && FileSystem.isDirectory(songsPath)) {
                            scanModSongsDirectory(songsPath, modFolder);
                            availableSiivaMods.push(modFolder);
                        }
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("HighQualityTrapManager: Error scanning temp mods folder: " + e);
        }

        trace("HighQualityTrapManager: Found " + Lambda.count(songReplacements) + " song replacements across " + availableSiivaMods.length + " mods");
        trace("HighQualityTrapManager: Found " + siivaBaseGameSongs.length + " base game song replacements");
    }

    /**
     * Scan base game content (songs that replace base engine/non-mod songs)
     */
    private static function scanBaseGameContent(basePath:String):Void {
        var songsPath = haxe.io.Path.join([basePath, "songs"]);
        if (FileSystem.exists(songsPath) && FileSystem.isDirectory(songsPath)) {
            try {
                var songFolders = FileSystem.readDirectory(songsPath);

                for (songFolder in songFolders) {
                    var songPath = haxe.io.Path.join([songsPath, songFolder]);
                    if (FileSystem.isDirectory(songPath)) {
                        // Check if this song has the required audio files
                        var instFile = haxe.io.Path.join([songPath, "Inst.ogg"]);

                        if (FileSystem.exists(instFile)) {
                            // Check for corresponding chart file in data folder
                            var dataPath = haxe.io.Path.join([basePath, "data", songFolder]);
                            var chartFile = haxe.io.Path.join([dataPath, songFolder + ".json"]);

                            if (FileSystem.exists(chartFile)) {
                                // Create a default week for base game content
                                var defaultWeekName = "base-game-siiva";
                                var difficulties = ['Easy', 'Normal', 'Hard'];

                                // This is a valid base game replacement song
                                var replacementData:SiivaReplacementData = {
                                    originalSong: songFolder,
                                    replacementSong: songFolder,
                                    modName: BASE_GAME_MARKER,
                                    weekName: defaultWeekName
                                };

                                // Create or update the default week for base game
                                var weekKey = BASE_GAME_MARKER + ":" + defaultWeekName;
                                var weekData:SiivaWeekData;
                                if (siivaWeeks.exists(weekKey)) {
                                    weekData = siivaWeeks.get(weekKey);
                                } else {
                                    weekData = {
                                        weekName: defaultWeekName,
                                        songs: [],
                                        modName: BASE_GAME_MARKER,
                                        availableDifficulties: difficulties.copy()
                                    };
                                    siivaWeeks.set(weekKey, weekData);
                                }

                                // Add song to the week
                                weekData.songs.push(replacementData);

                                songReplacements.set(songFolder, replacementData);
                                songReplacements.set(BASE_GAME_MARKER + ":" + songFolder, replacementData);
                                siivaBaseGameSongs.push(songFolder);
                                trace('HighQualityTrapManager: Added base game replacement for "$songFolder" with default difficulties: ${difficulties.join(", ")}');
                            } else {
                                trace('HighQualityTrapManager: Base game song "$songFolder" has audio but no chart file at $chartFile');
                            }
                        }
                    }
                }
            } catch (e:Dynamic) {
                trace("HighQualityTrapManager: Error scanning base game content: " + e);
            }
        }
    }

    /**
     * Scan songs directory for available songs in a specific mod
     */
    private static function scanModSongsDirectory(songsPath:String, modName:String):Void {
        try {
            var songFolders = FileSystem.readDirectory(songsPath);

            for (songFolder in songFolders) {
                var songPath = haxe.io.Path.join([songsPath, songFolder]);
                if (FileSystem.isDirectory(songPath)) {
                    // Check if this song has the required audio files
                    var instFile = haxe.io.Path.join([songPath, "Inst.ogg"]);

                    if (FileSystem.exists(instFile)) {
                        // Check for corresponding chart file in data folder
                        var modBasePath = haxe.io.Path.join([TEMP_SIIVA_FOLDER, modName]);
                        var dataPath = haxe.io.Path.join([modBasePath, "data", songFolder]);
                        var chartFile = haxe.io.Path.join([dataPath, songFolder + ".json"]);

                        if (FileSystem.exists(chartFile)) {
                            // Create a default week for orphaned songs (songs without week files)
                            var defaultWeekName = "orphaned-songs";
                            var weekKey = modName + ":" + defaultWeekName;
                            
                            // Create default week if it doesn't exist
                            if (!siivaWeeks.exists(weekKey)) {
                                var defaultWeek:SiivaWeekData = {
                                    weekName: defaultWeekName,
                                    songs: [],
                                    modName: modName,
                                    availableDifficulties: ['Easy', 'Normal', 'Hard']
                                };
                                siivaWeeks.set(weekKey, defaultWeek);
                            }

                            // This is a valid replacement song
                            var replacementData:SiivaReplacementData = {
                                originalSong: songFolder, // Assume song folder name = original song name
                                replacementSong: songFolder,
                                modName: modName,
                                weekName: defaultWeekName
                            };

                            // Add to the default week
                            var defaultWeek = siivaWeeks.get(weekKey);
                            defaultWeek.songs.push(replacementData);

                            // Store both with and without mod prefix for flexible matching
                            songReplacements.set(songFolder, replacementData);
                            songReplacements.set(modName + ":" + songFolder, replacementData);
                            trace('HighQualityTrapManager: Added replacement for "$songFolder" from mod "$modName" with default difficulties: ${defaultWeek.availableDifficulties.join(", ")}');
                        } else {
                            trace('HighQualityTrapManager: Song "$songFolder" in mod "$modName" has audio but no chart file at $chartFile');
                        }
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("HighQualityTrapManager: Error scanning songs directory for mod $modName: " + e);
        }
    }

    /**
     * Check if the trap needs to trigger a waiting state for mod installation
     */
    public static function needsWaitingState():Bool {
        return isActive && !isDownloaded && isDownloading;
    }

    /**
     * Get the download progress (for the waiting state)
     */
    public static function getDownloadProgress():Float {
        return downloadProgress;
    }

    /**
     * Check if currently downloading
     */
    public static function isCurrentlyDownloading():Bool {
        return isDownloading;
    }

    /**
     * Force refresh the mod scanning (useful after download completes)
     */
    public static function refresh():Void {
        if (isDownloaded) {
            loadSiivaContent();
        }
    }

    /**
     * Cleanup on AP session end
     */
    public static function onAPSessionEnd():Void {
        trace("HighQualityTrapManager: AP Session ended, cleaning up...");
        deactivateTrap();
    }

    /**
     * Cleanup on engine exit
     */
    public static function onEngineExit():Void {
        trace("HighQualityTrapManager: Engine exiting, cleaning up...");
        cleanupTempFolder();
    }

    /**
     * Get available difficulties for a specific song (from the week it belongs to)
     */
    public static function getAvailableDifficulties(songName:String, ?modName:String):Array<String> {
        if (!isActive || !isInitialized) return ['normal']; // Default fallback

        var replacement = getReplacementData(songName, modName);
        if (replacement != null) {
            // Get the week this song belongs to
            var weekKey = replacement.modName + ":" + replacement.weekName;
            if (siivaWeeks.exists(weekKey)) {
                var weekData = siivaWeeks.get(weekKey);
                if (weekData.availableDifficulties != null && weekData.availableDifficulties.length > 0) {
                    return weekData.availableDifficulties.copy();
                }
            }
        }

        return ['normal']; // Default fallback
    }

    /**
     * Get available difficulties for a specific week
     */
    public static function getWeekDifficulties(weekName:String, modName:String):Array<String> {
        if (!isActive || !isInitialized) return ['normal']; // Default fallback

        var weekKey = modName + ":" + weekName;
        if (siivaWeeks.exists(weekKey)) {
            var weekData = siivaWeeks.get(weekKey);
            if (weekData.availableDifficulties != null && weekData.availableDifficulties.length > 0) {
                return weekData.availableDifficulties.copy();
            }
        }

        return ['normal']; // Default fallback
    }

    /**
     * Get the week name that a song belongs to
     */
    public static function getWeekForSong(songName:String, ?modName:String):String {
        if (!isActive || !isInitialized) return null;

        var replacement = getReplacementData(songName, modName);
        if (replacement != null) {
            return replacement.weekName;
        }

        return null;
    }

    /**
     * Check if a specific difficulty is available for a song
     */
    public static function isDifficultyAvailable(songName:String, difficulty:String, ?modName:String):Bool {
        var difficulties = getAvailableDifficulties(songName, modName);
        return difficulties.contains(difficulty.toLowerCase());
    }

    /**
     * Get SiivaGunner week data for a specific mod (compatible with WeekData format)
     */
    public static function getSiivaWeeksForMod(modName:String):Array<SiivaWeekData> {
        if (!isActive || !isInitialized) return [];

        var weeks:Array<SiivaWeekData> = [];
        for (key in siivaWeeks.keys()) {
            var weekData = siivaWeeks.get(key);
            if (weekData.modName == modName) {
                weeks.push(weekData);
            }
        }

        return weeks;
    }

    /**
     * Get all SiivaGunner weeks (for debugging and testing)
     */
    public static function getAllSiivaWeeks():Map<String, SiivaWeekData> {
        return siivaWeeks.copy();
    }

    /**
     * Filter difficulties for freeplay based on available SiivaGunner difficulties
     */
    public static function filterDifficulties(originalDifficulties:Array<String>, songName:String, ?modName:String):Array<String> {
        if (!isActive || !isInitialized) return originalDifficulties;

        var availableDifficulties = getAvailableDifficulties(songName, modName);

        // Only return difficulties that exist in both lists
        var filteredDifficulties:Array<String> = [];
        for (diff in originalDifficulties) {
            if (availableDifficulties.contains(diff.toLowerCase())) {
                filteredDifficulties.push(diff);
            }
        }

        // If no difficulties match, return the SiivaGunner difficulties
        if (filteredDifficulties.length == 0) {
            return availableDifficulties;
        }

        return filteredDifficulties;
    }

    /**
     * Get all available replacements for debugging and testing
     */
    public static function getAllReplacements():Map<String, SiivaReplacementData> {
        return songReplacements.copy();
    }

    /**
     * Get trap status info for debugging
     */
    public static function getStatusInfo():String {
        var info = [];
        info.push("High Quality Trap Status (SiivaGunner Temp Mods):");
        info.push("  Active: " + (isActive ? "YES" : "NO"));
        info.push("  Initialized: " + (isInitialized ? "YES" : "NO"));
        info.push("  Downloaded: " + (isDownloaded ? "YES" : "NO"));
        info.push("  Temp Folder: " + TEMP_SIIVA_FOLDER);
        info.push("  Available Mods: " + availableSiivaMods.length + " (" + availableSiivaMods.join(", ") + ")");
        info.push("  Base Game Songs: " + siivaBaseGameSongs.length + " (" + siivaBaseGameSongs.join(", ") + ")");
        info.push("  Song Replacements: " + Lambda.count(songReplacements));
        info.push("  Weeks: " + Lambda.count(siivaWeeks));

        if (Lambda.count(songReplacements) > 0) {
            info.push("  Available Replacements:");
            for (key in songReplacements.keys()) {
                var replacement = songReplacements.get(key);
                // Get difficulties from the week this song belongs to
                var weekKey = replacement.modName + ":" + replacement.weekName;
                var difficulties = "unknown";
                if (siivaWeeks.exists(weekKey)) {
                    var weekData = siivaWeeks.get(weekKey);
                    if (weekData.availableDifficulties != null) {
                        difficulties = weekData.availableDifficulties.join(", ");
                    }
                }
                info.push('    - "$key" -> "${replacement.replacementSong}" (from ${replacement.modName}, week: ${replacement.weekName}) [${difficulties}]');
            }
        }

        if (Lambda.count(siivaWeeks) > 0) {
            info.push("  Available Weeks:");
            for (key in siivaWeeks.keys()) {
                var week = siivaWeeks.get(key);
                info.push('    - "${week.weekName}" (${week.modName}) with ${week.songs.length} songs');
            }
        }

        return info.join("\n");
    }

    /**
     * Get the SiivaGunner path for a song's audio file (for Paths.inst, Paths.voices)
     * Returns null if High Quality Trap is not active or no replacement exists
     */
    public static function getSiivaAudioPath(songName:String, audioFile:String, currentMod:String = null):String {
        if (!isActive || !isInitialized) return null;

        // Use the current mod directory if no specific mod is provided
        if (currentMod == null && backend.Mods.currentModDirectory != null && backend.Mods.currentModDirectory.length > 0) {
            currentMod = backend.Mods.currentModDirectory;
        }

        var replacement = getReplacementData(songName, currentMod);
        if (replacement == null) return null;

        var modPath = getModPathForLoading(replacement.modName);
        return haxe.io.Path.join([modPath, "songs", replacement.replacementSong, audioFile]);
    }

    /**
     * Get the SiivaGunner path for a song's data file (for Paths.json with charts)
     * Returns null if High Quality Trap is not active or no replacement exists
     */
    public static function getSiivaDataPath(songName:String, dataFile:String, currentMod:String = null):String {
        if (!isActive || !isInitialized) return null;

        // Use the current mod directory if no specific mod is provided
        if (currentMod == null && backend.Mods.currentModDirectory != null && backend.Mods.currentModDirectory.length > 0) {
            currentMod = backend.Mods.currentModDirectory;
        }

        var replacement = getReplacementData(songName, currentMod);
        if (replacement == null) return null;

        var modPath = getModPathForLoading(replacement.modName);
        return haxe.io.Path.join([modPath, "data", replacement.replacementSong, dataFile]);
    }

    /**
     * Get replacement data for a song
     */
    private static function getReplacementData(songName:String, currentMod:String = null):SiivaReplacementData {
        if (!isActive || !isInitialized) return null;

        // Use the current mod directory if no specific mod is provided
        if (currentMod == null && backend.Mods.currentModDirectory != null && backend.Mods.currentModDirectory.length > 0) {
            currentMod = backend.Mods.currentModDirectory;
        }

        // Try exact match first (song + mod)
        var key = songName;
        if (currentMod != null && currentMod != "") {
            key = currentMod + ":" + songName;
            if (songReplacements.exists(key)) {
                return songReplacements.get(key);
            }
        }

        // Try song-only match (vanilla/no mod specified)
        if (songReplacements.exists(songName)) {
            return songReplacements.get(songName);
        }

        // Try base game marker match (for when no mod is specified but base game replacement exists)
        var baseGameKey = BASE_GAME_MARKER + ":" + songName;
        if (songReplacements.exists(baseGameKey)) {
            return songReplacements.get(baseGameKey);
        }

        return null;
    }
}
