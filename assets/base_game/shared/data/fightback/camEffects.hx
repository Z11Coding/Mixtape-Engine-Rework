import flixel.FlxG;
import backend.Difficulty;
var z11Cam:PsychCamera;
function onCreatePost()
{    
    z11Cam = new FlxCamera();
    //z11Cam.bgColor.alpha = 0;
    //z11Cam.copyFrom(game.camGame);
    z11Cam.width = FlxG.width/2;
    FlxG.cameras.add(z11Cam, true);
    z11Cam.y = -3000;
    game.gf.alpha = 0.001;

    FlxG.cameras.add(game.camOther, true);
    FlxG.cameras.add(game.camHUD, true);
    FlxCamera.defaultCameras = [z11Cam, game.camGame];

    trace("yeah it works");
}

var forceUpdate:Bool = false;
function onUpdatePost()
{
    z11Cam.scroll.x = game.gf.getMidpoint().x - 350;
    z11Cam.scroll.y = game.gf.getMidpoint().y - 920;
    if (!forceUpdate)
    {
        forceUpdate = true;
        trace("yeah it works");
    }
}

function onStepHit()
{
    if (curStep == 1)
    {
        game.gf.alpha = 1;
    }
    if (curStep == 1468)
    {
        FlxTween.tween(z11Cam, {y: 0}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.sineInOut});
    }
    if (curStep == 1536)
    {
        FlxTween.tween(z11Cam, {y: -3000}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.sineInOut});
    }
    if (curStep == 1660)
    {
        FlxTween.tween(z11Cam, {y: 0}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.sineInOut});
    }
    if (curStep == 1792)
    {
        FlxTween.tween(z11Cam, {y: -3000}, Conductor.stepCrochet*0.001*4, {ease: FlxEase.sineInOut});
    }
    if (curStep == 1793)
    {
        game.gf.flipX = true;
    }
}