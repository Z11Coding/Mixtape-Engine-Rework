package archipelago;

import objects.charting.ChartingStrumNote as StrumNote;

class TrapLinkFunctions {
    static var bfPosition:Array<Float>;
    static var bfMaxPos:Array<Float>;
    public static function doCarCrash(random:Bool, ?direction:Null<Int>) {
        for (i in bfPosition) {
            bfMaxPos.push(i+5000);
        }

        var curDirec:Int = 3;
        
        if (random) curDirec = FlxG.random.int(0, 3);
        if (direction != null) curDirec = direction;

        switch(curDirec) {
            case 0:
                FlxTween.tween(APPlayState.instance.boyfriend, {x: (-1 * bfMaxPos[0])}, 0.6, {ease: FlxEase.expoIn, onComplete: 
                function (twn:FlxTween)
                {
                    FlxG.sound.play(Paths.sound("carCrash") ,2);
                    APPlayState.instance.triggerEvent('Screen Shake', '0.35, 0.05', '');
                    FlxTween.tween(APPlayState.instance.boyfriend, {x: bfPosition[0]}, 2, {ease: FlxEase.expoOut});
                }});
            case 1:
                FlxTween.tween(APPlayState.instance.boyfriend, {y: bfMaxPos[1]}, 0.6, {ease: FlxEase.expoIn, onComplete: 
                function (twn:FlxTween)
                {
                    FlxG.sound.play(Paths.sound("carCrash") ,2);
                    APPlayState.instance.triggerEvent('Screen Shake', '0.35, 0.05', '');
                    FlxTween.tween(APPlayState.instance.boyfriend, {y: bfPosition[1]}, 2, {ease: FlxEase.expoOut});
                }});
            case 2:
                FlxTween.tween(APPlayState.instance.boyfriend, {y: (-1 * bfMaxPos[1])}, 0.6, {ease: FlxEase.expoIn, onComplete: 
                function (twn:FlxTween)
                {
                    FlxG.sound.play(Paths.sound("carCrash") ,2);
                    APPlayState.instance.triggerEvent('Screen Shake', '0.35, 0.05', '');
                    FlxTween.tween(APPlayState.instance.boyfriend, {y: bfPosition[1]}, 2, {ease: FlxEase.expoOut});
                }});
            case 3:
                FlxTween.tween(APPlayState.instance.boyfriend, {x: bfMaxPos[0]}, 0.6, {ease: FlxEase.expoIn, onComplete: 
                function (twn:FlxTween)
                {
                    FlxG.sound.play(Paths.sound("carCrash") ,2);
                    APPlayState.instance.triggerEvent('Screen Shake', '0.35, 0.05', '');
                    FlxTween.tween(APPlayState.instance.boyfriend, {x: bfPosition[0]}, 2, {ease: FlxEase.expoOut});
                }});
        }
        
    }

    static var daCoolTween:FlxTween;
    static var grpNotes:FlxTween;
    static var randArray:FlxTween;
    public static function doBushwakThings(?length:Int = 4) {
        randArray = [for (i in 0...length) FlxG.random.int(0, 3)];

        for (i in grpNotes) { i.kill(); APPlatState.instance.remove(i); i.destroy(); }

        grpNotes = [];

        var colArray = ['purple', 'blue', 'green', 'red'];

        for (i in 0...randArray.length) {
            cool = new StrumNote(0, 0, randArray[i], 0);
            if (!APPlatState.instance.isPixelStage) cool.animation.addByPrefix('color', colArray[cool.noteData] + '0', 24, true);
            cool.playAnim('static');
            cool.ID = i;
            cool.scrollFactor.set(1, 1);
            cool.x = APPlatState.instance.boyfriend.x + (APPlatState.instance.boyfriend.width / 2) - ((Note.swagWidth * randArray.length) / 2);
            cool.x += Note.swagWidth * i;
            cool.y = APPlatState.instance.boyfriend.y - Note.swagWidth - 5;
            APPlatState.instance.add(cool);
            grpNotes[i] = cool;
        }

        var tag = 'ajgnaidngkjsfohijaoihjpdafgnadjoiashmfmhiobad';

        daCoolTween = FlxTween.num(6.1, 0, 2, { ease: FlxEase.expoOut}, function(num) {
            for (j in grpNotes) {
                j.x = APPlatState.instance.boyfriend.x + (APPlatState.instance.boyfriend.width / 2) - ((Note.swagWidth * randArray.length) / 2);
                j.x += Note.swagWidth * j.ID;
                j.y = APPlatState.instance.boyfriend.y - Note.swagWidth - 5;
                j.x += FlxG.random.float(-num, num);
                j.y += FlxG.random.float(-num, num);
                j.angle = FlxG.random.float(-num / 2, num / 2);
            }
        });

        for (j in 0...grpNotes.length) {
            var strum = grpNotes[j];
            strum.playAnim('confirm', true);
            strum.animation.finishCallback = function() {
                if (APPlatState.instance.isPixelStage) strum.playAnim(colArray[strum.noteData]);
                else strum.playAnim('color', true);
            }
        }

        position = -1;
        didcoolthing = false
        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    var position = -1;
    var didcoolthing:Bool = false;
    function onKeyPress(k) {
        if (APPlatState.instance.health > 0.05) {
            if (randArray != null && randArray.length > 0) {
                if (k == randArray[1]) {
                    position = position + 1
                    var strum = grpNotes[position];
                    strum.playAnim('pressed', true);
                    strum.resetAnim = 0.15;
                    table.remove(randArray, 1)
                    if (randArray.length < 1 && !didcoolthing) {
                        if (daCoolTween != null) daCoolTween.cancel();
                        for (j in grpNotes) {
                            j.acceleration.y = FlxG.random.float(300, 600);
                            j.velocity.y = FlxG.random.float(-200, -300);
                            j.velocity.x = FlxG.random.float(-10, 10);
                            j.angularVelocity = FlxG.random.float(-15, 15);
                            FlxTween.tween(j, { alpha: 0 }, 0.2 / game.playbackRate, {
                                onComplete: function(tween:FlxTween)
                                {
                                    j.kill();
                                    game.remove(j);
                                },
                                startDelay: Conductor.crochet * 0.002 / game.playbackRate
                            });
                        }
                        APPlatState.instance.playerStrums.forEach(function(str) { str.alpha = 1; });
                        APPlatState.instance.isCameraOnForcedPos = false;
                        APPlatState.instance.moveCameraSection();
                        FlxG.sound.play(Paths.sound('bf_vine_defeat'));
                        APPlatState.instance.boyfriend.stunned = true;
                        if (APPlatState.instance.health > 0.1)
                            APPlatState.instance.boyfriend.playAnim('dodge', true);

                        didcoolthing = true
                        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
                    }
                }
                else {
                    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
                    doBushwakThings();
                }
            }
        }
    }

    public static function startUnown(?timer:Int = 15, ?word:String = 'pain'):Void {
		APPlatState.instance.canPause = false;
		APPlatState.instance.persistentUpdate = true;
		APPlatState.instance.persistentDraw = true;
        APPlatState.instance.boyfriend.stunned = true;
		var realTimer = timer;
		var unownState = new UnownSubState(realTimer, word);
		unownState.win = wonUnown;
		unownState.lose = APPlayState.instance.die;
		unownState.cameras = [APPlatState.instance.camHUD];
		FlxG.autoPause = false;
		openSubState(unownState);
	}

    function wonUnown():Void {
		APPlatState.instance.canPause = true;
		APPlatState.instance.boyfriend.stunned = false;
	}
}