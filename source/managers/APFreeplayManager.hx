package managers;

import backend.Song;
import backend.WeekData;
import haxe.Json;
import lime.utils.Assets;
import managers.FreeplayManager;
import states.CategoryState;
import states.freeplay.FreeplayState;

#if ARCHIPELAGO_ALLOWED
import archipelago.*;
import archipelago.HighQualityTrapManager;
import archipelago.PacketTypes.ClientStatus;
#end


/*
    Basically FreeplayManager but specifically for AP
    just a way to separate Archipelago from the main stuff so it doesn't get affected by AP's bull
*/

// SongInfo structure as typedef
typedef SongInfo = {
    var song:String;
    var mod:String;
    var unlocked:Bool;
    var missing:Bool;
    var hinted:Bool;
    var otherData:Dynamic;
}

abstract APSongData(SongInfo) {
    // SongInfo holds all relevant data for a song
    public static function create(song:String, mod:String, unlocked:Bool, missing:Bool, hinted:Bool, otherData:Dynamic):APSongData {
        return new APSongData({song: song, mod: mod, unlocked: unlocked, missing: missing, hinted: hinted, otherData: otherData});
    }

    public function new(data:SongInfo) {
        this = data;
    }

    public var song(get, never):String;
    public var mod(get, never):String;
    public var unlocked(get, never):Bool;
    public var missing(get, never):Bool;
    public var hinted(get, never):Bool;
    public var otherData(get, never):Dynamic;

    inline function get_song():String return this.song;
    inline function get_mod():String return this.mod;
    inline function get_unlocked():Bool return this.unlocked;
    inline function get_missing():Bool return this.missing;
    inline function get_hinted():Bool return this.hinted;
    inline function get_otherData():Dynamic return this.otherData;


}
class APFreeplayManager extends FreeplayManager {
    #if ARCHIPELAGO_ALLOWED
    public static var curUnlocked:Array<{song:String, mod:String}> = [];
	public static var curMissing:Array<{song:String, mod:String}> = [];
	public static var curHinted:Array<{song:String, mod:String}> = [];
	public static var hintTable:Map<String, Array<String>> = new Map<String, Array<String>>();
	public static var trueMissing:Array<{song:String, mod:String}> = [];
	public static var unplayedList:Array<{song:String, mod:String}> = [];
    public static var callVictory:Bool = false;
    var apSongData = archipelago.APInfo.apGame?.getSongsAndModsFromArray(archipelago.APInfo.slotData.selectedSongs).map(function(songData):{song:String, mod:String} {
        return if (songData.mod == null) {
            {song: songData.song, mod: ''}
        } else {
            {song: songData.song, mod: songData.mod}
        };
    });

    #end

    /////////////////////////////////////////////////////FUNCTIONS///////////////////////////////////////////////////////////////////////////////

    // Archipelago Stuff
    public static function isVictorySong(songName:String, modName:String):Bool {
		if (modName == null) modName = "";
		var locationId = songName;
		locationId += (modName.trim() != "") ? " (" + modName + ")" : "";
		return locationId.trim().toLowerCase().replace('-', ' ') == APEntryState.victorySong.trim().toLowerCase().replace('-', ' ');
	}

	/**
	 * Get hints for a specific song
	 * @param songName The song name
	 * @param modName The mod name (can be null or empty)
	 * @return Array of hint strings, empty if no hints
	 */
	public static function getHintsForSong(songName:String, modName:String):Array<String> {
		if (modName == null) modName = "";

		// Create the full song identifier used in hint storage
		var fullSongName = songName;
		if (modName.trim() != "") {
			fullSongName += " (" + modName + ")";
		}

		if (hintTable.exists(fullSongName)) {
			return hintTable.get(fullSongName).copy(); // Return copy to prevent external modification
		}

		return []; // No hints found
	}

