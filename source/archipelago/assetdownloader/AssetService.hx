package archipelago.assetdownloader;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import yutautil.modules.AResult;
import yutautil.modules.ASync;

/**
 * Manages asset downloading with caching and re-download timing.
 * Prevents redundant downloads and allows customizable re-download intervals.
 */
class AssetService
{
	private static final NEVER_REDOWNLOAD = Math.pow(2, 31) - 1; // Maximum Int value

	private var downloader:AssetDownloader;
	private var downloadedGameZips:Map<String, Bool>;
	private var downloadedSpecificAssets:Set<String>;
	private var timeUntilRedownloadAssets:Float;

	/**
	 * @param timeUntilRedownloadAssets How long (in seconds) before re-downloading assets.
	 *                                  null = never re-download
	 */
	public function new(timeUntilRedownloadAssets:Null<Float> = null)
	{
		downloader = new AssetDownloader();
		downloadedGameZips = new Map();
		downloadedSpecificAssets = new Set();

		this.timeUntilRedownloadAssets = (timeUntilRedownloadAssets != null)
			? timeUntilRedownloadAssets
			: NEVER_REDOWNLOAD;
	}

	/**
	 * Attempts to download all assets for a game
	 */
	public function tryDownloadGameAssets(gameName:String, itemSprites:ArchipelagoItemSprites, async:Bool):Void
	{
		// Skip if already attempted
		if (downloadedGameZips.exists(gameName))
		{
			return;
		}

		downloadedGameZips.set(gameName, true);

		if (async)
		{
			tryDownloadGameAssetsAsync(gameName, itemSprites);
		}
		else
		{
			tryDownloadGameAssetsSync(gameName, itemSprites);
		}
	}

	/**
	 * Async version using ASync/AResult for threading
	 */
	private function tryDownloadGameAssetsAsync(gameName:String, itemSprites:ArchipelagoItemSprites):Void
	{
		var asyncDownload:ASync<Void->Void> = cast function() {
			tryDownloadGameAssetsSync(gameName, itemSprites);
		};

		asyncDownload().onError(function(error:Dynamic) {
			trace('Error in async game assets download for ${gameName}: ${error}');
		});
	}

	/**
	 * Synchronous asset download for a game
	 */
	private function tryDownloadGameAssetsSync(gameName:String, itemSprites:ArchipelagoItemSprites):Void
	{
		try
		{
			var zipPath = haxe.io.Path.join([AssetDownloaderPaths.getCustomAssetsDirectory(), '${gameName}.zip']);
			var hasZip = false;
			var downloadedNewZip = false;

			// Check if zip exists and is fresh enough
			if (FileSystem.exists(zipPath))
			{
				var fileInfo = FileSystem.stat(zipPath);
				var fileAge = (Sys.time() - fileInfo.mtime.getTime() / 1000);
				hasZip = fileAge < timeUntilRedownloadAssets;
			}

			// Download zip if needed
			if (!hasZip)
			{
				hasZip = downloader.downloadGameZip(gameName);
				downloadedNewZip = true;
			}

			var gamePath = haxe.io.Path.join([AssetDownloaderPaths.getCustomAssetsDirectory(), gameName]);
			var hasSprites = FileSystem.exists(gamePath);

			// Extract zip if needed
			if ((downloadedNewZip || (hasZip && !hasSprites)))
			{
				hasSprites = downloader.unzipGameZip(gameName);
			}

			// Register sprites if extraction succeeded
			if (hasSprites)
			{
				itemSprites.registerGameSprites(gamePath);
			}
		}
		catch (e:Dynamic)
		{
			trace('Error downloading game assets for ${gameName}: ${e}');
		}
	}

	/**
	 * Attempts to download a specific item asset
	 */
	public function tryDownloadAsset(gameName:String, itemName:String, itemSprites:ArchipelagoItemSprites):Void
	{
		var hashKey = getKey(gameName, itemName);

		// Skip if already attempted
		if (downloadedSpecificAssets.exists(hashKey))
		{
			return;
		}

		downloadedSpecificAssets.add(hashKey);
		tryDownloadAssetAsync(gameName, itemName, itemSprites);
	}

	/**
	 * Async download of specific asset using ASync/AResult
	 */
	private function tryDownloadAssetAsync(gameName:String, itemName:String, itemSprites:ArchipelagoItemSprites):Void
	{
		var asyncDownload:ASync<Void->Void> = cast function() {
			try
			{
				var assetPath = haxe.io.Path.join([
					AssetDownloaderPaths.getCustomAssetsDirectory(),
					gameName,
					'${gameName}_${itemName}.png'
				]);

				if (FileSystem.exists(assetPath))
				{
					return;
				}

				if (downloader.downloadSpecificItemAsset(gameName, itemName))
				{
					itemSprites.registerSprite(assetPath);
				}
			}
			catch (e:Dynamic)
			{
				trace('Error downloading specific asset ${itemName} for ${gameName}: ${e}');
			}
		};

		asyncDownload().onError(function(error:Dynamic) {
			trace('Async asset download failed for ${itemName} in ${gameName}: ${error}');
		});
	}

	/**
	 * Creates a hash key for deduplication
	 */
	private function getKey(gameName:String, itemName:String):String
	{
		return '${gameName}_${itemName}';
	}
}

/**
 * Simple Set implementation for tracking downloaded assets
 */
private class Set<T> // Did this for translation convienience since I don't want to dig through libraries.
{
	private var items:Map<String, T>;

	public function new()
	{
		items = new Map();
	}

	public function add(key:String):Void
	{
		items.set(key, cast null);
	}

	public function exists(key:String):Bool
	{
		return items.exists(key);
	}

	public function remove(key:String):Bool
	{
		var existed = items.exists(key);
		items.remove(key);
		return existed;
	}

	public function clear():Void
	{
		items.clear();
	}
}
