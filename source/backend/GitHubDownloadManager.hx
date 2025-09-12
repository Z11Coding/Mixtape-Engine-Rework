package backend;

import haxe.Http;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Mutex;
import sys.thread.Thread;

using StringTools;

/**
 * GitHub Download Manager - Downloads all GitHub mod content locally for offline use
 * This solves the performance issue of making GitHub API requests during runtime
 */
class GitHubDownloadManager
{
    // Download status
    public static var isDownloading:Bool = false;
    public static var downloadProgress:Float = 0.0; // 0 to 1
    public static var downloadStatus:String = "";
    public static var totalFiles:Int = 0;
    public static var downloadedFiles:Int = 0;

    // Download queue
    private static var downloadQueue:Array<GitHubDownloadItem> = [];
    private static var downloadMutex:Mutex = new Mutex();

    // Local storage directory
    private static inline var DOWNLOAD_DIR:String = "github_mods";

    // Download completion callbacks
    private static var onCompleteCallbacks:Array<Void->Void> = [];
    private static var onProgressCallbacks:Array<Float->String->Void> = [];

    /**
     * Starts downloading all enabled GitHub mods content
     * @param onComplete Callback when download is finished
     * @param onProgress Callback for progress updates (progress: Float, status: String)
     */
    public static function downloadAllGitHubMods(?onComplete:Void->Void, ?onProgress:Float->String->Void):Void
    {
        if (isDownloading) {
            trace('GitHub download already in progress');
            if (onComplete != null) onCompleteCallbacks.push(onComplete);
            if (onProgress != null) onProgressCallbacks.push(onProgress);
            return;
        }

        // Register callbacks
        if (onComplete != null) onCompleteCallbacks.push(onComplete);
        if (onProgress != null) onProgressCallbacks.push(onProgress);

        isDownloading = true;
        downloadProgress = 0.0;
        downloadStatus = "Preparing GitHub mod download...";
        downloadedFiles = 0;
        totalFiles = 0;
        downloadQueue = [];

        // Create download directory
        if (!FileSystem.exists(DOWNLOAD_DIR)) {
            FileSystem.createDirectory(DOWNLOAD_DIR);
        }

        updateProgress();

        // Start download in background thread
        Thread.create(function() {
            try {
                collectAllFiles();
                downloadAllFiles();
                completeDownload();
            } catch (e:Dynamic) {
                trace('Error during GitHub download: $e');
                downloadStatus = "Download failed: " + Std.string(e);
                isDownloading = false;
                updateProgress();
            }
        });
    }

    /**
     * Collects all files from enabled GitHub mods/folders into download queue
     */
    private static function collectAllFiles():Void
    {
        downloadStatus = "Discovering mod files...";
        updateProgress();

        // Collect from individual GitHub mods
        for (mod in GitHubAPI.getEnabledGitHubMods()) {
            var modDir = '$DOWNLOAD_DIR/${mod.name}';
            if (!FileSystem.exists(modDir)) {
                FileSystem.createDirectory(modDir);
            }

            collectFilesFromRepository(mod.repository, mod.branch, mod.token, mod.name, "");
        }

        // Collect from GitHub mod folders
        for (folder in GitHubAPI.getEnabledGitHubModsFolders()) {
            var folderDir = '$DOWNLOAD_DIR/folder-${folder.name}';
            if (!FileSystem.exists(folderDir)) {
                FileSystem.createDirectory(folderDir);
            }

            // Only collect files for enabled mods within the folder
            for (modName in folder.discoveredMods) {
                if (folder.enabledMods.get(modName) == true) {
                    collectFilesFromRepository(folder.repository, folder.branch, folder.token, 'folder-${folder.name}', modName);
                }
            }
        }

        totalFiles = downloadQueue.length;
        trace('GitHub Download Manager: Found $totalFiles files to download');
    }

    /**
     * Recursively collects files from a GitHub repository
     */
    private static function collectFilesFromRepository(repository:String, branch:String, token:String, localModName:String, subPath:String):Void
    {
        var url = 'https://api.github.com/repos/$repository/contents/$subPath';
        if (branch != "main" && branch != "master") {
            url += '?ref=$branch';
        }

        try {
            var http = new Http(url);
            if (token != "") {
                http.addHeader("Authorization", "Bearer " + token);
            }
            http.addHeader("User-Agent", "Mixtape-Engine-GitHubDownloadManager");
            http.addHeader("Accept", "application/vnd.github.v3+json");

            var responseData:String = null;
            var responseError:String = null;

            http.onData = function(data:String) {
                responseData = data;
            };

            http.onError = function(error:String) {
                responseError = error;
                trace('Error fetching directory contents from $url: $error');
            };

            http.request(false);

            if (responseError != null || responseData == null) return;

            var jsonData = Json.parse(responseData);
            if (!Std.isOfType(jsonData, Array)) return;

            for (item in cast(jsonData, Array<Dynamic>)) {
                if (item.type == "file") {
                    // Add file to download queue
                    var localPath = subPath == "" ? item.name : '$subPath/${item.name}';
                    downloadQueue.push({
                        repository: repository,
                        branch: branch,
                        token: token,
                        remotePath: localPath,
                        localModName: localModName,
                        localPath: '$DOWNLOAD_DIR/$localModName/$localPath',
                        downloadUrl: item.download_url
                    });
                } else if (item.type == "dir") {
                    // Recursively collect from subdirectory
                    var nextSubPath = subPath == "" ? item.name : '$subPath/${item.name}';
                    collectFilesFromRepository(repository, branch, token, localModName, nextSubPath);
                }
            }
        } catch (e:Dynamic) {
            trace('Error collecting files from $repository/$subPath: $e');
        }
    }

