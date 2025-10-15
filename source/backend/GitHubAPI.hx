package backend;

import haxe.Http;
import haxe.Json;
import haxe.crypto.Base64;
import lime.utils.Bytes;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;

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
}
