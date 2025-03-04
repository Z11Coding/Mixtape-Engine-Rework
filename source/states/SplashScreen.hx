package states;
import states.stages.objects.*;

//About time i got around to this
class SplashScreen extends MusicBeatState 
{
    var mix:FlxText;
    var tape:FlxText;
    var engine:FlxText;
    var mixtapeEngine:FlxText;

    var mixT:FlxTween;
    var tapeT:FlxTween;
    var engineT:FlxTween;
    var mixtapeEngineT:FlxTween;
    
    var camTween:FlxTween;
    var mixTA:FlxTween;
    var tapeTA:FlxTween;
    var engineTA:FlxTween;
    var mixtapeEngineTA:FlxTween;
    var splashTA:FlxTween;
    
    var splashSound:FlxSound;
    var splashGrad:FlxSprite;
    var mixtapeLogo:FlxSprite;
    var splashGlowParticles:FlxTypedGroup<SplashGlowParticle>;
    var initX:Float;

    override public function create()
    {
        states.FirstCheckState.gameInitialized = true;
        splashGrad = new FlxSprite().loadGraphic(Paths.image('effects/GradientSplash'));
        splashGrad.screenCenter();
        splashGrad.color = FlxColor.PURPLE;
        splashGrad.alpha = 0;
        add(splashGrad);

        mix = new FlxText(0, 0, 400, "MIX", 32);
        mix.font = Paths.font('FridayNightFunkin.ttf');
        mix.screenCenter();
        mix.x -= 300;
        mix.size = 100;
        mix.alpha = 0;
        add(mix);
        initX = mix.x;

        tape = new FlxText(0, 0, 400, "TAPE", 32);
        tape.font = Paths.font('FridayNightFunkin.ttf');
        tape.screenCenter();
        tape.x -= 300;
        tape.y += 200;
        tape.size = 100;
        tape.alpha = 0;
        add(tape);

        engine = new FlxText(0, 0, 800, "ENGINE", 32);
        engine.font = Paths.font('FridayNightFunkin.ttf');
        engine.screenCenter();
        engine.x -= 300;
        engine.y += 200;
        engine.size = 100;
        engine.alpha = 0;
        add(engine);

        mixtapeLogo = new FlxSprite().loadGraphic(Paths.image('logo'));
        mixtapeLogo.screenCenter();
        mixtapeLogo.alpha = 0;
        mixtapeLogo.setGraphicSize(Std.int(mixtapeLogo.width * 0.3));
        mixtapeLogo.y -= 50;
        add(mixtapeLogo);

        mixtapeEngine = new FlxText(0, 0, 1200, "MIXTAPE ENGINE", 32);
        mixtapeEngine.font = Paths.font('FridayNightFunkin.ttf');
        mixtapeEngine.screenCenter();
        mixtapeEngine.x += 100;
        mixtapeEngine.size = 100;
        mixtapeEngine.y += 200;
        mixtapeEngine.alpha = 0;
        add(mixtapeEngine);

        mix.y = mixtapeEngine.y;
        tape.y = mixtapeEngine.y;
        engine.y = mixtapeEngine.y;

        splashGlowParticles = new FlxTypedGroup<SplashGlowParticle>();
        splashGlowParticles.visible = true;
        add(splashGlowParticles);

        splashSound = new FlxSound().loadEmbedded(Paths.sound('You Win'));
        splashSound.volume = 0.5;
        FlxG.sound.list.add(splashSound);
        splashSound.onComplete = finishSong.bind();
        Conductor.bpm = 100;
        new FlxTimer().start(1, function(tmr:FlxTimer)
        {
            splashSound.play();
            mix.x += 600;
            tape.x += 600;
            engine.x += 600;
            mix.alpha = 1;
            mixT = FlxTween.tween(mix, {x:initX, y:mixtapeEngine.y}, Conductor.stepCrochet*0.001*3, {ease: FlxEase.expoInOut});
            mixTA = FlxTween.tween(mix, {alpha: 0}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.expoInOut});
        });
        super.create();
    }

    function particleBoom() {
        splashGrad.alpha = 1;
        var particlesNum:Int = FlxG.random.int(8, 12);
        var width:Float = (2000 / particlesNum);
        var color:FlxColor = FlxColor.PURPLE;
        for (j in 0...3)
        {
            for (i in 0...particlesNum)
            {
                var particle:SplashGlowParticle = new SplashGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), 400 + 200 + (FlxG.random.float(0, 125) + j * 40), color);
                splashGlowParticles.add(particle);
            }
        }
        splashTA = FlxTween.tween(splashGrad, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
    }

    override function stepHit()
    {
        super.stepHit();
        switch (curStep)
        {
            case 3:
                tape.alpha = 1;
                tapeT = FlxTween.tween(tape, {x:initX + 235, y:mixtapeEngine.y}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.expoInOut});
                tapeTA = FlxTween.tween(tape, {alpha: 0}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.expoInOut});
            case 6:
                particleBoom();
                engine.alpha = 1;
                engineT = FlxTween.tween(engine, {x:tape.x + 305, y:mixtapeEngine.y}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.expoInOut});
                engineTA = FlxTween.tween(engine, {alpha: 0}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.expoInOut});
            case 9:
                FlxG.camera.zoom = 3;
                FlxG.camera.scrollAngle = (360*2);
            case 10:
                mixtapeLogo.alpha = 1;
                camTween = FlxTween.tween(FlxG.camera, {zoom: 1, scrollAngle: 0}, Conductor.stepCrochet*0.001*2, {ease: FlxEase.sineInOut});
            case 12:
                mix.alpha = 1;
                tape.alpha = 1;
                FlxG.camera.zoom = 1.2;
                FlxG.camera.scrollAngle = 15;
                camTween = FlxTween.tween(FlxG.camera, {zoom: 1, scrollAngle: 0}, Conductor.stepCrochet*0.001*1, {ease: FlxEase.sineInOut});
                mixTA = FlxTween.tween(mix, {alpha: 0}, Conductor.stepCrochet*0.001*3, {ease: FlxEase.expoInOut});
                tapeTA = FlxTween.tween(tape, {alpha: 0}, Conductor.stepCrochet*0.001*3, {ease: FlxEase.expoInOut});
            case 14:
                FlxG.camera.zoom = 1.2;
                FlxG.camera.scrollAngle = -15;
                camTween = FlxTween.tween(FlxG.camera, {zoom: 1, scrollAngle: 0}, Conductor.stepCrochet*0.001*1, {ease: FlxEase.sineInOut});    
                engine.alpha = 1;
                engineTA = FlxTween.tween(engine, {alpha: 0}, Conductor.stepCrochet*0.001*3, {ease: FlxEase.expoInOut});
            case 16:
                FlxG.camera.zoom = 1.5;
                camTween = FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.stepCrochet*0.001*8, {ease: FlxEase.sineInOut});
                particleBoom();
                mixtapeEngine.alpha = 1;
                FlxTween.tween(mixtapeEngine, {alpha: 0}, Conductor.stepCrochet*0.001*8, {ease: FlxEase.expoInOut});
                FlxTween.tween(mixtapeLogo, {alpha: 0}, Conductor.stepCrochet*0.001*8, {ease: FlxEase.expoInOut});
        }
    }

    var finishTimer:FlxTimer = null;
    public function finishSong():Void
	{
		finishTimer = new FlxTimer().start(0.1, function(tmr:FlxTimer)
        {
            Conductor.songPosition = 0;
            TransitionState.transitionState(FirstCheckState.relaunch ? MainMenuState : TitleState, {duration: 1.5, transitionType: "stickers", color: FlxColor.BLACK});
        });
	}

    override public function onFocus():Void
    {
        FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
            tmr.active = true);
        FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
            twn.active = true);
        splashSound.resume();
        super.onFocus();
    }

    override public function onFocusLost():Void
    {
        FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
            tmr.active = false);
        FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
            twn.active = false);
        splashSound.pause();
        super.onFocusLost();
    }

    override public function update(e)
    {
        if(splashSound != null)
			Conductor.songPosition = splashSound.time;

        if (FlxG.keys.justPressed.ENTER) 
        {
            FlxG.switchState(FirstCheckState.relaunch ? new MainMenuState() : new TitleState());
            splashSound.stop();
        }
        if(splashGlowParticles != null)
        {
            var i:Int = splashGlowParticles.members.length-1;
            while (i > 0)
            {
                var particle = splashGlowParticles.members[i];
                if(particle.alpha <= 0)
                {
                    particle.kill();
                    splashGlowParticles.remove(particle, true);
                    particle.destroy();
                }
                --i;
            }
        }
        super.update(e);
    }
}

