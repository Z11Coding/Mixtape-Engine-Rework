package archipelago;

class Trampoline extends FlxSprite {
    // TRAMPOLINE SCRIPT!!!
    // by aflac
    // Coverted by Z11Gaming

    // WARNING:
    // offsets will not properly work
    // as of this version, if the character changes position, it will not look good.

    // config

    public var jumpBind:String = "space";
    public var gravity:Int = 32; // gravity [default: 32]
    public var jumpheight:Float = 1000;
    public var neckbreak:Int = 20; // range from 180 degrees he can be from  breaking his neck, -1 if you want to disable it, default: 20

    public var DEBUG_MODE:Bool = false; // display information

    public var allowStylePoints:Bool = true; // disable if you don't want points  to be  awarded on things like flips
    public var safetyMode:Bool = true; // combo cant be lost on mustHitSections if true
    public var autoStart:Bool = true; // start  jumping on song start, otherwise start after space was pressed

    public var trampolineOffsets:Array<Int> = [0, 0]; // offsets of  the trampoline sprite
    // { 0, 0 }     default
    // { 25, 75 }   car bf fix

    // do not touch from beyond here LOSER

    /*
        TODOs:
        * score for doing flips
        * ability to jump higher
        * lots of style point system shits
        * idk make it so you can do the hey pose mid  air for points sometimes
        * i  also wanna make it so the gravity  can  sync the jump with  beats but idk
    */

    var bouncing:Bool = false;
    var jumping:Bool = false;
    var posY:Float = 0;
    var tilt:Float = 0;
    var isPixelStaaagge:Bool = false;
    var lastBounceAng:Float = 0;
    var styleRot:Float = 0; // rotation used  to tracking flips for style points
    // vv ok i  lied  you can  touch this one vv --
    var points:Map<String, Array<Null<Dynamic>>> = [
        // cool tricks,  reccomended t o keep low because combos multiply it
        // format  is { enabled, score, text }
        'lost'      => [ false, 0, "Combo lost!"], // isn't  a trick youcan do  its just f or  text
        'backflip'  => [ true, 90, "Backflip!" ],
        'frontflip' => [ true, 90, "Frontflip!" ], // just for funsies
        'peak'      => [ true, 200, "!!!" ],       // pressing space at the peak of the bounce, why not? couldn't t hink  of a text
        'highJump'  => [ true, 100, "!!" ] // performing a "Very High" jump (timing down key press on land landing from a "high")
    ];
    var combo:Int = 0;
    var tricksLastBounce:Int = 0;
    var lastJumpHeight:Int = 0; // -1 = mini jump, 0 = normal jump, 1 = big  jump
    var isHeFuckingDead:Bool = false; // well, is he?
    var songStarted:Bool = false; // prevent style point bullshit

    var pressedSpaceOnBounce:Bool = false; // don't fuck this up

    var combo_timer:FlxTimer;
    var combo_timer_fade:FlxTimer;
    var combo_timer_fade_label:FlxTween;
    var combo_timer_fade_counter:FlxTween;

    var combo_label:FlxText;
    var combo_counter:FlxText;
    var debugTxt:FlxText;

    function spawnComboThingy(thingy, pointss) {
        combo_timer = null;
        combo_timer_fade = null;

        combo_timer_fade_label = null;
        combo_timer_fade_counter = null;

        combo_label.x = FlxG.width - FlxG.width/2.5;
        combo_counter.x = FlxG.width - FlxG.width/3;

        combo_label.y = FlxG.height/3;
        combo_counter.y = FlxG.height/3+ 38;

        combo_label.alpha = 1;
        combo_counter.alpha = 1;

        combo_label.text  = thingy;

        var pointsSt:String;

        if (pointss == 0)
            pointsSt = "";
        else
            pointsSt = '(+$pointss)';

        combo_counter.text = 'x$combo $pointsSt';

        combo_label.height = 40;

        if (isPixelStaaagge) { // make sure it isnt pixel stage because imo it looks bad with pixel font
            combo_label.size = 40;
            combo_counter.size = 25;
        }


        combo_label.velocity.y = -100;
        combo_counter.velocity.y = -100;

        combo_timer = new FlxTimer().start(0.02, function(tmr:FlxTimer)
        {
            combo_label.velocity.y += 40;
            combo_counter.velocity.y += 40;
        }, 50);

        combo_timer_fade = new FlxTimer().start(1, function(tmr:FlxTimer)
        {
            combo_timer_fade_label = FlxTween.tween(combo_label, {alpha: 0}, 1, {ease: FlxEase.quadIn});
            combo_timer_fade_counter = FlxTween.tween(combo_counter, {alpha: 0}, 1, {ease: FlxEase.quadIn});
        });
    }

