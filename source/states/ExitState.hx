package states;
import archipelago.APGameState;
import flixel.FlxState;
import flixel.text.FlxText;
import haxe.ds.StringMap;

class ExitState extends FlxState
{
	public static var cleanupFunctions:Array<Void->Void> = [];
	public static var returnFunctions:Array<Void->Dynamic> = [];
	public static var returnResults:Map<Int, Dynamic> = new Map();

	override public function create():Void
	{
		super.create();

		// Display "Exiting Game..." text
		var exitText:FlxText = new FlxText(0, 0, 0, "Exiting Game...", 32);
		exitText.screenCenter();
		add(exitText);

		// Perform cleanup
		performCleanup();
	}

	public static function addExitCallback(func:Void->Void):Void
	{
		cleanupFunctions.push(func);
	}

	public static function addReturnCallback(func:Void->Dynamic):Void
	{
		returnFunctions.push(func);
	}

	private function performCleanup():Void
	{
		// Clean up crash tracking (remove lock file for normal exit)
		yutautil.CrashReporter.cleanupOnExit();

		// Clean up temporary Archipelago weeks before exit
		APGameState.forceCleanupTemporaryWeeks();

		// Clean up GitHub downloads and mods
		cleanupGitHubContent();

		// Execute cleanup functions
		for (cleanupFunc in cleanupFunctions)
		{
			if (cleanupFunc != null)
			{
				try
				{
					cleanupFunc();
				}
				catch (e:Dynamic)
				{
					trace("Error executing cleanup function: " + e);
				}
			}
		}

		// Execute return functions and store results
		for (returnFunc in returnFunctions)
		{
			var index = returnFunctions.indexOf(returnFunc);
			if (returnFunc != null)
			{
				try
				{
					returnResults.set(index, returnFunc());
				}
				catch (e:Dynamic)
				{
					trace("Error executing return function: " + e);
				}
			}
		}

		trace("Returns: " + returnResults);
		Main.closeGame();
	}

	/**
	 * Cleans up all GitHub-related content including downloads and cached data
	 */
	private function cleanupGitHubContent():Void
	{
		try
		{
			trace('Cleaning up all download content and cached data...');

			// Clear GitHub API cache
			backend.GitHubAPI.clearCache();

			// Clear missing files tracking
			backend.GitHubAPI.clearMissingGitHubFiles();

			// Clean up downloaded GitHub content
			backend.GitHubDownloadManager.clearDownloadedMods();

			// Clean up external downloads from DownloadState
			cleanupExternalDownloads();

			// Clean up any temporary download directories
			cleanupTemporaryDownloads();

			// Reset GitHub mod configurations
			backend.GitHubAPI.githubMods = [];
			backend.GitHubAPI.githubModsFolders = [];

			trace('All download content cleanup completed');
		}
		catch (e:Dynamic)
		{
			trace('Error during download cleanup: $e');
		}
	}

	/**
	 * Static cleanup function for GitHub content that can be registered as an exit callback
	 */
	public static function cleanupGitHubContentStatic():Void
	{
		try
		{
			trace('Static cleanup: Clearing all download content and cached data...');

			// Clear GitHub API cache
			backend.GitHubAPI.clearCache();

			// Clear missing files tracking
			backend.GitHubAPI.clearMissingGitHubFiles();

			// Clean up downloaded GitHub content
			backend.GitHubDownloadManager.clearDownloadedMods();

			// Clean up external downloads from DownloadState
			cleanupExternalDownloadsStatic();

			// Clean up any temporary download directories
			cleanupTemporaryDownloadsStatic();

			// Reset GitHub mod configurations
			backend.GitHubAPI.githubMods = [];
			backend.GitHubAPI.githubModsFolders = [];

			trace('Static download content cleanup completed');
		}
		catch (e:Dynamic)
		{
			trace('Error during static download cleanup: $e');
		}
	}

