package stages;

import shaders.AdjustColorShader;
import substates.GameOverSubstate;
import stages.objects.*;
import stages.PicoCapableStage;

class MallXmasErect extends PicoCapableStage
{
	var snowSprites:Array<MallSnow> = [];
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	override function create()
	{
		var _song = PlayState.SONG;
		
		var bg:BGSprite = new BGSprite('christmas/erect/bgWalls', -1000, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		if(!ClientPrefs.data.lowQuality) {
			upperBoppers = new BGSprite('christmas/erect/upperBop', -240, -90, 0.33, 0.33, ['upperBop']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('christmas/erect/bgEscalator', -1100, -600, 0.3, 0.3);
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

		var tree:BGSprite = new BGSprite('christmas/erect/christmasTree', 370, -250, 0.40, 0.40);
		add(tree);

		var fog = new BGSprite("christmas/erect/white",-1000,100,0.85,0.85);
		fog.scale.set(0.9,0.9);
		add(fog);

		bottomBoppers = new MallCrowd(-300, 140,'christmas/erect/bottomBop',"bottomBop");
		add(bottomBoppers);

		var fgSnow:BGSprite = new BGSprite('christmas/erect/fgSnow', -880, 700);
		add(fgSnow);

		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		add(santa);
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

		if(isStoryMode && !seenCutscene)
			setEndCallback(eggnogEndCutscene);
	}
	override function createPost() {
		super.createPost();
		if(ClientPrefs.data.shaders){
			var colorShader = new AdjustColorShader();
			colorShader.hue = 5;
			colorShader.saturation = 20;

			if (boyfriend != null) boyfriend.shader = colorShader;
			if (gf != null) gf.shader = colorShader;
			if (dad != null) dad.shader = colorShader;
			if (santa != null) santa.shader = colorShader;
		}
		
		@:privateAccess
		if(PicoCapableStage.NENE_LIST.contains(PlayState.SONG.gfVersion)) GameOverSubstate.characterName = 'pico-christmas-dead';

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
	override function beatHit() {
		super.beatHit();
		everyoneDance();
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
			case "Change Character":
				var colorShader = new AdjustColorShader();
				colorShader.hue = 5;
				colorShader.saturation = 20;

				boyfriend.shader = colorShader;
				gf.shader = colorShader;
				dad.shader = colorShader;

		}
	}

	function everyoneDance()
	{
		if(!ClientPrefs.data.lowQuality)
			upperBoppers.dance(true);

		bottomBoppers.dance(true);
		santa.dance(true);
	}

	function eggnogEndCutscene()
	{
		if(PlayState.storyPlaylist[1] == null)
		{
			endSong();
			return;
		}

		var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
		endSong();
	}
}