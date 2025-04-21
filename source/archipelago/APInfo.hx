package archipelago;

class APInfo {
    public static var ap:Client;
    public static var apGame:APGameState;

	public static var ticketCount:Int = 0;
	public static var ticketWinCount:Int = 1;

	public static var unlockMethod:String = "Song Completion";
	public static var unlockType:String = "Per Song";

	public static var hasNoteChecks(get, never):Bool;

	public static var hasSongChecks(get, never):Bool;

	public static var hintPoints(get, never):Int;
	public static var hintCost(get, never):Int;

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
		'Darnell Erect' //it could go here, it could go with pico, but for the sake of consistancy imma put it here
	];

	public static final basePico:Array<String> = 
	[
		'Darnell', 'Lit Up', '2Hot', 'Blazin',
		'Bopeebo (Pico mix)', 'Fresh (Pico mix)', 'Dad Battle (Pico mix)',
	 	'Spookeez (Pico mix)', 'South (Pico mix)',
	 	'Pico (Pico mix)', 'Philly Nice (Pico mix)', 'Blammed (Pico mix)',
	 	'Eggnog (Pico mix)', 'Cocoa (Pico mix)',
		'Senpai (Pico mix)', 'Roses (Pico mix)',
	 	'Ugh (Pico mix)', 'Guns (Pico mix)', 'Stress (Pico mix)'
	];

	public static final secrets:Array<String> = [
		'Small Argument', 
		'Beat Battle', 
		'Beat Battle 2'
	];
}