class SplashGlowParticle extends FlxSprite
{
	var lifeTime:Float = 0;
	var decay:Float = 0;
	var originalScale:Float = 1;
	public function new(x:Float = 0, y:Float = 0, color:FlxColor = FlxColor.WHITE)
	{
		super(x, y);
		this.color = color;

		loadGraphic(Paths.image('effects/particle'));
		lifeTime = FlxG.random.float(0.6, 0.9);
		decay = FlxG.random.float(0.8, 1);
		if(!ClientPrefs.data.flashing)
		{
			decay *= 0.5;
			alpha = 0.5;
		}

		originalScale = FlxG.random.float(0.75, 1);
		scale.set(originalScale, originalScale);

		scrollFactor.set(FlxG.random.float(0.3, 0.75), FlxG.random.float(0.65, 0.75));
		velocity.set(FlxG.random.float(-40, 40), FlxG.random.float(-175, -250));
		acceleration.set(FlxG.random.float(-10, 10), 25);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	override function update(elapsed:Float)
	{
		lifeTime -= elapsed;
		if(lifeTime < 0)
		{
			lifeTime = 0;
			alpha -= decay * elapsed;
			if(alpha > 0)
			{
				scale.set(originalScale * alpha, originalScale * alpha);
			}
		}
		super.update(elapsed);
	}
}