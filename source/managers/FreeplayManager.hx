package managers;

import backend.Song;
import backend.WeekData;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import lime.utils.Assets;
import metadata.STMetaFile.FreeplayMetaJSON;
import metadata.STMetaFile.MetadataFile;
import states.CategoryState;
import states.PlayState;
import states.StoryMenuState;
import yutautil.AprilFools;

#if ARCHIPELAGO_ALLOWED
import archipelago.*;
import archipelago.PacketTypes.ClientStatus;
#end
//Lets try this again

/**
    Ok im gonna try to explain what this is in the best way I can

    This is where any hardcoded freeplay menus you want to use will be called from (actually getting to the menu)
    Scripting support will eventually be added through this as well
    Speaking of, scripted freeplays will also be ran through this (unless a better system for them is made)
    For now, this is what this Freeplay Manager does:

    ** Sends you to the proper freeplay that you select
    ** Loads the list for freeplay
    ** enables multiple diferent styled menus that can all act the same, as they would all be ran through this
    ** enables the ability to have cutsom freeplays without the large chunks of "load the entire song list" code
    ** does other things too

    TODO: Might make this extend of MusicBeatState so that freeplay can extend off it
**/
class FreeplayManager {
    public static var instance:FreeplayManager;

    public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	public static var gfVocals:FlxSound = null;

    var songs:Array<GlobalSongMetadata> = [];
	public var songList(get, never):Array<GlobalSongMetadata>;
	public function get_songList():Array<GlobalSongMetadata> {
		return songs;
	}

    public var metadata:Map<String, MetadataFile> = new Map<String, MetadataFile>();
    var metadataFile:MetadataFile;
    var pMetadataFile:FreeplayMetaJSON;
	var hasMetadataFile:Bool = false;

    public function new() {
        instance = this;
    }

    /////////////////////////////////////////////////////FUNCTIONS///////////////////////////////////////////////////////////////////////////////
    public static function loadFPManager() {
        #if ARCHIPELAGO_ALLOWED
        return switch (APEntryState.inArchipelagoMode) {
            case true:
                if (instance != null && Std.isOfType(instance, APFreeplayManager)) {
                    trace("Using existing APFreeplayManager instance.");
                    return instance;
                } else {
                    trace("Creating new APFreeplayManager instance.");
                    return instance = new APFreeplayManager();
                }
            case false:
                if (instance != null && !Std.isOfType(instance, FreeplayManager)) {
                    trace("Using existing FreeplayManager instance.");
                    return instance;
                } else {
                    trace("Creating new FreeplayManager instance.");
                    return instance = new FreeplayManager();
                }
        }
        #else
        return switch (instance != null && Std.isOfType(instance, FreeplayManager)) {
            case true:
                trace("Using existing FreeplayManager instance.");
                instance;
            case false:
                trace("Creating new FreeplayManager instance.");
                instance = new FreeplayManager();
        }
        #end
    }

    //Static things

