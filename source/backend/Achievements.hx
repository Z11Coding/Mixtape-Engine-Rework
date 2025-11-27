package backend;

#if ACHIEVEMENTS_ALLOWED
import haxe.Exception;
import haxe.Json;
import objects.AchievementPopup;

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
		// The achievements that are so easy to get that they're basically nothing more than filler
		createAchievement('start_fnf',				{name: "I Said Funkin'!", description: "Start the game for the first time."});
		createAchievement('play_fnf',				{name: "Just like the game!", description: "Get freaky on a Friday."});
		createAchievement('friday_night_play',		{name: "Freaky on a Friday Night", description: "Play on a Friday... Night.", hidden: true});

		// The "Beat the week!" achievements
		createAchievement('tutorial',				{name: "That's How You Do It!", description: "Beat Tutorial in Story Mode (on any difficulty)."});
		createAchievement('week1',					{name: "More Like Daddy Queerest", description: "Beat Week 1 in Story Mode (on any difficulty)."});
		createAchievement('week2',					{name: "IT IS THE SPOOKY MONTH", description: "Beat Week 2 in Story Mode (on any difficulty)."});
		createAchievement('week3',					{name: "Pico Funny", description: "Beat Week 3 in Story Mode (on any difficulty)."});
		createAchievement('week4',					{name: "Mommy Must Murder", description: "Beat Week 4 in Story Mode (on any difficulty)."});
		createAchievement('week5',					{name: "Yule Tide Joy", description: "Beat Week 5 in Story Mode (on any difficulty)."});
		createAchievement('week6',					{name: "A Visual Novelty", description: "Beat Week 6 in Story Mode (on any difficulty)."});
		createAchievement('week7',					{name: "I <3 JohnnyUtah", description: "Beat Week 7 in Story Mode (on any difficulty)."});
		createAchievement('weekend1',				{name: "Yo, Really Think So?", description: "Beat Weekend 1 in Story Mode (on any difficulty)."});

		// Pico-exclusive achievements
		createAchievement('pico_mixed',				{name: "A Challenger Appears", description: "Beat any Pico remix in Freeplay (on any difficulty)."});
		createAchievement('pico_stressed',			{name: "De-Stressing", description: "Beat Stress (Pico Mix) in Freeplay (on Normal difficulty or higher)."});

		// Rating achievements
		createAchievement('l',						{name: "L", description: "Earn a F rating on any song (on any difficulty)."});
		createAchievement('a_freaky',				{name: "Almost Freaky", description: "Earn a S Rank or higher on any song"});
		createAchievement('freaky',					{name: "Getting Freaky", description: "Earn a SS Rank or higher on any song"});
		createAchievement('true_funker',			{name: "You Should Drink More Water", description: "Earn a P Rank on any song on Hard difficulty or higher."});
		createAchievement('nice',					{name: "Nice", description: "Earn a rating of EXACTLY 69% (good luck)."});

		// Combo achievements
		createAchievement('mfc',					{name: "Literal Perfection!", description: "Earn a Combo Rating of MFC."});
		createAchievement('sfc',					{name: "Almost Perfection", description: "Earn a Combo Rating of SFC."});
		createAchievement('gfc',					{name: "Good Enough", description: "Earn a Combo Rating of GFC."});
		createAchievement('afc',					{name: "Pretty Acurate", description: "Earn a Combo Rating AFC."});
		createAchievement('fc',						{name: "Full Combo!", description: "Earn a Combo Rating FC."});
		createAchievement('sdcb',					{name: "Off by One", description: "Earn a Combo Rating SDCB."});
		createAchievement('clear',					{name: "In the clear", description: "Earn a Combo Rating Clear."});

		// Difficulty achievements
		createAchievement('erect',					{name: "Harder Than Hard", description: "Beat any Erect remix in Freeplay on Erect or Nightmare difficulty."});
		createAchievement('nightmare',				{name: "The Rap God", description: "Earn a P Rank on any song on Nightmare difficulty."});

		// The "Beat the week without missing!" achievements
		createAchievement('tutorial_nomiss',		{name: "Tutorial Extraordinaire", description: "Beat Tutorial (Week) on Hard with no Misses."});
		createAchievement('week1_nomiss',			{name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses."});
		createAchievement('week2_nomiss',			{name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses."});
		createAchievement('week3_nomiss',			{name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses."});
		createAchievement('week4_nomiss',			{name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses."});
		createAchievement('week5_nomiss',			{name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses."});
		createAchievement('week6_nomiss',			{name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses."});
		createAchievement('week7_nomiss',			{name: "God Effing Damn It!", description: "Beat Week 7 on Hard with no Misses."});
		createAchievement('weekend1_nomiss',		{name: "Just a Friendly Sparring", description: "Beat Weekend 1 on Hard with no Misses."});

		// extra achievements
		createAchievement('ur_bad',					{name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%."});
		createAchievement('ur_good',				{name: "Perfectionist", description: "Complete a Song with a rating of 100%."});
		createAchievement('roadkill_enthusiast',	{name: "Roadkill Enthusiast", description: "Watch the Henchmen die 50 times.", maxScore: 50, maxDecimals: 0});
		createAchievement('oversinging', 			{name: "Oversinging Much...?", description: "Sing for 10 seconds without going back to Idle."});
		createAchievement('hype',					{name: "Hyperactive", description: "Finish a Song without going back to Idle."});
		createAchievement('two_keys',				{name: "Just the Two of Us", description: "Finish a Song pressing only two keys."});
		createAchievement('toastie',				{name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?"});
		createAchievement('potato',					{name: "The Ultimate Potato", description: "The minimum requirement to run the game on a potato."});
		createAchievement('search_songs',			{name: "The Music Lost to Time", description: "Find all 4 secret freeplay songs\n(And no, playing them in archipelago mode doesn't count)", maxScore: 4, maxDecimals: 0});
		createAchievement('challenger',				{name: "Challenger", description: "Complete a Song with 2 Safe Frames."});
		createAchievement('hardcore',				{name: "Hardcore", description: "Beat a song with no Misses on 24/20 mode."});
		createAchievement('demon',					{name: "Demon", description: "Beat a Song with 100% accuracy on 24/20 mode. Well done, now stop it."});
		createAchievement('persistent',				{name: "Persistent", description: "Beat a Week with no Misses on 24/20 mode. Jesus Christ..."});
		createAchievement('resilient',				{name: "Resilient", description: "Beat a Week with 100% accuracy on all songs on 24/20 mode. Go touch grass you moron"});

		// Secret achievements
		createAchievement('fps',					{name: "1 FPS Gaming", description: "Slideshow Incarnate,", hidden: true});
		createAchievement('lag',					{name: "man this engine SUCKS", description: "Lag.", hidden: true});
		createAchievement('much_better',			{name: "Much Better", description: "Can someone please turn the lights off, please?", hidden: true});
		createAchievement('debugger',				{name: "Debugger", description: "Beat the \"Test\" Stage from the Chart Editor.", hidden: true});
		createAchievement('pessy_easter_egg',		{name: "Engine Gal Pal", description: "Teehee, you found me~!", hidden: true});
		createAchievement('freaky_bar',				{name: "All-In-One", description: "Get the secret health mode.", hidden: true});
		createAchievement('much_better',			{name: "Much Better", description: "Join the dark side.", hidden: true});

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

	public static function relock(name:String):String {
		if(!achievements.exists(name))
		{
			FlxG.log.error('Achievement "$name" does not exists!');
			throw new Exception('Achievement "$name" does not exists!');
			return null;
		}

		if(!Achievements.isUnlocked(name)) return null;

		trace('reset achievement "$name"');
		achievementsUnlocked.remove(name);

		// earrape prevention
		var time:Int = openfl.Lib.getTimer();
		if(Math.abs(time - _lastUnlock) >= 100) //If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
			_lastUnlock = time;
		}

		Achievements.save();
		FlxG.save.flush();

		return name;
	}

	public static function reset() {
		trace('reset all achievements');
		achievementsUnlocked = [];

		// earrape prevention
		var time:Int = openfl.Lib.getTimer();
		if(Math.abs(time - _lastUnlock) >= 100) //If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
		{
			FlxG.sound.play(Paths.sound('fnf_loss_sfx'), 0.5);
			_lastUnlock = time;
		}

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
