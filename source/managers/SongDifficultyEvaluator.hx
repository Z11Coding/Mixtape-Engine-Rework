package managers;

import backend.ModContext;
import backend.Mods;
import backend.Paths;
import backend.Song;
import backend.WeekData;
import flixel.FlxG;
import flixel.math.FlxMath;

/**
 * Evaluates song difficulty based on comprehensive chart analysis.
 * Considers note density, spacing, patterns, scroll speed, and timing variations.
 * Uses WeekData structure to discover songs and their associated difficulties.
 * Uses the Song class to properly load and validate charts.
 * Used by the challenge playlist generator to score and rank songs.
 */
class SongDifficultyEvaluator
{
	/**
	 * Gets all discoverable songs from WeekData along with their metadata and mods.
	 * Much simpler than filesystem scanning - leverages existing WeekData structure.
	 *
	 * @return Array of song entries with names, weeks, and mod folders
	 */
	public static function discoverAllSongs():Array<{songName:String, week:Int, folder:String}>
	{
		var songs:Array<{songName:String, week:Int, folder:String}> = [];
		var seen:Map<String, Bool> = new Map();

		for (weekIdx in 0...WeekData.weeksList.length) {
			var weekName = WeekData.weeksList[weekIdx];
			var week = WeekData.weeksLoaded.get(weekName);
			if (week == null || week.songs == null) continue;

			for (songData in week.songs) {
				var songName:String = cast songData[0];
				var key = (week.folder != null ? week.folder : '') + '::${songName.toLowerCase()}';

				if (!seen.exists(key)) {
					seen.set(key, true);
					songs.push({
						songName: songName,
						week: weekIdx,
						folder: week.folder != null ? week.folder : ''
					});
				}
			}
		}

		trace('[SongDiscovery] Found ${songs.length} songs from WeekData');
		return songs;
	}

	/**
	 * Gets available difficulties for a song by checking WeekData and validating charts can be loaded.
	 * Validates by attempting to load with Song.loadFromJson().
	 *
	 * @param songName Song to find difficulties for
	 * @param modFolder Optional mod folder to search in (if song belongs to a mod)
	 * @return Array of available difficulty names
	 */
	public static function getAvailableDifficulties(songName:String, ?modFolder:String):Array<String>
	{
		var difficulties:Array<String> = [];
		var seen:Map<String, Bool> = new Map();

		// Search through WeekData for weeks containing this song
		for (weekIdx in 0...WeekData.weeksList.length) {
			var weekName = WeekData.weeksList[weekIdx];
			var week = WeekData.weeksLoaded.get(weekName);
			if (week == null || week.songs == null) continue;

			// Check if this week belongs to the specified mod
			var weekFolder = week.folder != null ? week.folder : '';
			if (modFolder != null && modFolder != '' && weekFolder != modFolder) continue;

			// Check if this week contains the song
			var hasSong = false;
			for (songData in week.songs) {
				var wSongName:String = cast songData[0];
				if (wSongName.toLowerCase() == songName.toLowerCase()) {
					hasSong = true;
					break;
				}
			}

			if (!hasSong) continue;

			// Get difficulties from week definition
			if (week.difficulties != null && week.difficulties.length > 0) {
				var diffs = week.difficulties.split(',');
				for (diff in diffs) {
					var trimmedDiff = diff.trim();
					if (trimmedDiff.length > 0) {
						var lowerDiff = trimmedDiff.toLowerCase();

						// Validate that the chart can be loaded
						if (!seen.exists(lowerDiff)) {
							var folderToUse = modFolder != null && modFolder != '' ? modFolder : weekFolder;
							var chart = loadChartForValidation(songName, trimmedDiff, folderToUse);
							if (chart != null) {
								seen.set(lowerDiff, true);
								difficulties.push(trimmedDiff);
							}
						}
					}
				}
			}
		}

		// Fallback to common difficulties if none found
		if (difficulties.length == 0) {
			for (defaultDiff in ['easy', 'normal', 'hard']) {
				var chart = loadChartForValidation(songName, defaultDiff, modFolder != null ? modFolder : '');
				if (chart != null) {
					difficulties.push(defaultDiff);
				}
			}
		}

		// If still nothing, return empty array - song has no valid difficulties
		return difficulties;
	}

