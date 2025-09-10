package backend;

import haxe.Http;
import haxe.Json;
import haxe.crypto.Base64;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * GitHub API integration class for loading assets from GitHub repositories
 * Works like a virtual mod folder that can be accessed through the normal Paths system
 * Supports both single-mod repositories and multi-mod "mods folder" repositories
 */
class GitHubAPI
{
    // GitHub repositories that act as "virtual mod folders"
    public static var githubMods:Array<GitHubMod> = [];
    // GitHub repositories that act as entire "mods directories" containing multiple mods
    public static var githubModsFolders:Array<GitHubModsFolder> = [];
    public static var cacheDirectory:String = "github_cache";
    public static var useCache:Bool = true;
    public static var maxCacheAge:Float = 3600; // 1 hour in seconds

    // GitHub API endpoints
    private static inline var GITHUB_RAW_BASE:String = "https://raw.githubusercontent.com";

    // Cache management
    private static var fileCache:Map<String, CachedFile> = new Map();

    /**
     * Adds a GitHub repository as a virtual mod folder
     * @param name Virtual mod name (used for priority ordering)
     * @param repo Repository in format "owner/repo"
     * @param branch Branch to use (default: "main")
     * @param token Optional authentication token
     * @param priority Priority level (lower = higher priority, like mods)
     */
    public static function addGitHubMod(name:String, repo:String, ?branch:String = "main", ?token:String = "", ?priority:Int = 0):Void
    {
        // Remove existing mod with same name
        githubMods = githubMods.filter(mod -> mod.name != name);

        // Add new mod
        githubMods.push({
            name: name,
            repository: repo,
            branch: branch,
            token: token,
            priority: priority,
            enabled: true
        });

        // Sort by priority (lower number = higher priority)
        githubMods.sort((a, b) -> a.priority - b.priority);

        trace('Added GitHub mod: $name ($repo/$branch) with priority $priority');
    }

    /**
     * Adds a GitHub repository as an entire "mods folder" containing multiple mods
     * @param name Virtual mods folder name
     * @param repo Repository in format "owner/repo"
     * @param branch Branch to use (default: "main")
     * @param token Optional authentication token
     * @param priority Priority level for all mods in this folder
     */
    public static function addGitHubModsFolder(name:String, repo:String, ?branch:String = "main", ?token:String = "", ?priority:Int = 0):Void
    {
        // Remove existing mods folder with same name
        githubModsFolders = githubModsFolders.filter(folder -> folder.name != name);

        // Add new mods folder
        githubModsFolders.push({
            name: name,
            repository: repo,
            branch: branch,
            token: token,
            priority: priority,
            enabled: true,
            discoveredMods: []
        });

        // Sort by priority (lower number = higher priority)
        githubModsFolders.sort((a, b) -> a.priority - b.priority);

        trace('Added GitHub mods folder: $name ($repo/$branch) with priority $priority');

        // Discover mods in this folder
        discoverModsInFolder(name);
    }

    /**
     * Discovers available mods in a GitHub mods folder by listing directories
     * @param folderName Name of the GitHub mods folder to scan
     */
    public static function discoverModsInFolder(folderName:String):Void
    {
        var modsFolder = githubModsFolders.find(f -> f.name == folderName && f.enabled);
        if (modsFolder == null) return;

        // Try to get directory listing from the repository root
        var directories = listGitHubDirectories(modsFolder, "");
        if (directories != null) {
            modsFolder.discoveredMods = directories;
            trace('Discovered ${directories.length} mods in GitHub folder "$folderName": ${directories.join(", ")}');
        } else {
            trace('Could not discover mods in GitHub folder "$folderName"');
        }
    }

    /**
     * Lists directories in a GitHub repository (used for discovering mods)
     */
    private static function listGitHubDirectories(modsFolder:GitHubModsFolder, path:String):Array<String>
    {
        var url = 'https://api.github.com/repos/${modsFolder.repository}/contents/$path?ref=${modsFolder.branch}';

        try {
            var http = new Http(url);
            if (modsFolder.token != "") {
                http.addHeader("Authorization", "token " + modsFolder.token);
            }
            http.addHeader("User-Agent", "Mixtape-Engine-GitHubAPI");

            var responseData:String = null;
            var responseError:String = null;

            http.onData = function(data:String) {
                responseData = data;
            };

            http.onError = function(error:String) {
                responseError = error;
            };

            http.request(false);

            if (responseError != null || responseData == null) return null;

            var jsonData = Json.parse(responseData);
            var directories:Array<String> = [];

            for (item in cast(jsonData, Array<Dynamic>)) {
                if (item.type == "dir") {
                    directories.push(item.name);
                }
            }

            return directories;
        } catch (e:Dynamic) {
            trace('Error listing GitHub directories: $e');
            return null;
        }
    }

