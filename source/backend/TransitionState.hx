package backend;

import utils.window.CppAPI;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxRandom;
import flixel.state.*;
import substates.StickerSubState;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.Lib;

class TransitionState {
    public static var stickers:FlxTypedGroup<StickerSprite>;
    public static var currenttransition:Dynamic;
    public static var isTransitioning:Bool = false;
    public static var timers:Dynamic = {
        transition: new FlxTimer(),
    };
    public static var requiredTransition:Dynamic;

    static function switchState(targetState:Class<FlxState>, ?onComplete:Dynamic, ?stateArgs:Array<Dynamic> = null):Void {
        isTransitioning = false;
        timers.transition.start(5, function(timer:FlxTimer) {
            if (currenttransition != null) {
                trace("Transition timer expired. Resetting current transition.");
                currenttransition = null;
            }
            if (requiredTransition != null) {
                trace("Waiting transition is needed...");
                var newTransitoon = requiredTransition;
                requiredTransition = null;
                transitionState(newTransitoon.targetState, newTransitoon.options, newTransitoon.args, true);
            }
        }, 1);
        if (onComplete != null && Reflect.isFunction(onComplete)) {
            onComplete();
        } else {
            postSwitchTransition(currenttransition.options);
        }
        if (!Reflect.isFunction(onComplete) && onComplete != null) {
            trace("onComplete is not a function: " + onComplete);
        }
        trace("Switched to state: " + Type.getClassName(targetState));
        currenttransition = null;
        FlxG.switchState(Type.createInstance(targetState, stateArgs != null ? stateArgs : []));
    }

