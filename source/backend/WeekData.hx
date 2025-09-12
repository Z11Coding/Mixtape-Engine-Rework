package backend;

import archipelago.APEntryState;
import archipelago.APGameState;
import backend.GitHubAPI;
import haxe.Json;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

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
	var category:flixel.util.typeLimit.OneOfTwo<String, Array<String>>;
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
	public var category:flixel.util.typeLimit.OneOfTwo<String, Array<String>>;
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

		// Add GitHub mods as virtual directories
		var githubModNames = GitHubAPI.getAllGitHubModNames();
		var githubDirStart = directories.length;

		if (APEntryState.inArchipelagoMode) {
			for (day in APGameState.temporaryWeeks) weeksLoaded.set(day.weekName, day);
			weeksList = APGameState.temporaryWeekNames.copy();
		}

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getSharedPath('weeks/weekList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				if(!weeksLoaded.exists(sexList[i])) {
					var week:WeekFile = getWeekFile(fileToCheck);
					if(week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if(j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
						}
						#end

						if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}

			// Check GitHub mods for week files
			if(!weeksLoaded.exists(sexList[i])) {
				for (modName in githubModNames) {
					var githubPath = 'github://' + modName + '/weeks/' + sexList[i] + '.json';
					var week:WeekFile = getWeekFile(githubPath);
					if(week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);
						weekFile.folder = modName; // Use actual mod name instead of 'github'

						if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
							break; // Found it, no need to check other GitHub mods
						}
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

		// Check GitHub mods for additional weeks by scanning their directories
		for (modName in githubModNames) {
			// Get all .json files from the weeks folder of this GitHub mod
			var weekFiles:Array<String> = GitHubAPI.getGitHubDirectoryContents(modName, 'weeks/');
			if (weekFiles.length > 0) {
				for (fileName in weekFiles) {
					if (fileName.endsWith('.json') && fileName != 'weekList.txt') {
						var weekName = fileName.substr(0, fileName.length - 5);
						var githubPath = 'github://' + modName + '/weeks/' + fileName;
						addGitHubWeek(weekName, githubPath);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if(week != null)
			{
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

	private static function addGitHubWeek(weekToCheck:String, githubPath:String)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(githubPath);
			if(week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);

				// Extract mod name from github path (github://modname/weeks/...)
				var modName = 'github';
				if(githubPath.startsWith("github://")) {
					var parts = githubPath.substring(9).split('/');
					if(parts.length > 0) {
						modName = parts[0];
					}
				}
				weekFile.folder = modName;

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

		// Check if this is a GitHub path
		if(path.startsWith("github://")) {
			rawJson = GitHubAPI.getGitHubFile(path);
		} else {
			#if MODS_ALLOWED
			if(FileSystem.exists(path)) {
				rawJson = File.getContent(path);
			}
			#else
			if(OpenFlAssets.exists(path)) {
				rawJson = Assets.getText(path);
			}
			#end
		}

		if(rawJson != null && rawJson.length > 0) {
			return cast tjson.TJSON.parse(rawJson);
		}
		return null;
	}

	// FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	// To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	// Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			if(data.folder == 'github') {
				// For GitHub weeks, we don't set currentModDirectory since GitHub mods are handled differently
				// The Paths system will automatically check GitHub mods via GitHubAPI.githubModFolders()
				trace('Loading week from GitHub mods');
			} else {
				Mods.currentModDirectory = data.folder;
			}
		}
	}
}
