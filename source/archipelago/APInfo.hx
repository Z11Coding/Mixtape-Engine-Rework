package archipelago;

import lime.app.Application;
import substates.RankingSubstate;


typedef APSettings =
{
	var name:String;
	var description:String;
	var game:String;
	var FNF:APOptions;
}

typedef APOptions =
{
	var	progression_balancing:String;
	var	accessibility:String;
	var	mods_enabled:Bool;
	var	deathlink:Bool;
	var	unlock_type:String;
	var	unlock_method:String;
	var	graderequirement:String;
	var	accrequirement:String;
	var	songList:Array<String>;
	var	ticket_percentage:Int;
	var	ticket_win_percentage:Int;
	var	chart_modifier_change_chance:Int;
	var	allow_controller_only_modifiers:Bool;
	var	trapAmount:Int;
	var	bbcWeight:Int;
	var	ghostChatWeight:Int;
	var	svcWeight:Int;
	var	tutorialWeight:Int;
	var songswitchWeight:Int;
	var resistanceWeight:Int;
	var unoWeight:Int;
	var pongWeight:Int;
	var ultConfusionWeight:Int;
	var	fakeTransWeight:Int;
	var	shieldWeight:Int;
	var	MHPWeight:Int;
	var	MHPDWeight:Int;
	var	exLifeWeight:Int;
	var	song_limit:Int;
	// New settings for APAdvancedSettingsState
	var	include_secrets:Bool;
	var	include_pico:Bool;
	var	include_erect:Bool;
	var	include_vanilla:Bool;
	var	starting_song:String;
	var	victory_song:String;
	var	enable_sanity_locations:Bool;
	var	sanity_completion_type:String;
	var	stagesanity:Bool;
	var	charactersanity:Bool;
	var	starter_debuffs:Bool;
	var	hard_mode:Bool;
	var	enable_shop:Bool;
	var	perma_traps:Bool;
	var	excludeSongList:Array<String>;
}

enum ComboRank {
	ANY;
	MFC;
	SFC;
	GFC;
	AFC;
	FC;
	SDCB;
	CLEAR;
}

enum AccuracyRank {
	P;
	X;
	XMINUS;
	SSPLUS;
	SS;
	SSMINUS;
	SPLUS;
	S;
	SMINUS;
	APLUS;
	A;
	AMINUS;
	B;
	C;
	D;
	E;
	F;
}

typedef SongDetailData = {
	id: Int,
	modded: Bool,
	playerOwner: String,
	sharedWith: Array<String>,
	songName: String
}

typedef SanityItemData = {
	id: Int,
	type: String, // "stage" or "character"
	songs: Array<{song: String, mod:String, difficulties: Array<String>}>, // Array of songs with their difficulties
	player: String
}

typedef SanityLocationData = {
	id: Int,
	sanity_item: String
}

typedef SanitySettings = {
	enable_sanity_locations: Bool,
	sanity_completion_type: String, // "on_getting", "on_playing", or "on_beating"
	sanity_types: Array<String> // What types of sanity items to check for ("Character", "Stage", etc.)
}

typedef APSlotDataType = {
	deathLink: Bool,
	fullSongCount: Int,
	victoryLocation: String,
	victoryID: Int,
	ticketWinCount: Int,
	gradeNeeded: String,
	accuracyNeeded: String,
	locationType: String,
	locationMethod: String,
	selectedSongs: Array<String>,
	songData: haxe.DynamicAccess<SongDetailData>,
	?custom_weeks: Dynamic, // Custom weeks data from HScript processing
	?song_modifications: Dynamic, // Song additions/exclusions data
	?unoColorsUsed:Array<{name:String, color_code:String}>, // Uno mod colors used in the slot
	?highQualityExpected: Bool, // Whether high quality trap content is expected to be available
	?sanityData: haxe.DynamicAccess<SanityItemData>, // Sanity items for this player
	?sanityLocationData: haxe.DynamicAccess<SanityLocationData>, // Sanity locations for this player
	?sanitySettings: SanitySettings // Sanity settings for this player
}

