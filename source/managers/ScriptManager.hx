package managers;

/*
  SCRIPT MANAGER!

  This bad boy manages the scrips for the WHOLE engine. For example:

  * Handles all the HScripts
  * Handles all the LUA Scripts
  * Handels all the Modchart Variables from 0.6.x and later
  * Handels the V-Slice Scripts
  * Handels the Codename Scripts
  * Hamdels the FPS Plus Scripts (???)
  * Whatever else scripts do idk lol
*/

class ScriptManager {
  public static var instance:ScriptManager = null;

  #if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end
	public var yscriptArray:Array<YScript> = [];

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	#end

  public static var isLegacyLuaTest:Bool = false; // Flag to track if we're testing from Legacy Lua settings
}
