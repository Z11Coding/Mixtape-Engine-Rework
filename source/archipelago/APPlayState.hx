package archipelago;
import backend.Song;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import shaders.MosaicEffect;
import openfl.filters.BitmapFilter;
import flixel.tweens.misc.NumTween;
import flixel.input.keyboard.FlxKey;
import streamervschat.*;
import flixel.util.FlxDestroyUtil;
import objects.Character;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
class APPlayState extends PlayState {
    public static var apGame:APGameState;
    public static var deathByLink:Bool = false;
    public static var currentMod = "";
    public static var deathLinkPacket:Dynamic;
    public static var effectiveScrollSpeed:Float;
	public static var effectiveDownScroll:Bool;
    public static var xWiggle:Array<Float> = [0, 0, 0, 0];
	public static var yWiggle:Array<Float> = [0, 0, 0, 0];
    public static var notePositions:Array<Int> = [0, 1, 2, 3];
    public static var validWords:Array<String> = [];
    public static var controlButtons:Array<String> = [];
    public static var ogScroll:Bool = ClientPrefs.data.downScroll;
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
	// private var unBlurShaderRestore:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();
    var curDifficulty:Int = -1;
    var effectsActive:Map<String, Int> = new Map<String, Int>();
    var effectTimer:FlxTimer = new FlxTimer();
	var randoTimer:FlxTimer = new FlxTimer();
    var drainHealth:Bool = false;
	var drunkTween:NumTween = null;
	var lagOn:Bool = false;
	var addedMP4s:Array<VideoHandlerMP4> = [];
	var flashbangTimer:FlxTimer = new FlxTimer();
	var errorMessages:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
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
	var effectArray:Array<String> = [
		'colorblind', 'blur', 'lag', 'mine', 'warning', 'heal', 'spin', 'songslower', 'songfaster', 'scrollswitch', 'scrollfaster', 'scrollslower', 'rainbow',
		'cover', 'ghost', 'flashbang', 'nostrum', 'jackspam', 'spam', 'sever', 'shake', 'poison', 'dizzy', 'noise', 'flip', 'invuln',
		'desync', 'mute', 'ice', 'randomize', 'randomizeAlt', 'opponentPlay', 'bothplay', 'fakeheal', 'spell', 'terminate', 'lowpass', 'notif'
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
	var curEffect:Int = 0;

	public var effectMap:Map<String, Void->Void>;
	var effectendsin:FlxText;

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
        if (APEntryState.inArchipelagoMode)
        {
            if (FlxG.save.data.activeItems != null)
                activeItems = FlxG.save.data.activeItems;
            if (FlxG.save.data.activeItems == null)
            {
                activeItems[3] = -1; //FlxG.random.int(0, 9); im getting kinda tired of this
                activeItems[2] = 0;
				FlxG.save.flush();
            }
        }

        currentMod = WeekData.getCurrentWeek().folder;

        if (!APEntryState.inArchipelagoMode)
        {
            FlxG.switchState(new PlayState());
            return;
        }



		
effectMap = [
    'colorblind' => function() {
        var ttl:Float = 16;
        var onEnd:(Void->Void) = function() {
            camHUDfilters.remove(filterMap.get("Grayscale").filter);
            camGamefilters.remove(filterMap.get("Grayscale").filter);
        };
        var playSound:String = "colorblind";
        var playSoundVol:Float = 0.8;
        var noIcon:Bool = false;

        camHUDfilters.push(filterMap.get("Grayscale").filter);
        camGamefilters.push(filterMap.get("Grayscale").filter);

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'colorblind');
    },
    'blur' => function() {
        var originalShaders:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();
        var ttl:Float = 12;
        var onEnd:(Void->Void) = function() {
            for (sprite in playerField.strumNotes) {
                sprite.shader = originalShaders.get(sprite);
            };
            for (sprite in dadField.strumNotes) {
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
            camGamefilters.remove(filterMap.get("BlurLittle").filter);
        };
        var playSound:String = "blur";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = false;

        if (effectsActive["blur"] == null || effectsActive["blur"] <= 0) {
            camGamefilters.push(filterMap.get("BlurLittle").filter);
            if (PlayState.curStage.startsWith('school'))
                blurEffect.setStrength(2, 2);
            else
                blurEffect.setStrength(32, 32);
            for (sprite in playerField.strumNotes) {
                originalShaders.set(sprite, sprite.shader);
                sprite.shader = blurEffect.shader;
            };
            for (sprite in dadField.strumNotes) {
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
            modManager.setValue('roll', 0);
        };
        var playSound:String = "spin";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        modManager.setValue('roll', (FlxG.random.bool() ? 1 : -1) * FlxG.random.float(333 * 0.8, 333 * 1.15));
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
            songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
        };
        var playSound:String = "scrollfaster";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        effectiveScrollSpeed += changeAmount;
        songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd, 'scrollfaster');
    },
    'notif' => function() {
        backend.window.CppAPI.sendWindowsNotification("Archipelago", notifs[FlxG.random.int(0, notifs.length-1)]);
    },
    'scrollslower' => function() {
        var changeAmount:Float = FlxG.random.float(0.1, 0.9);
        var ttl:Float = 20;
        var onEnd:(Void->Void) = function() {
            effectiveScrollSpeed += changeAmount;
            songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
        };
        var playSound:String = "scrollslower";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        effectiveScrollSpeed -= changeAmount;
        songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;

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
        var errorMessage = new FlxSprite();
        var onEnd:(Void->Void) = function() {
            errorMessage.kill();
            errorMessages.remove(errorMessage);
            FlxDestroyUtil.destroy(errorMessage);
        };
        var playSound:String = "";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        var random = FlxG.random.int(0, 14);
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
            case 6:
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/mark'), null, false, false).setDimensions(378, 362);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
            case 7:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/fireworks'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'firework';
            case 8:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/spiral'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'spiral';
            case 9:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/thingy'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'thingy';
            case 10:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/light'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'light';
            case 11:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/snow'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'snow';
                playSoundVol = 0.6;
            case 12:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/spiral2'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'spiral';
            case 13:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/wheel'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'wheel';
            case 14:
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
                    errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                    errorMessage.screenCenter(Y);
                    errorMessages.add(errorMessage);
                case 1:
                    errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                    errorMessage.y = (effectiveDownScroll ? FlxG.height - errorMessage.height : 0);
                    errorMessages.add(errorMessage);
                case 2:
                    errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                    errorMessage.y = (effectiveDownScroll ? 0 : FlxG.height - errorMessage.height);
                    errorMessages.add(errorMessage);
                case 3:
                    errorMessage.screenCenter(XY);
                    errorMessages.add(errorMessage);
                case 4:
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
            camOther.flash(FlxColor.WHITE, 7, null, true);
            remove(whiteScreen);
            FlxG.sound.play(Paths.sound('streamervschat/ringing'), 0.4);
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
        var dataPicked = FlxG.random.int(0, PlayState.mania);
        for (i in startingPoint...endingPoint) {
            addNoteSvCLegacy(0, i, i, dataPicked);
        }
    },
    'spam' => function() {
        var noIcon:Bool = true;
        var startingPoint = FlxG.random.int(5, 9);
        var endingPoint = FlxG.random.int(startingPoint + 5, startingPoint + 10);
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
            explosion.kill();
            remove(explosion);
            FlxDestroyUtil.destroy(explosion);
        };
        explosion.cameras = [camHUD];
        explosion.x = playerField.strumNotes[picked].x + playerField.strumNotes[picked].width / 2 - explosion.width / 2;
        explosion.y = playerField.strumNotes[picked].y + playerField.strumNotes[picked].height / 2 - explosion.height / 2;
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
        var ttl:Float = 5;
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
            modManager.queueEase(curStep, curStep+3, availableS, 0, "sineInOut");
        };
        var playSound:String = "randomize";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = false;