    /**
     * Removes a GitHub mod
     * @param name Name of the mod to remove
     */
    public static function removeGitHubMod(name:String):Void
    {
        githubMods = githubMods.filter(mod -> mod.name != name);
        trace('Removed GitHub mod: $name');
    }

    /**
     * Removes a GitHub mods folder
     * @param name Name of the mods folder to remove
     */
    public static function removeGitHubModsFolder(name:String):Void
    {
        githubModsFolders = githubModsFolders.filter(folder -> folder.name != name);
        trace('Removed GitHub mods folder: $name');
    }

    /**
     * Enables or disables a GitHub mod
     * @param name Name of the mod
     * @param enabled Whether to enable or disable
     */
    public static function setGitHubModEnabled(name:String, enabled:Bool):Void
    {
        for (mod in githubMods) {
            if (mod.name == name) {
                mod.enabled = enabled;
                trace('${enabled ? "Enabled" : "Disabled"} GitHub mod: $name');
                break;
            }
        }
    }

    /**
     * Enables or disables a GitHub mods folder
     * @param name Name of the mods folder
     * @param enabled Whether to enable or disable
     */
    public static function setGitHubModsFolderEnabled(name:String, enabled:Bool):Void
    {
        for (folder in githubModsFolders) {
            if (folder.name == name) {
                folder.enabled = enabled;
                trace('${enabled ? "Enabled" : "Disabled"} GitHub mods folder: $name');
                break;
            }
        }
    }

    /**
     * Gets enabled GitHub mods in priority order
     */
    public static function getEnabledGitHubMods():Array<GitHubMod>
    {
        return githubMods.filter(mod -> mod.enabled);
    }

    /**
     * Checks if a file exists in any GitHub mod, similar to how modFolders works
     * Now also checks GitHub mods folders (repositories containing multiple mods)
     * @param key File path relative to the mod root
     * @return Full path to the file if found, null if not found
     */
    public static function githubModFolders(key:String):String
    {
        // First check individual GitHub mods
        for (mod in getEnabledGitHubMods()) {
            var fullPath = 'github://${mod.name}/$key';
            if (checkGitHubFileExists(mod.repository, mod.branch, mod.token, key)) {
                return fullPath;
            }
        }

        // Then check GitHub mods folders (repositories containing multiple mods)
        for (modsFolder in getEnabledGitHubModsFolders()) {
            // Check each discovered mod in this folder
            for (modName in modsFolder.discoveredMods) {
                var modPath = '$modName/$key';
                var fullPath = 'github://folder-${modsFolder.name}/$modPath';
                if (checkGitHubFileExists(modsFolder.repository, modsFolder.branch, modsFolder.token, modPath)) {
                    return fullPath;
                }
            }
        }

        return null;
    }

    /**
     * Gets enabled GitHub mods folders in priority order
     */
    public static function getEnabledGitHubModsFolders():Array<GitHubModsFolder>
    {
        return githubModsFolders.filter(folder -> folder.enabled);
    }

    /**
     * Gets file content from GitHub, works like File.getContent() but for GitHub
     * @param githubPath Path in format "github://modname/path/to/file" or "github://folder-foldername/modname/path/to/file"
     * @return File content as string, or null if not found
     */
    public static function getGitHubFile(githubPath:String):String
    {
        if (!githubPath.startsWith("github://")) return null;

        var pathParts = githubPath.substring(9).split("/"); // Remove "github://"
        var modName = pathParts.shift();
        var filePath = pathParts.join("/");

        // Check if this is a folder-based path (starts with "folder-")
        if (modName.startsWith("folder-")) {
            var folderName = modName.substring(7); // Remove "folder-" prefix
            var modsFolder = githubModsFolders.find(f -> f.name == folderName && f.enabled);
            if (modsFolder == null) return null;

            // The filePath already includes the mod name, so use it directly
            return fetchFileFromGitHubRepo(modsFolder.repository, modsFolder.branch, modsFolder.token, filePath);
        } else {
            // This is a regular single-mod GitHub repository
            var mod = githubMods.find(m -> m.name == modName && m.enabled);
            if (mod == null) return null;

            return fetchFileFromGitHubRepo(mod.repository, mod.branch, mod.token, filePath);
        }
    }

