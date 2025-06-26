package archipelago;

import substates.RankingSubstate;
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