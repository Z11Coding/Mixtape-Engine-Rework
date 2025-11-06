package substates;

import archipelago.APPlayState;
import backend.WeekData;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.Character;
import objects.FNFWeeklyVideoSprite;
import states.StoryMenuState;
import undertale.UnderTextParser;
//It has its own folder cuz it was made for something much bigger.
//im just too lazy to move it.
//-sans

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	var camFollow:FlxObject;

	var stagePostfix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var deathDelay:Float = 0;

	// Custom return state support for AP traps
	private var customReturnState:MusicBeatState = null;
	private var customBackState:MusicBeatState = null;

	public static var deathbysquare:FlxSprite;
	public static var causeofdeath:UnderTextParser;

	public static var video:Null<FNFWeeklyVideoSprite> = null;
	public static var isVideo:Bool = false;

	public static var instance:GameOverSubstate;
	public function new(?playStateBoyfriend:Character = null, ?customReturnState:MusicBeatState = null, ?customBackState:MusicBeatState = null)
	{
		// Set custom states from constructor parameters
		this.customReturnState = customReturnState;
		this.customBackState = customBackState;

		if(playStateBoyfriend != null && playStateBoyfriend.curCharacter == characterName) //Avoids spawning a second boyfriend cuz animate atlas is laggy
		{
			this.boyfriend = playStateBoyfriend;
		}
		super();
	}

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		deathDelay = 0;

		video = null;
		isVideo = false;

		var _song = PlayState.SONG;
		if(_song != null)
		{
			if(_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
			if(_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
			if(_song.gameOverLoop != null && _song.gameOverLoop.trim().length > 0) loopSoundName = _song.gameOverLoop;
			if(_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) endSoundName = _song.gameOverEnd;
		}
	}

	var charX:Float = 0;
	var charY:Float = 0;

	var overlay:FlxSprite;
	var overlayConfirmOffsets:FlxPoint = FlxPoint.get();
	override function create()
	{
		instance = this;

		var camCOD = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		camCOD.bgColor = 0xFF000000;
		camCOD.scroll.set();
		camCOD.target = null;
		camCOD.visible = true;



		FlxG.camera.bgColor = 0xFF000000; // to fix mods that like to change its color (looking at you, 17bucks)



		Conductor.songPosition = 0;

		if(boyfriend == null)
		{
			// Try to create boyfriend, using PlayState position if available
			if (PlayState.instance != null && PlayState.instance.boyfriend != null) {
				boyfriend = new Character(PlayState.instance.boyfriend.getScreenPosition().x, PlayState.instance.boyfriend.getScreenPosition().y, characterName, true);
				boyfriend.x += boyfriend.positionArray[0] - PlayState.instance.boyfriend.positionArray[0];
				boyfriend.y += boyfriend.positionArray[1] - PlayState.instance.boyfriend.positionArray[1];
			} else {
				// Create boyfriend at default position if no PlayState
				boyfriend = new Character(FlxG.width * 0.5, FlxG.height * 0.7, characterName, true);
			}
		}
		boyfriend.skipDance = true;
		add(boyfriend);

		FlxG.sound.play(Paths.sound(deathSoundName));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(boyfriend.getGraphicMidpoint().x + boyfriend.cameraPosition[0], boyfriend.getGraphicMidpoint().y + boyfriend.cameraPosition[1]);
		FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		add(camFollow);

		if (PlayState.instance != null) {
			PlayState.instance.setOnScripts('inGameOver', true);
			PlayState.instance.callOnScripts('onGameOverStart', []);
		}
		FlxG.sound.music.loadEmbedded(Paths.music(loopSoundName), true);

		if(characterName == 'pico-dead')
		{
			overlay = new FlxSprite(boyfriend.x + 205, boyfriend.y - 80);
			overlay.frames = Paths.getSparrowAtlas('Pico_Death_Retry');
			overlay.animation.addByPrefix('deathLoop', 'Retry Text Loop', 24, true);
			overlay.animation.addByPrefix('deathConfirm', 'Retry Text Confirm', 24, false);
			overlay.antialiasing = ClientPrefs.data.antialiasing;
			overlayConfirmOffsets.set(250, 200);
			overlay.visible = false;
			add(overlay);

			boyfriend.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				switch(name)
				{
					case 'firstDeath':
						if(frameNumber >= 36 - 1)
						{
							overlay.visible = true;
							overlay.animation.play('deathLoop');
							boyfriend.animation.callback = null;
						}
					default:
						boyfriend.animation.callback = null;
				}
			}

			if(PlayState.instance.gf != null && PlayState.instance.gf.curCharacter == 'nene')
			{
				var neneKnife:FlxSprite = new FlxSprite(boyfriend.x - 450, boyfriend.y - 250);
				neneKnife.frames = Paths.getSparrowAtlas('NeneKnifeToss');
				neneKnife.animation.addByPrefix('anim', 'knife toss', 24, false);
				neneKnife.antialiasing = ClientPrefs.data.antialiasing;
				neneKnife.animation.finishCallback = function(_)
				{
					remove(neneKnife);
					//neneKnife.destroy();
				}
				insert(0, neneKnife);
				neneKnife.animation.play('anim', true);
			}
		}

		deathbysquare = new FlxSprite().makeGraphic(500, 300, 0xFFFFFFFF);
		deathbysquare.scrollFactor.set();
		// Start off-screen to the right
		deathbysquare.x = FlxG.width + 100;
		deathbysquare.y = -100;
		deathbysquare.alpha = 0.3;
		deathbysquare.visible = false; // Start invisible
		deathbysquare.cameras = [(PlayState.instance != null ? PlayState.instance.camCOD : FlxG.cameras.list[FlxG.cameras.list.length-1])];
		add(deathbysquare);

		var alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
		causeofdeath = new UnderTextParser(0, 0, Std.int(deathbysquare.width), "", 32);
		causeofdeath.scrollFactor.set();
		causeofdeath.font = Paths.font("fnf1.ttf");
    causeofdeath.color = 0xFFFFFFFF;
		causeofdeath.visible = false; // Start invisible
		for (letter in alphabet) {
			causeofdeath.soundOnChars.set(letter, FlxG.sound.load(Paths.sound('ut/uifont'), 1));
			causeofdeath.soundOnChars.set(letter.toUpperCase(), FlxG.sound.load(Paths.sound('ut/uifont'), 1));
		}
		causeofdeath.cameras = [(PlayState.instance != null ? PlayState.instance.camCOD : FlxG.cameras.list[FlxG.cameras.list.length-1])];
		add(causeofdeath);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance?.callOnScripts('onUpdate', [elapsed]);

		var justPlayedLoop:Bool = false;
		if (!boyfriend.isAnimationNull() && boyfriend.getAnimationName() == 'firstDeath' && boyfriend.isAnimationFinished())
		{
			boyfriend.playAnim('deathLoop');
			if(overlay != null && overlay.animation.exists('deathLoop'))
			{
				overlay.visible = true;
				overlay.animation.play('deathLoop');
			}
			justPlayedLoop = true;
		}

		if(!isEnding)
		{
			if (controls.ACCEPT)
			{
				endBullshit();
			}
			else if (controls.BACK && !(this is archipelago.APVictorySubstate))
			{
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				FlxG.camera.visible = false;
				FlxG.sound.music.stop();
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.chartingMode = false;

				Mods.loadTopMod();

				// Use custom back state if provided
				if (customBackState != null) {
					MusicBeatState.switchState(customBackState);
				} else if (PlayState.isStoryMode) {
					MusicBeatState.switchState(new StoryMenuState());
				} else {
					FreeplayManager.openFreeplay();
				}

				MusicManager.playMenuMusic();
				PlayState.instance?.callOnScripts('onGameOverConfirm', [false]);
			}
			else if (justPlayedLoop)
			{
				if (PlayState.SONG != null) {
					switch(PlayState.SONG.stage)
					{
						case 'tank':
							coolStartDeath(0.2);

							var exclude:Array<Int> = [];
							//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

							FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
								if(!isEnding)
								{
									FlxG.sound.music.fadeIn(0.2, 1, 4);
								}
							});

						default:
							coolStartDeath();
					}
				} else {
					coolStartDeath();
				}
			}

			if (FlxG.sound.music.playing)
			{
				Conductor.songPosition = FlxG.sound.music.time;
			}
		}
		PlayState.instance?.callOnScripts('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;
	function coolStartDeath(?volume:Float = 1):Void
	{
		if (!isVideo) {
			FlxG.sound.music.play(true);
			FlxG.sound.music.volume = volume;

			// Make elements visible and tween them into position
			deathbysquare.visible = true;
			causeofdeath.visible = true;

			// Calculate final positions
			var finalSquareX = FlxG.width - deathbysquare.width - 100;
			var finalSquareY = -100;
			var finalTextX = finalSquareX;
			var finalTextY = finalSquareY + 125;

			// Tween the square into position
			FlxTween.tween(deathbysquare, {x: finalSquareX, y: finalSquareY}, 1, {
				ease: FlxEase.cubeInOut,
				onComplete: function(tween:FlxTween) {
					// Only start the text after the tween finishes
					causeofdeath.resetText(COD.getCOD());
					causeofdeath.start(0.05, true);
				}
			});

			// Tween the text to follow the square
			FlxTween.tween(causeofdeath, {x: finalTextX, y: finalTextY}, 1, {ease: FlxEase.cubeInOut});
		} else {
			causeofdeath.visible = false;
			deathbysquare.visible = false;
		}
	}

	function endBullshit():Void
	{
		if (!isVideo) {
			if (!isEnding)
			{
				isEnding = true;
				if(boyfriend.hasAnimation('deathConfirm'))
					boyfriend.playAnim('deathConfirm', true);
				else if(boyfriend.hasAnimation('deathLoop'))
					boyfriend.playAnim('deathLoop', true);

				if(overlay != null && overlay.animation.exists('deathConfirm'))
				{
					overlay.visible = true;
					overlay.animation.play('deathConfirm');
					overlay.offset.set(overlayConfirmOffsets.x, overlayConfirmOffsets.y);
				}
				FlxG.sound.music.stop();
				FlxG.sound.play(Paths.music(endSoundName));
				new FlxTimer().start(0.7, function(tmr:FlxTimer)
				{
					FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
					{
						if (Std.is(PlayState.instance, APPlayState) && APPlayState.deathByBlueBalls)
						{
							APPlayState.deathByBlueBalls = false;
							FlxG.camera.visible = false;
							FlxG.sound.music.stop();
							PlayState.deathCounter = 0;
							PlayState.seenCutscene = false;
							PlayState.chartingMode = false;

							Mods.loadTopMod();
							FreeplayManager.openFreeplay();
							MusicManager.playMenuMusic();
						}
						else
						{
							// Use custom return state if provided
							if (customReturnState != null) {
								MusicBeatState.switchState(customReturnState);
							} else {
								MusicBeatState.resetState();
							}
						}
					});
				});
				PlayState.instance?.callOnScripts('onGameOverConfirm', [true]);
			}
		}
	}

	public function setGameOverVideo(name:String) // called in hscript
	{
		isVideo = true;

		endSoundName = "empty";
		deathSoundName = "empty";
		loopSoundName = "empty";

		boyfriend.visible = false;

		video = new FNFWeeklyVideoSprite();

		video.addCallback('onFormat',()->{
			video.setGraphicSize(0, FlxG.height);
			video.updateHitbox();
			video.screenCenter();
			video.antialiasing = true;
			video.cameras = [(PlayState.instance != null ? PlayState.instance.camOther : FlxG.cameras.list[FlxG.cameras.list.length-1])];
		});
		video.addCallback('onEnd',()->{
			FlxG.resetState();
		});

		video.load(Paths.video(name));
		video.play();
		add(video);
	}

	override function destroy()
	{
		instance = null;

		if (APPlayState.deathByLink)
		{
			APPlayState.deathByLink = false;
			APPlayState.deathLinkPacket = null;
			APPlayState.alreadyKilledByLink = false;
		}
		super.destroy();
	}
}
