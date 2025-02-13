package states;
import stages.objects.*;

class What extends MusicBeatState 
{
    var what1:FlxText;
    var what2:FlxText;
    var what3:FlxText;
    var what4:FlxText;
    var what5:FlxText;
    var whatT1:FlxTween;
    var whatT2:FlxTween;
    var whatT3:FlxTween;
    var whatT4:FlxTween;
    var whatT5:FlxTween;
    var whatT1A:FlxTween;
    var whatT2A:FlxTween;
    var whatT3A:FlxTween;
    var whatT4A:FlxTween;
    var whatT5A:FlxTween;
    var what:FlxSound;
    var whatGrad:FlxSprite;
    var whatLogo:FlxSprite;
    var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;

    override public function create()
    {
        states.InitState.gameInitialized = true;
        // var titleStateCheckFunc = EventFunc.createEventFunc(
        //     "CheckForTitleState", // eventName
        //     EventType.EqualTo(TitleState), // eventType, checking for equality with TitleState class
        //     2 + 2, // expression, assuming this is a placeholder for the actual logic
        //     function() { trace("Now in TitleState!"); }, // func, the action to perform when the condition is met
        //     true // destroyOnTrigger, set to false if you want to keep checking
        // );
        // FlxG.sound.volume = 0.5;
        whatGrad = new FlxSprite().loadGraphic(Paths.image('effects/GradientSplash'));
        whatGrad.screenCenter();
        whatGrad.color = FlxColor.PURPLE;
        whatGrad.alpha = 0;
        add(whatGrad);
        what1 = new FlxText(0, 0, 400, "WHAT", 32);
        what1.font = Paths.font('FridayNightFunkin.ttf');
        what1.screenCenter();
        what1.x += 420;
        what1.y += 420;
        what1.size = 100;
        add(what1);
        what2 = new FlxText(0, 0, 400, "WHAT", 32);
        what2.font = Paths.font('FridayNightFunkin.ttf');
        what2.screenCenter();
        what2.x += 420;
        what2.y -= 450;
        what2.size = 100;
        add(what2);
        what3 = new FlxText(0, 0, 400, "WHAT", 32);
        what3.font = Paths.font('FridayNightFunkin.ttf');
        what3.screenCenter();
        what3.x -= 420;
        what3.y -= 450;
        what3.size = 100;
        add(what3);
        what4 = new FlxText(0, 0, 400, "WHAT", 32);
        what4.font = Paths.font('FridayNightFunkin.ttf');
        what4.screenCenter();
        what4.x -= 420;
        what4.y += 420;
        what4.size = 100;
        add(what4);
        whatLogo = new FlxSprite().loadGraphic(Paths.image('logo'));
        whatLogo.screenCenter();
        whatLogo.alpha = 0;
        whatLogo.setGraphicSize(Std.int(whatLogo.width * 0.3));
        whatLogo.y -= 50;
        add(whatLogo);
        what5 = new FlxText(0, 0, 1200, "MIXTAPE ENGINE", 32);
        what5.font = Paths.font('FridayNightFunkin.ttf');
        what5.screenCenter();
        what5.x += 100;
        what5.size = 100;
        what5.y += 200;
        what5.alpha = 0;
        add(what5);
        phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
        phillyGlowParticles.visible = true;
        add(phillyGlowParticles);
        what = new FlxSound().loadEmbedded(Paths.sound('WHAT_STARTUP'));
        what.volume = 0.5;
        FlxG.sound.list.add(what);
        what.play();
        //FlxG.sound.play(Paths.sound('WHAT_STARTUP'));
        new FlxTimer().start(12, function(tmr:FlxTimer)
        {
           TransitionState.transitionState(TitleState, {duration: 1.5, transitionType: "stickers", color: FlxColor.BLACK});
        });
        whatT1 = FlxTween.tween(what1, {x:what5.x + 350, y:what5.y}, 8, {ease: FlxEase.expoInOut});
        whatT2 = FlxTween.tween(what2, {x:what5.x + 350, y:what5.y}, 8, {ease: FlxEase.expoInOut});
        whatT3 = FlxTween.tween(what3, {x:what5.x + 350, y:what5.y}, 8, {ease: FlxEase.expoInOut});
        whatT4 = FlxTween.tween(what4, {x:what5.x + 350, y:what5.y}, 8, {ease: FlxEase.expoInOut});

        whatT1A = FlxTween.tween(what1, {alpha: 0}, 8, {ease: FlxEase.expoInOut});
        whatT2A = FlxTween.tween(what2, {alpha: 0}, 8, {ease: FlxEase.expoInOut});
        whatT3A = FlxTween.tween(what3, {alpha: 0}, 8, {ease: FlxEase.expoInOut});
        whatT4A = FlxTween.tween(what4, {alpha: 0}, 8, {ease: FlxEase.expoInOut});

        new FlxTimer().start(6, function(tmr:FlxTimer)
        {
            what5.alpha = 1;
            whatGrad.alpha = 1;
            whatLogo.alpha = 1;
            whatT1A = FlxTween.tween(what5, {alpha: 0}, 4, {ease: FlxEase.expoInOut});
            whatT2A = FlxTween.tween(whatGrad, {alpha: 0}, 4, {ease: FlxEase.expoInOut});
            whatT3A = FlxTween.tween(whatLogo, {alpha: 0}, 4, {ease: FlxEase.expoInOut});
            var particlesNum:Int = FlxG.random.int(8, 12);
            var width:Float = (2000 / particlesNum);
            var color:FlxColor = FlxColor.PURPLE;
            for (j in 0...3)
            {
                for (i in 0...particlesNum)
                {
                    var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), 400 + 200 + (FlxG.random.float(0, 125) + j * 40), color);
                    phillyGlowParticles.add(particle);
                }
            }
        });
        
        super.create();
    }

    override public function onFocus():Void
    {
        what.resume();
        if (whatT1 != null) whatT1.active = true;
        if (whatT2 != null) whatT2.active = true;
        if (whatT3 != null) whatT3.active = true;
        if (whatT4 != null) whatT4.active = true;
        if (whatT5 != null) whatT5.active = true;
        if (whatT1A != null) whatT1A.active = true;
        if (whatT2A != null) whatT2A.active = true;
        if (whatT3A != null) whatT3A.active = true;
        if (whatT4A != null) whatT4A.active = true;
        if (whatT5A != null) whatT5A.active = true;
        super.onFocus();
    }

    override public function onFocusLost():Void
    {
        what.pause();
        if (whatT1 != null) whatT1.active = false;
        if (whatT2 != null) whatT2.active = false;
        if (whatT3 != null) whatT3.active = false;
        if (whatT4 != null) whatT4.active = false;
        if (whatT5 != null) whatT5.active = false;
        if (whatT1A != null) whatT1A.active = false;
        if (whatT2A != null) whatT2A.active = false;
        if (whatT3A != null) whatT3A.active = false;
        if (whatT4A != null) whatT4A.active = false;
        if (whatT5A != null) whatT5A.active = false;
        super.onFocusLost();
    }

    override public function update(e)
    {
        if (FlxG.keys.justPressed.ENTER) 
        {
            FlxG.switchState(new TitleState());
            what.stop();
        }
        if(phillyGlowParticles != null)
        {
            var i:Int = phillyGlowParticles.members.length-1;
            while (i > 0)
            {
                var particle = phillyGlowParticles.members[i];
                if(particle.alpha <= 0)
                {
                    particle.kill();
                    phillyGlowParticles.remove(particle, true);
                    particle.destroy();
                }
                --i;
            }
        }
        super.update(e);
    }
}