package archipelago;

import archipelago.HighQualityTrapManager;
import archipelago.substates.UnownSubState;
import flixel.input.keyboard.FlxKey;
import objects.Note;
import objects.charting.ChartingStrumNote as StrumNote;
import openfl.events.KeyboardEvent;

class TrapLinkFunctions {
    public static var bfPosition:Array<Float>;
    public static var bfMaxPos:Array<Float>;
    public static function doCarCrash(random:Bool, ?direction:Null<Int>) {
        for (i in bfPosition) {
            bfMaxPos.push(i+5000);
        }

        var curDirec:Int = 3;

        if (random || direction == null) curDirec = FlxG.random.int(0, 3);
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
    static var grpNotes:Array<StrumNote>;
    static var randArray:Array<Int>;
    public static var keysArray:Array<Array<Dynamic>>; //Specifically for this one thing
    public static function doBushwakThings(?length:Int = 4) {
        if (keysArray == null)
			keysArray = backend.Keybinds.fill();

        randArray = [for (i in 0...length) FlxG.random.int(0, 3)];

        for (i in grpNotes) { i.kill(); APPlayState.instance.remove(i); i.destroy(); }

        grpNotes = [];

        var colArray = ['purple', 'blue', 'green', 'red'];
    @:privateAccess
        for (i in 0...randArray.length) {
            var cool:StrumNote = new StrumNote(0, 0, randArray[i], 0);
            @:privateAccess
            if (!PlayState.isPixelStage) cool.animation.addByPrefix('color', colArray[cool.noteData] + '0', 24, true);
            cool.playAnim('static');
            cool.ID = i;
            cool.scrollFactor.set(1, 1);
            cool.x = APPlayState.instance.boyfriend.x + (APPlayState.instance.boyfriend.width / 2) - ((Note.swagWidth * randArray.length) / 2);
            cool.x += Note.swagWidth * i;
            cool.y = APPlayState.instance.boyfriend.y - Note.swagWidth - 5;
            APPlayState.instance.add(cool);
            grpNotes[i] = cool;
        }

        var tag = 'ajgnaidngkjsfohijaoihjpdafgnadjoiashmfmhiobad';

        daCoolTween = FlxTween.num(6.1, 0, 2, { ease: FlxEase.expoOut}, function(num) {
            for (j in grpNotes) {
                j.x = APPlayState.instance.boyfriend.x + (APPlayState.instance.boyfriend.width / 2) - ((Note.swagWidth * randArray.length) / 2);
                j.x += Note.swagWidth * j.ID;
                j.y = APPlayState.instance.boyfriend.y - Note.swagWidth - 5;
                j.x += FlxG.random.float(-num, num);
                j.y += FlxG.random.float(-num, num);
                j.angle = FlxG.random.float(-num / 2, num / 2);
            }
        });
        @:privateAccess
        for (j in 0...grpNotes.length) {
            var strum = grpNotes[j];
            strum.playAnim('confirm', true);
            strum.animation.finishCallback = function(animName:String) {
                @:privateAccess
                if (PlayState.isPixelStage) strum.playAnim(colArray[strum.noteData]);
                else strum.playAnim('color', true);
            }
        }

        position = -1;
        didcoolthing = false;
        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, TrapLinkFunctions.onKeyPress);
    }