	/**
	 * Attempts to load a chart using ModContext, which is completely thread-safe.
	 * Never changes the global currentModDirectory.
	 *
	 * @param songName Song name
	 * @param difficulty Difficulty name
	 * @param modFolder Mod folder if applicable
	 * @return Loaded SwagSong object or null if chart doesn't exist/is invalid
	 */
	private static function loadChartForValidation(songName:String, difficulty:String, modFolder:String):Null<SwagSong>
	{
		try {
			var songPath = Paths.formatToSongPath(songName);
			var difficultyStr = difficulty.toLowerCase();
			var chartName = difficultyStr != 'normal' ? '${songPath}-${difficultyStr}' : songPath;

			// Use ModContext for thread-safe song loading without changing global state
			var modContext = new backend.ModContext(modFolder != null ? modFolder : '');
			return modContext.loadSongChart(chartName, songPath);
		}
		catch (e:Dynamic) {
			return null;
		}
	}

	/**
	 * Calculates a comprehensive difficulty score for a song using actual chart data.
	 * Analyzes note patterns, spacing, scroll speed, BPM changes, and timing complexity.
	 * Thread-safe - uses ModContext without changing the global currentModDirectory.
	 *
	 * @param songName The name of the song to evaluate
	 * @param difficulty The difficulty to analyze (e.g., "hard", "nightmare")
	 * @param songMeta Metadata with rating info from FreeplayManager
	 * @param modFolder Optional mod folder for file lookup
	 * @return Calculated difficulty score (higher = harder)
	 */
	public static function calculateDifficultyFromChart(songName:String, difficulty:String, ?songMeta:managers.FreeplayManager.GlobalSongMetadata, ?modFolder:String):Float
	{
		var score:Float = 0.0;

		try {
			// Use ModContext for thread-safe song loading without changing global state
			var modContext = new backend.ModContext(modFolder != null ? modFolder : '');
			var songPath = Paths.formatToSongPath(songName);
			var difficultyName = difficulty.toLowerCase();
			var chartName = difficultyName != 'normal' ? '${songPath}-${difficultyName}' : songPath;

			var loadedChart = modContext.loadSongChart(chartName, songPath);

			if (loadedChart != null && loadedChart.notes != null && loadedChart.notes.length > 0) {
			var bpm = loadedChart.bpm > 0 ? loadedChart.bpm : 120.0;
				score = analyzeChartDifficulty(loadedChart.notes, bpm, difficultyName);
			} else {
				// Fallback to quick scoring if chart is empty or invalid
				score = quickDifficultyScore(difficultyName);
			}
		}
		catch (e:Dynamic) {
			trace('Error analyzing chart for $songName: $e');
			score = quickDifficultyScore(difficulty);
		}

		// Use metadata rating as a baseline if available and score is low
		if (songMeta != null && score < 30.0) {
			try {
				var metadata = managers.FreeplayManager.getMixtapeMetadata(songName);
				if (metadata != null && metadata.freeplay.ratings != null) {
					var rating = metadata.freeplay.ratings.get(difficulty.toLowerCase());
					if (rating != null && rating > 0) {
						var metadataScore = rating * 15.0;
						score = Math.max(score, metadataScore);
					}
				}
			} catch (e:Dynamic) {}
		}

		return Math.max(score, 10.0); // Minimum score of 10
	}
	public static var debug:Bool = false;

