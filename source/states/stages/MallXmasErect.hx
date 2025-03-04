package states.stages;

import shaders.AdjustColorShader;
import substates.GameOverSubstate;
import states.stages.objects.*;
import states.stages.PicoCapableStage;

class MallXmasErect extends PicoCapableStage
{
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	override function create()
	{
		var _song = PlayState.SONG;
		
		var bg:BGSprite = new BGSprite('stages/christmas/erect/bgWalls', -1000, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		if(!ClientPrefs.data.lowQuality) {
			upperBoppers = new BGSprite('stages/christmas/erect/upperBop', -240, -90, 0.33, 0.33, ['upperBop']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('stages/christmas/erect/bgEscalator', -1100, -600, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);
		}

		var tree:BGSprite = new BGSprite('stages/christmas/erect/christmasTree', 370, -250, 0.40, 0.40);
		add(tree);

		var fog = new BGSprite("stages/christmas/erect/white",-1000,100,0.85,0.85);
		fog.scale.set(0.9,0.9);
		add(fog);

		bottomBoppers = new MallCrowd(-300, 140,'stages/christmas/erect/bottomBop',"bottomBop");
		add(bottomBoppers);

		var fgSnow:BGSprite = new BGSprite('stages/christmas/erect/fgSnow', -880, 700);
		add(fgSnow);

		santa = new BGSprite('stages/christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		add(santa);
		setDefaultGF('gf-christmas');

		if(isStoryMode && !seenCutscene)
			setEndCallback(eggnogEndCutscene);
	}
	override function createPost() {
		super.createPost();
		if(ClientPrefs.data.shaders){
			var colorShader = new AdjustColorShader();
			colorShader.hue = 5;
			colorShader.saturation = 20;

			boyfriend.shader = colorShader;
			gf.shader = colorShader;
			dad.shader = colorShader;
			santa.shader = colorShader;
		}
		
		@:privateAccess
		if(PicoCapableStage.NENE_LIST.contains(PlayState.SONG.gfVersion)) GameOverSubstate.characterName = 'pico-christmas-dead';
	}
	override function countdownTick(count:Countdown, num:Int) everyoneDance();
	override function beatHit() {
		super.beatHit();
		everyoneDance();
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