package backend;

#if !html5
import backend.util.JSEZip;
#end
import haxe.Http;
import haxe.Json;
import haxe.crypto.Base64;
import lime.utils.Bytes;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.net.URLRequestHeader;
import openfl.utils.ByteArray;
import yutautil.DualProgressSubstate;
import yutautil.TypeUtils.OneOrMore;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef GitHubRelease = {
	var id:Int;
	var tag_name:String;
	var name:String;
	var body:String;
	var draft:Bool;
	var prerelease:Bool;
	var created_at:String;
	var published_at:String;
	var assets:Array<GitHubAsset>;
	var html_url:String;
	var author:GitHubUser;
}

typedef GitHubAsset = {
	var id:Int;
	var name:String;
	var size:Int;
	var download_count:Int;
	var browser_download_url:String;
	var content_type:String;
}

typedef GitHubUser = {
	var login:String;
	var id:Int;
	var avatar_url:String;
	var name:String;
	var email:String;
}

typedef GitHubCreateRelease = {
	var tag_name:String;
	var target_commitish:String;
	var name:String;
	var body:String;
	var draft:Bool;
	var prerelease:Bool;
}

// New typedefs for file/repo operations
typedef GitHubFileContent = {
	var name:String;
	var path:String;
	var sha:String;
	var size:Int;
	var url:String;
	var html_url:String;
	var git_url:String;
	var download_url:String;
	var type:String; // "file" or "dir"
	var content:String; // Base64 encoded for files
	var encoding:String; // "base64" for files
}

typedef GitHubRepository = {
	var id:Int;
	var name:String;
	var full_name:String;
	var isPrivate:Bool;
	var owner:GitHubUser;
	var html_url:String;
	var description:String;
	var fork:Bool;
	var created_at:String;
	var updated_at:String;
	var pushed_at:String;
	var clone_url:String;
	var ssh_url:String;
	var size:Int;
	var language:String;
	var default_branch:String;
}

typedef GitHubTree = {
	var sha:String;
	var url:String;
	var tree:Array<GitHubTreeItem>;
	var truncated:Bool;
}

typedef GitHubTreeItem = {
	var path:String;
	var mode:String;
	var type:String; // "blob" (file) or "tree" (directory)
	var sha:String;
	var size:Int;
	var url:String;
}

typedef GitHubArchive = {
	var url:String;
	var ref:String; // branch/tag name
	var format:String; // "zipball" or "tarball"
}

typedef DownloadConfig = {
	var repo:String; // "owner/repo" format
	var ?branch:String; // defaults to default branch
	var ?files:OneOrMore<String>; // specific files/paths to download
	var ?destination:String; // local destination path
	var ?onProgress:(current:Int, total:Int, fileName:String)->Void;
	var ?onFileProgress:(progress:Float, fileName:String)->Void;
	var ?onComplete:(downloadedFiles:Array<String>)->Void;
	var ?onError:(error:String)->Void;
}

class GitHubAPI {
	public static final REPO_OWNER:String = "Z11Coding";
	public static final REPO_NAME:String = "Mixtape-Engine-Rework";
	public static final API_BASE:String = "https://api.github.com";

	private static var authToken:String = null;
	private static var authenticated:Bool = false;

	public static function isAuthenticated():Bool {
		return authenticated && authToken != null;
	}

	public static function setAuthToken(token:String):Void {
		authToken = token;
		authenticated = true;
		// Save token securely
		saveAuthToken(token);
	}

	public static function loadAuthToken():Bool {
		try {
			if (FileSystem.exists("./save/github_token.dat")) {
				var encryptedToken = File.getContent("./save/github_token.dat");
				// Simple XOR encryption for basic security (not production-level)
				authToken = xorEncrypt(encryptedToken, "MixtapeEngineKey");
				authenticated = true;
				return true;
			}
		} catch (e:Dynamic) {
			trace("Failed to load auth token: " + e);
		}
		return false;
	}

	private static function saveAuthToken(token:String):Void {
		try {
			if (!FileSystem.exists("./save/")) {
				FileSystem.createDirectory("./save/");
			}
			// Simple XOR encryption for basic security
			var encryptedToken = xorEncrypt(token, "MixtapeEngineKey");
			File.saveContent("./save/github_token.dat", encryptedToken);
		} catch (e:Dynamic) {
			trace("Failed to save auth token: " + e);
		}
	}