    /**
     * Gets binary data from GitHub
     * @param githubPath Path in format "github://modname/path/to/file" or "github://folder-foldername/modname/path/to/file"
     * @return ByteArray of file content, or null if not found
     */
    public static function getGitHubBinary(githubPath:String):ByteArray
    {
        if (!githubPath.startsWith("github://")) return null;

        var pathParts = githubPath.substring(9).split("/");
        var modName = pathParts.shift();
        var filePath = pathParts.join("/");

        // Check if this is a folder-based path (starts with "folder-")
        if (modName.startsWith("folder-")) {
            var folderName = modName.substring(7); // Remove "folder-" prefix
            var modsFolder = githubModsFolders.find(f -> f.name == folderName && f.enabled);
            if (modsFolder == null) return null;

            // Check cache first
            var cacheKey = '${modsFolder.repository}/${modsFolder.branch}/$filePath';
            var localPath = getCachePath(cacheKey);

            if (useCache && FileSystem.exists(localPath) && isCacheValid(cacheKey)) {
                try {
                    return File.getBytes(localPath);
                } catch (e:Dynamic) {
                    trace('Error reading cached binary: $e');
                }
            }

            // Fetch from GitHub
            var binaryData = fetchBinaryFromGitHubRepo(modsFolder.repository, modsFolder.branch, modsFolder.token, filePath);
            if (binaryData != null && useCache) {
                saveBinaryToCache(cacheKey, binaryData);
            }

            return binaryData;
        } else {
            // This is a regular single-mod GitHub repository
            var mod = githubMods.find(m -> m.name == modName && m.enabled);
            if (mod == null) return null;

            // Check cache first
            var cacheKey = '${mod.repository}/${mod.branch}/$filePath';
            var localPath = getCachePath(cacheKey);

            if (useCache && FileSystem.exists(localPath) && isCacheValid(cacheKey)) {
                try {
                    return File.getBytes(localPath);
                } catch (e:Dynamic) {
                    trace('Error reading cached binary: $e');
                }
            }

            // Fetch from GitHub
            var binaryData = fetchBinaryFromGitHubRepo(mod.repository, mod.branch, mod.token, filePath);
            if (binaryData != null && useCache) {
                saveBinaryToCache(cacheKey, binaryData);
            }

            return binaryData;
        }
    }

    /**
     * Checks if a file exists in a specific GitHub repository
     */
    private static function checkGitHubFileExists(repository:String, branch:String, token:String, filePath:String):Bool
    {
        // For now, we'll do a simple HEAD request to check existence
        // This could be optimized by caching directory listings
        var url = '$GITHUB_RAW_BASE/$repository/$branch/$filePath';

        try {
            var http = new Http(url);
            if (token != "") {
                http.addHeader("Authorization", "token " + token);
            }
            http.addHeader("User-Agent", "Mixtape-Engine-GitHubAPI");

            var responseCode:Int = 0;
            http.onStatus = function(status:Int) {
                responseCode = status;
            };

            http.request(true); // HEAD request
            return responseCode == 200;
        } catch (e:Dynamic) {
            return false;
        }
    }

    /**
     * Fetches file content from a specific GitHub repository
     */
    private static function fetchFileFromGitHubRepo(repository:String, branch:String, token:String, filePath:String):String
    {
        // Check cache first
        var cacheKey = '$repository/$branch/$filePath';
        if (useCache && isCacheValid(cacheKey)) {
            return getCachedFile(cacheKey);
        }

        var url = '$GITHUB_RAW_BASE/$repository/$branch/$filePath';

        try {
            var http = new Http(url);
            if (token != "") {
                http.addHeader("Authorization", "token " + token);
            }
            http.addHeader("User-Agent", "Mixtape-Engine-GitHubAPI");

            var responseData:String = null;
            var responseError:String = null;

            http.onData = function(data:String) {
                responseData = data;
            };

            http.onError = function(error:String) {
                responseError = error;
            };

            http.request(false); // Synchronous request

            if (responseError == null && responseData != null && useCache) {
                cacheFile(cacheKey, responseData);
            }

            return responseError == null ? responseData : null;
        } catch (e:Dynamic) {
            trace('Error fetching from GitHub: $e');
            return null;
        }
    }

    /**
     * Fetches binary data from a specific GitHub repository
     */
    private static function fetchBinaryFromGitHubRepo(repository:String, branch:String, token:String, filePath:String):ByteArray
    {
        var url = '$GITHUB_RAW_BASE/$repository/$branch/$filePath';

        try {
            var http = new Http(url);
            if (token != "") {
                http.addHeader("Authorization", "token " + token);
            }
            http.addHeader("User-Agent", "Mixtape-Engine-GitHubAPI");

            var responseData:ByteArray = null;
            var responseError:String = null;

            http.onBytes = function(data:ByteArray) {
                responseData = data;
            };

            http.onError = function(error:String) {
                responseError = error;
            };

            http.request(false);

            return responseError == null ? responseData : null;
        } catch (e:Dynamic) {
            trace('Error fetching binary from GitHub: $e');
            return null;
        }
    }