    /**
     * Downloads all files in the download queue
     */
    private static function downloadAllFiles():Void
    {
        downloadStatus = "Downloading GitHub mod files...";

        for (i in 0...downloadQueue.length) {
            var item = downloadQueue[i];
            downloadStatus = 'Downloading ${item.remotePath}...';

            try {
                downloadSingleFile(item);
                downloadedFiles++;
                downloadProgress = downloadedFiles / totalFiles;
                updateProgress();
            } catch (e:Dynamic) {
                trace('Error downloading ${item.remotePath}: $e');
                // Continue with other files even if one fails
            }
        }
    }

    /**
     * Downloads a single file from GitHub
     */
    private static function downloadSingleFile(item:GitHubDownloadItem):Void
    {
        // Create directory if needed
        var dir = haxe.io.Path.directory(item.localPath);
        createDirectoryRecursive(dir);

        // Skip if file already exists and is recent
        if (FileSystem.exists(item.localPath)) {
            var stat = FileSystem.stat(item.localPath);
            var ageHours = (Date.now().getTime() - stat.mtime.getTime()) / (1000 * 60 * 60);
            if (ageHours < 24) { // Cache for 24 hours
                return; // Skip download
            }
        }

        var http = new Http(item.downloadUrl);
        if (item.token != "") {
            http.addHeader("Authorization", "Bearer " + item.token);
        }
        http.addHeader("User-Agent", "Mixtape-Engine-GitHubDownloadManager");

        var responseData:String = null;
        var responseError:String = null;

        http.onData = function(data:String) {
            responseData = data;
        };

        http.onError = function(error:String) {
            responseError = error;
            trace('Error downloading ${item.downloadUrl}: $error');
        };

        http.request(false);

        if (responseError == null && responseData != null) {
            try {
                File.saveContent(item.localPath, responseData);
                trace('Downloaded: ${item.localPath}');
            } catch (e:Dynamic) {
                trace('Error saving ${item.localPath}: $e');
            }
        }
    }

    /**
     * Completes the download process
     */
    private static function completeDownload():Void
    {
        isDownloading = false;
        downloadProgress = 1.0;
        downloadStatus = "GitHub mod download complete!";
        updateProgress();

        trace('GitHub Download Manager: Download complete! Downloaded $downloadedFiles/$totalFiles files');

        // Call completion callbacks
        for (callback in onCompleteCallbacks) {
            try {
                callback();
            } catch (e:Dynamic) {
                trace('Error in download complete callback: $e');
            }
        }

        // Clear callbacks
        onCompleteCallbacks = [];
        onProgressCallbacks = [];
    }

    /**
     * Updates progress and notifies callbacks
     */
    private static function updateProgress():Void
    {
        for (callback in onProgressCallbacks) {
            try {
                callback(downloadProgress, downloadStatus);
            } catch (e:Dynamic) {
                trace('Error in download progress callback: $e');
            }
        }
    }

