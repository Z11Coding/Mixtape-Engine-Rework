package states.music;

import backend.WeekData;
import flixel.system.FlxAssets;
import haxe.Json;
import haxe.io.Path;
import managers.FreeplayManager;
import sys.FileSystem;
import sys.io.File;

/**
 * Scans and catalogs all available music in the engine.
 * Uses FreeplayManager for charts and searches music folders
 * for standalone audio files.
 */
class MusicScanner
{
	public static function scanAllMusic():Array<MusicEntry>
	{
		var entries:Array<MusicEntry> = [];
		var seen:Map<String, Bool> = new Map();

		// First, add all songs from FreeplayManager (chart-based songs)
		var freeplayMgr = FreeplayManager.loadFPManager(true);
		if (freeplayMgr != null && freeplayMgr.songList != null) {
			for (songMeta in freeplayMgr.songList) {
				var key = '${songMeta.songName}_${songMeta.folder}';
				if (!seen.exists(key)) {
					seen.set(key, true);

					var entry = new MusicEntry(
						songMeta.songName,
						songMeta.songName,
						"chart",
						songMeta.folder // null or mod directory
					);

					// Set metadata from FreeplayManager
					if (songMeta.songCharacter != null) {
						entry.character = songMeta.songCharacter;
					}

					// Try to get more metadata
					var metaKey = '${songMeta.folder}_${songMeta.songName}'.toLowerCase();
					if (freeplayMgr.metadata != null && freeplayMgr.metadata.exists(metaKey)) {
						var metadata = freeplayMgr.metadata.get(metaKey);
						if (metadata != null && metadata.song != null) {
							if (metadata.song.artist != null) entry.artist = metadata.song.artist;
							if (metadata.song.charter != null) entry.album = 'Charter: ${metadata.song.charter}';
						}
						if (metadata != null && metadata.freeplay != null && metadata.freeplay.album != null) {
							entry.album = metadata.freeplay.album;
						}
					}

					// Set cover path from metadata
					entry.coverPath = getCoverPath(entry);

					// Check for inst/vocals
					checkChartTracks(entry);

					entries.push(entry);
				}
			}
		}

		// Then scan music folders for standalone audio files
		scanMusicFolders(entries, seen);

		return entries;
	}

	/**
	 * Scans music folders (both base and mod) for standalone audio files
	 */
	static function scanMusicFolders(entries:Array<MusicEntry>, seen:Map<String, Bool>):Void
	{
		// Scan base game music folders
		scanFolder(entries, seen, "assets/music", null);

		// Scan mod music folders
		#if MODS_ALLOWED
		for (mod in backend.Mods.parseList().enabled) {
			var modPath = 'mods/$mod/music';
			if (FileSystem.exists(modPath)) {
				scanFolder(entries, seen, modPath, mod);
			}
		}
		#end
	}

	/**
	 * Scans a folder for audio files and creates MusicEntry objects
	 */
	static function scanFolder(entries:Array<MusicEntry>, seen:Map<String, Bool>, folderPath:String, modSource:String):Void
	{
		if (!FileSystem.exists(folderPath)) {
			return;
		}

		try {
			for (file in FileSystem.readDirectory(folderPath)) {
				var fullPath = '$folderPath/$file';

				if (FileSystem.isDirectory(fullPath)) {
					// Don't scan subdirectories in music folder
					continue;
				}

				// Check if it's an audio file
				if (!isAudioFile(file)) {
					continue;
				}

				// Skip some system/UI audio
				if (shouldSkipFile(file)) {
					continue;
				}

				var songName = new Path(file).file;
				var key = '${songName}_${modSource}';

				if (!seen.exists(key)) {
					seen.set(key, true);

					var sourceType = modSource != null ? "mod_music" : "base_music";

					var entry = new MusicEntry(
						songName,
						songName,
						sourceType,
						modSource
					);

					entry.coverPath = null; // No cover for standalone music files usually

					entries.push(entry);
				}
			}
		} catch (e:Dynamic) {
			trace('Error scanning folder $folderPath: $e');
		}
	}

	/**
	 * Checks if a file is an audio file
	 */
	static function isAudioFile(fileName:String):Bool
	{
		var ext = new Path(fileName).ext.toLowerCase();
		return ext == "ogg" || ext == "mp3" || ext == "wav" || ext == "flac";
	}