	/**
	 * Analyzes a chart's difficulty through multiple factors:
	 * - Note density (overall notes per measure)
	 * - Note spacing distribution (how close together notes are)
	 * - Scroll speed impacts
	 * - BPM variation and complexity
	 * - Quantization levels (identifies dense streams)
	 * - Hand work intensity (jumps, chords, one-hand patterns)
	 * - Stream velocity and consistency
	 */
	private static function analyzeChartDifficulty(notesArray:Array<Dynamic>, baseBpm:Float, difficulty:String):Float
	{
		var score:Float = 0.0;
		var sections:Int = 0;
		var totalNotes:Int = 0;
		var maxNotesInSection:Int = 0;
		var denseSections:Int = 0;
		var bpmChanges:Int = 0;
		var jumpCount:Int = 0;
		var chordCount:Int = 0;
		var maxNotesPerBeat:Int = 0;
		var handWorkIntensity:Float = 0.0;

		// Analysis per section
		for (section in notesArray) {
			if (section == null) continue;
			sections++;

			var sectionNotes:Array<Dynamic> = section.sectionNotes;

			if (sectionNotes != null) {
				var notesInSection = sectionNotes.length;
				totalNotes += notesInSection;
				maxNotesInSection = Std.int(Math.max(maxNotesInSection, notesInSection));

				// Dense sections (lots of notes)
				if (notesInSection > 15) {
					denseSections++;
				}

				// Analyze note spacing and patterns
				var lastNoteTime:Float = -1000;
				var minSpacing:Float = 999999;
				var spacingVariance:Float = 0.0;
				var spacings:Array<Float> = [];

				for (i in 0...sectionNotes.length) {
					var note = sectionNotes[i];
					if (note != null) {
						var noteTime:Float = note[0];

						if (lastNoteTime >= 0) {
							var gap = noteTime - lastNoteTime;
							minSpacing = Math.min(minSpacing, gap);
							spacings.push(gap);
						}
						lastNoteTime = noteTime;

						// Count jumps (2+ notes at same time) and chords
						var noteCount:Int = 0;
						for (j in 1...note.length) {
							if (Std.isOfType(note[j], Int)) {
								noteCount++;
							}
						}

						if (noteCount >= 2) {
							if (noteCount == 2) jumpCount++;
							else if (noteCount >= 3) chordCount++;
							handWorkIntensity += noteCount * 0.5;
						}
					}
				}

				// Calculate spacing variance (tighter spacing = harder)
				if (spacings.length > 0) {
					var sum:Float = 0.0;
					for (spacing in spacings) {
						sum += spacing;
					}
					var avgSpacing = sum / spacings.length;

					for (spacing in spacings) {
						spacingVariance += Math.abs(spacing - avgSpacing);
					}
					spacingVariance /= Math.max(1, spacings.length);

					// Penalize tight spacing
					if (minSpacing < 100) {
						score += 15.0; // Very tight streams
					} else if (minSpacing < 150) {
						score += 10.0; // Tight streams
					} else if (minSpacing < 200) {
						score += 5.0; // Medium spacing
					}

					// Penalize inconsistent spacing (requires adaptation)
					score += Math.min(spacingVariance / 50.0, 10.0);
				}

				// Check quantization complexity
				maxNotesPerBeat = Std.int(Math.max(maxNotesPerBeat, notesInSection));
			}

			// BPM changes
			if (section.changeBPM != null && section.changeBPM == true) {
				bpmChanges++;
			}
		}

		// Calculate overall metrics
		var noteDensity:Float = sections > 0 ? totalNotes / sections : 0;

		// 1. Note Density Score (0-30 points)
		if (noteDensity > 30) {
			score += Math.min(noteDensity - 30, 30.0); // High density
		} else if (noteDensity > 15) {
			score += (noteDensity - 15) * 0.5;
		}

		// 2. Pattern Complexity (0-20 points)
		// Max notes in a section indicates streaming density
		if (maxNotesInSection > 40) {
			score += 20.0; // Extreme streams
		} else if (maxNotesInSection > 25) {
			score += 15.0; // Heavy streams
		} else if (maxNotesInSection > 15) {
			score += 10.0; // Moderate streams
		}

		// 3. Dense Section Penalty (0-15 points)
		var denseSectionPenalty = Math.min(denseSections * 2.0, 15.0);
		score += denseSectionPenalty;

		// 4. Hand Work (0-20 points)
		var handWorkScore = Math.min((jumpCount * 2 + chordCount * 3 + handWorkIntensity) / 10, 20.0);
		score += handWorkScore;

		// 5. BPM Variation (0-10 points)
		var tempoBonus = Math.min(bpmChanges * 3.0, 10.0);
		score += tempoBonus;

		// 6. Quantization Bonus (0-15 points)
		// More 16th/32nd notes = harder
		var quantBonus = Math.min(maxNotesPerBeat * 3.0, 15.0);
		score += quantBonus;

		// 7. Consistency Check - if lots of notes but low density variance, it's a stream chart
		if (denseSections > sections * 0.5 && totalNotes > 100) {
			score += 5.0; // Sustained challenging content
		}

		if (debug) {
		trace('Chart Analysis for difficulty "$difficulty": Notes=$totalNotes, Sections=$sections, AvgDensity=$noteDensity, Density%=${denseSections}/${sections}, Jumps=$jumpCount, Chords=$chordCount, BPMChanges=$bpmChanges, Score=$score');
		}
		return score;
	}

