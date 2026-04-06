package states.music;

import backend.Paths;
import flixel.FlxG;
import flixel.sound.FlxSound;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

/**
 * Manages the Music Player's playback state, including:
 * - Current song playback
 * - Volume control for separate tracks (inst/vocals)
 * - Playlist management
 * - Shuffle and repeat modes
 */
class MusicPlayerManager
{
	/** Singleton instance */
	private static var _instance:MusicPlayerManager;

	/** All available songs */
	public var allSongs:Array<MusicEntry> = [];

	/** Current playlist (null = all songs) */
	public var currentPlaylist:MusicPlayerPlaylist;

	/** Songs in current playback queue */
	public var queue:Array<MusicEntry> = [];

	/** Current song index in queue */
	public var currentIndex:Int = 0;

	/** Currently playing song */
	public var currentSong:MusicEntry;

	/** Instrumental track volume (0-1) */
	public var instVolume:Float = 0.8;

	/** Vocals track volume (0-1) */
	public var vocalsVolume:Float = 0.8;

	/** Whether to mute instrumental */
	public var instMuted:Bool = false;

	/** Whether to mute vocals */
	public var vocalsMuted:Bool = false;

	/** Repeat mode: 0 = off, 1 = all, 2 = one */
	public var repeatMode:Int = 0;

	/** Shuffle enabled */
	public var shuffleEnabled:Bool = false;

	/** Is currently playing */
	public var isPlaying:Bool = false;

	/** Current playback time in seconds */
	public var currentTime:Float = 0;

	/** Currently loaded inst FlxSound */
	public var currentInstSound:FlxSound;

	/** Currently loaded vocals FlxSound */
	public var currentVocalsSound:FlxSound;

	/** Saved playlists */
	public var playlists:Array<MusicPlayerPlaylist> = [];

	private function new()
	{
		loadPlaylists();
		rescanMusic();
	}

	public static function getInstance():MusicPlayerManager
	{
		if (_instance == null) {
			_instance = new MusicPlayerManager();
		}
		return _instance;
	}

	/**
	 * Rescans all available music
	 */
	public function rescanMusic():Void
	{
		allSongs = MusicScanner.scanAllMusic();
		queue = allSongs.copy();
		trace('Music Player: Found ${allSongs.length} total songs');
	}

	/**
	 * Loads a song into the player
	 */
	public function loadSong(entry:MusicEntry):Void
	{
		stopCurrentSong();
		currentSong = entry;

		// Load inst and vocals based on song type
		if (entry.sourceType == "chart") {
			try {
				if (entry.hasInst) {
					var instSound = FlxG.sound.load(Paths.inst(entry.songId), instVolume);
					if (instSound != null) {
						currentInstSound = instSound;
					}
				}

			// Try to load vocals - prefer general, then mix others
			if (entry.hasVocals) {
				// Try general vocals first
				var vocalsSound = FlxG.sound.load(Paths.voices(entry.songId), vocalsVolume);
				if (vocalsSound != null) {
					currentVocalsSound = vocalsSound;
				} else if (entry.hasPlayerVocals) {
					// Try player vocals
					var playerVocals = FlxG.sound.load(Paths.voices(entry.songId, 'Player'), vocalsVolume);
					if (playerVocals != null) {
						currentVocalsSound = playerVocals;
					}
				} else if (entry.hasOpponentVocals) {
					// Try opponent vocals
					var oppVocals = FlxG.sound.load(Paths.voices(entry.songId, 'Opponent'), vocalsVolume);
					if (oppVocals != null) {
						currentVocalsSound = oppVocals;
					}
				} else if (entry.hasGFVocals) {
					// Try GF vocals
					var gfVocals = FlxG.sound.load(Paths.voices(entry.songId, 'GF'), vocalsVolume);
					if (gfVocals != null) {
						currentVocalsSound = gfVocals;
					}
					}
				}
			} catch (e:Dynamic) {
				trace('Error loading chart audio for ${entry.songId}: $e');
			}
		} else {
			// Try to load standalone audio file from music folder
			try {
				var musicPath = entry.songId;
				if (entry.modSource != null) {
					// For modded music, need special handling
					musicPath = '${entry.modSource}_${entry.songId}';
				}

				// Try to load as main track using Paths.music
				var loadedSound = Paths.music(musicPath);
				if (loadedSound != null) {
					currentInstSound = FlxG.sound.load(loadedSound, instVolume);
				}
				currentVocalsSound = null;
			} catch (e:Dynamic) {
				trace('Error loading music file for ${entry.songId}: $e');
			}
		}

		// Apply current volume settings
		updateTrackVolumes();
	}

	/**
	 * Plays the current loaded song
	 */
	public function play():Void
	{
		if (currentInstSound != null) {
			currentInstSound.play();
			currentInstSound.volume = instMuted ? 0 : instVolume;
		}
		if (currentVocalsSound != null) {
			currentVocalsSound.play();
			currentVocalsSound.volume = vocalsMuted ? 0 : vocalsVolume;
		}
		isPlaying = true;
	}

	/**
	 * Pauses playback
	 */
	public function pause():Void
	{
		if (currentInstSound != null) currentInstSound.pause();
		if (currentVocalsSound != null) currentVocalsSound.pause();
		isPlaying = false;
	}

	/**
	 * Resumes playback
	 */
	public function resume():Void
	{
		if (currentInstSound != null) currentInstSound.resume();
		if (currentVocalsSound != null) currentVocalsSound.resume();
		isPlaying = true;
	}

	/**
	 * Stops playback
	 */
	public function stopCurrentSong():Void
	{
		if (currentInstSound != null) {
			currentInstSound.stop();
			currentInstSound.destroy();
			currentInstSound = null;
		}
		if (currentVocalsSound != null) {
			currentVocalsSound.stop();
			currentVocalsSound.destroy();
			currentVocalsSound = null;
		}
		isPlaying = false;
	}

