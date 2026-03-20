package backend;

import haxe.Json;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

#if ARCHIPELAGO_ALLOWED
import archipelago.APEntryState;
import archipelago.APGameState;
#end

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
	var category:OneOrMore<String>;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;
	public var category:OneOrMore<String>;
	public var fileName:String;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "face", [146, 113, 253]], ["Fresh", "face", [146, 113, 253]], ["Dad Battle", "face", [146, 113, 253]]],
			#if BASE_GAME_FILES
			weekCharacters: ['dad', 'bf', 'gf'],
			#else
			weekCharacters: ['bf', 'bf', 'gf'],
			#end
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: '',
			category: ''
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String) {
		// here ya go - MiguelItsOut
		for (field in Reflect.fields(weekFile))
			if(Reflect.fields(this).contains(field)) // Reflect.hasField() won't fucking work :/
				Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
		var originalLength:Int = directories.length;

		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods(mod + '/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath()];
		var originalLength:Int = directories.length;
		#end

		#if ARCHIPELAGO_ALLOWED
		if (APEntryState.inArchipelagoMode) {
			for (day in APGameState.temporaryWeeks) weeksLoaded.set(day.weekName, day);
			weeksList = APGameState.temporaryWeekNames.copy();
		}
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getSharedPath('weeks/weekList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				var week:WeekFile = getWeekFile(fileToCheck);
				if(week != null) {
					var weekFile:WeekData = new WeekData(week, sexList[i]);

					#if MODS_ALLOWED
					if(j >= originalLength) {
						weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
					}
					#end

					// Generate unique ID: use folder if from mod, otherwise just name
					var uniqueId:String = sexList[i];
					#if MODS_ALLOWED
					if(j >= originalLength && weekFile.folder.length > 0) {
						uniqueId = sexList[i] + '|' + weekFile.folder;
					}
					#end

					if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
						weeksLoaded.set(uniqueId, weekFile);
						weeksList.push(uniqueId);
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'weeks/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if(FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck)) {
			var week:WeekFile = getWeekFile(path).funcAndReturn(function(wk) {
				wk.category = wk.category.split(',').map(function(s) return s.trim()).filter(function(s) return s.length > 0);
			});
			if(week != null) {
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if(i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length-1);
					#end
				}
				if((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast tjson.TJSON.parse(rawJson);
		}
		return null;
	}

	// FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	// To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek].split('|')[0];
	}

	// Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Mods.currentModDirectory = data.folder;
		}
	}
}

/**
 * Abstract for convenient week access with type conversions.
 * Supports accessing weeks by name, index, or direct WeekData reference.
 *
 * Usage:
 * ```haxe
 * var w1:Week = "week1";                    // By week name
 * var w2:Week = 0;                        // By index in weeksList
 * var w3:Week = weekDataInstance;         // Direct conversion
 * trace(w1.name);                         // Access properties
 * trace(w1.songs[0]);                     // Access first song
 * var data:WeekData = w1;                 // Implicit conversion back to WeekData
 * ```
 */
abstract Week(WeekData) {
	/**
	 * Create Week from another WeekData instance.
	 */
	@:from public static inline function fromWeekData(data:WeekData):Week {
		return cast data;
	}

	/**
	 * Create Week from week name (string).
	 * Looks up the week by name in weeksLoaded.
	 */
	@:from public static inline function fromString(name:String):Week {
		var week = WeekData.weeksLoaded.get(name);
		if (week == null) {
			// Try to find by display name instead
			for (id => w in WeekData.weeksLoaded) {
				if (w.weekName == name) {
					return cast w;
				}
			}
		}
		return cast week;
	}

	/**
	 * Create Week from index in weeksList.
	 * Returns null Week if index is out of bounds.
	 */
	@:from public static inline function fromIndex(index:Int):Week {
		if (index >= 0 && index < WeekData.weeksList.length) {
			return cast WeekData.weeksLoaded.get(WeekData.weeksList[index]);
		}
		return cast null;
	}

	/**
	 * Convert Week back to WeekData.
	 */
	@:to public inline function toWeekData():WeekData {
		return this;
	}

	// Quick access properties
	public var name(get, never):String;
	inline function get_name():String return this.weekName;

	public var displayName(get, never):String;
	inline function get_displayName():String return this.storyName;

	public var characters(get, never):Array<String>;
	inline function get_characters():Array<String> return this.weekCharacters;

	public var background(get, never):String;
	inline function get_background():String return this.weekBackground;

	public var songs(get, never):Array<Dynamic>;
	inline function get_songs():Array<Dynamic> return this.songs;

	public var fileName(get, never):String;
	inline function get_fileName():String return this.fileName;

	public var folder(get, never):String;
	inline function get_folder():String return this.folder;

	public var isUnlocked(get, never):Bool;
	inline function get_isUnlocked():Bool return this.startUnlocked;

	public var hiddenUntilUnlocked(get, never):Bool;
	inline function get_hiddenUntilUnlocked():Bool return this.hiddenUntilUnlocked;

	public var hideFromStory(get, never):Bool;
	inline function get_hideFromStory():Bool return this.hideStoryMode;

	public var hideFromFreeplay(get, never):Bool;
	inline function get_hideFromFreeplay():Bool return this.hideFreeplay;

	public var difficulties(get, never):String;
	inline function get_difficulties():String return this.difficulties;

	public var category(get, never):OneOrMore<String>;
	inline function get_category():OneOrMore<String> return this.category;

	public var songCount(get, never):Int;
	inline function get_songCount():Int return this.songs.length;

	/**
	 * Get a song by index.
	 */
	@:op(A[B]) public inline function getSong(index:Int):Dynamic {
		if (index >= 0 && index < this.songs.length) {
			return this.songs[index];
		}
		return null;
	}

	/**
	 * Check if week contains a character.
	 */
	public inline function hasCharacter(character:String):Bool {
		return this.weekCharacters.contains(character);
	}

	/**
	 * Get the underlying WeekData instance.
	 */
	public inline function getData():WeekData {
		return this;
	}

	/**
	 * Iterate over songs in this week.
	 */
	public inline function iterator():Iterator<Dynamic> {
		return this.songs.iterator();
	}
}
