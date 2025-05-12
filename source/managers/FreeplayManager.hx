package managers;

import flixel.util.FlxDestroyUtil;
import backend.WeekData;
import haxe.Json;
import backend.Song;
import states.CategoryState;
import states.StoryMenuState;
import lime.utils.Assets;
import metadata.STMetaFile.MetadataFile;
import yutautil.AprilFools;

#if ARCHIPELAGO_ALLOWED
import archipelago.*;
import archipelago.PacketTypes.ClientStatus;
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

    static var songs:Array<GlobalSongMetadata> = [];
	public static var songList(get, never):Array<GlobalSongMetadata>;
	public static function get_songList():Array<GlobalSongMetadata> {
		return songs;
	}

    public static var metadata:Map<String, MetadataFile> = new Map<String, MetadataFile>();
    static var metadataFile:MetadataFile;
	var hasMetadataFile:Bool = false;

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

    static function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

    public static function reloadFreeplay(refresh:Bool = false, ?searchText:String = '')
    {
        trace("Reloading Songs!");
        songs = [];
        
        for (i in 0...WeekData.weeksList.length) {
            if(weekIsLocked(WeekData.weeksList[i]) && !APEntryState.inArchipelagoMode) continue;
            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

            function nullIfEmptyArray<T>(array:Array<T>):Null<Array<T>> {
                if (array == null || array.length == 0) {
                    return null;
                }
                return array;
            }

            WeekData.setDirectoryFromWeek(leWeek);
            for (song in leWeek.songs)
            {
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


                try {metadataFile = cast Json.parse(Assets.getText(Paths.json(Paths.formatToSongPath(song[0].toLowerCase()) + '/meta')));}
                catch(e) {
                    //trace("can't.");
                    metadataFile = null;
                }

                try
                {
                    metadata.set(song[0].toLowerCase(), cast metadataFile);
                    trace("Found metadata for " + song[0].toLowerCase());
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

                            for (songObj in FreeplayManager.curUnlocked)
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
                            for (songObj in FreeplayManager.curUnlocked)
                            {
                                if (songObj.song.trim().toLowerCase().replace('-', ' ') == songNameThing.trim().toLowerCase().replace('-', ' ') && leWeek.folder == songObj.mod)
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
                            for (songObj in FreeplayManager.curHinted)
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
                                for (songObj in FreeplayManager.curUnlocked)
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
                                for (songObj in FreeplayManager.curUnlocked)
                                {
                                    if (((songNameThing.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && leWeek.folder == songObj.mod) && !isMissing)
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
                                    if (locationIds != null && locationIds.isNotEmpty())
                                        addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                                }
                                else addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                            }
                        }
                    }
                }
            }
        }
            

        if (APEntryState.inArchipelagoMode)
        {
            if (refresh)
            {
                if (CategoryState.loadWeekForce == "all"){
                    //Add them to Wekk 7 so they're below that week
                    addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
                    addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                    addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                }
                else {
                    for (songObj in FreeplayManager.curUnlocked) {
                        if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'small argument'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '')
                            addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
                        if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '')
                            addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                        if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle 2'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '')
                            addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                    }	
                }
            }
            else
            {
                for (songObj in FreeplayManager.curUnlocked) {
                    if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'small argument'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '' && Std.string('Small Argument').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                        addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
                    if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '' && Std.string('Beat Battle').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                        addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                    if (songObj.song.trim().toLowerCase().replace('-', ' ') == 'beat battle 2'.trim().toLowerCase().replace('-', ' ') && songObj.mod == '' && Std.string('Beat Battle 2').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                        addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                }
            }
        }
        else
        {
            if (refresh)
            {
                if (FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                    addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
                if (FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                    addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                    addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
            }
            else
            {
                if (Std.string('Small Argument').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                    addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
                if (Std.string('Beat Battle').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                    addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (Std.string('Beat Battle 2').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
                    addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
            }
        }

        for (song in ["Beat Battle", "Beat Battle 2", "Small Argument"]) {
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
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                if (states.freeplay.FreeplayState.instance != null)
                    states.freeplay.FreeplayState.instance.reloadSongs(true);
        }
        return states.freeplay.OsuFreeplayState;
    }

    public static function addSong(songName:String, weekNum:Int, songCharacter:String, color:Array<Array<Dynamic>>)
	{
		songs.push(new GlobalSongMetadata(songName, weekNum, songCharacter, color));
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
        if (CategoryState.loadWeekForce != null && !states.PlayState.Crashed) {
            MusicBeatState.preloadAndSwitchState(Type.createInstance(getFreeplay(), []));
    } else if (CategoryState.loadWeekForce != null && states.PlayState.Crashed) {
            FlxG.switchState(Type.createInstance(getFreeplay(), []));
    }
        else //You cant play a song without picking a category first!
            FlxG.switchState(new states.CategoryState());

        if (FlxG.sound.music == null || !FlxG.sound.music.playing)
            MusicManager.playMenuMusic();
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

    public static function checkSongStatus() {
        trueMissing = [];
        unplayedList = [];
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
                    color = isMissing ? FlxColor.RED : FlxColor.GREEN;

                    
                    someLocationsNotMissing = isMissing && [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].contains(false);

                    for (songObj in curUnlocked)
                    {
                        if (((songName.trim().toLowerCase().replace('-', ' ') == songObj.song.trim().toLowerCase().replace('-', ' ')) && modName == songObj.mod) && isMissing) {
                            color = someLocationsNotMissing ? FlxColor.GRAY : FlxColor.WHITE;
                            unplayedList.push(songName);
                        }
                    }

                    if (!unplayedList.contains(songName) && isMissing) {
                        trueMissing.push(songName);
                    }
                }

                FreeplayManager.callVictory = FreeplayManager.isVictorySong(songName, modName) && !isMissing && !someLocationsNotMissing;

                if (FreeplayManager.callVictory) {
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
		APEntryState.apGame.info().Say("!release");
		APEntryState.apGame.info().Say("!collect");
		APEntryState.apGame.info().poll();
	}
}

class GlobalSongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Array<Array<Dynamic>> = [];
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Array<Array<Dynamic>>)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
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