	private static function xorEncrypt(data:String, key:String):String {
		var result = "";
		for (i in 0...data.length) {
			var char = data.charCodeAt(i);
			var keyChar = key.charCodeAt(i % key.length);
			result += String.fromCharCode(char ^ keyChar);
		}
		return result;
	}

	public static function clearAuth():Void {
		authToken = null;
		authenticated = false;
		try {
			if (FileSystem.exists("./save/github_token.dat")) {
				FileSystem.deleteFile("./save/github_token.dat");
			}
		} catch (e:Dynamic) {
			trace("Failed to delete auth token: " + e);
		}
	}

	public static function getPublicReleases(callback:Array<GitHubRelease>->Void, errorCallback:String->Void):Void {
		var http = new Http('$API_BASE/repos/$REPO_OWNER/$REPO_NAME/releases');

		http.onData = function(data:String) {
			try {
				var releases:Array<GitHubRelease> = Json.parse(data);
				callback(releases);
			} catch (e:Dynamic) {
				errorCallback("Failed to parse releases data: " + e);
			}
		};

		http.onError = function(error:String) {
			errorCallback("Failed to fetch releases: " + error);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Updater");
		http.request();
	}

	public static function getUserInfo(callback:GitHubUser->Void, errorCallback:String->Void):Void {
		if (!isAuthenticated()) {
			errorCallback("Not authenticated");
			return;
		}

		var http = new Http('$API_BASE/user');

		http.onData = function(data:String) {
			try {
				var user:GitHubUser = Json.parse(data);
				callback(user);
			} catch (e:Dynamic) {
				errorCallback("Failed to parse user data: " + e);
			}
		};

		http.onError = function(error:String) {
			errorCallback("Failed to fetch user info: " + error);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Updater");
		http.addHeader("Authorization", "Bearer " + authToken);
		http.request();
	}

	public static function hasRepoAccess(callback:Bool->Void, errorCallback:String->Void):Void {
		if (!isAuthenticated()) {
			errorCallback("Not authenticated");
			return;
		}

		var http = new Http('$API_BASE/repos/$REPO_OWNER/$REPO_NAME');

		http.onData = function(data:String) {
			try {
				var repo = Json.parse(data);
				// Check if user has push access
				callback(repo.permissions != null && repo.permissions.push == true);
			} catch (e:Dynamic) {
				callback(false);
			}
		};

		http.onError = function(error:String) {
			callback(false);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Updater");
		http.addHeader("Authorization", "Bearer " + authToken);
		http.request();
	}

	public static function createRelease(releaseData:GitHubCreateRelease, callback:GitHubRelease->Void, errorCallback:String->Void):Void {
		if (!isAuthenticated()) {
			errorCallback("Not authenticated");
			return;
		}

		var http = new Http('$API_BASE/repos/$REPO_OWNER/$REPO_NAME/releases');

		http.onData = function(data:String) {
			try {
				var release:GitHubRelease = Json.parse(data);
				callback(release);
			} catch (e:Dynamic) {
				errorCallback("Failed to parse release data: " + e);
			}
		};

		http.onError = function(error:String) {
			errorCallback("Failed to create release: " + error);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Updater");
		http.addHeader("Authorization", "Bearer " + authToken);
		http.addHeader("Content-Type", "application/json");
		http.setPostData(Json.stringify(releaseData));
		http.request(true);
	}

	public static function uploadReleaseAsset(releaseId:Int, filePath:String, fileName:String, contentType:String,
		progressCallback:Float->Void, callback:GitHubAsset->Void, errorCallback:String->Void):Void {
		if (!isAuthenticated()) {
			errorCallback("Not authenticated");
			return;
		}

		if (!FileSystem.exists(filePath)) {
			errorCallback("File not found: " + filePath);
			return;
		}

		try {
			var fileBytes = File.getBytes(filePath);
			var uploadUrl = 'https://uploads.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$releaseId/assets?name=$fileName';

			var http = new Http(uploadUrl);

			http.onData = function(data:String) {
				try {
					var asset:GitHubAsset = Json.parse(data);
					callback(asset);
				} catch (e:Dynamic) {
					errorCallback("Failed to parse asset data: " + e);
				}
			};

			http.onError = function(error:String) {
				errorCallback("Failed to upload asset: " + error);
			};

			http.addHeader("User-Agent", "Mixtape-Engine-Updater");
			http.addHeader("Authorization", "Bearer " + authToken);
			http.addHeader("Content-Type", contentType);
			http.addHeader("Content-Length", Std.string(fileBytes.length));

			// Note: For large files, you'd want to implement chunked upload
			// This is a simplified version
			http.setPostBytes(fileBytes);
			http.request(true);

		} catch (e:Dynamic) {
			errorCallback("Failed to read file: " + e);
		}
	}

	public static function validateToken(token:String, callback:Bool->Void):Void {
		var http = new Http('$API_BASE/user');

		http.onData = function(data:String) {
			callback(true);
		};

		http.onError = function(error:String) {
			callback(false);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Updater");
		http.addHeader("Authorization", "Bearer " + token);
		http.request();
	}

	public static function formatFileSize(bytes:Int):String {
		if (bytes == 0) return "0 B";

		var units = ["B", "KB", "MB", "GB", "TB"];
		var digitGroups = Math.floor(Math.log(bytes) / Math.log(1024));
		var size = bytes / Math.pow(1024, digitGroups);

		return Math.round(size * 100) / 100 + " " + units[digitGroups];
	}

	public static function formatDate(dateString:String):String {
		try {
			// Parse ISO 8601 date format from GitHub API
			var date = Date.fromString(dateString.split("T")[0]);
			return date.toString();
		} catch (e:Dynamic) {
			return dateString;
		}
	}

	public static function getPlatformAssets(release:GitHubRelease):Array<GitHubAsset> {
		var platformAssets = [];
		var platform = getPlatform();

		for (asset in release.assets) {
			var assetName = asset.name.toLowerCase();
			if (assetName.indexOf(platform) != -1) {
				platformAssets.push(asset);
			}
		}

		// If no platform-specific assets found, return all assets
		return platformAssets.length > 0 ? platformAssets : release.assets;
	}

	private static function getPlatform():String {
		#if windows
		return 'windows';
		#elseif mac
		return 'macos';
		#elseif linux
		return 'linux';
		#elseif android
		return 'android';
		#else
		return '';
		#end
	}

	// ========================================================================
	// NEW: Generic GitHub file/repo download functionality
	// ========================================================================

	/**
	 * Get repository information
	 */
	public static function getRepository(repoPath:String, callback:GitHubRepository->Void, errorCallback:String->Void):Void {
		var http = new Http('$API_BASE/repos/$repoPath');

		http.onData = function(data:String) {
			try {
				var repo:GitHubRepository = Json.parse(data);
				callback(repo);
			} catch (e:Dynamic) {
				errorCallback("Failed to parse repository data: " + e);
			}
		};

		http.onError = function(error:String) {
			errorCallback("Failed to fetch repository: " + error);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Downloader");
		if (isAuthenticated()) {
			http.addHeader("Authorization", "Bearer " + authToken);
		}
		http.request();
	}

	/**
	 * Get file/directory contents from a repository
	 */
	public static function getContents(repoPath:String, path:String, ?branch:String, callback:Array<GitHubFileContent>->Void, errorCallback:String->Void):Void {
		var encodedPath = StringTools.urlEncode(path);
		var url = '$API_BASE/repos/$repoPath/contents/$encodedPath';
		if (branch != null) url += '?ref=' + StringTools.urlEncode(branch);

		var http = new Http(url);

		http.onData = function(data:String) {
			try {
				var contents:Array<GitHubFileContent> = Json.parse(data);
				callback(contents);
			} catch (e:Dynamic) {
				errorCallback("Failed to parse contents data: " + e);
			}
		};

		http.onError = function(error:String) {
			errorCallback("Failed to fetch contents: " + error);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Downloader");
		if (isAuthenticated()) {
			http.addHeader("Authorization", "Bearer " + authToken);
		}
		http.request();
	}

	/**
	 * Get repository tree (recursive directory listing)
	 */
	public static function getTree(repoPath:String, ?branch:String, ?recursive:Bool = true, callback:GitHubTree->Void, errorCallback:String->Void):Void {
		// First get the repo to find the default branch if not specified
		if (branch == null) {
			getRepository(repoPath, function(repo) {
				getTree(repoPath, repo.default_branch, recursive, callback, errorCallback);
			}, errorCallback);
			return;
		}

		var url = '$API_BASE/repos/$repoPath/git/trees/$branch';
		if (recursive) url += '?recursive=1';

		var http = new Http(url);

		http.onData = function(data:String) {
			try {
				var tree:GitHubTree = Json.parse(data);
				callback(tree);
			} catch (e:Dynamic) {
				errorCallback("Failed to parse tree data: " + e);
			}
		};

		http.onError = function(error:String) {
			errorCallback("Failed to fetch tree: " + error);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Downloader");
		if (isAuthenticated()) {
			http.addHeader("Authorization", "Bearer " + authToken);
		}
		http.request();
	}

	/**
	 * Download a single file from a repository
	 */
	public static function downloadFile(repoPath:String, filePath:String, localPath:String, ?branch:String,
		?progressCallback:(progress:Float)->Void, callback:String->Void, errorCallback:String->Void):Void {

		// Properly encode the file path for URL
		var encodedFilePath = StringTools.urlEncode(filePath);

		// Get file content first
		var url = '$API_BASE/repos/$repoPath/contents/$encodedFilePath';
		if (branch != null) url += '?ref=' + StringTools.urlEncode(branch);

		var http = new Http(url);

		http.onData = function(data:String) {
			try {
				var fileContent:GitHubFileContent = Json.parse(data);

				if (fileContent.type != "file") {
					errorCallback("Path is not a file: " + filePath);
					return;
				}

				// Decode base64 content
				// Remove newlines from base64 content before decoding
				var base64Content = fileContent.content.replace("\n", "").replace("\r", "");
				var decodedBytes = Base64.decode(base64Content);

				// Ensure directory exists
				var dir = haxe.io.Path.directory(localPath);
				if (dir != "" && !FileSystem.exists(dir)) {
					FileSystem.createDirectory(dir);
				}

				// Write file
				File.saveBytes(localPath, decodedBytes);

				if (progressCallback != null) progressCallback(1.0);
				callback(localPath);

			} catch (e:Dynamic) {
				errorCallback("Failed to download file: " + e);
			}
		};

		http.onError = function(error:String) {
			errorCallback("Failed to fetch file: " + error);
		};

		http.addHeader("User-Agent", "Mixtape-Engine-Downloader");
		if (isAuthenticated()) {
			http.addHeader("Authorization", "Bearer " + authToken);
		}
		http.request();
	}

	/**
	 * Download multiple files from a repository with progress tracking
	 */
	public static function downloadFiles(config:DownloadConfig):Void {
		var repoPath = config.repo;
		var branch = config.branch;
		var files:Array<String> = config.files;
		var destination = config.destination != null ? config.destination : "./downloads";

		if (!FileSystem.exists(destination)) {
			FileSystem.createDirectory(destination);
		}

		var downloadedFiles:Array<String> = [];
		var currentIndex = 0;
		var totalFiles = files.length;

		function downloadNextFile():Void {
			if (currentIndex >= totalFiles) {
				if (config.onComplete != null) config.onComplete(downloadedFiles);
				return;
			}

			var filePath = files[currentIndex];
			var fileName = haxe.io.Path.withoutDirectory(filePath);
			var localPath = haxe.io.Path.join([destination, fileName]);

			if (config.onProgress != null) {
				config.onProgress(currentIndex, totalFiles, fileName);
			}

			downloadFile(repoPath, filePath, localPath, branch,
				function(progress:Float) {
					if (config.onFileProgress != null) {
						config.onFileProgress(progress, fileName);
					}
				},
				function(path:String) {
					downloadedFiles.push(path);
					currentIndex++;
					downloadNextFile();
				},
				function(error:String) {
					if (config.onError != null) {
						config.onError('Failed to download $fileName: $error');
					}
				}
			);
		}

		downloadNextFile();
	}

	/**
	 * Download an entire repository as a ZIP archive using GitHub API zipball
	 */
	public static function downloadRepository(repoPath:String, localPath:String, ?branch:String,
		?progressCallback:(progress:Float)->Void, callback:String->Void, errorCallback:String->Void):Void {

		// If no branch specified, get the default branch
		if (branch == null) {
			getRepository(repoPath, function(repo) {
				downloadRepository(repoPath, localPath, repo.default_branch, progressCallback, callback, errorCallback);
			}, errorCallback);
			return;
		}

		// Use GitHub API zipball endpoint for better reliability and authentication
		var encodedRef = StringTools.urlEncode(branch);
		var url = '$API_BASE/repos/$repoPath/zipball/$encodedRef';

		// Use URLLoader for proper binary data handling (same as UpdateState)
		var loader = new openfl.net.URLLoader();
		loader.dataFormat = openfl.net.URLLoaderDataFormat.BINARY;

		loader.addEventListener(openfl.events.ProgressEvent.PROGRESS, function(event:openfl.events.ProgressEvent) {
			if (progressCallback != null) {
				var progress = event.bytesLoaded / event.bytesTotal;
				progressCallback(progress);
			}
		});

		loader.addEventListener(openfl.events.Event.COMPLETE, function(event:openfl.events.Event) {
			try {
				// Ensure directory exists
				var dir = haxe.io.Path.directory(localPath);
				if (dir != "" && !FileSystem.exists(dir)) {
					FileSystem.createDirectory(dir);
				}

				// Get binary data from loader
				var fileBytes:Bytes = cast(loader.data, ByteArray);
				File.saveBytes(localPath, fileBytes);

				if (progressCallback != null) progressCallback(1.0);
				callback(localPath);

			} catch (e:Dynamic) {
				errorCallback("Failed to save repository archive: " + e);
			}
		});

		loader.addEventListener(openfl.events.IOErrorEvent.IO_ERROR, function(event:openfl.events.IOErrorEvent) {
			errorCallback("Failed to download repository: " + event.text);
		});

		loader.addEventListener(openfl.events.SecurityErrorEvent.SECURITY_ERROR, function(event:openfl.events.SecurityErrorEvent) {
			errorCallback("Security error downloading repository: " + event.text);
		});

		// Create request with proper headers
		var request = new openfl.net.URLRequest(url);
		request.userAgent = "Mixtape-Engine-Downloader";
		request.requestHeaders = [
			new openfl.net.URLRequestHeader("Accept", "application/vnd.github+json"),
			new openfl.net.URLRequestHeader("X-GitHub-Api-Version", "2022-11-28")
		];

		if (isAuthenticated()) {
			request.requestHeaders.push(new openfl.net.URLRequestHeader("Authorization", "Bearer " + authToken));
		}

		loader.load(request);
	}

	/**
	 * Clone repository (download and extract to folder structure)
	 * Uses GitHub API zipball for much faster downloads
	 */
	public static function cloneRepository(repoPath:String, localFolder:String, ?branch:String,
		?progressCallback:(current:Int, total:Int, fileName:String)->Void,
		?fileProgressCallback:(progress:Float, fileName:String)->Void,
		callback:String->Void, errorCallback:String->Void):Void {

		// Create temporary file for the ZIP
		var tempZipPath = haxe.io.Path.join([Sys.getCwd(), "temp_repo_download.zip"]);

		if (progressCallback != null) {
			progressCallback(0, 3, "Starting download...");
		}

		// Download the repository as a ZIP file
		downloadRepository(repoPath, tempZipPath, branch,
			function(progress:Float) {
				if (fileProgressCallback != null) {
					fileProgressCallback(progress * 0.7, "Downloading repository...");
				}
			},
			function(zipPath:String) {
				if (progressCallback != null) {
					progressCallback(1, 3, "Download complete, extracting...");
				}

				// Extract the ZIP file
				try {
					extractZipFile(zipPath, localFolder, function(progress:Float, fileName:String) {
						if (fileProgressCallback != null) {
							fileProgressCallback(0.7 + (progress * 0.3), "Extracting: " + fileName);
						}
					}, function(extractedPath:String) {
						// Clean up temporary ZIP file
						if (FileSystem.exists(tempZipPath)) {
							try {
								FileSystem.deleteFile(tempZipPath);
							} catch (e:Dynamic) {
								trace("Warning: Could not delete temporary file: " + e);
							}
						}

						if (progressCallback != null) {
							progressCallback(3, 3, "Clone complete!");
						}

						callback(extractedPath);
					}, errorCallback);

				} catch (e:Dynamic) {
					// Clean up on error
					if (FileSystem.exists(tempZipPath)) {
						try {
							FileSystem.deleteFile(tempZipPath);
						} catch (cleanupError:Dynamic) {
							trace("Warning: Could not delete temporary file after error: " + cleanupError);
						}
					}
					errorCallback("Failed to extract repository: " + e);
				}
			},
			function(error:String) {
				// Clean up on download error
				if (FileSystem.exists(tempZipPath)) {
					try {
						FileSystem.deleteFile(tempZipPath);
					} catch (cleanupError:Dynamic) {
						trace("Warning: Could not delete temporary file after download error: " + cleanupError);
					}
				}
				errorCallback("Failed to download repository: " + error);
			}
		);
	}

	/**
	 * Extract ZIP file to destination folder using JSEZip (same as UpdateState)
	 */
	private static function extractZipFile(zipPath:String, destinationFolder:String,
		?progressCallback:(progress:Float, fileName:String)->Void,
		callback:String->Void, errorCallback:String->Void):Void {

		#if !html5
		if (!FileSystem.exists(zipPath)) {
			errorCallback("ZIP file not found: " + zipPath);
			return;
		}

		if (!FileSystem.exists(destinationFolder)) {
			FileSystem.createDirectory(destinationFolder);
		}

		try {
			if (progressCallback != null) {
				progressCallback(0.1, "Starting extraction...");
			}

			// Use JSEZip.unzip with ignoreRootFolder parameter to skip GitHub's root folder
			// GitHub zipballs have a root folder like "reponame-branchname-sha" that we want to ignore
			JSEZip.unzip(zipPath, destinationFolder, "github_root");

			if (progressCallback != null) {
				progressCallback(1.0, "Extraction complete");
			}

			callback(destinationFolder);

		} catch (e:Dynamic) {
			errorCallback("Failed to extract ZIP file: " + e);
		}
		#else
		errorCallback("You can't use this on HTML5 bozo! (how'd you even access this...)");
		#end
	}

	/**
	 * Download files/repo with dual progress bars using DualProgressSubstate
	 */
	public static function downloadWithProgress(config:DownloadConfig, title:String = "Downloading Files"):Void {
		var progressSubstate:DualProgressSubstate;

		var tasks = [];

		if (config.files != null) {
			// Download specific files
			var files:Array<String> = config.files;

			for (i in 0...files.length) {
				var filePath = files[i];
				var fileName = haxe.io.Path.withoutDirectory(filePath);

				tasks.push(DualProgressSubstate.createTask(
					'Download $fileName',
					function(results:Array<Dynamic>):Dynamic {
						var destination = config.destination != null ? config.destination : "./downloads";
						var localPath = haxe.io.Path.join([destination, fileName]);

						// This is a synchronous wrapper - in a real implementation you'd want
						// to make this properly async or use a different approach
						var completed = false;
						var result:String = null;
						var error:String = null;

						downloadFile(config.repo, filePath, localPath, config.branch,
							function(progress:Float) {
								// Update current file progress
								if (progressSubstate != null) {
									progressSubstate.updateCurrentFileProgress(progress, fileName);
								}
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

						// Wait for completion (this is a simple blocking approach)
						while (!completed) {
							Sys.sleep(0.01);
						}

						if (error != null) throw new haxe.Exception(error);
						return result;
					}
				));
			}
		} else {
			// Download entire repository
			tasks.push(DualProgressSubstate.createTask(
				'Clone Repository',
				function(results:Array<Dynamic>):Dynamic {
					var destination = config.destination != null ? config.destination : "./downloads";
					var completed = false;
					var result:String = null;
					var error:String = null;

					cloneRepository(config.repo, destination, config.branch,
						function(current:Int, total:Int, fileName:String) {
							if (progressSubstate != null) {
								var progress = current / total;
								progressSubstate.updateCurrentFileProgress(progress, fileName);
							}
						},
						function(progress:Float, fileName:String) {
							if (progressSubstate != null) {
								progressSubstate.updateCurrentFileProgress(progress, fileName);
							}
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

					if (error != null) throw new haxe.Exception(error);
					return result;
				}
			));
		}

		var progressConfig = DualProgressSubstate.createConfig(title, tasks);
		progressConfig.onComplete = function(results:Array<Dynamic>) {
			if (config.onComplete != null) {
				var downloadedFiles:Array<String> = [];
				for (result in results) {
					if (Std.isOfType(result, String)) {
						downloadedFiles.push(result);
					}
				}
				config.onComplete(downloadedFiles);
			}
		};
		progressConfig.onError = function(error:String, shouldThrow:Bool) {
			if (config.onError != null) {
				config.onError(error);
			}
		};
		progressConfig.currentFileLabel = "Current File";
		progressConfig.overallLabel = "Overall Progress";

		progressSubstate = new DualProgressSubstate(progressConfig);
		flixel.FlxG.state.openSubState(progressSubstate);
	}
}
