package archipelago.assetdownloader;

import haxe.Http;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Reader;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;

/**
 * Handles downloading game asset zips and individual items from remote sources.
 * Manages extraction and local caching.
 */
class AssetDownloader
{
	private var nameCleaner:NameCleaner;

	public function new()
	{
		nameCleaner = new NameCleaner();
	}

	/**
	 * Downloads a zipped asset for a game
	 */
	public function downloadGameZip(game:String):Bool
	{
		try
		{
			var zipName = '${game}.zip';
			var webPath = '${AssetDownloaderPaths.WEB_DOWNLOAD_ZIPPED_ASSETS}${zipName}';
			var localPath = haxe.io.Path.join([AssetDownloaderPaths.getCustomAssetsDirectory(), zipName]);
			return downloadFile(webPath, localPath);
		}
		catch (e:Dynamic)
		{
			trace('Error downloading game zip for ${game}: ${e}');
			return false;
		}
	}

	/**
	 * Unzips a downloaded game asset
	 */
	public function unzipGameZip(game:String):Bool
	{
		try
		{
			var zipName = '${game}.zip';
			var zipFile = haxe.io.Path.join([AssetDownloaderPaths.getCustomAssetsDirectory(), zipName]);
			var path = haxe.io.Path.join([AssetDownloaderPaths.getCustomAssetsDirectory(), game]);

			if (FileSystem.exists(path))
			{
				deleteDirectory(path);
			}

			extractZip(zipFile, AssetDownloaderPaths.getCustomAssetsDirectory());
			return true;
		}
		catch (e:Dynamic)
		{
			trace('Error unzipping game ${game}: ${e}');
			return false;
		}
	}

	/**
	 * Downloads a specific item asset
	 */
	public function downloadSpecificItemAsset(game:String, itemName:String):Bool
	{
		var fileName = '${game}_${itemName}.png';
		return downloadSpecificAsset(game, fileName);
	}

	/**
	 * Downloads a specific asset by name
	 */
	private function downloadSpecificAsset(game:String, assetName:String):Bool
	{
		try
		{
			var filePath = '${game}/${assetName}';
			var webPath = '${AssetDownloaderPaths.WEB_DOWNLOAD_ASSETS}${game}/${assetName}';
			var fileName = haxe.io.Path.join([AssetDownloaderPaths.getCustomAssetsDirectory(), filePath]);
			return downloadFile(webPath, fileName);
		}
		catch (e:Dynamic)
		{
			trace('Error downloading specific asset ${assetName} for ${game}: ${e}');
			return false;
		}
	}

	/**
	 * Downloads a file from a URL to a local path (blocking)
	 * Handles both text and binary data properly
	 */
	private static function downloadFile(originPath:String, destinationPath:String):Bool
	{
		try
		{
			// Create directories if needed
			var dir = new Path(destinationPath).dir;
			if (dir != null && dir.length > 0 && !FileSystem.exists(dir))
			{
				FileSystem.createDirectory(dir);
			}

			// For binary files (PNG, ZIP), we need to use URLLoader for proper binary handling
			// URLLoader properly preserves binary data unlike haxe.Http which treats it as text
			var urlLoader = new URLLoader();
			var urlRequest = new URLRequest(originPath);
			urlLoader.dataFormat = BINARY; // Set to binary mode

			var completed = false;
			var bytes:Bytes = null;
			var errorMsg:String = null;

			urlLoader.addEventListener(Event.COMPLETE, function(e:Event)
			{
				try
				{
					// URLLoader with BINARY dataFormat returns ByteArray
					var data:Dynamic = e.target.data;
					if (data != null)
					{
						// Convert OpenFL ByteArray to haxe.io.Bytes
						if (Std.isOfType(data, openfl.utils.ByteArray))
						{
							var byteArray:openfl.utils.ByteArray = cast data;
							bytes = Bytes.ofData(byteArray);
						}
						else
						{
							// Fallback: try direct conversion
							bytes = cast data;
						}
					}
					completed = true;
				}
				catch (e2:Dynamic)
				{
					errorMsg = 'Error processing downloaded data: ${e2}';
					completed = true;
				}
			});

			urlLoader.addEventListener(openfl.events.IOErrorEvent.IO_ERROR, function(e:openfl.events.IOErrorEvent)
			{
				errorMsg = 'IO Error downloading ${originPath}: ${e.text}';
				completed = true;
			});

			// Load the file
			urlLoader.load(urlRequest);

			// Wait for completion with timeout (up to 60 seconds for large files)
			var maxWaitTime = 60.0;
			var startTime = Sys.time();
			while (!completed && (Sys.time() - startTime) < maxWaitTime)
			{
				Sys.sleep(0.01);
			}

			if (errorMsg != null)
			{
				trace(errorMsg);
				return false;
			}

			if (!completed)
			{
				trace('Download timeout for ${originPath}');
				return false;
			}

			if (bytes != null && bytes.length > 0)
			{
				File.saveBytes(destinationPath, bytes);
				trace('Successfully downloaded ${originPath} (${bytes.length} bytes) to ${destinationPath}');
				return true;
			}
			else
			{
				trace('No data received from ${originPath}');
				return false;
			}
		}
		catch (e:Dynamic)
		{
			trace('Error downloading file from ${originPath}: ${e}');
			return false;
		}
	}

	/**
	 * Extracts a zip file to a destination directory
	 */
	private static function extractZip(zipPath:String, destinationDir:String):Void
	{
		try
		{
			var bytes = File.getBytes(zipPath);
			var reader = new Reader(bytes);
			var entries = reader.read();

			for (entry in entries)
			{
				var targetPath = haxe.io.Path.join([destinationDir, entry.fileName]);

				// Create directory if needed
				var dir = new haxe.io.Path(targetPath).dir;
				if (dir != null && !FileSystem.exists(dir))
				{
					FileSystem.createDirectory(dir);
				}

				// Extract file
				if (!entry.fileName.endsWith("/"))
				{
					var data = Reader.unzip(entry);
					File.saveBytes(targetPath, data);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Error extracting zip: ${e}');
			throw e;
		}
	}

	/**
	 * Recursively deletes a directory
	 */
	private static function deleteDirectory(path:String):Void
	{
		if (!FileSystem.exists(path))
			return;

		if (FileSystem.isDirectory(path))
		{
			for (file in FileSystem.readDirectory(path))
			{
				var fullPath = haxe.io.Path.join([path, file]);
				deleteDirectory(fullPath);
			}
			FileSystem.deleteDirectory(path);
		}
		else
		{
			FileSystem.deleteFile(path);
		}
	}
}
