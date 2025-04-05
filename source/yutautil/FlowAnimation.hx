package yutautil;

import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class FlowAnimation {
	private var tween:FlxTween;
	private var animationName:String;
	private var waitForFrame:Int;
	private var waitForCompletion:Bool;

	public function new(?tween:FlxTween, ?animationName:String, ?waitForFrame:Int = -1, ?waitForCompletion:Bool = false) {
		this.tween = tween;
		this.animationName = animationName;
		this.waitForFrame = waitForFrame;
		this.waitForCompletion = waitForCompletion;
	}

	/**
	 * Plays the animation or tween on the given sprite.
	 */
	public function play(sprite:FlxSprite, callback:Void->Void):Void {
		if (tween != null) {
			tween.start({onComplete: function() callback()});
		} else if (animationName != null) {
			sprite.animation.play(animationName, false);
			if (waitForFrame >= 0) {
				sprite.animation.setCallback(function() {
					if (sprite.animation.curFrame >= waitForFrame) {
						sprite.animation.setCallback(null);
						callback();
					}
				});
			} else if (waitForCompletion) {
				sprite.animation.setCallback(function() {
					if (sprite.animation.finished) {
						sprite.animation.setCallback(null);
						callback();
					}
				});
			} else {
				callback();
			}
		} else {
			callback();
		}
	}
}
