package stages;

import stages.PicoCapableStage;
import stages.objects.*;
import stages.cutscenes.PicoTankman;
import objects.Character;
import shaders.DropShadowShader;
import shaders.DropShadowScreenspace;
import substates.GameOverSubstate;
import substates.StickerSubState;
import stages.cutscenes.VideoCutscene;

class TankErect extends BaseStage {
	var sniper:FlxSprite;
	var guy:FlxSprite;
	var tankmanRim:DropShadowShader;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var cutscene:PicoTankman;
	var pico_stage:PicoCapableStage;

	public function new() {
		if (songName == "stress-(pico-mix)") pico_stage = new PicoCapableStage(true);
		super();
	}

    override function create() {
        super.create();

        var bg:BGSprite = new BGSprite('erect/bg', -985, -805, 1,1);
        bg.scale.set(1.15,1.15);
		add(bg);

        sniper = new FlxSprite( -346, 245);
		sniper.frames = Paths.getSparrowAtlas('erect/sniper');
        sniper.animation.addByPrefix("idle","Tankmanidlebaked instance 1",24);
        sniper.animation.addByPrefix("sip","tanksippingBaked instance 1",24);
        sniper.scale.set(1.15,1.15);
		add(sniper);

        guy = new FlxSprite(1175, 270);
		guy.frames = Paths.getSparrowAtlas('erect/guy');
        guy.animation.addByPrefix("idle","BLTank2 instance 1",24);
        guy.scale.set(1.15,1.15);
		add(guy);

		tankmanRun = new FlxTypedGroup<TankmenBG>();
		add(tankmanRun);
		if (PicoCapableStage.instance != null)
			PicoCapableStage.instance.onABotInit.addOnce( (pico) ->{
			applyAbotShader(pico.abot.speaker);
			applyShader(pico.abot.bg,"");
		});
		if (songName == "stress-(pico-mix)")
		{
			pico_stage.create();
			game.stages.remove(pico_stage);
			game.stages.insert(1,pico_stage);
			StickerSubState.STICKER_SET = "stickers-set-2"; //? yep, it's pico time!
			this.cutscene = new PicoTankman(this);
			if(!seenCutscene) setStartCallback(VideoCutscene.playVideo.bind('stressPicoCutscene',startCountdown));
			setEndCallback(cutscene.playCutscene);
		}

    }
    override function beatHit() {
        super.beatHit();
        if(curBeat%2 == 0){
            sniper.animation.play('idle', true); 
            guy.animation.play('idle',true); 
        }
        if(FlxG.random.bool(2)) sniper.animation.play('sip', true);
        if(songName.toLowerCase() == "stress (pico mix)"){
            // We gonna have some events here

			if (curBeat == 184) dad.animation.play("redheadsAnim", true);

			if (curBeat == 188) boyfriend.animation.play("knifeToss", true);

			if (curBeat == 344) dad.animation.play("singDOWN-alt", true); //man idk
        }
    }

	override function stepHit() {
        super.stepHit();
        if(songName.toLowerCase() == "stress (pico mix)"){
			if (curStep == 183) {
				PlayState.instance.triggerEvent("Change Character", "dad", "tankman-bloody");
			}
        }
    }

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		if(eventName == "Change Character" && ClientPrefs.data.shaders){
			switch(value1.toLowerCase().trim()) {
				case 'gf' | 'girlfriend' | '2':
					applyShader(gf, gf.curCharacter);
				case 'dad' | 'opponent' | '1':
					applyShader(dad, dad.curCharacter);
				default:
					applyShader(boyfriend, boyfriend.curCharacter);
			}
		}
	}

    override function createPost(){
		if(ClientPrefs.data.shaders) {
			applyShader(boyfriend, boyfriend.curCharacter);
			applyShader(gf, gf.curCharacter);
			applyShader(dad, dad.curCharacter);
		}

		if(!ClientPrefs.data.lowQuality)
        {
            for (daGf in gfGroup)
			{
				var gf:Character = cast daGf;
				if (gf.curCharacter == 'otis-speaker')
				{
					GameOverSubstate.characterName = 'pico-holding-nene-dead';
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 1500, true, false);
					firstTank.strumTime = 10;
					firstTank.visible = false;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if (FlxG.random.bool(16))
						{
							var tankBih = tankmanRun.recycle(TankmenBG);
							if (ClientPrefs.data.shaders) applyShader(tankBih, ""); // Is this wasting resources? I don't know tbh
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.scale.set(1, 1);
							tankBih.updateHitbox();
							tankBih.resetShit(500, 150, TankmenBG.animationNotes[i][1] < 2, false);
							// @:privateAccess
							// tankBih.endingOffset = 
							tankmanRun.add(tankBih);
						}
					}
					break;
				}
			}
		}
		cutscene?.preloadCutscene();
	}

	var videoEnded:Bool = false;

	function videoCutscene(?videoName:String = null)
	{
		game.inCutscene = true;
		if (!videoEnded && videoName != null)
		{
			#if VIDEOS_ALLOWED
			game.startVideo(videoName);
			function onVideoEnd() {
				videoEnded = true;
				game.videoCutscene = null;
				videoCutscene();
			}
			game.videoCutscene.finishCallback = onVideoEnd; 
			game.videoCutscene.onSkip = onVideoEnd;
			#else // Make a timer to prevent it from crashing due to sprites not being ready yet.
			new FlxTimer().start(0.0, function(tmr:FlxTimer)
			{
				videoEnded = true;
				videoCutscene(videoName);
			});
			#end
			return;
		}
		startCountdown();
	}

	function applyAbotShader(sprite:FlxSprite){
		var rim = new DropShadowScreenspace();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFDFEF3C;
		rim.antialiasAmt = 0;
		rim.attachedSprite = sprite;
		rim.distance = 5;
		rim.angle = 90;
		sprite.shader = rim;
		sprite.animation.callback = function(anim, frame, index)
		{
			rim.updateFrameInfo(sprite.frame);
			rim.curZoom = camGame.zoom;
		};
	}

    function applyShader(sprite:FlxSprite, char_name:String)
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFDFEF3C;
		rim.threshold = 0.3;
		rim.attachedSprite = sprite;
		rim.distance = 15;
		rim.strength = 1;
		rim.angle = 90;
		switch (char_name)
		{
			case "bf":
				{
					rim.threshold = 0.1;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			case "gf-tankmen":
				{
					rim.setAdjustColor(-42, -10, 5, -25);
					rim.distance = 3;
					rim.threshold = 0.3;
					rim.altMaskImage = Paths.image("erect/masks/gfTankmen_mask").bitmap;
					rim.maskThreshold = 1;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}

			case "tankman-bloody":
				{
					rim.angle = 135;
					rim.altMaskImage = Paths.image("erect/masks/tankmanCaptainBloody_mask").bitmap;
					rim.maskThreshold = 1;
					rim.threshold = 0.3;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			case "tankman":
				{
					rim.angle = 135;
					rim.maskThreshold = 1;
					rim.useAltMask = false;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			case "nene":
				{
					rim.threshold = 0.3;
					rim.angle = 90;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			default:
				{
					rim.angle = 90;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
		}
		sprite.shader = rim;
	}
}