import flixel.addons.effects.FlxTrail;
var godCutEnd:Bool = true;
var godMoveBf:Bool = false;
var godMoveGf:Bool = true;
var godMoveSh:Bool = false;
var sh_r:Float = 600;
var gf_launched:Bool = false;
var rock:FlxSprite;
var gf_rock:FlxSprite;
var doorFrame:FlxSprite;
var legs:FlxSprite;
var shaggyT:FlxTrail;
var legT:FlxTrail;
var burst:FlxSprite;
var camLerp:Float = 1;
var localStep:Int = 0;

function onCreate()
{
    var sky = new FlxSprite(-850, -850);
    sky.frames = Paths.getSparrowAtlas('stages/shag/god_bg');
    sky.animation.addByPrefix('sky', "bg", 30);
    sky.setGraphicSize(Std.int(sky.width * 0.8));
    sky.animation.play('sky');
    sky.scrollFactor.set(0.1, 0.1);
    sky.antialiasing = true;
    addBehindGF(sky);

    var bgcloud = new FlxSprite(-850, -1250);
    bgcloud.frames = Paths.getSparrowAtlas('stages/shag/god_bg');
    bgcloud.animation.addByPrefix('c', "cloud_smol", 30);
    //bgcloud.setGraphicSize(Std.int(bgcloud.width * 0.8));
    bgcloud.animation.play('c');
    bgcloud.scrollFactor.set(0.3, 0.3);
    bgcloud.antialiasing = true;
    addBehindGF(bgcloud);

    /*addBehindGF(new MansionDebris(300, -800, 'norm', 0.4, 1, 0, 1));
    addBehindGF(new MansionDebris(600, -300, 'tiny', 0.4, 1.5, 0, 1));
    addBehindGF(new MansionDebris(-150, -400, 'spike', 0.4, 1.1, 0, 1));
    addBehindGF(new MansionDebris(-750, -850, 'small', 0.4, 1.5, 0, 1));

    addBehindGF(new MansionDebris(-300, -1700, 'norm', 0.75, 1, 0, 1));
    addBehindGF(new MansionDebris(-1000, -1750, 'rect', 0.75, 2, 0, 1));
    addBehindGF(new MansionDebris(-600, -1100, 'tiny', 0.75, 1.5, 0, 1));
    addBehindGF(new MansionDebris(900, -1850, 'spike', 0.75, 1.2, 0, 1));
    addBehindGF(new MansionDebris(1500, -1300, 'small', 0.75, 1.5, 0, 1));
    addBehindGF(new MansionDebris(-600, -800, 'spike', 0.75, 1.3, 0, 1));
    addBehindGF(new MansionDebris(-1000, -900, 'small', 0.75, 1.7, 0, 1));*/

    var fgcloud = new FlxSprite(-1150, -2900);
    fgcloud.frames = Paths.getSparrowAtlas('stages/shag/god_bg');
    fgcloud.animation.addByPrefix('c', "cloud_big", 30);
    //bgcloud.setGraphicSize(Std.int(bgcloud.width * 0.8));
    fgcloud.animation.play('c');
    fgcloud.scrollFactor.set(0.9, 0.9);
    fgcloud.antialiasing = true;
    addBehindGF(fgcloud);

    var bg:FlxSprite = new FlxSprite(-400, -160).loadGraphic(Paths.image('stages/shag/bg_lemon'));
    bg.setGraphicSize(Std.int(bg.width * 1.5));
    bg.antialiasing = true;
    bg.scrollFactor.set(0.95, 0.95);
    bg.active = false;
    addBehindGF(bg);

    var techo = new FlxSprite(0, -20);
    techo.frames = Paths.getSparrowAtlas('stages/shag/god_bg');
    techo.animation.addByPrefix('r', "broken_techo", 30);
    techo.setGraphicSize(Std.int(techo.frameWidth * 1.5));
    techo.animation.play('r');
    techo.scrollFactor.set(0.95, 0.95);
    techo.antialiasing = true;
    addBehindGF(techo);

    gf_rock = new FlxSprite(20, 20);
    gf_rock.frames = Paths.getSparrowAtlas('stages/shag/god_bg');
    gf_rock.animation.addByPrefix('rock', "gf_rock", 30);
    gf_rock.animation.play('rock');
    gf_rock.scrollFactor.set(0.8, 0.8);
    gf_rock.antialiasing = true;
    gf_rock.alpha = 0;
    addBehindGF(gf_rock);

    rock = new FlxSprite(20, 20);
    rock.frames = Paths.getSparrowAtlas('stages/shag/god_bg');
    rock.animation.addByPrefix('rock', "rock", 30);
    rock.animation.play('rock');
    rock.scrollFactor.set(1, 1);
    rock.antialiasing = true;
    rock.alpha = 0;
    addBehindDad(rock);

    //god eater legs
    legs = new FlxSprite(-850, -850);
    legs.frames = Paths.getSparrowAtlas('characters/pshaggy');
    legs.animation.addByPrefix('legs', "solo_legs", 30);
    legs.animation.play('legs');
    legs.antialiasing = true;
    legs.updateHitbox();
    legs.offset.set(legs.frameWidth / 2, 10);
    legs.alpha = 0;
    addBehindBF(legs);
}

function onSongStart() {
    gf_rock.alpha = 1;
}

