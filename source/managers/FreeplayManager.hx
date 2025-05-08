package managers;

import flixel.util.FlxDestroyUtil;
import backend.WeekData;
import haxe.Json;
import backend.Song;
import states.CategoryState;

#if ARCHIPELAGO_ALLOWED
import archipelago.*;
#end
//Lets try this again


/*
    Ok im gonna try to explain what this is in the best way I can

    his is where any hardcoded freeplay menus you want to use will be called from (actually getting to the menu)
    Scripting support will eventually be added through this as well
    Speaking of, scripted freeplays will also be ran through this (unless a better system for them is made)
    For now, this is what this Freeplay Manager does:
    
    * Sends you to the proper freeplay that you select
    
    yeah that's literally it for now

    TODO: Might make this extend of MusicBeatState so that freeplay can extend off it
*/
class FreeplayManager {
    public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	public static var gfVocals:FlxSound = null;

    #if ARCHIPELAGO_ALLOWED
    public static var curUnlocked:Array<{song:String, mod:String}> = [];
	public static var curMissing:Array<{song:String, mod:String}> = [];
	public static var curHinted:Array<{song:String, mod:String}> = [];
	public static var hintTable:Map<String, String> = new Map<String, String>();
	public static var trueMissing:Array<String> = [];
	public static var unplayedList:Array<String> = [];
    public static var callVictory:Bool = false;
    #end

    /////////////////////////////////////////////////////FUNCTIONS///////////////////////////////////////////////////////////////////////////////