    public static function getFreeplay():Class<Dynamic>
    {
        return switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                states.freeplay.FreeplayState;
            case "Osu":
                states.freeplay.OsuFreeplayState;
            default:
                if (ClientPrefs.data.freeplayMenu == "Base Game") {
                    FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                    return states.freeplay.FreeplayState;
                }
                new states.freeplay.CustomFreeplayState(Paths.mods(ClientPrefs.data.freeplayMenu));
                states.freeplay.CustomFreeplayState;
        }
        return states.freeplay.FreeplayState;
    }

    public static function getFreeplayState():Class<flixel.FlxState>
    {
        // Check if we should return to Legacy Lua settings instead of normal freeplay
        if (PlayState.isLegacyLuaTest) {
            PlayState.isLegacyLuaTest = false; // Reset the flag
            return options.legacylua.LegacyLuaFreeplayState;
        }

        return switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                states.freeplay.FreeplayState;
            case "Osu":
                states.freeplay.OsuFreeplayState;
            default:
                if (ClientPrefs.data.freeplayMenu == "Base Game") {
                    FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                    return states.freeplay.FreeplayState;
                }
                states.freeplay.CustomFreeplayState;
        }
        return states.freeplay.FreeplayState;
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

    //Public things

    public function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

    public function reloadFreeplay(refresh:Bool = false, ?searchText:String = '')
    {
        trace("Reloading Songs!");
        songs = [];

        for (i in 0...WeekData.weeksList.length) {
            if(weekIsLocked(WeekData.weeksList[i])) continue;
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


                try {metadataFile = cast Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(song[0].toLowerCase()) + '/meta')));}
                catch(e) {
                    //trace("can't.");
                    metadataFile = null;
                }

                try {
                    pMetadataFile = new FreeplayMetaJSON().mergeWithJson(Json.parse(Paths.getTextFromFile('data/${Paths.formatToSongPath(song[0].toLowerCase())}/metadata.json')));
                    metadataFile = {
                        song: {
                            name: song[0],
                            mod: pMetadataFile.freeplayWeekName,
                            charter: "???",
                            artist: "???"
                        },
                        freeplay: {
                            ratings: [],
                            bg: "menuDesat",
                            album: pMetadataFile.albumId
                        },
                    };
                    var diffStr:String = leWeek.difficulties;
                    if(diffStr != null && diffStr.length > 0)
                    {
                        var diffs:Array<String> = diffStr.trim().split(',');
                        for (diff in diffs) {
                            if(diff != null)
                            {
                                diff = diff.trim();
                                if(diff.length < 1) diffs.remove(diff);
                            }
                            metadataFile.freeplay.ratings.set(diff, pMetadataFile.songRating);
                        }
                    }
                }
                catch(e) {
                    //trace("can't.");
                    pMetadataFile = null;
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

                if ((ClientPrefs.data.showMods && leWeek.folder.toLowerCase() == CategoryState.loadWeekForce.toLowerCase()) || (CategoryState.loadWeekForce == "all" && (searchText == null || searchText == '') && (leWeek.folder != '' || leWeek.folder != null)))
                {
                    addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                }
                else if (categoryWhaat.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && categoryWhaat.isEmpty()) || (CategoryState.loadWeekForce == "all"))
                {
                    if (refresh)
                    {
                        var colors:Array<Int> = song[2];
                        if(colors == null || colors.length < 3)
                        {
                            colors = [146, 113, 253];
                        }

                        if (categoryWhaat.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && categoryWhaat.isEmpty()) || CategoryState.loadWeekForce == "all")
                            addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);

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

                            if (categoryWhaat.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && categoryWhaat.isEmpty()) || CategoryState.loadWeekForce == "all")
                                addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                        }
                    }
                }
            }
        }


        if (refresh)
        {
            if (FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
            if (FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
            if (FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
            if (FlxG.save.data.gotgeostar && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('GeoStar', 7, "ElCaption", [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
        }
        else
        {
            if (Std.string('Small Argument').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
            if (Std.string('Beat Battle').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
            if (Std.string('Beat Battle 2').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
            if (Std.string('GeoStar').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                addSong('GeoStar', 7, "ElCaption", [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
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
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                if (states.freeplay.FreeplayState.instance != null)
                    states.freeplay.FreeplayState.instance.reloadSongs(true);
        }
    }

    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Array<Array<Dynamic>>, ?charter:String = "???", ?artist:String = "???")
	{
		songs.push(new GlobalSongMetadata(songName, weekNum, songCharacter, color, charter, artist));
	}

    public function isModName(name:String):Bool {
        var mods = Mods.parseList().enabled;
        // trace("Checking: " + mod);

        if (mods != null && mods.length > 0) {
            for (mod in mods) {
                // trace("Looking for: " + name);
                if (mod == name) {
                    // trace("Found: " + mod);
                    return true;
                }
            }
        }
        // trace("Not Found: " + name);
        return false;
    }

    //Actual freeplay stuff
    public function previewSong(needVoices) {
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

    public function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

    public function getVocalFromCharacter(char:String)
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
}

class GlobalSongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Array<Array<Dynamic>> = [];
	public var folder:String = "";
	public var lastDifficulty:String = null;

    // V-Slice/P-Slice compat
    public var charter:String = "???";
    public var artist:String = "???";

	public function new(song:String, week:Int, songCharacter:String, color:Array<Array<Dynamic>>, ?charter:String = "???", ?artist:String = "???")
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
        this.charter = charter;
        this.artist = artist;
		if(this.folder == null) this.folder = '';
	}
}
