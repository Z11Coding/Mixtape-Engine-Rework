package states.music;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.Alphabet;

/**
 * The Music Player state - allows listening to all songs and audio in the engine
 */
class MusicPlayerState extends MusicBeatState
{
	var manager:MusicPlayerManager;

	// UI Groups
	var songList:FlxTypedGroup<Alphabet>;
	var bg:FlxSprite;

	// Currently displayed songs (filtered/all)
	var displayedSongs:Array<MusicEntry> = [];
	var currentSelection:Int = 0;

	// UI Elements
	var titleText:FlxText;
	var nowPlayingText:FlxText;
	var timeText:FlxText;
	var albumArtSprite:FlxSprite;
	var controlHintText:FlxText;

	// Volume display
	var instVolText:FlxText;
	var vocalsVolText:FlxText;

	// State
	var viewMode:String = "all_songs"; // all_songs, base_songs, mod_songs, playlists
	var searchQuery:String = "";
	var visibleRange:Int = 15; // Number of songs to display on screen

	override function create()
	{
		MemoryUtil.clearMajor();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In Music Player", null);
		#end

		manager = MusicPlayerManager.getInstance();

		// Create background
		bg = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.color = FlxColor.fromRGB(30, 40, 60);
		bg.scrollFactor.set();
		add(bg);

		// Create UI
		createUI();

		// Load and display songs
		displayedSongs = manager.allSongs.copy();
		initialBuildSongList();

		Cursor.show();
		Cursor.cursorMode = Default;

		super.create();
	}

	function createUI():Void
	{
		// Title
		titleText = new FlxText(20, 20, FlxG.width - 40, "Music Player", 32);
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
		titleText.scrollFactor.set();
		add(titleText);

		// Now Playing info
		nowPlayingText = new FlxText(20, 70, FlxG.width - 40, "Select a song to play", 16);
		nowPlayingText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW);
		nowPlayingText.scrollFactor.set();
		add(nowPlayingText);