    /**
     * Checks if GitHub mods are downloaded and available offline
     * @return True if all enabled mods are downloaded
     */
    public static function areGitHubModsDownloaded():Bool
    {
        if (!FileSystem.exists(DOWNLOAD_DIR)) {
            return false;
        }

        // Check individual GitHub mods
        for (mod in GitHubAPI.getEnabledGitHubMods()) {
            var modDir = '$DOWNLOAD_DIR/${mod.name}';
            if (!FileSystem.exists(modDir)) {
                return false;
            }
        }

        // Check GitHub mod folders
        for (folder in GitHubAPI.getEnabledGitHubModsFolders()) {
            var folderDir = '$DOWNLOAD_DIR/folder-${folder.name}';
            if (!FileSystem.exists(folderDir)) {
                return false;
            }

            // Check each enabled mod in the folder
            for (modName in folder.discoveredMods) {
                if (folder.enabledMods.get(modName) == true) {
                    var modSubDir = '$folderDir/$modName';
                    if (!FileSystem.exists(modSubDir)) {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    /**
     * Gets the local path for a GitHub file (replaces online GitHub API calls)
     * @param githubPath Path in format "github://modname/path/to/file" or "github://folder-foldername/modname/path/to/file"
     * @return Local file path, or null if not found
     */
    public static function getLocalGitHubFilePath(githubPath:String):String
    {
        if (!githubPath.startsWith("github://")) return null;

        var pathParts = githubPath.substring(9).split("/"); // Remove "github://"
        var modName = pathParts.shift();
        var filePath = pathParts.join("/");

        var localPath = '$DOWNLOAD_DIR/$modName/$filePath';

        return FileSystem.exists(localPath) ? localPath : null;
    }

    /**
     * Gets file content from downloaded GitHub mods (offline)
     * @param githubPath Path in GitHub format
     * @return File content as string, or null if not found
     */
    public static function getOfflineGitHubFile(githubPath:String):String
    {
        var localPath = getLocalGitHubFilePath(githubPath);
        if (localPath == null) return null;

        try {
            return File.getContent(localPath);
        } catch (e:Dynamic) {
            trace('Error reading offline GitHub file $localPath: $e');
            return null;
        }
    }

    /**
     * Gets binary data from downloaded GitHub mods (offline)
     * @param githubPath Path in GitHub format
     * @return ByteArray of file content, or null if not found
     */
    public static function getOfflineGitHubBinary(githubPath:String):ByteArray
    {
        var localPath = getLocalGitHubFilePath(githubPath);
        if (localPath == null) return null;

        try {
            var bytes = File.getBytes(localPath);
            var byteArray = new ByteArray();
            byteArray.writeBytes(bytes);
            return byteArray;
        } catch (e:Dynamic) {
            trace('Error reading offline GitHub binary $localPath: $e');
            return null;
        }
    }

    /**
     * Clears downloaded GitHub mod cache
     */
    public static function clearDownloadedMods():Void
    {
        if (FileSystem.exists(DOWNLOAD_DIR)) {
            try {
                deleteDirectoryRecursive(DOWNLOAD_DIR);
                FileSystem.createDirectory(DOWNLOAD_DIR);
                trace('Cleared GitHub mod downloads');
            } catch (e:Dynamic) {
                trace('Error clearing GitHub mod downloads: $e');
            }
        }
    }

    /**
     * Gets download statistics
     */
    public static function getDownloadStats():{totalMods:Int, totalFiles:Int, downloadSizeMB:Float}
    {
        var totalMods = 0;
        var totalFiles = 0;
        var totalSize = 0;

        if (FileSystem.exists(DOWNLOAD_DIR)) {
            totalMods = FileSystem.readDirectory(DOWNLOAD_DIR).length;
            countFilesRecursive(DOWNLOAD_DIR, {files: 0, size: 0});
            totalFiles = countResult.files;
            totalSize = countResult.size;
        }

        return {
            totalMods: totalMods,
            totalFiles: totalFiles,
            downloadSizeMB: totalSize / (1024 * 1024)
        };
    }

    private static var countResult:{files:Int, size:Int};

    private static function countFilesRecursive(path:String, result:{files:Int, size:Int}):Void
    {
        countResult = result;
        if (FileSystem.isDirectory(path)) {
            for (item in FileSystem.readDirectory(path)) {
                countFilesRecursive('$path/$item', result);
            }
        } else {
            result.files++;
            try {
                result.size += FileSystem.stat(path).size;
            } catch (e:Dynamic) {
                // Ignore stat errors
            }
        }
    }

    // Helper functions

    private static function createDirectoryRecursive(path:String):Void
    {
        var parts = path.replace("\\", "/").split("/");
        var current = "";

        for (i in 0...parts.length) {
            current += parts[i];
            if (current.length > 0 && !FileSystem.exists(current)) {
                FileSystem.createDirectory(current);
            }
            if (i < parts.length - 1) current += "/";
        }
    }

    private static function deleteDirectoryRecursive(path:String):Void
    {
        if (!FileSystem.exists(path)) return;

        if (FileSystem.isDirectory(path)) {
            for (file in FileSystem.readDirectory(path)) {
                deleteDirectoryRecursive('$path/$file');
            }
            FileSystem.deleteDirectory(path);
        } else {
            FileSystem.deleteFile(path);
        }
    }
}

/**
 * Represents a file to be downloaded from GitHub
 */
typedef GitHubDownloadItem = {
    var repository:String;      // GitHub repo in "owner/repo" format
    var branch:String;          // Branch to download from
    var token:String;           // Authentication token
    var remotePath:String;      // Path in the GitHub repository
    var localModName:String;    // Local mod name for organization
    var localPath:String;       // Local file path where to save
    var downloadUrl:String;     // Direct download URL from GitHub API
}
