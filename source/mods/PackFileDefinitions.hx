package mods;

// Aight enough's enough im doing this now i dont care anymore
import haxe.Json;
import openfl.utils.Assets;

enum ModTypes {
  ONESHOT;
  FULLWEEK;
  FULLMOD;
  PORT;
  UI;
  MENU;
  ADDITION;
  MOD;
  CUSTOMIZE;
  OVERHAUL;
  CUSTOM;
  OTHER;
}

enum EngineTypes {
  MIXTAPE;
  PSYCH;
  PSYCH63;
  PSYCH73;
  PSYCHONLINE;
  PSLICE;
  PSYCHFORK;
  VSLICE;
  CODENAME;
  TROLL;
  NMV;
  FPS;
}

typedef MixtapeModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
  engine:Array<String>,
  activeDLC:Array<String>,
	all:Array<String>
}

typedef MixtapePackJSON = {
	var modName:String; // The name of the mod (default: folderName)
  var folderName:String; // The name of the folder this mod is in. This field will be filled automatically.
  var icon:String; // The icon this mod uses (default: "Unknown")
  var weekList:Array<String>; // Every week this mod has, so it can be sorted by mod in Story Mode (default: [])
  var songList:Array<String>; // Every song this mod has, for easy song collection (default: [])
  @:optional var playlists:Array<String>; // If this mod has any specific playlists. Will be empty or null otherwise
  var allowDLC:Bool; // If DLC should be allowed to be loaded within this mod (default: false)
  @:optional var dlcList:Array<String>; // The list of DLC's this mod has. Will be empty or null if there are none.
  @:optional var discordRPC:String; // The discord RPC, if your into tht kinda thing (default: "")
  @:optional var isFullMod:Bool; // If the mod should be considered an Engine Mod, which is a mod that modifies every level of the engine (default: false)
  var modType:ModTypes; // The type of mod it is, for organization sake (default: OTHER)
  var engineType:EngineTypes; // The original engine this mod is based off of, for ports n stuff (default: MIXTAPE)
  var description:String; // The description of the mod (default: "This is the mod of all time")
  var enabled:Bool; // If the mod is enabled or not (default: true)
  @:optional var apCompat:Bool; // If this mod should be allowed in AP (default: true)
  @:optional var isAPMod:Bool; // only shows up in AP mode (default: false)
  @:optional var needsReload:Bool; // If the game needs to reload when this specific mod is changed (default: false)
  @:optional var runsGlobally:Bool; // If the mod runs even when its not the main loaded mod (default: false)
}

typedef EnginePackJSON = {
	// I'll let yuta figure this one out
}
