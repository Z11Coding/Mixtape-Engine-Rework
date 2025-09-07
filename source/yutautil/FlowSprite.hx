package yutautil;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * FlowSprite - Enhanced sprite with built-in enter/exit animations and tweens
 * Designed to work seamlessly with the FlowState system
 */
class FlowSprite extends FlxSprite {
	private var enterAnimations:Array<FlowAnimation> = [];
	private var exitAnimations:Array<FlowAnimation> = [];
	private var enterTweens:Array<FlxTween> = [];
	private var exitTweens:Array<FlxTween> = [];

	private var destroyWithAnimation:Bool = true;
	private var destroyCallback:Void->Void;

	public function new(x:Float = 0, y:Float = 0, graphic:Dynamic = null) {
		super(x, y);
		if (graphic != null) {
			this.loadGraphic(graphic);
		}
	}

	/**
	 * Add an enter animation using FlowAnimation
	 */
	public function addEnterAnimation(animation:FlowAnimation):FlowSprite {
		enterAnimations.push(animation);
		return this;
	}

	/**
	 * Add an exit animation using FlowAnimation
	 */
	public function addExitAnimation(animation:FlowAnimation):FlowSprite {
		exitAnimations.push(animation);
		return this;
	}

	/**
	 * Add an enter tween
	 */
	public function addEnterTween(tween:FlxTween):FlowSprite {
		enterTweens.push(tween);
		return this;
	}

	/**
	 * Add an exit tween
	 */
	public function addExitTween(tween:FlxTween):FlowSprite {
		exitTweens.push(tween);
		return this;
	}

	/**
	 * Quick helper to add a fade-in enter animation
	 */
	public function fadeIn(duration:Float = 0.5, ?ease:Null<Float->Float>):FlowSprite {
		this.alpha = 0;
		var tween = FlxTween.tween(this, {alpha: 1}, duration, {ease: ease != null ? ease : FlxEase.quadOut});
		addEnterTween(tween);
		return this;
	}

	/**
	 * Quick helper to add a fade-out exit animation
	 */
	public function fadeOut(duration:Float = 0.5, ?ease:Null<Float->Float>):FlowSprite {
		var tween = FlxTween.tween(this, {alpha: 0}, duration, {ease: ease != null ? ease : FlxEase.quadIn});
		addExitTween(tween);
		return this;
	}

	/**
	 * Quick helper to add a slide-in enter animation
	 */
	public function slideInFrom(direction:String, distance:Float = 200, duration:Float = 0.5, ?ease:Null<Float->Float>):FlowSprite {
		var originalX = this.x;
		var originalY = this.y;

		switch (direction.toLowerCase()) {
			case "left":
				this.x = originalX - distance;
			case "right":
				this.x = originalX + distance;
			case "top":
				this.y = originalY - distance;
			case "bottom":
				this.y = originalY + distance;
		}

		var tween = FlxTween.tween(this, {x: originalX, y: originalY}, duration, {ease: ease != null ? ease : FlxEase.backOut});
		addEnterTween(tween);
		return this;
	}

	/**
	 * Quick helper to add a slide-out exit animation
	 */
	public function slideOutTo(direction:String, distance:Float = 200, duration:Float = 0.5, ?ease:Null<Float->Float>):FlowSprite {
		var targetX = this.x;
		var targetY = this.y;

		switch (direction.toLowerCase()) {
			case "left":
				targetX = this.x - distance;
			case "right":
				targetX = this.x + distance;
			case "top":
				targetY = this.y - distance;
			case "bottom":
				targetY = this.y + distance;
		}

		var tween = FlxTween.tween(this, {x: targetX, y: targetY}, duration, {ease: ease != null ? ease : FlxEase.backIn});
		addExitTween(tween);
		return this;
	}

	/**
	 * Quick helper to add a scale-in enter animation
	 */
	public function scaleIn(duration:Float = 0.5, ?ease:Null<Float->Float>):FlowSprite {
		this.scale.set(0, 0);
		var tween = FlxTween.tween(this.scale, {x: 1, y: 1}, duration, {ease: ease != null ? ease : FlxEase.backOut});
		addEnterTween(tween);
		return this;
	}

	/**
	 * Quick helper to add a scale-out exit animation
	 */
	public function scaleOut(duration:Float = 0.3, ?ease:Null<Float->Float>):FlowSprite {
		var tween = FlxTween.tween(this.scale, {x: 0, y: 0}, duration, {ease: ease != null ? ease : FlxEase.backIn});
		addExitTween(tween);
		return this;
	}

	/**
	 * Set whether this sprite should be destroyed with animation or immediately
	 */
	public function setDestroyWithAnimation(value:Bool):FlowSprite {
		destroyWithAnimation = value;
		return this;
	}

	/**
	 * Play all animations/tweens for entering or exiting
	 */
	public function playAnimations(isEntering:Bool, callback:Void->Void):Void {
		var animations = isEntering ? enterAnimations : exitAnimations;
		var tweens = isEntering ? enterTweens : exitTweens;

		var totalAnimations = animations.length + tweens.length;
		if (totalAnimations == 0) {
			if (callback != null) callback();
			return;
		}

		var completed = 0;

		// Play FlowAnimations
		if (animations.length > 0) {
			playFlowAnimations(animations, 0, function() {
				completed++;
				if (completed >= 2 && callback != null) callback();
			});
		} else {
			completed++;
		}

		// Play Tweens
		if (tweens.length > 0) {
			playTweens(tweens, function() {
				completed++;
				if (completed >= 2 && callback != null) callback();
			});
		} else {
			completed++;
		}

		// If both are already completed
		if (completed >= 2 && callback != null) {
			callback();
		}
	}

	private function playFlowAnimations(animations:Array<FlowAnimation>, index:Int, callback:Void->Void):Void {
		if (index < animations.length) {
			animations[index].play(this, function() {
				playFlowAnimations(animations, index + 1, callback);
			});
		} else {
			if (callback != null) callback();
		}
	}

	private function playTweens(tweens:Array<FlxTween>, callback:Void->Void):Void {
		var remaining = tweens.length;
		for (tween in tweens) {
			var originalComplete = tween.onComplete;
			tween.onComplete = function(t:FlxTween) {
				if (originalComplete != null) originalComplete(t);
				remaining--;
				if (remaining <= 0 && callback != null) {
					callback();
				}
			};
			tween.start();
		}
	}

	/**
	 * Destroy this sprite with or without animation
	 */
	public function destroySprite(?callback:Void->Void):Void {
		destroyCallback = callback;

		if (destroyWithAnimation && exitAnimations.length > 0 || exitTweens.length > 0) {
			playAnimations(false, function() {
				actuallyDestroy();
			});
		} else {
			actuallyDestroy();
		}
	}

	private function actuallyDestroy():Void {
		if (destroyCallback != null) {
			destroyCallback();
		}
		this.destroy();
	}

	override public function destroy():Void {
		// Cancel all active tweens
		for (tween in enterTweens) {
			if (tween != null) tween.cancel();
		}
		for (tween in exitTweens) {
			if (tween != null) tween.cancel();
		}

		// Clean up arrays
		enterAnimations = null;
		exitAnimations = null;
		enterTweens = null;
		exitTweens = null;
		destroyCallback = null;

		super.destroy();
	}
}
