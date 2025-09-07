package yutautil;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

/**
 * FlowAnimation - Flexible animation system for FlowSprites
 * Can handle tweens, sprite animations, delays, and custom functions
 */
class FlowAnimation {
	private var tween:FlxTween;
	private var animationName:String;
	private var waitForFrame:Int;
	private var waitForCompletion:Bool;
	private var delay:Float;
	private var customFunction:FlxSprite->Void->Void;

	public function new(?tween:FlxTween, ?animationName:String, ?waitForFrame:Int = -1, ?waitForCompletion:Bool = false, ?delay:Float = 0, ?customFunction:FlxSprite->Void->Void) {
		this.tween = tween;
		this.animationName = animationName;
		this.waitForFrame = waitForFrame;
		this.waitForCompletion = waitForCompletion;
		this.delay = delay;
		this.customFunction = customFunction;
	}

	/**
	 * Create a tween-based animation
	 */
	public static function createTween(properties:Dynamic, duration:Float, ?options:Dynamic):FlowAnimation {
		var tween = FlxTween.tween(null, properties, duration, options);
		return new FlowAnimation(tween);
	}

	/**
	 * Create a sprite animation
	 */
	public static function createSpriteAnimation(animationName:String, waitForCompletion:Bool = true):FlowAnimation {
		return new FlowAnimation(null, animationName, -1, waitForCompletion);
	}

	/**
	 * Create a delay animation
	 */
	public static function createDelay(duration:Float):FlowAnimation {
		return new FlowAnimation(null, null, -1, false, duration);
	}

	/**
	 * Create a custom function animation
	 */
	public static function createCustom(func:FlxSprite->Void->Void):FlowAnimation {
		return new FlowAnimation(null, null, -1, false, 0, func);
	}

	/**
	 * Create a fade in animation
	 */
	public static function fadeIn(duration:Float = 0.5, ?ease:Null<Float->Float>):FlowAnimation {
		return new FlowAnimation(null, null, -1, false, 0, function(sprite:FlxSprite, callback:Void->Void) {
			sprite.alpha = 0;
			FlxTween.tween(sprite, {alpha: 1}, duration, {
				ease: ease != null ? ease : FlxEase.quadOut,
				onComplete: function(t:FlxTween) callback()
			});
		});
	}

	/**
	 * Create a fade out animation
	 */
	public static function fadeOut(duration:Float = 0.5, ?ease:Null<Float->Float>):FlowAnimation {
		return new FlowAnimation(null, null, -1, false, 0, function(sprite:FlxSprite, callback:Void->Void) {
			FlxTween.tween(sprite, {alpha: 0}, duration, {
				ease: ease != null ? ease : FlxEase.quadIn,
				onComplete: function(t:FlxTween) callback()
			});
		});
	}

	/**
	 * Create a scale animation
	 */
	public static function scale(fromX:Float, fromY:Float, toX:Float, toY:Float, duration:Float = 0.5, ?ease:Null<Float->Float>):FlowAnimation {
		return new FlowAnimation(null, null, -1, false, 0, function(sprite:FlxSprite, callback:Void->Void) {
			sprite.scale.set(fromX, fromY);
			FlxTween.tween(sprite.scale, {x: toX, y: toY}, duration, {
				ease: ease != null ? ease : FlxEase.backOut,
				onComplete: function(t:FlxTween) callback()
			});
		});
	}

	/**
	 * Create a slide animation
	 */
	public static function slide(fromX:Float, fromY:Float, toX:Float, toY:Float, duration:Float = 0.5, ?ease:Null<Float->Float>):FlowAnimation {
		return new FlowAnimation(null, null, -1, false, 0, function(sprite:FlxSprite, callback:Void->Void) {
			sprite.setPosition(fromX, fromY);
			FlxTween.tween(sprite, {x: toX, y: toY}, duration, {
				ease: ease != null ? ease : FlxEase.quadOut,
				onComplete: function(t:FlxTween) callback()
			});
		});
	}

	/**
	 * Play this animation on the given sprite
	 */
	public function play(sprite:FlxSprite, callback:Void->Void):Void {
		if (delay > 0) {
			new FlxTimer().start(delay, function(timer:FlxTimer) {
				executeAnimation(sprite, callback);
			});
		} else {
			executeAnimation(sprite, callback);
		}
	}

	private function executeAnimation(sprite:FlxSprite, callback:Void->Void):Void {
		if (customFunction != null) {
			customFunction(sprite, callback);
		} else if (tween != null) {
			// Set the target for the tween
			tween.target = sprite;
			var originalComplete = tween.onComplete;
			tween.onComplete = function(t:FlxTween) {
				if (originalComplete != null) originalComplete(t);
				if (callback != null) callback();
			};
			tween.start();
		} else if (animationName != null) {
			sprite.animation.play(animationName, false);

			if (waitForFrame >= 0) {
				// Wait for specific frame
				waitForAnimationFrame(sprite, waitForFrame, callback);
			} else if (waitForCompletion) {
				// Wait for animation completion
				waitForAnimationComplete(sprite, callback);
			} else {
				// Don't wait, call immediately
				if (callback != null) callback();
			}
		} else {
			// No animation, just call callback
			if (callback != null) callback();
		}
	}

	private function waitForAnimationFrame(sprite:FlxSprite, targetFrame:Int, callback:Void->Void):Void {
		if (sprite.animation.curAnim == null) {
			if (callback != null) callback();
			return;
		}

		var timer = new FlxTimer();
		timer.start(0.016, function(t:FlxTimer) { // ~60fps check
			if (sprite.animation.curAnim != null && sprite.animation.curAnim.curFrame >= targetFrame) {
				timer.cancel();
				if (callback != null) callback();
			}
		}, 0); // Loop indefinitely until condition is met
	}

	private function waitForAnimationComplete(sprite:FlxSprite, callback:Void->Void):Void {
		if (sprite.animation.curAnim == null) {
			if (callback != null) callback();
			return;
		}

		var timer = new FlxTimer();
		timer.start(0.016, function(t:FlxTimer) { // ~60fps check
			if (sprite.animation.curAnim == null || sprite.animation.curAnim.finished) {
				timer.cancel();
				if (callback != null) callback();
			}
		}, 0); // Loop indefinitely until condition is met
	}

	public function cancel():Void {
		if (tween != null) {
			tween.cancel();
		}
	}
}