	/**
	 * Check if a song has any hints available
	 * @param songName The song name
	 * @param modName The mod name (can be null or empty)
	 * @return True if hints exist, false otherwise
	 */
	public static function hasHintsForSong(songName:String, modName:String):Bool {
		return getHintsForSong(songName, modName).length > 0;
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

		// Check and send sanity item location checks related to this song
		#if ARCHIPELAGO_ALLOWED
		trace("Checking for sanity item location checks...");
		var sanityLocationIds = APEntryState.apGame.getSanityLocationsForSong(songName.trim(), modName.trim());
		if (sanityLocationIds != null && sanityLocationIds.length > 0) {
			trace("Found " + sanityLocationIds.length + " sanity location checks for this song");
			for (sanityLocationId in sanityLocationIds) {
				if (sanityLocationId != 0) {
					trace("Sending sanity location check: " + sanityLocationId);
					trace("Sanity location name: " + APEntryState.apGame.info().get_location_name(sanityLocationId));
					APEntryState.apGame.info().LocationChecks([sanityLocationId]);
				}
			}
		} else {
			trace("No sanity location checks found for this song");
		}
		#end

		archipelago.ArchPopup.startPopupCustom("You've sent " + APEntryState.apGame.info().get_location_name(locationIdInts[0]) + " to Archipelago!", "Good Job!", "archColor", function() {
			trace("Popup triggered for sending location to Archipelago.");
			FlxG.sound.playMusic(Paths.sound('secret'));
		});

		for (locationIdInt in locationIdInts) {
			trace("Processing locationIdInt for victory song check: " + locationIdInt);
			if (locationIdInt != 0 && isVictorySong(songName, modName)) {
				trace("Victory song condition met. Triggering victory popup...");
				archipelago.ArchPopup.startPopupCustom("You've completed your goal!", "You win!", "archipelago", function() {
					trace("Popup triggered for completing goal.");
					FlxG.sound.playMusic(Paths.sound('secret'));
				});
				APEntryState.apGame.info().set_goal();
				trace("Goal set in Archipelago.");
			}
		}

		trace("Reloading songs in FreeplayManager instance...");
		FreeplayManager.instance.reloadFreeplay(true);

		trace("Checking if the song is a victory song...");
		if (archipelago.APEntryState.apGame.checkGoal(songName, modName)) {
			archipelago.ArchPopup.startPopupCustom("Congratulations! You've achieved your goal!", "Well Done!", "archColor", function() {
				trace("Goal achievement popup triggered.");
				FlxG.sound.playMusic(Paths.sound('victory'));
			});
		}
	}


    public static function cleanup() {
        curUnlocked = [];
        curMissing = [];
        curHinted = [];
        hintTable = new Map<String, Array<String>>();
        trueMissing = [];
        unplayedList = [];
        callVictory = false;
        trace("APFreeplayManager cleaned up.");
    }