	/**
	 * Returns true if this file should be skipped during scanning
	 */
	static function shouldSkipFile(fileName:String):Bool
	{
		var lower = fileName.toLowerCase();
		// Skip certain UI/system sounds
		return lower.contains("click") || lower.contains("menu") || lower.contains("confirm");
	}

	/**
	 * Checks what tracks are available for a chart song
	 */
	static function checkChartTracks(entry:MusicEntry):Void
	{
		var songPathBase = 'assets/songs/${entry.songId}';

		// Check in base game first
		if (FileSystem.exists('$songPathBase/Inst.ogg') || FileSystem.exists('$songPathBase/Inst.mp3')) {
			entry.hasInst = true;
		} else {
			entry.hasInst = false;
		}

		// Check for general vocals (Voices.ogg/mp3)
		if (FileSystem.exists('$songPathBase/Voices.ogg') || FileSystem.exists('$songPathBase/Voices.mp3')) {
			entry.hasVocals = true;
		} else {
			entry.hasVocals = false;
		}

		// Check for player-specific vocals
		if (FileSystem.exists('$songPathBase/Voices-Player.ogg') || FileSystem.exists('$songPathBase/Voices-Player.mp3')) {
			entry.hasPlayerVocals = true;
			entry.hasVocals = true; // Player vocals also count as available vocals
		}

		// Check for opponent-specific vocals
		if (FileSystem.exists('$songPathBase/Voices-Opponent.ogg') || FileSystem.exists('$songPathBase/Voices-Opponent.mp3')) {
			entry.hasOpponentVocals = true;
			entry.hasVocals = true; // Opponent vocals also count as available vocals
		}

		// Check for GF-specific vocals
		if (FileSystem.exists('$songPathBase/Voices-GF.ogg') || FileSystem.exists('$songPathBase/Voices-GF.mp3')) {
			entry.hasGFVocals = true;
			entry.hasVocals = true; // GF vocals also count as available vocals
		}

		// Check in mod folder if modded
		if (entry.isModded()) {
			var modPath = 'mods/${entry.modSource}/songs/${entry.songId}';
			if (FileSystem.exists(modPath)) {
				if (FileSystem.exists('$modPath/Inst.ogg') || FileSystem.exists('$modPath/Inst.mp3')) {
					entry.hasInst = true;
				}
				if (FileSystem.exists('$modPath/Voices.ogg') || FileSystem.exists('$modPath/Voices.mp3')) {
					entry.hasVocals = true;
				}
				if (FileSystem.exists('$modPath/Voices-Player.ogg') || FileSystem.exists('$modPath/Voices-Player.mp3')) {
					entry.hasPlayerVocals = true;
					entry.hasVocals = true;
				}
				if (FileSystem.exists('$modPath/Voices-Opponent.ogg') || FileSystem.exists('$modPath/Voices-Opponent.mp3')) {
					entry.hasOpponentVocals = true;
					entry.hasVocals = true;
				}
				if (FileSystem.exists('$modPath/Voices-GF.ogg') || FileSystem.exists('$modPath/Voices-GF.mp3')) {
					entry.hasGFVocals = true;
					entry.hasVocals = true;
				}
			}
		}
	}

	/**
	 * Gets the cover art path for a song
	 */
	static function getCoverPath(entry:MusicEntry):String
	{
		if (entry.sourceType == "chart") {
			// Try to get cover from freeplay metadata or week data
			var potentialPaths = [
				'assets/songs/${entry.songId}',
				'assets/week_assets/${entry.songId}',
			];

			for (basePath in potentialPaths) {
				for (ext in ["png", "jpg", "jpeg"]) {
					var coverPath = '$basePath/cover.$ext';
					if (FileSystem.exists(coverPath)) {
						return 'songs/${entry.songId}/cover';
					}
				}
			}

			// Try metadata album art reference
			var freeplayMgr = FreeplayManager.instance;
			if (freeplayMgr != null && freeplayMgr.metadata != null) {
				var metaKey = '${entry.modSource}_${entry.songId}'.toLowerCase();
				if (freeplayMgr.metadata.exists(metaKey)) {
					var metadata = freeplayMgr.metadata.get(metaKey);
					if (metadata != null && metadata.freeplay != null && metadata.freeplay.album != null) {
						var albumRef = metadata.freeplay.album;
						if (FileSystem.exists('assets/images/album_art/$albumRef.png')) {
							return 'album_art/$albumRef';
						}
					}
				}
			}
		}

		return null; // No cover found
	}
}
