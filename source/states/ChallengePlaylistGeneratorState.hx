package states;

import archipelago.substates.InfoPanelSubstate;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import options.GameplayChangersSubstate;
import states.LoadingState;
import states.PlayState;
import states.PlaylistState.PlaylistMetadata;
import states.PlaylistState.PlaylistSongMetadata;
import yutautil.modules.ASync.AResult;
import yutautil.modules.ASync;

/**
 * State machine enum for challenge playlist generation
 */
enum ChallengeGenState {
	MENU;                    // Showing menu, waiting for input
	GENERATING_DISCOVERING;  // Discovering songs from WeekData
	GENERATING_DIFFICULTIES; // Getting available difficulties
	GENERATING_SCORING;      // Scoring songs (sub-state for each song)
	GENERATING_SELECTING;    // Selecting top N songs
	PREVIEW;                 // Preview mode (unchanged)
	READY;                   // Ready to launch PlayState
	CANCELLING;              // Waiting for async to stop
	CANCELLED;               // Generation was cancelled, ready to return
}

/**
 * ChallengePlaylistGeneratorState
 *
 * Manages the generation of challenge playlists with async generation,
 * preview mode, and proper state machine transitions.
 */
class ChallengePlaylistGeneratorState extends backend.MusicBeatState
{
	// State tracking
	private var currentState:ChallengeGenState = MENU;
	private var generatorAsync:ASyncF<PlaylistMetadata>;
	private var generatorResult:Null<AResult<PlaylistMetadata>>;

	// Configuration
	private var songCount:Int = 10;
	private var previewEnabled:Bool = false;
	private var generatedPlaylist:Null<PlaylistMetadata>;

	// UI Elements
	private var menuBG:FlxSprite;
	private var songCountText:FlxText;
	private var previewToggleText:FlxText;
	private var statusText:FlxText;
	private var instructionText:FlxText;
	private var generatedSongsText:FlxText;

	// Generation tracking
	private var generatingProgress:Int = 0;
	private var totalSongsToGenerate:Int = 0;
	private var currentSongName:String = "";

	// Maximum songs available (will be set during discovery)
	private var maxSongs:Int = 0;

	// Static progress tracking for async function
	private static var generationPhase:ChallengeGenState = MENU;
	private static var generationProgress:Int = 0;
	private static var generationSongName:String = "";
	private static var cancellationRequested:Bool = false;

	override function create():Void
	{
		// Game state initialization
		Mods.loadTopMod();
		Paths.clearStoredWithoutStickers();
		persistentUpdate = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Generating Challenge Playlist', null);
		#end

		// Set background color
		FlxG.camera.bgColor = 0xFF222222;

		// Create background
		menuBG = new FlxSprite(0, 0);
		menuBG.makeGraphic(FlxG.width, FlxG.height, 0xFF1a1a1a);
		add(menuBG);

		// Create title text
		var titleText:FlxText = new FlxText(0, 80, FlxG.width, "Challenge Playlist Generator", 32);
		titleText.alignment = CENTER;
		titleText.color = FlxColor.WHITE;
		titleText.fieldWidth = FlxG.width;
		titleText.screenCenter(X);
		add(titleText);

		// Create song count text
		songCountText = new FlxText(0, 200, FlxG.width, "", 24);
		songCountText.alignment = CENTER;
		songCountText.color = FlxColor.YELLOW;
		songCountText.fieldWidth = FlxG.width;
		songCountText.screenCenter(X);
		add(songCountText);

		// Create preview toggle text
		previewToggleText = new FlxText(0, 280, FlxG.width, "", 24);
		previewToggleText.alignment = CENTER;
		previewToggleText.color = FlxColor.WHITE;
		previewToggleText.fieldWidth = FlxG.width;
		previewToggleText.screenCenter(X);
		add(previewToggleText);

		// Create status text
		statusText = new FlxText(0, 360, FlxG.width, "", 20);
		statusText.alignment = CENTER;
		statusText.color = FlxColor.LIME;
		statusText.fieldWidth = FlxG.width;
		statusText.screenCenter(X);
		add(statusText);

		// Create instruction text
		instructionText = new FlxText(0, 450, FlxG.width, "", 18);
		instructionText.alignment = CENTER;
		instructionText.color = FlxColor.WHITE;
		instructionText.fieldWidth = FlxG.width;
		instructionText.screenCenter(X);
		add(instructionText);

		// Create generated songs display text
		generatedSongsText = new FlxText(50, 550, FlxG.width - 100, "", 14);
		generatedSongsText.alignment = LEFT;
		generatedSongsText.color = FlxColor.WHITE;
		generatedSongsText.fieldWidth = FlxG.width - 100;
		add(generatedSongsText);

		// Discover max songs available
		var allSongs = managers.SongDifficultyEvaluator.discoverAllSongs();
		maxSongs = allSongs.length;

		// Validate song count
		if (songCount > maxSongs)
			songCount = maxSongs;

		updateMenuDisplay();

		super.create();
	}

