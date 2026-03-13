package substates;

import archipelago.APPlayState;
import backend.WeekData;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import objects.Character;
import objects.GameOverVideoSprite;
import states.FreeplayState;
import states.StoryMenuState;
import undertale.UnderTextParser;
//It has its own folder cuz it was made for something much bigger.
//im just too lazy to move it.
//-sans

class APGameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	var camFollow:FlxObject;

	var stagePostfix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var deathDelay:Float = 0;

	public static var deathbysquare:FlxSprite;
	public static var causeofdeath:UnderTextParser;

	public static var video:Null<GameOverVideoSprite> = null;
	public static var isVideo:Bool = false;

	public static var instance:APGameOverSubstate;
	public function new() {
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

		FlxG.camera.bgColor = 0xFF000000; // to fix mods that like to change its color (looking at you, 17bucks)

		if (Std.is(PlayState.instance, APPlayState) && APPlayState.deathByLink)
		{
			APPlayState.deathByLink = false;
			APPlayState.deathLinkPacket = null;
		}

		Conductor.songPosition = 0;

		if(boyfriend == null)
		{
			boyfriend = new Character(0, 0, 'bf-dead', true);
			boyfriend.x += boyfriend.positionArray[0];
			boyfriend.y += boyfriend.positionArray[1];
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

		PlayState.instance?.setOnScripts('inGameOver', true);
		PlayState.instance?.callOnScripts('onGameOverStart', []);
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

			if(PlayState.instance?.gf != null && PlayState.instance?.gf.curCharacter == 'nene')
			{
				var neneKnife:FlxSprite = new FlxSprite(boyfriend.x - 450, boyfriend.y - 250);
				neneKnife.frames = Paths.getSparrowAtlas('NeneKnifeToss');
				neneKnife.animation.addByPrefix('anim', 'knife toss', 24, false);
				neneKnife.antialiasing = ClientPrefs.data.antialiasing;
				neneKnife.animation.finishCallback = function(_)
				{
					remove(neneKnife);
					neneKnife.destroy();
				}
				insert(0, neneKnife);
				neneKnife.animation.play('anim', true);
			}
		}

		deathbysquare = new FlxSprite().makeGraphic(500, 300, 0xFFFFFFFF);
		deathbysquare.scrollFactor.set();
		deathbysquare.x += 800;
		deathbysquare.y -= 100;
		deathbysquare.alpha = 0.3;
		add(deathbysquare);

		var alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
		causeofdeath = new UnderTextParser(deathbysquare.x, deathbysquare.y + 125, Std.int(deathbysquare.width), "", 32);
		causeofdeath.scrollFactor.set();
		causeofdeath.font = Paths.font("fnf1.ttf");
        causeofdeath.color = 0xFFFFFFFF;
		for (letter in alphabet) {
			causeofdeath.soundOnChars.set(letter, FlxG.sound.load(Paths.sound('ut/uifont'), 1));
			causeofdeath.soundOnChars.set(letter.toUpperCase(), FlxG.sound.load(Paths.sound('ut/uifont'), 1));
		}
		add(causeofdeath);

		super.create();

		new FlxTimer().start(3, function(tmr:FlxTimer)
		{
			if (!justPlayedLoop || !deathbysquare.visible)
				coolStartDeath();
		});
	}

	var justPlayedLoop:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance?.callOnScripts('onUpdate', [elapsed]);


		if (!boyfriend.isAnimationNull() && boyfriend.getAnimationName() == 'firstDeath' && boyfriend.isAnimationFinished())
		{
			boyfriend.playAnim('deathLoop');
			if(overlay != null && overlay.animation.exists('deathLoop'))
			{
				overlay.visible = true;
				overlay.animation.play('deathLoop');
			}
			justPlayedLoop = true;
		} else if (boyfriend.isAnimationNull() && !justPlayedLoop) { // just so it doesn't break if the character doesn't have a game over sprite
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
			else if (controls.BACK)
			{
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				FlxG.camera.visible = false;
				FlxG.sound.music.stop();

				Mods.loadTopMod();
				MusicBeatState.switchState(new FreeplayState());

				FlxG.sound.playMusic(Paths.music(Constants.menuMusic));
				PlayState.instance?.callOnScripts('onGameOverConfirm', [false]);
			}
			else if (justPlayedLoop && !deathbysquare.visible) { // make sure it only triggers ONCE
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
		FlxG.sound.music.play(true);
		FlxG.sound.music.volume = volume;
		causeofdeath.resetText(COD.getCOD());
        causeofdeath.start(0.05, true);
	}

	function endBullshit():Void
	{
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
					MusicBeatState.resetState();
				});
			});
			PlayState.instance?.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