typedef MixtapeItemData = {
	item_id: Int,
	location_id: Int,
	songs: Array<String>,
	locations:Array<Int>,
	contains_victory:Bool,
	name:String
}

abstract APSlotData(APSlotDataType) from APSlotDataType to APSlotDataType {
	public function new(?data:APSlotDataType) {
		this = data != null ? data : {
			deathLink: false,
			fullSongCount: 0,
			victoryLocation: "",
			victoryID: 0,
			ticketWinCount: 1,
			gradeNeeded: "Any",
			accuracyNeeded: "Any",
			locationType: "Song Completion",
			locationMethod: "Per Song",
			selectedSongs: [],
			songData: new haxe.DynamicAccess<SongDetailData>(),
			custom_weeks: null,
			song_modifications: null,
			highQualityExpected: false
		};
	}

	public var deathLink(get, never):Bool;
	public var fullSongCount(get, never):Int;
	public var victoryLocation(get, never):String;
	public var victoryID(get, never):Int;
	public var ticketWinCount(get, never):Int;
	public var gradeNeeded(get, never):String;
	public var accuracyNeeded(get, never):String;
	public var locationType(get, never):String;
	public var locationMethod(get, never):String;
	public var selectedSongs(get, never):Array<String>;
	public var songData(get, never):haxe.DynamicAccess<SongDetailData>;
	public var custom_weeks(get, never):Dynamic;
	public var song_modifications(get, never):Dynamic;
	public var unoColorsUsed(get, never):Array<{name:String, color_code:String}>;
	public var highQualityExpected(get, never):Bool;
	public var sanityData(get, never):haxe.DynamicAccess<SanityItemData>;
	public var sanityLocationData(get, never):haxe.DynamicAccess<SanityLocationData>;
	public var sanitySettings(get, never):SanitySettings;

	private function get_deathLink():Bool return this.deathLink;
	private function get_fullSongCount():Int return this.fullSongCount;
	private function get_victoryLocation():String return this.victoryLocation;
	private function get_victoryID():Int return this.victoryID;
	private function get_ticketWinCount():Int return this.ticketWinCount;
	private function get_gradeNeeded():String return this.gradeNeeded;
	private function get_accuracyNeeded():String return this.accuracyNeeded;
	private function get_locationType():String return this.locationType;
	private function get_locationMethod():String return this.locationMethod;
	private function get_selectedSongs():Array<String> return this.selectedSongs;
	private function get_songData():haxe.DynamicAccess<SongDetailData> return this.songData;
	private function get_custom_weeks():Dynamic return this.custom_weeks;
	private function get_song_modifications():Dynamic return this.song_modifications;
	private function get_unoColorsUsed():Array<{name:String, color_code:String}> return this.unoColorsUsed;
	private function get_highQualityExpected():Bool return this.highQualityExpected != null ? this.highQualityExpected : false;
	private function get_sanityData():haxe.DynamicAccess<SanityItemData> return this.sanityData != null ? this.sanityData : new haxe.DynamicAccess<SanityItemData>();
	private function get_sanityLocationData():haxe.DynamicAccess<SanityLocationData> return this.sanityLocationData != null ? this.sanityLocationData : new haxe.DynamicAccess<SanityLocationData>();
	private function get_sanitySettings():SanitySettings return this.sanitySettings != null ? this.sanitySettings : {enable_sanity_locations: false, sanity_completion_type: "on_getting", sanity_types: []};

	public function get(key:String):Dynamic {
		return Reflect.field(this, key);
	}

	// public function set(key:String, value:Dynamic):Void {
	// 	Reflect.setField(this, key, value);
	// }

	public function hasKey(key:String):Bool {
		return Reflect.hasField(this, key);
	}
}

enum APMinigame {
	None;
	Uno;
	Pong;
}

class APInfo {

	static var currentAPLocation:String = new yutautil.save.MixSaveWrapper(null, "save/apLocation.json", true).getItem("apLocation") != null
		? new yutautil.save.MixSaveWrapper(null, "save/apLocation.json", true).getItem("apLocation")
		: "C:/ProgramData/Archipelago";

	public static var ap:Client;
	public static var apGame:APGameState;

