package archipelago;
import backend.InputFormatter;
import backend.Song;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.misc.NumTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import managers.FreeplayManager;
import objects.*;
import objects.Character;
import objects.Note;
import objects.VideoSprite;
import objects.playfields.PlayField;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
import shaders.MosaicEffect;
import stages.StageData;
import states.PlayState;
import states.PlaylistState.PlaylistData;
import states.PlaylistState.PlaylistMetadata;
import states.PlaylistState.PlaylistSongMetadata;
import states.PlaylistState.SongMetadata;
import states.freeplay.FreeplayState;
import states.freeplay.OsuFreeplayState;
import streamervschat.*;

using yutautil.Table;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
class APPlayState extends PlayState {
    public static var instance:APPlayState;

    public static var apGame:APGameState;
    public static var deathByLink:Bool = false;
    public static var deathByBlueBalls:Bool = false;
    public static var alreadyKilledByLink:Bool = false;
    public static var resisting:Bool = false;

    public var instanceDeferredLocationChecks:Array<Int> = []; // Instance checks collected during this song
    public var instanceDeferredNoteChecks:Array<Int> = []; // Instance note checks collected during this song
    public var antiHornySpray:Bool = false;
    public var noHorny(get, never):Bool;

    function get_noHorny():Bool
    {
        return antiHornySpray || inCutscene;
    }

    public var checkedNotes:Array<Note> = new Array<Note>();

    public static var currentMod = "";
    public static var currentSong = "";
    public static var deathLinkPacket:Dynamic;
    public static var effectiveScrollSpeed:Float;
	public static var effectiveDownScroll:Bool;
    public static var xWiggle:Array<Float> = [0, 0, 0, 0];
	public static var yWiggle:Array<Float> = [0, 0, 0, 0];
    public static var notePositions:Array<Int> = [0, 1, 2, 3];
    public static var validWords:Array<String> = [];
    public static var controlButtons:Array<String> = [];
    public var ogScroll:Bool = ClientPrefs.data.downScroll;
	public var allowSetChartModifier:Bool = false;
    public var activeItems:Array<Int> = [0, 0, 0, 0]; // Shield, Curse, MHP, Traps
    public var itemAmount:Int = 0;
    public var midSwitched:Bool = false;
    public var severInputs:Array<Bool> = new Array<Bool>();
    public var lowFilterAmount:Float = 1;
	public var vocalLowFilterAmount:Float = 1;
    private var lastDifficultyName:String = '';
    private var invulnCount:Int = 0;
    private var debugKeysDodge:Array<FlxKey>;

