package managers;

import archipelago.substates.InfoPanelSubstate;
import archipelago.substates.NumberInputSubstate;
import backend.Mods;
import backend.Paths;
import backend.Song;
import backend.WeekData;
import flixel.FlxG;
import flixel.util.FlxColor;
import states.LoadingState;
import states.PlayState;
import states.PlaylistState.PlaylistMetadata;
import states.PlaylistState.PlaylistSongMetadata;
import yutautil.DualProgressSubstate;
import yutautil.GenericProgressSubstate.ProgressTask;
import yutautil.GenericProgressSubstate;

/**
 * ChallengePlaylistGenerator
 *
 * Simple utility class for generating challenge playlists with async progress tracking.
 * Uses NumberInputSubstate for input and DualProgressSubstate for generation progress.
 * Iter tasks are used for scoring phase to provide dynamic progress updates.
 */
class ChallengePlaylistGenerator {
	private var parentState:backend.MusicBeatState;
	private var onGenerationComplete:(PlaylistMetadata)->Bool;
	private var onGenerationCancelled:Void->Void;
	public var forceQuiet:Bool = false;

	public function new(parentState:backend.MusicBeatState, ?onComplete:(PlaylistMetadata)->Bool, ?onCancel:Void->Void) {
		this.parentState = parentState;
		this.onGenerationComplete = onComplete != null ? onComplete : function(playlist:PlaylistMetadata) { return false; };
		this.onGenerationCancelled = onCancel != null ? onCancel : function() {};
	}

	/**
	 * Start the generation process with pre-generation checks in a progress substate
	 * @param forcedSongCount Optional: if provided, skips the number input and uses this count
	 * @param quiet Optional: if true, runs synchronously without UI and doesn't use callbacks
	 * @return In quiet mode, returns the generated playlist; otherwise returns null
	 */
	public function start(?forcedSongCount:Null<Int>, ?quiet:Bool = false):PlaylistMetadata {
		var isQuiet = quiet || forceQuiet;

		// If quiet mode, execute synchronously without any substates
		if (isQuiet) {
			return startQuietly(forcedSongCount);
		}

		// Non-quiet mode: show progress substates as before
		var preCheckTasks:Array<ProgressTask> = [];

		// Task 1: Update mod list if needed, then reload weeks
		preCheckTasks.push(Func({
			name: "Updating Mods & Weeks",
			func: function(results:Array<Dynamic>):Dynamic {
				trace('[ChallengePlaylist] Checking if mods need update...');

				if (!Mods.updatedOnState) {
					trace('[ChallengePlaylist] Mods not updated on state, updating mod list...');
					Mods.parseList();
				} else {
					trace('[ChallengePlaylist] Mods already updated on state');
				}

				trace('[ChallengePlaylist] Reloading week files...');
				WeekData.reloadWeekFiles();

				return true;
		}
		}));

		// Task 2: Discover all songs
		preCheckTasks.push(Func({
			name: "Discovering Songs",
			func: function(results:Array<Dynamic>):Dynamic {
				trace('[ChallengePlaylist] Discovering available songs...');
				var allSongs = managers.SongDifficultyEvaluator.discoverAllSongs();
				trace('[ChallengePlaylist] Found ${allSongs.length} songs');
				return allSongs;
		}
		}));

		// Show pre-check progress substate
		var preCheckSubstate = new yutautil.GenericProgressSubstate(
			"Preparing Challenge Generator",
			preCheckTasks,
			function(results:Array<Dynamic>) {
				// On completion, check if songs were found
				if (results.length >= 2) {
					var allSongs:Dynamic = results[1];
					var maxSongs:Int = (allSongs : Array<Dynamic>).length;

					if (maxSongs == 0) {
						InfoPanelSubstate.show("No Songs Available", "Could not find any songs to generate a playlist from.\n\nMake sure you have songs configured.", FlxColor.RED);
						return;
					}

					// If song count was forced, start generation directly
					if (forcedSongCount != null) {
						var songCount = Std.int(Math.min(forcedSongCount, maxSongs));
						trace('[ChallengePlaylist] Using forced song count: $songCount');
						startGeneration(songCount, false);
						return;
					}

					// Otherwise, show number input substate for song count
					var numberInput = new NumberInputSubstate(
						"Songs in Challenge",
						10,
						1,
						maxSongs,
						function(songCount:Float) {
							startGeneration(Std.int(songCount), false);
						},
						function() {
							onGenerationCancelled();
						},
						1,
						false,
						"Select how many songs to include in the challenge playlist",
						FlxColor.CYAN,
						true
					);

					parentState.openSubState(numberInput);
				}
			},
			function(error:String, shouldThrow:Bool) {
				trace('Pre-check error: $error');
				InfoPanelSubstate.show("Preparation Error", 'Failed to prepare playlist generator:\n\n$error', FlxColor.RED);
			},
			function() {
				onGenerationCancelled();
			},
			true // Enable cancel button
		);

		parentState.openSubState(preCheckSubstate);
		return null;
	}