    public function new() {
        super();
        if (PlayState.isPixelStage)
            isPixelStaaagge = true;

        APPlayState.instance.botplayTxt.text = "boingb oi ng   boing o bin  go  ingingbgoibing";
        APPlayState.instance.boyfriend.y -= 90;
        new FlxSprite(APPlayState.instance.boyfriend.x + (APPlayState.instance.boyfriend.width / 2) + trampolineOffsets[1], APPlayState.instance.boyfriend.y + trampolineOffsets[2]);
        loadGraphic('trampoline');
        if (isPixelStaaagge) {
            new FlxSprite(APPlayState.instance.boyfriend.x + (APPlayState.instance.boyfriend.width / 2) + trampolineOffsets[1], APPlayState.instance.boyfriend.y + trampolineOffsets[2]);
            scale.set(6, 6);
            updateHitbox();
        }

        combo_label = new FlxText(0, 0, 400, "Backflip!");
        APPlayState.instance.add(combo_label);
        combo_label.cameras = [APPlayState.instance.camHUD];
        combo_label.size = 35;

        combo_counter = new FlxText(0, 38, 200, "x10");
        APPlayState.instance.add(combo_counter);
        combo_counter.cameras = [APPlayState.instance.camHUD];
        combo_counter.size = 20;

        combo_label.alpha = 0;
        combo_counter.alpha = 0;

        combo_counter.alignment = LEFT;

        updateHitbox();

        if (isPixelStaaagge) {
            combo_counter.font = Paths.font("pixel.otf");
            combo_label.font = Paths.font("pixel.otf");
        }

        x = APPlayState.instance.boyfriend.getMidpoint().x;



        if (isPixelStaaagge) {
            x -= (width / 2.5); // weird  bug
            antialiasing = false;
            y = APPlayState.instance.boyfriend.y + (APPlayState.instance.boyfriend.height / 1.75) - (height / 2);
        }
        else {
            y = APPlayState.instance.boyfriend.y + APPlayState.instance.boyfriend.height - (height / 2);
        }

        x += trampolineOffsets[1];
        y += trampolineOffsets[2];

        debugTxt = new FlxText(10, FlxG.height / 3, FlxG.width / 3, "debug text goes here");
        debugTxt.alignment =  LEFT;
        debugTxt.cameras = [APPlayState.instance.camOther];

        // setProperty('gf.visible', false) -- she gets in the way of bfs epic trampolining skills
        // NEVERMIND SHE IS VERY GOOD AT NOT GETTING IN HIS WAY WHILE TRAMPOLINING!!!!!!
        // setProperty('botplayTxt.visible', true)

        if (DEBUG_MODE)
            APPlayState.instance.add(debugTxt);

        if (APPlayState.instance.songName == "Senpai") { // LORE
            if (!jumping) {
                posY = APPlayState.instance.boyfriend.y; // get the start point
                jumping = true;
                bouncing = true;
                APPlayState.instance.boyfriend.velocity.y = -jumpheight * 0.5; // initial jump is smaller for effect
            }
        }
    }

