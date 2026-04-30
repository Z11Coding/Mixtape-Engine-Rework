package managers;

import backend.Song;
import backend.WeekData;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import lime.utils.Assets;
import metadata.STMetaFile.CodenameMetadata;
import metadata.STMetaFile.FreeplayMetaJSON;
import metadata.STMetaFile.MetadataFile;
import states.CategoryState;
import states.PlayState;
import states.StoryMenuState;
import states.freeplay.*; // WHY DIDN'T I DO THIS EARLIER????
import states.freeplay.VSliceFreeplayState.FreeplayStateParams;
import states.freeplay.vslice.FreeplaySongData;
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
**/
class FreeplayManager {
    public static var instance:FreeplayManager;

    public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	public static var gfVocals:FlxSound = null;
    private var _ignoreLocks:Bool = false; // Used for scripted freeplays that want to ignore locked weeks (or sanity data)
    public var ignoreLocks(get, set):Bool;
    public inline function get_ignoreLocks():Bool {
        return _ignoreLocks || this is APFreeplayManager; // Always ignore locks in AP mode to ensure all songs are accessible
    }
    public inline function set_ignoreLocks(value:Bool):Bool {
        return _ignoreLocks = value;
    }

    public static var songListGlobal:Array<GlobalSongData> = [];

    var songs:Array<GlobalSongMetadata> = [];
	public var songList(get, never):Array<GlobalSongMetadata>;
	public function get_songList():Array<GlobalSongMetadata> {
		return songs;
	}

    public var metadata:Map<String, MetadataFile> = new Map<String, MetadataFile>();
    var metadataFile:MetadataFile;
    var pMetadataFile:FreeplayMetaJSON;
    var cMetadataFile:CodenameMetadata;
	var hasMetadataFile:Bool = false;
    var weeklessSongs:Array<String> = [
        'Small Argument',
        'Beat Battle',
        'Beat Battle 2',
        'GeoStar',
        'Rise',
        'Zeventeen',
        'Pack-A-Punch',
        'Driller',
        'Test Field',
        'Rawr',
        'Fightback',
        'Funky Fanta',
        'Tag And Seek',
        'Testimony',
        'Fangirl Frenzy',
        'Slowdown',
        'Reminisce'
    ];

    public function new(?loadSongs:Bool = false, ?skipStateRefresh:Bool = false) {
        instance = this;
        if (loadSongs)
            reloadFreeplay(true);
    }

    /////////////////////////////////////////////////////FUNCTIONS///////////////////////////////////////////////////////////////////////////////
    public static function loadFPManager(?ensureLoaded:Bool = false):FreeplayManager {
        //trace("FP in Arch Mode: " + APEntryState.inArchipelagoMode);
        #if ARCHIPELAGO_ALLOWED
        return switch (APEntryState.inArchipelagoMode) {
            case true:
                if (instance != null && Std.isOfType(instance, APFreeplayManager)) {
                    //trace("Using existing APFreeplayManager instance.");
                    if (ensureLoaded) instance.reloadFreeplay(true);
                    return instance;
                } else {
                    //trace("Creating new APFreeplayManager instance.");
                    return instance = new APFreeplayManager(ensureLoaded);
                }
            case false:
                if (instance != null && instance.isType(FreeplayManager, true)) {
                    //trace("Using existing FreeplayManager instance.");
                    if (ensureLoaded) instance.reloadFreeplay(true);
                    return instance;
                } else {
                    //trace("Creating new FreeplayManager instance.");
                    return instance = new FreeplayManager(ensureLoaded);
                }
        }
        #else
        return switch (instance != null && instance.isType(FreeplayManager, true)) {
            case true:
                trace("Using existing FreeplayManager instance.");
                if (ensureLoaded) instance.reloadFreeplay(true);
                instance;
            case false:
                trace("Creating new FreeplayManager instance.");
                instance = new FreeplayManager(ensureLoaded);
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
            case "Base Game":
                states.freeplay.VSliceFreeplayState;
            case "Dynamic":
                states.freeplay.DynamicFreeplayState;
            default:
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
            case "Base Game":
                states.freeplay.VSliceFreeplayState;
            case "Dynamic":
                states.freeplay.DynamicFreeplayState;
            default:
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
            case "Base Game":
                states.freeplay.VSliceFreeplayState.instance;
            case "Dynamic":
                states.freeplay.DynamicFreeplayState.instance;
            default:
                FlxG.log.error("Invalid Freeplay Menu: " + ClientPrefs.data.freeplayMenu);
                states.freeplay.FreeplayState.instance;
        }
        return states.freeplay.FreeplayState.instance;
    }