    // Song unlock system
    private var songNotUnlocked:Bool = false;
    private var missingItems:Array<String> = [];
    private var unlockTransitionStarted:Bool = false;
	// private var unBlurShaderRestore:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();
    var curDifficulty:Int = -1;
    var effectsActive:Map<String, Int> = new Map<String, Int>();
    var effectTimer:FlxTimer = new FlxTimer();
	var randoTimer:FlxTimer = new FlxTimer();
    var drainHealth:Bool = false;
	var drunkTween:NumTween = null;
	var lagOn:Bool = false;
	var addedMP4s:Array<VideoSprite> = [];
	var flashbangTimer:FlxTimer = new FlxTimer();
	var errorMessages:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
    var aliveVideos:FlxTypedGroup<VideoSprite> = new FlxTypedGroup<VideoSprite>();
	var noiseSound:FlxSound = new FlxSound();
	var camAngle:Float = 0;
	var dmgMultiplier:Float = 1;
	var frozenInput:Int = 0;
	var blurEffect:MosaicEffect = new MosaicEffect();
	var spellPrompts:Array<SpellPrompt> = [];
    var terminateStep:Int = -1;
	var terminateMessage:FlxSprite = new FlxSprite();
	var terminateSound:FlxSound = new FlxSound();
	var terminateTimestamps:Array<TerminateTimestamp> = new Array<TerminateTimestamp>();
	var terminateCooldown:Bool = false;
	var shieldSprite:FlxSprite = new FlxSprite();
	var filtersGame:Array<BitmapFilter> = [];
	var filtersHUD:Array<BitmapFilter> = [];
	var filterMap:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}>;
	var picked:Int = 0;
    var wordList:Array<String> = [];
	var nonoLetters:String = "";
    public static var livecount:Int = 0;
	public var effectArray:Array<String> = [
		'colorblind', 'blur', 'lag', 'mine', 'warning', 'heal', 'spin', 'songslower', 'songfaster', 'scrollswitch', 'scrollfaster', 'scrollslower', 'rainbow',
		'cover', 'ghost', 'flashbang', 'nostrum', 'jackspam', 'spam', 'sever', 'shake', 'poison', 'dizzy', 'noise', 'flip', 'invuln',
		'desync', 'mute', 'ice', 'fakeheal', 'spell', 'terminate', 'lowpass', #if windows 'notif' #end
	];
	var notifs:Array<String> = [
		"You're crazy...",
		"Hey there.",
		"LOOK OUT!!!",
		"RUN!",
		"Hey bro, what's that behind you?",
		"Z11 says hi",
		"Yuta says hi",
		"whatever you do, DON'T PRESS 7!",
		"I can see you.",
		"⣀⣠⣤⣤⣤⣤⢤⣤⣄⣀⣀⣀⣀⡀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
		⠄⠉⠹⣾⣿⣛⣿⣿⣞⣿⣛⣺⣻⢾⣾⣿⣿⣿⣶⣶⣶⣄⡀⠄⠄⠄
		⠄⠄⠠⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣿⣿⣿⣿⣿⣆⠄⠄
		⠄⠄⠘⠛⠛⠛⠛⠋⠿⣷⣿⣿⡿⣿⢿⠟⠟⠟⠻⠻⣿⣿⣿⣿⡀⠄
		⠄⢀⠄⠄⠄⠄⠄⠄⠄⠄⢛⣿⣁⠄⠄⠒⠂⠄⠄⣀⣰⣿⣿⣿⣿⡀
		⠄⠉⠛⠺⢶⣷⡶⠃⠄⠄⠨⣿⣿⡇⠄⡺⣾⣾⣾⣿⣿⣿⣿⣽⣿⣿
		⠄⠄⠄⠄⠄⠛⠁⠄⠄⠄⢀⣿⣿⣧⡀⠄⠹⣿⣿⣿⣿⣿⡿⣿⣻⣿
		⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠉⠛⠟⠇⢀⢰⣿⣿⣿⣏⠉⢿⣽⢿⡏
		⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠠⠤⣤⣴⣾⣿⣿⣾⣿⣿⣦⠄⢹⡿⠄
		⠄⠄⠄⠄⠄⠄⠄⠄⠒⣳⣶⣤⣤⣄⣀⣀⡈⣀⢁⢁⢁⣈⣄⢐⠃⠄
		⠄⠄⠄⠄⠄⠄⠄⠄⠄⣰⣿⣛⣻⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡯⠄⠄
		⠄⠄⠄⠄⠄⠄⠄⠄⠄⣬⣽⣿⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠄⠄
		⠄⠄⠄⠄⠄⠄⠄⠄⠄⢘⣿⣿⣻⣛⣿⡿⣟⣻⣿⣿⣿⣿⡟⠄⠄⠄
		⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠛⢛⢿⣿⣿⣿⣿⣿⣿⣷⡿⠁⠄⠄⠄
		⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠉⠉⠉⠉⠈⠄⠄⠄⠄⠄⠄",
		"You know what that means, FISH!"
	];
	public var curEffect:Int = 0;

	public var effectMap:Map<String, Void->Void>;
    public static var updateFunctions:Array<{func: Void->Void, keepOnRestart:Bool, ?activated:Main.Boolean}> = [];

	var effectendsin:FlxText;

    var resistanceBar:Bar;
    var zenetta:Character;
    var resistanceAmount:Float = 0;

    public static var dontCorrect:Bool = false;

    public function new(?playlistData:PlaylistData, ?songlist:Array<PlaylistSongMetadata>)
    {
        super(playlistData, songlist);
    }

    function generateGibberish(length:Int, exclude:String):String
	{
		var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
		var result:String = "";

		// Remove excluded characters from the alphabet
		for (i in 0...exclude.length)
		{
			alphabet = StringTools.replace(alphabet, exclude.charAt(i), "");
		}

		// Generate the gibberish string
		for (i in 0...length)
		{
			var randomIndex:Int = Math.floor(Math.random() * alphabet.length);
			result += alphabet.charAt(randomIndex);
		}

		return result;
	}

    override public function create()
    {
        // Check if the current song/mod is unlocked; if not, set flag and show info panel
        if (APEntryState.inArchipelagoMode && !archipelago.APInfo.inSongTrap)
        {
            var found = false;
            var missingItems:Array<String> = [];

            trace('APPlayState checking song: currentSong="$currentSong", currentMod="$currentMod"');

            for (entry in APFreeplayManager.curUnlocked)
            {
                if (entry.song == currentSong && entry.mod == currentMod)
                {
                    trace('Found in APFreeplayManager.curUnlocked: song=$currentSong, mod=$currentMod');
                    found = true;
                    break;
                }
            }

            if (!found)
            {
                trace('Not in curUnlocked, checking playlists...');
                for (playlistEntry in archipelago.APPlaylistState.apPlaylists)
                for (songEntry in playlistEntry.songList)
                {
                    trace('Comparing: "${songEntry.songName.trim()}" == "${currentSong.trim()}" && "${songEntry.folder.trim()}" == "${currentMod.trim()}"');
                    if (songEntry.songName.trim() == currentSong.trim() && songEntry.folder.trim() == currentMod.trim())
                    {
                        trace('Found in playlist: song=$currentSong, mod=$currentMod');
                        found = true;
                        break;
                    }
                }
            }

            // If song is unlocked, also check if required characters and stage are unlocked via sanity system
            if (found && archipelago.APEntryState.apGame != null) {
                // Check sanity items for this song's characters and stage
                missingItems = archipelago.APEntryState.apGame.checkSongCharactersAndStageUnlocked(PlayfieldManager.SONG);
                if (missingItems.length > 0) {
                    trace('APPlayState: Song requires unlocked sanity items: ' + missingItems.join(", "));
                    found = false; // Mark as not accessible due to missing sanity items
                }
            }

            if (!found) {
                trace('APPlayState: Song $currentSong in mod $currentMod is not unlocked. Missing items: ' + missingItems.join(", "));
                songNotUnlocked = true;
                // Store missing items for later use in startCountdown
                this.missingItems = missingItems;
            }
        }

        if (FlxG.save.data.manualOverride != null && FlxG.save.data.manualOverride && !dontCorrect)
        {
            // When manual override is active, ensure we're playing the correct trap song
            trace('Manual Override detected - verifying trap song consistency');

            var intendedTrapSong = FlxG.save.data.trapSONG; // The song the trap wanted to play
            var currentSong = PlayfieldManager.SONG;

            // Check if the current song matches the intended trap song
            if (intendedTrapSong != null && currentSong != null) {
                var songMismatch = (intendedTrapSong.song != currentSong.song ||
                                  FlxG.save.data.trapStoryWeek != PlayState.storyWeek ||
                                  FlxG.save.data.trapCurrentModDirectory != Mods.currentModDirectory ||
                                  FlxG.save.data.trapStoryDifficulty != PlayState.storyDifficulty);

                if (songMismatch) {
                    trace('Trap song mismatch detected during manual override');
                    trace('Expected trap song: ' + intendedTrapSong.song + ' (Week: ' + FlxG.save.data.trapStoryWeek + ', Mod: ' + FlxG.save.data.trapCurrentModDirectory + ')');
                    trace('Current: ' + currentSong.song + ' (Week: ' + PlayState.storyWeek + ', Mod: ' + Mods.currentModDirectory + ')');

                    // Restore the correct trap song state and force a reset
                    PlayState.storyWeek = FlxG.save.data.trapStoryWeek;
                    Mods.currentModDirectory = FlxG.save.data.trapCurrentModDirectory;
                    Difficulty.list = FlxG.save.data.trapDifficulties;
                    curDifficulty = FlxG.save.data.trapCurDifficulty;
                    PlayfieldManager.SONG = FlxG.save.data.trapSONG;
                    PlayState.storyDifficulty = FlxG.save.data.trapStoryDifficulty;

                    trace('Trap song state corrected - resetting APPlayState');
                    PlayState.resettingState = true;
                    StageData.loadDirectory(PlayfieldManager.SONG);
                    MusicBeatState.resetState();
                    return;
                }
            }
        }

        instance = this; // For traps and items

        currentMod = (backend.WeekData.getCurrentWeek() != null ? backend.WeekData.getCurrentWeek().folder : '');



        if (!APEntryState.inArchipelagoMode)
        {
            FlxG.switchState(new PlayState());
            return;
        }


        {
            super.create();
        }

        allowDebugKeys = false;
        lives = livecount;

        if (ogScroll != ClientPrefs.data.downScroll)
        {
            ogScroll = ClientPrefs.data.downScroll;
            effectiveDownScroll = ogScroll;
            updateScrollUI();
            trace("Scrolling changed to " + (effectiveDownScroll ? "down" : "up") + ", as for some reason, it wasn't before.");
        }

        MaxHP += archipelago.APItem.maxHPUp / 2;

        for (func in updateFunctions)
        {
            if (!func.keepOnRestart && (func.activated != null && func.activated)) updateFunctions.remove(func);
        }

        // TODO: Figure out why this is suddenly broken???
        filterMap = [
            "Grayscale" => {
                var matrix:Array<Float> = [
                    0.5, 0.5, 0.5, 0, 0,
                    0.5, 0.5, 0.5, 0, 0,
                    0.5, 0.5, 0.5, 0, 0,
                        0,   0,   0, 1, 0,
                ];

                {filter: new ColorMatrixFilter(matrix)}
            },
            "BlurLittle" => {
                filter: new BlurFilter()
            }
        ];

        effectMap = [
            'colorblind' => function() {
                var ttl:Float = 16;
                var onEnd:(Void->Void) = function() {
                    //camHUD.filters.remove(filterMap.get("Grayscale").filter);
                    //camGame.filters.remove(filterMap.get("Grayscale").filter);
                };
                var playSound:String = "colorblind";
                var playSoundVol:Float = 0.8;
                var noIcon:Bool = false;

                //camGame.filters.push(filterMap.get("Grayscale").filter);
                //camGame.filters.push(filterMap.get("Grayscale").filter);

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'colorblind');
            },
            'blur' => function() {
                var originalShaders:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();
                var ttl:Float = 12;
                var onEnd:(Void->Void) = function() {
                    for (sprite in playfield.playerField.strumNotes) {
                        sprite.shader = originalShaders.get(sprite);
                    };
                    for (sprite in playfield.dadField.strumNotes) {
                        sprite.shader = originalShaders.get(sprite);
                    };
                    for (daNote in unspawnNotes) {
                        if (daNote == null) continue;
                        if (daNote.strumTime >= Conductor.songPosition)
                            daNote.shader = originalShaders.get(daNote);
                    }
                    for (daNote in notes) {
                        if (daNote == null) continue;
                        else
                            daNote.shader = originalShaders.get(daNote);
                    }
                    boyfriend.shader = originalShaders.get(boyfriend);
                    dad.shader = originalShaders.get(dad);
                    if (gf != null) gf.shader = originalShaders.get(gf);
                    blurEffect.setStrength(0, 0);
                    //camGame.filters.remove(filterMap.get("BlurLittle").filter);
                };
                var playSound:String = "blur";
                var playSoundVol:Float = 0.7;
                var noIcon:Bool = false;

                if (effectsActive["blur"] == null || effectsActive["blur"] <= 0) {
                    //camGame.filters.push(filterMap.get("BlurLittle").filter);
                    if (PlayState.curStage.startsWith('school'))
                        blurEffect.setStrength(2, 2);
                    else
                        blurEffect.setStrength(32, 32);
                    for (sprite in playfield.playerField.strumNotes) {
                        originalShaders.set(sprite, sprite.shader);
                        sprite.shader = blurEffect.shader;
                    };
                    for (sprite in playfield.dadField.strumNotes) {
                        originalShaders.set(sprite, sprite.shader);
                        sprite.shader = blurEffect.shader;
                    };
                    for (daNote in unspawnNotes) {
                        if (daNote == null) continue;
                        if (daNote.strumTime >= Conductor.songPosition) {
                            originalShaders.set(daNote, daNote.shader);
                            daNote.shader = blurEffect.shader;
                        }
                    }
                    for (daNote in notes) {
                        if (daNote == null) continue;
                        else {
                            originalShaders.set(daNote, daNote.shader);
                            daNote.shader = blurEffect.shader;
                        }
                    }
                    originalShaders.set(boyfriend, boyfriend.shader);
                    boyfriend.shader = blurEffect.shader;
                    originalShaders.set(dad, dad.shader);
                    dad.shader = blurEffect.shader;
                    if (gf != null) {
                        originalShaders.set(gf, gf.shader);
                        gf.shader = blurEffect.shader;
                    }
                }

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'blur');
            },
            'lag' => function() {
                var ttl:Float = 12;
                var onEnd:(Void->Void) = function() {
                    lagOn = false;
                };
                var playSound:String = "lag";
                var playSoundVol:Float = 0.7;
                var noIcon:Bool = false;

                lagOn = true;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'lag');
            },
            'mine' => function() {
                var noIcon:Bool = true;
                var startPoint:Int = FlxG.random.int(5, 9);
                var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
                var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
                addNoteSvCLegacy(1, startPoint, startPoint);
                addNoteSvCLegacy(1, nextPoint, nextPoint);
                addNoteSvCLegacy(1, lastPoint, lastPoint);
            },
            'warning' => function() {
                var noIcon:Bool = true;
                var startPoint:Int = FlxG.random.int(5, 9);
                var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
                var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
                addNoteSvCLegacy(2, startPoint, startPoint, -1);
                addNoteSvCLegacy(2, nextPoint, nextPoint, -1);
                addNoteSvCLegacy(2, lastPoint, lastPoint, -1);
            },
            'heal' => function() {
                var noIcon:Bool = true;
                addNoteSvCLegacy(3, 5, 9);
            },
            'spin' => function() {
                var ttl:Float = 15;
                var onEnd:(Void->Void) = function() {
                    modManager.setValue('orient', 0);
                };
                var playSound:String = "spin";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                modManager.setValue('confusion', (FlxG.random.bool() ? 1 : -1) * FlxG.random.float(333 * 0.8, 333 * 1.15));
                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'spin');
            },
            'songslower' => function() {
                var desiredChangeAmount:Float = FlxG.random.float(0.1, 0.9);
                var changeAmount = playbackRate - Math.max(playbackRate - desiredChangeAmount, 0.2);
                var ttl:Float = 15;
                var onEnd:(Void->Void) = function() {
                    set_playbackRate(playbackRate + changeAmount);
                    playbackRate + changeAmount;
                };
                var playSound:String = "songslower";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                var alwaysEnd:Bool = true;

                set_playbackRate(playbackRate - changeAmount);
                playbackRate - changeAmount;
                trace(playbackRate);

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd, 'songslower');
            },
            'songfaster' => function() {
                var changeAmount:Float = FlxG.random.float(0.1, 0.9);
                var ttl:Float = 15;
                var onEnd:(Void->Void) = function() {
                    set_playbackRate(playbackRate - changeAmount);
                    playbackRate - changeAmount;
                };
                var playSound:String = "songfaster";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                var alwaysEnd:Bool = true;

                set_playbackRate(playbackRate + changeAmount);
                playbackRate + changeAmount;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd, 'songfaster');
            },
            'scrollswitch' => function() {
                var noIcon:Bool = false;
                var playSound:String = "scrollswitch";
                effectiveDownScroll = !effectiveDownScroll;
                updateScrollUI();
                applyEffect(0, null, playSound, 1, noIcon, 'scrollswitch');
            },
            'scrollfaster' => function() {
                var changeAmount:Float = FlxG.random.float(1.1, 3);
                var ttl:Float = 20;
                var onEnd:(Void->Void) = function() {
                    effectiveScrollSpeed -= changeAmount;
                    songSpeed = PlayfieldManager.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
                };
                var playSound:String = "scrollfaster";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                var alwaysEnd:Bool = true;

                effectiveScrollSpeed += changeAmount;
                songSpeed = PlayfieldManager.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd, 'scrollfaster');
            },
            'notif' => function() {
                #if windows backend.window.CppAPI.sendWindowsNotification("Archipelago", notifs[FlxG.random.int(0, notifs.length-1)]); #end
            },
            'scrollslower' => function() {
                var changeAmount:Float = FlxG.random.float(0.1, 0.9);
                var ttl:Float = 20;
                var onEnd:(Void->Void) = function() {
                    effectiveScrollSpeed += changeAmount;
                    songSpeed = PlayfieldManager.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
                };
                var playSound:String = "scrollslower";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                var alwaysEnd:Bool = true;

                effectiveScrollSpeed -= changeAmount;
                songSpeed = PlayfieldManager.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd, 'scrollslower');
            },
            'rainbow' => function() {
                var ttl:Float = 20;
                var onEnd:(Void->Void) = function() {
                    for (daNote in unspawnNotes) {
                        if (daNote == null) continue;
                        if (daNote.strumTime >= Conductor.songPosition)
                            daNote.defaultRGB();
                    }
                    for (daNote in notes) {
                        if (daNote == null) continue;
                        daNote.defaultRGB();
                    }
                };
                var playSound:String = "rainbow";
                var playSoundVol:Float = 0.5;
                var noIcon:Bool = false;

                for (daNote in unspawnNotes) {
                    if (daNote == null) continue;
                    if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote) {
                        daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                    } else if (daNote.strumTime >= Conductor.songPosition && daNote.isSustainNote) {
                        daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                    }
                }
                for (daNote in notes) {
                    if (daNote == null) continue;
                    if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote) {
                        daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                    } else if (daNote.strumTime >= Conductor.songPosition && daNote.isSustainNote) {
                        daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                        daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                    }
                }

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'rainbow');
            },
            'cover' => function() {
                var ttl:Float = 12;
                var errorMessage:FlxSprite = new FlxSprite();
                var videoGames:VideoSprite = null;
                var onEnd:(Void->Void) = function() {
                    if (errorMessage != null) {
                        errorMessage.kill();
                        errorMessages.remove(errorMessage);
                        FlxDestroyUtil.destroy(errorMessage);
                    }

                    if (videoGames != null) {
                        videoGames.kill();
                        aliveVideos.remove(videoGames);
                        FlxDestroyUtil.destroy(videoGames);
                    }
                };
                var playSound:String = "";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                var alwaysEnd:Bool = true;

                var random = FlxG.random.int(0, #if windows 14 #else 9 #end);
                var randomPosition:Bool = true;

                switch (random) {
                    case 0:
                        errorMessage.loadGraphic(Paths.image("zzzzzzzz"));
                        errorMessage.scale.x = errorMessage.scale.y = 0.5;
                        errorMessage.updateHitbox();
                        playSound = "bell";
                        playSoundVol = 0.6;
                    case 1:
                        errorMessage.loadGraphic(Paths.image("streamervschat/scam"));
                        playSound = 'scam';
                    case 2:
                        errorMessage.loadGraphic(Paths.image("streamervschat/funnyskeletonman"));
                        playSound = 'doot';
                        errorMessage.scale.x = errorMessage.scale.y = 0.8;
                    case 3:
                        errorMessage.loadGraphic(Paths.image("streamervschat/error"));
                        playSound = 'error';
                        errorMessage.scale.x = errorMessage.scale.y = 0.8;
                        errorMessage.antialiasing = true;
                        errorMessage.updateHitbox();
                    case 4:
                        errorMessage.loadGraphic(Paths.image("streamervschat/nopunch"));
                        playSound = 'nopunch';
                        errorMessage.scale.x = errorMessage.scale.y = 0.8;
                        errorMessage.antialiasing = true;
                        errorMessage.updateHitbox();
                    case 5:
                        errorMessage.loadGraphic(Paths.image("streamervschat/banana"), true, 397, 750);
                        errorMessage.animation.add("dance", [0, 1, 2, 3, 4, 5, 6, 7, 8], 9, true);
                        errorMessage.animation.play("dance");
                        playSound = 'banana';
                        playSoundVol = 0.5;
                        errorMessage.scale.x = errorMessage.scale.y = 0.5;
                    #if windows
                    case 6:
                        videoGames = new VideoSprite(Paths.video('streamervschat/mark'), true, false);
                        videoGames.videoSprite.scale.set(378, 362);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                    case 7:
                        randomPosition = false;
                        videoGames = new VideoSprite(Paths.video('streamervschat/fireworks'), true, false);
                        videoGames.videoSprite.scale.set(1280, 720);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                        videoGames.videoSprite.x = videoGames.videoSprite.y = 0;
                        videoGames.videoSprite.blend = ADD;
                        playSound = 'firework';
                    case 8:
                        randomPosition = false;
                        videoGames = new VideoSprite(Paths.video('streamervschat/spiral'), true, false);
                        videoGames.videoSprite.scale.set(1280, 720);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                        videoGames.videoSprite.x = videoGames.videoSprite.y = 0;
                        videoGames.videoSprite.blend = ADD;
                        playSound = 'spiral';
                    case 9:
                        randomPosition = false;
                        videoGames = new VideoSprite(Paths.video('streamervschat/thingy'), true, false);
                        videoGames.videoSprite.scale.set(1280, 720);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                        videoGames.videoSprite.x = videoGames.videoSprite.y = 0;
                        videoGames.videoSprite.blend = ADD;
                        playSound = 'thingy';
                    case 10:
                        randomPosition = false;
                        videoGames = new VideoSprite(Paths.video('streamervschat/light'), true, false);
                        videoGames.videoSprite.scale.set(1280, 720);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                        videoGames.videoSprite.x = videoGames.videoSprite.y = 0;
                        videoGames.videoSprite.blend = ADD;
                        playSound = 'light';
                    case 11:
                        randomPosition = false;
                        videoGames = new VideoSprite(Paths.video('streamervschat/snow'), true, false);
                        videoGames.videoSprite.scale.set(1280, 720);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                        videoGames.videoSprite.x = videoGames.videoSprite.y = 0;
                        videoGames.videoSprite.blend = ADD;
                        playSound = 'snow';
                        playSoundVol = 0.6;
                    case 12:
                        randomPosition = false;
                        videoGames = new VideoSprite(Paths.video('streamervschat/spiral2'), true, false);
                        videoGames.videoSprite.scale.set(1280, 720);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                        videoGames.videoSprite.x = videoGames.videoSprite.y = 0;
                        videoGames.videoSprite.blend = ADD;
                        playSound = 'spiral';
                    case 13:
                        randomPosition = false;
                        videoGames = new VideoSprite(Paths.video('streamervschat/wheel'), true, false);
                        videoGames.videoSprite.scale.set(1280, 720);
                        videoGames.finishCallback = () -> addedMP4s.remove(videoGames);
                        addedMP4s.push(videoGames);
                        videoGames.videoSprite.x = videoGames.videoSprite.y = 0;
                        videoGames.videoSprite.blend = ADD;
                        playSound = 'wheel';
                    #end
                    case #if windows 14 #else 9 #end:
                        var transitions = ["fadeOut", "fadeColor", "slideLeft", "slideRight", "slideUp", "slideDown", "slideRandom", "fallRandom", "fallSequential"];
                        var transition = transitions[FlxG.random.int(0, transitions.length - 1)];
                        var duration = FlxG.random.float(0.5, 2);
                        TransitionState.fakeTransition({
                            transitionType: transition,
                            duration: duration,
                        });
                }

                if (randomPosition) {
                    var position = FlxG.random.int(0, 4);
                    switch (position) {
                        case 0:
                            if (errorMessage != null) {
                                errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                                errorMessage.screenCenter(Y);
                                errorMessages.add(errorMessage);
                            }

                            if (videoGames != null && videoGames.videoSprite != null) {
                                videoGames.videoSprite.x = (FlxG.width - FlxG.width / 4) - videoGames.videoSprite.width / 2;
                                videoGames.videoSprite.screenCenter(Y);
                                aliveVideos.add(videoGames);
                            }
                        case 1:
                            if (errorMessage != null) {
                                errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                                errorMessage.y = (effectiveDownScroll ? FlxG.height - errorMessage.height : 0);
                                errorMessages.add(errorMessage);
                            }

                            if (videoGames != null && videoGames.videoSprite != null) {
                                videoGames.videoSprite.x = (FlxG.width - FlxG.width / 4) - videoGames.videoSprite.width / 2;
                                videoGames.videoSprite.y = (effectiveDownScroll ? FlxG.height - videoGames.videoSprite.height : 0);
                                aliveVideos.add(videoGames);
                            }
                        case 2:
                            if (errorMessage != null) {
                                errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                                errorMessage.y = (effectiveDownScroll ? 0 : FlxG.height - errorMessage.height);
                                errorMessages.add(errorMessage);
                            }

                            if (videoGames != null && videoGames.videoSprite != null) {
                                videoGames.videoSprite.x = (FlxG.width - FlxG.width / 4) - videoGames.videoSprite.width / 2;
                                videoGames.videoSprite.y = (effectiveDownScroll ? 0 : FlxG.height - videoGames.videoSprite.height);
                                aliveVideos.add(videoGames);
                            }

                        case 3:
                            if (errorMessage != null) {
                                errorMessage.screenCenter(XY);
                                errorMessages.add(errorMessage);
                            }

                            if (videoGames != null && videoGames.videoSprite != null) {
                                videoGames.videoSprite.screenCenter(XY);
                                aliveVideos.add(videoGames);
                            }
                        case 4:
                            if (errorMessage != null) {
                                errorMessage.x = 0;
                                errorMessage.y = 0;
                                FlxTween.circularMotion(errorMessage, FlxG.width / 2 - errorMessage.width / 2, FlxG.height / 2 - errorMessage.height / 2,
                                    errorMessage.width / 2, 0, true, 6, true, {
                                        onStart: function(_) {
                                            errorMessages.add(errorMessage);
                                        },
                                        type: LOOPING
                                    });
                            }

                            if (videoGames != null && videoGames.videoSprite != null) {
                                videoGames.videoSprite.x = 0;
                                videoGames.videoSprite.y = 0;
                                FlxTween.circularMotion(videoGames.videoSprite, FlxG.width / 2 - videoGames.videoSprite.width / 2, FlxG.height / 2 - videoGames.videoSprite.height / 2,
                                    videoGames.videoSprite.width / 2, 0, true, 6, true, {
                                        onStart: function(_) {
                                            aliveVideos.add(videoGames);
                                        },
                                        type: LOOPING
                                    });
                            }
                    }
                }

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
            },
            'ghost' => function() {
                var ttl:Float = 15;
                var onEnd:(Void->Void) = function() {
                    modManager.setValue('sudden', 0);
                };
                var playSound:String = "ghost";
                var playSoundVol:Float = 0.5;
                var noIcon:Bool = false;

                modManager.setValue('sudden', 1);

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
            },
            'flashbang' => function() {
                var noIcon:Bool = true;
                var playSound:String = "bang";
                if (flashbangTimer != null && flashbangTimer.active)
                    flashbangTimer.cancel();
                var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
                whiteScreen.scrollFactor.set();
                whiteScreen.cameras = [camOther];
                add(whiteScreen);
                flashbangTimer.start(0.4, function(timer) {
                    camOther.flash(FlxColor.WHITE, 5, null, true);
                    remove(whiteScreen);
                    FlxG.sound.play(Paths.sound('streamervschat/ringing'), 0.4);
                });
                applyEffect(0, null, playSound, 1, noIcon);
            },
            'strongflashbang' => function() {
                var noIcon:Bool = true;
                var playSound:String = "bang";
                if (flashbangTimer != null && flashbangTimer.active)
                    flashbangTimer.cancel();
                var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
                whiteScreen.scrollFactor.set();
                whiteScreen.cameras = [camOther];
                add(whiteScreen);
                flashbangTimer.start(0.4, function(timer) {
                    camOther.flash(FlxColor.WHITE, 15, null, true);
                    remove(whiteScreen);
                    FlxG.sound.play(Paths.sound('streamervschat/ringingex'), 0.4);
                });
                applyEffect(0, null, playSound, 1, noIcon);
            },
            'nostrum' => function() {
                var ttl:Float = 13;
                var onEnd:(Void->Void) = function() {
                    for (i in 0...playerField.strumNotes.length)
                        playerField.strumNotes[i].visible = true;
                };
                var playSound:String = "nostrum";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;

                for (i in 0...playerField.strumNotes.length)
                    playerField.strumNotes[i].visible = false;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
            },
            'jackspam' => function() {
                var noIcon:Bool = true;
                var startingPoint = FlxG.random.int(5, 9);
                var endingPoint = FlxG.random.int(startingPoint + 6, startingPoint + 12);
                var dataPicked = FlxG.random.int(0, PlayfieldManager.mania[0]);
                for (i in startingPoint...endingPoint) {
                    addNoteSvCLegacy(0, i, i, dataPicked);
                }
            },
            'spam' => function() {
                var noIcon:Bool = true;
                var startingPoint = FlxG.random.int(5, 9);
                var endingPoint = FlxG.random.int(startingPoint + 5, startingPoint + 30);
                for (i in startingPoint...endingPoint) {
                    addNoteSvCLegacy(0, i, i);
                }
            },
            'insanespam' => function() {
                var noIcon:Bool = true;
                var startingPoint = FlxG.random.int(5, 9);
                var endingPoint = FlxG.random.int(startingPoint + 5, startingPoint + 40);
                for (i in startingPoint...endingPoint) {
                    addNoteSvCLegacy(0, i, i);
                }
            },
            'sever' => function() {
                var ttl:Float = 6;
                var onEnd:(Void->Void) = function() {
                    playerField.strumNotes[picked].alpha = 1;
                    severInputs[picked] = false;
                };
                var playSound:String = "sever";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                var alwaysEnd:Bool = true;

                var chooseFrom:Array<Int> = [];
                for (i in 0...severInputs.length) {
                    if (!severInputs[i])
                        chooseFrom.push(i);
                }
                if (chooseFrom.length <= 0)
                    picked = FlxG.random.int(0, 3);
                else
                    picked = chooseFrom[FlxG.random.int(0, chooseFrom.length - 1)];
                playerField.strumNotes[picked].alpha = 0;
                severInputs[picked] = true;

                var okayden:Array<Int> = [];
                for (i in 0...64) {
                    okayden.push(i);
                }
                var explosion = new FlxSprite().loadGraphic(Paths.image("streamervschat/explosion"), true, 256, 256);
                explosion.animation.add("boom", okayden, 60, false);
                explosion.animation.finishCallback = function(name) {
                    explosion.visible = false;
                    remove(explosion);
                    explosion.kill();
                };
                explosion.cameras = [camHUD];
                explosion.x = playerField.baseXPositions[picked] + playerField.strumNotes[picked].width / 2 - explosion.width / 2;
                explosion.y = playerField.strumNotes[picked].y + playerField.strumNotes[picked].height / 2 - explosion.height / 2;
                explosion.animation.play("boom", true);
                add(explosion);

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
            },
            'permasever' => function() {
                var ttl:Float = 6;
                var playSound:String = "sever";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;
                var alwaysEnd:Bool = false;
                var onEnd:(Void->Void) = function() {
                    trace("Nah, I don't feel like giving it back");
                };

                var chooseFrom:Array<Int> = [];
                for (i in 0...severInputs.length) {
                    if (!severInputs[i])
                        chooseFrom.push(i);
                }
                if (chooseFrom.length <= 0)
                    picked = FlxG.random.int(0, 3);
                else
                    picked = chooseFrom[FlxG.random.int(0, chooseFrom.length - 1)];
                playerField.strumNotes[picked].alpha = 0;
                severInputs[picked] = true;

                var okayden:Array<Int> = [];
                for (i in 0...64) {
                    okayden.push(i);
                }
                var baseY = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
                var explosion = new FlxSprite().loadGraphic(Paths.image("streamervschat/explosion"), true, 256, 256);
                explosion.animation.add("boom", okayden, 60, false);
                explosion.animation.finishCallback = function(name) {
                    explosion.visible = false;
                    remove(explosion);
                    explosion.kill();
                };
                explosion.cameras = [camHUD];
                explosion.x = (playerField.baseXPositions[picked] - playerField.baseXPositions[picked]) + playerField.strumNotes[picked].width / 2 - explosion.width / 2;
                explosion.y = (playerField.strumNotes[picked].y - baseY) + playerField.strumNotes[picked].height / 2 - explosion.height / 2;
                explosion.animation.play("boom", true);
                add(explosion);

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
            },
            'shake' => function() {
                var noIcon:Bool = false;
                var playSound:String = "shake";
                var playSoundVol:Float = 0.5;
                camHUD.shake(FlxG.random.float(0.03, 0.06), 9, null, true);
                camGame.shake(FlxG.random.float(0.03, 0.06), 9, null, true);
                applyEffect(0, null, playSound, playSoundVol, noIcon);
            },
            'poison' => function() {
                var ttl:Float = 5;
                var onEnd:(Void->Void) = function() {
                    drainHealth = false;
                    boyfriend.color = 0xffffff;
                };
                var playSound:String = "poison";
                var playSoundVol:Float = 0.6;
                var noIcon:Bool = false;

                drainHealth = true;
                boyfriend.color = 0xf003fc;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
            },
            'poisonbutworse' => function() {
                var ttl:Float = 5;
                var onEnd:(Void->Void) = function() {
                    trace("Nah, you're still poisoned");
                };
                var playSound:String = "poison";
                var playSoundVol:Float = 0.6;
                var noIcon:Bool = false;

                dmgMultiplier = 0.3;

                drainHealth = true;
                boyfriend.color = 0xf003fc;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
            },
            'dizzy' => function() {
                var ttl:Float = 8;
                var onEnd:(Void->Void) = function() {
                    if (drunkTween != null && drunkTween.active) {
                        drunkTween.cancel();
                        FlxDestroyUtil.destroy(drunkTween);
                    }
                    camHUD.scrollAngle = camAngle;
                    camGame.scrollAngle = camAngle;
                };
                var playSound:String = "dizzy";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;

                if (effectsActive["dizzy"] == null || effectsActive["dizzy"] <= 0) {
                    if (drunkTween != null && drunkTween.active) {
                        drunkTween.cancel();
                        FlxDestroyUtil.destroy(drunkTween);
                    }
                    drunkTween = FlxTween.num(0, 24, FlxG.random.float(1.2, 1.4), {
                        onUpdate: function(tween) {
                            camHUD.scrollAngle = (tween.executions % 4 > 1 ? 1 : -1) * cast(tween, NumTween).value + camAngle;
                            camGame.scrollAngle = (tween.executions % 4 > 1 ? -1 : 1) * cast(tween, NumTween).value / 2 + camAngle;
                        },
                        type: PINGPONG
                    });
                }

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'dizzy');
            },
            'noise' => function() {
                var noIcon:Bool = false;
                var noisysound:String = "";
                var noisysoundVol:Float = 1.0;
                switch (FlxG.random.int(0, 9)) {
                    case 0:
                        noisysound = "dialup";
                        noisysoundVol = 0.5;
                    case 1:
                        noisysound = "crowd";
                        noisysoundVol = 0.3;
                    case 2:
                        noisysound = "airhorn";
                        noisysoundVol = 0.6;
                    case 3:
                        noisysound = "copter";
                        noisysoundVol = 0.5;
                    case 4:
                        noisysound = "magicmissile";
                        noisysoundVol = 0.9;
                    case 5:
                        noisysound = "ping";
                        noisysoundVol = 1.0;
                    case 6:
                        noisysound = "call";
                        noisysoundVol = 1.0;
                    case 7:
                        noisysound = "knock";
                        noisysoundVol = 1.0;
                    case 8:
                        noisysound = "fuse";
                        noisysoundVol = 0.7;
                    case 9:
                        noisysound = "hallway";
                        noisysoundVol = 0.9;
                }
                noiseSound.stop();
                // noiseSound.loadEmbedded(Paths.sound("streamervschat/"+noisysound));
                // noiseSound.volume = noisysoundVol;
                // noiseSound.play(true);
                applyEffect(0, null, noisysound, noisysoundVol, noIcon, 'noise');
            },
            'flip' => function() {
                var ttl:Float = 5;
                var onEnd:(Void->Void) = function() {
                    camAngle = 0;
                    camHUD.angle = camAngle;
                    camGame.angle = camAngle;
                };
                var playSound:String = "flip";
                var playSoundVol:Float = 1;
                var noIcon:Bool = false;

                camAngle = 180;
                camHUD.angle = camAngle;
                camGame.angle = camAngle;
                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'flip');
            },
            'invuln' => function() {
                var ttl:Float = 30;
                var onEnd:(Void->Void) = function() {
                    boyfriend.invuln = false;
                    shieldSprite.visible = false;
                    dmgMultiplier = 1.0;
                };
                var playSound:String = "invuln";
                var playSoundVol:Float = 0.5;
                var noIcon:Bool = false;

                if (boyfriend.curCharacter.contains("pixel")) {
                    shieldSprite.x = boyfriend.x + boyfriend.width / 2 - shieldSprite.width / 2 - 150;
                    shieldSprite.y = boyfriend.y + boyfriend.height / 2 - shieldSprite.height / 2 - 150;
                } else {
                    shieldSprite.x = boyfriend.x + boyfriend.width / 2 - shieldSprite.width / 2;
                    shieldSprite.y = boyfriend.y + boyfriend.height / 2 - shieldSprite.height / 2;
                }
                shieldSprite.visible = true;
                dmgMultiplier = 0;
                boyfriend.invuln = true;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'invuln');
            },
            'desync' => function() {
                var ttl:Float = 8;
                var onEnd:(Void->Void) = function() {
                    FlxG.sound.music.time += delayOffset;
                    delayOffset = 0;
                    resyncVocals();
                };
                var playSound:String = "delay";
                var playSoundVol:Float = 1;
                var noIcon:Bool = true;

                delayOffset = FlxG.random.int(Std.int(Conductor.stepCrochet), Std.int(Conductor.stepCrochet) * 3);
                FlxG.sound.music.time -= delayOffset;
                resyncVocals();

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'desync');
            },
            'mute' => function() {
                var ttl:Float = 8;
                var onEnd:(Void->Void) = function() {
                    instVolumeMultiplier = 1;
                    vocalVolumeMultiplier = 1;
                };
                var playSound:String = "delay";
                var playSoundVol:Float = 1;
                var noIcon:Bool = true;

                if (FlxG.random.bool(15)) {
                    instVolumeMultiplier = 0;
                } else {
                    vocalVolumeMultiplier = 0;
                }

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'mute');
            },
            'ice' => function() {
                var noIcon:Bool = true;
                var startPoint:Int = FlxG.random.int(5, 9);
                var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
                var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
                addNoteSvCLegacy(4, startPoint, startPoint, -1);
                addNoteSvCLegacy(4, nextPoint, nextPoint, -1);
                addNoteSvCLegacy(4, lastPoint, lastPoint, -1);
            },
            'icebutmoreagressive' => function() {
                var noIcon:Bool = true;
                var startPoint:Int = FlxG.random.int(5, 9);
                var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
                var nextPoint2:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
                var nextPoint3:Int = FlxG.random.int(nextPoint2 + 2, nextPoint2 + 6);
                var nextPoint4:Int = FlxG.random.int(nextPoint3 + 2, nextPoint3 + 6);
                var nextPoint5:Int = FlxG.random.int(nextPoint4 + 2, nextPoint4 + 6);
                var nextPoint6:Int = FlxG.random.int(nextPoint5 + 2, nextPoint5 + 6);
                var nextPoint7:Int = FlxG.random.int(nextPoint6 + 2, nextPoint6 + 6);
                var nextPoint8:Int = FlxG.random.int(nextPoint7 + 2, nextPoint7 + 6);
                var nextPoint9:Int = FlxG.random.int(nextPoint8 + 2, nextPoint8 + 6);
                var lastPoint:Int = FlxG.random.int(nextPoint9 + 2, nextPoint9 + 6);
                addNoteSvCLegacy(4, startPoint, startPoint, -1);
                addNoteSvCLegacy(4, nextPoint, nextPoint, -1);
                addNoteSvCLegacy(4, nextPoint2, nextPoint2, -1);
                addNoteSvCLegacy(4, nextPoint3, nextPoint3, -1);
                addNoteSvCLegacy(4, nextPoint4, nextPoint4, -1);
                addNoteSvCLegacy(4, nextPoint5, nextPoint5, -1);
                addNoteSvCLegacy(4, nextPoint6, nextPoint6, -1);
                addNoteSvCLegacy(4, nextPoint7, nextPoint7, -1);
                addNoteSvCLegacy(4, nextPoint8, nextPoint8, -1);
                addNoteSvCLegacy(4, nextPoint9, nextPoint9, -1);
                addNoteSvCLegacy(4, lastPoint, lastPoint, -1);
            },
            'randomize' => function() {
                var ttl:Float = 10;
                var availableS:String = "";
                switch (FlxG.random.bool(15)) {
                    case true:
                        availableS = "invert";
                    case false:
                        availableS = "flip";
                }
                var onEnd:(Void->Void) = function() {
                    modManager.queueEase(MegaManager.conductor.currentStep, MegaManager.conductor.currentStep+3, availableS, 0, "sineInOut");
                };
                var playSound:String = "randomize";
                var playSoundVol:Float = 0.7;
                var noIcon:Bool = false;


                modManager.queueEase(MegaManager.conductor.currentStep, MegaManager.conductor.currentStep+3, availableS, .96, "sineInOut");
                trace(availableS);

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'randomize');
            },
            'randomizeAlt' => function() {
                var ttl:Float = 10;
                var onEnd:(Void->Void) = function() {
                    available = [];
                    doRandomize = false;
                    for (daNote in notes) {
                        if (daNote == null) continue;
                        else {
                            daNote.noteData = daNote.trueNoteData;
                        }
                    }
                    /*for (data => column in playerField.noteQueue) {
                        if (column[0] != null) {
                            if (column[0] == null) continue;
                            else {
                                column[0].noteData = available[column[0].noteData];
                            }
                        }
                    }*/
                };
                var playSound:String = "randomize";
                var playSoundVol:Float = 0.7;
                var noIcon:Bool = false;
                doRandomize = true;
                available = [];
                for (i in 0...PlayfieldManager.mania[0]+1) {
                    available.push(i);
                    trace("available: " + available);
                }
                FlxG.random.shuffle(available);
                switch (available) {
                    case [0, 1, 2, 3]:
                        available = [3, 2, 1, 0];
                    default:
                }
                for (daNote in notes) {
                    if (daNote == null) continue;
                    else {
                        daNote.noteData = available[daNote.noteData];
                    }
                }
                /*for (data => column in playerField.noteQueue) {
                    if (column[0] != null) {
                        if (column[0] == null) continue;
                        else {
                            column[0].noteData = available[column[0].noteData];
                        }
                    }
                }*/

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'randomizeAlt');
            },
            'opponentPlay' => function() {
                var ttl:Float = 12;
                var onEnd:(Void->Void) = function() {
                    opponentmode =  false;
                    playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
                    playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
                    playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
                    dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
                    dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
                    dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;
                    health = MaxHP + health;
                };
                var playSound:String = "randomize";
                var playSoundVol:Float = 0.7;
                var noIcon:Bool = true;

                opponentmode = true;
                playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
                playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
                playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
                dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
                dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
                dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;
                health = MaxHP - health;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'opponentPlay');
            },
            'bothplay' => function() {
                var ttl:Float = 12;
                var onEnd:(Void->Void) = function() {
                    bothMode = false;
                    playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
                    playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
                    playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
                    dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
                    dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
                    dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;
                };
                var playSound:String = "randomize";
                var playSoundVol:Float = 0.7;
                var noIcon:Bool = true;

                bothMode = true;
                playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
                playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
                playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
                dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
                dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
                dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'bothplay');
            },
            'fakeheal' => function() {
                var noIcon:Bool = true;
                addNoteSvCLegacy(5, 5, 9);
            },
            'spell' => function() {
                var noIcon:Bool = false;
                var playSound:String = "spell";
                var playSoundVol:Float = 0.66;
                var spellThing = new SpellPrompt();
                spellPrompts.push(spellThing);
                applyEffect(0, null, playSound, playSoundVol, noIcon, 'spell');
            },
            'terminate' => function() {
                var noIcon:Bool = true;
                terminateStep = 3;
            },
            'lowpass' => function() {
                var ttl:Float = 10;
                var onEnd:(Void->Void) = function() {
                    blurEffect.setStrength(0, 0);
                    //camHUD.filters.remove(filterMap.get("BlurLittle").filter);
                    //camGame.filters.remove(filterMap.get("BlurLittle").filter);
                    lowFilterAmount = 1;
                    vocalLowFilterAmount = 1;
                };
                var playSound:String = "delay";
                var playSoundVol:Float = 0.6;
                var noIcon:Bool = true;

                if (FlxG.random.bool(40)) {
                    lowFilterAmount = .0134;
                    //camGame.filters.push(filterMap.get("BlurLittle").filter);
                    blurEffect.setStrength(32, 32);
                } else {
                    vocalLowFilterAmount = .0134;
                    //camHUD.filters.push(filterMap.get("BlurLittle").filter);
                    //camGame.filters.push(filterMap.get("BlurLittle").filter);
                    blurEffect.setStrength(32, 32);
                }

                applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, true, 'lowpass');
            },
            'songSwitch' => function() {
                // var haltTween:NumTween = new NumTween(null, null);
                    FlxTween.num(playbackRate, 0, 0.5, {
                    onComplete: function(e) {
                        paused = false;
                        FlxG.sound.play(Paths.sound('streamervschat/itcomes'), 1, false, null, true, function() {
                            trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);
                            if (!FlxG.save.data.manualOverride) {
                                FlxG.save.data.manualOverride = true;

                                // Save original song data for restoration later
                                FlxG.save.data.storyWeek = PlayState.storyWeek;
                                FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
                                FlxG.save.data.difficulties = Difficulty.list; // just in case
                                FlxG.save.data.curDifficulty = curDifficulty; // just in case
                                FlxG.save.data.SONG = PlayfieldManager.SONG;
                                FlxG.save.data.storyDifficulty = PlayState.storyDifficulty;
                                FlxG.save.data.songPos = FlxG.sound.music.time;
                                FlxG.save.data.score = comboManager.songScore;
                                FlxG.save.data.rating = comboManager.ratingPercent;
                                FlxG.save.data.misses = comboManager.songMisses;
                                FlxG.save.data.health = health;

                                // Set up trap song
                                Difficulty.list = Difficulty.defaultList.copy();
                                PlayState.storyWeek = 0;
                                Mods.currentModDirectory = 'week1';
                                PlayfieldManager.SONG = Song.loadFromJson(backend.Highscore.formatSong('tutorial', Difficulty.list.length-1), Paths.formatToSongPath('tutorial'));
                                PlayState.storyDifficulty = Difficulty.list.length-1;

                                // Save trap song data for consistency checking
                                FlxG.save.data.trapStoryWeek = PlayState.storyWeek;
                                FlxG.save.data.trapCurrentModDirectory = Mods.currentModDirectory;
                                FlxG.save.data.trapDifficulties = Difficulty.list;
                                FlxG.save.data.trapCurDifficulty = curDifficulty;
                                FlxG.save.data.trapSONG = PlayfieldManager.SONG;
                                FlxG.save.data.trapStoryDifficulty = PlayState.storyDifficulty;

                                FlxG.save.flush();

                                if (Std.is(FlxG.state, APPlayState)) {
                                    MusicBeatState.resetState();
                                } else {
                                    FlxG.switchState(new APPlayState());
                                }
                            }
                        });
                    }
                }, function(t) {
                    playbackRate = t;
                });
            },
            'songSwitchSpecial' => function() {
                FlxTween.num(playbackRate, 0, 0.5, {
                    onComplete: function(e) {
                        paused = false;
                        FlxG.sound.play(Paths.sound('streamervschat/itcomes'), 1, false, null, true, function() {
                            trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);
                            if (!FlxG.save.data.manualOverride) {
                                FlxG.save.data.manualOverride = true;
                                // Save original song data for restoration later
                                FlxG.save.data.storyWeek = PlayState.storyWeek;
                                FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
                                FlxG.save.data.difficulties = Difficulty.list; // just in case
                                FlxG.save.data.curDifficulty = curDifficulty; // just in case
                                FlxG.save.data.SONG = PlayfieldManager.SONG;
                                FlxG.save.data.storyDifficulty = PlayState.storyDifficulty;
                                FlxG.save.data.songPos = FlxG.sound.music.time;

                                var specialSongList = ['Rise', 'Zeventeen', 'Pack-A-Punch', 'Driller', 'Test Field', 'Rawr', 'Fightback', 'Funky Fanta', 'Tag And Seek', 'Testimony', 'Fangirl Frenzy', 'Slowdown'];
                                var curSong = FlxG.random.int(0, specialSongList.length-1);

                                // Set up trap song
                                Difficulty.list = Difficulty.defaultList.copy();
                                PlayState.storyWeek = -1;
                                Mods.currentModDirectory = '';
                                PlayfieldManager.SONG = Song.loadFromJson(backend.Highscore.formatSong(specialSongList[curSong], Difficulty.list.length-1), Paths.formatToSongPath(specialSongList[curSong]));
                                PlayState.storyDifficulty = Difficulty.list.length-1;

                                // Save trap song data for consistency checking
                                FlxG.save.data.trapStoryWeek = PlayState.storyWeek;
                                FlxG.save.data.trapCurrentModDirectory = Mods.currentModDirectory;
                                FlxG.save.data.trapDifficulties = Difficulty.list;
                                FlxG.save.data.trapCurDifficulty = curDifficulty;
                                FlxG.save.data.trapSONG = PlayfieldManager.SONG;
                                FlxG.save.data.trapStoryDifficulty = PlayState.storyDifficulty;

                                FlxG.save.flush();

                                if (Std.is(FlxG.state, APPlayState)) {
                                    MusicBeatState.resetState();
                                } else {
                                    FlxG.switchState(new APPlayState());
                                }
                            }
                        });
                    }
                }, function(t) {
                    playbackRate = t;
                });
            },
            "freeze" => function() {
                var oldPlaybackRate:Float = playbackRate;
                var soundOptions:Array<String> = ["delay", "dialup"];
                var selectedSound:String = soundOptions[FlxG.random.int(0, soundOptions.length)];
                var onEnd:(Void->Void) = function() {
                    paused = false;
                    FlxTween.num(0, oldPlaybackRate, 0.5, {
                        onComplete: function(e) {
                            playbackRate = oldPlaybackRate;
                        }
                    }, function(t) {
                        playbackRate = t;
                    });
                };

                FlxTween.num(playbackRate, 0, 0.5, {
                    onComplete: function(e) {
                        paused = true;
                        FlxG.sound.play(Paths.sound('streamervschat/$selectedSound'), 1, false, null, true, function() {
                            FlxTween.num(playbackRate, 0, 0.5, {
                                onComplete: function(e) {
                                    FlxG.sound.play(Paths.sound('streamervschat/itcomes'), 1, false, null, true, function() {
                                        onEnd();
                                });
                            }});
                        });
                    }
                }, function(t) {
                    playbackRate = t;
                });
            }
        ];

        // addEffect("freeze");

        debugKeysDodge = ClientPrefs.keyBinds.get('dodge').copy();

		effectiveScrollSpeed = 1;
		effectiveDownScroll = ClientPrefs.data.downScroll;
		notePositions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
        blurEffect.setStrength(0, 0);
        addNonoLetters('note_left');
		addNonoLetters('note_down');
		addNonoLetters('note_up');
		addNonoLetters('note_right');
		addNonoLetters('reset');
        trace(nonoLetters);
        if (FileSystem.exists(Paths.txt("words")))
		{
			var content:String = sys.io.File.getContent(Paths.txt("words"));
			wordList = content.toLowerCase().split("\n");
		}
        wordList.push(PlayfieldManager.SONG?.song);
		trace(wordList.length + " words loaded");
		trace(wordList);
        try {
            wordList.concat(backend.MusicBeatState.words);
        } catch (e:Dynamic) {
            trace('Failed to concat backend.MusicBeatState.words: ' + e);
        }
		validWords.resize(0);
		for (word in wordList)
		{
			var containsNonoLetter:Bool = false;
			var nonoLettersArray:Array<String> = nonoLetters.split("");

			for (nonoLetter in nonoLettersArray)
			{
				if (word.contains(nonoLetter))
				{
					containsNonoLetter = true;
					break;
				}
			}

			if (!containsNonoLetter)
			{
				validWords.push(word.toLowerCase());
			}
		}

		if (validWords.length <= 0)
		{
			trace("wtf no valid words");
			var numWords:Int = 10; // Number of words to generate

			validWords = [for (i in 0...numWords) generateGibberish(5, nonoLetters)];
		}
		trace(validWords.length + " words accepted");
		trace(validWords);
		controlButtons.resize(0);
		/*for (thing in [
            ClientPrefs.keyBinds.get('note_left').copy().toString(),
            ClientPrefs.keyBinds.get('note_down').copy().toString(),
            ClientPrefs.keyBinds.get('note_up').copy().toString(),
            ClientPrefs.keyBinds.get('note_right').copy().toString(),
            ClientPrefs.keyBinds.get('reset').copy().toString(),
			"LEFT",
			"RIGHT",
			"UP",
			"DOWN",
			"SEVEN",
			"EIGHT",
			"NINE"
		])
		{
			controlButtons.push(StringTools.trim(thing).toLowerCase());
		}*/

        if (FlxG.save.data.songPos != 0 && !FlxG.save.data.manualOverride)
        {
            PlayState.savedTime = FlxG.save.data.songPos;
            FlxG.save.data.songPos = 0;
            FlxG.save.flush(); // This is why we flush
        }

        effectendsin = new FlxText(botplayTxt.x, botplayTxt.y, 1500, "EFFECT ENDS IN: ");
		effectendsin.screenCenter(X);
		effectendsin.alpha = 0;
		add(effectendsin);

        terminateSound = new FlxSound().loadEmbedded(Paths.sound('streamervschat/beep'));
        FlxG.sound.list.add(terminateSound);

        terminateMessage.visible = false;
        add(terminateMessage);

        errorMessages.cameras = [camOther];
		add(errorMessages);

        aliveVideos.cameras = [camOther];
        add(errorMessages);

        for (i in 0...PlayfieldManager.mania[0] + 1) {
			severInputs.push(false);
		}

        itemAmount = FlxG.random.int(1, 100);
        trace('Max Items = ' + 100);
        trace('itemAmount:' + itemAmount);

        if (PlayState.isPixelStage)
		{
			shieldSprite.loadGraphic(Paths.image("streamervschat/pixelUI/shield"));
			shieldSprite.alpha = 0.85;
			shieldSprite.setGraphicSize(Std.int(shieldSprite.width * PlayState.daPixelZoom));
			shieldSprite.updateHitbox();
			shieldSprite.antialiasing = false;
		}
		else
		{
			shieldSprite.loadGraphic(Paths.image("streamervschat/shield"));
			shieldSprite.alpha = 0.85;
			shieldSprite.scale.x = shieldSprite.scale.y = 0.8;
			shieldSprite.updateHitbox();
		}
		shieldSprite.visible = false;
		add(shieldSprite);

        if (cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) && !(Sys.args().contains('-livereload')))
        {
            //set_cpuControlled(false);
            cpuControlled = false;
            ClientPrefs.data.gameplaySettings.set('botplay', false);
            ClientPrefs.data.gameplaySettings.set('showcase', false);
            trace('CPU Controlled: ' + cpuControlled);
        } else {
            trace('CPU Controlled: ' + 'showcase allowed');
        }

        resistanceBar = new Bar(FlxG.width - 340, 400, 'mechanics/general/resistancebarv1', function() return resistanceAmount);
        resistanceBar.scrollFactor.set();
        resistanceBar.cameras = [camHUD];
        resistanceBar.visible = false;
        resistanceBar.angle = 270;
        add(resistanceBar);
        resistanceBar.setColors(0xFFFFFFFF, 0xFFFD00A9);

        zenetta = new Character(boyfriendGroup.x + dadGroup.x, boyfriendGroup.y, 'Zenetta-cowbell-p', true, BF);
        zenetta.scrollFactor.set(0.95, 0.95);
        zenetta.alpha = 0.0000000001;
        zenetta.cameras = [camGame];
        add(zenetta);

        if (ghostChat && !ghostChatCheck) //so that it re-triggers after death/reset
            triggerGhostChat();
    }

    public function addEffect(e:String)
        effectArray.push(e);

    public static var startOnTime:Float = 0;
	public var camMovement:Float = 40;
	public var velocity:Float = 1;
	public var campointx:Float = 0;
	public var campointy:Float = 0;
	public var camlockx:Float = 0;
	public var camlocky:Float = 0;
	public var camlock:Bool = false;
	public var bfturn:Bool = false;
    public var stuck:Bool = false;
    public var did:Int = 0;
    var entryDenied:Bool = false;

    override public function startCountdown():Bool
    {
        // Prevent countdown if song is not unlocked and start transition timer
        if (songNotUnlocked) {
            entryDenied = true;
            trace("Countdown blocked: Song not unlocked");

            // Start the transition timer only once
            if (!unlockTransitionStarted) {
                unlockTransitionStarted = true;
                new FlxTimer().start(3.0, function(timer:FlxTimer) {
                    // 99.99% chance for sticker transition, 0.01% for random transition
                    if (FlxG.random.bool(0.01)) {
                        // Use a random transition from available ones
                        var transitions = ["fade", "fadeColor", "slideLeft", "slideRight", "slideUp", "slideDown"];
                        var randomTransition = transitions[FlxG.random.int(0, transitions.length - 1)];
                        TransitionState.transitionState(new APSongLockedInfoState(currentSong, currentMod, missingItems), {
                            transitionType: randomTransition,
                            duration: 1.0
                        });
                    } else {
                        // Use sticker transition (default/preferred method)
                        FlxG.state.openSubState(new substates.StickerSubState(null, function(sticker) {
                            return new APSongLockedInfoState(currentSong, currentMod, missingItems);
                        }));
                    }
                });
            }

            return false;
        }

        if (PlayfieldManager.SONG.player1.toLowerCase().contains('zenetta') || PlayfieldManager.SONG.player2.toLowerCase().contains('zenetta') || PlayfieldManager.SONG.gfVersion.toLowerCase().contains('zenetta'))
        {
            itemAmount = 69;
            trace("RESISTANCE OVERRIDE!"); // what are the chances
        }
        // Check if there are any mustPress notes available
        /*if (allNotes.filter(function(note:Note):Bool
        {
            return note.field == playerField && note.noteType == '' && !note.isSustainNote;
        }).length == 0)
        {
            trace('No mustPress notes found. Pausing Note Generation...');
            trace('Waiting for Note Scripts...');
        }
        else
        {
            while (did < itemAmount && !stuck)
            {
                var foundOne:Bool = false;

                for(queue in playerField.noteQueue)
                {
                    for(note in queue)
                    {
                        if (did >= itemAmount)
                        {
                            break; // exit the loop if the required number of notes are created
                        }
                        if (note.mustPress
                            && note.noteType == ''
                            && !note.isSustainNote
                            && FlxG.random.bool(1)
                            && queue.filter(function(note:Note):Bool
                            {
                                return note.mustPress && note.noteType == '' && !note.isSustainNote;
                            }).length != 0)

                        {
                            note.isCheck = true;
							note.rgbShader.r = 0xFF313131;
							note.rgbShader.g = 0xFFFFFFFF;
							note.rgbShader.b = 0xFFB4B4B4;
                            note.noteType = 'Check Note';
                            did++;
                            foundOne = true;
                            Sys.print('\rGenerating Checks: ' + did + '/' + itemAmount);
							//trace('\rGenerating Checks: ' + did + '/' + itemAmount);
                        }
                        else if (queue.filter(function(note:Note):Bool
                        {
                            return note.mustPress && note.noteType == '' && !note.isSustainNote;
                        }).length == 0)
                        {
                            Sys.println('');
                            trace('Stuck!');
                            stuck = true;
                            // Additional handling for when it gets stuck
                        }
                    }
                }
                // Check if there are no more mustPress notes of type '' and not isSustainNote
                if (stuck)
                {
                    Sys.println('');
                    trace('No more mustPress notes of type \'\' found. Pausing Note Generation...');
                    trace('Waiting for Note Scripts...');
                    break; // exit the loop if no more mustPress notes of type '' are found
                }
            }
        }
        Sys.println('');*/

        super.startCountdown();

        // Check sanity locations on playing if enabled
        if (APPlayState.apGame != null)
        {
            var songName = PlayfieldManager.SONG.song;
            var modName = APPlayState.currentMod != null && APPlayState.currentMod.trim() != "" ? APPlayState.currentMod.trim() : null;
            APPlayState.apGame.checkSanityLocationsOnPlaying(songName, modName);
        }

        return true;
    }

    var releasethebeast:Bool = false;
    public function startResisting()
    {
        if (resistanceBar != null) resistanceBar.visible = true;
        resistanceAmount = 0;
        releasethebeast = true;
        FlxG.sound.play(Paths.sound('streamervschat/releasethebeast'), 1, false);
        trace("RESISTANCE MODE ACTIVATED!");
    }

    public static var ghostChat:Bool = false;
    var effectsRan:Int = -1;
    var ghostChatCheck:Bool = false;
    // I feel bad for the poor soul that has this trigger on them multiple times
    public function triggerGhostChat()
    {
        ghostChat = true;
        ghostChatCheck = true;
        randoTimer.start(FlxG.random.float(5, 10), function(tmr:FlxTimer) {
            doEffect(effectArray[curEffect]);
            tmr.reset(FlxG.random.float(5, 10) + (FlxG.random.bool(10) ? FlxG.random.float(1, 20) : 0));
        });
        trace("Ghost Chat Activated! L E T  T H E  C H A O S  B E G I N !");
    }

    function addNonoLetters(keyBind:String) {
        var keys:Null<Array<FlxKey>> = ClientPrefs.keyBinds.get(keyBind);
        if (keys != null) {
            for (key in keys) {
                var keyName:String = InputFormatter.getKeyName(key);
                if (keyName.length == 1 && keyName != "-") {
                    nonoLetters += keyName.toLowerCase();
                }
            }
        }
    }

    function showUnlockInfoPanel() {
        var songDisplayName = currentSong != null && currentSong != "" ? currentSong : "this song";
        var modDisplayName = currentMod != null && currentMod != "" ? " from " + currentMod : "";

        var content = "You haven't unlocked " + songDisplayName + modDisplayName + " yet.\\n\\n" +
                     "Complete more checks in the Archipelago\\nmultiworld to unlock new songs!\\n\\n" +
                     "Press ESC or ENTER to return to Freeplay.";

        archipelago.substates.InfoPanelSubstate.show(
            "SONG LOCKED",
            content,
            FlxColor.RED,
            returnToFreeplay
        );
    }

    function returnToFreeplay() {
        // Use FreeplayManager's built-in method to return to freeplay
        FreeplayManager.openFreeplay();
    }

    override function destroy()
	{
		if (drunkTween != null && drunkTween.active)
		{
			drunkTween.cancel();
		}

		if (effectTimer != null && effectTimer.active)
			effectTimer.cancel();
		if (randoTimer != null && randoTimer.active)
			randoTimer.cancel();

        instance = null;
		super.destroy();

        if (ClientPrefs.data.gameplaySettings.get('chartModifier') != 'Normal' || ClientPrefs.data.gameplaySettings.get('chartModifier') == null) {
        ClientPrefs.data.gameplaySettings.set('chartModifier', 'Normal');

        if (chartModifier != "Normal") {
            chartModifier = "Normal";
            ArchPopup.startPopupCustom('Chart Modifier Reset', 'Chart Modifier has been reset to Normal.', 'archWhite');
        }
    }

	}

    var oldRate:Int = 60;
	var noIcon:Bool = false;
	var available:Array<Int> = [];

    public function doEffect(effect:String)
    {
        // trace('im finna act up');
        if (!APEntryState.inArchipelagoMode) return; //why are you here lol

        if (paused || endingSong || transitioning) return;

        ghostChatCheck = true; //check every time an effect runs so it doesn't get stuck

        // Additional checks to prevent effects during transitions or ranking
        if (backend.TransitionState.currenttransition != null ||
            (subState != null && Std.is(subState, substates.RankingSubstate))) return;

        effectsRan++;

        if (APEntryState.inArchipelagoMode && (paused || endingSong || transitioning)) {
            new FlxTimer().start(0.1, function(tmr:FlxTimer) {
                if (!paused && !endingSong && !transitioning &&
                    backend.TransitionState.currenttransition == null &&
                    !(subState != null && Std.is(subState, substates.RankingSubstate))) {
                    doEffect(effect);
                }
                FlxDestroyUtil.destroy(tmr);
            });
            return;
        }

        if (effectMap.exists(effect)) {
            effectMap.get(effect)();
            trace('running effect: $effect');
        } else {
            trace("Effect not found: " + effect);
        }
    }

	inline public function applyEffect(ttl:Float, onEnd:(Void->Void), playSound:String, playSoundVol:Float, noIcon:Bool, alwaysEnd:Bool = false, ?effect:String = "")
	{
		effectsActive[effect] = (effectsActive[effect] == null ? 0 : effectsActive[effect] + 1);

		if (playSound != "") {
			FlxG.sound.play(Paths.sound("streamervschat/" + playSound), playSoundVol);
		}

		new FlxTimer().start(ttl, function(tmr:FlxTimer) {
			effectsActive[effect]--;
			if (effectsActive[effect] < 0)
				effectsActive[effect] = 0;

			if (onEnd != null && (effectsActive[effect] <= 0 || alwaysEnd))
				onEnd();

			FlxDestroyUtil.destroy(tmr);
		});

		if (!noIcon) {
			var icon = new FlxSprite().loadGraphic(Paths.image("streamervschat/effectIcons/" + effect));
			icon.cameras = [camOther];
			icon.screenCenter(X);
			icon.y = (effectiveDownScroll ? FlxG.height - icon.frameHeight - 10 : 10);
			icon.scale.x = icon.scale.y = 0.5;
			icon.updateHitbox();
			FlxTween.tween(icon, {"scale.x": 1, "scale.y": 1}, 0.1, {
				onUpdate: function(tween) {
					icon.updateHitbox();
					icon.screenCenter(X);
					icon.y = (effectiveDownScroll ? FlxG.height - icon.frameHeight - 10 : 10);
				}
			});
			add(icon);
			new FlxTimer().start(2, function(tmr:FlxTimer) {
				icon.kill();
				remove(icon);
				FlxDestroyUtil.destroy(icon);
				FlxDestroyUtil.destroy(tmr);
			});
		}
	}

    var apNotes:Array<archipelago.APNote> = [];
    private override function generateSong(preload:Bool = false):Void
    {
        super.generateSong(preload);
        if (PlayfieldManager.SONG == null || archipelago.APItem.activeItem?.name=="Tutorial Trap" || preload) return;
        try {
        apNotes = archipelago.APNote.replaceInQueue(playerField.noteQueue, apGame.excludeCheckedLocations(apGame.noteData(currentSong, currentMod)));
        } catch (e:Dynamic) {
            trace('Error replacing notes with APNotes: ' + e);
            apNotes = null;
        }

        for (field in playfields.members)
            field.clearStackedNotes();
    }

    private override function finishPreloadedGeneration():Void {
        super.finishPreloadedGeneration();

        // Ensure apNotes is populated in case preload didn't work
        if (apNotes == null) {
            try {
                apNotes = archipelago.APNote.replaceInQueue(playerField.noteQueue, apGame.excludeCheckedLocations(apGame.noteData(currentSong, currentMod)));
            } catch (e:Dynamic) {
                trace('Error populating apNotes in finishPreloadedGeneration: ' + e);
                apNotes = [];
            }
        }
    }

	// override public function generateNotes(song:SwagSong, AI:Array<Array<Float>>):Void
	// 	super.generateNotes(song, AI);

    function updateScrollUI()
	{
		timeTxt.y = (effectiveDownScroll ? FlxG.height - 44 : 19);
		timeBar.y = (timeTxt.y + (timeTxt.height / 4)) + 4;
        playfield.modManager.queueEase(MegaManager.conductor.currentStep, MegaManager.conductor.currentStep+3, 'reverse',  effectiveDownScroll ? 1 : 0, "sineInOut");
		healthBar.y = (effectiveDownScroll ? FlxG.height * 0.1 : FlxG.height * 0.875) + 4;
		//healthBar2.y = (effectiveDownScroll ? FlxG.height * 0.1 : FlxG.height * 0.875) + 4;
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		scoreTxt.y = (effectiveDownScroll ? FlxG.height * 0.1 - 72 : FlxG.height * 0.9 + 36);
	}

    var shape:Array<Array<Int>> = [
        [1, 1, 1, 1],
        [1, 0, 0, 0],
        [1, 1, 1, 0],
        [1, 0, 0, 0],
        [1, 1, 1, 1]
    ];

    var typedShape:Array<Array<Int>> = [
        [1, 1, 1, 1],
        [1, -1, -1, -1],
        [1, 1, 1, -1],
        [1, -1, -1, -1],
        [1, 1, 1, 1]
    ];

    public function createNotesFromTable(table:DTable<Int>, distance:Int):Void {
        var rows = table.toArray().length;
        var cols = table.toArray()[0].length;

        for (i in 0...rows) {
            for (j in 0...cols) {
                if (table.getCell(i, j) == 1) {
                    var min = i * distance;
                    var max = min + distance;
                    addNoteSvCLegacy(0, min, max, j);
                }
            }
        }
    }

    public function createNotesFromArray(array:Array<Int>, distance:Int):Void {
        for (i in 0...array.length) {
            if (array[i] == 1) {
                var min = i * distance;
                var max = min + distance;
                addNoteSvCLegacy(0, min, max, -1);
            }
        }
    }

    public function createNotesFromArrayTable(array:Array<Array<Int>>, distance:Int):Void {
        for (i in 0...array.length) {
            for (j in 0...array[i].length) {
                if (array[i][j] == 1) {
                    var min = i * distance;
                    var max = min + distance;
                    addNoteSvCLegacy(0, min, max, j);
                }
            }
        }
    }

    public function createTypedNotesFromTable(table:DTable<Int>, distance:Int):Void {
        var rows = table.toArray().length;
        var cols = table.toArray()[0].length;

        for (i in 0...rows) {
            for (j in 0...cols) {
                var type = table.getCell(i, j);
                if (type != -1) {
                    var min = i * distance;
                    var max = min + distance;
                    addNoteSvCLegacy(type, min, max, j);
                }
            }
        }
    }

    public function createTypedNotesFromArray(array:Array<Int>, distance:Int):Void {
        for (i in 0...array.length) {
            var type = array[i];
            if (type != -1) {
                var min = i * distance;
                var max = min + distance;
                addNoteSvCLegacy(type, min, max, -1);
            }
        }
    }

    public function createTypedNotesFromArrayTable(array:Array<Array<Int>>, distance:Int):Void {
        for (i in 0...array.length) {
            for (j in 0...array[i].length) {
                var type = array[i][j];
                if (type != -1) {
                    var min = i * distance;
                    var max = min + distance;
                    addNoteSvCLegacy(type, min, max, j);
                }
            }
        }
    }

	function addNoteSvCLegacy(type:Int = 0, min:Int = 0, max:Int = 0, ?specificData:Int)
	{
		if (startingSong)
			return;
		var pickSteps = FlxG.random.int(min, max);
		var pickTime = Conductor.songPosition + pickSteps * Conductor.stepCrochet;
		var pickData:Int = 0;

		if (PlayfieldManager.SONG.notes.length <= Math.floor((MegaManager.conductor.currentStep + pickSteps + 1) / 16))
			return;

		if (PlayfieldManager.SONG.notes[Math.floor((MegaManager.conductor.currentStep + pickSteps + 1) / 16)] == null)
			return;

		if (specificData == null)
		{
			if (PlayfieldManager.SONG.notes[Math.floor((MegaManager.conductor.currentStep + pickSteps + 1) / 16)].mustHitSection)
			{
				pickData = FlxG.random.int(0, PlayfieldManager.mania);
			}
			else
			{
				// pickData = FlxG.random.int(4, 7);
				pickData = FlxG.random.int(0, PlayfieldManager.mania);
			}
		}
		else if (specificData == -1)
		{
			var chooseFrom:Array<Int> = [];
			for (i in 0...severInputs.length)
			{
				if (!severInputs[i])
					chooseFrom.push(i);
			}

			if (chooseFrom.length <= 0)
				pickData = FlxG.random.int(0, PlayfieldManager.mania);
			else
				pickData = chooseFrom[FlxG.random.int(0, chooseFrom.length - 1)];
		}
		else
		{
			if (PlayfieldManager.SONG.notes[Math.floor((MegaManager.conductor.currentStep + pickSteps + 1) / 16)].mustHitSection)
			{
				pickData = specificData % Note.ammo[PlayfieldManager.mania];
			}
			else
			{
				// pickData = specificData % 4 + 4;
				pickData = specificData % Note.ammo[PlayfieldManager.mania];
			}
		}
		var swagNote:Note = ClientPrefs.data.useExperimentalNotePool ?
			managers.NotePoolManager.createNote(pickTime, pickData, null, false, false, this) :
			new Note(pickTime, pickData);
		switch (type)
		{
			case 1:
				swagNote.noteType = 'Mine Note';
				swagNote.reloadNote();
				swagNote.isMine = true;
				swagNote.specialNote = true;
				swagNote.hitCausesMiss = true;
                swagNote.ratingDisabled = true;
                swagNote.cod = 'Hit a Mine Note.';
			case 2:
				swagNote.noteType = 'Warning Note';
				swagNote.reloadNote();
				swagNote.isAlert = true;
				swagNote.specialNote = true;
				swagNote.hitCausesMiss = false;
                swagNote.ratingDisabled = true;
                swagNote.cod = 'Missed a Warning Note.';
			case 3:
				swagNote.noteType = 'Heal Note';
				swagNote.reloadNote();
				swagNote.isHeal = true;
				swagNote.specialNote = true;
				swagNote.hitCausesMiss = false;
                swagNote.ratingDisabled = true;
			case 4:
				swagNote.noteType = 'Ice Note';
				swagNote.reloadNote();
				swagNote.isFreeze = true;
				swagNote.hitCausesMiss = true;
				swagNote.specialNote = true;
                swagNote.ratingDisabled = true;
                swagNote.cod = 'Hit a Ice Note.';
			case 5:
				swagNote.noteType = 'Fake Heal Note';
				swagNote.reloadNote();
				swagNote.isFakeHeal = true;
				swagNote.hitCausesMiss = true;
				swagNote.specialNote = true;
                swagNote.ratingDisabled = true;
                swagNote.cod = 'Hit a Fake Heal Note.';
			default:
				swagNote.ignoreNote = false;
				swagNote.specialNote = false;
                swagNote.ratingDisabled = true;
                swagNote.cod = 'Missed a Spam/Jack Note.';
		}
		swagNote.mustPress = true;
		if (playfield.chartModifier == "SpeedRando")
			{swagNote.multSpeed = FlxG.random.float(0.1, 2);}
		if (playfield.chartModifier == "SpeedUp")
			{}
		swagNote.x += FlxG.width / 2;

        if (swagNote.fieldIndex == -1 && swagNote.field == null)
            swagNote.field = swagNote.mustPress ? playfield.playfield.playerField : playfield.playfield.dadField;
        if (swagNote.field != null)
            swagNote.fieldIndex = playfield.playfields.members.indexOf(swagNote.field);
        var playfield:PlayField = playfield.playfields.members[swagNote.fieldIndex];
        if (playfield != null)
        {
            playfield.queue(swagNote); // queues the note to be spawned
            unspawnNotes.push(swagNote);
            playfield.allNotes.push(swagNote); // just for the sake of convenience
        }
        else
        {
            swagNote.destroy();
        }
		unspawnNotes.sort(PlayState.sortByTime);
        playfield.allNotes.sort(PlayState.sortByTime);
        for (field in playfield.playfields.members)
			field.clearStackedNotes();
	}

	public var isFrozen:Bool = false;
	var doRandomize:Bool = false;
    var lowpass:FlxSoundFilter;
    var lowpassVocal:FlxSoundFilter;
    override public function update(elapsed:Float)
    {

        if (archipelago.APInfo.inMinigame != None)
        {
            // Save current state before switching to minigame
            if (APEntryState.apGame != null) {
                APEntryState.apGame.updateSaveData();
            }

            switch (archipelago.APInfo.inMinigame) {
                case Uno:
                    FlxG.switchState(new archipelago.traps.games.APUnoTrapState());
                    return;
                case Pong:
                    FlxG.switchState(new archipelago.traps.games.APPongTrapState());
                    return;
                case None:
            }
        }
        // If Legacy Lua settings are being edited, don't allow AP PlayState during gameplay
        // This prevents conflicts but doesn't interrupt mid-song
        if (options.legacylua.LegacyLuaSettingsState.inLegacyLuaSettingsMode && !startedCountdown) {
            // Only switch if we haven't started the song yet to avoid interrupting gameplay
            FlxG.switchState(new PlayState());
            return;
        }

        // If we're in Legacy Lua testing mode, switch to regular PlayState
        if (PlayState.isLegacyLuaTest && !startedCountdown) {
            FlxG.switchState(new PlayState());
            return;
        }

        if (zenetta?.holdTimer > Conductor.stepCrochet * 0.001 * zenetta?.singDuration
            && zenetta?.animation.curAnim.name.startsWith('sing')
            && !zenetta?.animation.curAnim.name.endsWith('miss'))
            zenetta?.dance();

        // if (archipelago.APItem.activeItem is archipelago.APItem.APChartModifier && cast(archipealgo.APItem.activeItem:archipelago.APItem.APChartModifier).chartModifier != chartModifier)
        //
        if ((startedCountdown && !(inCutscene || (function()
        {
            var hasVideoSprite = false;
            this.members.map(function(member) {
                if (Std.is(member, objects.VideoSprite)) {
                    hasVideoSprite = true;
                    return member;
                }
                return member;
            });
            return hasVideoSprite;
        })())) && deathByLink) {
            var cause:String = "";
            {
                var extraMessages = [
                    "Sounds like a skill issue...",
                    "They must suck...",
                    "At least they tried...",
                    "What a noob...",
                    "At least you aren't that bad... [pause:0.5]Or are you?",
                    "Maybe next time...",
                    "You can always try again...",
                    "This doesn't affect you, right?",
                    "What a shame...",
                    "Better luck next time...",
                    'Eh, you can always play ${PlayfieldManager.SONG.song} again...',
                    "Dang...",
                    "RIP..."
                ];

                // Find player ID from name and add game-specific messages
                if (apGame?.info() != null && deathLinkPacket?.source != null) {
                    var playerID:Int = -1;
                    var apClient = apGame.info();

                    // Find player ID by name - iterate through _slotInfo
                    @:privateAccess
                    for (id in apClient._slotInfo.keys()) {
                        if (apClient._slotInfo.get(id).name == deathLinkPacket.source) {
                            playerID = id;
                            break;
                        }
                    }

                    // Get player's game and add game-specific messages
                    if (playerID != -1) {
                        var playerGame = apClient.get_player_game(playerID);

                        switch (playerGame.toLowerCase()) {
                            case "friday night funkin":
                                extraMessages = extraMessages.concat([
                                    "Skill issue detected...",
                                    "They couldn't hit the notes...",
                                    "Rhythm game more like skill issue game...",
                                    "Maybe they should practice on easy mode...",
                                    "Beep boop beep... FAIL!"
                                ]);
                            case "minecraft" | "minecraft fabric" | "minecraft fabric yuta edition":
                                extraMessages = extraMessages.concat([
                                    "At least they didn't lose their diamonds... right?"
                                ]);
                            case "the legend of zelda: a link to the past":
                                extraMessages = extraMessages.concat([
                                    "Link has fallen...",
                                    "The princess will have to wait...",
                                    "Game Over! Press Start to continue...",
                                    "Even the Master Sword couldn't save them...",
                                    "Ganon laughs in the distance..."
                                ]);
                            case "super metroid":
                                extraMessages = extraMessages.concat([
                                    "Samus has lost all energy...",
                                    "The mission has failed...",
                                    "Planet Zebes claims another victim...",
                                    "Should have collected more energy tanks...",
                                    "The last Metroid is still in captivity..."
                                ]);
                            case "super mario world":
                                extraMessages = extraMessages.concat([
                                    "Mario has lost a life...",
                                    "Game Over! Thank you Mario!",
                                    "Bowser wins this round...",
                                    "Should have grabbed that mushroom...",
                                    "Mamma mia! That's-a gonna hurt!"
                                ]);
                            case "flipwitch forbidden sex hex":
                                extraMessages = extraMessages.concat([
                                    "Sounds like they had fun...",
                                    "Wow, they get more game than you!",
                                    "Stop getting fucked, maybe you'll win next time..."
                                ]);
                            case "undertale":
                                extraMessages = extraMessages.concat([
                                    "They fell down...",
                                    "Don't forget to save...",
                                    "You idiot...",
                                    "Hope they listen to Toriel next time...",
                                    "The underground claims another soul..."
                                ]);
                            case "hollow knight":
                                extraMessages = extraMessages.concat([
                                    "They have been defeated...",
                                    "The kingdom of Hallownest mourns another...",
                                    "Should have listened to the Nailsmith...",
                                    "Even the Radiance couldn't save them...",
                                    "The void claims another..."
                                ]);
                            case "celeste":
                                extraMessages = extraMessages.concat([
                                    "They couldn't reach the summit...",
                                    "Maybe next time they'll make it to the top...",
                                    "Madeline needs a break...",
                                    "The mountain claims another...",
                                    "Breathe in, breathe out... and try again..."
                                ]);
                            case "dark souls" | "dark souls ii" | "dark souls iii":
                                extraMessages = extraMessages.concat([
                                    "They have been hollowed...",
                                    "The bonfire fades to embers...",
                                    "You Died. Try again, Undead...",
                                    "Should have summoned a phantom...",
                                    "Even the gods couldn't save them..."
                                ]);
                            case "stardew valley":
                                extraMessages = extraMessages.concat([
                                    "They passed out from exhaustion...",
                                    "The farm will have to wait...",
                                    "Should have eaten more food...",
                                    "Even the Joja Corporation couldn't save them...",
                                    "The valley claims another..."
                                ]);
                            case "deltarune":
                                extraMessages = extraMessages.concat([
                                    "They fell into the dark...",
                                    "Don't forget to save...",
                                    "Hope they listen to Ralsei next time...",
                                    "Are they gonna go back to the light...?",
                                    "Are they rebelling against their soul again?"
                                ]);
                            case "glover":
                                extraMessages = extraMessages.concat([
                                    "They dropped the ball...",
                                    "The world of Glover spins on without them...",
                                    "Even the magical glove couldn't save them...",
                                    "Seems they lost their balls too!",
                                    "Mr. Tip says: [pause:0.5]'Try not dying!'"
                                    ]);
                            default:
                                extraMessages = extraMessages.concat([
                                    "They failed at " + playerGame + "...",
                                    "Game over in " + playerGame + "!",
                                    "Apparently " + playerGame + " is harder than it looks...",
                                    "RIP to another " + playerGame + " player..."
                                ]);
                        }
                    }
                }

                if (deathLinkPacket.cause != null && cast(deathLinkPacket.cause, String).trim() != "") {
                    var randomMsg = extraMessages[FlxG.random.int(0, extraMessages.length - 1)];
                    cause = deathLinkPacket.cause + "\n[pause:0.5](" + randomMsg + ")";
                }
            }
            // catch(e) {
            //     trace('DEATHLINKPACK ERROR: ' + e);
            //     trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            //     trace('e stack: ' + e.stack);
            // }
            try {
                if (cause.trim() == "") cause = deathLinkPacket.source + " has died.\n[pause:0.5](How Unfortunate...)";
            } catch (e:Dynamic) {
                cause = "???\n[pause:0.5](Someone died... somehow...)\n[pause:0.5](Unsure how...)";
            }
            COD.setCOD(null, cause);
            if (alreadyKilledByLink) {
                FlxG.switchState(new substates.GameOverSubstate(boyfriend, new PlayState()));
            } else {
                alreadyKilledByLink = true;
                die();
            }
            trace("Triggering DeathLink!");
        }

        if (lowpass == null) {
			lowpass = new FlxSoundFilter();
			lowpass.filterType = FlxSoundFilterType.LOWPASS;
			add(lowpass);

            lowpassVocal = new FlxSoundFilter();
			lowpassVocal.filterType = FlxSoundFilterType.LOWPASS;
			add(lowpassVocal);
        }

        if (lowpass != null) lowpass.applyFilter(FlxG.sound.music);
        if (lowpassVocal != null) {
            if (vocals != null && vocals.length > 0) lowpassVocal.applyFilter(vocals);
            if (opponentVocals != null && opponentVocals.length > 0) lowpassVocal.applyFilter(opponentVocals);
        }

        #if cpp
		if(FlxG.sound.music != null && FlxG.sound.music.playing)
            lowpass.gainHF = lowFilterAmount;

		if(vocals != null && vocals.playing)
            lowpassVocal.gainHF = vocalLowFilterAmount;

		if(opponentVocals != null && opponentVocals.playing)
            lowpassVocal.gainHF = vocalLowFilterAmount;

        /*if(gfVocals != null && gfVocals.playing)
		{
			@:privateAccess
			{
				var af = lime.media.openal.AL.createFilter(); // create AudioFilter
				lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, vocalLowFilterAmount ); // set gainhf
				lime.media.openal.AL.sourcei( gfVocals._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
				//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
			}
		}

		for (track in tracks)
		{
			if(track != null && track.playing)
			{
				@:privateAccess
				{
					var af = lime.media.openal.AL.createFilter(); // create AudioFilter
					lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
					lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
					lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, vocalLowFilterAmount ); // set gainhf
					lime.media.openal.AL.sourcei( track._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
					//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
				}
			}
		}*/
		#end

        curEffect = FlxG.random.int(0, 38);
        if (isFrozen) boyfriend.stunned = true;
        if (notes != null)
		{
			notes.forEachAlive(function(note:Note)
			{
				if (severInputs[picked] == true && note.noteData == picked)
					note.blockHit = true;
				else
					note.blockHit = false;
			});
		}

        #if windows
		for (video in addedMP4s)
		{
			if (video != null)
            {
				video.cameras = [camHUD];
            }
		}
        #end

        if (activeItems[0] > 0 && health <= 0)
        {
            health = 1;
            activeItems[0]--;
            ArchPopup.startPopupCustom('You Used A Shield!', '-1 Shield ( ' + activeItems[0] + ' Left)', 'archWhite');
        }

        if (activeItems[1] >= 1)
        {
            activeItems[1] -= 1;
			if (activeItems[0] > 0 && health <= 0)
			{
				health = 1;
				activeItems[0]--;
				ArchPopup.startPopupCustom('You Used A Shield!', '-1 Shield ( ' + activeItems[0] + ' Left)', 'archColor');
			}
			else
            {
                die();
                COD.setCOD(null, 'Blue Balls Curse\n[pause:0.2](Better luck next time!)');
            }
        }

        if (drainHealth)
		{
			health = Math.max(0.0000000001, health - (FlxG.elapsed * 0.425 * dmgMultiplier));
		}

		for (i in 0...spellPrompts.length)
		{
			if (spellPrompts[i] == null)
			{
				continue;
			}
			else if (spellPrompts[i].ttl <= 0)
			{
                COD.setCOD('Apparently, ${apGame.info().slot} is bad at spelling.');
				die();
				FlxG.sound.play(Paths.sound('streamervschat/spellfail'));
				camOther.flash(FlxColor.RED, 1, null, true);
				spellPrompts[i].kill();
				FlxDestroyUtil.destroy(spellPrompts[i]);
				remove(spellPrompts[i]);
				spellPrompts.remove(spellPrompts[i]);
			}
			else if (!spellPrompts[i].alive)
			{
				remove(spellPrompts[i]);
				FlxDestroyUtil.destroy(spellPrompts[i]);
			}
		}

        for (timestamp in terminateTimestamps)
        {
            if (timestamp == null || !timestamp.alive)
                continue;

            if (timestamp.tooLate)
            {
                if (!timestamp.didLatePenalty)
                {
                    timestamp.didLatePenalty = true;
                    var healthToTake = health / 3 * dmgMultiplier;
                    health -= healthToTake;
                    boyfriend.playAnim('hit', true);
                    FlxG.sound.play(Paths.sound('streamervschat/theshoe'));
                    timestamp.kill();
                    terminateTimestamps.resize(0);

                    var theShoe = new FlxSprite();
                    theShoe.loadGraphic(Paths.image("streamervschat/theshoe"));
                    theShoe.x = boyfriend.x + boyfriend.width / 2 - theShoe.width / 2;
                    theShoe.y = -FlxG.height / defaultCamZoom;
                    add(theShoe);
                    FlxTween.tween(theShoe, {y: boyfriend.y + boyfriend.height - theShoe.height}, 0.2, {
                        onComplete: function(tween)
                        {
                            if (tween.executions >= 2)
                            {
                                theShoe.kill();
                                FlxDestroyUtil.destroy(theShoe);
                                tween.cancel();
                                FlxDestroyUtil.destroy(tween);
                            }
                        },
                        type: PINGPONG
                    });
                }
            }
        }
        for (func in updateFunctions) {
            if (func != null)
                func.func();
            func.activated = true;
        }

        if (ghostChat && effectsRan <= 1 && ghostChatCheck && randoTimer != null && (randoTimer.timeLeft <= 0 || !randoTimer.active)) {
            ghostChatCheck = false;
            randoTimer.start(FlxG.random.float(5, 10), function(tmr:FlxTimer) {
                doEffect(effectArray[curEffect]);
                tmr.reset(FlxG.random.float(5, 10) + (FlxG.random.bool(10) ? FlxG.random.float(1, 20) : 0));
            });
            trace("Ghost Chat Re-activated!");
        } else if (ghostChat && effectsRan > 0 && ghostChatCheck && (randoTimer == null || randoTimer != null && randoTimer.timeLeft <= 0 || randoTimer != null && !randoTimer.active)) {
            ghostChatCheck = false;
            randoTimer.start(FlxG.random.float(5, 10), function(tmr:FlxTimer) {
                doEffect(effectArray[curEffect]);
                tmr.reset(FlxG.random.float(5, 10) + (FlxG.random.bool(10) ? FlxG.random.float(1, 20) : 0));
            });
            trace("Ghost Chat got stuck! Re-activating!");
        }

        if (bfAscend) boyfriendGroup.y += 0.01;

        if (releasethebeast && !noHorny) {
            if (resistanceAmount > 1) resistanceAmount = 1;
            if (resistanceAmount <= 0) resistanceAmount = 0;
            if (resistanceAmount == 1) health -= (0.00051 / (60 / ClientPrefs.data.framerate)) * dmgMultiplier;

            zenetta.alpha = 0.0000000001 + resistanceAmount;
            boyfriend.alpha = (1 - resistanceAmount);
            zenetta.x = boyfriend.x;
            zenetta.y = boyfriend.y - 280;

            if (resistanceAmount == 1 && health == 0)
                die(true, "You have been...\n[pause:0.5] We shouldn't talk about it.\n[pause:0.5](Killed by Zenetta)");


        }

        super.update(elapsed);
    }

    override function opponentNoteHit(note:Note, field:PlayField):Void {
        super.opponentNoteHit(note, field);

        if (releasethebeast) {
            if (FlxG.sound.music.time > (FlxG.sound.music.length/2))
                if (resistanceAmount < 1) resistanceAmount += 0.009;
            else
                if (resistanceAmount < 1) resistanceAmount += 0.005;
        }

        try{
            @:privateAccess
            if ((note.isCheck || apNotes.contains(cast note)) && !note.ignoreNote) {
                ArchPopup.startPopupCustom('You Found A Check!', '...while not even playing that side.', 'archColor'); // test
                checkedNotes.push(note);
            }
        } catch(e) {
            trace("AP NOTE CHECK FAILED!");
        }
    }

    public var bfAscend:Bool = false;
    var alreadySent:Bool = false;
    override public function doDeathCheck(?skipHealthCheck:Bool = false):Bool
    {
        return (function(shouldKill:Bool):Bool {
            if (shouldKill && health <= 0 && bfkilledcheck && !deathByLink && !alreadySent) {
                alreadySent = true; // because indie cross likes to spam this every frame for some reason
                APEntryState.apGame.info().sendDeathLink(undertale.UnderTextParser.removeFormatting(COD.COD));
            }
            if (shouldKill && activeItems[0] <= 0) {
                ClientPrefs.data.downScroll = ogScroll;
                if (effectTimer != null && effectTimer.active)
                    effectTimer.cancel();
                if (randoTimer != null && randoTimer.active)
                    randoTimer.cancel();
                noiseSound.pause();
            }
            return shouldKill;
        })(super.doDeathCheck(skipHealthCheck));
    }

    public function forceResync()
    {
        resyncVocals();
    }

    public static function APInstance()
    {
        if (instance != null && instance is APPlayState)
            return instance;
        return null;
    }

    override public function endSong():Bool
    {
        antiHornySpray = true;
        if (effectTimer != null && effectTimer.active)
			effectTimer.cancel();

        for (func in updateFunctions)
        {
            updateFunctions.remove(func);
        }

        updateFunctions.resize(0);
        updateFunctions = [];

        if (ghostChat)
            ghostChat = false;

		ClientPrefs.data.downScroll = ogScroll;

        if (resisting)
        {
            resisting = false;
            boyfriend.playAnim('Hey!', true);
        }

        if (releasethebeast)
        {
            // Null checks before tweening
            if (boyfriend != null)
                FlxTween.tween(boyfriend, {alpha: 1}, 0.5);
            if (zenetta != null)
            {
                FlxTween.tween(zenetta, {alpha: 0.0000000001}, 0.5);
                FlxTween.tween(zenetta, {x: -2000, y: -2000}, 0.5);
            }
            FlxTween.num(resistanceAmount, 0, 0.5, {
                onUpdate: function(tween) {
                    resistanceAmount = cast(tween, NumTween).value;
                }
            });
        }

        if (FlxG.save.data.manualOverride)
        {
            trace('Switch Back');
            PlayState.storyWeek = FlxG.save.data.storyWeek;
            Mods.currentModDirectory = FlxG.save.data.currentModDirectory;
            Difficulty.list = FlxG.save.data.difficulties;
            curDifficulty = FlxG.save.data.curDifficulty; // just in case
            PlayfieldManager.SONG = FlxG.save.data.SONG;
            PlayState.storyDifficulty = FlxG.save.data.storyDifficulty;
            FlxG.save.data.manualOverride = false;
            APPlayState.instance.playfields.forEach(function(pf) {
                pf.autoPlayed = false;
            });
			StageData.loadDirectory(PlayfieldManager.SONG);
            FlxG.save.flush();
            FlxG.resetState();
            return true;
        }

        PlayState.gameplayArea = "APFreeplay";

        if (archipelago.HighQualityTrapManager.isTrapInUse()) {
            // Don't stop the trap here - let APVictorySubstate handle it
            // Remove the stopHighQualityTrap call
        }

        ghostChat = false;
        super.endSong();


        paused = true;
        APFreeplayManager.callVictory = APFreeplayManager.isVictorySong(PlayfieldManager.SONG.song, currentMod);

        // Never open victory substate when running a playlist - playlist mode handles its own state transitions
        if (!PlayState.isPlaylist) {
            // Use APVictorySubstate instead of RankingSubstate when High Quality Trap is active
            if (archipelago.HighQualityTrapManager.isTrapInUse()) {
                openSubState(new archipelago.APVictorySubstate(boyfriend));
            } else {
                openSubState(new substates.RankingSubstate());
            }
        }

        return true; //why does endsong need this?????
    }

    /**
	This needs to have two different keybinds since that's how ninjamuffin wanted it like bruh.

	yeah this is like 10X better than what it was before lmao
**/
	var TemporaryKeys:Map<String, Map<String, Array<FlxKey>>> = [
		"dfjk" => [
			'note_left' => [D, D],
			'note_down' => [F, F],
			'note_up' => [J, J],
			'note_right' => [K, K]
		],
		// ... other keybind configurations ...
	];

	var switched:Bool = false;

	/*function keybindSwitch(keybind:String = 'normal'):Void
	{
		switched = true;

		// Function to create keybinds dynamically
		function createKeybinds(bindString:String):Map<String, Array<FlxKey>>
		{
			var keybinds:Map<String, Array<FlxKey>> = new Map<String, Array<FlxKey>>();
			var keys:Array<FlxKey> = [];

			var keyNames:Array<String> = ['left', 'down', 'up', 'right'];

			for (i in 0...bindString.length)
			{
				var keyChar:String = bindString.charAt(i).toUpperCase();
				var key:FlxKey = FlxKey.fromString(keyChar);

				keys.push(key);
				keybinds.set('note_' + keyNames[i], [key, key]); // Modify as needed
			}
			trace(keybinds);
			return keybinds;
		}

		function switchKeys(newBinds:String):Void
		{
			var bindsTable:Array<String> = newBinds.split("");
			midSwitched = true;
			changeMania(PlayfieldManager.mania[0]);

			keysArray = [];
			ClientPrefs.keyBinds = createKeybinds(newBinds);
			keysArray = [
                (ClientPrefs.keyBinds.get('note_left').copy()),
                (ClientPrefs.keyBinds.get('note_down').copy()),
                (ClientPrefs.keyBinds.get('note_up').copy()),
                (ClientPrefs.keyBinds.get('note_right').copy())
			];
		}

		// Switch based on the provided keybind
		switchKeys(keybind);
	}*/

    override public function keysCheck()
    {
        // FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
        {
            if ((FlxG.keys.anyJustPressed(debugKeysDodge) && terminateTimestamps.length > 0 && !terminateCooldown) || cpuControlled)
            {
                boyfriend.playAnim('dodge', true);
                terminateCooldown = true;

                for (i in 0...terminateTimestamps.length)
                {
                    if (!terminateTimestamps[i].alive || terminateTimestamps[i] == null)
                        continue;

                    if (terminateTimestamps[i].alive && terminateTimestamps[i].canBeHit)
                    {
                        terminateTimestamps[i].wasGoodHit = true;
                        terminateTimestamps[i].kill();
                        terminateTimestamps.resize(0);
                    }
                }

                new FlxTimer().start(Conductor.stepCrochet * 2 / 1000, function(tmr)
                {
                    terminateCooldown = false;
                    FlxDestroyUtil.destroy(tmr);
                });
            }
        }
		super.keysCheck();
    }

    override function noteMiss(daNote:Note, field:PlayField)
    {
        var char:Character = boyfriend;
		/*if (opponentmode || field == dadField)
			char = dad;*/
		if (daNote.gfNote)
			char = gf;
		/*if (daNote.exNote && field == playerField)
			char = bf2;
		if (daNote.exNote && field == dadField)
			char = dad2;*/
        if (!boyfriend.invuln)
        {
            if (daNote.isAlert)
            {
                COD.setPresetCOD(daNote);
                health -= 0.5;
                FlxG.sound.play(Paths.sound('streamervschat/warning'));
                var fist:FlxSprite = new FlxSprite().loadGraphic(Paths.image("streamervschat/thepunch"));
                fist.x = FlxG.width / camGame.zoom;
                fist.y = char.y + char.height / 2 - fist.height / 2;
                add(fist);
                FlxTween.tween(fist, {x: char.x + char.frameWidth / 2}, 0.1, {
                    onComplete: function(tween)
                    {
                        if (tween.executions >= 2)
                        {
                            fist.kill();
                            FlxDestroyUtil.destroy(fist);
                            tween.cancel();
                            FlxDestroyUtil.destroy(tween);
                        }
                    },
                    type: PINGPONG
                });
                char.playAnim('hit', true);
            }
            @:privateAccess
            if (daNote.isCheck && daNote.ignoreNote)
            {
                // If the note is meant to be ignored for some reason, check it.
                // This is used for the check notes that are not meant to be hit.
                checkedNotes.push(daNote);
                ArchPopup.startPopupCustom('You Found A Check!', 'One of em anyway', 'archColor'); // test
            }

            if (daNote.specialNote)
			{
				return;
			}
            super.noteMiss(daNote, field);
        }
        else
        {
            // You didn't hit the key and let it go offscreen, also used by Hurt Notes
            // Dupe note remove
            notes.forEachAlive(function(note:Note)
            {
                if (daNote != note
                    && daNote.mustPress
                    && daNote.noteData == note.noteData
                    && daNote.isSustainNote == note.isSustainNote
                    && Math.abs(daNote.strumTime - note.strumTime) < 1)
                {
                    note.kill();
                    notes.remove(note, true);
                    note.destroy();
                }
            });
        }

        super.noteMiss(daNote, field);

        if (releasethebeast) {
            if (daNote.noteType == '')
                if (resistanceAmount < 1)
                    resistanceAmount += 0.053;
        }
    }

    public var check:Int = 0;
    override function goodNoteHit(note:Note, field:PlayField):Void
    {
        if (note.specialNote)
		{
            COD.setPresetCOD(note);
			specialNoteHit(note, field);
			return;
		}

        try {
            @:privateAccess
            if ((note.isCheck || apNotes.contains(cast note)) && !note.ignoreNote) {
                ArchPopup.startPopupCustom('You Found A Check!', 'One of em anyway', 'archColor'); // test
                checkedNotes.push(note);
            }
        } catch(e) {
            trace("\"NOTE CHECK\" CHECK FAILED!\n"+e);
        }

        super.goodNoteHit(note, field);

        if (releasethebeast && !note.gfNote) {
            if (resistanceAmount > 0) resistanceAmount -= 0.0080;
            if (note.noteType == 'Anti-Horny Note') resistanceAmount -= 0.03;
            if (note.noteType == 'Bat Note') resistanceAmount -= 0.5;

            var animToPlay:String = Note.keysShit.get(PlayfieldManager.mania[0]).get('singAnims')[note.noteData] + "-alt";
            if(note.isSustainNote)
            {
                var holdAnim:String = animToPlay + '-hold';
                if(zenetta?.animation.exists(holdAnim)) animToPlay = holdAnim;
            }

            zenetta?.playAnim(animToPlay, true);
            zenetta.holdTimer = 0;
              "e".GoToTag();
        }
    }

    function specialNoteHit(note:Note, field:PlayField):Void
	{
		if (!note.wasGoodHit)
		{
			if (note.isMine || note.isFakeHeal)
			{
				comboManager.songMisses++;
				health -= FlxG.random.float(0.2, 1) * dmgMultiplier;
				if (note.isMine)
					FlxG.sound.play(Paths.sound('streamervschat/mine'));
				else if (note.isFakeHeal)
					FlxG.sound.play(Paths.sound('streamervschat/fakeheal'));
				var nope:FlxSprite = new FlxSprite(0, 0);
				nope.loadGraphic(Paths.image("streamervschat/cross"));
				nope.setGraphicSize(Std.int(nope.width * 4));
				nope.angle = 45;
				nope.updateHitbox();
				nope.alpha = 0.8;
				nope.cameras = [camHUD];

				/*for (spr in playerField.strumNotes)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						nope.x = (spr.x + spr.width / 2) - nope.width / 2;
						nope.y = (spr.y + spr.height / 2) - nope.height / 2;
					}
				};*/

				add(nope);

				FlxTween.tween(nope, {alpha: 0}, 1, {
					onComplete: function(tween)
					{
						nope.kill();
						remove(nope);
						nope.destroy();
					}
				});
			}
			else if (note.isFreeze)
			{
				comboManager.songMisses++;
				FlxG.sound.play(Paths.sound('streamervschat/freeze'));
				frozenInput++;
				for (sprite in playerField.strumNotes)
				{
					sprite.color = 0x0073b5;
				};
                isFrozen = true;
				new FlxTimer().start(2, function(timer)
				{
					frozenInput--;
					if (frozenInput <= 0)
					{
						for (sprite in playerField.strumNotes)
						{
							sprite.color = 0xffffff;
						};
                        isFrozen = false;
                        boyfriend.stunned = false;
					}
					FlxDestroyUtil.destroy(timer);
				});
			}
			else if (note.isAlert)
			{
				FlxG.sound.play(Paths.sound('streamervschat/dodge'));
				boyfriend.playAnim('dodge', true);
			}
			else if (note.isHeal)
			{
				health += FlxG.random.float(0.3, 0.6);
				FlxG.sound.play(Paths.sound('streamervschat/heal'));
				boyfriend.playAnim('hey', true);
			}

			if (note.visible)
            {
                if (/*field.autoPlayed*/ cpuControlled)
                {
                    var time:Float = 0.15;
                    if (note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
                        time += 0.15;

                    strumPlayAnim(field, note.column % field.keyCount, time, /*note*/);
                }
                else
                {
                    /*
                    var spr = field.strumNotes[note.noteData];
                    if (spr != null && field.keysPressed[note.noteData])
                        spr.playAnim('confirm', true, note);*/
                    var spr = playerStrums.members[note.noteData];
    				if(spr != null) spr.playAnim('confirm', true);
                }
            }

			note.wasGoodHit = true;
			if (FlxG.sound.music != null)
				FlxG.sound.music.volume = 1 * instVolumeMultiplier;
			vocals.volume = 1 * vocalVolumeMultiplier;
			if (opponentVocals != null)
				opponentVocals.volume = 1 * vocalVolumeMultiplier;
			/*if (gfVocals != null)
				gfVocals.volume = 1 * vocalVolumeMultiplier;*/

			if (!note.isSustainNote)
			{
				note.kill();
			}

			popUpScore(note);
		}
	}

    override function doMegaManagerStuff() {
        MegaManager.conductor.addBeatCallback((curBeat:Int, backward:Bool) ->
		{
            switch (terminateStep)
			{
				case 3:
					var terminate = new TerminateTimestamp(Math.floor(Conductor.songPosition / Conductor.crochet) * Conductor.crochet + Conductor.crochet * 3);
					add(terminate);
					terminateTimestamps.push(terminate);
					terminateStep--;
					COD.setPresetCOD('custom');
					COD.custom = 'You were Terminated.';
				case 2 | 1 | 0:
					terminateMessage.loadGraphic(Paths.image("streamervschat/terminate" + terminateStep));
					terminateMessage.screenCenter(XY);
					terminateMessage.cameras = [camOther];
					terminateMessage.visible = true;
					if (terminateStep > 0)
					{
						terminateSound.volume = 0.6;
						terminateSound.play(true);
					}
					else if (terminateStep == 0)
					{
						FlxG.sound.play(Paths.sound('streamervschat/beep2'), 0.85);
					}
					terminateStep--;
				case -1:
					terminateMessage.visible = false;
			}
            if (releasethebeast) {
                if (resistanceAmount < 1) resistanceAmount += 0.005;

                if (curBeat % zenetta?.danceEveryNumBeats == 0 && !zenetta?.getAnimationName().endsWith('-alt')) {
                    zenetta?.dance();
                }
            }
            if (curBeat % 32 == 0 && APInfo.unstableSpeed && !songAboutToLoop)
            {
                // goes up to 5x speed cuz screw you thats why
                var randomSpeed = FlxG.random.float(0.45, 5);
                var randomShit = FlxMath.roundDecimal(randomSpeed, 2);
                lerpSongSpeed(randomShit, 1);
            }
        });

        MegaManager.conductor.addStepCallback((curStep:Int, backward:Bool) ->
		{
            if (!localFreezeNotes) // so that the event doen't get overriden
            {
                if (lagOn)
                {
                    if (curStep % 2 == 0)
                        freezeNotes = true;
                    else if (curStep % 2 == 1)
                        freezeNotes = false;
                }
                else freezeNotes = false;
            }

            if (doRandomize)
            {
                if (curStep % 16 == 0)
                {
                    for (daNote in notes) {
                        if (daNote == null) continue;
                        else {
                            daNote.noteData = daNote.trueNoteData;
                        }
                    }
                }
            }
        });
    }

    override function closeSubState()
    {
        setBoyfriendInvuln(1 / 60);
        super.closeSubState();
    }

    override public function noteMissPress(direction:Int = 1, field:PlayField)
    {
        super.noteMissPress(direction, field);
        setBoyfriendInvuln(4 / 60);
    }

    function setBoyfriendInvuln(time:Float = 5 / 60)
	{
		invulnCount++;
		var invulnCheck = invulnCount;

		boyfriend.invuln = true;

		new FlxTimer().start(time, function(tmr:FlxTimer)
		{
			if (invulnCount == invulnCheck)
			{
				boyfriend.invuln = false;
			}
		});
	}

    //Removes the Throat Notes
    public function removeThroatNotes() {
        for (note in allNotes) {
            if (note.noteType == "Throat Note")
                invalidateNote(note);
        }
    }

    //Adjust the note's alpha
    public function adjustSight() {
        if (APInfo.blindness) {
            for (field in playfields.members) {
                for (strum in field.strumNotes) {
                    strum.multAlpha = 0.3;
                }
            }
            for (note in allNotes) {
                note.multAlpha = 0.3;
            }
        } else {
            for (field in playfields.members) {
                for (strum in field.strumNotes) {
                    strum.multAlpha = 1;
                }
            }
            for (note in allNotes) {
                note.multAlpha = 1;
            }
        }
    }

    //remove the mechanics and restart the song
    public function removeLeMechanics() {
        triggerEvent("Save Song Posititon", '', '');
        FlxG.resetState();
    }
}

