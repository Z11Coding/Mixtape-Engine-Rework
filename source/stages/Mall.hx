package stages;

import stages.objects.*;

class Mall extends BaseStage
{
	var snowSprites:Array<MallSnow> = [];
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	override function create()
	{
		var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		if(!ClientPrefs.data.lowQuality) {
			upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);

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

		var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
		add(tree);

		bottomBoppers = new MallCrowd(-300, 140);
		add(bottomBoppers);

		var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
		add(fgSnow);

		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		add(santa);
		Paths.sound('Lights_Shut_off');
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
			snowSprites.push(snowSprite);
			add(snowSprite);
		}

		if(isStoryMode)
			setEndCallback(eggnogEndCutscene);
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

	override function countdownTick(count:Countdown, num:Int) everyoneDance();
	override function beatHit() everyoneDance();

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Hey!":
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						return;
				}
				bottomBoppers.animation.play('hey', true);
				bottomBoppers.heyTimer = flValue2;
		}
	}

	function everyoneDance()
	{
		if(!ClientPrefs.data.lowQuality)
			upperBoppers.dance(true);

		bottomBoppers.dance(true);
		santa.dance(true);

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

	function eggnogEndCutscene()
	{
		if(PlayState.storyPlaylist[1] == null)
		{
			endSong();
			return;
		}

		var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
		if(nextSong == 'winter-horrorland')
		{
			FlxG.sound.play(Paths.sound('Lights_Shut_off'));

			var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
				-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			blackShit.scrollFactor.set();
			add(blackShit);
			camHUD.visible = false;

			inCutscene = true;
			canPause = false;

			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				endSong();
			});
		}
		else endSong();
	}
}