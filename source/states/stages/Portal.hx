package states.stages;

import states.stages.objects.*;

import flixel.math.FlxPoint;
import backend.cutscenes.DialogueBoxPsych;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.FlxObject;

class Portal extends BaseStage
{
	public var sh_r:Float = 60;
	var rotRateSh:Float;
	var portalBG:BGSprite;
	var portalrock:BGSprite;
	var portalDoor:BGSprite;
	var lightningLight:BGSprite;
	var darkness:BGSprite;
	var whiteScreen:FlxSprite;
	var cutSong:FlxSound;
	var wind:FlxSound;
	var powerEmitter:FlxEmitter;
	var randChan:String = '';
	override function create()
	{
		powerEmitter = new FlxEmitter(-1200, 2500);
		for (i in 0 ... 150)
		{
			var p = new FlxParticle();
			p.frames = Paths.getSparrowAtlas('noteskins/normal');
			p.animation.addByPrefix('0','A', 0, false);
			p.animation.addByPrefix('1','B', 0, false);
			p.animation.addByPrefix('2','C', 0, false);
			p.animation.addByPrefix('3','D', 0, false);
			p.animation.addByPrefix('4','E', 0, false);
			p.animation.addByPrefix('5','F', 0, false);
			p.animation.addByPrefix('6','G', 0, false);
			p.animation.addByPrefix('7','H', 0, false);
			p.animation.addByPrefix('8','I', 0, false);
			p.animation.addByPrefix('9','J', 0, false);
			p.animation.addByPrefix('10','K', 0, false);
			p.animation.addByPrefix('11','L', 0, false);
			p.animation.addByPrefix('12','M', 0, false);
			p.animation.addByPrefix('13','N', 0, false);
			p.animation.addByPrefix('14','O', 0, false);
			p.animation.addByPrefix('15','P', 0, false);
			p.animation.addByPrefix('16','Q', 0, false);
			p.animation.addByPrefix('17','R', 0, false);
			p.animation.play(Std.string(FlxG.random.int(0, 17)));
			p.exists = false;
			p.blend = ADD;
			powerEmitter.add(p);
		}
		powerEmitter.launchMode = FlxEmitterMode.SQUARE;
		powerEmitter.velocity.set(-50, -400, 50, -800, -100, 0, 100, -800);
		powerEmitter.scale.set(1, 1, 0.8, 0.8, 0, 0, 0, 0);
		powerEmitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
		powerEmitter.width = 4200.45;
		powerEmitter.alpha.set(1, 1);
		powerEmitter.lifespan.set(4, 4.5);
				
		powerEmitter.start(false, FlxG.random.float(0.3, 0.4), 100000);

		portalBG = new BGSprite('stages/portal/SpacialDisturbanceBg_20230712203810', -200, -100);
		add(portalBG);
		portalBG.setGraphicSize(Std.int(portalBG.width * 1.8));
		if (!ClientPrefs.data.noParticles) add(powerEmitter);
		portalrock = new BGSprite('stages/portal/SpacialDisturbanceBg_20230712203819', -200, -100);
		add(portalrock);
		portalrock.setGraphicSize(Std.int(portalrock.width * 1.8));
		portalDoor = new BGSprite('stages/portal/SpacialDisturbanceBg_20230712203815', -200, -100);
		add(portalDoor);
		portalDoor.setGraphicSize(Std.int(portalDoor.width * 1.8));
	}
	
	override function createPost()
	{
		whiteScreen = new FlxSprite().loadGraphic(Paths.image('mechanics/general/white'));
		whiteScreen.setGraphicSize(Std.int(FlxG.width * 2400), Std.int(FlxG.height * 2400));
		whiteScreen.scrollFactor.set();
		whiteScreen.blend = ADD;
		whiteScreen.cameras = [camOther];
		whiteScreen.alpha = 0;
		whiteScreen.screenCenter();
		add(whiteScreen);
	}

	override function update(elapsed:Float)
	{
		rotRateSh = curStep / 9.5;
		var sh_toy = -Math.sin(rotRateSh * 2) * sh_r * 0.45;
		var sh_tox = -Math.cos(rotRateSh) * (sh_r * 2);
		if (portalrock != null) portalrock.y += (sh_toy - portalrock.y) / 12;
		whiteScreen.cameras = [camOther];
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	override function beatHit()
	{
		if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.hasAnimation('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.hasAnimation('scared')) {
			gf.playAnim('scared', true);
		}

		if(dad != null && dad.hasAnimation('scared')) {
			dad.playAnim('scared', true);
		}

		if(ClientPrefs.data.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!game.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.data.flashing) {
			whiteScreen.alpha = 0.4;
			FlxTween.tween(whiteScreen, {alpha: 0.5}, 0.075);
			FlxTween.tween(whiteScreen, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}
}