class TerminateTimestamp extends FlxObject
{
	public var strumTime:Float = 0;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var tooLate:Bool = false;
	public var didLatePenalty:Bool = false;

	public function new(_strumTime:Float)
	{
		super();
		strumTime = _strumTime;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		canBeHit = (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
			&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset);

		if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
			tooLate = true;
	}
}

/**
 * Mini state that displays song unlock information and returns to freeplay
 * Used when a song is locked due to AP progression requirements
 */
class APSongLockedInfoState extends backend.MusicBeatState
{
	var songName:String;
	var modName:String;
	var missingItems:Array<String>;
	var infoPanel:FlxSprite;
	var infoText:FlxText;
	var okButton:FlxSprite;
	var okText:FlxText;

	public function new(song:String, mod:String, missing:Array<String>)
	{
		super();
		this.songName = song;
		this.modName = mod;
		this.missingItems = missing != null ? missing : [];
	}

	override function create()
	{
		super.create();

		// Dark background
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x88000000);
		add(bg);

		// Info panel background
		infoPanel = new FlxSprite().makeGraphic(600, 400, 0xFF333333);
		infoPanel.screenCenter();
		add(infoPanel);

		// Panel border
		var border:FlxSprite = new FlxSprite(infoPanel.x - 2, infoPanel.y - 2).makeGraphic(Std.int(infoPanel.width + 4), Std.int(infoPanel.height + 4), 0xFFFFFFFF);
		insert(members.indexOf(infoPanel), border);