	/**
	 * Cleans up external downloads created by DownloadState
	 */
	private function cleanupExternalDownloads():Void
	{
		try
		{
			var externalDir = "downloads/external";
			if (FileSystem.exists(externalDir))
			{
				deleteDirectoryRecursive(externalDir);
				trace('Cleaned up external downloads directory: $externalDir');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error cleaning up external downloads: $e');
		}
	}

	/**
	 * Static version of cleanupExternalDownloads
	 */
	public static function cleanupExternalDownloadsStatic():Void
	{
		try
		{
			var externalDir = "downloads/external";
			if (FileSystem.exists(externalDir))
			{
				deleteDirectoryRecursiveStatic(externalDir);
				trace('Cleaned up external downloads directory: $externalDir');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error cleaning up external downloads: $e');
		}
	}

	/**
	 * Cleans up any temporary download directories and files
	 */
	private function cleanupTemporaryDownloads():Void
	{
		try
		{
			var downloadsDir = "downloads";
			if (FileSystem.exists(downloadsDir))
			{
				// Clean up the entire downloads directory
				deleteDirectoryRecursive(downloadsDir);
				trace('Cleaned up all downloads directory: $downloadsDir');
			}

			// Also clean up any .tmp or .download files
			cleanupTemporaryFiles(".", [".tmp", ".download", ".part"]);
		}
		catch (e:Dynamic)
		{
			trace('Error cleaning up temporary downloads: $e');
		}
	}

	/**
	 * Static version of cleanupTemporaryDownloads
	 */
	public static function cleanupTemporaryDownloadsStatic():Void
	{
		try
		{
			var downloadsDir = "downloads";
			if (FileSystem.exists(downloadsDir))
			{
				// Clean up the entire downloads directory
				deleteDirectoryRecursiveStatic(downloadsDir);
				trace('Cleaned up all downloads directory: $downloadsDir');
			}

			// Also clean up any .tmp or .download files
			cleanupTemporaryFilesStatic(".", [".tmp", ".download", ".part"]);
		}
		catch (e:Dynamic)
		{
			trace('Error cleaning up temporary downloads: $e');
		}
	}

	/**
	 * Cleans up files with specific extensions (temporary files)
	 */
	private function cleanupTemporaryFiles(directory:String, extensions:Array<String>):Void
	{
		if (!FileSystem.exists(directory)) return;

		try
		{
			var files = FileSystem.readDirectory(directory);
			for (file in files)
			{
				var fullPath = '$directory/$file';
				if (FileSystem.isDirectory(fullPath))
				{
					// Recursively clean subdirectories
					cleanupTemporaryFiles(fullPath, extensions);
				}
				else
				{
					for (ext in extensions)
					{
						if (file.endsWith(ext))
						{
							FileSystem.deleteFile(fullPath);
							trace('Deleted temporary file: $fullPath');
							break;
						}
					}
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Error cleaning up temporary files in $directory: $e');
		}
	}

	/**
	 * Static version of cleanupTemporaryFiles
	 */
	public static function cleanupTemporaryFilesStatic(directory:String, extensions:Array<String>):Void
	{
		if (!FileSystem.exists(directory)) return;

		try
		{
			var files = FileSystem.readDirectory(directory);
			for (file in files)
			{
				var fullPath = '$directory/$file';
				if (FileSystem.isDirectory(fullPath))
				{
					// Recursively clean subdirectories
					cleanupTemporaryFilesStatic(fullPath, extensions);
				}
				else
				{
					for (ext in extensions)
					{
						if (file.endsWith(ext))
						{
							FileSystem.deleteFile(fullPath);
							trace('Deleted temporary file: $fullPath');
							break;
						}
					}
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Error cleaning up temporary files in $directory: $e');
		}
	}

	/**
	 * Recursively deletes a directory and all its contents
	 */
	private function deleteDirectoryRecursive(path:String):Void
	{
		if (!FileSystem.exists(path)) return;

		if (FileSystem.isDirectory(path))
		{
			var files = FileSystem.readDirectory(path);
			for (file in files)
			{
				deleteDirectoryRecursive('$path/$file');
			}
			FileSystem.deleteDirectory(path);
		}
		else
		{
			FileSystem.deleteFile(path);
		}
	}

	/**
	 * Static version of deleteDirectoryRecursive
	 */
	public static function deleteDirectoryRecursiveStatic(path:String):Void
	{
		if (!FileSystem.exists(path)) return;

		if (FileSystem.isDirectory(path))
		{
			var files = FileSystem.readDirectory(path);
			for (file in files)
			{
				deleteDirectoryRecursiveStatic('$path/$file');
			}
			FileSystem.deleteDirectory(path);
		}
		else
		{
			FileSystem.deleteFile(path);
		}
	}
}
