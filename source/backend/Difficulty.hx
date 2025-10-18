package backend;

class Difficulty
{
	public static final defaultList:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	private static final defaultDifficulty:String = 'Normal'; //The chart that has no postfix and starting difficulty on Freeplay/Story Mode

	public static var list:Array<String> = [];

	inline public static function getFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var filePostfix:String = list[num];
		if(filePostfix != null && (Paths.formatToSongPath(filePostfix) != Paths.formatToSongPath(defaultDifficulty) || Paths.formatToSongPath(filePostfix) != Paths.formatToSongPath(defaultDifficulty.toLowerCase())))
			filePostfix = '-' + filePostfix;
		else
			filePostfix = '';
		return Paths.formatToSongPath(filePostfix);
	}

	inline public static function loadFromWeek(week:WeekData = null)
	{
		if(week == null) week = WeekData.getCurrentWeek();

		var diffStr:String = week.difficulties;
		function APD() {
		#if ARCHIPELAGO_ALLOWED
		// If High Quality Trap is in use, check for SiivaGunner difficulties
		if (archipelago.HighQualityTrapManager.isTrapInUse())
		{
			// Get difficulties from SiivaGunner week data (not individual songs)
			var siivaModName = week.folder;
			if (siivaModName == null || siivaModName == '') siivaModName = archipelago.HighQualityTrapManager.BASE_GAME_MARKER;

			var siivaDiffs = archipelago.HighQualityTrapManager.getWeekDifficulties(week.weekName, siivaModName);
			if (siivaDiffs != null && siivaDiffs.length > 0)
			{
				list = siivaDiffs.copy();
				trace('Difficulty: Using SiivaGunner week difficulties for "${week.weekName}": ${siivaDiffs.join(", ")}');
				return true;
			}
		}
		#end
		return false;
	}
		if (APD()) return;

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.trim().split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
				list = diffs;
		}
		else resetList();
	}

	inline public static function resetList()
	{
		list = defaultList.copy();
	}

	inline public static function copyFrom(diffs:Array<String>)
	{
		list = diffs.copy();
	}

	inline public static function getString(?num:Null<Int> = null, ?canTranslate:Bool = true):String
	{
		var diffName:String = list[num == null ? PlayState.storyDifficulty : num];
		if(diffName == null) diffName = defaultDifficulty;
		return canTranslate ? Language.getPhrase('difficulty_$diffName', diffName) : diffName;
	}

	inline public static function getDefault():String
	{
		return defaultDifficulty;
	}

	#if ARCHIPELAGO_ALLOWED
	/**
	 * Load difficulties specifically for a SiivaGunner song if trap is in use
	 */
	inline public static function loadFromSiivaSong(songName:String, modName:String = null)
	{
		if (!archipelago.HighQualityTrapManager.isTrapInUse()) return;

		var siivaDiffs = archipelago.HighQualityTrapManager.getAvailableDifficulties(songName, modName);
		if (siivaDiffs != null && siivaDiffs.length > 0)
		{
			list = siivaDiffs.copy();
		}
		else
		{
			resetList();
		}
	}

	/**
	 * Check if a difficulty is available for a specific song when SiivaGunner trap is in use
	 */
	inline public static function isDifficultyAvailableForSong(songName:String, modName:String, difficulty:String):Bool
	{
		#if ARCHIPELAGO_ALLOWED
		if (archipelago.HighQualityTrapManager.isTrapInUse())
		{
			return archipelago.HighQualityTrapManager.isDifficultyAvailable(songName, modName, difficulty);
		}
		#end
		return true; // If trap is not in use, all difficulties are available
	}
	#end
}