	private function updateMenuDisplay():Void
	{
		if (currentState == MENU) {
			songCountText.text = "Number of Songs: " + songCount + " (Max: " + maxSongs + ")";
			previewToggleText.text = "Preview Playlist: " + (previewEnabled ? "ON" : "OFF");
			statusText.text = "";
			instructionText.text = "UP/DOWN - Adjust Songs\nLEFT/RIGHT - Toggle Preview\nENTER - Generate\nESC - Back";
			generatedSongsText.text = "";
		}
	}

	private function updateGeneratingDisplay():Void
	{
		switch (currentState) {
			case GENERATING_DISCOVERING:
				statusText.text = "Discovering songs...";
				instructionText.text = "ESC - Cancel Generation";
			case GENERATING_DIFFICULTIES:
				statusText.text = "Finding difficulties: " + generatingProgress + "/" + totalSongsToGenerate;
				instructionText.text = "ESC - Cancel Generation";
			case GENERATING_SCORING:
				statusText.text = "Scoring songs: " + generatingProgress + "/" + totalSongsToGenerate;
				if (currentSongName != "")
					instructionText.text = "Current: " + currentSongName + "\nESC - Cancel Generation";
				else
					instructionText.text = "ESC - Cancel Generation";
			case GENERATING_SELECTING:
				statusText.text = "Selecting hardest songs...";
				instructionText.text = "ESC - Cancel Generation";
			default:
				statusText.text = "Generating... " + generatingProgress + " of " + totalSongsToGenerate;
				instructionText.text = "ESC - Cancel Generation";
		}
	}

	private function updatePreviewDisplay():Void
	{
		if (generatedPlaylist != null) {
			previewToggleText.text = generatedPlaylist.playlistName;

			var songListStr:String = "";
			for (i in 0...generatedPlaylist.songList.length) {
				var song = generatedPlaylist.songList[i];
				songListStr += (i + 1) + ". " + song.songName + " [" + song.difficulty + "]\n";
			}
			generatedSongsText.text = songListStr;

			instructionText.text = "ENTER - Play Playlist\nCTRL - Settings Menu\nESC - Back";
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		switch (currentState) {
			case MENU:
				handleMenuInput();
			case GENERATING_DISCOVERING | GENERATING_DIFFICULTIES | GENERATING_SCORING | GENERATING_SELECTING:
				handleGeneratingState();
			case PREVIEW:
				handlePreviewInput();
			case READY:
				// Load first song before transitioning to PlayState
				if (generatedPlaylist != null && generatedPlaylist.songList.length > 0) {
					var firstSong = generatedPlaylist.songList[0];
					var songLowercase:String = Paths.formatToSongPath(firstSong.songName);
					Mods.currentModDirectory = firstSong.folder != null ? firstSong.folder : '';
					PlayState.storyWeek = firstSong.week;
					backend.Song.loadFromJson('${songLowercase}${(firstSong.difficulty.toLowerCase() != "normal" ? "-"+firstSong.difficulty.toLowerCase() : "")}', songLowercase);
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState(generatedPlaylist));
				}
			case CANCELLING:
				handleCancellingState();
			case CANCELLED:
				// Return to playlist state and reset cancellation flag
				cancellationRequested = false;
				FlxG.switchState(new states.PlaylistState());
		}
	}

