package archipelago;

import substates.RankingSubstate;

typedef SongDetailData = {
	id: Int,
	modded: Bool,
	playerOwner: String,
	sharedWith: Array<String>,
	songName: String
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
	songData: Map<String, SongDetailData>
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
			songData: new Map<String, SongDetailData>()
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
	public var songData(get, never):Map<String, SongDetailData>;

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
	private function get_songData():Map<String, SongDetailData> return this.songData;

	public function get(key:String):Dynamic {
		return Reflect.field(this, key);
	}

	public function set(key:String, value:Dynamic):Void {
		Reflect.setField(this, key, value);
	}

	public function hasKey(key:String):Bool {
		return Reflect.hasField(this, key);
	}
}
class APInfo {
	public static var ap:Client;
	public static var apGame:APGameState;

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

	public static var slotData(get, never):APSlotData;
	public static function get_slotData():APSlotData {
		return apGame?._slotData;
	}

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
		'Beat Battle 2'
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
    }


}