function onUpdate() {
    var rotRate = localStep * 0.25;
    var rotRateSh = localStep / 9.5;
    var rotRateGf = localStep / 9.5 / 4;
    var derp = 12;

    if (godCutEnd)
    {
        var bf_toy = -2000 + Math.sin(rotRate) * 20;

        var sh_toy = -2450 + -Math.sin(rotRateSh * 2) * sh_r * 0.45;
        var sh_tox = -330 -Math.cos(rotRateSh) * sh_r;

        var gf_tox = 100 + Math.sin(rotRateGf) * 200;
        var gf_toy = -2000 -Math.sin(rotRateGf) * 80;

        if (godMoveBf)
        {
            game.dad.y += (bf_toy - (game.dad.y + 400)) / derp;
            rock.x = game.dad.x - 200;
            rock.y = game.dad.y + 500;
            rock.alpha = 1;
        }

        if (godMoveSh)
        {
            //game.moveCameraSection();
            game.boyfriend.x += (sh_tox - (game.boyfriend.x + 700)) / 12;
            game.boyfriend.y += (sh_toy - game.boyfriend.y) / 12;
            legs.x = game.boyfriend.x + 120 + Math.cos((legs.angle + 90) * (Math.PI/180)) * 150;
            legs.y = game.boyfriend.y + 300 + Math.sin((legs.angle + 90) * (Math.PI/180)) * 150;

            if (game.boyfriend.animation.curAnim.name == 'idle')
            {
                sh_r = 60;
                var pene = 0.07;
                game.boyfriend.angle = Math.sin(rotRateSh) * sh_r * pene / 4;

                legs.alpha = 1;
                legs.angle = Math.sin(rotRateSh) * sh_r * pene;// + Math.cos(curStep) * 5;
            }
            else
            {
                sh_r = 100;
                rotRateSh *= 1.2;
                game.boyfriend.angle = 0;
                legs.alpha = 0;
            }
            legT.visible = true;
            if (legs.alpha == 0)
                legT.visible = false;
        }

        if (godMoveGf)
        {
            game.gf.x += (gf_tox - game.gf.x) / derp;
            game.gf.y += (gf_toy - game.gf.y) / derp;

            gf_rock.x = game.gf.x - 100;
            gf_rock.y = game.gf.y + 450;
            gf_rock.alpha = 1;
            if (!gf_launched)
            {
                game.gf.scrollFactor.set(0.8, 0.8);
                game.gf.setGraphicSize(Std.int(game.gf.width * 0.8));
                gf_launched = true;
            }
        }
    }
    if (!godCutEnd || !godMoveBf)
    {
        rock.alpha = 0;
    }
}

function onStepHit() {
    localStep = curStep;
    if (curStep == 1261) superShaggy();
    if (curStep == 2800)
    {
        remove(shaggyT);
        FlxG.camera.flash(game.camGame, 0xFFFFFFFF, 2, true);
        godMoveBf = true;
        godMoveSh = true;
        shaggyT = new FlxTrail(game.boyfriend, null, 5, 7, 0.3, 0.001);
        insert(game.boyfriendGroup.members.indexOf(game.boyfriendGroup) - 6, shaggyT);

        legT = new FlxTrail(legs, null, 5, 7, 0.3, 0.001);
        insert(game.boyfriendGroup.members.indexOf(game.boyfriendGroup) - 7, legT);

        dadGroup.y -= 6000;
        dad.flipX = true; 
    }
}

var cutTime = 0;
function superShaggy()
{
    new FlxTimer().start(0.008, function(ct:FlxTimer)
    {
        switch (cutTime)
        {
            case 0:
                game.camFollow.x = game.boyfriend.getMidpoint().x - 100;
                game.camFollow.y = game.boyfriend.getMidpoint().y;
                camLerp = 2;
                trace('why1');
            case 15:
                game.boyfriend.playAnim('powerup', true);
                game.boyfriend.specialAnim = true;
                trace('why2');
            case 48:
                game.boyfriend.playAnim('danceLeft-alt', true);
                game.triggerEvent('Alt Idle Animation', 'bf', '-alt');
                burst = new FlxSprite(-1110, 0);
                FlxG.sound.play(Paths.sound('burst'));
                remove(burst);
                burst = new FlxSprite(game.boyfriend.getMidpoint().x - 1000, game.boyfriend.getMidpoint().y - 100);
                burst.frames = Paths.getSparrowAtlas('characters/shaggy');
                burst.animation.addByPrefix('burst', "burst", 30);
                burst.animation.play('burst');
                //burst.setGraphicSize(Std.int(burst.width * 1.5));
                burst.antialiasing = true;
                add(burst);

                FlxG.sound.play(Paths.sound('powerup'), 1);

                shaggyT = new FlxTrail(game.boyfriend, null, 3, 6, 0.3, 0.002);
                shaggyT.visible = true;
                insert(game.boyfriendGroup.members.indexOf(game.boyfriendGroup) - 6, shaggyT);
                trace('why3');
            case 62:
                burst.y = 0;
                remove(burst);
                trace('why4');
            case 95:
                FlxG.camera.angle = 0;
                trace('why5');
        }

        var ssh:Float = 45;
        var stime:Float = 30;
        var corneta:Float = (stime - (cutTime - ssh)) / stime;

        if (cutTime % 6 >= 3)
        {
            corneta *= -1;
        }
        if (cutTime >= ssh && cutTime <= ssh + stime)
        {
            FlxG.camera.angle = corneta * 5;
        }
        cutTime += 1;
        ct.reset(0.008);
    });
}