	public static var allSongs:Array<String> = []; // Backup Global list
	public static var excludedSongs:Array<String> = [];

	public static var ticketCount:Int = 0;
	public static var ticketWinCount:Int = 1;

	public static var unlockMethod:String = "Song Completion";
	public static var unlockType:String = "Per Song";

	public static var accRankSetLimit:Int = 0;
	public static var comboRankSetLimit:Int = 0;

	public static var hasNoteChecks(get, never):Bool;
	public static var hasSongChecks(get, never):Bool;
	public static var hintPoints(get, never):Int;
	public static var hintCost(get, never):Int;
	public static var inMinigame:APMinigame = None;

	public static var inSongTrap(get, never):Bool;
	public static function get_inSongTrap():Bool {
		return FlxG.save.data.manualOverride == true;
	}

	public static var slotData(get, never):APSlotData;
	public static function get_slotData():APSlotData {
		return apGame?._slotData;
	}


	//Debuff Variables
	public static var soreThroat:Bool = false;
	public static var backwardsSinging:Bool = false;
	public static var blindness:Bool = false;
	public static var fivenightsatmechanicsmod:Bool = false;
	public static var unstableSpeed:Bool = false;

	public static var inHardMode:Bool = false;
	public static var inArchipelagoMode:Bool = false;
	public static var gonnaRunSync:Bool = false;
	public static var lowFilterAmount:Float = 1;
	public static var deathLink:Bool = false;
	public static var victorySong:String = '???';
	public static var fullSongCount:Int = 1;

	var accReq:AccuracyRank;
	var comReq:ComboRank;

	//So we have a general idea of what to put in the yaml
	public static var gameSettings:APSettings = {
		name: 'Player',
		description: 'Generated by Funkipelago for Friday Night Funkin',
		game: 'Friday Night Funkin',
		FNF: {
			progression_balancing: "normal",
			accessibility: "full",
			mods_enabled: false,
			deathlink: false,
			unlock_type: 'Per Song',
			unlock_method: 'Song Completion',
			graderequirement: "Any",
			accrequirement: "Any",
			songList: [],
			ticket_percentage: 15,
			ticket_win_percentage: 15,
			chart_modifier_change_chance: 15,
			allow_controller_only_modifiers: false,
			trapAmount: 15,
			bbcWeight: 5,
			ghostChatWeight: 5,
			svcWeight: 5,
			tutorialWeight: 5,
			songswitchWeight: 5,
			resistanceWeight: 5,
			unoWeight: 5,
			pongWeight: 5,
			ultConfusionWeight: 5,
			fakeTransWeight: 5,
			shieldWeight: 5,
			MHPWeight: 5,
			MHPDWeight: 5,
			exLifeWeight: 5,
			song_limit: 5,
			// New settings for APAdvancedSettingsState
			include_secrets: true,
			include_pico: true,
			include_erect: true,
			include_vanilla: true,
			starting_song: "Tutorial",
			victory_song: "Bopeebo",
			enable_sanity_locations: false,
			sanity_completion_type: "on_getting",
			stagesanity: false,
			charactersanity: false,
			starter_debuffs: false,
			perma_traps: false,
			hard_mode: false,
			enable_shop: false,
			excludeSongList: []
		}
	};

	public static var gradeList:Array<String> =
	[
		'Any',
		"MFC",
		"SFC",
		"GFC",
		"AFC",
		"FC",
		"SDCB"
	];

	public static var accuracyList:Array<String> =
	[
		"Any",
		"P",
		"X",
		"X-",
		"SS+",
		"SS",
		"SS-",
		"S+",
		"S",
		"S-",
		"A+",
		"A",
		"A-",
		"B",
		"C",
		"D",
		"E",
	];

	// All things to escape when making song names.
	public static var YAMLEscapeMap:Map<String, String>  = [
		"<cOpen>" => "{",
		"<cClose>" => "}",
		"<sOpen>" => "[",
		"<sClose>" => "]",
		"<comma>" => ",",
		"<hash>" => "#",
		// "<question>" => "?",
		"<backtick>" => "`"
	];

