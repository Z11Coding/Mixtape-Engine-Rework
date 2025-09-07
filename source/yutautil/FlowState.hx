package yutautil;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import backend.MusicBeatState;
import yutautil.FlowSpriteManager;

/**
 * FlowState - Main state manager that handles smooth transitions between BaseFlowStates
 * Acts as an intermediary state that can perform special animations and transitions
 */
class FlowState extends MusicBeatState {
    private var currentSubState:BaseFlowState;
    private var nextSubState:BaseFlowState;
    private var isTransitioning:Bool = false;
    private var transitionCallbacks:Array<Void->Void> = [];

    public static var instance:FlowState;

    public function new(initialState:BaseFlowState) {
        super();
        instance = this;
        this.currentSubState = initialState;

        // Add the initial state to this FlowState
        if (currentSubState != null) {
            add(currentSubState);
            currentSubState.onEnter(null);
        }
    }

    /**
     * Transition to a new BaseFlowState with smooth animations
     */
    public function transitionTo(newState:BaseFlowState, ?transitionCallback:Void->Void):Void {
        if (isTransitioning) return;

        isTransitioning = true;
        nextSubState = newState;

        if (transitionCallback != null) {
            transitionCallbacks.push(transitionCallback);
        }

        // Start exit animations for current state
        if (currentSubState != null) {
            currentSubState.onExit(nextSubState, function() {
                switchToNewState();
            });
        } else {
            switchToNewState();
        }
    }

    /**
     * Transition to a regular FlxState (exit the FlowState system)
     */
    public function transitionToFlxState(newState:FlxState, ?transitionCallback:Void->Void):Void {
        if (isTransitioning) return;

        isTransitioning = true;

        if (transitionCallback != null) {
            transitionCallbacks.push(transitionCallback);
        }

        if (currentSubState != null) {
            currentSubState.onExit(null, function() {
                // Execute callbacks
                for (callback in transitionCallbacks) {
                    callback();
                }
                transitionCallbacks = [];

                // Transition to new FlxState
                FlxG.camera.fade(0xFF000000, 0.5, false, function() {
                    MusicBeatState.switchState(newState);
                });
            });
        } else {
            MusicBeatState.switchState(newState);
        }
    }

    private function switchToNewState():Void {
        // Remove current state
        if (currentSubState != null) {
            remove(currentSubState);
            currentSubState.destroy();
        }

        // Add and enter new state
        currentSubState = nextSubState;
        nextSubState = null;

        if (currentSubState != null) {
            add(currentSubState);
            currentSubState.onEnter(currentSubState, function() {
                // Execute transition callbacks
                for (callback in transitionCallbacks) {
                    callback();
                }
                transitionCallbacks = [];
                isTransitioning = false;
            });
        } else {
            isTransitioning = false;
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Current state will update itself since it's added to this state
        // No need to manually call update on it
    }

    override public function destroy():Void {
        if (currentSubState != null) {
            currentSubState.destroy();
            currentSubState = null;
        }
        if (nextSubState != null) {
            nextSubState.destroy();
            nextSubState = null;
        }
        instance = null;
        super.destroy();
    }

    public function getCurrentSubState():BaseFlowState {
        return currentSubState;
    }

    public function getIsTransitioning():Bool {
        return isTransitioning;
    }
}

/**
 * BaseFlowState - Replacement for extending MusicBeatState normally
 * This is what you should extend when creating states for this game
 */
class BaseFlowState extends FlxGroup {
    private var flowSprites:Array<FlowSprite> = [];
    private var regularSprites:Array<FlxSprite> = [];

    public var isEntering:Bool = false;
    public var isExiting:Bool = false;

    public function new() {
        super();
    }

    /**
     * Called when this state is being entered
     * Override this to set up your state
     */
    public function onEnter(fromState:BaseFlowState, ?callback:Void->Void):Void {
        isEntering = true;
        isExiting = false;

        // Create your sprites and add animations here
        create();

        // Play enter animations
        if (flowSprites.length > 0) {
            playFlowSpriteAnimations(true, function() {
                isEntering = false;
                if (callback != null) callback();
            });
        } else {
            isEntering = false;
            if (callback != null) callback();
        }
    }