    public static function getFreeplay():Class<Dynamic>
    {
        return switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                states.freeplay.FreeplayState;
            case "Osu":
                states.freeplay.OsuFreeplayState;
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                states.freeplay.FreeplayState;
        }
        return states.freeplay.FreeplayState;
    }

    public static function getFreeplayState():Class<flixel.FlxState>
    {
        return switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                states.freeplay.FreeplayState;
            case "Osu":
                states.freeplay.OsuFreeplayState;
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                states.freeplay.FreeplayState;
        }
        return states.freeplay.FreeplayState;
    }

    public static function reloadFreeplay(refresh:Bool = false)
    {
        switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                if (states.freeplay.FreeplayState.instance != null)
                    states.freeplay.FreeplayState.instance.reloadSongs(true);
            case "Osu":
                /*if (states.freeplay.OsuFreeplayState.instance != null)
                    states.freeplay.OsuFreeplayState.instance.reloadSongs(true);*/
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                if (states.freeplay.FreeplayState.instance != null)
                    states.freeplay.FreeplayState.instance.reloadSongs(true);
        }
        return states.freeplay.OsuFreeplayState;
    }

    public static function getInstance()
    {
        return switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                states.freeplay.FreeplayState.instance;
            case "Osu":
                states.freeplay.OsuFreeplayState.instance;
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                states.freeplay.FreeplayState.instance;
        }
        return states.freeplay.FreeplayState.instance;
    }

    public static inline function openFreeplay()
	{
        if (CategoryState.loadWeekForce != null)
            FlxG.switchState(Type.createInstance(getFreeplay(), []));
        else //You cant play a song without picking a category first!
            FlxG.switchState(new states.CategoryState());
	}

    //Actual freeplay stuff
    public static function previewSong(needVoices) {
        if (needVoices)
        {
            vocals = new FlxSound();
            try
            {
                var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
                var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
                if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
                
                if(loadedVocals != null)
                {
                    vocals.loadEmbedded(loadedVocals);
                    FlxG.sound.list.add(vocals);
                    vocals.persist = vocals.looped = true;
                    vocals.volume = 0.8;
                    vocals.play();
                    vocals.pause();
                }
                else vocals = FlxDestroyUtil.destroy(vocals);
            }
            catch(e:Dynamic)
            {
                vocals = FlxDestroyUtil.destroy(vocals);
            }
            
            opponentVocals = new FlxSound();
            gfVocals = new FlxSound();
            try
            {
                //trace('please work...');
                var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
                var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
                var loadedgfVocals = Paths.voices(PlayState.SONG.song, 'gf');
                
                if(loadedVocals != null)
                {
                    opponentVocals.loadEmbedded(loadedVocals);
                    FlxG.sound.list.add(opponentVocals);
                    opponentVocals.persist = opponentVocals.looped = true;
                    opponentVocals.volume = 0.8;
                    opponentVocals.play();
                    opponentVocals.pause();
                    //trace('yaaay!!');
                }
                else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);

                if(loadedgfVocals != null)
                {
                    gfVocals.loadEmbedded(loadedgfVocals);
                    FlxG.sound.list.add(gfVocals);
                    gfVocals.persist = gfVocals.looped = true;
                    gfVocals.volume = 0.8;
                    gfVocals.play();
                    gfVocals.pause();
                    //trace('yaaay!!');
                }
                else gfVocals = FlxDestroyUtil.destroy(gfVocals);
            }
            catch(e:Dynamic)
            {
                //trace('FUUUCK');
                opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
                gfVocals = FlxDestroyUtil.destroy(gfVocals);
            }
        }

        FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
        FlxG.sound.music.pause();
        Conductor.bpm = PlayState.SONG.bpm;
    }

    public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

    static function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

    // Archipelago Stuff
    public static function isVictorySong(songName:String, modName:String):Bool {
		if (modName == null) modName = "";
		var locationId = songName;
		locationId += (modName.trim() != "") ? " (" + modName + ")" : "";
		return locationId.trim().toLowerCase().replace('-', ' ') == APEntryState.victorySong.trim().toLowerCase().replace('-', ' ');
	}

    // public static function addHint(song:String, item)
	public static function forceUnlockCheck(songName:String, modName:String):Void {
		trace("Starting forceUnlockCheck...");
		trace("Input songName: " + songName);
		trace("Input modName: " + modName);

		var locationId = songName;
		trace("Initial locationId: " + locationId);

		// if (modName.trim() != "") {
		// 	locationId += " (" + modName + ")";
		// 	trace("Updated locationId with modName: " + locationId);
		// }

		trace("Final locationId after trimming: " + locationId.trim());
		var locationIdInts = APEntryState.apGame.locationData(locationId.trim(), modName.trim()).concat(APEntryState.apGame.noteData(songName.trim(), modName.trim()));
		trace("Location IDs retrieved: " + locationIdInts);

		if (locationIdInts == null || locationIdInts.length == 0 || locationIdInts.indexOf(0) != -1) {
			trace("Location IDs are null, empty, or contain 0. Attempting fallback logic...");
			for (song in WeekData.getCurrentWeek().songs) {
				trace("Checking song in current week: " + song[0]);
				if ((cast song[0] : String).toLowerCase().trim() == PlayState.SONG.song.trim().toLowerCase() ||
					(cast song[0] : String).toLowerCase().trim().replace(" ", "-") == PlayState.SONG.song.trim().toLowerCase().replace(" ", "-")) {
					trace("Match found for song: " + song[0]);
					locationId = song[0];
					trace("Updated locationId in fallback logic: " + locationId);
					locationIdInts = APEntryState.apGame.locationData(locationId.trim(), modName);
					trace("Location IDs retrieved in fallback logic: " + locationIdInts);
					break;
				}
			}
		}

		if (locationIdInts == null || locationIdInts.length == 0 || locationIdInts.indexOf(0) != -1) {
			trace("Location IDs are still null, empty, or contain 0. Attempting secondary fallback logic...");
			for (song in WeekData.getCurrentWeek().songs) {
				trace("Checking song in secondary fallback logic: " + song[0]);
				var songPath = archipelago.APPlayState.currentMod.trim() != ""
					? "mods/" + archipelago.APPlayState.currentMod + "/data/" + song[0] + "/" + song[0] + "-" + Difficulty.getString(PlayState.storyDifficulty) + ".json"
					: "assets/shared/" + (song[0] + Difficulty.getFilePath());
				trace("Constructed songPath: " + songPath);

				var songJson:SwagSong = null;
				var jsonStuff:Array<String> = Paths.crawlDirectoryOG("mods/" + archipelago.APPlayState.currentMod + "/data", ".json");
				trace("Retrieved JSON files: " + jsonStuff);

				for (json in jsonStuff) {
					trace("Checking JSON file: " + json);
					if (json.trim().toLowerCase().replace(" ", "-") == songPath.trim().toLowerCase().replace(" ", "-")) {
						trace("Match found for JSON file: " + json);
						songJson = Song.parseJSON(File.getContent(json));
						if (songJson != null) {
							trace("Parsed song JSON successfully. Checking song name...");
							if (songJson.song.trim().toLowerCase().replace(" ", "-") == PlayState.SONG.song.trim().toLowerCase().replace(" ", "-")) {
								trace("Match found for song in JSON: " + songJson.song);
								locationId = song[0];
								trace("Updated locationId in secondary fallback logic: " + locationId);
								locationIdInts = APEntryState.apGame.locationData(locationId.trim(), modName);
								trace("Location IDs retrieved in secondary fallback logic: " + locationIdInts);
								break;
							}
						}
					} 
				}
			}
		}
		
		trace("Final locationIdInts: " + locationIdInts);
		for (locationIdInt in locationIdInts) {
			trace("Checking locationIdInt: " + locationIdInt);
			trace("Location check result: " + APEntryState.apGame.info().LocationChecks([locationIdInt]));
			trace("Location name: " + APEntryState.apGame.info().get_location_name(locationIdInt));
		}
		trace("Current song in PlayState: " + PlayState.SONG.song);

		archipelago.ArchPopup.startPopupCustom("You've sent " + APEntryState.apGame.info().get_location_name(locationIdInts[0]) + " to Archipelago!", "Good Job!", "archColor", function() {
			trace("Popup triggered for sending location to Archipelago.");
			FlxG.sound.playMusic(Paths.sound('secret'));
		});

		for (locationIdInt in locationIdInts) {
			trace("Processing locationIdInt for victory song check: " + locationIdInt);
			if (locationIdInt != 0 && FreeplayManager.isVictorySong(songName, modName)) {
				trace("Victory song condition met. Triggering victory popup...");
				archipelago.ArchPopup.startPopupCustom("You've completed your goal!", "You win!", "archipelago", function() {
					trace("Popup triggered for completing goal.");
					FlxG.sound.playMusic(Paths.sound('secret'));
				});
				APEntryState.apGame.info().set_goal();
				trace("Goal set in Archipelago.");
			}
		}

		trace("Reloading songs in FreeplayState instance...");
		reloadFreeplay(true);

		trace("Checking if the song is a victory song...");
		if (archipelago.APEntryState.apGame.checkGoal(songName, modName)) {
			archipelago.ArchPopup.startPopupCustom("Congratulations! You've achieved your goal!", "Well Done!", "archColor", function() {
				trace("Goal achievement popup triggered.");
				FlxG.sound.playMusic(Paths.sound('victory'));
			});
		}
	}
}