	/**
	 * Execute generation synchronously in quiet mode without any UI or callbacks
	 * @param forcedSongCount Optional song count
	 * @return The generated PlaylistMetadata
	 */
	private function startQuietly(?forcedSongCount:Null<Int>):PlaylistMetadata {
		trace('[ChallengePlaylist] Starting quiet synchronous generation...');

		// Pre-checks
		if (!Mods.updatedOnState) {
			Mods.parseList();
		}
		WeekData.reloadWeekFiles();

		// Discover songs
		var allSongs = managers.SongDifficultyEvaluator.discoverAllSongs();
		var maxSongs:Int = allSongs.length;

		if (maxSongs == 0) {
			trace('[ChallengePlaylist] No songs available in quiet mode');
			return null;
		}

		// Use forced song count or default
		var songCount = forcedSongCount != null ? Std.int(Math.min(forcedSongCount, maxSongs)) : 10;

		// Process songs and their difficulties
		var songsWithDiffs:Array<Dynamic> = [];
		for (songEntry in allSongs) {
			var entry:Dynamic = songEntry;
			var availableDiffs = managers.SongDifficultyEvaluator.getAvailableDifficulties(entry.songName, entry.folder);

			if (availableDiffs.length > 0) {
				songsWithDiffs.push({
					songName: entry.songName,
					week: entry.week,
					folder: entry.folder,
					availableDiffs: availableDiffs
				});
			}
		}

		// Score all songs
		var scoredSongs:Array<Dynamic> = [];
		for (data in songsWithDiffs) {
			var selectedDiff = managers.SongDifficultyEvaluator.selectChallengeDifficulty(
				data.songName,
				data.availableDiffs,
				null,
				data.folder
			);

			var score = managers.SongDifficultyEvaluator.calculateDifficultyFromChart(
				data.songName,
				selectedDiff,
				null,
				data.folder
			);

			scoredSongs.push({
				songName: data.songName,
				week: data.week,
				folder: data.folder,
				score: score,
				selectedDiff: selectedDiff
			});
		}

		// Sort by difficulty (hardest first)
		scoredSongs.sort((a, b) -> {
			var scoreA:Float = (cast a : Dynamic).score;
			var scoreB:Float = (cast b : Dynamic).score;
			return scoreB > scoreA ? 1 : -1;
		});

		// Select hardest songs with some variation (top 35%)
		var selectedCountPercent:Int = Std.int(Math.ceil(scoredSongs.length * 0.35));
		var selectedCount:Int = Std.int(Math.min(songCount, selectedCountPercent));

		var selectedSongs:Array<Dynamic> = [];

		// Select from top tier with some randomization
		for (i in 0...selectedCount) {
			if (i < scoredSongs.length) {
				var tierSize:Int = Std.int(Math.max(1, Math.ceil(scoredSongs.length * 0.2)));
				var songIndex:Int = Std.int(Math.floor(i / tierSize) * tierSize) + FlxG.random.int(0, tierSize - 1);
				songIndex = Std.int(Math.min(songIndex, scoredSongs.length - 1));

				selectedSongs.push(scoredSongs[songIndex]);
			}
		}

		// Shuffle the selected songs
		for (i in 0...selectedSongs.length) {
			var j = FlxG.random.int(i, selectedSongs.length - 1);
			var temp = selectedSongs[i];
			selectedSongs[i] = selectedSongs[j];
			selectedSongs[j] = temp;
		}

		// Create the playlist
		var challengePlaylist = new PlaylistMetadata('CHALLENGE RUN');

		for (entry in selectedSongs) {
			var songData:Dynamic = entry;
			var playlistSong = new PlaylistSongMetadata(songData.songName, 0, "", [], songData.selectedDiff);
			playlistSong.folder = songData.folder;
			challengePlaylist.songList.push(playlistSong);
		}

		trace('[ChallengePlaylist] Quiet generation complete! Generated playlist with ${challengePlaylist.songList.length} songs');
		return challengePlaylist;
	}

