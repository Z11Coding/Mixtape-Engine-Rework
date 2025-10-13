package backend;

import archipelago.ArchPopup;
import backend.window.CppAPI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxRandom;
import flixel.state.*;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import substates.StickerSubState;

abstract TransitionableState(Dynamic) from FlxState to FlxState {
    public inline function new(?state:Dynamic) {
        if (state == null) {
            this = new FlxState();
        } else if (Std.is(state, FlxState)) {
            // Already an instance, use as-is (preserves arguments)
            this = cast(state, FlxState);
        } else if (Std.is(state, Class)) {
            // Store the class to be created later
            this = state;
        } else {
            this = new FlxState();
        }
    }

    // Implicit conversion from Class<FlxState>
    @:from
    public static inline function fromClass(stateClass:Class<FlxState>):TransitionableState {
        return cast stateClass;
    }

    // Helper method to create instance with arguments
    public static inline function create(state:Dynamic, ?args:Array<Dynamic>):FlxState {
        if (state == null) {
            return new FlxState();
        } else if (Std.is(state, FlxState)) {
            // Already an instance, return as-is (preserves arguments)
            return cast(state, FlxState);
        } else if (Std.is(state, Class)) {
            // Create new instance from class with arguments
            return Type.createInstance(cast(state, Class<Dynamic>), args != null ? args : []);
        } else {
            return new FlxState();
        }
    }

    // Get the underlying FlxState instance
    public inline function getInstance(?args:Array<Dynamic>):FlxState {
        return create(this, args);
    }
}

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

    static function switchState(targetState:TransitionableState, ?onComplete:Dynamic, ?stateArgs:Array<Dynamic> = null):Void {

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
        trace("Switched to state: " + Type.getClassName(Type.getClass(targetState)));
        currenttransition = null;
        trace("Switch complete.");
        isTransitioning = false;
        if (targetState == null) {
            trace("Target state is null. Cancelling switch.");
            targetState = Type.getClass(FlxG.state);
        }
        var stateInstance:FlxState = TransitionableState.create(targetState, stateArgs);
        FlxG.switchState(stateInstance);
    }

    public static function transitionState(targetState:TransitionableState, options:Dynamic = null, ?args:Array<Dynamic>, ?required:Bool = false):Void {
        isTransitioning = true;
        if (required)
            requiredTransition = { targetState: targetState, options: options, args: args, required: true };

        if (targetState == null) {
            trace("Target state is null. Ignoring transition request.");
            return;
        }

        // Get the class to compare
        var targetClass:Class<FlxState> = null;
        var targetStateRaw:Dynamic = cast targetState; // Get the underlying value
        if (Std.is(targetStateRaw, Class)) {
            targetClass = cast targetStateRaw;
        } else if (Std.is(targetStateRaw, FlxState)) {
            targetClass = Type.getClass(cast(targetStateRaw, FlxState));
        }

        // Check for exit state conditions - if ExitState is somehow null, emergency exit
        if (targetClass == states.ExitState && states.ExitState == null)
        {
            trace("Exit state was null! (somehow)\nTriggering Emergency Exit!");
            Main.closeGame();
        }

        if (targetClass == Type.getClass(FlxG.state)) {
            trace("Target state is the same as current state. Ignoring transition request.");
            return;
        }

        if (targetClass == states.ExitState) {
            trace("Preparing to exit game...");
            // Try to switch to ExitState first
            requiredTransition = { targetState: targetState, options: options, args: args, required: true };
            // After 3 seconds, if still not in ExitState, force close the game
            new FlxTimer().start(3, function(timer:FlxTimer) {
                if (Type.getClass(FlxG.state) != states.ExitState) {
                    trace("GAME IS STILL OPEN and not in ExitState! FORCE CLOSING!");
            new FlxTimer().start(3, function(timer:FlxTimer) {
                if (Type.getClass(FlxG.state) != states.ExitState) {
                    trace("GAME IS STILL OPEN! FORCE CLOSING!");
                    Main.closeGame();
                }
            });
                    FlxG.switchState(new states.ExitState());

                }
            });

        }

        if (currenttransition != null) {
            trace("Transition already in progress. Ignoring new transition request.");
            timers.transition.start(5, function(timer:FlxTimer) {
                if (currenttransition != null) {
                    trace("Transition timer expired. Resetting current transition.");
                    currenttransition = null;
                }
                if (Type.getClass(FlxG.state) != targetState) {
                    trace("Waiting transition is needed...");
                    var newTransitoon = currenttransition;
                    currenttransition = null;
                    requiredTransition = null;
                    transitionState(newTransitoon.targetState, newTransitoon.options, newTransitoon.args, true);
                    }});
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
                FlxG.state.openSubState(new substates.StickerSubState(null, (sticker) -> TransitionableState.create(targetState, args)));
            case "melt":
                // Take a proper screenshot of the current state
                var screenCopy = new BitmapData(FlxG.width, FlxG.height, false, FlxColor.BLACK);
                screenCopy.draw(FlxG.camera.buffer);

                // Create a sprite to display the melting effect
                var meltSprite = new FlxSprite(0, 0);
                meltSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
                meltSprite.pixels.copyPixels(screenCopy, new openfl.geom.Rectangle(0, 0, FlxG.width, FlxG.height), new openfl.geom.Point(0, 0));
                meltSprite.scrollFactor.set(0, 0);
                FlxG.state.add(meltSprite);

                // Start the melt effect
                meltEffect(meltSprite, screenCopy, duration, function() {
                    switchState(targetState, onComplete, args);
                });
            case "instant":
                switchState(targetState, onComplete, args);
            case 'transparent fade':
                #if windows
                MusicBeatState.emergencyOpacityFix = true;
                FlxTween.num(1, 0, 2, {ease: FlxEase.sineInOut, onComplete:
                function(twn:FlxTween)
                {
                    switchState(targetState, onComplete, args);
                }},
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
                #end
            case 'transparent close':
                if (FlxG.sound.music != null && FlxG.sound.music.playing)
                {
                    if (MusicBeatState.getState() == PlayState.instance)
                        PlayState.instance.paused = true;
                    else
                        FlxG.sound.music.stop();
                    FlxG.sound.play(Paths.music('gameOverEnd'));
                }
                else
                {
                    FlxG.sound.play(Paths.music('gameOverEnd'));
                }
                MusicBeatState.emergencyOpacityFix = true;
                if (ClientPrefs.data.flashing) FlxG.camera.flash(FlxColor.WHITE, 2);
                #if windows
                FlxTween.num(1, 0, 2, {ease: FlxEase.sineInOut, onComplete:
                function(twn:FlxTween)
                {
                    switchState(targetState, onComplete, args);
                }},
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
                #end
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
				#if windows CppAPI.setWindowOppacity(1); #end
				trace("Post-switch transparent fade complete.");
            default:
                trace("Unknown post-switch transition type: " + transitionType);
        }
    }

    static function slideScreen(x:Float, y:Float, duration:Float, targetState:TransitionableState, onComplete:Dynamic, ?args:Array<Dynamic>):Void {
        FlxTween.tween(FlxG.camera.scroll, { x: x, y: y }, duration, {
            onComplete: function(_) {
                switchState(targetState, onComplete, args);
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
                        MusicBeatState.resetState();
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
                    MusicBeatState.resetState();
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
                        MusicBeatState.resetState();
                    }
                };

                // Start processing with the first object
                processNextObject();
            case 'transparent fade':
                MusicBeatState.emergencyOpacityFix = true;
                #if windows
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
                #end
            case 'transparent close':
                var psPause = states.PlayState.instance?.paused;
                if (FlxG.sound.music != null && FlxG.sound.music.playing)
                {
                    try {
                        if (!states.PlayState.instance?.paused) {
                            FlxG.sound.music.pause();
                            states.PlayState.instance.paused = true;
                        }
                    } catch (e:Dynamic) {
                        trace("Error while pausing music or setting paused state: " + e);
                    }
                    FlxG.sound.play(Paths.music('gameOverEnd'));
                }
                else
                {
                    FlxG.sound.play(Paths.music('gameOverEnd'));
                }
                MusicBeatState.emergencyOpacityFix = true;
                if (ClientPrefs.data.flashing) FlxG.camera.flash(FlxColor.WHITE, 2);
                #if windows
                FlxTween.num(1, 0, 2, {ease: FlxEase.sineInOut, onComplete:
                function(twn:FlxTween)
                {
                    restoreSprites();
                    CppAPI.setWindowOppacity(1);
                    FlxG.sound.resume();
                    try {
                        if (!psPause) cast(states.PlayState.instance, archipelago.APPlayState).paused = false;
                        cast(states.PlayState.instance, archipelago.APPlayState).forceResync();
                    } catch (_) {}
                    ArchPopup.startPopupCustom('APItem: Fake Transition', "Gotcha!", "ArchWhite");
                }},
                function(num)
                {
                    CppAPI.setWindowOppacity(num);
                });
                #end
        }
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

    static function meltEffect(meltSprite:FlxSprite, originalPixels:BitmapData, duration:Float, onComplete:Void->Void):Void {
        var pixelColumns:Array<Array<{x:Int, y:Int, color:Int, fallSpeed:Float}>> = [];

        // Initialize pixel columns
        for (x in 0...FlxG.width) {
            pixelColumns[x] = [];
        }

        // Scan the original image and create falling pixel data
        for (y in 0...FlxG.height) {
            for (x in 0...FlxG.width) {
                var pixel = originalPixels.getPixel32(x, y);
                if ((pixel & 0xFF000000) != 0) { // Check if pixel is not transparent
                    pixelColumns[x].push({
                        x: x,
                        y: y,
                        color: pixel,
                        fallSpeed: FlxG.random.float(50, 200) // Random fall speed for each pixel
                    });
                }
            }
        }

        var meltProgress:Float = 0;
        var meltDuration:Float = duration > 0 ? duration : 2.0;

        // Create the melting animation
        FlxTween.num(0, 1, meltDuration, {
            ease: FlxEase.quadIn,
            onUpdate: function(tween:FlxTween) {
                meltProgress = tween.percent;

                // Clear the sprite
                meltSprite.pixels.fillRect(new openfl.geom.Rectangle(0, 0, FlxG.width, FlxG.height), FlxColor.TRANSPARENT);

                // Draw melting pixels
                for (x in 0...pixelColumns.length) {
                    var column = pixelColumns[x];
                    for (i in 0...column.length) {
                        var pixelData = column[i];
                        var fallDistance = pixelData.fallSpeed * meltProgress;
                        var newY = pixelData.y + Std.int(fallDistance);

                        // Only draw pixels that haven't fallen off screen
                        if (newY < FlxG.height) {
                            meltSprite.pixels.setPixel32(pixelData.x, newY, pixelData.color);
                        }
                    }
                }

                // Apply the changes to the sprite
                meltSprite.dirty = true;
                meltSprite.pixels = meltSprite.pixels;
            },
            onComplete: function(tween:FlxTween) {
                // Clean up
                meltSprite.destroy();
                originalPixels.dispose();

                // Call completion callback
                if (onComplete != null) {
                    onComplete();
                }
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