    public static function checkSongStatus() {
        trueMissing = [];
        unplayedList = [];

        // Preform a separate check for these 3 because they're not an actual file
        for (song in ["Beat Battle", "Beat Battle 2", "Small Argument", "GeoStar"]) {
            var songName:String = '';
            var modName:String = '';
            var locationId:Array<Int> = [];
            var isMissing:Bool = false;
            var color:FlxColor = 0xFFFFFFFF;
            var someLocationsNotMissing:Bool = false;

            if (APEntryState.inArchipelagoMode) {
                songName = song;
                modName = '';
                locationId = APEntryState.apGame.locationData(songName, modName).concat(APEntryState.apGame.noteData(songName, modName));
                isMissing = [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].indexOf(true) != -1 || locationId.length == 0;

                // Check if song is unlocked
                var isUnlocked = [for (songObj in curUnlocked) songObj.song.trim().toLowerCase().replace('-', ' ') == songName.trim().toLowerCase().replace('-', ' ') && songObj.mod == modName].length > 0;

                // Color logic: RED = missing, WHITE = unlocked but not checked, GREEN = checked
                color = isMissing ? FlxColor.RED : (isUnlocked ? FlxColor.GREEN : FlxColor.WHITE);


                someLocationsNotMissing = isMissing && [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].contains(false);

                for (songObj in curUnlocked)
                {
                    if (((songName.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && modName == songObj.mod) && isMissing) {
                        color = someLocationsNotMissing ? FlxColor.GRAY : FlxColor.WHITE;
                        unplayedList.push(songObj);
                    }
                }

                if (!unplayedList.arrayContainsObject({song: songName, mod: modName}) && isMissing) {
                    color = someLocationsNotMissing ? FlxColor.GRAY : FlxColor.WHITE;
                    trueMissing.push({song: songName, mod: modName});
                }
            }

            callVictory = isVictorySong(songName, modName) && !isMissing && !someLocationsNotMissing;

            if (callVictory) {
                trace("Apparently, the victory song has been cleared, so... Goaling!");
                APEntryState.apGame.checkGoal(songName, modName);
            }
        }

        for (i in 0...WeekData.weeksList.length) {
            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            WeekData.setDirectoryFromWeek(leWeek);
            for (song in leWeek.songs)
            {
                var songName:String = '';
                var modName:String = '';
                var locationId:Array<Int> = [];
                var isMissing:Bool = false;
                var color:FlxColor = 0xFFFFFFFF;
                var someLocationsNotMissing:Bool = false;

                if (APEntryState.inArchipelagoMode) {
                    songName = song[0];
                    modName = leWeek.folder;
                    locationId = APEntryState.apGame.locationData(songName, modName).concat(APEntryState.apGame.noteData(songName, modName));
                    isMissing = [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].indexOf(true) != -1 || locationId.length == 0;

                    // Check if song is unlocked
                    var isUnlocked = [for (songObj in curUnlocked) songObj.song.trim().toLowerCase().replace('-', ' ') == songName.trim().toLowerCase().replace('-', ' ') && songObj.mod == modName].length > 0;

                    // Color logic: RED = missing, WHITE = unlocked but not checked, GREEN = checked
                    color = isMissing ? FlxColor.RED : (isUnlocked ? FlxColor.GREEN : FlxColor.WHITE);


                    someLocationsNotMissing = isMissing && [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].contains(false);

                    for (songObj in curUnlocked)
                    {
                        if (((songName.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && modName == songObj.mod) && isMissing) {
                            color = someLocationsNotMissing ? FlxColor.GRAY : FlxColor.WHITE;
                            unplayedList.push(songObj);
                        }
                    }

                    if (!unplayedList.arrayContainsObject({song: songName, mod: modName}) && isMissing) {
                        trueMissing.push({song: songName, mod: modName});
                    }
                }

                callVictory = isVictorySong(songName, modName) && !isMissing && !someLocationsNotMissing;

                if (callVictory) {
                    trace("Apparently, the victory song has been cleared, so... Goaling!");
                    APEntryState.apGame.checkGoal(songName, modName);
                }
            }
        }
    }

    public static function checkVictory() {
        // Check if the Victory Song is cleared.
        var victorySong = APEntryState.apGame?.getSongAndMod(APEntryState.victorySong);
        if (APEntryState.apGame?.checkGoal(victorySong.song, victorySong.mod))
            trace("Victory song is cleared!");
    }

    #if ARCHIPELAGO_ALLOWED
    /**
     * Get available difficulties for a specific song, considering SiivaGunner trap
     */
    public static function getAvailableDifficultiesForSong(songName:String, modName:String):Array<String> {
        if (HighQualityTrapManager.isTrapInUse()) {
            var siivaDiffs = HighQualityTrapManager.getAvailableDifficulties(songName, modName);
            if (siivaDiffs != null && siivaDiffs.length > 0) {
                return siivaDiffs.copy();
            }
        }

        // Fallback to default difficulties
        return backend.Difficulty.defaultList.copy();
    }

    /**
     * Check if a difficulty is available for a specific song, considering SiivaGunner trap
     */
    public static function isDifficultyAvailableForSong(songName:String, modName:String, difficulty:String):Bool {
        if (HighQualityTrapManager.isTrapInUse()) {
            return HighQualityTrapManager.isDifficultyAvailable(songName, modName, difficulty);
        }

        return true; // If trap is not in use, all difficulties are available
    }

    /**
     * Get the actual song name to use (considering SiivaGunner replacements)
     */
    public static function getActualSongName(originalSong:String, modName:String):String {
        if (HighQualityTrapManager.isTrapInUse()) {
            return HighQualityTrapManager.getReplacementSong(originalSong, modName);
        }

        return originalSong;
    }
    #end

    public static function updateArchFreeplay() {
        if (APEntryState.apGame != null && APEntryState.apGame.info() != null) {
			var checker = archipelago.APGameState.instance?.info();
			checker.poll();
			checker.Get(['_read_hints_${checker.team}_${checker.slotnr}']);

			APEntryState.apGame.info().Sync();
			APEntryState.gonnaRunSync = false;

			function getLastParenthesesContent(input:String):String {
				var lastParenIndex = input.lastIndexOf("(");
				if (lastParenIndex != -1) {
					var endIndex = input.indexOf(")", lastParenIndex);
					if (endIndex != -1) {
						return input.substring(lastParenIndex + 1, endIndex);
					}
				}
				return "";
			}

			if (curUnlocked.contains(APEntryState.apGame.getSongAndMod(APEntryState.victorySong)) && callVictory)
			{
				trace("GOAL COMPLETE");
				callVictory = false;
				APEntryState.apGame.info().clientStatus = ClientStatus.GOAL;
				FlxG.state.openSubState(new Prompt("Congradulations! You Win!", 0,
				function()
				{
					collectAndRelease();
					MusicBeatState.switchState(new APEntryState());
					APEntryState.inArchipelagoMode = false;
				},
				function()
				{
					collectAndRelease();
					MusicBeatState.switchState(new states.MainMenuState());
					APEntryState.inArchipelagoMode = false;
				}, false, "Return to Archipelago Menu", "Return to Main Menu"));
			}
		}
    }

    static function collectAndRelease()
	{
        trace("Do not actually do this in multiplayer lmao"); return;
		APEntryState.apGame.info().Say("!release");
		APEntryState.apGame.info().Say("!collect");
		APEntryState.apGame.info().poll();
	}

    var songsHidden:Bool = archipelago.APItem.unknownSongs;
	override public function reloadFreeplay(refresh:Bool = false, searchText:String = '')
    {
        trace("Reloading Songs!");
        songs = [];
        songsHidden = archipelago.APItem.unknownSongs;

        // Check all current allowed songs and make sure there's no duplicates.
        if (curUnlocked != null) {
            var seen = new Map<String, Bool>();
            curUnlocked = curUnlocked.filter(function(songObj) {
                var key = songObj.song + "|" + songObj.mod;
                if (!seen.exists(key)) {
                    seen.set(key, true);
                    return true;
                }
                return false;
            });
        }

        for (i in 0...WeekData.weeksList.length) {
            if(weekIsLocked(WeekData.weeksList[i]) && !APEntryState.inArchipelagoMode) continue;
            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

            var categoryWhaat:Array<String> = Std.isOfType(leWeek.category, String) ?
                    (cast leWeek.category:String).split(',').map(function(cat:String):String {
                        return cat.trim().toLowerCase();
                    }) : Std.isOfType(leWeek.category, Array) ?
                    (cast leWeek.category:Array<String>).map(function(cat:String):String {
                        return cat.trim().toLowerCase();
                    }) :
                    [(cast leWeek.category:String)].map(function(cat:String):String {
                        return cat.trim().toLowerCase();
                    });


            function nullIfEmptyArray<T>(array:Array<T>):Null<Array<T>> {
                if (array == null || array.length == 0) {
                    return null;
                }
                return array;
            }


            WeekData.setDirectoryFromWeek(leWeek);
            var allowedSongs:Array<Dynamic> = [for (song in leWeek.songs) {
                for (songData in apSongData) {
                    if (songData.song == song[0] && songData.mod == leWeek.folder) {
                        song;
                    }
                }
            }];

            #if ARCHIPELAGO_ALLOWED
            // Apply High Quality Trap filtering if in use
            if (HighQualityTrapManager.isTrapInUse()) {
                var originalSongs = allowedSongs.copy();

                // Convert allowedSongs format to {song:String, mod:String} format for filtering
                var convertedSongs:Array<{song:String, mod:String}> = [];
                for (song in originalSongs) {
                    convertedSongs.push({song: song[0], mod: leWeek.folder});
                }

                var filteredSongs = HighQualityTrapManager.filterUnlockedSongsForSiiva(convertedSongs);

                // Convert back to original format
                allowedSongs = [];
                for (songData in filteredSongs) {
                    // Find the original song data to preserve format
                    for (originalSong in originalSongs) {
                        if (originalSong[0] == songData.song) {
                            allowedSongs.push(originalSong);
                            break;
                        }
                    }
                }

                // If no songs remain after filtering, try to get a random SiivaGunner song
                if (allowedSongs.length == 0 && originalSongs.length > 0) {
                    var randomSiivaSong = HighQualityTrapManager.getRandomSiivaSong();
                    if (randomSiivaSong != null) {
                        // Convert to the expected format: [songName, icon, colors]
                        allowedSongs = [[randomSiivaSong.song, "bf", [146, 113, 253]]];
                    }
                }

                // Also set up difficulty list for the week if SiivaGunner content is available
                if (allowedSongs.length > 0 && HighQualityTrapManager.hasSiivaContentForMod(leWeek.folder)) {
                    // Update week difficulties to SiivaGunner difficulties
                    var firstSong = allowedSongs[0][0];
                    var siivaDiffs = HighQualityTrapManager.getAvailableDifficulties(firstSong, leWeek.folder);
                    if (siivaDiffs != null && siivaDiffs.length > 0) {
                        // Create a temporary difficulties string for this week
                        leWeek.difficulties = siivaDiffs.join(',');
                    }
                }
            }
            #end

            for (song in allowedSongs)
            {

                if (categoryWhaat.length == 1 && categoryWhaat[0] == "" || categoryWhaat.length == 0) {
                    categoryWhaat = [];
                }

                // trace("CategoryWhaat2: " + categoryWhaat);
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3)
                {
                    colors = [146, 113, 253];
                }

                //This is for later
                var musician:String = 'unknown';
                if (FileSystem.exists(Paths.json(song[0].toLowerCase() + "/credits")))
                musician = File.getContent((Paths.json(song[0].toLowerCase() + "/credits")));


                try {metadataFile = cast Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(song[0].toLowerCase()) + '/meta')));}
                catch(e) {
                    //trace("can't.");
                    metadataFile = null;
                }

                try
                {
                    metadata.set(song[0].toLowerCase(), cast metadataFile);
                    //trace("Found metadata for " + song[0].toLowerCase());
                }
                catch (e)
                {
                    /*try
                    {
                        trace("No metadata for " + song[0].toLowerCase());
                    }
                    catch (e)
                    {
                        trace("No metadata found. No song either apparently.");
                    }*/
                }

                if ((ClientPrefs.data.showMods && leWeek.folder.toLowerCase() == CategoryState.loadWeekForce.toLowerCase()) || (CategoryState.loadWeekForce == "all" && (searchText == null || searchText == '') && (leWeek.folder != '' || leWeek.folder != null) && !APEntryState.inArchipelagoMode))
                {
                    addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                }
                else if (categoryWhaat.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && categoryWhaat.isEmpty()) || (CategoryState.loadWeekForce == "all" || APEntryState.inArchipelagoMode))
                {
                    if (refresh)
                    {
                        var colors:Array<Int> = song[2];
                        if(colors == null || colors.length < 3)
                        {
                            colors = [146, 113, 253];
                        }
                        if (CategoryState.loadWeekForce == "unplayed")
                        {
                            var songNameThing:String = song[0];
                            var modName:String = leWeek.folder;
                            var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));
                            var isMissing:Bool = APEntryState.apGame.areLocationsMissing(locationIds);

                            if (locationIds.isEmpty())
                            {
                                continue;
                            }

                            for (songObj in curUnlocked)
                            {
                                if (songObj.song.trim().toLowerCase().replace('-', ' ') == songNameThing.trim().toLowerCase().replace('-', ' ') && leWeek.folder == songObj.mod && isMissing)
                                    addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                            }
                        }
                        else if (CategoryState.loadWeekForce == "unlocked")
                        {
                            var songNameThing:String = song[0];
                            var modName:String = leWeek.folder;
                            var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));
                            var isMissing:Bool = APEntryState.apGame.areLocationsMissing(locationIds);

                            if (locationIds.isEmpty())
                            {
                                continue;
                            }
                            for (songObj in curUnlocked)
                            {
                                if (songObj.song.trim().toLowerCase().replace('-', ' ') == songNameThing.trim().toLowerCase().replace('-', ' ') && leWeek.folder == songObj.mod && !isMissing)
                                    addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                            }
                        }
                        else if (CategoryState.loadWeekForce == 'hinted')
                        {
                            var songNameThing:String = song[0];
                            var modName:String = leWeek.folder;
                            var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));
                            var isMissing:Bool = APEntryState.apGame.areLocationsMissing(locationIds);

                            if (locationIds.isEmpty())
                            {
                                continue;
                            }
                            for (songObj in curHinted)
                            {
                                if (((songNameThing.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && leWeek.folder == songObj.mod) && isMissing)
                                    addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                            }

                        }
                        else if (categoryWhaat.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && categoryWhaat.isEmpty()) || CategoryState.loadWeekForce == "all")
                        {
                            if (APEntryState.inArchipelagoMode)
                            {
                                var songNameThing:String = song[0];
                                var modName:String = leWeek.folder;
                                var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));

                                if (locationIds.isEmpty())
                                {
                                    continue;
                                }
                                if (locationIds != null && locationIds.isNotEmpty())
                                    addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                            }
                            else addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                        }

                    }
                    else
                    {
                        if (Std.string(song[0]).toLowerCase().trim().contains(searchText.toLowerCase().trim()))
                        {
                            var colors:Array<Int> = song[2];
                            if(colors == null || colors.length < 3)
                            {
                                colors = [146, 113, 253];
                            }

                            if (CategoryState.loadWeekForce == "unplayed")
                            {
                                var songNameThing:String = song[0];
                                var modName:String = leWeek.folder;
                                var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));
                                var isMissing:Bool = APEntryState.apGame.areLocationsMissing(locationIds);
                                for (songObj in curUnlocked)
                                {
                                    if (((songNameThing.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && leWeek.folder == songObj.mod) && isMissing)
                                        addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                                }
                            }
                            else if (CategoryState.loadWeekForce == "unlocked")
                            {
                                var songNameThing:String = song[0];
                                var modName:String = leWeek.folder;
                                var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));
                                var isMissing:Bool = APEntryState.apGame.areLocationsMissing(locationIds);
                                for (songObj in curUnlocked)
                                {
                                    if (((songNameThing.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && leWeek.folder == songObj.mod) && !isMissing)
                                        addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                                }
                            }
							else if (CategoryState.loadWeekForce == 'hinted')
							{
								var songNameThing:String = song[0];
								var modName:String = leWeek.folder;
								var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));
								var isMissing:Bool = APEntryState.apGame.areLocationsMissing(locationIds);

								if (locationIds.isEmpty())
									continue;

								for (songObj in curHinted)
								{
									if (((songNameThing.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && leWeek.folder == songObj.mod) && isMissing)
										addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
								}

							}
                            else if (categoryWhaat.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && categoryWhaat.isEmpty()) || CategoryState.loadWeekForce == "all")
                            {
                                var songNameThing:String = song[0];
								var modName:String = leWeek.folder;
								var locationIds:Null<Array<Int>> = APEntryState.apGame.locationData(songNameThing, modName).concat(APEntryState.apGame.noteData(songNameThing, modName));
								if (locationIds != null && locationIds.isNotEmpty())
									addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                            }
                        }
                    }
                }
            }
        }


        Mods.currentModDirectory = '';

        #if ARCHIPELAGO_ALLOWED
        // Apply High Quality Trap filtering to curUnlocked if in use
        var processedUnlocked = APFreeplayManager.curUnlocked.copy();
        if (HighQualityTrapManager.isTrapInUse()) {
            var originalUnlocked = processedUnlocked.copy();
            processedUnlocked = HighQualityTrapManager.filterUnlockedSongsForSiiva(processedUnlocked);

            // If no songs remain after filtering, try to get a random SiivaGunner song
            if (processedUnlocked.length == 0 && originalUnlocked.length > 0) {
                var randomSiivaSong = HighQualityTrapManager.getRandomSiivaSong();
                if (randomSiivaSong != null) {
                    // Convert the random song to the expected format
                    processedUnlocked = [{song: randomSiivaSong.song, mod: randomSiivaSong.mod}];
                }
            }
        }
        #else
        var processedUnlocked = APFreeplayManager.curUnlocked.copy();
        #end

        if (refresh)
		{
			for (songObj in processedUnlocked) {
				if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'small argument'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '')
					addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
				if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '')
					addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
				if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle 2'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '')
					addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'geostar'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '')
					addSong('GeoStar', 7, "ElCaption", [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
			}
		}
		else
		{
			for (songObj in processedUnlocked) {
				if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'small argument'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '' && Std.string('Small Argument').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
					addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
				if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '' && Std.string('Beat Battle').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
					addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
				if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle 2'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '' && Std.string('Beat Battle 2').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
					addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'geostar'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '' && Std.string('GeoStar').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
					addSong('GeoStar', 7, "ElCaption", [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
			}
		}

        for (song in ["Beat Battle", "Beat Battle 2", "Small Argument", "GeoStar"]) {
            try {metadataFile = cast Json.parse(Assets.getText(Paths.json(Paths.formatToSongPath(song.toLowerCase()) + '/meta')));}
            catch(e) {
                //trace("can't.");
                metadataFile = null;
            }

            try
            {
                metadata.set(song.toLowerCase(), cast metadataFile);
                //trace("Found metadata for " + song.toLowerCase());
            }
            catch (e)
            {
                try
                {
                    //trace("No metadata for " + song.toLowerCase());
                }
                catch (e)
                {
                    //trace("No metadata found. No song either apparently.");
                }
            }
        }

        switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                if (states.freeplay.FreeplayState.instance != null)
                    states.freeplay.FreeplayState.instance.reloadSongs(true);
            case "Osu":
                @:privateAccess
                if (states.freeplay.OsuFreeplayState.instance != null)
                    states.freeplay.OsuFreeplayState.instance.loadSongArray(false);
            case "Base Game":
                if (states.freeplay.VSliceFreeplayState.instance != null)
                    states.freeplay.VSliceFreeplayState.instance.generateSongList(null, false);
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                if (states.freeplay.FreeplayState.instance != null)
                    states.freeplay.FreeplayState.instance.reloadSongs(true);
        }
    }
}

class VictorySong extends DynamicColoredAlphabet
{

	public function new(x:Float, y:Float, text:String, color:Int, preserve:Bool)
	{
		super(x, y, text, color, preserve);
	}

	var e:Int = 0;

	override function update(elapsed:Float)
	{
		e++;
		super.update(elapsed);
		this.color = FlxColor.fromHSL(((e / 2) / 300 * 360) % 360, 1.0, 0.5 * 1.0);
	}
}