		// Title text
		var titleText:FlxText = new FlxText(infoPanel.x + 20, infoPanel.y + 20, infoPanel.width - 40, "Song Locked", 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(titleText);

		// Song info
		var songInfo:String = 'Song: ${songName}\n';
		if (modName != null && modName.length > 0) {
			songInfo += 'Mod: ${modName}\n';
		}
		songInfo += '\nThis song is locked in Archipelago mode.\n';

		if (missingItems.length > 0) {
			songInfo += '\nMissing required items:\n';
			for (item in missingItems) {
				songInfo += '• ${item}\n';
			}
		} else {
			songInfo += '\nThis song requires progression through\nthe Archipelago multiworld to unlock.\n';
		}

		infoText = new FlxText(infoPanel.x + 20, titleText.y + 40, infoPanel.width - 40, songInfo, 16);
		infoText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(infoText);

		// OK button
		okButton = new FlxSprite().makeGraphic(120, 40, 0xFF666666);
		okButton.x = infoPanel.x + (infoPanel.width - okButton.width) / 2;
		okButton.y = infoPanel.y + infoPanel.height - 60;
		add(okButton);

		var okBorder:FlxSprite = new FlxSprite(okButton.x - 1, okButton.y - 1).makeGraphic(Std.int(okButton.width + 2), Std.int(okButton.height + 2), FlxColor.WHITE);
		insert(members.indexOf(okButton), okBorder);

		okText = new FlxText(okButton.x, okButton.y, okButton.width, "OK", 16);
		okText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(okText);

		// Play sound
		FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Check for OK button click or key press
		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(okButton)) {
				returnToFreeplay();
			}
		}

		if (controls.ACCEPT || controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER) {
			returnToFreeplay();
		}

		// Button hover effect
		if (FlxG.mouse.overlaps(okButton)) {
			okButton.color = 0xFF888888;
		} else {
			okButton.color = 0xFF666666;
		}
	}

	function returnToFreeplay()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Use stickers transition to return to freeplay
		openSubState(new substates.StickerSubState(null, function(sticker) {
			return cast FreeplayManager.getNewFreeplayInstance();
		}));
	}
}