	/**
	 * Internal: Start the actual generation process
	 */
	private function startGeneration(songCount:Int, ?quiet:Bool = false) {
		var isQuiet = quiet || forceQuiet;
		var songsWithDiffs:Array<Dynamic> = [];

		// Build task list
		var tasks:Array<ProgressTask> = [];

		// Phase 1: Discover songs and get their difficulties
		tasks.push(Func({
			name: "Discovering and Processing Songs",
			func: function(results:Array<Dynamic>):Dynamic {
				var allSongs = managers.SongDifficultyEvaluator.discoverAllSongs();
				trace('[ChallengePlaylist] Found ${allSongs.length} songs, processing difficulties');

				// Process each song to get available difficulties
				for (songEntry in allSongs) {
					var entry:Dynamic = songEntry;
					var availableDiffs = managers.SongDifficultyEvaluator.getAvailableDifficulties(entry.songName, entry.folder);

					if (availableDiffs.length > 0) {
						songsWithDiffs.push({
							songName: entry.songName,
							week: entry.week,
							folder: entry.folder,
							availableDiffs: availableDiffs
						});
					}
				}

				trace('[ChallengePlaylist] Processed ${songsWithDiffs.length} songs with available difficulties');
				return songsWithDiffs;
			}
		}));

		// Phase 2: Score all songs (using Iter task for dynamic progress bar)
		tasks.push(Iter({
			name: "Scoring Songs",
			iterable: [],
			func: function(diffData:Dynamic):Dynamic {
				var data:Dynamic = diffData;

				// Select best difficulty
				var selectedDiff = managers.SongDifficultyEvaluator.selectChallengeDifficulty(
					data.songName,
					data.availableDiffs,
					null,
					data.folder
				);

				// Score it
				var score = managers.SongDifficultyEvaluator.calculateDifficultyFromChart(
					data.songName,
					selectedDiff,
					null,
					data.folder
				);

				return {
					songName: data.songName,
					week: data.week,
					folder: data.folder,
					score: score,
					selectedDiff: selectedDiff
				};
			}
		}));

		// Phase 3: Select hardest songs
		tasks.push(Func({
			name: "Selecting Hardest Songs",
			func: function(results:Array<Dynamic>):Dynamic {
				// Get the scored songs from the previous iter result
				var scoredSongs:Array<Dynamic> = [];

				if (results.length >= 2) {
					var scoreResults:Dynamic = results[1];
					var scoreResultsArray:Array<Dynamic> = scoreResults;
					for (result in scoreResultsArray) {
						if (result != null) {
							scoredSongs.push(result);
						}
					}
				}

				if (scoredSongs.length == 0) {
					trace('[ChallengePlaylist] No playable songs found!');
					return [];
				}

				trace('[ChallengePlaylist] Scored ${scoredSongs.length} songs');

				// Sort by difficulty (hardest first)
				scoredSongs.sort((a, b) -> {
					var scoreA:Float = (cast a : Dynamic).score;
					var scoreB:Float = (cast b : Dynamic).score;
					return scoreB > scoreA ? 1 : -1;
				});

				// Select hardest songs with some variation (top 35%)
				var selectedCountPercent:Int = Std.int(Math.ceil(scoredSongs.length * 0.35));
				var selectedCount:Int = Std.int(Math.min(songCount, selectedCountPercent));

				var selectedSongs:Array<Dynamic> = [];

				// Select from top tier with some randomization
				for (i in 0...selectedCount) {
					if (i < scoredSongs.length) {
						// Add some variance: prefer top tier but allow picking from next tier down
						var tierSize:Int = Std.int(Math.max(1, Math.ceil(scoredSongs.length * 0.2)));
						var songIndex:Int = Std.int(Math.floor(i / tierSize) * tierSize) + FlxG.random.int(0, tierSize - 1);
						songIndex = Std.int(Math.min(songIndex, scoredSongs.length - 1));

						selectedSongs.push(scoredSongs[songIndex]);
					}
				}

				// Shuffle the selected songs
				for (i in 0...selectedSongs.length) {
					var j = FlxG.random.int(i, selectedSongs.length - 1);
					var temp = selectedSongs[i];
					selectedSongs[i] = selectedSongs[j];
					selectedSongs[j] = temp;
				}

				return selectedSongs;
			}
		}));

		// Create instance of the progress substate wrapper
		var substate = new ChallengePlaylistProgressSubstate(
			{
				title: "Generating Challenge Playlist",
				tasks: tasks,
				onComplete: function(results:Array<Dynamic>) {
					handleGenerationComplete(results, songCount);
				},
				onError: function(error:String, shouldThrow:Bool) {
					trace('Generation error: $error');
					if (!isQuiet) {
						InfoPanelSubstate.show("Generation Error", 'Failed to generate playlist:\n\n$error', FlxColor.RED);
					}
				},
				onCancel: function() {
					onGenerationCancelled();
				}
			},
			songsWithDiffs
		);

		// Always show the progress substate (quiet mode is handled at a higher level)
		parentState.openSubState(substate);
	}