	// Escape map for characters that only affect strings at the beginning.
	public static var YAMLStartEscapeMap:Map<String, String> = [
		"<pipe>" => "|",
		"<amp>" => "&",
		"<exclamation>" => "!",
		"<asterisk>" => "*",
		"<percent>" => "%",
		"<at>" => "@",
		"<singleQuote>" => "'",
		"<doubleQuote>" => "\""
	];

	// Escape map for characters that only affect strings at the end.
	public static var YAMLEndEscapeMap:Map<String, String> = [
		"<singleQuote>" => "'",
		"<doubleQuote>" => "\""
	];

	// Function to reverse conversions of YAML keywords.
	public static function realName(input:String):String {
		for (key in YAMLEscapeMap.keys()) {
			input = input.replace(key, YAMLEscapeMap.get(key));
		}
		for (key in YAMLStartEscapeMap.keys()) {
			input = input.replace(key, YAMLStartEscapeMap.get(key));
		}
		for (key in YAMLEndEscapeMap.keys()) {
			input = input.replace(key, YAMLEndEscapeMap.get(key));
		}
		return input;
	}

	// Function to convert special characters into YAML-safe keywords.
	public static function toYAMLSafe(input:String):String {
		// Handle start-specific replacements
		for (key in YAMLStartEscapeMap.keys()) {
			var value = YAMLStartEscapeMap.get(key);
			if (input.startsWith(value)) {
				input = input.replace(value, key);
			}
		}
		// Handle end-specific replacements
		for (key in YAMLEndEscapeMap.keys()) {
			var value = YAMLEndEscapeMap.get(key);
			if (input.endsWith(value)) {
				input = input.substr(0, input.length - 1) + key;
			}
		}
		// Handle general replacements
		for (key in YAMLEscapeMap.keys()) {
			var value = YAMLEscapeMap.get(key);
			input = input.replace(value, key);
		}
		return input;
	}

	// Array version of toYAMLSafe - converts all strings in an array to YAML-safe format.
	public static function toYAMLSafeArray(input:Array<String>):Array<String> {
		if (input == null) return null;
		var result:Array<String> = [];
		for (item in input) {
			result.push(toYAMLSafe(item));
		}
		return result;
	}

	// Array version of realName - reverses YAML-safe formatting for all strings in an array.
	public static function realNameArray(input:Array<String>):Array<String> {
		if (input == null) return null;
		var result:Array<String> = [];
		for (item in input) {
			result.push(realName(item));
		}
		return result;
	}

	public static function get_hintPoints():Int {
		return APInfo.apGame.info().hintPoints;
	}

	public static function get_hintCost():Int {
		return APInfo.apGame.info().hintCostPoints;
	}

	public static function get_hasNoteChecks():Bool {
		return unlockMethod == "Note Checks" || unlockMethod == "Both";
	}

	public static function get_hasSongChecks():Bool {
		return unlockMethod == "Song Completion" || unlockMethod == "Both";
	}

	public static final baseGame:Array<String> =
	[
		'Tutorial',
		'Bopeebo', 'Fresh', 'Dad Battle',
		'Spookeez', 'South', 'Monster',
		'Pico', 'Philly Nice', 'Blammed',
		'Satin Panties', 'High', 'Milf',
		'Cocoa', 'Eggnog', 'Winter Horrorland',
		'Senpai', 'Roses', 'Thorns',
		'Ugh', 'Guns', 'Stress',
		'Darnell (BF Mix)', 'Lit Up (BF Mix)'
	];

	public static final baseErect:Array<String> =
	[
		'Bopeebo Erect', 'Fresh Erect', 'Dad Battle Erect',
		'Spookeez Erect', 'South Erect',
		'Pico Erect', 'Philly Nice Erect', 'Blammed Erect',
		'Satin Panties Erect', 'High Erect',
		'Cocoa Erect', 'Eggnog Erect',
		'Senpai Erect', 'Roses Erect', 'Thorns Erect',
		'Ugh Erect',
		'Darnell Erect'
	];

