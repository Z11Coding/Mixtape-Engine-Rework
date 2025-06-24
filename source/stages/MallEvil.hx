package stages;

import stages.objects.*;

class MallEvil extends BaseStage
{
	var snowSprites:Array<MallSnow> = [];
	override function create()
	{
		var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		if(!ClientPrefs.data.lowQuality) {
			var snowSprite = new MallSnow({
				x: -900,
				y: -1200,
				width: 2400,
				height: 400
			});
			snowSprite.scrollFactor.set(0.15, 0.15);
			snowSprite.antialiasing = ClientPrefs.data.antialiasing;
			snowSprite.color = FlxColor.RED;
			snowSprites.push(snowSprite);
			add(snowSprite);
		}

		var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
		add(evilTree);

		var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
		add(evilSnow);
		setDefaultGF('gf-christmas');

		if (!ClientPrefs.data.lowQuality) {
			var snowSprite = new MallSnow({
				x: -900,
				y: -1200,
				width: 2400,
				height: 400
			});
			snowSprite.scrollFactor.set(0.15, 0.15);
			snowSprite.antialiasing = ClientPrefs.data.antialiasing;
			snowSprite.color = FlxColor.RED;
			snowSprites.push(snowSprite);
			add(snowSprite);
		}
		
		//Winter Horrorland cutscene
		if (isStoryMode && !seenCutscene)
		{
			switch(songName)
			{
				case 'winter-horrorland':
					setStartCallback(winterHorrorlandCutscene);
			}
		}
	}

	override function createPost() {
		super.createPost();
		if (!ClientPrefs.data.lowQuality) {
			var snowSprite = new MallSnow({
				x: -900,
				y: -1200,
				width: 2400,
				height: 400
			});
			snowSprite.scrollFactor.set(0.15, 0.15);
			snowSprite.antialiasing = ClientPrefs.data.antialiasing;
			snowSprites.push(snowSprite);
			add(snowSprite);
		}
	}

	override function beatHit() {
		if (curBeat % 2 == 0)
		{
			for (snowSprite in snowSprites)
			{
				var spawnMin = FlxG.random.int(3, 12);
				var spawnMax = spawnMin + FlxG.random.int(12, 16);
				snowSprite.spawnGroup(spawnMin, spawnMax, 0.8, 1.4, 120, 360);
			}
		}
	}

	function winterHorrorlandCutscene()
	{
		camHUD.visible = false;
		inCutscene = true;

		FlxG.sound.play(Paths.sound('Lights_Turn_On'));
		FlxG.camera.zoom = 1.5;
		camFollow.setPosition(400, -2050);
		game.isCameraOnForcedPos = true;

		// blackout at the start
		var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackScreen.scrollFactor.set();
		add(blackScreen);

		FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween) {
				remove(blackScreen);
			}
		});

		// zoom out
		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			game.isCameraOnForcedPos = false;
			camHUD.visible = true;
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					startCountdown();
				}
			});
		});
	}
}