	/**
	 * Internal: Handle generation completion (only called in non-quiet mode)
	 */
	private function handleGenerationComplete(results:Array<Dynamic>, songCount:Int) {
		// Extract selected songs from results
		var selectedSongs:Array<Dynamic> = [];

		if (results.length >= 3) {
			var selectedResult:Dynamic = results[2];
			selectedSongs = selectedResult;
		}

		if (selectedSongs.length == 0) {
			InfoPanelSubstate.show("No Songs Selected", "Could not generate a valid challenge playlist. Try fewer songs or check your song configuration.", FlxColor.RED);
			return;
		}

		// Create the challenge playlist
		var challengePlaylist = new PlaylistMetadata('CHALLENGE RUN');

		for (entry in selectedSongs) {
			var songData:Dynamic = entry;
			var playlistSong = new PlaylistSongMetadata(songData.songName, 0, "", [], songData.selectedDiff);
			playlistSong.folder = songData.folder;
			challengePlaylist.songList.push(playlistSong);
		}

		trace('[ChallengePlaylist] Generated playlist with ${challengePlaylist.songList.length} songs');

		// Show preview with the song list
		var songListStr = "";
		for (i in 0...challengePlaylist.songList.length) {
			var song = challengePlaylist.songList[i];
			songListStr += (i + 1) + ". " + song.songName + " [" + song.difficulty + "]\n";
		}

		InfoPanelSubstate.show("Challenge Playlist Ready", "Your challenge playlist has been generated!\n\n" + songListStr, FlxColor.CYAN, function() {
			// Call completion callback - if it returns true, launch the playlist
			var shouldLaunch = onGenerationComplete(challengePlaylist);
			if (shouldLaunch) {
				launchPlaylist(challengePlaylist);
			}
		});
	}

	/**
	 * Async version that generates and returns a playlist directly via AResult
	 * @param forcedSongCount Optional: if provided, uses this song count
	 * @return AResult<PlaylistMetadata>
	 */
	public function startAsync(?forcedSongCount:Null<Int>):AResult<PlaylistMetadata> {
		// Execute quietly and return result directly as an AResult (no callbacks used)
		var playlist:ASyncF<PlaylistMetadata> = startQuietly;
		return cast playlist(forcedSongCount);
	}

	/**
	 * Internal: Launch the generated playlist
	 */
	private function launchPlaylist(playlist:PlaylistMetadata) {
		if (playlist.songList.length > 0) {
			PlayState.isPlaylist = true;
			var firstSong = playlist.songList[0];
			var songLowercase:String = Paths.formatToSongPath(firstSong.songName);
			Mods.currentModDirectory = firstSong.folder != null ? firstSong.folder : '';
			PlayState.storyWeek = firstSong.week;
			backend.Song.loadFromJson('${songLowercase}${(firstSong.difficulty.toLowerCase() != "normal" ? "-" + firstSong.difficulty.toLowerCase() : "")}', songLowercase);
			LoadingState.prepareToSong();
			LoadingState.loadAndSwitchState(new PlayState(playlist));
		}
	}
}

/**
 * ChallengePlaylistProgressSubstate
 * Extended DualProgressSubstate that handles special case of populating
 * the Iter task's iterable after discovery completes.
 */
class ChallengePlaylistProgressSubstate extends DualProgressSubstate {
	var songsWithDiffs:Array<Dynamic>;

	public function new(config:Dynamic, songsWithDiffs:Array<Dynamic>) {
		this.songsWithDiffs = songsWithDiffs;
		super(config);
	}

	override function executeNextTask() {
		// Special handling: when scoring task is about to run (step 1), populate its iterable
		if (currentStep == 1 && songsWithDiffs.length > 0 && taskFunctions.length > 1) {
			var task = taskFunctions[1];
			switch (task) {
				case Iter(iterTask):
					iterTask.iterable = songsWithDiffs;
					trace('[ChallengePlaylist] Populated scoring tasks with ${songsWithDiffs.length} songs');
				default:
			}
		}

		super.executeNextTask();
	}
}



