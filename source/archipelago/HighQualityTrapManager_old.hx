package archipelago;

import backend.GitHubAPI;
import backend.WeekData;
import backend.Paths;
import backend.ClientPrefs;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import yutautil.TypeUtils.OneOrMore;

typedef SiivaReplacementData = {
    var originalSong:String;
    var replacementSong:String;
    var modName:String;
}

typedef SiivaModInfo = {
    var name:String;
    var version:String;
    var description:String;
}

/**
 * HighQualityTrapManager
 * Manages the "High Quality Trap" system for Archipelago mode.
 * Downloads SiivaGunner repo to a temporary folder and treats it like the entire mods directory.
 * The name is a joke reference to SiivaGunner's "High Quality Video Game Rips".
 */
class HighQualityTrapManager {
    // The joke name references SiivaGunner's "High Quality Video Game Rips"
    public static final SIIVA_REPO:String = "SiivaGunner/FNF-Rips"; // Adjust to actual repo
    public static final TEMP_SIIVA_FOLDER:String = "./temp_siivagunner_mods";
    
    private static var isActive:Bool = false;
    private static var isDownloaded:Bool = false;
    private static var songReplacements:Map<String, SiivaReplacementData> = new Map();
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
            // Scan for mods in the temp folder (treats it like the entire mods directory)
            scanTempModsFolder();
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
            // Already downloaded, just scan for mods
            scanTempModsFolder();
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
    }

    /**
     * Check if the trap is currently active
     */
    public static function isTrapActive():Bool {
        return isActive;
    }

    /**
     * Get replacement song for a given original song
     */
    public static function getReplacementSong(originalSong:String, ?modName:String):String {
        if (!isActive || !isInitialized) return originalSong;
        
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
        
        // Try song-only match
        if (songReplacements.exists(originalSong)) {
            var replacement = songReplacements.get(originalSong);
            trace('HighQualityTrapManager: Replacing "$originalSong" with "${replacement.replacementSong}"');
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
        
        var key = originalSong;
        if (modName != null && modName != "") {
            key = modName + ":" + originalSong;
            if (songReplacements.exists(key)) return true;
        }
        
        return songReplacements.exists(originalSong);
    }

    /**
     * Get all available replacements for debugging
     */
    public static function getAllReplacements():Map<String, SiivaReplacementData> {
        return songReplacements.copy();
    }

    /**
     * Download SiivaGunner repository to temp folder (treats it like entire mods directory)
     */
    private static function downloadSiivaRepo():Void {
        trace("HighQualityTrapManager: Starting download of SiivaGunner repo to temp folder...");
        
        var config:GitHubAPI.DownloadConfig = {
            repo: SIIVA_REPO,
            destination: TEMP_SIIVA_FOLDER,
            onProgress: function(current:Int, total:Int, fileName:String) {
                trace('HighQualityTrapManager: Downloading file ${current}/${total}: $fileName');
            },
            onFileProgress: function(progress:Float, fileName:String) {
                // Could show individual file progress if needed
            },
            onComplete: function(downloadedFiles:Array<String>) {
                trace("HighQualityTrapManager: Download complete! Files: " + downloadedFiles.length);
                isDownloaded = true;
                scanTempModsFolder();
                trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
            },
            onError: function(error:String) {
                trace("HighQualityTrapManager: Download failed: " + error);
                // Trap fails gracefully - just continues without replacements
            }
        };

        // Clone the entire repository to temp folder (structure like entire mods directory)
        GitHubAPI.cloneRepository(SIIVA_REPO, TEMP_SIIVA_FOLDER, null,
            config.onProgress,
            config.onFileProgress, 
            function(path:String) {
                trace("HighQualityTrapManager: SiivaGunner repo downloaded to temp folder: " + path);
                isDownloaded = true;
                scanTempModsFolder();
                trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
            },
            function(error:String) {
                trace("HighQualityTrapManager: Download failed: " + error);
            }
        );
    }

    /**
     * Scan the temp folder for mods (treats temp folder like the entire mods directory)
     */
    private static function scanTempModsFolder():Void {
        trace("HighQualityTrapManager: Scanning temp SiivaGunner folder (treating as mods directory)...");
        
        songReplacements.clear();
        
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
                    // Scan this mod folder for songs
                    var songsPath = haxe.io.Path.join([modPath, "songs"]);
                    if (FileSystem.exists(songsPath) && FileSystem.isDirectory(songsPath)) {
                        scanModSongsDirectory(songsPath, modFolder);
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("HighQualityTrapManager: Error scanning temp mods folder: " + e);
        }
        
        trace("HighQualityTrapManager: Found " + Lambda.count(songReplacements) + " song replacements");
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
                    // Check if this song has the required files (Inst.ogg, chart files)
                    var instFile = haxe.io.Path.join([songPath, "Inst.ogg"]);
                    var chartFile = haxe.io.Path.join([songPath, songFolder + ".json"]);
                    
                    if (FileSystem.exists(instFile) && FileSystem.exists(chartFile)) {
                        // This is a valid replacement song
                        var replacementData:SiivaReplacementData = {
                            originalSong: songFolder, // Assume song folder name = original song name
                            replacementSong: songFolder,
                            modName: modName
                        };
                        
                        // Store both with and without mod prefix for flexible matching
                        songReplacements.set(songFolder, replacementData);
                        songReplacements.set(modName + ":" + songFolder, replacementData);
                        trace('HighQualityTrapManager: Added replacement for "$songFolder" from mod "$modName"');
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
        return isActive && !isDownloaded;
    }

    /**
     * Get the download progress (for the waiting state)
     */
    public static function getDownloadProgress():Float {
        // This would need to be implemented if we want detailed progress
        // For now, just return simple status
        return isDownloaded ? 1.0 : 0.0;
    }

    /**
     * Force refresh the mod scanning (useful after download completes)
     */
    public static function refresh():Void {
        if (isDownloaded) {
            scanTempModsFolder();
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
     * Get trap status info for debugging
     */
    public static function getStatusInfo():String {
        var info = [];
        info.push("High Quality Trap Status (SiivaGunner Temp Mods):");
        info.push("  Active: " + (isActive ? "YES" : "NO"));
        info.push("  Initialized: " + (isInitialized ? "YES" : "NO"));
        info.push("  Downloaded: " + (isDownloaded ? "YES" : "NO"));
        info.push("  Temp Folder: " + TEMP_SIIVA_FOLDER);
        info.push("  Song Replacements: " + Lambda.count(songReplacements));
        
        if (Lambda.count(songReplacements) > 0) {
            info.push("  Available Replacements:");
            for (key in songReplacements.keys()) {
                var replacement = songReplacements.get(key);
                info.push('    - "$key" -> "${replacement.replacementSong}" (from ${replacement.modName})');
            }
        }
        
        return info.join("\n");
    }
}

import backend.GitHubAPI;
import backend.WeekData;
import backend.Paths;
import backend.ClientPrefs;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import yutautil.TypeUtils.OneOrMore;

typedef SiivaReplacementData = {
    var originalSong:String;
    var replacementSong:String;
    var modName:String;
}

typedef SiivaModInfo = {
    var name:String;
    var version:String;
    var description:String;
}

/**
 * HighQualityTrapManager
 * Manages the "High Quality Trap" system for Archipelago mode.
 * Downloads SiivaGunner repo to a temporary folder and treats it like the entire mods directory.
 * The name is a joke reference to SiivaGunner's "High Quality Video Game Rips".
 */
class HighQualityTrapManager {
    // The joke name references SiivaGunner's "High Quality Video Game Rips"
    public static final SIIVA_REPO:String = "SiivaGunner/FNF-Rips"; // Adjust to actual repo
    public static final TEMP_SIIVA_FOLDER:String = "./temp_siivagunner_mods";
    
    private static var isActive:Bool = false;
    private static var isDownloaded:Bool = false;
    private static var songReplacements:Map<String, SiivaReplacementData> = new Map();
    private static var isInitialized:Bool = false;

    /**
     * Initialize the High Quality Trap system
     * The name is a joke reference to SiivaGunner's "High Quality Video Game Rips"
     */
    public static function initialize():Void {
        if (isInitialized) return;
        
        trace("HighQualityTrapManager: Initializing High Quality Trap system...");
        
        // Ensure mods directory exists
        if (!FileSystem.exists("./mods")) {
            FileSystem.createDirectory("./mods");
        }
        
        // Check if SiivaGunner mod is already downloaded
        checkExistingDownload();
        
        isInitialized = true;
        trace("HighQualityTrapManager: High Quality Trap system initialized!");
    }

    /**
     * Check if SiivaGunner mod is already downloaded
     */
    private static function checkExistingDownload():Void {
        if (FileSystem.exists(SIIVA_MOD_FOLDER) && FileSystem.isDirectory(SIIVA_MOD_FOLDER)) {
            trace("HighQualityTrapManager: Found existing SiivaGunner mod folder");
            isDownloaded = true;
            // Scan for songs in the mod folder
            scanModFolder();
        } else {
            trace("HighQualityTrapManager: No existing SiivaGunner mod found");
            isDownloaded = false;
        }
    }

    /**
     * Activate the High Quality Trap
     * Downloads the SiivaGunner repo as a mod if not already present
     */
    public static function activateTrap():Void {
        if (!isInitialized) initialize();
        
        trace("HighQualityTrapManager: Activating High Quality Trap!");
        isActive = true;
        
        // Download the repo as a mod if not already downloaded
        if (!isDownloaded) {
            downloadSiivaRepo();
        } else {
            // Already downloaded, just scan for songs
            scanModFolder();
            trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
        }
    }

    /**
     * Deactivate the High Quality Trap
     */
    public static function deactivateTrap():Void {
        trace("HighQualityTrapManager: Deactivating High Quality Trap");
        isActive = false;
    }

    /**
     * Check if the trap is currently active
     */
    public static function isTrapActive():Bool {
        return isActive;
    }

    /**
     * Get replacement song for a given original song
     */
    public static function getReplacementSong(originalSong:String, ?modName:String):String {
        if (!isActive || !isInitialized) return originalSong;
        
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
        
        // Try song-only match
        if (songReplacements.exists(originalSong)) {
            var replacement = songReplacements.get(originalSong);
            trace('HighQualityTrapManager: Replacing "$originalSong" with "${replacement.replacementSong}"');
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
        
        var key = originalSong;
        if (modName != null && modName != "") {
            key = modName + ":" + originalSong;
            if (songReplacements.exists(key)) return true;
        }
        
        return songReplacements.exists(originalSong);
    }

    /**
     * Get all available replacements for debugging
     */
    public static function getAllReplacements():Map<String, SiivaReplacementData> {
        return songReplacements.copy();
    }

    /**
     * Download SiivaGunner repository as a mod
     */
    private static function downloadSiivaRepo():Void {
        trace("HighQualityTrapManager: Starting download of SiivaGunner mod...");
        
        var config:GitHubAPI.DownloadConfig = {
            repo: SIIVA_REPO,
            destination: SIIVA_MOD_FOLDER,
            onProgress: function(current:Int, total:Int, fileName:String) {
                trace('HighQualityTrapManager: Downloading file ${current}/${total}: $fileName');
            },
            onFileProgress: function(progress:Float, fileName:String) {
                // Could show individual file progress if needed
            },
            onComplete: function(downloadedFiles:Array<String>) {
                trace("HighQualityTrapManager: Download complete! Files: " + downloadedFiles.length);
                isDownloaded = true;
                scanModFolder();
                trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
            },
            onError: function(error:String) {
                trace("HighQualityTrapManager: Download failed: " + error);
                // Trap fails gracefully - just continues without replacements
            }
        };

        // Clone the entire repository as a mod
        GitHubAPI.cloneRepository(SIIVA_REPO, SIIVA_MOD_FOLDER, null,
            config.onProgress,
            config.onFileProgress, 
            function(path:String) {
                trace("HighQualityTrapManager: SiivaGunner mod downloaded to: " + path);
                isDownloaded = true;
                scanModFolder();
                trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
            },
            function(error:String) {
                trace("HighQualityTrapManager: Download failed: " + error);
            }
        );
    }

    /**
     * Scan the SiivaGunner mod folder for songs (like any other mod)
     */
    private static function scanModFolder():Void {
        trace("HighQualityTrapManager: Scanning SiivaGunner mod folder...");
        
        songReplacements.clear();
        
        if (!FileSystem.exists(SIIVA_MOD_FOLDER)) {
            trace("HighQualityTrapManager: SiivaGunner mod folder not found");
            return;
        }

        // Scan for songs in the standard mod structure
        var songsPath = haxe.io.Path.join([SIIVA_MOD_FOLDER, "songs"]);
        if (FileSystem.exists(songsPath) && FileSystem.isDirectory(songsPath)) {
            scanSongsDirectory(songsPath);
        }
        
        trace("HighQualityTrapManager: Found " + Lambda.count(songReplacements) + " song replacements");
    }

    /**
     * Scan songs directory for available songs
     */
    private static function scanSongsDirectory(songsPath:String):Void {
        try {
            var songFolders = FileSystem.readDirectory(songsPath);
            
            for (songFolder in songFolders) {
                var songPath = haxe.io.Path.join([songsPath, songFolder]);
                if (FileSystem.isDirectory(songPath)) {
                    // Check if this song has the required files (Inst.ogg, Voices.ogg, chart files)
                    var instFile = haxe.io.Path.join([songPath, "Inst.ogg"]);
                    var chartFile = haxe.io.Path.join([songPath, songFolder + ".json"]);
                    
                    if (FileSystem.exists(instFile) && FileSystem.exists(chartFile)) {
                        // This is a valid replacement song
                        var replacementData:SiivaReplacementData = {
                            originalSong: songFolder, // Assume song folder name = original song name
                            replacementSong: songFolder,
                            modName: "SiivaGunner"
                        };
                        
                        songReplacements.set(songFolder, replacementData);
                        trace('HighQualityTrapManager: Added replacement for "$songFolder"');
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("HighQualityTrapManager: Error scanning songs directory: " + e);
        }
    }

    /**
     * Check if the trap needs to trigger a waiting state for mod installation
     */
    public static function needsWaitingState():Bool {
        return isActive && !isDownloaded;
    }

    /**
     * Get the download progress (for the waiting state)
     */
    public static function getDownloadProgress():Float {
        // This would need to be implemented if we want detailed progress
        // For now, just return simple status
        return isDownloaded ? 1.0 : 0.0;
    }

    /**
     * Force refresh the mod scanning (useful after download completes)
     */
    public static function refresh():Void {
        if (isDownloaded) {
            scanModFolder();
        }
    }

    /**
     * Get trap status info for debugging
     */
    public static function getStatusInfo():String {
        var info = [];
        info.push("High Quality Trap Status (SiivaGunner Mod):");
        info.push("  Active: " + (isActive ? "YES" : "NO"));
        info.push("  Initialized: " + (isInitialized ? "YES" : "NO"));
        info.push("  Downloaded: " + (isDownloaded ? "YES" : "NO"));
        info.push("  Song Replacements: " + Lambda.count(songReplacements));
        
        if (Lambda.count(songReplacements) > 0) {
            info.push("  Available Replacements:");
            for (key in songReplacements.keys()) {
                var replacement = songReplacements.get(key);
                info.push('    - "$key" -> "${replacement.replacementSong}"');
            }
        }
        
        return info.join("\n");
    }
}

typedef SiivaReplacementData = {
    var originalSong:String;
    var replacementSong:String;
    var modName:String;
}

typedef SiivaModInfo = {
    var name:String;
    var version:String;
    var description:String;
}

class HighQualityTrapManager {
    // The joke name references SiivaGunner's "High Quality Video Game Rips"
    public static final SIIVA_REPO:String = "SiivaGunner/FNF-Rips"; // Adjust to actual repo
    public static final SIIVA_MOD_FOLDER:String = "./mods/SiivaGunner";
    
    private static var isActive:Bool = false;
    private static var isDownloaded:Bool = false;
    private static var songReplacements:Map<String, SiivaReplacementData> = new Map();
    private static var isInitialized:Bool = false;

    /**
     * Initialize the High Quality Trap system
     * The name is a joke reference to SiivaGunner's "High Quality Video Game Rips"
     */
    public static function initialize():Void {
        if (isInitialized) return;
        
        trace("HighQualityTrapManager: Initializing High Quality Trap system...");
        
        // Ensure mods directory exists
        if (!FileSystem.exists("./mods")) {
            FileSystem.createDirectory("./mods");
        }
        
        // Check if SiivaGunner mod is already downloaded
        checkExistingDownload();
        
        isInitialized = true;
        trace("HighQualityTrapManager: High Quality Trap system initialized!");
    }

    /**
     * Check if SiivaGunner mod is already downloaded
     */
    private static function checkExistingDownload():Void {
        if (FileSystem.exists(SIIVA_MOD_FOLDER) && FileSystem.isDirectory(SIIVA_MOD_FOLDER)) {
            trace("HighQualityTrapManager: Found existing SiivaGunner mod folder");
            isDownloaded = true;
            // Scan for songs in the mod folder
            scanModFolder();
        } else {
            trace("HighQualityTrapManager: No existing SiivaGunner mod found");
            isDownloaded = false;
        }
    }

    /**
     * Activate the High Quality Trap
     * Downloads the SiivaGunner repo as a mod if not already present
     */
    public static function activateTrap():Void {
        if (!isInitialized) initialize();
        
        trace("HighQualityTrapManager: Activating High Quality Trap!");
        isActive = true;
        
        // Download the repo as a mod if not already downloaded
        if (!isDownloaded) {
            downloadSiivaRepo();
        } else {
            // Already downloaded, just scan for songs
            scanModFolder();
            trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
        }
    }

    /**
     * Deactivate the High Quality Trap
     */
    public static function deactivateTrap():Void {
        trace("HighQualityTrapManager: Deactivating High Quality Trap");
        isActive = false;
    }

    /**
     * Check if the trap is currently active
     */
    public static function isTrapActive():Bool {
        return isActive;
    }

    /**
     * Get replacement song for a given original song
     */
    public static function getReplacementSong(originalSong:String, ?modName:String):String {
        if (!isActive || !isInitialized) return originalSong;
        
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
        
        // Try song-only match
        if (songReplacements.exists(originalSong)) {
            var replacement = songReplacements.get(originalSong);
            trace('HighQualityTrapManager: Replacing "$originalSong" with "${replacement.replacementSong}"');
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
        
        var key = originalSong;
        if (modName != null && modName != "") {
            key = modName + ":" + originalSong;
            if (songReplacements.exists(key)) return true;
        }
        
        return songReplacements.exists(originalSong);
    }

    /**
     * Get all available replacements for debugging
     */
    public static function getAllReplacements():Map<String, SiivaReplacementData> {
        return songReplacements.copy();
    }

    /**
     * Download SiivaGunner repository as a mod
     */
    private static function downloadSiivaRepo():Void {
        trace("HighQualityTrapManager: Starting download of SiivaGunner mod...");
        
        var config:GitHubAPI.DownloadConfig = {
            repo: SIIVA_REPO,
            destination: SIIVA_MOD_FOLDER,
            onProgress: function(current:Int, total:Int, fileName:String) {
                trace('HighQualityTrapManager: Downloading file ${current}/${total}: $fileName');
            },
            onFileProgress: function(progress:Float, fileName:String) {
                // Could show individual file progress if needed
            },
            onComplete: function(downloadedFiles:Array<String>) {
                trace("HighQualityTrapManager: Download complete! Files: " + downloadedFiles.length);
                isDownloaded = true;
                scanModFolder();
                trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
            },
            onError: function(error:String) {
                trace("HighQualityTrapManager: Download failed: " + error);
                // Trap fails gracefully - just continues without replacements
            }
        };

        // Clone the entire repository as a mod
        GitHubAPI.cloneRepository(SIIVA_REPO, SIIVA_MOD_FOLDER, null,
            config.onProgress,
            config.onFileProgress, 
            function(path:String) {
                trace("HighQualityTrapManager: SiivaGunner mod downloaded to: " + path);
                isDownloaded = true;
                scanModFolder();
                trace("HighQualityTrapManager: Trap activated with " + Lambda.count(songReplacements) + " song replacements");
            },
            function(error:String) {
                trace("HighQualityTrapManager: Download failed: " + error);
            }
        );
    }

    /**
     * Scan the SiivaGunner mod folder for songs (like any other mod)
     */
    private static function scanModFolder():Void {
        trace("HighQualityTrapManager: Scanning SiivaGunner mod folder...");
        
        songReplacements.clear();
        
        if (!FileSystem.exists(SIIVA_MOD_FOLDER)) {
            trace("HighQualityTrapManager: SiivaGunner mod folder not found");
            return;
        }

        // Scan for songs in the standard mod structure
        var songsPath = haxe.io.Path.join([SIIVA_MOD_FOLDER, "songs"]);
        if (FileSystem.exists(songsPath) && FileSystem.isDirectory(songsPath)) {
            scanSongsDirectory(songsPath);
        }
        
        trace("HighQualityTrapManager: Found " + Lambda.count(songReplacements) + " song replacements");
    }

    /**
     * Scan songs directory for available songs
     */
    private static function scanSongsDirectory(songsPath:String):Void {
        try {
            var songFolders = FileSystem.readDirectory(songsPath);
            
            for (songFolder in songFolders) {
                var songPath = haxe.io.Path.join([songsPath, songFolder]);
                if (FileSystem.isDirectory(songPath)) {
                    // Check if this song has the required files (Inst.ogg, Voices.ogg, chart files)
                    var instFile = haxe.io.Path.join([songPath, "Inst.ogg"]);
                    var chartFile = haxe.io.Path.join([songPath, songFolder + ".json"]);
                    
                    if (FileSystem.exists(instFile) && FileSystem.exists(chartFile)) {
                        // This is a valid replacement song
                        var replacementData:SiivaReplacementData = {
                            originalSong: songFolder, // Assume song folder name = original song name
                            replacementSong: songFolder,
                            modName: "SiivaGunner"
                        };
                        
                        songReplacements.set(songFolder, replacementData);
                        trace('HighQualityTrapManager: Added replacement for "$songFolder"');
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("HighQualityTrapManager: Error scanning songs directory: " + e);
        }
    }
            
            for (item in items) {
                var itemPath = haxe.io.Path.join([SIIVA_FOLDER, item]);
                
                if (FileSystem.isDirectory(itemPath)) {
                    // Check if this is a mod pack directory
                    var packInfoPath = haxe.io.Path.join([itemPath, "pack_info.json"]);
                    if (FileSystem.exists(packInfoPath)) {
                        try {
                            var packContent = File.getContent(packInfoPath);
                            var pack:SiivaModPack = Json.parse(packContent);
                            downloadedPacks.push(pack);
                            trace('HighQualityTrapManager: Found pack "${pack.name}" with ${pack.songs.length} songs');
                        } catch (e:Dynamic) {
                            trace("HighQualityTrapManager: Failed to parse pack info for " + item + ": " + e);
                        }
                    }
                }
            }
            
            trace("HighQualityTrapManager: Scanned and found " + downloadedPacks.length + " packs");
        } catch (e:Dynamic) {
            trace("HighQualityTrapManager: Failed to scan for pack files: " + e);
        }
    }

    /**
     * Load existing packs from local storage
     */
    private static function loadExistingPacks():Void {
        if (!FileSystem.exists(SIIVA_FOLDER)) return;
        
        processSiivaPacks();
        
        if (downloadedPacks.length > 0) {
            buildReplacementMap();
        }
    }

    /**
     * Build the song replacement map from loaded packs
     */
    private static function buildReplacementMap():Void {
        songReplacements.clear();
        
        for (pack in downloadedPacks) {
            for (song in pack.songs) {
                // Add both mod-specific and general mappings
                var modKey = song.modName + ":" + song.originalSong;
                var generalKey = song.originalSong;
                
                songReplacements.set(modKey, song);
                
                // Only set general key if it doesn't exist (first pack wins)
                if (!songReplacements.exists(generalKey)) {
                    songReplacements.set(generalKey, song);
                }
            }
        }
        
        trace("HighQualityTrapManager: Built replacement map with " + Lambda.count(songReplacements) + " entries");
    }

    /**
     * Check if a mod is supported by any downloaded pack
     */
    public static function isModSupported(modName:String):Bool {
        if (!isInitialized || downloadedPacks.length == 0) return false;
        
        for (pack in downloadedPacks) {
            for (song in pack.songs) {
                if (song.modName == modName) {
                    return true;
                }
            }
        }
        
        return false;
    }

    /**
     * Get supported mods list
     */
    public static function getSupportedMods():Array<String> {
        var mods:Array<String> = [];
        
        if (!isInitialized || downloadedPacks.length == 0) return mods;
        
        for (pack in downloadedPacks) {
            for (song in pack.songs) {
                if (!mods.contains(song.modName)) {
                    mods.push(song.modName);
                }
            }
        }
        
        return mods;
    }

    /**
     * Force refresh packs (re-download)
     */
    public static function refreshPacks(?onComplete:Void->Void):Void {
        trace("HighQualityTrapManager: Force refreshing packs...");
        
        // Clear existing data
        downloadedPacks = [];
        songReplacements.clear();
        
        // Delete existing folder and recreate
        if (FileSystem.exists(SIIVA_FOLDER)) {
            try {
                // Simple folder deletion (recursive)
                deleteDirectory(SIIVA_FOLDER);
            } catch (e:Dynamic) {
                trace("HighQualityTrapManager: Failed to delete existing folder: " + e);
            }
        }
        
        FileSystem.createDirectory(SIIVA_FOLDER);
        
        // Re-download
        downloadSiivaPacks(onComplete);
    }

    /**
     * Simple recursive directory deletion
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
     * Get trap status info for debugging
     */
    public static function getStatusInfo():String {
        var info = [];
        info.push("High Quality Trap Status:");
        info.push("  Active: " + (isActive ? "YES" : "NO"));
        info.push("  Initialized: " + (isInitialized ? "YES" : "NO"));
        info.push("  Downloaded Packs: " + downloadedPacks.length);
        info.push("  Song Replacements: " + Lambda.count(songReplacements));
        
        if (downloadedPacks.length > 0) {
            info.push("  Packs:");
            for (pack in downloadedPacks) {
                info.push('    - ${pack.name} (${pack.songs.length} songs)');
            }
        }
        
        return info.join("\n");
    }
}