	public static final basePico:Array<String> =
	[
		'Darnell', 'Lit Up', '2Hot', 'Blazin',
		'Bopeebo (Pico Mix)', 'Fresh (Pico mix)', 'Dad Battle (Pico mix)',
		'Spookeez (Pico mix)', 'South (Pico mix)',
		'Pico (Pico mix)', 'Philly Nice (Pico mix)', 'Blammed (Pico mix)',
		'Eggnog (Pico Mix)', 'Cocoa (Pico Mix)',
		'Senpai (Pico mix)', 'Roses (Pico mix)',
		'Ugh (Pico mix)', 'Guns (Pico mix)', 'Stress (Pico Mix)'
	];

	public static final secrets:Array<String> = [
		'Small Argument',
		'Beat Battle',
		'Beat Battle 2',
		'GeoStar'
	];

	// TODO: Make this better lol
	public static function grabLimits(grade:String, accuracy:String) {
		switch (grade) {
				case 'Any':
					comboRankSetLimit = 0;
				case "MFC":
					comboRankSetLimit = 1;
				case "SFC":
					comboRankSetLimit = 2;
				case "GFC":
					comboRankSetLimit = 3;
				case "AFC":
					comboRankSetLimit = 4;
				case "FC":
					comboRankSetLimit = 5;
				case "SDCB":
					comboRankSetLimit = 6;
		}

		switch (accuracy) {
				case "Any":
					accRankSetLimit = 0;
				case "P":
					accRankSetLimit = 1;
				case "X":
					accRankSetLimit = 2;
				case "X-":
					accRankSetLimit = 3;
				case "SS+":
					accRankSetLimit = 4;
				case "SS":
					accRankSetLimit = 5;
				case "SS-":
					accRankSetLimit = 6;
				case "S+":
					accRankSetLimit = 7;
				case "S":
					accRankSetLimit = 8;
				case "S-":
					accRankSetLimit = 9;
				case "A+":
					accRankSetLimit = 10;
				case "A":
					accRankSetLimit = 11;
				case "A-":
					accRankSetLimit = 12;
				case "B":
					accRankSetLimit = 13;
				case "C":
					accRankSetLimit = 14;
				case "D":
					accRankSetLimit = 15;
				case "E":
					accRankSetLimit = 16;
		}

		trace('Combo Minimum: $comboRankSetLimit\nAccuacy Minimum: $accRankSetLimit');
	}

	public static function grabAPItemName(item:APItemID):String {
		if (item is String)
			return ap.get_item_name(ap.get_item_id(item));
		if (item is Int)
			return ap.get_item_name(item);
		return "";
	}

	public static function grabAPItemID(item:APItemID):Int {
		if (item is Int)
			return ap.get_item_id(ap.get_item_name(item));
		if (item is String)
			return ap.get_item_id(item);
		return -1;
	}

	public static function hasItem(item:APItemID):Bool {
		return [for (item in APGameState.instance.APItems.keys()) item == grabAPItemName(item)].contains(true);
	}
	public static function hasHMItem(item:APItemID):Bool {
		return [for (item in APItem.hardmodeItems) item == grabAPItemName(item)].contains(true);
	}

		public static function checkAPWorld():{status:String, message:String}
	{
		#if sys
		var programDataPath = currentAPLocation + "/";
		var customWorldsPath = programDataPath + "custom_worlds/";
		var apWorldFile = customWorldsPath + "fridaynightfunkin.apworld";

		try {
			if (FileSystem.exists(apWorldFile))
			{
				trace("APWorld file found.");
				var apworld = haxe.Resource.getBytes("apworld");
				var installedApworld = File.getBytes(apWorldFile);
				if (apworld.compare(installedApworld) == 0) {
					trace("APWorld file matches the current version.");
					return {status: "exact", message: "APWorld file matches the current version."};
				} else {
					trace("APWorld file does not match the current version.");
					return {status: "outdated", message: "APWorld file does not match the current version."};
				}
			}
			else
			{
				trace("APWorld file not found.");
				return {status: "missing", message: "APWorld file not found."};
			}
		} catch (e:Dynamic) {
			trace("Error checking APWorld file: " + e);
			return {status: "error", message: "Error checking APWorld file: " + e};
		}
		#end
		return {status: "unsupported", message: "System not supported."};
	}