        modManager.queueEase(curStep, curStep+3, availableS, .96, "sineInOut");
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
        for (i in 0...PlayState.mania+1) {
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

        opponentmode =  true;
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
            camHUDfilters.remove(filterMap.get("BlurLittle").filter);
            camGamefilters.remove(filterMap.get("BlurLittle").filter);
            lowFilterAmount = 1;
            vocalLowFilterAmount = 1;
        };
        var playSound:String = "delay";
        var playSoundVol:Float = 0.6;
        var noIcon:Bool = true;

        if (FlxG.random.bool(40)) {
            lowFilterAmount = .0134;
            camGamefilters.push(filterMap.get("BlurLittle").filter);
            blurEffect.setStrength(32, 32);
        } else {
            vocalLowFilterAmount = .0134;
            camHUDfilters.push(filterMap.get("BlurLittle").filter);
            camGamefilters.push(filterMap.get("BlurLittle").filter);
            blurEffect.setStrength(32, 32);
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, 'lowpass');
    },
    'songSwitch' => function() {
        // var haltTween:NumTween = new NumTween(null, null);
            FlxTween.num(playbackRate, 0, 0.5, {
            onComplete: function(e) {
                FlxG.sound.play(Paths.sound('streamervschat/itcomes'), 1, false, null, true, function() {
                    trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);
                    if (!FlxG.save.data.manualOverride) {
                        FlxG.save.data.manualOverride = true;
                        FlxG.save.data.storyWeek = PlayState.storyWeek;
                        FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
                        FlxG.save.data.difficulties = Difficulty.list; // just in case
                        FlxG.save.data.SONG = PlayState.SONG;
                        FlxG.save.data.storyDifficulty = PlayState.storyDifficulty;
                        FlxG.save.data.songPos = Conductor.songPosition;
                        FlxG.save.flush();
                    
                        PlayState.SONG = Song.loadFromJson(Highscore.formatSong('tutorial', curDifficulty), Paths.formatToSongPath('tutorial'));
                        PlayState.storyWeek = 0;
                        Mods.currentModDirectory = 'week1';
                        Difficulty.list = Difficulty.defaultList.copy();
                        PlayState.storyDifficulty = curDifficulty;
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

        addEffect("freeze");

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
        wordList.push(PlayState.SONG.song);
		trace(wordList.length + " words loaded");
		trace(wordList);
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
		for (thing in [
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
		}

        if (FlxG.save.data.activeItems == null)
		{
			switch (activeItems[3])
			{
				case 1:
					chartModifier = 'Flip';
				case 2:
					chartModifier = 'Random';
				case 3:
					chartModifier = 'Stairs';
				case 4:
					chartModifier = 'Wave';
				case 5:
					chartModifier = 'SpeedRando';
				case 6:
					chartModifier = 'Amalgam';
				case 7:
					chartModifier = 'Trills';
				case 8:
					chartModifier = "SpeedUp";
				case 9:
					if (PlayState.SONG.mania == 3)
					{
						chartModifier = "ManiaConverter";
						convertMania = FlxG.random.int(4, Note.maxMania);
					}
					else
					{
						chartModifier = "4K Only";
					}
				default:
					chartModifier = allowSetChartModifier && ClientPrefs.getGameplaySetting('chartModifier', 'Normal') != null ? ClientPrefs.getGameplaySetting('chartModifier', 'Normal') : "Normal";
			}
			if (chartModifier == "ManiaConverter")
			{
				ArchPopup.startPopupCustom("convertMania value is:", "" + convertMania + "", 'archColor');
            }
            if (chartModifier != 'Normal') ArchPopup.startPopupCustom('You Got an Item!', "Chart Modifier Trap (" + chartModifier + ")", 'archColor');
			//MaxHP = activeItems[2];
		}

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

        super.create();

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

        for (i in 0...PlayState.mania + 1) {
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

        if (cpuControlled)
            {
                set_cpuControlled(false);
            }
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

    override public function startCountdown():Bool
    {
        if (PlayState.SONG.player1.toLowerCase().contains('zenetta') || PlayState.SONG.player2.toLowerCase().contains('zenetta') || PlayState.SONG.gfVersion.toLowerCase().contains('zenetta'))
        {
            itemAmount = 69;
            trace("RESISTANCE OVERRIDE!"); // what are the chances
        }
        // Check if there are any mustPress notes available
        if (allNotes.filter(function(note:Note):Bool
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
        Sys.println('');
        super.startCountdown();
        return true;
    }

    override function startSong()
    {
        /*effectTimer.start(5, function(timer)
        {
            if (paused)
                return;
            if (startingSong)
                return;
            if (endingSong)
                return;
        }, 0);

        randoTimer.start(FlxG.random.float(5, 10), function(tmr:FlxTimer)
        {
            if (curEffect <= 38) doEffect(effectArray[curEffect]);
            else if (curEffect > 38)
            {
                switch (curEffect)
                {
                    case 38:
                        activeItems[0] += 1;
                        ArchPopup.startPopupCustom('You Got an Item!', '+1 Shield ( ' + activeItems[0] + ' Left)', 'archColor');
                    case 39:
                        activeItems[1] = 1;
                        ArchPopup.startPopupCustom('You Got an Item!', "Blue Ball's Curse", 'archWhite');
                    case 40:
                        activeItems[2] += 1;
						MaxHP = 2+activeItems[2];
                        ArchPopup.startPopupCustom('You Got an Item!', "Max HP Up!", 'archColor');
                }
            }
            tmr.reset(FlxG.random.float(5, 10));
        });*/
        super.startSong();
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

		super.destroy();
	}

    var oldRate:Int = 60;
	var noIcon:Bool = false;
	var available:Array<Int> = [];

	
public function doEffect(effect:String)
	{
		if (paused || endingSong) return;
		
		if (effectMap.exists(effect)) {
			effectMap.get(effect)();
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

	override function stepHit()
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
		super.stepHit();
	}

	// override public function generateNotes(song:SwagSong, AI:Array<Array<Float>>):Void
	// 	super.generateNotes(song, AI);

    function updateScrollUI()
	{
		timeTxt.y = (effectiveDownScroll ? FlxG.height - 44 : 19);
		timeBar.y = (timeTxt.y + (timeTxt.height / 4)) + 4;
        modManager.queueEase(curStep, curStep+3, 'reverse', effectiveDownScroll ? 1 : 0, "sineInOut");
		healthBar.y = (effectiveDownScroll ? FlxG.height * 0.1 : FlxG.height * 0.875) + 4;
		healthBar2.y = (effectiveDownScroll ? FlxG.height * 0.1 : FlxG.height * 0.875) + 4;
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

		if (PlayState.SONG.notes.length <= Math.floor((curStep + pickSteps + 1) / 16))
			return;

		if (PlayState.SONG.notes[Math.floor((curStep + pickSteps + 1) / 16)] == null)
			return;

		if (specificData == null)
		{
			if (PlayState.SONG.notes[Math.floor((curStep + pickSteps + 1) / 16)].mustHitSection)
			{
				pickData = FlxG.random.int(0, PlayState.mania);
			}
			else
			{
				// pickData = FlxG.random.int(4, 7);
				pickData = FlxG.random.int(0, PlayState.mania);
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
				pickData = FlxG.random.int(0, PlayState.mania);
			else
				pickData = chooseFrom[FlxG.random.int(0, chooseFrom.length - 1)];
		}
		else
		{
			if (PlayState.SONG.notes[Math.floor((curStep + pickSteps + 1) / 16)].mustHitSection)
			{
				pickData = specificData % Note.ammo[PlayState.mania];
			}
			else
			{
				// pickData = specificData % 4 + 4;
				pickData = specificData % Note.ammo[PlayState.mania];
			}
		}
		var swagNote:Note = new Note(pickTime, pickData);
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
		if (chartModifier == "SpeedRando")
			{swagNote.multSpeed = FlxG.random.float(0.1, 2);}
		if (chartModifier == "SpeedUp")
			{}
		swagNote.x += FlxG.width / 2;

        if (swagNote.fieldIndex == -1 && swagNote.field == null)
            swagNote.field = swagNote.mustPress ? playerField : dadField;
        if (swagNote.field != null)
            swagNote.fieldIndex = playfields.members.indexOf(swagNote.field);
        var playfield:PlayField = playfields.members[swagNote.fieldIndex];
        if (playfield != null)
        {
            playfield.queue(swagNote); // queues the note to be spawned
            unspawnNotes.push(swagNote);
            allNotes.push(swagNote); // just for the sake of convenience
        }
        else
        {
            swagNote.destroy();
        }
		unspawnNotes.sort(sortByNotes);
        allNotes.sort(sortByNotes);
        /*for (field in playfields.members)
        {
            var goobaeg:Array<Note> = [];
            for (column in field.noteQueue)
            {
                if (column.length >= Note.ammo[PlayState.mania])
                {
                    for (nIdx in 1...column.length)
                    {
                        var last = column[nIdx - 1];
                        var current = column[nIdx];

                        if (Math.abs(last.strumTime - current.strumTime) <= Conductor.stepCrochet / (192 / 16))
                        {
                            if (last.sustainLength < current.sustainLength) // keep the longer hold
                                field.removeNote(last);
                            else
                            {
                                current.kill();
                                goobaeg.push(current); // mark to delete after, cant delete here because otherwise it'd fuck w/ stuff
                            }
                        }
                    }
                }
            }
            for (note in goobaeg)
                field.removeNote(note);
        }*/
	}

	var isFrozen:Bool = false;
	var doRandomize:Bool = false;
    override public function update(elapsed:Float)
    {
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
            try {
                if (deathLinkPacket.cause != null && (deathLinkPacket.cause != "" || deathLinkPacket.cause != " ")) cause = deathLinkPacket.cause + "\n[pause:0.5](Sounds like a skill issue...)";
            }
            catch(e) {trace('DEATHLINKPACK WAS NULL!');}
            if (cause.trim() == "") cause = deathLinkPacket.source + " has died.\n[pause:0.5](How Unfortunate...)";
            COD.setCOD(null, cause);
            die();  
            trace("Triggering DeathLink!");
        }
        #if cpp			
		if(FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			@:privateAccess
			{
				var af = lime.media.openal.AL.createFilter(); // create AudioFilter
				lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, lowFilterAmount ); // set gainhf
				lime.media.openal.AL.sourcei( FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
				//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
			}
		}
		if(vocals != null && vocals.playing)
		{
			@:privateAccess
			{
				var af = lime.media.openal.AL.createFilter(); // create AudioFilter
				lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, vocalLowFilterAmount ); // set gainhf
				lime.media.openal.AL.sourcei( vocals._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
				//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
			}
		}
		if(opponentVocals != null && opponentVocals.playing)
		{
			@:privateAccess
			{
				var af = lime.media.openal.AL.createFilter(); // create AudioFilter
				lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, vocalLowFilterAmount ); // set gainhf
				lime.media.openal.AL.sourcei( opponentVocals._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
				//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
			}
		}
		if(gfVocals != null && gfVocals.playing)
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
		}
		#end
        curEffect = FlxG.random.int(0, 40);
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
        for(queue in playerField.noteQueue){
            for(note in queue)
            {
                if (note.noteData == picked)
                    note.blockHit = true;
            }
		}

        if (!endingSong)
            FlxG.save.data.activeItems = activeItems;

        for (i in activeItems)
            if (i == 0)
                FlxG.save.data.activeItems = null;

        /*if (FlxG.keys.justPressed.F)
        {
            switch (FlxG.random.int(0, 2))
            {
                case 0:
                    activeItems[0] += 1;
                    ArchPopup.startPopupCustom('You Got an Item!', '+1 Shield ( ' + activeItems[0] + ' Left)', 'archColor');
                case 1:
                    activeItems[1] = 1;
                    ArchPopup.startPopupCustom('You Got an Item!', "Blue Ball's Curse", 'archColor');
                case 2:
                    activeItems[2] += 1;
                    ArchPopup.startPopupCustom('You Got an Item!', "Max HP Up!", 'archColor');
                case 3:
                    keybindSwitch('SAND');
                    ArchPopup.startPopupCustom('You Got an Item!', "Keybind Switch (S A N D)", 'archColor');
            }
        }*/
		for (video in addedMP4s)
		{
			if (video != null)
            {
				video.cameras = [camHUD];
                if (video.completed)
                    addedMP4s.remove(video);
            }
		}

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
        super.update(elapsed);
    }

    override function doDeathCheck(?skipHealthCheck:Bool = false):Bool
    {
        if (activeItems[0] <= 0)
        {
            if ((((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead))
            {
                ClientPrefs.data.downScroll = ogScroll;
                if (effectTimer != null && effectTimer.active)
                    effectTimer.cancel();
                if (randoTimer != null && randoTimer.active)
                    randoTimer.cancel();
                noiseSound.pause();
            }
        }
        if (health <= 0 && bfkilledcheck && !deathByLink) APEntryState.apGame.info().sendDeathLink(COD.COD.COD); // Don't ask why it works like this...
        super.doDeathCheck();
        return true;
    }

    override public function endSong():Bool
    {
        if (effectTimer != null && effectTimer.active)
			effectTimer.cancel();

		ClientPrefs.data.downScroll = ogScroll;

        if (FlxG.save.data.manualOverride)
        {
            trace('Switch Back');
            PlayState.storyWeek = FlxG.save.data.storyWeek;
            Mods.currentModDirectory = FlxG.save.data.currentModDirectory;
            Difficulty.list = FlxG.save.data.difficulties;
            PlayState.SONG = FlxG.save.data.SONG;
            PlayState.storyDifficulty = FlxG.save.data.storyDifficulty;
            FlxG.save.data.manualOverride = false;
			StageData.loadDirectory(PlayState.SONG);
            FlxG.save.flush();
            FlxG.resetState();
            return true;
        }

        if (check == did)
		{
			// For Later
		}
        super.endSong();
		PlayState.gameplayArea = "APFreeplay";
        paused = true;
        states.FreeplayState.callVictory = PlayState.SONG.song == APEntryState.victorySong;
		openSubState(new substates.RankingSubstate());
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

	function keybindSwitch(keybind:String = 'normal'):Void
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
			changeMania(PlayState.mania);

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
	}

    override public function keyShit()
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
		super.keyShit();
    }

    override function noteMiss(daNote:Note, field:PlayField)
    {
        var char:Character = boyfriend;
		if (opponentmode || field == dadField)
			char = dad;
		if (daNote.gfNote)
			char = gf;
		if (daNote.exNote && field == playerField)
			char = bf2;
		if (daNote.exNote && field == dadField)
			char = dad2;
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

            if (daNote.specialNote)
			{
				specialNoteHit(daNote, field);
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
        if (note.isCheck)
        {
            check++;
            if (ClientPrefs.data.notePopup)
                ArchPopup.startPopupCustom('You Found A Check!', '$check/$itemAmount', 'archColor'); // test
            trace('Got: ' + check + '/' + itemAmount);
            updateScore();
        }
        super.goodNoteHit(note, field);
    }

    function specialNoteHit(note:Note, field:PlayField):Void
	{
		if (!note.wasGoodHit)
		{
			if (note.isMine || note.isFakeHeal)
			{
				songMisses++;
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

				for (spr in playerField.strumNotes)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						nope.x = (spr.x + spr.width / 2) - nope.width / 2;
						nope.y = (spr.y + spr.height / 2) - nope.height / 2;
					}
				};

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
				songMisses++;
				FlxG.sound.play(Paths.sound('streamervschat/freeze'));
				frozenInput++;
				for (sprite in playerField.strumNotes)
				{
					sprite.color = 0x0073b5;
					isFrozen = true;
				};
				new FlxTimer().start(2, function(timer)
				{
					frozenInput--;
					if (frozenInput <= 0)
					{
						for (sprite in playerField.strumNotes)
						{
							sprite.color = 0xffffff;
							isFrozen = false;
							boyfriend.stunned = false;
						};
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
                if (field.autoPlayed)
                {
                    var time:Float = 0.15;
                    if (note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
                        time += 0.15;
    
                    StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % Note.ammo[PlayState.mania], time, note);
                }
                else
                {
                    var spr = field.strumNotes[note.noteData];
                    if (spr != null && field.keysPressed[note.noteData])
                        spr.playAnim('confirm', true, note);
                }
            }

			note.wasGoodHit = true;
			if (FlxG.sound.music != null)
				FlxG.sound.music.volume = 1 * instVolumeMultiplier;
			vocals.volume = 1 * vocalVolumeMultiplier;
			if (opponentVocals != null)
				opponentVocals.volume = 1 * vocalVolumeMultiplier;
			if (gfVocals != null)
				gfVocals.volume = 1 * vocalVolumeMultiplier;

			if (!note.isSustainNote)
			{
				note.kill();
			}

			popUpScore(note);
		}
	}

    override function beatHit()
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
        super.beatHit();
    }

    override function closeSubState()
    {
        setBoyfriendInvuln(1 / 60);
        super.closeSubState();
    }

    override public function noteMissPress(direction:Int = 1)
    {
        super.noteMissPress(direction);
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