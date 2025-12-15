package backend;

import backend.GitHubAPI.DownloadConfig;
import backend.GitHubAPI.GitHubAsset;
import backend.GitHubAPI.GitHubCreateRelease;
import backend.GitHubAPI.GitHubFileContent;
import backend.GitHubAPI.GitHubRelease;
import backend.GitHubAPI.GitHubRepository;
import backend.GitHubAPI.GitHubTree;
import backend.GitHubAPI.GitHubUser;
import backend.GitHubAPI;

/**
 * Synchronous wrapper for GitHubAPI that provides direct result functions
 * instead of callback-based ones. Uses internal callback handling to
 * provide blocking/direct return behavior.
 */
class GitHubHelper {

	/**
	 * Get public releases (blocks until result is available)
	 * @return Array of releases, or null if error occurred
	 */
	public static function getPublicReleases():Array<GitHubRelease> {
		var result:Array<GitHubRelease> = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.getPublicReleases(
			function(releases:Array<GitHubRelease>) {
				result = releases;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		// Wait for completion
		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.getPublicReleases error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Get user information (blocks until result is available)
	 * @return User info, or null if error occurred or not authenticated
	 */
	public static function getUserInfo():GitHubUser {
		if (!GitHubAPI.isAuthenticated()) {
			trace("GitHubHelper.getUserInfo error: Not authenticated");
			return null;
		}

		var result:GitHubUser = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.getUserInfo(
			function(user:GitHubUser) {
				result = user;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.getUserInfo error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Check if user has repository access (blocks until result is available)
	 * @return true if has access, false otherwise
	 */
	public static function hasRepoAccess():Bool {
		if (!GitHubAPI.isAuthenticated()) {
			trace("GitHubHelper.hasRepoAccess error: Not authenticated");
			return false;
		}

		var result:Bool = false;
		var error:String = null;
		var completed = false;

		GitHubAPI.hasRepoAccess(
			function(hasAccess:Bool) {
				result = hasAccess;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.hasRepoAccess error: " + error);
		}

		return result;
	}

	/**
	 * Create a release (blocks until result is available)
	 * @param releaseData Release information
	 * @return Created release, or null if error occurred
	 */
	public static function createRelease(releaseData:GitHubCreateRelease):GitHubRelease {
		if (!GitHubAPI.isAuthenticated()) {
			trace("GitHubHelper.createRelease error: Not authenticated");
			return null;
		}

		var result:GitHubRelease = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.createRelease(releaseData,
			function(release:GitHubRelease) {
				result = release;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.createRelease error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Upload release asset (blocks until result is available)
	 * @param releaseId Release ID to upload to
	 * @param filePath Local file path
	 * @param fileName Name for the asset
	 * @param contentType MIME type
	 * @return Uploaded asset info, or null if error occurred
	 */
	public static function uploadReleaseAsset(releaseId:Int, filePath:String, fileName:String, contentType:String):GitHubAsset {
		if (!GitHubAPI.isAuthenticated()) {
			trace("GitHubHelper.uploadReleaseAsset error: Not authenticated");
			return null;
		}

		var result:GitHubAsset = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.uploadReleaseAsset(releaseId, filePath, fileName, contentType,
			function(progress:Float) {
				// Progress callback - could be logged if needed
				trace('Upload progress: ${Math.round(progress * 100)}%');
			},
			function(asset:GitHubAsset) {
				result = asset;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.uploadReleaseAsset error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Validate authentication token (blocks until result is available)
	 * @param token Token to validate
	 * @return true if token is valid, false otherwise
	 */
	public static function validateToken(token:String):Bool {
		var result:Bool = false;
		var completed = false;

		GitHubAPI.validateToken(token,
			function(valid:Bool) {
				result = valid;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		return result;
	}

	/**
	 * Get repository information (blocks until result is available)
	 * @param repoPath Repository path in "owner/repo" format
	 * @return Repository info, or null if error occurred
	 */
	public static function getRepository(repoPath:String):GitHubRepository {
		var result:GitHubRepository = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.getRepository(repoPath,
			function(repo:GitHubRepository) {
				result = repo;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.getRepository error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Get file/directory contents (blocks until result is available)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param path Path within repository
	 * @param branch Branch name (optional)
	 * @return Array of file contents, or null if error occurred
	 */
	public static function getContents(repoPath:String, path:String, ?branch:String):Array<GitHubFileContent> {
		var result:Array<GitHubFileContent> = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.getContents(repoPath, path, branch,
			function(contents:Array<GitHubFileContent>) {
				result = contents;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.getContents error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Get repository tree (blocks until result is available)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param branch Branch name (optional)
	 * @param recursive Whether to get recursive tree
	 * @return Repository tree, or null if error occurred
	 */
	public static function getTree(repoPath:String, ?branch:String, ?recursive:Bool = true):GitHubTree {
		var result:GitHubTree = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.getTree(repoPath, branch, recursive,
			function(tree:GitHubTree) {
				result = tree;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.getTree error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Download a single file (blocks until result is available)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param filePath Path to file within repository
	 * @param localPath Local destination path
	 * @param branch Branch name (optional)
	 * @return Local file path if successful, null if error occurred
	 */
	public static function downloadFile(repoPath:String, filePath:String, localPath:String, ?branch:String):String {
		var result:String = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.downloadFile(repoPath, filePath, localPath, branch,
			function(progress:Float) {
				// Progress callback - could be logged if needed
				trace('Download progress: ${Math.round(progress * 100)}%');
			},
			function(path:String) {
				result = path;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.downloadFile error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Download multiple files (blocks until result is available)
	 * @param config Download configuration
	 * @return Array of downloaded file paths, or null if error occurred
	 */
	public static function downloadFiles(config:DownloadConfig):Array<String> {
		var result:Array<String> = null;
		var error:String = null;
		var completed = false;

		// Create a modified config with our own callbacks
		var helperConfig:DownloadConfig = {
			repo: config.repo,
			branch: config.branch,
			files: config.files,
			destination: config.destination,
			onProgress: function(current:Int, total:Int, fileName:String) {
				trace('Progress: $current/$total - $fileName');
			},
			onFileProgress: function(progress:Float, fileName:String) {
				trace('File progress: ${Math.round(progress * 100)}% - $fileName');
			},
			onComplete: function(downloadedFiles:Array<String>) {
				result = downloadedFiles;
				completed = true;
			},
			onError: function(err:String) {
				error = err;
				completed = true;
			}
		};

		GitHubAPI.downloadFiles(helperConfig);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.downloadFiles error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Download entire repository as ZIP (blocks until result is available)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param localPath Local destination path for ZIP file
	 * @param branch Branch name (optional)
	 * @return Local ZIP file path if successful, null if error occurred
	 */
	public static function downloadRepository(repoPath:String, localPath:String, ?branch:String):String {
		var result:String = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.downloadRepository(repoPath, localPath, branch,
			function(progress:Float) {
				trace('Download progress: ${Math.round(progress * 100)}%');
			},
			function(path:String) {
				result = path;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.downloadRepository error: " + error);
			return null;
		}

		return result;
	}

	/**
	 * Clone repository (download and extract, blocks until result is available)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param localFolder Local destination folder
	 * @param branch Branch name (optional)
	 * @return Local folder path if successful, null if error occurred
	 */
	public static function cloneRepository(repoPath:String, localFolder:String, ?branch:String):String {
		var result:String = null;
		var error:String = null;
		var completed = false;

		GitHubAPI.cloneRepository(repoPath, localFolder, branch,
			function(current:Int, total:Int, fileName:String) {
				trace('Progress: $current/$total - $fileName');
			},
			function(progress:Float, fileName:String) {
				trace('File progress: ${Math.round(progress * 100)}% - $fileName');
			},
			function(path:String) {
				result = path;
				completed = true;
			},
			function(err:String) {
				error = err;
				completed = true;
			}
		);

		while (!completed) {
			Sys.sleep(0.01);
		}

		if (error != null) {
			trace("GitHubHelper.cloneRepository error: " + error);
			return null;
		}

		return result;
	}

	// ========================================================================
	// CONVENIENCE FUNCTIONS
	// ========================================================================

	/**
	 * Get the latest release from the current repository
	 * @return Latest release, or null if none found
	 */
	public static function getLatestRelease():GitHubRelease {
		var releases = getPublicReleases();
		if (releases == null || releases.length == 0) return null;

		// Releases are typically returned in descending order by creation date
		return releases[0];
	}

	/**
	 * Get platform-specific assets for the latest release
	 * @return Array of assets for current platform, or all assets if none match
	 */
	public static function getLatestPlatformAssets():Array<GitHubAsset> {
		var release = getLatestRelease();
		if (release == null) return null;

		return GitHubAPI.getPlatformAssets(release);
	}

	/**
	 * Check if a file exists in the repository
	 * @param repoPath Repository path in "owner/repo" format
	 * @param filePath Path to file within repository
	 * @param branch Branch name (optional)
	 * @return true if file exists, false otherwise
	 */
	public static function fileExists(repoPath:String, filePath:String, ?branch:String):Bool {
		var contents = getContents(repoPath, filePath, branch);
		return contents != null && contents.length > 0;
	}

	/**
	 * Get file content as string (for text files)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param filePath Path to file within repository
	 * @param branch Branch name (optional)
	 * @return File content as string, or null if error occurred
	 */
	public static function getFileContentAsString(repoPath:String, filePath:String, ?branch:String):String {
		var contents = getContents(repoPath, filePath, branch);
		if (contents == null || contents.length == 0) return null;

		var fileContent = contents[0];
		if (fileContent.type != "file") return null;

		try {
			// Decode base64 content
			var base64Content = fileContent.content.replace("\n", "").replace("\r", "");
			var decodedBytes = haxe.crypto.Base64.decode(base64Content);
			return decodedBytes.toString();
		} catch (e:Dynamic) {
			trace("GitHubHelper.getFileContentAsString error: " + e);
			return null;
		}
	}

	/**
	 * List all files in a directory (non-recursive)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param dirPath Path to directory within repository
	 * @param branch Branch name (optional)
	 * @return Array of file names, or null if error occurred
	 */
	public static function listFiles(repoPath:String, dirPath:String, ?branch:String):Array<String> {
		var contents = getContents(repoPath, dirPath, branch);
		if (contents == null) return null;

		var fileNames = [];
		for (item in contents) {
			if (item.type == "file") {
				fileNames.push(item.name);
			}
		}

		return fileNames;
	}

	/**
	 * List all directories in a directory (non-recursive)
	 * @param repoPath Repository path in "owner/repo" format
	 * @param dirPath Path to directory within repository
	 * @param branch Branch name (optional)
	 * @return Array of directory names, or null if error occurred
	 */
	public static function listDirectories(repoPath:String, dirPath:String, ?branch:String):Array<String> {
		var contents = getContents(repoPath, dirPath, branch);
		if (contents == null) return null;

		var dirNames = [];
		for (item in contents) {
			if (item.type == "dir") {
				dirNames.push(item.name);
			}
		}

		return dirNames;
	}

	/**
	 * Get all file paths in repository recursively
	 * @param repoPath Repository path in "owner/repo" format
	 * @param branch Branch name (optional)
	 * @return Array of all file paths, or null if error occurred
	 */
	public static function getAllFilePaths(repoPath:String, ?branch:String):Array<String> {
		var tree = getTree(repoPath, branch, true);
		if (tree == null) return null;

		var filePaths = [];
		for (item in tree.tree) {
			if (item.type == "blob") { // blob = file
				filePaths.push(item.path);
			}
		}

		return filePaths;
	}
}