    /**
     * Clears the GitHub cache
     */
    public static function clearCache():Void
    {
        fileCache.clear();

        if (FileSystem.exists(cacheDirectory)) {
            try {
                deleteCacheDirectory(cacheDirectory);
                trace('GitHub cache cleared');
            } catch (e:Dynamic) {
                trace('Error clearing cache: $e');
            }
        }
    }

    /**
     * Gets all GitHub mods and mods from folders in priority order
     * @return Array of all virtual mod names for debugging/management
     */
    public static function getAllGitHubModNames():Array<String>
    {
        var modNames:Array<String> = [];

        // Add individual mods
        for (mod in getEnabledGitHubMods()) {
            modNames.push(mod.name);
        }

        // Add mods from folders
        for (folder in getEnabledGitHubModsFolders()) {
            for (modName in folder.discoveredMods) {
                modNames.push('${folder.name}/$modName');
            }
        }

        return modNames;
    }

    // Private helper methods for caching

    private static function getCachePath(cacheKey:String):String
    {
        var fileName = cacheKey.replace("/", "_").replace("\\", "_").replace(":", "_");
        return '$cacheDirectory/$fileName';
    }

    private static function cacheFile(cacheKey:String, content:String):Void
    {
        try {
            var localPath = getCachePath(cacheKey);
            var dir = haxe.io.Path.directory(localPath);

            if (!FileSystem.exists(dir)) {
                createDirectoryRecursive(dir);
            }

            File.saveContent(localPath, content);

            fileCache.set(cacheKey, {
                path: localPath,
                timestamp: Date.now().getTime(),
                size: content.length
            });

        } catch (e:Dynamic) {
            trace('Error caching file: $e');
        }
    }

    private static function saveBinaryToCache(cacheKey:String, data:ByteArray):Void
    {
        try {
            var localPath = getCachePath(cacheKey);
            var dir = haxe.io.Path.directory(localPath);

            if (!FileSystem.exists(dir)) {
                createDirectoryRecursive(dir);
            }

            File.saveBytes(localPath, data);

            fileCache.set(cacheKey, {
                path: localPath,
                timestamp: Date.now().getTime(),
                size: data.length
            });

        } catch (e:Dynamic) {
            trace('Error caching binary file: $e');
        }
    }

    private static function isCacheValid(cacheKey:String):Bool
    {
        if (!fileCache.exists(cacheKey)) return false;

        var cached = fileCache.get(cacheKey);
        var currentTime = Date.now().getTime();
        var ageInSeconds = (currentTime - cached.timestamp) / 1000;

        return ageInSeconds < maxCacheAge && FileSystem.exists(cached.path);
    }

    private static function getCachedFile(cacheKey:String):String
    {
        if (!fileCache.exists(cacheKey)) return null;

        var cached = fileCache.get(cacheKey);
        if (!FileSystem.exists(cached.path)) {
            fileCache.remove(cacheKey);
            return null;
        }

        try {
            return File.getContent(cached.path);
        } catch (e:Dynamic) {
            trace('Error reading cached file: $e');
            return null;
        }
    }

    private static function createDirectoryRecursive(path:String):Void
    {
        var parts = path.split("/");
        var current = "";

        for (part in parts) {
            current += part + "/";
            if (!FileSystem.exists(current)) {
                FileSystem.createDirectory(current);
            }
        }
    }

    private static function deleteCacheDirectory(path:String):Void
    {
        if (!FileSystem.exists(path)) return;

        if (FileSystem.isDirectory(path)) {
            for (file in FileSystem.readDirectory(path)) {
                deleteCacheDirectory('$path/$file');
            }
            FileSystem.deleteDirectory(path);
        } else {
            FileSystem.deleteFile(path);
        }
    }
}

/**
 * Represents a GitHub repository acting as a virtual mod
 */
typedef GitHubMod = {
    var name:String;           // Virtual mod name
    var repository:String;     // GitHub repo in "owner/repo" format
    var branch:String;         // Branch to use
    var token:String;          // Authentication token (optional)
    var priority:Int;          // Priority order (lower = higher priority)
    var enabled:Bool;          // Whether this mod is enabled
}

/**
 * Represents a GitHub repository acting as an entire "mods folder" containing multiple mods
 */
typedef GitHubModsFolder = {
    var name:String;           // Virtual mods folder name
    var repository:String;     // GitHub repo in "owner/repo" format
    var branch:String;         // Branch to use
    var token:String;          // Authentication token (optional)
    var priority:Int;          // Priority order (lower = higher priority)
    var enabled:Bool;          // Whether this mods folder is enabled
    var discoveredMods:Array<String>; // List of mod directories found in this repository
}

/**
 * Structure for cached file metadata
 */
typedef CachedFile = {
    var path:String;
    var timestamp:Float;
    var size:Int;
}
