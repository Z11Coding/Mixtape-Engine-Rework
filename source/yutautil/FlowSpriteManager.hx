package yutautil;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

/**
 * FlowSpriteManager - Utility class for managing animations on regular FlxSprites
 * Provides an easy way to add exit animations to any FlxSprite
 */
class FlowSpriteManager {
    private static var exitAnimations:Map<FlxSprite, Array<FlxSprite->Void->Void>> = new Map();
    private static var enterAnimations:Map<FlxSprite, Array<FlxSprite->Void->Void>> = new Map();

    /**
     * Add an exit animation to a regular FlxSprite
     */
    public static function addExitAnimation(sprite:FlxSprite, animation:FlxSprite->Void->Void):Void {
        if (!exitAnimations.exists(sprite)) {
            exitAnimations.set(sprite, []);
        }
        exitAnimations.get(sprite).push(animation);
    }

    /**
     * Add an enter animation to a regular FlxSprite
     */
    public static function addEnterAnimation(sprite:FlxSprite, animation:FlxSprite->Void->Void):Void {
        if (!enterAnimations.exists(sprite)) {
            enterAnimations.set(sprite, []);
        }
        enterAnimations.get(sprite).push(animation);
    }

    /**
     * Play exit animations for a sprite
     */
    public static function playExitAnimations(sprite:FlxSprite, callback:Void->Void):Void {
        if (exitAnimations.exists(sprite)) {
            var animations = exitAnimations.get(sprite);
            playAnimationSequence(sprite, animations, callback);
        } else {
            // Use default exit animation
            defaultExitAnimation(sprite, callback);
        }
    }

    /**
     * Play enter animations for a sprite
     */
    public static function playEnterAnimations(sprite:FlxSprite, callback:Void->Void):Void {
        if (enterAnimations.exists(sprite)) {
            var animations = enterAnimations.get(sprite);
            playAnimationSequence(sprite, animations, callback);
        } else {
            // No enter animation, just call callback
            if (callback != null) callback();
        }
    }

    /**
     * Remove all animations for a sprite (cleanup)
     */
    public static function removeSprite(sprite:FlxSprite):Void {
        exitAnimations.remove(sprite);
        enterAnimations.remove(sprite);
    }

    /**
     * Clear all stored animations (for cleanup)
     */
    public static function clearAll():Void {
        exitAnimations.clear();
        enterAnimations.clear();
    }

    private static function playAnimationSequence(sprite:FlxSprite, animations:Array<FlxSprite->Void->Void>, callback:Void->Void):Void {
        if (animations.length == 0) {
            if (callback != null) callback();
            return;
        }

        var remaining = animations.length;
        for (animation in animations) {
            animation(sprite, function() {
                remaining--;
                if (remaining <= 0 && callback != null) {
                    callback();
                }
            });
        }
    }

    private static function defaultExitAnimation(sprite:FlxSprite, callback:Void->Void):Void {
        FlxTween.tween(sprite, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.3, {
            ease: FlxEase.backIn,
            onComplete: function(tween:FlxTween) {
                if (callback != null) callback();
            }
        });
    }

    // Helper functions for common animations

    /**
     * Create a fade out animation
     */
    public static function createFadeOut(duration:Float = 0.5, ?ease:Null<Float->Float>):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            FlxTween.tween(sprite, {alpha: 0}, duration, {
                ease: ease != null ? ease : FlxEase.quadIn,
                onComplete: function(t:FlxTween) if (callback != null) callback()
            });
        };
    }

    /**
     * Create a fade in animation
     */
    public static function createFadeIn(duration:Float = 0.5, ?ease:Null<Float->Float>):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            sprite.alpha = 0;
            FlxTween.tween(sprite, {alpha: 1}, duration, {
                ease: ease != null ? ease : FlxEase.quadOut,
                onComplete: function(t:FlxTween) if (callback != null) callback()
            });
        };
    }

    /**
     * Create a scale out animation
     */
    public static function createScaleOut(duration:Float = 0.3, ?ease:Null<Float->Float>):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            FlxTween.tween(sprite.scale, {x: 0, y: 0}, duration, {
                ease: ease != null ? ease : FlxEase.backIn,
                onComplete: function(t:FlxTween) if (callback != null) callback()
            });
        };
    }

    /**
     * Create a scale in animation
     */
    public static function createScaleIn(duration:Float = 0.5, ?ease:Null<Float->Float>):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            sprite.scale.set(0, 0);
            FlxTween.tween(sprite.scale, {x: 1, y: 1}, duration, {
                ease: ease != null ? ease : FlxEase.backOut,
                onComplete: function(t:FlxTween) if (callback != null) callback()
            });
        };
    }

    /**
     * Create a slide out animation
     */
    public static function createSlideOut(direction:String, distance:Float = 200, duration:Float = 0.5, ?ease:Null<Float->Float>):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            var targetX = sprite.x;
            var targetY = sprite.y;

            switch (direction.toLowerCase()) {
                case "left":
                    targetX = sprite.x - distance;
                case "right":
                    targetX = sprite.x + distance;
                case "top":
                    targetY = sprite.y - distance;
                case "bottom":
                    targetY = sprite.y + distance;
            }

            FlxTween.tween(sprite, {x: targetX, y: targetY}, duration, {
                ease: ease != null ? ease : FlxEase.backIn,
                onComplete: function(t:FlxTween) if (callback != null) callback()
            });
        };
    }

    /**
     * Create a slide in animation
     */
    public static function createSlideIn(direction:String, distance:Float = 200, duration:Float = 0.5, ?ease:Null<Float->Float>):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            var originalX = sprite.x;
            var originalY = sprite.y;

            switch (direction.toLowerCase()) {
                case "left":
                    sprite.x = originalX - distance;
                case "right":
                    sprite.x = originalX + distance;
                case "top":
                    sprite.y = originalY - distance;
                case "bottom":
                    sprite.y = originalY + distance;
            }

            FlxTween.tween(sprite, {x: originalX, y: originalY}, duration, {
                ease: ease != null ? ease : FlxEase.backOut,
                onComplete: function(t:FlxTween) if (callback != null) callback()
            });
        };
    }

    /**
     * Create a delay animation
     */
    public static function createDelay(duration:Float):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            new FlxTimer().start(duration, function(timer:FlxTimer) {
                if (callback != null) callback();
            });
        };
    }

    /**
     * Create a combined animation (multiple animations at once)
     */
    public static function createCombined(animations:Array<FlxSprite->Void->Void>):FlxSprite->Void->Void {
        return function(sprite:FlxSprite, callback:Void->Void) {
            if (animations.length == 0) {
                if (callback != null) callback();
                return;
            }

            var remaining = animations.length;
            for (animation in animations) {
                animation(sprite, function() {
                    remaining--;
                    if (remaining <= 0 && callback != null) {
                        callback();
                    }
                });
            }
        };
    }
}