		// Time display
		timeText = new FlxText(20, 100, 300, "00:00 / 00:00", 14);
		timeText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE);
		timeText.scrollFactor.set();
		add(timeText);

		// Album art placeholder
		albumArtSprite = new FlxSprite(FlxG.width - 220, 20);
		albumArtSprite.makeGraphic(200, 200, FlxColor.fromRGB(60, 60, 80));
		albumArtSprite.scrollFactor.set();
		add(albumArtSprite);

		// Volume display
		instVolText = new FlxText(20, 140, 400, 'Inst: 80% ${manager.instMuted ? '[MUTED]' : ''}', 12);
		instVolText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.CYAN);
		instVolText.scrollFactor.set();
		add(instVolText);

		vocalsVolText = new FlxText(20, 160, 400, 'Vocals: 80% ${manager.vocalsMuted ? '[MUTED]' : ''}', 12);
		vocalsVolText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.MAGENTA);
		vocalsVolText.scrollFactor.set();
		add(vocalsVolText);

		// Control hints
		controlHintText = new FlxText(20, FlxG.height - 100, FlxG.width - 40, "");
		controlHintText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.fromRGB(200, 200, 200));
		controlHintText.scrollFactor.set();
		controlHintText.text = getControlHints();
		add(controlHintText);

		// Song list
		songList = new FlxTypedGroup<Alphabet>();
		add(songList);
	}

	function initialBuildSongList():Void
	{
		songList.clear();

		// Only build visible items + buffer
		var startIdx:Num = Math.max(0, currentSelection - 2);
		var endIdx:Num = Math.min(displayedSongs.length, currentSelection + visibleRange);

		for (i in startIdx...endIdx) {
			var song = displayedSongs[i];
			var label = song.getFullLabel();

			// Add source annotation
			if (song.isModded()) {
				label += ' [${song.modSource}]';
			} else {
				label += ' [Base]';
			}

			var songText = new Alphabet(20, 200 + ((i - startIdx) * 35), label, false);
			songText.isMenuItem = true;
			songText.targetY = i - currentSelection;
			songText.ID = i;
			songText.alpha = (i == currentSelection) ? 1 : 0.6;
			songList.add(songText);
		}

		updateDisplay();
	}

	function updateSongListVisuals():Void
	{
		// Efficiently update visual properties without rebuilding
		for (item in songList.members) {
			if (item != null) {
				var idx = item.ID;
				item.targetY = idx - currentSelection;
				item.alpha = (idx == currentSelection) ? 1 : 0.6;
			}
		}
	}

	function updateDisplay():Void
	{
		// Show currently playing song, not selected song
		var displaySong = (manager.isPlaying && manager.currentSong != null) ? manager.currentSong : null;

		if (displaySong != null) {
			// Update now playing text with currently playing song
			nowPlayingText.text = 'Now: ${displaySong.getFullLabel()} ${displaySong.getSourceLabel()}';
		} else if (displayedSongs.length > 0 && currentSelection >= 0 && currentSelection < displayedSongs.length) {
			var song = displayedSongs[currentSelection];
			// Update now playing text with selected song
			nowPlayingText.text = 'Sel: ${song.getFullLabel()} ${song.getSourceLabel()}';
		}

		if (displayedSongs.length > 0 && currentSelection >= 0 && currentSelection < displayedSongs.length) {
			var song = displayedSongs[currentSelection];

			// Update time if playing
			if (manager.isPlaying && manager.currentSong == song) {
				var current = manager.getCurrentTime();
				var duration = manager.getCurrentDuration();
				var timeStr = formatTime(current) + ' / ' + formatTime(duration);
				timeText.text = timeStr;
			} else {
				timeText.text = "00:00 / 00:00";
			}

			// Update volume text
			instVolText.text = 'Inst: ${Math.round(manager.instVolume * 100)}% ${manager.instMuted ? '[MUTED]' : ''}';
			vocalsVolText.text = 'Vocals: ${Math.round(manager.vocalsVolume * 100)}% ${manager.vocalsMuted ? '[MUTED]' : ''}';

			// Try to load album art
			loadAlbumArt(song);
		}
	}

	function loadAlbumArt(song:MusicEntry):Void
	{
		if (song.coverPath != null) {
			try {
				albumArtSprite.loadGraphic(Paths.image(song.coverPath));
			} catch (e:Dynamic) {
				albumArtSprite.makeGraphic(200, 200, FlxColor.fromRGB(80, 80, 80));
			}
		} else {
			// Show placeholder with song info
			albumArtSprite.makeGraphic(200, 200, FlxColor.fromRGB(50, 50, 80));
		}
	}

	function formatTime(seconds:Float):String
	{
		var mins = Math.floor(seconds / 60);
		var secs = Math.floor(seconds % 60);
		return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs;
	}

	function getControlHints():String
	{
		var hints = [
			"SPACE: Play/Pause | N: Next | P: Previous | R: Repeat | S: Shuffle",
			"I: Mute Inst | V: Mute Vocals | UP/DOWN: Vol | ENTER: Play | B: Back"
		];
		return hints.join("\n");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		manager.update(elapsed);

		// Update time display
		if (manager.isPlaying && displayedSongs.contains(manager.currentSong)) {
			updateDisplay();
		}

		// Controls
		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new CategoryState());
			return;
		}

		// Song selection
		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;

		if (upP) {
			changeSelection(-1);
		}
		if (downP) {
			changeSelection(1);
		}

		// Playback controls
		if (FlxG.keys.justPressed.SPACE) {
			if (manager.currentSong != null) {
				if (manager.isPlaying) {
					manager.pause();
				} else {
					manager.resume();
				}
			} else if (displayedSongs.length > 0) {
				manager.loadSong(displayedSongs[currentSelection]);
				manager.play();
			}
		}

		// Next song
		if (FlxG.keys.justPressed.N) {
			manager.nextSong();
			findCurrentAndScroll();
		}

		// Previous song
		if (FlxG.keys.justPressed.P) {
			manager.previousSong();
			findCurrentAndScroll();
		}

		// Repeat mode
		if (FlxG.keys.justPressed.R) {
			manager.cycleRepeatMode();
			var mode = ["Off", "All", "One"];
			trace('Repeat: ${mode[manager.repeatMode]}');
		}

		// Shuffle
		if (FlxG.keys.justPressed.S) {
			manager.toggleShuffle();
			trace('Shuffle: ${manager.shuffleEnabled ? "On" : "Off"}');
		}

		// Volume controls
		var volUp = FlxG.keys.pressed.UP;
		var volDown = FlxG.keys.pressed.DOWN;

		if (volUp) {
			manager.setInstVolume(manager.instVolume + 0.01);
			updateDisplay();
		}
		if (volDown) {
			manager.setInstVolume(manager.instVolume - 0.01);
			updateDisplay();
		}

		// Mute instrumental
		if (FlxG.keys.justPressed.I) {
			manager.toggleInstMute();
			updateDisplay();
		}

		// Mute vocals
		if (FlxG.keys.justPressed.V) {
			manager.toggleVocalsMute();
			updateDisplay();
		}

		// Play selected song on Enter
		if (FlxG.keys.justPressed.ENTER) {
			if (displayedSongs.length > 0) {
				manager.loadSong(displayedSongs[currentSelection]);
				manager.play();
				trace('Playing: ${displayedSongs[currentSelection].displayName}');
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		currentSelection += change;

		if (currentSelection < 0) {
			currentSelection = displayedSongs.length - 1;
		}
		if (currentSelection >= displayedSongs.length) {
			currentSelection = 0;
		}

		updateSongListVisuals();
		updateDisplay();
	}

	function findCurrentAndScroll():Void
	{
		// Find current song in displayed list
		if (manager.currentSong != null) {
			for (i in 0...displayedSongs.length) {
				if (displayedSongs[i] == manager.currentSong) {
					currentSelection = i;
					updateSongListVisuals();
					updateDisplay();
					return;
				}
			}
		}
	}

	override function destroy()
	{
		manager.stopCurrentSong();
		super.destroy();
	}
}
