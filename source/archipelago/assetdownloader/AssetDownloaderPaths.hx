package archipelago.assetdownloader;

import sys.FileSystem;
import sys.io.File;

/**
 * Central path management for Archipelago asset downloading.
 * Handles remote URLs and local cache directories.
 */
class AssetDownloaderPaths
{
	public static final REPOSITORY_URL:String = "https://raw.githubusercontent.com/agilbert1412/ArchipelagoUtilities/";
	public static final GIT_BRANCH:String = "main";
	public static final PROJECT_PATH:String = "/KaitoKid.ArchipelagoUtilities.Net/KaitoKid.ArchipelagoUtilities.AssetDownloader/";

	public static final WEB_DOWNLOAD_URL:String = REPOSITORY_URL + GIT_BRANCH + PROJECT_PATH;
	public static final ASSETS_FOLDER:String = "Assets/";
	public static final ZIPPED_ASSETS_FOLDER:String = "ZippedAssets/";

	public static final WEB_DOWNLOAD_ASSETS:String = WEB_DOWNLOAD_URL + ASSETS_FOLDER;
	public static final WEB_DOWNLOAD_ZIPPED_ASSETS:String = WEB_DOWNLOAD_URL + ZIPPED_ASSETS_FOLDER;

	// Local cache directory
	private static var _customAssetsDirectory:String = null;

	/**
	 * Gets the custom assets directory, creating it if it doesn't exist
	 */
	public static function getCustomAssetsDirectory():String
	{
		if (_customAssetsDirectory != null)
			return _customAssetsDirectory;

		// Use Mixtape Engine's asset cache directory
		var cacheDir = haxe.io.Path.join([
			Sys.getCwd(),
			"cache",
			"ap_assets"
		]);

		if (!FileSystem.exists(cacheDir))
		{
			FileSystem.createDirectory(cacheDir);
		}

		_customAssetsDirectory = cacheDir;
		return _customAssetsDirectory;
	}

	/**
	 * Sets a custom assets directory (for testing or custom configurations)
	 */
	public static function setCustomAssetsDirectory(path:String):Void
	{
		_customAssetsDirectory = path;
	}
}
