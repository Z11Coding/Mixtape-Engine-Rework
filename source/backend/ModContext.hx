package backend;

import backend.NativeFileSystem;

/**
 * Provides Paths-like methods for a specific mod without changing currentModDirectory.
 *
 * This allows multiple threads or contexts to load assets from different mods
 * simultaneously without interfering with each other or the main thread.
 *
 * Usage:
 * ```haxe
 * var modContext = new ModContext("MyMod");
 * var charImage = modContext.image('characters/bf');
 * var soundFile = modContext.sound('songs/test/Inst');
 *
 * // In a thread
 * Threader.runInThread({
 *     var modContext = new ModContext("OtherMod");
 *     var asset = modContext.image('stage/bg');  // No interference with main thread
 * });
 * ```
 */
class ModContext {
	/**
	 * The mod directory this context is bound to.
	 */
	public var modDirectory:String;

	/**
	 * Creates a new mod context for the specified mod directory.
	 *
	 * @param modDirectory The mod directory (e.g., "MyMod").
	 *                     Empty string uses base game directory.
    *                    If null, defaults to backend.Mods.currentModDirectory.
	 */
	public function new(modDirectory:String = '') {
		this.modDirectory = modDirectory ?? backend.Mods.currentModDirectory;
	}

	/**
	 * Gets an image path for this mod.
	 *
	 * @param key Image name (e.g., "characters/bf").
	 * @return Path to the image.
	 */
	public function image(key:String):String {
		return Paths.modFolders('images/' + key + '.png', modDirectory);
	}

	/**
	 * Gets a sound path for this mod.
	 *
	 * @param key Sound name (e.g., "songs/test/Inst").
	 * @return Path to the sound.
	 */
	public function sound(key:String):String {
		return Paths.modFolders(key + '.' + Paths.SOUND_EXT, modDirectory);
	}

	/**
	 * Gets a JSON data path for this mod.
	 *
	 * @param key JSON file name (e.g., "data/test-song/test-hard").
	 * @return Path to the JSON file.
	 */
	public function json(key:String):String {
		return Paths.modFolders('data/' + key + '.json', modDirectory);
	}

	/**
	 * Gets a music path for this mod.
	 *
	 * @param key Music file name (e.g., "songs/test/Inst").
	 * @return Path to the music file.
	 */
	public function music(key:String):String {
		return Paths.modFolders('music/' + key + '.' + Paths.SOUND_EXT, modDirectory);
	}

	/**
	 * Gets a file path for this mod.
	 *
	 * @param path Relative path within the mod.
	 * @return Full path to the file.
	 */
	public function file(path:String):String {
		return Paths.mods(modDirectory + (modDirectory.length > 0 ? '/' : '') + path);
	}

	/**
	 * Checks if a file exists in this mod.
	 *
	 * @param path Relative path within the mod.
	 * @return true if the file exists, false otherwise.
	 */
	public function fileExists(path:String):Bool {
		#if sys
		return NativeFileSystem.exists(file(path));
		#else
		return false;
		#end
	}

	/**
	 * Loads file content from this mod.
	 *
	 * @param path Relative path within the mod.
	 * @return File content, or empty string if not found.
	 */
	public function loadFile(path:String):String {
		#if sys
		var fullPath = file(path);
		if (NativeFileSystem.exists(fullPath)) {
			try {
				return sys.io.File.getContent(fullPath);
			} catch (e:Dynamic) {
				return '';
			}
		}
		#end
		return '';
	}

	/**
	 * Gets the pack.json data for this mod.
	 *
	 * @return The pack object, or null if not found.
	 */
	public function getPack():Dynamic {
		return Mods.getPack(modDirectory);
	}

	/**
	 * Checks if this mod is enabled.
	 *
	 * @return true if in enabled mods list, false otherwise.
	 */
	public function isEnabled():Bool {
		return Mods.isModDirEnabled(modDirectory);
	}

	/**
	 * Gets the mod directory this context is bound to.
	 */
	public function getModDirectory():String {
		return modDirectory;
	}

	/**
	 * Creates a child context for a subdirectory within this mod.
	 *
	 * @param subPath Relative path within the mod.
	 * @return A new ModContext for the subdirectory.
	 */
	public function createChild(subPath:String):ModContext {
		var childPath = modDirectory;
		if (childPath.length > 0 && !childPath.endsWith('/')) {
			childPath += '/';
		}
		childPath += subPath;
		return new ModContext(childPath);
	}

	/**
	 * Loads a song chart for this mod without changing currentModDirectory.
	 * Handles chart format upgrading, High Quality Trap replacements, and special cases.
	 * Completely thread-safe - never touches global state.
	 *
	 * @param chartName Chart name (e.g., "test-song" or "test-song-hard").
	 * @param songPath Song path (e.g., "test-song").
	 * @return Loaded SwagSong object, or null if not found/invalid.
	 */
	public function loadSongChart(chartName:String, songPath:String):Null<Song.SwagSong> {
		#if sys
		try {
			var actualSongPath = songPath;
			var actualChartName = chartName;

			#if ARCHIPELAGO_ALLOWED
			// Check for High Quality Trap replacement - pass modDirectory explicitly
			var replacementSong = archipelago.HighQualityTrapManager.getReplacementSong(songPath, modDirectory);
			if (replacementSong != songPath) {
				trace('ModContext.loadSongChart: High Quality Trap replacing "$songPath" with "$replacementSong"');
				actualSongPath = replacementSong;
				// Update chartName if it matches the original song
				if (Paths.formatToSongPath(chartName) == Paths.formatToSongPath(songPath)) {
					actualChartName = replacementSong;
				}
			}
			#end

			// Load the chart JSON directly from this mod
			var jsonPath = 'data/${actualSongPath}/${actualChartName}.json';
			var jsonContent = loadFile(jsonPath);

			if (jsonContent.length == 0) {
				return null;
			}

			// Parse and convert chart format using Song's conversion logic
			var song:Song.SwagSong = Song.parseJSON(jsonContent, actualChartName, 'psych_v1');

			return song;
		} catch (e:Dynamic) {
			return null;
		}
		#else
		return null;
		#end
	}
}