	private function handleMenuInput():Void
	{
		// Adjust song count with up/down
		if (controls.justPressed("ui_up")) {
			if (songCount < maxSongs)
				songCount++;
			updateMenuDisplay();
		}
		if (controls.justPressed("ui_down")) {
			if (songCount > 1)
				songCount--;
			updateMenuDisplay();
		}

		// Toggle preview with left/right
		if (controls.justPressed("ui_left") || controls.justPressed("ui_right")) {
			previewEnabled = !previewEnabled;
			updateMenuDisplay();
		}

		// Start generation
		if (controls.justPressed("accept")) {
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			startAsyncGeneration();
		}

		// Back to playlist state
		if (controls.justPressed("back")) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			FlxG.switchState(new states.PlaylistState());
		}
	}

	private function startAsyncGeneration():Void
	{
		currentState = GENERATING_DISCOVERING;
		totalSongsToGenerate = songCount;
		generatingProgress = 0;
		currentSongName = "";

		// Create async wrapper using the ASync type
		generatorAsync = generateChallengePlaylistAsync;

		// Call function asynchronously
		generatorResult = generatorAsync(songCount);
	}

	private function handleGeneratingState():Void
	{
		// Always keep display in sync with actual generation phase
		currentState = generationPhase;

		// Read progress from static tracking variables
		generatingProgress = generationProgress;
		currentSongName = generationSongName;

		// Check if async result is ready, independent of state
		if (generatorResult != null && generatorResult.isReady) {
			// If we're cancelling, transition to cancelled
			if (cancellationRequested) {
				currentState = CANCELLED;
			} else {
				// Normal completion path
				try {
					generatedPlaylist = generatorResult.get();
					currentState = previewEnabled ? PREVIEW : READY;

					if (currentState == PREVIEW) {
						updatePreviewDisplay();
					}
				} catch (e:Dynamic) {
					InfoPanelSubstate.show("Generation Error", 'Generation failed: ${e}\n\nReturning to menu...', FlxColor.RED, () -> {
						currentState = MENU;
						generatorResult = null;
						updateMenuDisplay();
					});
				}
			}
		} else if (generatorResult != null && generatorResult.isFailed) {
			// Handle async failure
			InfoPanelSubstate.show("Generation Failed", 'Playlist generation failed.\n\nReturning to menu...', FlxColor.RED, () -> {
				currentState = MENU;
				generatorResult = null;
				updateMenuDisplay();
			});
		} else {
			// Still generating - update the display
			updateGeneratingDisplay();
		}

		// Handle user cancellation request
		if (controls.justPressed("back")) {
			cancellationRequested = true;
			statusText.text = "Cancelling...";
		}
	}

	private function handleCancellingState():Void
	{
		// Wait for async to finish
		if (generatorResult != null && generatorResult.isReady) {
			currentState = CANCELLED;
		}
	}

	override function closeSubState():Void
	{
		super.closeSubState();
		persistentUpdate = true;
	}

	private function handlePreviewInput():Void
	{
		// Play the playlist
		if (controls.justPressed("accept")) {
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			currentState = READY;
		}

		// Back to menu
		if (controls.justPressed("back")) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			currentState = MENU;
			generatedPlaylist = null;
			generatorResult = null;
			updateMenuDisplay();
		}

		// Settings menu (Ctrl key)
		#if sys
		if (FlxG.keys.anyPressed([CONTROL])) {
			openSubState(new options.GameplayChangersSubstate());
		}
		#end
	}

	/**
	 * Static function that runs in a thread to generate the challenge playlist
	 * This is wrapped by ASync to execute asynchronously
	 */
	static function generateChallengePlaylistAsync(songCount:Int):PlaylistMetadata
	{
		// Phase 1: Discover all songs
		generationPhase = GENERATING_DISCOVERING;
		generationProgress = 0;
		generationSongName = "";

		// Check if cancellation was requested
		if (cancellationRequested) {
			return new PlaylistMetadata('CHALLENGE RUN');
		}

		var songList = managers.SongDifficultyEvaluator.discoverAllSongs();

		if (songList.length == 0) {
			trace('[ChallengePlaylist] No songs found!');
			return new PlaylistMetadata('CHALLENGE RUN');
		}

		trace('[ChallengePlaylist] Found ${songList.length} total songs, selecting $songCount');

		// Phase 2: Get available difficulties for all songs
		generationPhase = GENERATING_DIFFICULTIES;
		generationProgress = 0;

		// Check if cancellation was requested
		if (cancellationRequested) {
			return new PlaylistMetadata('CHALLENGE RUN');
		}

		// Score all songs by their best/hardest available difficulty
		var scoredSongs:Array<{songName:String, week:Int, folder:String, score:Float, selectedDiff:String}> = [];

		for (songEntry in songList) {
			// Check if cancellation was requested
			if (cancellationRequested) {
				return new PlaylistMetadata('CHALLENGE RUN');
			}

			generationProgress++;
			generationSongName = songEntry.songName;

			// Get available difficulties for this song
			var availableDiffs = managers.SongDifficultyEvaluator.getAvailableDifficulties(songEntry.songName, songEntry.folder);

			if (availableDiffs.length == 0) {
				trace('  -> Skipping ${songEntry.songName}: no difficulties found');
				continue;
			}

			// Select best difficulty using weighted system
			var selectedDiff = managers.SongDifficultyEvaluator.selectChallengeDifficulty(
				songEntry.songName,
				availableDiffs,
				null,
				songEntry.folder
			);

			// Phase 3: Score songs
			generationPhase = GENERATING_SCORING;
			generationProgress = scoredSongs.length + 1;
			generationSongName = songEntry.songName;

			// Score the selected difficulty
			var score = managers.SongDifficultyEvaluator.calculateDifficultyFromChart(
				songEntry.songName,
				selectedDiff,
				null,
				songEntry.folder
			);

			scoredSongs.push({
				songName: songEntry.songName,
				week: songEntry.week,
				folder: songEntry.folder,
				score: score,
				selectedDiff: selectedDiff
			});
		}

		trace('[ChallengePlaylist] Scored ${scoredSongs.length} songs, selecting hardest...');

		if (scoredSongs.length == 0) {
			trace('[ChallengePlaylist] No playable songs found!');
			return new PlaylistMetadata('CHALLENGE RUN');
		}

		// Phase 4: Select songs
		generationPhase = GENERATING_SELECTING;
		generationProgress = 0;
		generationSongName = "";

		// Check if cancellation was requested
		if (cancellationRequested) {
			return new PlaylistMetadata('CHALLENGE RUN');
		}

		// Sort by difficulty (hardest first)
		scoredSongs.sort((a, b) -> b.score - a.score > 0 ? 1 : -1);

		// Select hardest songs with some variation (top 35%)
		var selectedCountPercent:Int = Std.int(Math.ceil(scoredSongs.length * 0.35));
		var selectedCount:Int = Std.int(Math.min(songCount, selectedCountPercent));

		var selectedSongs:Array<{songName:String, difficulty:String, folder:String}> = [];

		// Select from top tier with some randomization
		for (i in 0...selectedCount) {
			if (i < scoredSongs.length) {
				// Add some variance: prefer top tier but allow picking from next tier down
				var tierSize:Int = Std.int(Math.max(1, Math.ceil(scoredSongs.length * 0.2)));
				var songIndex:Int = Std.int(Math.floor(i / tierSize) * tierSize) + FlxG.random.int(0, tierSize - 1);
				songIndex = Std.int(Math.min(songIndex, scoredSongs.length - 1));

				var selectedSong = scoredSongs[songIndex];

				selectedSongs.push({
					songName: selectedSong.songName,
					difficulty: selectedSong.selectedDiff,
					folder: selectedSong.folder
				});
			}
		}

		// Shuffle the selected songs
		FlxG.random.shuffle(selectedSongs);

		// Create the challenge playlist
		var challengePlaylist = new PlaylistMetadata('CHALLENGE RUN');
		for (entry in selectedSongs) {
			var playlistSong = new PlaylistSongMetadata(entry.songName, 0, "", [], entry.difficulty);
			playlistSong.folder = entry.folder;
			challengePlaylist.songList.push(playlistSong);
		}

		trace('[ChallengePlaylist] Generated playlist with ${challengePlaylist.songList.length} songs');

		return challengePlaylist;
	}

	override function destroy():Void
	{
		// Clean up async operation if still pending
		if (generatorResult != null && generatorResult.isPending) {
			generatorResult = null;
		}

		super.destroy();
	}
}