	/**
	 * Quick difficulty score based on difficulty name.
	 * Used as fallback when chart data isn't available.
	 *
	 * @param difficulty Difficulty string ("easy", "hard", etc.)
	 * @return Difficulty score
	 */
	public static function quickDifficultyScore(difficulty:String):Float
	{
		var diffMap = [
			"easy" => 20.0,
			"normal" => 40.0,
			"hard" => 60.0,
			"harder" => 75.0,
			"insane" => 90.0,
			"nightmare" => 110.0,
			"erect" => 120.0
		];

		var lower = difficulty.toLowerCase();
		if (diffMap.exists(lower)) {
			return diffMap.get(lower);
		}

		return 50.0; // Default fallback
	}

	/**
	 * Selects the best difficulty for a challenge playlist using a weighted system.
	 * Evaluates all available difficulties and weights selection by chart hardness,
	 * but still allows lower difficulties to be picked (weighted toward harder).
	 *
	 * @param songName The song to evaluate
	 * @param availableDifficulties Array of available difficulty strings
	 * @param songMeta Optional metadata
	 * @param modFolder Optional mod folder for file lookup
	 * @return Selected difficulty string (weighted toward harder charts)
	 */
	public static function selectChallengeDifficulty(songName:String, availableDifficulties:Array<String>, ?songMeta:managers.FreeplayManager.GlobalSongMetadata, ?modFolder:String):String
	{
		if (availableDifficulties.length == 0)
			return "normal";

		if (availableDifficulties.length == 1)
			return availableDifficulties[0];

		// Score each available difficulty based on its actual chart content
		var difficultyScores:Array<{difficulty:String, score:Float, weight:Float}> = [];
		var maxScore:Float = 0.0;

		for (difficulty in availableDifficulties) {
			var score = calculateDifficultyFromChart(songName, difficulty, songMeta, modFolder);
			difficultyScores.push({difficulty: difficulty, score: score, weight: 0.0});
			if (score > maxScore) {
				maxScore = score;
			}
		}

		// Normalize scores to 0-1 range and create weights
		for (entry in difficultyScores) {
			var normalizedScore = (entry.score / Math.max(maxScore, 1.0));
			// Quadratic weighting heavily favors harder charts but still allows others
			entry.weight = normalizedScore * normalizedScore;
		}

		// Weighted random selection
		var totalWeight:Float = 0.0;
		for (entry in difficultyScores) {
			totalWeight += entry.weight;
		}

		// If all weights are 0, just return a random difficulty
		if (totalWeight <= 0) {
			return availableDifficulties[FlxG.random.int(0, availableDifficulties.length - 1)];
		}

		// Select based on weights
		var random:Float = FlxG.random.float(0, totalWeight);
		var currentWeight:Float = 0.0;

		for (entry in difficultyScores) {
			currentWeight += entry.weight;
			if (random >= currentWeight - entry.weight && random < currentWeight) {
				return entry.difficulty;
			}
		}

		// Fallback
		return difficultyScores[difficultyScores.length - 1].difficulty;
	}
}