	public static function checkAndAlertAPWorld():Bool
	{
		return switch (checkAPWorld().status) {
			case "outdated":
				Application.current.window.alert("APWorld file does not match the current version.\nPlease update it in the AP Menu.", "APWorld Update Recommended");
				false;
			case "missing":
				Application.current.window.alert("APWorld file not found.\nPlease install it in the AP Menu.", "APWorld Missing");
				false;
			case "error":
				Application.current.window.alert("Error checking APWorld file.\nPlease try again.", "APWorld Error");
				false;
			case "unsupported":
				Application.current.window.alert("System not supported.\nYou cannot use AP on this System.", "Unsupported Error");
				true;
			case "exact":
				true;
			default:
				Application.current.window.alert("Unexpected status encountered.\nPlease report this issue.\nStatus = " + checkAPWorld().status, "Unexpected Error");
				false;
		};
	}

	public static function outputAPWorld():Void
	{
		#if sys
		// var programDataPath = "C:/ProgramData/Archipelago/";
		// var customWorldsPath = programDataPath + "custom_worlds/";
		// var apWorldFile = customWorldsPath + "fridaynightfunkin.apworld";

		trace("Outputting .apworld file.");
		var apworld = haxe.Resource.getBytes("apworld");
		File.saveBytes("fridaynightfunkin.apworld", apworld);
		trace("APWorld output success!");
		#end
	}


	public static function installAPWorld():Void
	{
		#if sys
		var programDataPath = currentAPLocation + "/";
		var launcherPath = programDataPath + "ArchipelagoLauncher.exe";
		var customWorldsPath = programDataPath + "custom_worlds/";
		var apWorldFile = customWorldsPath + "fridaynightfunkin.apworld";

		if (FileSystem.exists(launcherPath))
		{
			trace("ArchipelagoLauncher found. Installing or updating .apworld file.");
			// Create a temp file to run with the system.
			var apworld = haxe.Resource.getBytes("apworld");
			if (FileSystem.exists(apWorldFile)) {
				var installedApworld = File.getBytes(apWorldFile);
				if (apworld.compare(installedApworld) == 0) {
					trace("You already have this version of the APWorld.");
					Application.current.window.alert("You already have this version of the APWorld.", "APWorld Installation");
					return;
				}
			}
			File.saveBytes("fridaynightfunkin.apworld", apworld);

			Sys.command("cmd /c start fridaynightfunkin.apworld");

			while (!FileSystem.exists(apWorldFile)) {
				Sys.sleep(1); // Sleep for 1 second before checking again
			}

			while (true) {
				var installedApworld = File.getBytes(apWorldFile);
				if (apworld.compare(installedApworld) == 0) {
					try {
						FileSystem.deleteFile("fridaynightfunkin.apworld");
						trace("APWorld installed successfully.");
						break;
					} catch (e:Dynamic) {
						// trace("Failed to delete file: " + e);
					}
				} else {
					trace("Waiting for APWorld file to match the embedded one...");
					Sys.sleep(1); // Sleep for 1 second before checking again
					installedApworld = File.getBytes(apWorldFile);
				}
			}
		}
		else
		{
			trace("Archipelago was not found. Please install Archipelago to install the .apworld file.");
			Application.current.window.alert("Archipelago was not found. Please install Archipelago to install the .apworld file.
			\nNote: If your Archipelago Installation is not in the default location, use the \"Change AP Location\" button.", "APWorld Installation");
		}
		#end
	}
}

abstract APItemID(Int) from Int to Int {
	public function new(value:Int) {
		this = value;
	}

	public inline function get_name():String {
		return APInfo.ap.get_item_name(this);
	}

	public inline function get_id():Int {
		return this;
	}

		@:from public static inline function fromName(name:String):APItemID {
			return APInfo.ap.get_item_id(name);
		}
		@:to public static inline function toName(id:APItemID):String {
			return APInfo.ap.get_item_name(id);
		}
		@:to public inline function implToName():String {
			return APInfo.ap.get_item_name(this);
		}
}
