package backend;

import backend.window.CppAPI;
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
    // public static var states:Dynamic = {
    //     WelcomeToPain: states.WelcomeToPain,
    // };
    public static var timers:Dynamic = {
        transition: new FlxTimer(),
    };
    public static var requiredTransition:Dynamic;

    static function switchState(targetState:Class<FlxState>, ?onComplete:Dynamic, ?stateArgs:Array<Dynamic> = null):Void {
        
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
        }
        else {
            postSwitchTransition(currenttransition.options);
        }
        if (!Reflect.isFunction(onComplete) && onComplete != null) {
            trace("onComplete is not a function: " + onComplete);
        }
        trace("Switched to state: " + Type.getClassName(targetState));
        currenttransition = null;
        trace("Switch complete.");
        isTransitioning = false;
        if (targetState == null) {
            trace("Target state is null. Cancelling switch.");
            targetState = Type.getClass(FlxG.state);
        }
        FlxG.switchState(Type.createInstance(targetState, stateArgs != null ? stateArgs : []));
    }

    public static function transitionState(targetState:Class<FlxState>, options:Dynamic = null, ?args:Array<Dynamic>, ?required:Bool = false):Void {
        isTransitioning = true;
        if (required) {
        requiredTransition = { targetState: targetState, options: options, args: args, required: true };
    }

        if (targetState == null) {
            trace("Target state is null. Ignoring transition request.");
            return;
        }

        if (targetState == Type.getClass(FlxG.state)) {
            trace("Target state is the same as current state. Ignoring transition request.");
            return;
        }

        if (targetState == ExitState) {
            trace("Preparing to exit game...");
            requiredTransition = { targetState: targetState, options: options, args: args, required: true };
        }
    
        if (currenttransition != null) {
            trace("Transition already in progress. Ignoring new transition request.");
            return;
        }
        //trace("Transitioning to state: " + Type.getClassName(targetState));
        //trace("Options: " + options);
        currenttransition = { targetState: targetState, options: options, args: args };
        if (options == null) {
            // If options are null, select a random transition
            //trace("Random transition selected due to null options.");
            var transitions = ["fadeOut", "fadeColor", "slideLeft", "slideRight", "slideUp", "slideDown", "slideRandom", "fallRandom", "fallSequential", "stickers"];
            var random = new FlxRandom();
            options = {
                transitionType: transitions[random.int(0, transitions.length - 1)],
                duration: random.float(0.5, 2), // Random duration between 0.5 and 2 seconds
                color: random.color() // Random color for fadeColor transition
            };
            //trace("Random options: " + options);
        }
        var duration:Float = options != null && Reflect.hasField(options, "duration") ? options.duration : 1;
        var onComplete = options != null && Reflect.hasField(options, "onComplete") ? options.onComplete : null;
        var transitionType:String = options != null && Reflect.hasField(options, "transitionType") ? options.transitionType : "fadeOut";
        //trace("Transition type: " + transitionType);
        //trace("Duration: " + duration);
        //trace("On complete: " + onComplete);
        //trace("Args: " + args);
        //trace("Target state: " + Type.getClassName(targetState));
        //trace("Options: " + options);
        
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
                transitionState(targetState, { duration: duration, transitionType: randomDirection, onComplete: onComplete }, args);
                return; // Prevent further execution in this call
            case "fallRandom":
                var sprites: Array<FlxSprite> = [];
                var completedTweens = 0;
                var totalTweens = 0;
            
                // Collect valid sprites
                //trace("Collecting sprites...");
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
                //trace("Collecting sprites...");

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

            case "stickers":
                //trace("Opening sticker substate...");
                MusicBeatState.reopen = true;
                FlxG.state.openSubState(new substates.StickerSubState(null,  (sticker) -> Type.createInstance(targetState, args != null ? args : [])));
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
                    switchState(targetState, onComplete, args);
                }}, 
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
        }
        //trace("Transition complete!");
    }

    public static function postSwitchTransition(options:Dynamic = null):Void {
        //trace("Post-switch transition started.");
        if (options == null) {
            //trace("No options provided for post-switch transition.");
            return;
        }

        var duration:Float = Reflect.hasField(options, "duration") ? options.duration : 1;
        var transitionType:String = Reflect.hasField(options, "transitionType") ? options.transitionType : "fadeIn";
        //trace("Post-switch transition type: " + transitionType);
        //trace("Duration: " + duration);

        switch (transitionType) {
            case "fadeOut":
                FlxTween.tween(FlxG.camera, { alpha: 1 }, duration, {
                    onComplete: function(_) {
                        //trace("Post-switch fadeIn complete.");
                    }
                });
            case "slideLeft":
                FlxTween.tween(FlxG.camera.scroll, { x: 0 }, duration, {
                    onComplete: function(_) {
                        //trace("Post-switch slideInLeft complete.");
                    }
                });
            case "slideRight":
                FlxTween.tween(FlxG.camera.scroll, { x: 0 }, duration, {
                    onComplete: function(_) {
                        //trace("Post-switch slideInRight complete.");
                    }
                });
            case "slideUp":
                FlxTween.tween(FlxG.camera.scroll, { y: 0 }, duration, {
                    onComplete: function(_) {
                        //trace("Post-switch slideInUp complete.");
                    }
                });
            case "slideDown":
                FlxTween.tween(FlxG.camera.scroll, { y: 0 }, duration, {
                    onComplete: function(_) {
                        //trace("Post-switch slideInDown complete.");
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

    // static function slideWindow(x:Float, y:Float, duration:Float, targetState:Class<FlxState>, onComplete:Dynamic, ?args:Array<Dynamic>):Void {
    //     var screenWidth:Float = FlxG.width * FlxG.camera.zoom;
    //     var screenHeight:Float = FlxG.height * FlxG.camera.zoom;
    //     var windowWidth:Float = Lib.current.stage.stageWidth;
    //     var windowHeight:Float = Lib.current.stage.stageHeight;
    //     var targetX:Float = (windowWidth - screenWidth) / 2 + x;
    //     var targetY:Float = (windowHeight - screenHeight) / 2 + y;
        
    //     FlxTween.tween(Lib.current.stage, { x: targetX, y: targetY }, duration, {
    //         onComplete: function(_) {
    //             switchState(targetState, onComplete, args);
    //             FlxTween.tween(Lib.current.stage, { x: 0, y: 0 }, duration, {
    //                 onComplete: function(_) {
    //                     trace("Slide back complete.");
    //                 }
    //             });
    //         }
    //     });
    // }

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
                //trace("Post-switch melt complete.");
                screenCopy.dispose(); // Clean up memory for screenCopy
            }
        });
    }

    function getTargetState(state:FlxState) {
        
    }
}

// class TransitionChecker extends FlxObject {
//     public var targetState:Class<FlxState>;
//     public var options:Dynamic;
//     public var args:Array<Dynamic>;
//     public var required:Bool;

//     public function new(targetState:Class<FlxState>, options:Dynamic, ?args:Array<Dynamic>, ?required:Bool = false) {
//         super();
//         this.targetState = targetState;
//         this.options = options;
//         this.args = args;
//         this.required = required;
//     }

//     public function update(elapsed:Float):Void {
//         if (FlxG.keys.justPressed("SPACE")) {
//             TransitionState.transitionState(targetState, options, args, required);
//         }
//     }
// }