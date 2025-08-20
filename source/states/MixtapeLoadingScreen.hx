package states;

import lime.app.Future;
import sys.thread.FixedThreadPool;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import flixel.FlxState;

import flash.media.Sound;

import backend.Song;
import stages.StageData;
import objects.Character;

import sys.thread.Thread;
import sys.thread.Mutex;

import objects.Note;
import objects.NoteSplash;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

@:privateAccess(states.LoadingState)
class MixtapeLoadingScreen extends MusicBeatState
{
	var target:FlxState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	// Loading bar elements
	var barGroup:FlxSpriteGroup;
	var bar:FlxSprite;
	var barWidth:Int = 0;
	var intendedPercent:Float = 0;
	var curPercent:Float = 0;
	var stateChangeDelay:Float = 0;

	// Mixtape theme elements (based on TitleState/splash screen)
	var bg:FlxSprite;
	var logo:FlxSprite;
	var bottomEffect:FlxSprite;
	var loadingText:FlxText;

	// Animation/effect variables
	var timePassed:Float = 0;
	var logoFloatOffset:Float = 0;
	var finishedLoading:Bool = false;
	var isExiting:Bool = false;

	public function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;
		super();
	}

	public static function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		LoadingState.loadAndSwitchState(target, stopMusic, intrusive);

	override function create()
	{
		persistentUpdate = true;

		// Create background similar to splash screen
		bg = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.color = 0xFF270138; // Purple tint similar to main menu
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		// Create the main Mixtape logo (similar to TitleState)
		logo = new FlxSprite().loadGraphic(Paths.image('logo'));
		try {
			// logo.frames = Paths.getSparrowAtlas('logoBumpin');
			// logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			// logo.animation.play('bump');
		} catch (e:haxe.Exception) {
			// Fallback to static image if animated atlas doesn't exist
			logo.loadGraphic(Paths.image('menuDesat')); // Use a basic background as fallback
		}
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.setGraphicSize(Std.int(logo.width * 0.4));
		logo.updateHitbox();
		logo.screenCenter();
		logo.y -= 200; // Move up a bit to make room for loading bar
		add(logo);

		// Create bottom effect/glow (similar to splash screen effects)
		bottomEffect = new FlxSprite(0, FlxG.height - 150);
		bottomEffect.makeGraphic(FlxG.width, 150, FlxColor.WHITE);
		bottomEffect.alpha = 0.1;
		bottomEffect.blend = ADD;
		add(bottomEffect);

		// Create loading bar group
		barGroup = new FlxSpriteGroup();
		add(barGroup);

		var barBack:FlxSprite = new FlxSprite(0, 620).makeGraphic(1, 1, FlxColor.BLACK);
		barBack.scale.set(FlxG.width - 300, 25);
		barBack.updateHitbox();
		barBack.screenCenter(X);
		barGroup.add(barBack);

		bar = new FlxSprite(barBack.x + 5, barBack.y + 5).makeGraphic(1, 1, 0xFF33FFFF); // Mixtape blue
		bar.scale.set(0, 15);
		bar.updateHitbox();
		barGroup.add(bar);
		barWidth = Std.int(barBack.width - 10);

		// Loading text
		loadingText = new FlxText(0, 660, FlxG.width, Language.getPhrase('now_loading', 'Now Loading', ['...']), 24);
		loadingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		loadingText.borderSize = 2;
		loadingText.screenCenter(X);
		add(loadingText);

		super.create();

		// Check if we should do loading or skip it based on settings
		if (ClientPrefs.data.loadingState == 'Everything' || ClientPrefs.data.loadingState == 'Song Only') {
			if (stateChangeDelay <= 0 && checkLoaded())
			{
				onLoad();
			}
		}
		else {
			loadNextDirectory();
			
			if (stopMusic && FlxG.sound.music != null)
				FlxG.sound.music.stop();

			MusicBeatState.switchState(target);
			finishedLoading = true;
		}
	}

	var transitioning:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (dontUpdate || isExiting) return;

		timePassed += elapsed;

		// Logo floating animation (subtle)
		logoFloatOffset = Math.sin(timePassed * 2) * 5;
		if (logo != null)
		{
			logo.offset.y = logoFloatOffset;
		}

		// Bottom effect breathing
		if (bottomEffect != null)
		{
			bottomEffect.alpha = 0.05 + Math.sin(timePassed * 1.5) * 0.03;
		}

		// Loading text dots animation
		var dots:String = '';
		switch(Math.floor(timePassed % 1.5 * 3))
		{
			case 0:
				dots = '.';
			case 1:
				dots = '..';
			case 2:
				dots = '...';
		}
		loadingText.text = Language.getPhrase('now_loading', 'Now Loading{1}', [dots]);

		if (!transitioning)
		{
			if (!finishedLoading && checkLoaded())
			{
				if(stateChangeDelay <= 0)
				{
					transitioning = true;
					onLoad();
					return;
				}
				else stateChangeDelay = Math.max(0, stateChangeDelay - elapsed);
			}
			intendedPercent = LoadingState.loadMax > 0 ? LoadingState.loaded / LoadingState.loadMax : 0;
		}

		// Update loading bar
		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.001) curPercent = intendedPercent;
			else curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = barWidth * curPercent;
			bar.updateHitbox();
		}
	}

	function onLoad()
	{
		if (isExiting) return;
		isExiting = true;
		
		// Choose random exit animation: fade or drop
		var exitType = FlxG.random.bool() ? 'fade' : 'drop';
		
		trace('Loading complete! Using exit animation: $exitType');

		switch(exitType)
		{
			case 'fade':
				// Fade out animation
				FlxTween.tween(logo, {alpha: 0}, 0.8, {ease: FlxEase.quadOut});
				FlxTween.tween(bottomEffect, {alpha: 0}, 0.6, {ease: FlxEase.quadOut});
				FlxTween.tween(barGroup, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
				FlxTween.tween(loadingText, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
				
				FlxTween.tween(bg, {alpha: 0}, 1.0, {
					ease: FlxEase.quadOut,
					onComplete: function(tween:FlxTween) {
						finishTransition();
					}
				});

			case 'drop':
				// Drop animation
				FlxTween.tween(logo, {y: FlxG.height + 100, angle: FlxG.random.float(-15, 15)}, 0.8, {
					ease: FlxEase.backIn
				});
				FlxTween.tween(bottomEffect, {alpha: 0}, 0.6, {ease: FlxEase.quadOut});
				FlxTween.tween(barGroup, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
				FlxTween.tween(loadingText, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
				
				new FlxTimer().start(0.9, function(tmr:FlxTimer) {
					finishTransition();
				});
		}
	}

	function finishTransition()
	{
		_loaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.switchState(target);
		finishedLoading = true;
	}

	// Static loading functions (copied from original LoadingState)
	static function _loaded()
	{
		LoadingState.loaded = 0;
		LoadingState.loadMax = 0;
		@:privateAccess {
		LoadingState.initialThreadCompleted = true;
		LoadingState.isIntrusive = false;
		}

		FlxTransitionableState.skipNextTransIn = true;
	}

	public static function checkLoaded():Bool
	{
		return LoadingState.checkLoaded();
	}

	public static function loadNextDirectory()
	{
		LoadingState.loadNextDirectory();
	}
}