    // makes sure bf didnt break his neck in a jump
    // if he did ooff ouchie ouuwwwww  my  neckk  aououuoutuutuuuuu it hurty!!
    function checkIfBrokeNeck() {
        var angle = APPlayState.instance.boyfriend.angle % 360;

        @:privateAccess {
            if (!(safetyMode && PlayState.SONG.notes[MegaManager.conductor.currentMeasure].mustHitSection)) {
                if (tricksLastBounce == 0) {
                    if (combo != 0) {
                        combo = 0;
                        spawnComboThingy(points.get('lost')[2], 0);
                    }
                    else
                        combo = 0;
                }
            }
        }
        tricksLastBounce = 0;

        lastBounceAng = angle;
        styleRot = 0; // because style is only gained during air time


        if (neckbreak > -1) { // make suyre breaking your neck isnt disabled
            if (angle < 180 + neckbreak && angle > 180 - neckbreak) {
                if (lastJumpHeight > -1) { // smaller jumps wont kill you
                    bouncing = false;
                    jumping = false;
                    APPlayState.instance.boyfriend.velocity.y = 0;
                    APPlayState.instance.die(true);
                    isHeFuckingDead = true;
                } else if (lastJumpHeight == -1)
                    APPlayState.instance.health -= 0.25;
                else
                    APPlayState.instance.health -= 0.05;
            }
        }
    }

    function startJumping() {
        songStarted = true; // HI
        if (autoStart) {
            if (!jumping) {
                posY = APPlayState.instance.boyfriend.y; // get the start point
                jumping = true;
                bouncing = true;
                APPlayState.instance.boyfriend.velocity.y = -jumpheight * 0.5; // initial  jump is smaller  for  effect
            }
        }
    }

    function centerSpriteOrigin(sprite:FlxSprite) {
        sprite.origin.x = sprite.frameWidth * 0.5;
        sprite.origin.y = sprite.frameHeight * 0.5;
    }

