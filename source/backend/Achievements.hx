package backend;

#if ACHIEVEMENTS_ALLOWED
import objects.AchievementPopup;
import haxe.Exception;
import haxe.Json;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

typedef Achievement =
{
	var name:String;
	var description:String;
	@:optional var hidden:Bool;
	@:optional var maxScore:Float;
	@:optional var maxDecimals:Int;

	//handled automatically, ignore these two
	@:optional var mod:String;
	@:optional var ID:Int; 
}

enum abstract AchievementOp(String)
{
	var GET = 'get';
	var SET = 'set';
	var ADD = 'add';
}

class Achievements {
	public static function init()
	{
		createAchievement('friday_night_play',		{name: "Freaky on a Friday Night", description: "Play on a Friday... Night.", hidden: true});
		createAchievement('ur_bad',					{name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%."});
		createAchievement('ur_good',				{name: "Perfectionist", description: "Complete a Song with a rating of 100%."});
		createAchievement('toastie',				{name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?"});
		createAchievement('beat_battle',			{name: "Rhythm Master", description: "Beat \"Beat Battle\" on any difficulty higher than Normal."});
		createAchievement('beat_battle_master',		{name: "King Of Memory", description: "Beat \"Beat Battle\" on at least Reasonable difficulty or higher with no higher then 10 misses."});
		createAchievement('beat_battle_god',		{name: "God Teir Memory", description: "Beat \"Beat Battle\" on at least Semi-Impossible difficulty or higher with no higher then 25 misses."});
		createAchievement('beat_battle_fanatic',	{name: "Number One Fan", description: "Beat \"Beat Battle\" on at least Reasonable difficulty or higher and \"Beat Battle 2\" with modcharts on", maxScore: 2, maxDecimals: 0});
		createAchievement('feelinfrisky',	        {name: "FANTA IN MY SYSTEM", description: "Beat \"Funky Fanta\" without missing"});
		createAchievement('leantastic',	            {name: "Maybe We Should Cool It On The Lean...", description: "Beat \"ULS\" without missing"});
		createAchievement('punchout',	            {name: "Where's The COD Reference?", description: "Beat \"Pack-A-Punch\" without missing"});
		createAchievement('rawr',	                {name: "Don't mess with michael", description: "Beat \"Rawr\" without missing"});
		createAchievement('underlust',	            {name: "DETERMINATION...I Think...", description: "Beat \"Resistalovania (Mega Mix)\" on the hardest difficulty"});
		createAchievement('resistified',	        {name: "True Resistance", description: "Beat Every version of \"Resistance\" without missing", maxScore: 7, maxDecimals: 0});
		createAchievement('skysthelimit',	        {name: "Sky's The Limit", description: "Beat \"Fangirl Frenzy\" without missing", hidden: true});
		createAchievement('secretsunveiled',	    {name: "THERE'S MORE???", description: "Find one of the 4 secrets", hidden: true});
		createAchievement('pokemon',	    		{name: "Gotta find em' all!", description: "Find all 3 menu secrets", hidden: true});
		createAchievement('waldosworstnightmare',	{name: "Detective", description: "Find all 4 secret songs", hidden: true});
		createAchievement('error404',	            {name: "SONG NOT FOUND", description: "Find and beat \"Slowdown\"", hidden: true});
		createAchievement('secretsuntold',	        {name: "Secret's Untold", description: "Unlock the Secrets Category", hidden: true});
		createAchievement('potato',	                {name: "Slow-Mo", description: "Set the game to 1 FPS", hidden: true});
		createAchievement('potatogameplay',	        {name: "YOU CAN PLAY LIKE THIS?!?!", description: "Beat a song while the FPS is set to 1", hidden: true});
		createAchievement('mattdestroyer',	        {name: "Max Efficiency", description: "Beat a song at 2X Speed or higher", hidden: true});
		createAchievement('matteleminator',	        {name: "Max Efficiency 2X", description: "Beat a song at 5X Speed or higher", hidden: true});
		createAchievement('mattgod',	            {name: "Max Efficiency 3X", description: "Beat a song at 10x Speed or higher", hidden: true});
		createAchievement('matt',	                {name: "Max Efficiency 4X", description: "Beat a song at 15X Speed or higher", hidden: true});
		createAchievement('mattbeyond',	            {name: "Bro what are you even doing anymore", description: "Beat a song at 20X Speed or higher", hidden: true});
		createAchievement('perfectionist',	        {name: "S for the best", description: "Beat every song with an S Rank or higher"});
		createAchievement('nohitspecialist',	    {name: "No-Hit Specialist", description: "Beat \"Resistalovania (Mega Mix)\" without getting damaged"});
		createAchievement('multitasker',	        {name: "Two-For-One Special", description: "Beat \"Resistalovania (Mega Mix)\" without getting damaged AND without missing"});
		createAchievement('possessed',	        	{name: "The Moon Slayer", description: "Beat \"Possessed by The Blood Moon\" on FNF or NITG difficulty without missing", hidden: true});
		createAchievement('themoon',	        	{name: "The Exorcist", description: "Beat \"Possessed by The Blood Moon\" on Possessed difficulty without missing", hidden: true});
		createAchievement('what',	        	    {name: "What.", description: "You did read the bottom of the file, right?"});
		createAchievement('lessismore',	        	{name: "Master of Less", description: "Beat any song in a mania of 1-3"});
		createAchievement('toomanynotes',	        {name: "Master of Mania", description: "Beat any song in a mania higher than 4"});
		createAchievement('h?',	                    {name: "h?", description: "h?"});
		createAchievement('pessy_easter_egg',		{name: "Engine Gal Pal", description: "Teehee, you found me~!", hidden: true});
		
		//dont delete this thing below
		_originalLength = _sortID + 1;
	}

	public static var achievements:Map<String, Achievement> = new Map<String, Achievement>();
	public static var variables:Map<String, Float> = [];
	public static var achievementsUnlocked:Array<String> = [];
	private static var _firstLoad:Bool = true;

	public static function get(name:String):Achievement
		return achievements.get(name);
	public static function exists(name:String):Bool
		return achievements.exists(name);

	public static function load():Void
	{
		if(!_firstLoad) return;

		if(_originalLength < 0) init();

		if(FlxG.save.data != null) {
			if(FlxG.save.data.achievementsUnlocked != null)
				achievementsUnlocked = FlxG.save.data.achievementsUnlocked;

			var savedMap:Map<String, Float> = cast FlxG.save.data.achievementsVariables;
			if(savedMap != null)
			{
				for (key => value in savedMap)
				{
					variables.set(key, value);
				}
			}
			_firstLoad = false;
		}
	}

	public static function save():Void
	{
		FlxG.save.data.achievementsUnlocked = achievementsUnlocked;
		FlxG.save.data.achievementsVariables = variables;
	}
	
	public static function getScore(name:String):Float
		return _scoreFunc(name, GET);

	public static function setScore(name:String, value:Float, saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, SET, value, saveIfNotUnlocked);

	public static function addScore(name:String, value:Float = 1, saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, ADD, value, saveIfNotUnlocked);

	static function _scoreFunc(name:String, mode:AchievementOp, addOrSet:Float = 1, saveIfNotUnlocked:Bool = true):Float
	{
		if(!variables.exists(name))
			variables.set(name, 0);

		if(achievements.exists(name))
		{
			var achievement:Achievement = achievements.get(name);
			if(achievement.maxScore < 1) throw new Exception('Achievement has score disabled or is incorrectly configured: $name');

			if(achievementsUnlocked.contains(name)) return achievement.maxScore;

			var val = addOrSet;
			switch(mode)
			{
				case GET: return variables.get(name); //get
				case ADD: val += variables.get(name); //add
				default:
			}

			if(val >= achievement.maxScore)
			{
				unlock(name);
				val = achievement.maxScore;
			}
			variables.set(name, val);

			Achievements.save();
			if(saveIfNotUnlocked || val >= achievement.maxScore) FlxG.save.flush();
			return val;
		}
		return -1;
	}

	static var _lastUnlock:Int = -999;
	public static function unlock(name:String, autoStartPopup:Bool = true):String {
		if(!achievements.exists(name))
		{
			FlxG.log.error('Achievement "$name" does not exists!');
			throw new Exception('Achievement "$name" does not exists!');
			return null;
		}

		if(Achievements.isUnlocked(name)) return null;

		trace('Completed achievement "$name"');
		achievementsUnlocked.push(name);

		// earrape prevention
		var time:Int = openfl.Lib.getTimer();
		if(Math.abs(time - _lastUnlock) >= 100) //If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
			_lastUnlock = time;
		}

		Achievements.save();
		FlxG.save.flush();

		if(autoStartPopup) startPopup(name);
		return name;
	}

	public static function lock(name:String, autoStartPopup:Bool = false):String {
		if(!achievements.exists(name))
		{
			FlxG.log.error('Achievement "$name" does not exists!');
			throw new Exception('Achievement "$name" does not exists!');
			return null;
		}

		if(!Achievements.isUnlocked(name)) return null;

		trace('Completed achievement "$name"');
		achievementsUnlocked.remove(name);

		// earrape prevention
		/*var time:Int = openfl.Lib.getTimer();
		if(Math.abs(time - _lastUnlock) >= 100) //If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
			_lastUnlock = time;
		}*/

		Achievements.save();
		FlxG.save.flush();

		if(autoStartPopup) startPopup(name);
		return name;
	}

	public static function relock()
	{
		achievementsUnlocked = [];
		Achievements.save();
		FlxG.save.flush();
	}

	inline public static function isUnlocked(name:String)
		return achievementsUnlocked.contains(name);

	@:allow(objects.AchievementPopup)
	private static var _popups:Array<AchievementPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups()
		return _popups.length > 0;

	public static function startPopup(achieve:String, endFunc:Void->Void = null) {
		for (popup in _popups)
		{
			if(popup == null) continue;
			popup.intendedY += 150;
		}

		var newPop:AchievementPopup = new AchievementPopup(achieve, endFunc);
		_popups.push(newPop);
		//trace('Giving achievement ' + achieve);
	}

	// Map sorting cuz haxe is physically incapable of doing that by itself
	static var _sortID = 0;
	static var _originalLength = -1;
	public static function createAchievement(name:String, data:Achievement, ?mod:String = null)
	{
		data.ID = _sortID;
		data.mod = mod;
		achievements.set(name, data);
		_sortID++;
	}

	#if MODS_ALLOWED
	public static function reloadList()
	{
		// remove modded achievements
		if((_sortID + 1) > _originalLength)
			for (key => value in achievements)
				if(value.mod != null)
					achievements.remove(key);

		_sortID = _originalLength-1;

		var modLoaded:String = Mods.currentModDirectory;
		Mods.currentModDirectory = null;
		loadAchievementJson(Paths.mods('data/achievements.json'));
		for (i => mod in Mods.parseList().enabled)
		{
			Mods.currentModDirectory = mod;
			loadAchievementJson(Paths.mods('$mod/data/achievements.json'));
		}
		Mods.currentModDirectory = modLoaded;
	}

	inline static function loadAchievementJson(path:String, addMods:Bool = true)
	{
		var retVal:Array<Dynamic> = null;
		if(FileSystem.exists(path)) {
			try {
				var rawJson:String = File.getContent(path).trim();
				if(rawJson != null && rawJson.length > 0) retVal = tjson.TJSON.parse(rawJson); //Json.parse('{"achievements": $rawJson}').achievements;
				
				if(addMods && retVal != null)
				{
					for (i in 0...retVal.length)
					{
						var achieve:Dynamic = retVal[i];
						if(achieve == null)
						{
							var errorTitle = 'Mod name: ' + Mods.currentModDirectory != null ? Mods.currentModDirectory : "None";
							var errorMsg = 'Achievement #${i+1} is invalid.';
							#if windows
							lime.app.Application.current.window.alert(errorMsg, errorTitle);
							#end
							trace('$errorTitle - $errorMsg');
							continue;
						}

						var key:String = achieve.save;
						if(key == null || key.trim().length < 1)
						{
							var errorTitle = 'Error on Achievement: ' + (achieve.name != null ? achieve.name : achieve.save);
							var errorMsg = 'Missing valid "save" value.';
							#if windows
							lime.app.Application.current.window.alert(errorMsg, errorTitle);
							#end
							trace('$errorTitle - $errorMsg');
							continue;
						}
						key = key.trim();
						if(achievements.exists(key)) continue;

						createAchievement(key, achieve, Mods.currentModDirectory);
					}
				}
			} catch(e:Dynamic) {
				var errorTitle = 'Mod name: ' + Mods.currentModDirectory != null ? Mods.currentModDirectory : "None";
				var errorMsg = 'Error loading achievements.json: $e';
				#if windows
				lime.app.Application.current.window.alert(errorMsg, errorTitle);
				#end
				trace('$errorTitle - $errorMsg');
			}
		}
		return retVal;
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "getAchievementScore", function(name:String):Float
		{
			if(!achievements.exists(name))
			{
				FunkinLua.luaTrace('getAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return getScore(name);
		});
		Lua_helper.add_callback(lua, "setAchievementScore", function(name:String, ?value:Float = 0, ?saveIfNotUnlocked:Bool = true):Float
		{
			if(!achievements.exists(name))
			{
				FunkinLua.luaTrace('setAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return setScore(name, value, saveIfNotUnlocked);
		});
		Lua_helper.add_callback(lua, "addAchievementScore", function(name:String, ?value:Float = 1, ?saveIfNotUnlocked:Bool = true):Float
		{
			if(!achievements.exists(name))
			{
				FunkinLua.luaTrace('addAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return addScore(name, value, saveIfNotUnlocked);
		});
		Lua_helper.add_callback(lua, "unlockAchievement", function(name:String):Dynamic
		{
			if(!achievements.exists(name))
			{
				FunkinLua.luaTrace('unlockAchievement: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return unlock(name);
		});
		Lua_helper.add_callback(lua, "isAchievementUnlocked", function(name:String):Dynamic
		{
			if(!achievements.exists(name))
			{
				FunkinLua.luaTrace('isAchievementUnlocked: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return isUnlocked(name);
		});
		Lua_helper.add_callback(lua, "achievementExists", function(name:String) return achievements.exists(name));
	}
	#end
}
#end