package backend;

import Lambda;
import backend.GitHubDownloadManager;
import haxe.Http;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
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

    // Missing file tracking for download management
    private static var missingGitHubFiles:Array<MissingGitHubFile> = [];
    private static var downloadTriggered:Bool = false;

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
            discoveredMods: [],
            enabledMods: new Map<String, Bool>()
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
        var modsFolder:Dynamic = null;
        for (folder in githubModsFolders) {
            if (folder.name == folderName && folder.enabled) {
                modsFolder = folder;
                break;
            }
        }
        if (modsFolder == null) return;

        // Try to get directory listing from the repository root
        var directories = listGitHubDirectories(modsFolder, "", true); // Use detailed response
        if (directories != null) {
            modsFolder.discoveredMods = directories;

            // Initialize enabled state for new mods (default to enabled)
            for (modName in directories) {
                if (!modsFolder.enabledMods.exists(modName)) {
                    modsFolder.enabledMods.set(modName, true);
                }
            }

            trace('Discovered ${directories.length} mods in GitHub folder "$folderName": ${directories.join(", ")}');
        } else {
            trace('Could not discover mods in GitHub folder "$folderName"');
        }
    }

    /**
     * Lists directories in a GitHub repository (used for discovering mods)
     */
    private static function listGitHubDirectories(modsFolder:GitHubModsFolder, path:String, ?useDetailedResponse:Bool = false):Array<String>
    {
        var url = 'https://api.github.com/repos/${modsFolder.repository}/contents/$path?ref=${modsFolder.branch}';

        trace('Listing GitHub directories: $url');

        try {
            var http = new Http(url);
            if (modsFolder.token != "") {
                http.addHeader("Authorization", "Bearer " + modsFolder.token);
                if (useDetailedResponse) {
                    http.addHeader("Accept", "application/vnd.github.object+json");
                }
                http.addHeader("X-GitHub-Api-Version", "2022-11-28");
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

            try {
                var jsonData = Json.parse(responseData);
                var directories:Array<String> = [];

                trace('GitHub directory listing for ${modsFolder.repository}/$path: $responseData');

                // Handle both response formats
                var itemsArray:Array<Dynamic> = null;

                if (useDetailedResponse && Reflect.hasField(jsonData, "entries")) {
                    // Detailed response format with entries array
                    itemsArray = cast(Reflect.field(jsonData, "entries"), Array<Dynamic>);
                } else if (Std.isOfType(jsonData, Array)) {
                    // Simple array response format
                    itemsArray = cast(jsonData, Array<Dynamic>);
                } else {
                    trace('Unknown GitHub API response format');
                    return null;
                }

                if (itemsArray != null) {
                    for (item in itemsArray) {
                        if (item.type == "dir") {
                            directories.push(item.name);
                        }
                    }
                }

                return directories;
            } catch (e:Dynamic) {
                if (responseError != null) {
                    trace('Error parsing GitHub directory response: $responseError');
                } else {
                    trace('Error parsing GitHub directory response: $e');
                }
                return null;
            }

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
     * Enables or disables a specific mod within a GitHub mods folder
     * @param folderName Name of the GitHub mods folder
     * @param modName Name of the specific mod within the folder
     * @param enabled Whether to enable or disable this specific mod
     */
    public static function setGitHubFolderModEnabled(folderName:String, modName:String, enabled:Bool):Void
    {
        for (folder in githubModsFolders) {
            if (folder.name == folderName) {
                folder.enabledMods.set(modName, enabled);
                trace('${enabled ? "Enabled" : "Disabled"} mod "$modName" in GitHub folder "$folderName"');
                break;
            }
        }
    }

    /**
     * Checks if a specific mod within a GitHub mods folder is enabled
     * @param folderName Name of the GitHub mods folder
     * @param modName Name of the specific mod within the folder
     * @return True if the mod is enabled, false otherwise
     */
    public static function isGitHubFolderModEnabled(folderName:String, modName:String):Bool
    {
        for (folder in githubModsFolders) {
            if (folder.name == folderName) {
                return folder.enabled && folder.enabledMods.get(modName) == true;
            }
        }
        return false;
    }

    /**
     * Gets all enabled mods from GitHub mods folders
     * @return Array of mod names that are enabled across all GitHub mods folders
     */
    public static function getEnabledGitHubFolderMods():Array<String>
    {
        var enabledMods:Array<String> = [];
        for (folder in githubModsFolders) {
            if (folder.enabled) {
                for (modName in folder.discoveredMods) {
                    if (folder.enabledMods.get(modName) == true && !enabledMods.contains(modName)) {
                        enabledMods.push(modName);
                    }
                }
            }
        }
        return enabledMods;
    }

    /**
     * Gets all mods within a specific GitHub mods folder (both enabled and disabled)
     * @param folderName Name of the GitHub mods folder
     * @return Array of {modName: String, enabled: Bool} objects
     */
    public static function getGitHubFolderModList(folderName:String):Array<{modName:String, enabled:Bool}>
    {
        for (folder in githubModsFolders) {
            if (folder.name == folderName) {
                var modList:Array<{modName:String, enabled:Bool}> = [];
                for (modName in folder.discoveredMods) {
                    modList.push({
                        modName: modName,
                        enabled: folder.enabledMods.get(modName) == true
                    });
                }
                return modList;
            }
        }
        return [];
    }

    /**
     * Checks if a file exists in any GitHub mod, similar to how modFolders works
     * Now also checks GitHub mods folders (repositories containing multiple mods)
     * FAST VERSION: Only checks offline downloads, avoids slow API calls
     * @param key File path relative to the mod root
     * @return Full path to the file if found offline, null if not found
     */
    public static function githubModFolders(key:String):String
    {
        // First check individual GitHub mods (offline only)
        for (mod in getEnabledGitHubMods()) {
            var fullPath = 'github://${mod.name}/$key';

            // Check if file exists offline
            var offlineFile = GitHubDownloadManager.getLocalGitHubFilePath(fullPath);
            if (offlineFile != null) {
                return fullPath;
            }
        }

        // Then check GitHub mods folders (repositories containing multiple mods, offline only)
        for (modsFolder in getEnabledGitHubModsFolders()) {
            // Check each enabled mod in this folder
            for (modName in modsFolder.discoveredMods) {
                if (modsFolder.enabledMods.get(modName) == true) {
                    var modPath = '$modName/$key';
                    var fullPath = 'github://folder-${modsFolder.name}/$modPath';

                    // Check if file exists offline
                    var offlineFile = GitHubDownloadManager.getLocalGitHubFilePath(fullPath);
                    if (offlineFile != null) {
                        return fullPath;
                    }
                }
            }
        }

        // File not found offline
        return null;
    }
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
     * Now prioritizes offline downloaded content for performance
     * @param githubPath Path in format "github://modname/path/to/file" or "github://folder-foldername/modname/path/to/file"
     * @return File content as string, or null if not found
     */
    public static function getGitHubFile(githubPath:String):String
    {
        // Try offline download first (much faster)
        var offlineContent = GitHubDownloadManager.getOfflineGitHubFile(githubPath);
        if (offlineContent != null) {
            return offlineContent;
        }

        // Fallback to online API request (slower)
        trace('GitHub file not found offline, attempting online request: $githubPath');

        if (!githubPath.startsWith("github://")) return null;

        var pathParts = githubPath.substring(9).split("/"); // Remove "github://"
        var modName = pathParts.shift();
        var filePath = pathParts.join("/");

        // Check if this is a folder-based path (starts with "folder-")
        if (modName.startsWith("folder-")) {
            var folderName = modName.substring(7); // Remove "folder-" prefix
            var modsFolder:Dynamic = null;
            for (folder in githubModsFolders) {
                if (folder.name == folderName && folder.enabled) {
                    modsFolder = folder;
                    break;
                }
            }
            if (modsFolder == null) return null;

            // Extract the specific mod name from the file path and check if it's enabled
            var firstSlash = filePath.indexOf("/");
            if (firstSlash != -1) {
                var specificModName = filePath.substring(0, firstSlash);
                if (modsFolder.enabledMods.get(specificModName) != true) {
                    return null; // This specific mod within the folder is disabled
                }
            }

            // The filePath already includes the mod name, so use it directly
            return fetchFileFromGitHubRepo(modsFolder.repository, modsFolder.branch, modsFolder.token, filePath);
        } else {
            // This is a regular single-mod GitHub repository
            var mod:Dynamic = null;
            for (m in githubMods) {
                if (m.name == modName && m.enabled) {
                    mod = m;
                    break;
                }
            }
            if (mod == null) return null;

            return fetchFileFromGitHubRepo(mod.repository, mod.branch, mod.token, filePath);
        }
    }

    /**
     * Gets binary data from GitHub
     * Now prioritizes offline downloaded content for performance
     * @param githubPath Path in format "github://modname/path/to/file" or "github://folder-foldername/modname/path/to/file"
     * @return ByteArray of file content, or null if not found
     */
    public static function getGitHubBinary(githubPath:String):ByteArray
    {
        // Try offline download first (much faster)
        var offlineBinary = GitHubDownloadManager.getOfflineGitHubBinary(githubPath);
        if (offlineBinary != null) {
            return offlineBinary;
        }

        // Fallback to online API request (slower)
        trace('GitHub binary not found offline, attempting online request: $githubPath');

        if (!githubPath.startsWith("github://")) return null;

        var pathParts = githubPath.substring(9).split("/");
        var modName = pathParts.shift();
        var filePath = pathParts.join("/");

        // Check if this is a folder-based path (starts with "folder-")
        if (modName.startsWith("folder-")) {
            var folderName = modName.substring(7); // Remove "folder-" prefix
            var modsFolder:Dynamic = null;
            for (folder in githubModsFolders) {
                if (folder.name == folderName && folder.enabled) {
                    modsFolder = folder;
                    break;
                }
            }
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
            var mod:Dynamic = null;
            for (m in githubMods) {
                if (m.name == modName && m.enabled) {
                    mod = m;
                    break;
                }
            }
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
                http.addHeader("Authorization", "Bearer " + token);
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
                http.addHeader("Authorization", "Bearer " + token);
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
        // For now, use text fetch and convert to ByteArray
        var textData = fetchFileFromGitHubRepo(repository, branch, token, filePath);
        if (textData != null) {
            var bytes = haxe.io.Bytes.ofString(textData);
            var byteArray = new ByteArray();
            byteArray.writeBytes(bytes);
            return byteArray;
        }
        return null;
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

        // Add enabled mods from folders (with folder prefix)
        for (folder in getEnabledGitHubModsFolders()) {
            for (modName in folder.discoveredMods) {
                if (folder.enabledMods.get(modName) == true) {
                    modNames.push(modName);
                }
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

    /**
     * Gets the list of files in a directory from a GitHub mod
     * @param modName Name of the mod to check
     * @param directoryPath Path to the directory (e.g., "weeks/")
     * @return Array of filenames in the directory, null if not found
     */
    public static function getGitHubDirectoryContents(modName:String, directoryPath:String):Array<String>
    {
        // Find the mod
        var targetMod:GitHubMod = null;
        for (mod in getEnabledGitHubMods()) {
            if (mod.name == modName) {
                targetMod = mod;
                break;
            }
        }

        if (targetMod == null) {
            // Check in GitHub mods folders
            for (folder in getEnabledGitHubModsFolders()) {
                if (folder.discoveredMods.contains(modName)) {
                    return getGitHubDirectoryContentsFromFolder(folder, modName, directoryPath);
                }
            }
            return [];
        }

        // Use GitHub API to get directory contents
        return getDirectoryContentsFromRepo(targetMod.repository, targetMod.branch, targetMod.token, directoryPath);
    }

    private static function getGitHubDirectoryContentsFromFolder(folder:GitHubModsFolder, modName:String, directoryPath:String):Array<String>
    {
        var fullPath = modName + '/' + directoryPath;
        return getDirectoryContentsFromRepo(folder.repository, folder.branch, folder.token, fullPath);
    }

    private static function getDirectoryContentsFromRepo(repository:String, branch:String, token:String, directoryPath:String):Array<String>
    {
        var url = 'https://api.github.com/repos/$repository/contents/$directoryPath';
        if (branch != "main" && branch != "master") {
            url += '?ref=$branch';
        }

        try {
            var http = new Http(url);
            if (token != "") {
                http.addHeader("Authorization", "Bearer " + token);
            }
            http.addHeader("User-Agent", "Mixtape-Engine-GitHubAPI");
            http.addHeader("Accept", "application/vnd.github.v3+json");

            var responseData:String = null;
            var responseError:String = null;

            http.onData = function(data:String) {
                responseData = data;
            };

            http.onError = function(error:String) {
                responseError = error;
            };

            http.request(false);

            if (responseError != null || responseData == null) {
                return [];
            }

            // Parse JSON response
            var jsonData = Json.parse(responseData);
            var files:Array<String> = [];

            // Handle both response formats
            var itemsArray:Array<Dynamic> = null;

            if (Reflect.hasField(jsonData, "entries")) {
                // Detailed response format with entries array
                itemsArray = cast(Reflect.field(jsonData, "entries"), Array<Dynamic>);
            } else if (Std.isOfType(jsonData, Array)) {
                // Simple array response format
                itemsArray = cast(jsonData, Array<Dynamic>);
            } else {
                trace('Unknown GitHub API response format in getDirectoryContentsFromRepo');
                return [];
            }

            if (itemsArray != null) {
                for (item in itemsArray) {
                    if (item.type == "file" && item.name != null) {
                        files.push(item.name);
                    }
                }
            }

            return files;
        } catch (e:Dynamic) {
            trace('Error getting directory contents from GitHub: $e');
            return [];
        }
    }

    // Missing GitHub file management

    /**
     * Adds a file to the missing files list for later download
     */
    private static function addMissingGitHubFile(modName:String, repository:String, branch:String, token:String, filePath:String, isFolder:Bool):Void
    {
        // Check if this file is already in the missing list
        for (missing in missingGitHubFiles) {
            if (missing.modName == modName && missing.filePath == filePath) {
                return; // Already tracked
            }
        }

        missingGitHubFiles.push({
            modName: modName,
            repository: repository,
            branch: branch,
            token: token,
            filePath: filePath,
            isFolder: isFolder,
            timestamp: Date.now().getTime()
        });

        trace('Added missing GitHub file to download queue: $modName/$filePath');
    }

    /**
     * Checks if any GitHub mods are missing downloaded files
     * @return True if there are missing files that need downloading
     */
    public static function hasMissingGitHubFiles():Bool
    {
        return missingGitHubFiles.length > 0;
    }

    /**
     * Gets the list of missing GitHub files
     */
    public static function getMissingGitHubFiles():Array<MissingGitHubFile>
    {
        return missingGitHubFiles.copy();
    }

    /**
     * Clears the missing files list
     */
    public static function clearMissingGitHubFiles():Void
    {
        missingGitHubFiles = [];
        downloadTriggered = false;
    }

    /**
     * Triggers download for all missing GitHub files
     * @param onComplete Callback when download is complete
     * @param onProgress Progress callback
     */
    public static function downloadMissingFiles(?onComplete:Void->Void, ?onProgress:Float->String->Void):Void
    {
        if (missingGitHubFiles.length == 0) {
            if (onComplete != null) onComplete();
            return;
        }

        if (downloadTriggered) {
            trace('Download already triggered for missing files');
            return;
        }

        downloadTriggered = true;
        trace('Triggering download for ${missingGitHubFiles.length} missing GitHub files');

        // Use the existing GitHubDownloadManager to download everything
        GitHubDownloadManager.downloadAllGitHubMods(
            function() {
                trace('Missing GitHub files download completed');
                clearMissingGitHubFiles();
                if (onComplete != null) onComplete();
            },
            onProgress
        );
    }

    /**
     * Automatically checks all configured GitHub mods for missing files
     * This is useful for doing a comprehensive check without waiting for file requests
     * FAST VERSION: Only checks offline content, avoids slow API calls during loading
     */
    public static function checkAllConfiguredMods():Void
    {
        trace('Checking all configured GitHub mods for missing files (offline only)...');

        // Check individual GitHub mods (offline only for performance)
        for (mod in getEnabledGitHubMods()) {
            // Check for common mod files
            var commonFiles = ["meta.json", "data/data.json", "weeks/weekList.txt"];
            for (file in commonFiles) {
                var fullPath = 'github://${mod.name}/$file';
                var offlineFile = GitHubDownloadManager.getLocalGitHubFilePath(fullPath);
                if (offlineFile == null) {
                    // File not found offline - mark for later download but don't check online now
                    // This prevents slow loading times during normal operation
                    trace('Missing offline GitHub file: $fullPath (will download later if requested)');
                    addMissingGitHubFile(mod.name, mod.repository, mod.branch, mod.token, file, false);
                }
            }
        }

        // Check GitHub mod folders (offline only for performance)
        for (folder in getEnabledGitHubModsFolders()) {
            for (modName in folder.discoveredMods) {
                if (folder.enabledMods.get(modName) == true) {
                    // Check for common mod files in each enabled mod
                    var commonFiles = ["meta.json", "data/data.json"];
                    for (file in commonFiles) {
                        var modPath = '$modName/$file';
                        var fullPath = 'github://folder-${folder.name}/$modPath';
                        var offlineFile = GitHubDownloadManager.getLocalGitHubFilePath(fullPath);
                        if (offlineFile == null) {
                            // File not found offline - mark for later download but don't check online now
                            trace('Missing offline GitHub file: $fullPath (will download later if requested)');
                            addMissingGitHubFile('folder-${folder.name}', folder.repository, folder.branch, folder.token, modPath, true);
                        }
                    }
                }
            }
        }

        var missingCount = missingGitHubFiles.length;
        if (missingCount > 0) {
            trace('Found $missingCount missing GitHub files that are not downloaded offline');
        } else {
            trace('All configured GitHub mods appear to be downloaded offline');
        }
    }
}

/**
 * Typedef for tracking missing GitHub files that need to be downloaded
 */
typedef MissingGitHubFile = {
    var modName:String;
    var repository:String;
    var branch:String;
    var token:String;
    var filePath:String;
    var isFolder:Bool;
    var timestamp:Float;
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
    var enabledMods:Map<String, Bool>; // Individual enable/disable state for each mod
}

/**
 * Structure for cached file metadata
 */
typedef CachedFile = {
    var path:String;
    var timestamp:Float;
    var size:Int;
}