    public static inline function getNewFreeplayInstance():flixel.FlxState
	{
        return switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                new states.freeplay.FreeplayState();
            case "Osu":
                new states.freeplay.OsuFreeplayState();
            case "Base Game":
                new states.CategoryState(); //Since this is where Freeplay is hosted, it has to go here
            case "Dynamic":
                new states.freeplay.DynamicFreeplayState();
            default:
                new states.freeplay.CustomFreeplayState(Paths.mods(ClientPrefs.data.freeplayMenu));
        }
	}

    public static inline function openFreeplay(?fromCategory:Bool = false, ?freeplayPrams:FreeplayStateParams = null)
	{
        if (ClientPrefs.data.freeplayMenu == "Base Game") { //Base game opens a little differently
            if (fromCategory) {
                var curState = MusicBeatState.getState();
                curState.persistentDraw = true;
                curState.persistentUpdate = false;
                // Freeplay has its own custom transition
                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;

                curState.openSubState(new states.freeplay.VSliceFreeplayState(freeplayPrams));
            } else FlxG.switchState(() -> states.freeplay.VSliceFreeplayState.build());
        } else if (CategoryState.loadWeekForce != null && !states.PlayState.Crashed) {
            var freeplayClass = getFreeplay();
            var freeplayInstance = freeplayClass == states.freeplay.CustomFreeplayState ?
            Type.createInstance(freeplayClass, [Paths.mods(ClientPrefs.data.freeplayMenu)]) :
            Type.createInstance(freeplayClass, []);
            MusicBeatState.preloadAndSwitchState(freeplayInstance);
        } else if (CategoryState.loadWeekForce != null && states.PlayState.Crashed) {
            var freeplayClass = getFreeplay();
            var freeplayInstance = freeplayClass == states.freeplay.CustomFreeplayState ?
            Type.createInstance(freeplayClass, [Paths.mods(ClientPrefs.data.freeplayMenu)]) :
            Type.createInstance(freeplayClass, []);
            FlxG.switchState(freeplayInstance);
        }
        else //You cant play a song without picking a category first!
            FlxG.switchState(new states.CategoryState());

        if (FlxG.sound.music == null || !FlxG.sound.music.playing)
            MusicManager.playMenuMusic();
	}

    public static function getPSliceMetadata(songName:String):FreeplayMetaJSON {
        try {
        var psliceMetadataFile:FreeplayMetaJSON = cast Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(songName.toLowerCase()) + '/metadata')));
        return psliceMetadataFile;
        } catch(e:Dynamic) {/*trace(e);*/}
        return null;
    }

    public static function getCodenameMetadata(songName:String):CodenameMetadata {
        try {
        var psliceMetadataFile:CodenameMetadata = cast Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(songName.toLowerCase()) + '/meta')));
        return psliceMetadataFile;
        } catch(e:Dynamic) {/*trace(e);*/}
        return null;
    }

    public static function getMixtapeMetadata(songName:String):MetadataFile {
        if (loadFPManager().metadata.get(songName) != null) return loadFPManager().metadata.get(songName);
        else {
            //trace("No preloaded metadata for this song found! Using direct load...");
            try {
                var mixtapeMetadataFile:MetadataFile = cast Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(songName.toLowerCase()) + '/meta')));
                return mixtapeMetadataFile;
            }
            catch(e) {
                //trace("No Metadata found!");
                return null;
            }
        }
        return null;
    }

    public static function loadGlobalSongs(?forceLoad:Bool = false, ?skipStateRefresh:Bool = true)
    {
        trace("Reloading Global Songs!");
        // make sure the list is alive and empty before using it
        if (forceLoad || (songListGlobal == null || songListGlobal != null && songListGlobal.length == 0))
            songListGlobal = [];
        else return;

        WeekData.reloadWeekFiles(false);
        for (i in 0...WeekData.weeksList.length) {
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
                var newSong:GlobalSongData = {
                    songName: "",
                    week: 0,
                    songCharacter: "",
                    color: [],
                    folder: "",
                    lastDifficulty: '',
                    category: [],
                    charter: "???",
                    artist: "???",
                    metadata: {},
                    weekless: false
                };
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

                newSong.category = categoryWhaat;

                // trace("CategoryWhaat2: " + categoryWhaat);
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3)
                {
                    colors = [146, 113, 253];
                }

                var metadataFilelocal:MetadataFile;
                var pMetadataFilelocal:FreeplayMetaJSON = new FreeplayMetaJSON();
                var cMetadataFilelocal:CodenameMetadata;
                try {metadataFilelocal = cast Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(song[0].toLowerCase()) + '/meta')));}
                catch(e) {
                    //trace("can't.");
                    metadataFilelocal = null;
                }

                //If loading it through Mixtape Metadata didnt work, try P-Slice
                if (metadataFilelocal == null) {
                    try {
                        pMetadataFilelocal = new FreeplayMetaJSON().mergeWithJson(Json.parse(Paths.getTextFromFile('data/${Paths.formatToSongPath(song[0].toLowerCase())}/metadata.json')));
                        metadataFilelocal = {
                            song: {
                                name: song[0],
                                mod: Mods.currentModDirectory,
                                charter: "???",
                                artist: "???"
                            },
                            freeplay: { // cover the defaults and pray to god the custom ones figure themselves out
                                ratings: ['easy' => pMetadataFilelocal.songRating, 'normal' => pMetadataFilelocal.songRating, 'hard' => pMetadataFilelocal.songRating, 'erect' => pMetadataFilelocal.songRating, 'nightmare' => pMetadataFilelocal.songRating],
                                bg: "menuDesat",
                                album: pMetadataFilelocal.albumId
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
                                metadataFilelocal.freeplay.ratings.set(diff.toLowerCase(), pMetadataFilelocal.songRating);
                            }
                        }
                    }
                    catch(e) {
                        //trace("can't.");
                        pMetadataFilelocal = null;
                    }
                }

                // If loading it through P-Slice didn't work, try Codename
                if (metadataFilelocal == null) {
                    try {
                        cMetadataFilelocal = getCodenameMetadata(song[0]);
                        var coolName:String = '${cMetadataFilelocal.displayName ?? ''} (${cMetadataFilelocal.variant ?? ''})';
                        metadataFilelocal = {
                            song: {
                                name: (coolName.length > 0 ? coolName : song[0]),
                                mod: Mods.currentModDirectory,
                                charter: (cMetadataFilelocal.customValues?.credits?.chart ?? "???"),
                                artist: (cMetadataFilelocal.customValues?.credits?.sprites ?? "???")
                            },
                            freeplay: { // cover the defaults and pray to god the custom ones figure themselves out
                                ratings: (cMetadataFilelocal.customValues?.ratings ?? ['easy' => -1, 'normal' => -1, 'hard' => -1, 'erect' => -1, 'nightmare' => -1]),
                                bg: (cMetadataFilelocal.customValues?.bg ?? "menuDesat"),
                                album: (cMetadataFilelocal.customValues?.album ?? 'NoCover')
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
                                metadataFilelocal.freeplay.ratings.set(diff.toLowerCase(), pMetadataFilelocal.songRating);
                            }
                        }
                    }
                    catch(e) {
                        //trace("can't.");
                        cMetadataFilelocal = null;
                    }
                }

                try
                {
                    newSong.metadata = cast metadataFilelocal;
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

                newSong.songName = song[0];
                newSong.week = i;
                newSong.songCharacter = song[1];
                newSong.color = [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]];
                newSong.folder = Mods.currentModDirectory;
                songListGlobal.push(newSong);
            }
        }


        Mods.currentModDirectory = '';
        // Secrets
        var newSongEX:GlobalSongData = {
            songName: "Small Argument",
            week: 7,
            songCharacter: "gfchibi",
            color: [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]],
            folder: "",
            lastDifficulty: '',
            category: ["secrets"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Beat Battle",
            week: 7,
            songCharacter: "gf",
            color: [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]],
            folder: "",
            lastDifficulty: '',
            category: ["secrets"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Beat Battle 2",
            week: 7,
            songCharacter: "gf",
            color: [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]],
            folder: "",
            lastDifficulty: '',
            category: ["secrets"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "GeoStar",
            week: 7,
            songCharacter: "ElCaption",
            color: [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]],
            folder: "",
            lastDifficulty: '',
            category: ["secrets"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);

        // Special
        var newSongEX:GlobalSongData = {
            songName: "GeoStar",
            week: 8,
            songCharacter: "ElCaption",
            color: [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Rise",
            week: 8,
            songCharacter: "gf",
            color: [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Zeventeen",
            week: 8,
            songCharacter: "Z_icon",
            color: [[135, 53, 172], [FlxColor.fromRGB(135, 53, 172)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "???",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Pack-A-Punch",
            week: 8,
            songCharacter: "matt",
            color: [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Driller",
            week: 8,
            songCharacter: "matt",
            color: [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Test Field",
            week: 8,
            songCharacter: "icons-ohagi",
            color: [[255, 200, 40], [FlxColor.fromRGB(255, 200, 40)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Rawr",
            week: 8,
            songCharacter: "michael",
            color: [[140, 120, 80], [FlxColor.fromRGB(140, 120, 80)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Fightback",
            week: 8,
            songCharacter: "z12",
            color: [[255, 253, 255], [FlxColor.fromRGB(255, 253, 255)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Funky Fanta",
            week: 8,
            songCharacter: "fanta",
            color: [[254, 134, 29], [FlxColor.fromRGB(254, 134, 29)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Tag And Seek",
            week: 8,
            songCharacter: "sillyexe",
            color: [[45, 69, 165], [FlxColor.fromRGB(45, 69, 165)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Testimony",
            week: 8,
            songCharacter: "shaggy",
            color: [[146, 113, 253], [FlxColor.fromRGB(146, 113, 253)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Fangirl Frenzy",
            week: 8,
            songCharacter: "sky",
            color: [[0, 140, 240], [FlxColor.fromRGB(0, 140, 240)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Slowdown",
            week: 8,
            songCharacter: "astria",
            color: [[255, 127, 202], [FlxColor.fromRGB(255, 127, 202)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Z11Gaming",
            artist: "Z11Gaming",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);
        var newSongEX:GlobalSongData = {
            songName: "Reminisce",
            week: 8,
            songCharacter: "cornered-sans",
            color: [[66, 33, 133], [FlxColor.fromRGB(66, 33, 133)]],
            folder: "",
            lastDifficulty: '',
            category: ["special"],
            charter: "Yutamon",
            artist: "Z11Gaming, ChillSpaceFNF",
            metadata: {},
            weekless: true
        };
        songListGlobal.push(newSongEX);

        trace("Global Song List:"+songListGlobal);

        for (song in ['Small Argument', 'Beat Battle', 'Beat Battle 2', 'GeoStar', 'Rise', 'Zeventeen', 'Pack-A-Punch', 'Driller', 'Test Field', 'Rawr', 'Fightback', 'Funky Fanta', 'Tag And Seek', 'Testimony', 'Fangirl Frenzy', 'Slowdown', 'Reminisce']) {
            var newSongEX:GlobalSongData = null;
            for (songObj in songListGlobal) {
                if (songObj != null && songObj.songName?.trim().toLowerCase().replace("-", " ") == song.trim().toLowerCase().replace("-", " ")) {
                    newSongEX = songObj;
                    break;
                } else continue;
            }
            var metadataFile:MetadataFile;
            try {metadataFile = cast Json.parse(Assets.getText(Paths.json(Paths.formatToSongPath(song.toLowerCase()) + '/meta')));}
            catch(e) {
                //trace("can't.");
                metadataFile = null;
            }

            try
            {
                newSongEX.metadata = cast metadataFile;
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

        if (!skipStateRefresh) {
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
                        states.freeplay.VSliceFreeplayState.instance.refreshSongList();
                default:
                    states.freeplay.CustomFreeplayState.instance != null ?
                        states.freeplay.CustomFreeplayState.instance.handleFreeplayReload(true, '') : null;
            }
        }
    }

    //Public things

    public function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

    public function reloadFreeplayState(refresh:Bool = false, ?searchText:String = '') {
        switch (ClientPrefs.data.freeplayMenu) {
            case "Mixtape": //Why rename it when you're already here?
                if (states.freeplay.FreeplayState.instance != null)
                    states.freeplay.FreeplayState.instance.reloadSongs(refresh);
            case "Osu":
                @:privateAccess
                if (states.freeplay.OsuFreeplayState.instance != null)
                    states.freeplay.OsuFreeplayState.instance.loadSongArray(refresh, searchText);
            case "Base Game":
                if (states.freeplay.VSliceFreeplayState.instance != null)
                    states.freeplay.VSliceFreeplayState.instance.refreshSongList();
            case "Dynamic":
                if (states.freeplay.DynamicFreeplayState.instance != null)
                    states.freeplay.DynamicFreeplayState.instance.reloadDynamicSongs();
            default:
                if (states.freeplay.CustomFreeplayState.instance != null)
                    states.freeplay.CustomFreeplayState.instance.handleFreeplayReload(refresh, searchText);
        }
    }

    public function reloadFreeplay(refresh:Bool = false, ?skipStateRefresh:Bool = false, ?searchText:String = '')
    {
        trace("Reloading Songs!");
        // Always populate the main songs array for all freeplay menus
        songs = [];

        if (songListGlobal?.length > 0) {
            for (song in songListGlobal) {
                if (song != null) {
                    var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[song.week]);
                    WeekData.setDirectoryFromWeek(leWeek);
                    if ((ClientPrefs.data.showMods && song.folder.toLowerCase() == CategoryState.loadWeekForce.toLowerCase()) || (CategoryState.loadWeekForce == "all" && (searchText == null || searchText == '') && (song.folder != '' || song.folder != null)))
                    {
                        addSong(song.songName, song.week, song.songCharacter, song.color);
                    }
                    else if (song.category.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && song.category.isEmpty()) || (CategoryState.loadWeekForce == "all"))
                    {
                        if (refresh)
                        {
                            var colors:Array<Int> = cast song.color[0];
                            if(colors == null || colors.length < 3)
                                colors = [146, 113, 253];

                            if (song.category.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && song.category.isEmpty()) || CategoryState.loadWeekForce == "all")
                                addSong(song.songName, song.week, song.songCharacter, [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);

                        }
                        else
                        {
                            if (Std.string(song.songName).toLowerCase().trim().contains(searchText.toLowerCase().trim()))
                            {
                                var colors:Array<Int> = cast song.color[0];
                                if(colors == null || colors.length < 3)
                                {
                                    colors = [146, 113, 253];
                                }

                                if (song.category.indexOf(CategoryState.loadWeekForce.toLowerCase()) != -1 || (CategoryState.loadWeekForce == "mods" && song.category.isEmpty()) || CategoryState.loadWeekForce == "all")
                                    addSong(song.songName, song.week, song.songCharacter, [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
                            }
                        }
                    }
                }
            }
        } else {
            for (i in 0...WeekData.weeksList.length) {
                if(!ignoreLocks && weekIsLocked(WeekData.weeksList[i])) continue;
                var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

                function nullIfEmptyArray<T>(array:Array<T>):Null<Array<T>> {
                    if (array == null || array.length == 0) {
                        return null;
                    }
                    return array;
                }

                WeekData.setDirectoryFromWeek(leWeek);
                if (leWeek.songs != null) {
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



                        //trace("Song Category: " + categoryWhaat);
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

                        //If loading it through Mixtape Metadata didnt work, try P-Slice
                        if (metadataFile == null) {
                            try {
                                pMetadataFile = new FreeplayMetaJSON().mergeWithJson(Json.parse(Paths.getTextFromFile('data/${Paths.formatToSongPath(song[0].toLowerCase())}/metadata.json')));
                                metadataFile = {
                                    song: {
                                        name: song[0],
                                        mod: Mods.currentModDirectory,
                                        charter: "???",
                                        artist: "???"
                                    },
                                    freeplay: { // cover the defaults and pray to god the custom ones figure themselves out
                                        ratings: ['easy' => pMetadataFile.songRating, 'normal' => pMetadataFile.songRating, 'hard' => pMetadataFile.songRating, 'erect' => pMetadataFile.songRating, 'nightmare' => pMetadataFile.songRating],
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
                                        metadataFile.freeplay.ratings.set(diff.toLowerCase(), pMetadataFile.songRating);
                                    }
                                }
                            }
                            catch(e) {
                                //trace("can't.");
                                pMetadataFile = null;
                            }
                        }

                        // If loading it through P-Slice didn't work, try Codename
                        if (metadataFile == null) {
                            try {
                                cMetadataFile = getCodenameMetadata(song[0]);
                                var coolName:String = '${cMetadataFile.displayName ?? ''} (${cMetadataFile.variant ?? ''})';
                                metadataFile = {
                                    song: {
                                        name: (coolName.length > 0 ? coolName : song[0]),
                                        mod: Mods.currentModDirectory,
                                        charter: (cMetadataFile.customValues?.credits?.chart ?? "???"),
                                        artist: (cMetadataFile.customValues?.credits?.sprites ?? "???")
                                    },
                                    freeplay: { // cover the defaults and pray to god the custom ones figure themselves out
                                        ratings: (cMetadataFile.customValues?.ratings ?? ['easy' => -1, 'normal' => -1, 'hard' => -1, 'erect' => -1, 'nightmare' => -1]),
                                        bg: (cMetadataFile.customValues?.bg ?? "menuDesat"),
                                        album: (cMetadataFile.customValues?.album ?? 'NoCover')
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
                                        metadataFile.freeplay.ratings.set(diff.toLowerCase(), pMetadataFile.songRating);
                                    }
                                }
                            }
                            catch(e) {
                                //trace("can't.");
                                cMetadataFile = null;
                            }
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
                } else {
                    trace("WEEK WAS NULL!");
                }
            }


            Mods.currentModDirectory = '';
            if (refresh)
            {
                // Secrets
                if (FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
                if (FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (FlxG.save.data.gotgeostar && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('GeoStar', 7, "ElCaption", [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);

                // Special
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Rise', 8, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Zeventeen', 8, "Z_icon", [[135, 53, 172], [FlxColor.fromRGB(135, 53, 172)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Pack-A-Punch', 8, "matt", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Driller', 8, "matt", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Test Field', 8, "icons-ohagi", [[255, 200, 40], [FlxColor.fromRGB(255, 200, 40)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Rawr', 8, "michael", [[140, 120, 80], [FlxColor.fromRGB(140, 120, 80)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Fightback', 8, "z12", [[255, 253, 255], [FlxColor.fromRGB(255, 253, 255)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Funky Fanta', 8, "fanta", [[254, 134, 29], [FlxColor.fromRGB(254, 134, 29)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Tag And Seek', 8, "sillyexe", [[45, 69, 165], [FlxColor.fromRGB(45, 69, 165)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Testimony', 8, "shaggy", [[146, 113, 253], [FlxColor.fromRGB(146, 113, 253)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Fangirl Frenzy', 8, "sky", [[0, 140, 240], [FlxColor.fromRGB(0, 140, 240)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Slowdown', 8, "astria", [[255, 127, 202], [FlxColor.fromRGB(255, 127, 202)]]);
                if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
                    addSong('Reminisce', 8, "cornered-sans", [[66, 33, 133], [FlxColor.fromRGB(66, 33, 133)]]);
            }
            else
            {
                if (Std.string('Small Argument').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
                if (Std.string('Beat Battle').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (Std.string('Beat Battle 2').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (Std.string('GeoStar').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.gotgeostar && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
                    addSong('GeoStar', 7, "ElCaption", [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);

                // Special
                if (Std.string('Rise').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Rise', 8, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (Std.string('Zeventeen').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Zeventeen', 8, "Z_icon", [[135, 53, 172], [FlxColor.fromRGB(135, 53, 172)]]);
                if (Std.string('Pack-A-Punch').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Pack-A-Punch', 8, "matt", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (Std.string('Driller').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Driller', 8, "matt", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
                if (Std.string('Test Field').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Test Field', 8, "icons-ohagi", [[255, 200, 40], [FlxColor.fromRGB(255, 200, 40)]]);
                if (Std.string('Rawr').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Rawr', 8, "michael", [[140, 120, 80], [FlxColor.fromRGB(140, 120, 80)]]);
                if (Std.string('Fightback').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Fightback', 8, "z12", [[255, 253, 255], [FlxColor.fromRGB(255, 253, 255)]]);
                if (Std.string('Funky Fanta').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Funky Fanta', 8, "fanta", [[254, 134, 29], [FlxColor.fromRGB(254, 134, 29)]]);
                if (Std.string('Tag And Seek').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Tag And Seek', 8, "sillyexe", [[45, 69, 165], [FlxColor.fromRGB(45, 69, 165)]]);
                if (Std.string('Testimony').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Testimony', 8, "shaggy", [[146, 113, 253], [FlxColor.fromRGB(146, 113, 253)]]);
                if (Std.string('Fangirl Frenzy').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Fangirl Frenzy', 8, "sky", [[0, 140, 240], [FlxColor.fromRGB(0, 140, 240)]]);
                if (Std.string('Slowdown').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Slowdown', 8, "astria", [[255, 127, 202], [FlxColor.fromRGB(255, 127, 202)]]);
                if (Std.string('Reminisce').toLowerCase().trim().contains(searchText.toLowerCase().trim()) && FlxG.save.data.specialbabygirl && (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl))
                    addSong('Reminisce', 8, "cornered-sans", [[66, 33, 133], [FlxColor.fromRGB(66, 33, 133)]]);
            }

            for (song in weeklessSongs) {
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
        }

        if (!skipStateRefresh) {
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
                        states.freeplay.VSliceFreeplayState.instance.refreshSongList();
                default:
                    states.freeplay.CustomFreeplayState.instance != null ?
                        states.freeplay.CustomFreeplayState.instance.handleFreeplayReload(refresh, searchText) : null;
            }
        }
    }

    public function reloadPlaylistSelect()
    {
        trace("Reloading Songs!");
        // Always populate the main songs array for all freeplay menus
        songs = [];

        for (i in 0...WeekData.weeksList.length) {
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
                        freeplay: { // cover the defaults and pray to god the custom ones figure themselves out
                            ratings: ['easy' => pMetadataFile.songRating, 'normal' => pMetadataFile.songRating, 'hard' => pMetadataFile.songRating, 'erect' => pMetadataFile.songRating, 'nightmare' => pMetadataFile.songRating],
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
                            metadataFile.freeplay.ratings.set(diff.toLowerCase(), pMetadataFile.songRating);
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

                addSong(song[0], i, song[1], [colors, [FlxColor.fromRGB(colors[0], colors[1], colors[2])]]);
            }
        }


        Mods.currentModDirectory = '';
        // Secrets
        if (FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
            addSong('Small Argument', 7, "gfchibi", [[235, 100, 161], [FlxColor.fromRGB(235, 100, 161)]]);
        if (FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
            addSong('Beat Battle', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
        if (FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
            addSong('Beat Battle 2', 7, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
        if (FlxG.save.data.gotgeostar && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all"))
            addSong('GeoStar', 7, "ElCaption", [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);

        // Special
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Rise', 8, "gf", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Zeventeen', 8, "Z_icon", [[135, 53, 172], [FlxColor.fromRGB(135, 53, 172)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Pack-A-Punch', 8, "matt", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Driller', 8, "matt", [[165, 0, 77], [FlxColor.fromRGB(165, 0, 77)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Test Field', 8, "icons-ohagi", [[255, 200, 40], [FlxColor.fromRGB(255, 200, 40)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Rawr', 8, "michael", [[140, 120, 80], [FlxColor.fromRGB(140, 120, 80)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Fightback', 8, "z12", [[255, 253, 255], [FlxColor.fromRGB(255, 253, 255)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Funky Fanta', 8, "fanta", [[254, 134, 29], [FlxColor.fromRGB(254, 134, 29)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Tag And Seek', 8, "sillyexe", [[45, 69, 165], [FlxColor.fromRGB(45, 69, 165)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Testimony', 8, "shaggy", [[146, 113, 253], [FlxColor.fromRGB(146, 113, 253)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Fangirl Frenzy', 8, "sky", [[0, 140, 240], [FlxColor.fromRGB(0, 140, 240)]]);
        if (CategoryState.loadWeekForce == "special" || CategoryState.loadWeekForce == "all" && FlxG.save.data.specialbabygirl)
            addSong('Slowdown', 8, "astria", [[255, 127, 202], [FlxColor.fromRGB(255, 127, 202)]]);

        for (song in weeklessSongs) {
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

        if (states.editors.PlaylistSongSelectorState.instance != null)
            states.editors.PlaylistSongSelectorState.instance.reloadSongs();
    }

    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Array<Array<Dynamic>>, ?charter:String = "???", ?artist:String = "???", ?weekless:Bool = false)
	{
		songs.push(new GlobalSongMetadata(songName, weekNum, songCharacter, color, charter, artist, weekless));
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
                var playerVocals:String = getVocalFromCharacter(PlayfieldManager.SONG.player1);
                var loadedVocals = Paths.voices(PlayfieldManager.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
                if(loadedVocals == null) loadedVocals = Paths.voices(PlayfieldManager.SONG.song);

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
                var oppVocals:String = getVocalFromCharacter(PlayfieldManager.SONG.player2);
                var loadedVocals = Paths.voices(PlayfieldManager.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
                var loadedgfVocals = Paths.voices(PlayfieldManager.SONG.song, 'gf');

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

        FlxG.sound.playMusic(Paths.inst(PlayfieldManager.SONG.song), 0.8);
        FlxG.sound.music.pause();
        Conductor.bpm = PlayfieldManager.SONG.bpm;
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
    public var weekless:Bool = false;

    // V-Slice/P-Slice compat
    public var charter:String = "???";
    public var artist:String = "???";

	public function new(song:String, week:Int, songCharacter:String, color:Array<Array<Dynamic>>, ?charter:String = "???", ?artist:String = "???", ?weekless:Bool = false)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
        this.charter = charter;
        this.artist = artist;
        this.weekless = weekless;
		if(this.folder == null) this.folder = '';
	}
}

@:structInit
class GlobalSongData
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Array<Array<Dynamic>> = [];
	public var folder:String = "";
	public var lastDifficulty:String = "";
    public var category:Array<String> = [];
    // V-Slice/P-Slice compat
    public var charter:String = "???";
    public var artist:String = "???";
    public var metadata:Dynamic = {};
    public var weekless:Bool = false;

    public function dispose() {
		// will be cleared by the GC later
		for (field in Reflect.fields(this)) {
			Reflect.setField(this, field, null);
		}
	}
}
