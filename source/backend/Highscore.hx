package backend;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songMisses:Map<String, Int> = new Map<String, Int>();
	public static var songRanks:Map<String, Int> = new Map<String, Int>();
	public static var songDeaths:Map<String, Int> = new Map<String, Int>();
	public static var endlessScores:Map<String, Int> = new Map<String, Int>();

	public static var saveMod:String = "";
	// Gameplay settings
	var mixupMode:Bool = false;
	var gimmicksAllowed:Bool = false;

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1, ?misses:Int = 0, ?deaths:Int = 0):Void
	{
		if(song == null) return;
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (songScores.exists(songMod))
		{
			if (songScores.get(songMod) < score)
			{
				setScore(songMod, score);
			}
		}
		else
		{
			setScore(songMod, score);
		}

		if (songRating.exists(songMod)) {
			if (songRating.get(songMod) < rating) {
				setRating(songMod, rating);
			}
		}
		else {
			if(rating >= 0) setRating(songMod, rating);
		}

		if (songMisses.exists(songMod)) {
			if (songMisses.get(songMod) > misses) {
				setMisses(songMod, misses);
			}
		}
		else {
			if(misses >= 0) setMisses(songMod, misses);
		}

		if (songDeaths.exists(songMod)) {
			if (songDeaths.get(songMod) > deaths) {
				setDeaths(songMod, deaths);
			}
		}
		else {
			if(deaths >= 0) setDeaths(songMod, deaths);
		}
	}

	public static function saveRank(song:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (songRanks.exists(songMod))
		{
			if (songRanks.get(songMod) > score)
				setRank(songMod, score);
		}
		else
			setRank(songMod, score);
	}

	public static function saveDeaths(song:String, deaths:Int = 0, ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (songDeaths.exists(songMod))
		{
			if (songDeaths.get(songMod) > deaths)
				setDeaths(songMod, deaths);
		}
		else
			setDeaths(songMod, deaths);
	}

	public static function saveEndlessScore(song:String, score:Int = 0):Void
	{
		var daSong:String = song;
		var songMod:String = daSong+saveMod;
		if (endlessScores.exists(songMod))
		{
			if (endlessScores.get(songMod) < score)
				setEndless(songMod, score);
		}
		else
			setEndless(songMod, score);
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		var weekMod:String = daWeek+saveMod;
		if (weekScores.exists(weekMod))
		{
			if (weekScores.get(weekMod) < score)
				setWeekScore(weekMod, score);
		}
		else setWeekScore(weekMod, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setRank(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRanks.set(song, score);
		FlxG.save.data.songRanks = songRanks;	
		FlxG.save.flush();
	}

	static function setDeaths(song:String, deaths:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		var deathCounter:Int = songDeaths.get(song) + deaths;

		songDeaths.set(song, deathCounter);
		FlxG.save.data.songDeaths = songDeaths;
		FlxG.save.flush();
	}

	static function setEndless(song:String, score:Int):Void
	{
		endlessScores.set(song, score);
		FlxG.save.data.endlessScores = endlessScores;
		FlxG.save.flush();
	}

	static function setMisses(song:String, misses:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songMisses.set(song, misses);
		FlxG.save.data.songMisses = songMisses;
		FlxG.save.flush();
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	public static function getRank(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (!songRanks.exists(songMod))
			setRank(songMod, 16);

		return songRanks.get(songMod);
	}

	public static function getDeaths(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (!songDeaths.exists(songMod))
			setDeaths(songMod, 0);

		return songDeaths.get(songMod);
	}

	public static function getMisses(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (!songMisses.exists(songMod))
			setMisses(songMod, 0);	
	
		return songMisses.get(songMod);
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (!songScores.exists(songMod))
			setScore(songMod, 0);

		return songScores.get(songMod);
	}

	public static function getRating(song:String, diff:Int):Float
	{
		var daSong:String = formatSong(song, diff);
		var songMod:String = daSong+saveMod;
		if (!songRating.exists(songMod))
			setRating(songMod, 0);

		return songRating.get(songMod);
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		var weekMod:String = daWeek+saveMod;
		if (!weekScores.exists(weekMod))
			setWeekScore(weekMod, 0);

		return weekScores.get(weekMod);
	}

	public static function reloadModifiers(?customMod:String):Void
	{
		saveMod = "";
		var playAsGF:Bool = ClientPrefs.getGameplaySetting('gfMode', false);
		var chartModifier:String = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');		
		var opponentmode:Bool = ClientPrefs.getGameplaySetting('opponentplay', false);
		var loopMode:Bool = ClientPrefs.getGameplaySetting('loopMode', false);
		var loopModeChallenge:Bool = ClientPrefs.getGameplaySetting('loopModeC', false);
		var bothMode:Bool = ClientPrefs.getGameplaySetting('bothMode', false);
		if (bothMode)
			saveMod += "-bothMode";
		else if (opponentmode)
			saveMod += "-opponentMode";
		else if (playAsGF)
			saveMod += "-gfMode";
		if (chartModifier != "Normal")
			saveMod += "-"+chartModifier;
		if (!ClientPrefs.data.gimmicksAllowed)
			saveMod += "-noGimmick";
		if (!ClientPrefs.data.modcharts)
			saveMod += "-noModchart";
		if (ClientPrefs.data.noAntimash)
			saveMod += "-noAntimash";
		if (!ClientPrefs.data.drain)
			saveMod += "-noHealthDrain";
		if (!ClientPrefs.data.useMarvs)
			saveMod += "-noMarvs";
		if (loopModeChallenge)
			saveMod += "-endlessChallenge";
		else if (loopMode)
			saveMod += "-endless";
		if (customMod != "" && customMod != null)
			saveMod += customMod;
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
			weekScores = FlxG.save.data.weekScores;

		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;

		if (FlxG.save.data.songRating != null)
			songRating = FlxG.save.data.songRating;

		if (FlxG.save.data.songMisses != null)
			songMisses = FlxG.save.data.songMisses;
		
		if (FlxG.save.data.songRanks != null)
			songRanks = FlxG.save.data.songRanks;
		
		if (FlxG.save.data.songDeaths != null)
			songDeaths = FlxG.save.data.songDeaths;
	}
}