    function onUpdate(elapsed) {
        // elapsed gets used a lot here to make sure that if a mod
        // has a faster update speed or smth or the player has a
        // shitty pc, the trampoline will still behave corrcetly
        // and not lag behind or be super slow. haven't tested it
        // but this computer im using is 7 years oldS

        centerSpriteOrigin(APPlayState.instance.boyfriend);

        FlxMath.lerp(combo_label.size, 35, 0.2 * (elapsed * 0.2));
        FlxMath.lerp(combo_counter.size, 20, 0.2 * (elapsed * 0.2));

        //TODO: make the jump button bindable
        if (jumping) {
            if (FlxG.keys.justPressed.SPACE) {
                posY = APPlayState.instance.boyfriend.y;  // get the start point
                APPlayState.instance.boyfriend.velocity.y = -jumpheight * 0.5;
                jumping = true;
                bouncing = true;
            }
        }
        else
            // for if jumping, handle the jump height n shits
            if (FlxG.keys.justPressed.SPACE) {
                if (!pressedSpaceOnBounce) {
                    if (points.get('peak')[1]) {
                        if (APPlayState.instance.boyfriend.velocity.y > -300 && APPlayState.instance.boyfriend.velocity.y < 300) {
                            APPlayState.instance.boyfriend.playAnim('hey', true);
                            APPlayState.instance.boyfriend.specialAnim = true;
                            APPlayState.instance.boyfriend.heyTimer = 0.6;
                            APPlayState.instance.comboManager.songScore += points.get('peak')[2];
                            combo++;
                            tricksLastBounce++; // SAFE
                            spawnComboThingy(points.get('peak')[3], points.get('peak')[2]);

                        }
                    }
                }
                pressedSpaceOnBounce = true;
            }

            if (APPlayState.instance.boyfriend.y >= posY) {
                checkIfBrokeNeck();
                if (bouncing) {
                    APPlayState.instance.boyfriend.y = posY;
                    jumping = true;
                    pressedSpaceOnBounce = false; // a new bounce
                    var lastlastjumpheight:Int;
                    lastlastjumpheight = lastJumpHeight;

                    lastJumpHeight = 0;
                    if (lastlastjumpheight == 2)
                        lastJumpHeight = 1;

                    var additional:Float = 0;
                    if (PlayState.instance.controls.NOTE_UP) {
                        additional = jumpheight * 0.25;
                        lastJumpHeight = 1;
                    }

                    if (PlayState.instance.controls.NOTE_DOWN) {
                        if (lastlastjumpheight == 1) {
                            additional = jumpheight * 0.5;
                            lastJumpHeight = 2;
                            lastlastjumpheight = 2; // prevent conflict
                            if (points.get('highJump')[1])
                                APPlayState.instance.comboManager.songScore += points.get('highJump')[2];
                        }
                        else if (lastlastjumpheight == -1 || lastlastjumpheight == -2) {
                            additional = jumpheight * -0.2;
                            lastJumpHeight = -2;
                        } else {
                            additional = jumpheight * -0.05;
                            lastJumpHeight = -1;
                        }
                    }

                    if (lastlastjumpheight == 1)
                        additional = jumpheight * 0.25;

                    FlxG.sound.play(Paths.sound('boing'));
                    PlayState.instance.boyfriend.velocity.y = -jumpheight + FlxG.random.int(-50, 50) - additional;
                }
            else {
                // setProperty("boyfriend.velocity.x",getProperty('boyfriend.velocity.x')+50) // https://twitter.com/aflaccck/status/1595932461082763264
                if (APPlayState.instance.controls.NOTE_LEFT)
                    tilt = tilt - 0.5;

                if (APPlayState.instance.controls.NOTE_RIGHT)
                    tilt = tilt + 0.5;

                var additional:Float = 0;

                if (APPlayState.instance.controls.NOTE_DOWN)
                    additional = 30;

                APPlayState.instance.boyfriend.velocity.y += (gravity + additional) * (elapsed * 40);
            }
        }

        // flips system
        if (allowStylePoints && songStarted) { // disregard everything i said
            if (styleRot >= 360 && points.get('backflip')[1]) {
                // FUCCIN BACKFLIP
                combo++;
                tricksLastBounce++;
                styleRot         = styleRot - 360;
                APPlayState.instance.comboManager.songScore += Std.int(points.get('backflip')[2] * (combo * 1.1));
                APPlayState.instance.boyfriend.playAnim('hey', true);
                APPlayState.instance.boyfriend.specialAnim = true;
                APPlayState.instance.boyfriend.heyTimer = 0.6;
                spawnComboThingy(points.get('backflip')[3], Std.int(points.get('backflip')[2] * (combo * 1.1)));
            }

            if (styleRot <= -360 && points.get('frontflip')[1]) {
                // FUCCIN FRONTFLIP
                combo++;
                styleRot         = styleRot + 360;
                tricksLastBounce++;
                APPlayState.instance.comboManager.songScore += Std.int(points.get('frontflip')[2] * (combo * 1.1));
                APPlayState.instance.boyfriend.playAnim('hey', true);
                APPlayState.instance.boyfriend.specialAnim = true;
                APPlayState.instance.boyfriend.heyTimer = 0.6;
                spawnComboThingy(points.get('frontflip')[3], Std.int(points.get('frontflip')[2] * (combo * 1.1)));
            }
        }

        APPlayState.instance.boyfriend.angle += tilt * (elapsed * 40);
        styleRot += tilt * (elapsed * 40);

        tilt = tilt * 0.95;

        var temptilt:Int = FlxMath.absInt(Std.int(APPlayState.instance.boyfriend.angle)) % 360;
        if (APPlayState.instance.boyfriend.angle < 0)
            APPlayState.instance.boyfriend.angle = temptilt * -1;
        else
            APPlayState.instance.boyfriend.angle = temptilt;

        if (DEBUG_MODE) {
            var SILLIES = "Normal";

            if (lastJumpHeight == -2)
                SILLIES = "Very low";
            else if (lastJumpHeight == -1)
                SILLIES = "Low";
            else if (lastJumpHeight == 1)
                SILLIES = "High";
            else if (lastJumpHeight == 2)
                SILLIES = "Very high";

            var join:String = "angle: "
            + APPlayState.instance.boyfriend.angle
            + "\nlastBounceAng: "
            + lastBounceAng
            + "\nstyleRot: "
            + styleRot
            + "\ncombo: "
            + combo
            + "\nlastJumpHeight: "
            + SILLIES
            + "\nboyfriend.velocity.y: "
            + APPlayState.instance.boyfriend.velocity.y;
            debugTxt.text = join;
        }

    }
}