    /**
     * Called when this state is being exited
     * Override this to handle cleanup
     */
    public function onExit(toState:BaseFlowState, ?callback:Void->Void):Void {
        isExiting = true;
        isEntering = false;

        // Play exit animations
        var totalAnimations = flowSprites.length + regularSprites.length;
        if (totalAnimations > 0) {
            var completed = 0;

            // Handle FlowSprites with their built-in exit animations
            if (flowSprites.length > 0) {
                playFlowSpriteAnimations(false, function() {
                    completed++;
                    if (completed >= 2) { // FlowSprites + RegularSprites
                        if (callback != null) callback();
                    }
                });
            } else {
                completed++;
            }

            // Handle regular FlxSprites with custom or default exit animations
            if (regularSprites.length > 0) {
                playRegularSpriteExitAnimations(function() {
                    completed++;
                    if (completed >= 2) { // FlowSprites + RegularSprites
                        if (callback != null) callback();
                    }
                });
            } else {
                completed++;
            }

            // If we have both completed already, call callback
            if (completed >= 2 && callback != null) {
                callback();
            }
        } else {
            if (callback != null) callback();
        }
    }

    /**
     * Override this to create your sprites and set up the state
     */
    public function create():Void {
        // Override in your state implementations
    }

    /**
     * Add a FlowSprite to this state
     */
    public function addFlowSprite(sprite:FlowSprite):FlowSprite {
        flowSprites.push(sprite);
        add(sprite);
        return sprite;
    }

    /**
     * Add a regular FlxSprite to this state
     */
    public function addSprite(sprite:FlxSprite):FlxSprite {
        regularSprites.push(sprite);
        add(sprite);
        return sprite;
    }

    /**
     * Add a custom exit animation for a regular FlxSprite
     */
    public function addSpriteExitAnimation(sprite:FlxSprite, exitAnimation:FlxSprite->Void->Void):Void {
        FlowSpriteManager.addExitAnimation(sprite, exitAnimation);
    }

    /**
     * Add a custom enter animation for a regular FlxSprite
     */
    public function addSpriteEnterAnimation(sprite:FlxSprite, enterAnimation:FlxSprite->Void->Void):Void {
        FlowSpriteManager.addEnterAnimation(sprite, enterAnimation);
    }

    /**
     * Remove a sprite from this state
     */
    public function removeSprite(sprite:FlxSprite):Void {
        if (sprite is FlowSprite) {
            flowSprites.remove(cast sprite);
        } else {
            regularSprites.remove(sprite);
            FlowSpriteManager.removeSprite(sprite);
        }
        remove(sprite);
    }

    private function playFlowSpriteAnimations(isEntering:Bool, callback:Void->Void):Void {
        if (flowSprites.length == 0) {
            if (callback != null) callback();
            return;
        }

        var remaining = flowSprites.length;
        for (sprite in flowSprites) {
            sprite.playAnimations(isEntering, function() {
                remaining--;
                if (remaining <= 0 && callback != null) {
                    callback();
                }
            });
        }
    }

    private function playRegularSpriteExitAnimations(callback:Void->Void):Void {
        if (regularSprites.length == 0) {
            if (callback != null) callback();
            return;
        }

        var remaining = regularSprites.length;

        for (sprite in regularSprites) {
            FlowSpriteManager.playExitAnimations(sprite, function() {
                remaining--;
                if (remaining <= 0 && callback != null) {
                    callback();
                }
            });
        }
    }

    override public function destroy():Void {
        // Clean up arrays
        flowSprites = null;
        regularSprites = null;

        super.destroy();
    }

    private function createDefaultExitAnimation(sprite:FlxSprite, callback:Void->Void):Void {
        FlxTween.tween(sprite, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.3, {
            ease: FlxEase.backIn,
            onComplete: function(tween:FlxTween) {
                if (callback != null) callback();
            }
        });
    }
}