    public static function transitionState(targetState:Class<FlxState>, options:Dynamic = null, ?args:Array<Dynamic>, ?required:Bool = false):Void {
        if (required) {
            requiredTransition = { targetState: targetState, options: options, args: args };
        }
    
        if (currenttransition != null) {
            trace("Transition already in progress. Ignoring new transition request.");
            var checkTimer = new FlxTimer();
            checkTimer.start(10, function(timer:FlxTimer) {
                if (currenttransition != null) {
                    trace("Error: Transition still in progress after 10 seconds. Resetting current transition.");
                    var newTransition = requiredTransition != null ? requiredTransition : currenttransition;
                    requiredTransition = null;
                    currenttransition = null;
                    transitionState(newTransition.targetState, newTransition.options, newTransition.args, true);
                } else {
                    trace("Transition completed. Proceeding with new transition.");
                    transitionState(requiredTransition == null ? targetState : requiredTransition.targetState, requiredTransition == null ? options : requiredTransition.options, requiredTransition == null ? args : requiredTransition.args, requiredTransition != null);
                }
            }, 1);
            return;
        }
        isTransitioning = true;
        currenttransition = { targetState: targetState, options: options, args: args };
        if (options == null) {
            var transitions = ["fadeOut", "fadeColor", "slideLeft", "slideRight", "slideUp", "slideDown", "slideRandom", "fallRandom", "fallSequential", "stickers"];
            var random = new FlxRandom();
            options = {
                transitionType: transitions[random.int(0, transitions.length - 1)],
                duration: random.float(0.5, 2), // Random duration between 0.5 and 2 seconds
                color: random.color() // Random color for fadeColor transition
            };
        }
        var duration:Float = options != null && Reflect.hasField(options, "duration") ? options.duration : 1;
        var onComplete = options != null && Reflect.hasField(options, "onComplete") ? options.onComplete : null;
        var transitionType:String = options != null && Reflect.hasField(options, "transitionType") ? options.transitionType : "fadeOut";
        
        switch (transitionType) {
            case "fadeOut":
                FlxTween.tween(FlxG.camera, { alpha: 0 }, duration, {
                    onComplete: function(_) {
                        switchState(targetState, onComplete, args);
                    }
                });
            case "fadeColor":
                var color:Int = options != null && Reflect.hasField(options, "color") ? options.color : FlxColor.BLACK;
                FlxG.camera.fade(color, duration, true, function():Void {
                    switchState(targetState, onComplete, args);
                });
            case "slideLeft":
                slideScreen(-FlxG.width, 0, duration, targetState, onComplete, args);
            case "slideRight":
                slideScreen(FlxG.width, 0, duration, targetState, onComplete, args);
            case "slideUp":
                slideScreen(0, -FlxG.height, duration, targetState, onComplete, args);
            case "slideDown":
                slideScreen(0, FlxG.height, duration, targetState, onComplete, args);
            case "slideRandom":
                var directions = ["slideLeft", "slideRight", "slideUp", "slideDown"];
                var randomDirection = new FlxRandom().shuffleArray(directions, 1)[0];
                currenttransition = null;
                transitionState(targetState, { duration: duration, transitionType: randomDirection, onComplete: onComplete }, args);
                return; // Prevent further execution in this call
                case "stickers":
                    //trace("Opening sticker substate...");
                    MusicBeatState.reopen = true;
                    FlxG.state.openSubState(new substates.StickerSubState(null,  (sticker) -> Type.createInstance(targetState, args != null ? args : [])));
            case "fallRandom":
                var sprites: Array<FlxSprite> = [];
                var completedTweens = 0;
                var totalTweens = 0;
            
                // Collect valid sprites
                for (object in FlxG.state.members) {
                    if (object != null && Std.is(object, FlxSprite)) {
                        sprites.push(cast(object));
                    }
                }
                totalTweens = sprites.length;
            
                // Function to check if all tweens are complete
                var checkAllComplete = function() {
                    if (completedTweens >= totalTweens) {
                        switchState(targetState, onComplete, args);
                    }
                };
            
                // Apply a tween to each sprite with a random delay
                for (sprite in sprites) {
                    var delay = FlxG.random.float(0, 1); // Adjust max delay as needed
                    var direction = FlxG.random.float(-1, 1);
                    var timer = new FlxTimer();
                    timer.start(delay, function(timer:FlxTimer) {
                        FlxTween.tween(sprite, { y: FlxG.height + sprite.height, x: sprite.x + direction * FlxG.random.float(100, 200) }, duration, {
                            onComplete: function(_) {
                                sprite.exists = false;
                                completedTweens++;
                                checkAllComplete();
                            }
                        });
                    }, 1);
                }
            
                // In case there are no sprites, directly switch state
                if (totalTweens == 0) {
                    switchState(targetState, onComplete, args);
                }
            
            case "fallSequential":
                var randomDirection:Bool = true; // Ensure this is defined appropriately
                var delayIncrement = 0.0;
                var objectsToTween: Array<FlxSprite> = [];
                
                // Collect valid objects first
                for (object in FlxG.state.members) {
                    if (object != null && Std.is(object, FlxSprite)) {
                        objectsToTween.push(cast(object));
                    }
                }
                
                // Function to process each object with a delay
                var processNextObject: Void->Void = null;
                processNextObject = function() {
                    if (objectsToTween.length > 0) {
                        var sprite = objectsToTween.shift();
                        var direction = randomDirection ? FlxG.random.float(-1, 1) : 0;
                        FlxTween.tween(sprite, { y: FlxG.height + sprite.height, x: sprite.x + direction * FlxG.random.float(100, 200) }, duration, {
                            onComplete: function(_) {
                                sprite.exists = false;
                                new FlxTimer().start(0.1, function(timer:FlxTimer) { processNextObject(); }, 1);
                            }
                        });
                    } else {
                        // All objects processed, switch state
                        switchState(targetState, onComplete, args);
                    }
                };
                
                // Start processing with the first object
                processNextObject();

            case "melt":
                var screenCopy = new BitmapData(FlxG.width, FlxG.height);
                screenCopy.draw(FlxG.camera.buffer);
                switchState(targetState, onComplete, args);
                meltEffect(screenCopy, options);
            case "instant":
                switchState(targetState, onComplete, args);
            case 'transparent fade':
                FlxTween.num(1, 0, 2, {ease: FlxEase.sineInOut, onComplete: 
                function(twn:FlxTween)
                {
                    switchState(targetState, onComplete, args);
                }}, 
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
            case 'transparent close':
                var exitSound:FlxSound;
                exitSound = new FlxSound().loadEmbedded(Paths.music('gameOverEnd'));
                if (FlxG.sound.music != null && FlxG.sound.music.playing)
                {
                    FlxG.sound.music.stop();
                    exitSound.play();
                }
                else
                {
                    exitSound.play();
                }
                if (ClientPrefs.data.flashing) FlxG.camera.flash(FlxColor.WHITE, (exitSound.length*0.0005));
                FlxTween.num(1, 0, (exitSound.length*0.0005), {ease: FlxEase.sineInOut, onComplete: 
                function(twn:FlxTween)
                {
                    switchState(targetState, onComplete, args);
                }}, 
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
        }
    }

    public static function postSwitchTransition(options:Dynamic = null):Void {
        if (options == null) {
            return;
        }

        var duration:Float = Reflect.hasField(options, "duration") ? options.duration : 1;
        var transitionType:String = Reflect.hasField(options, "transitionType") ? options.transitionType : "fadeIn";

        switch (transitionType) {
            case "fadeOut":
                FlxTween.tween(FlxG.camera, { alpha: 1 }, duration, {
                    onComplete: function(_) {
                    }
                });
            case "slideLeft":
                FlxTween.tween(FlxG.camera.scroll, { x: 0 }, duration, {
                    onComplete: function(_) {
                    }
                });
            case "slideRight":
                FlxTween.tween(FlxG.camera.scroll, { x: 0 }, duration, {
                    onComplete: function(_) {
                    }
                });
            case "slideUp":
                FlxTween.tween(FlxG.camera.scroll, { y: 0 }, duration, {
                    onComplete: function(_) {
                    }
                });
            case "slideDown":
                FlxTween.tween(FlxG.camera.scroll, { y: 0 }, duration, {
                    onComplete: function(_) {
                    }
                });
            case "transparent fade":
				CppAPI.setWindowOppacity(1);
				trace("Post-switch transparent fade complete.");
            default:
                trace("Unknown post-switch transition type: " + transitionType);
        }
    }

    static function slideScreen(x:Float, y:Float, duration:Float, targetState:Class<FlxState>, onComplete:Dynamic, ?args:Array<Dynamic>):Void {
        FlxTween.tween(FlxG.camera.scroll, { x: x, y: y }, duration, {
            onComplete: function(_) {
                switchState(targetState, onComplete, args);
            }
        });
    }

    static function meltEffect(screenCopy:BitmapData, ?options:Dynamic):Void {
        var pixels = screenCopy;
        var duration:Float = Reflect.hasField(options, "duration") ? options.duration : FlxG.random.float(1, 3);
        FlxTween.num(0, FlxG.height, duration, {
            onUpdate: function(tween:FlxTween) {
                var value = tween.percent;
                for (y in 0...FlxG.height) {
                    for (x in 0...FlxG.width) {
                        var pixel = pixels.getPixel32(x, y);
                        if (pixel != FlxColor.TRANSPARENT) {
                            var newY = y + Std.int(Math.random() * value);
                            if (newY < FlxG.height) {
                                screenCopy.setPixel(x, newY, pixel);
                                screenCopy.setPixel(x, y, FlxColor.TRANSPARENT);
                            }
                        }
                    }
                }
                FlxG.camera.buffer.draw(screenCopy);
            },
            onComplete: function(tween:FlxTween) {
                screenCopy.dispose(); // Clean up memory for screenCopy
            }
        });
    }

    public static function fakeTransition(options:Dynamic = null):Void {
        var duration:Float = options != null && Reflect.hasField(options, "duration") ? options.duration : 1;
        var transitionType:String = options != null && Reflect.hasField(options, "transitionType") ? options.transitionType : "fadeOut";
        var originalSprites:Array<{sprite:FlxSprite, x:Float, y:Float, alpha:Float}> = [];

        // Store original state of sprites
        for (object in FlxG.state.members) {
            if (object != null && Std.is(object, FlxSprite)) {
                var sprite = cast(object, FlxSprite);
                originalSprites.push({sprite: sprite, x: sprite.x, y: sprite.y, alpha: sprite.alpha});
            }
        }

        var restoreSprites = function() {
            for (original in originalSprites) {
                original.sprite.x = original.x;
                original.sprite.y = original.y;
                original.sprite.alpha = original.alpha;
                if (!FlxG.state.members.contains(original.sprite)) {
                    FlxG.state.add(original.sprite);
                }
            }
        };

        switch (transitionType) {
            case "fadeOut":
                FlxTween.tween(FlxG.camera, { alpha: 0 }, duration, {
                    onComplete: function(_) {
                        FlxTween.tween(FlxG.camera, { alpha: 1 }, duration, {
                            onComplete: function(_) {
                                restoreSprites();
                            }
                        });
                    }
                });
            case "fadeColor":
                var color:Int = options != null && Reflect.hasField(options, "color") ? options.color : FlxColor.BLACK;
                FlxG.camera.fade(color, duration, true, function():Void {
                    FlxG.camera.fade(FlxColor.TRANSPARENT, duration, true, function():Void {
                        restoreSprites();
                    });
                });
            case "slideLeft":
                slideScreen(-FlxG.width, 0, duration, null, function() {
                    slideScreen(0, 0, duration, null, function() {
                        restoreSprites();
                    });
                });
            case "slideRight":
                slideScreen(FlxG.width, 0, duration, null, function() {
                    slideScreen(0, 0, duration, null, function() {
                        restoreSprites();
                    });
                });
            case "slideUp":
                slideScreen(0, -FlxG.height, duration, null, function() {
                    slideScreen(0, 0, duration, null, function() {
                        restoreSprites();
                    });
                });
            case "slideDown":
                slideScreen(0, FlxG.height, duration, null, function() {
                    slideScreen(0, 0, duration, null, function() {
                        restoreSprites();
                    });
                });
            case "fallRandom":
                var sprites: Array<FlxSprite> = [];
                var completedTweens = 0;
                var totalTweens = 0;
            
                // Collect valid sprites
                for (object in FlxG.state.members) {
                    if (object != null && Std.is(object, FlxSprite)) {
                        sprites.push(cast(object));
                    }
                }
                totalTweens = sprites.length;
            
                // Function to check if all tweens are complete
                var checkAllComplete = function() {
                    if (completedTweens >= totalTweens) {
                        restoreSprites();
                    }
                };
            
                // Apply a tween to each sprite with a random delay
                for (sprite in sprites) {
                    var delay = FlxG.random.float(0, 1); // Adjust max delay as needed
                    var direction = FlxG.random.float(-1, 1);
                    var timer = new FlxTimer();
                    timer.start(delay, function(timer:FlxTimer) {
                        FlxTween.tween(sprite, { y: FlxG.height + sprite.height, x: sprite.x + direction * FlxG.random.float(100, 200) }, duration, {
                            onComplete: function(_) {
                                sprite.exists = false;
                                completedTweens++;
                                checkAllComplete();
                            }
                        });
                    }, 1);
                }
            
                // In case there are no sprites, directly restore state
                if (totalTweens == 0) {
                    restoreSprites();
                }
            
            case "fallSequential":
                var randomDirection:Bool = true; // Ensure this is defined appropriately
                var delayIncrement = 0.0;
                var objectsToTween: Array<FlxSprite> = [];
                
                // Collect valid objects first
                for (object in FlxG.state.members) {
                    if (object != null && Std.is(object, FlxSprite)) {
                        objectsToTween.push(cast(object));
                    }
                }
                
                // Function to process each object with a delay
                var processNextObject: Void->Void = null;
                processNextObject = function() {
                    if (objectsToTween.length > 0) {
                        var sprite = objectsToTween.shift();
                        var direction = randomDirection ? FlxG.random.float(-1, 1) : 0;
                        FlxTween.tween(sprite, { y: FlxG.height + sprite.height, x: sprite.x + direction * FlxG.random.float(100, 200) }, duration, {
                            onComplete: function(_) {
                                sprite.exists = false;
                                new FlxTimer().start(0.1, function(timer:FlxTimer) { processNextObject(); }, 1);
                            }
                        });
                    } else {
                        // All objects processed, restore state
                        restoreSprites();
                    }
                };
                
                // Start processing with the first object
                processNextObject();
            case 'transparent fade':
                FlxTween.num(1, 0, 2, {ease: FlxEase.sineInOut, onComplete: 
                function(twn:FlxTween)
                {
                    restoreSprites();
                    CppAPI.setWindowOppacity(1);
                }}, 
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
            case 'transparent close':
                if (FlxG.sound.music != null && FlxG.sound.music.playing)
                {
                    FlxG.sound.music.stop();
                    FlxG.sound.play(Paths.music('gameOverEnd'));
                }
                else
                {
                    FlxG.sound.play(Paths.music('gameOverEnd'));
                }
                if (ClientPrefs.data.flashing) FlxG.camera.flash(FlxColor.WHITE, 2);
                FlxTween.num(1, 0, 2, {ease: FlxEase.sineInOut, onComplete: 
                function(twn:FlxTween)
                {
                    restoreSprites();
                    CppAPI.setWindowOppacity(1);
                }}, 
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
        }
    }

    function getTargetState(state:FlxState) {
        
    }
}