    public static function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
			for (i in 0...keysArray[3].length)
				for (j in 0...keysArray[3][i].length)
					if (key == keysArray[3][i][j])
						return i;
		return -1;
	}

    static var position = -1;
    static var didcoolthing:Bool = false;
    static function onKeyPress(k:KeyboardEvent) {
        var eventKey:FlxKey = k.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
        if (APPlayState.instance.health > 0.05) {
            if (randArray != null && randArray.length > 0) {
                if (key == randArray[0]) {
                    position = position + 1;
                    var strum = grpNotes[position];
                    strum.playAnim('pressed', true);
                    strum.resetAnim = 0.15;
                    randArray.remove(randArray[0]);
                    if (randArray.length < 1 && !didcoolthing) {
                        if (daCoolTween != null) daCoolTween.cancel();
                        for (j in grpNotes) {
                            j.acceleration.y = FlxG.random.float(300, 600);
                            j.velocity.y = FlxG.random.float(-200, -300);
                            j.velocity.x = FlxG.random.float(-10, 10);
                            j.angularVelocity = FlxG.random.float(-15, 15);
                            FlxTween.tween(j, { alpha: 0 }, 0.2 / APPlayState.instance.playbackRate, {
                                onComplete: function(tween:FlxTween)
                                {
                                    j.kill();
                                    APPlayState.instance.remove(j);
                                },
                                startDelay: Conductor.crochet * 0.002 / APPlayState.instance.playbackRate
                            });
                        }
                        APPlayState.instance.playerStrums.forEach(function(str) { str.alpha = 1; });
                        APPlayState.instance.isCameraOnForcedPos = false;
                        APPlayState.instance.moveCameraSection();
                        FlxG.sound.play(Paths.sound('bf_vine_defeat'));
                        APPlayState.instance.boyfriend.stunned = true;
                        if (APPlayState.instance.health > 0.1)
                            APPlayState.instance.boyfriend.playAnim('dodge', true);

                        didcoolthing = true;
                        removeListener();
                    }
                }
                else {
                    removeListener();
                    doBushwakThings();
                }
            }
        }
    }

    static function removeListener() {
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    public static function startUnown(?timer:Int = 15, ?word:String = 'pain'):Void {
		APPlayState.instance.canPause = false;
		APPlayState.instance.persistentUpdate = true;
		APPlayState.instance.persistentDraw = true;
        APPlayState.instance.boyfriend.stunned = true;
		var realTimer = timer;
		var unownState = new UnownSubState(realTimer, word);
		unownState.win = wonUnown;
		unownState.lose = APPlayState.instance.die;
		unownState.cameras = [APPlayState.instance.camHUD];
		FlxG.autoPause = false;
		FlxG.state.openSubState(unownState);
	}

    static function wonUnown():Void {
		APPlayState.instance.canPause = true;
		APPlayState.instance.boyfriend.stunned = false;
	}

	/**
	 * High Quality Trap - activates SiivaGunner replacements for songs
	 */
	public static function doHighQualityTrap():Void {
		trace("TrapLinkFunctions: Activating High Quality Trap!");

		// Activate the trap manager
		HighQualityTrapManager.activateTrap();

		// Check if we need to show waiting state for mod installation
		if (HighQualityTrapManager.needsWaitingState()) {
			trace("TrapLinkFunctions: High Quality Trap needs mod installation, switching to waiting state");

			// Get AP context from APInfo
			if (APInfo.apGame != null && APInfo.ap != null) {
				flixel.FlxG.switchState(new archipelago.states.HighQualityWaitingState(APInfo.apGame, APInfo.ap));
			} else {
				// Fallback: use the non-AP waiting state if not in AP context
				flixel.FlxG.switchState(new states.HighQualityTrapWaitingState());
			}
			return;
		}

		// Show a notification to the player if mod is already installed
		if (APPlayState.instance != null) {
			// Create a temporary text notification
			var notificationText = new flixel.text.FlxText(0, 50, flixel.FlxG.width, "HIGH QUALITY MUSIC ACTIVATED!", 32);
			notificationText.setFormat(backend.Paths.font("vcr.ttf"), 32, flixel.util.FlxColor.YELLOW, flixel.text.FlxTextAlign.CENTER, flixel.text.FlxTextBorderStyle.OUTLINE, flixel.util.FlxColor.BLACK);
			notificationText.borderSize = 2;
			notificationText.cameras = [APPlayState.instance.camHUD];
			APPlayState.instance.add(notificationText);

			// Tween the notification
			notificationText.alpha = 0;
			flixel.tweens.FlxTween.tween(notificationText, {alpha: 1}, 0.5, {
				ease: flixel.tweens.FlxEase.backOut,
				onComplete: function(_) {
					new flixel.util.FlxTimer().start(2.0, function(_) {
						flixel.tweens.FlxTween.tween(notificationText, {alpha: 0, y: notificationText.y - 50}, 0.5, {
							ease: flixel.tweens.FlxEase.backIn,
							onComplete: function(_) {
								notificationText.destroy();
							}
						});
					});
				}
			});

			// Play a sound effect
			flixel.FlxG.sound.play(backend.Paths.sound('confirmMenu'), 0.7);
		}

		trace("TrapLinkFunctions: High Quality Trap activated successfully!");
	}
}