	/**
	 * Plays next song in queue
	 */
	public function nextSong():Void
	{
		if (queue.length == 0) return;

		currentIndex++;
		if (currentIndex >= queue.length) {
			currentIndex = 0;
			if (repeatMode == 0) {
				// Repeat off - stop playing
				stopCurrentSong();
				return;
			}
		}

		var nextSong = queue[currentIndex];
		loadSong(nextSong);
		play();
	}

	/**
	 * Plays previous song in queue
	 */
	public function previousSong():Void
	{
		if (queue.length == 0) return;

		currentIndex--;
		if (currentIndex < 0) {
			currentIndex = queue.length - 1;
		}

		var prevSong = queue[currentIndex];
		loadSong(prevSong);
		play();
	}

	/**
	 * Updates track volumes based on mute settings
	 */
	public function updateTrackVolumes():Void
	{
		if (currentInstSound != null) {
			currentInstSound.volume = instMuted ? 0 : instVolume;
		}
		if (currentVocalsSound != null) {
			currentVocalsSound.volume = vocalsMuted ? 0 : vocalsVolume;
		}
	}

	/**
	 * Sets instrumental volume
	 */
	public function setInstVolume(vol:Float):Void
	{
		instVolume = Math.max(0, Math.min(1, vol));
		if (currentInstSound != null && !instMuted) {
			currentInstSound.volume = instVolume;
		}
	}

	/**
	 * Sets vocals volume
	 */
	public function setVocalsVolume(vol:Float):Void
	{
		vocalsVolume = Math.max(0, Math.min(1, vol));
		if (currentVocalsSound != null && !vocalsMuted) {
			currentVocalsSound.volume = vocalsVolume;
		}
	}

	/**
	 * Toggles muting of instrumental track
	 */
	public function toggleInstMute():Void
	{
		instMuted = !instMuted;
		if (currentInstSound != null) {
			currentInstSound.volume = instMuted ? 0 : instVolume;
		}
	}

	/**
	 * Toggles muting of vocals track
	 */
	public function toggleVocalsMute():Void
	{
		vocalsMuted = !vocalsMuted;
		if (currentVocalsSound != null) {
			currentVocalsSound.volume = vocalsMuted ? 0 : vocalsVolume;
		}
	}

	/**
	 * Cycles through repeat modes
	 */
	public function cycleRepeatMode():Void
	{
		repeatMode = (repeatMode + 1) % 3;
	}

	/**
	 * Toggles shuffle
	 */
	public function toggleShuffle():Void
	{
		shuffleEnabled = !shuffleEnabled;
		rebuildQueue();
	}

	/**
	 * Rebuilds queue based on current filters and shuffle setting
	 */
	public function rebuildQueue():Void
	{
		queue = (currentPlaylist != null) ? currentPlaylist.songs.copy() : allSongs.copy();

		if (shuffleEnabled) {
			for (i in 0...queue.length) {
				var j = Math.floor(Math.random() * queue.length);
				var temp = queue[i];
				queue[i] = queue[j];
				queue[j] = temp;
			}
		}

		currentIndex = 0;
	}

	/**
	 * Gets current playback time
	 */
	public function getCurrentTime():Float
	{
		if (currentInstSound != null) {
			return currentInstSound.time / 1000; // Convert from milliseconds
		}
		return 0;
	}

	/**
	 * Gets duration of current song
	 */
	public function getCurrentDuration():Float
	{
		if (currentInstSound != null) {
			return currentInstSound.length / 1000; // Convert from milliseconds
		}
		return 0;
	}

	/**
	 * Seeks to a position in the current song
	 */
	public function seek(time:Float):Void
	{
		var ms = time * 1000; // Convert to milliseconds
		if (currentInstSound != null) {
			currentInstSound.time = ms;
		}
		if (currentVocalsSound != null) {
			currentVocalsSound.time = ms;
		}
	}

	// ===== PLAYLIST MANAGEMENT =====

	/**
	 * Creates a new playlist
	 */
	public function createPlaylist(name:String):MusicPlayerPlaylist
	{
		var playlist = new MusicPlayerPlaylist(name);
		playlists.push(playlist);
		savePlaylists();
		return playlist;
	}

	/**
	 * Loads a playlist for playback
	 */
	public function loadPlaylist(playlist:MusicPlayerPlaylist):Void
	{
		currentPlaylist = playlist;
		rebuildQueue();
		currentIndex = 0;
	}

	/**
	 * Saves all playlists to file
	 */
	public function savePlaylists():Void
	{
		try {
			var playlistData = [];
			for (playlist in playlists) {
				playlistData.push(playlist.toJson());
			}
			var json = Json.stringify(playlistData);
			var savePath = 'music_playlists.json';
			File.saveContent(savePath, json);
		} catch (e:Dynamic) {
			trace('Error saving playlists: $e');
		}
	}

	/**
	 * Loads playlists from file
	 */
	public function loadPlaylists():Void
	{
		// Playlist loading deferred - JSON parsing having type issues
		playlists = [];
	}

	/**
	 * Deletes a playlist
	 */
	public function deletePlaylist(playlist:MusicPlayerPlaylist):Void
	{
		playlists.remove(playlist);
		if (currentPlaylist == playlist) {
			currentPlaylist = null;
			rebuildQueue();
		}
		savePlaylists();
	}

	/**
	 * Updates playback from current audio
	 */
	public function update(elapsed:Float):Void
	{
		// Check if current song finished
		if (isPlaying && currentInstSound != null) {
			if (currentInstSound.playing == false && !isPlaying) {
				// Song ended
				nextSong();
			}
		}
	}
}
