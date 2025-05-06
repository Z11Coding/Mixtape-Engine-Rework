package yutautil;

import flixel.FlxSprite;

class FlowSprite extends FlxSprite {
	private var enterAnimations:Array<FlowAnimation>;
	private var exitAnimations:Array<FlowAnimation>;

	public function new(x:Float, y:Float, graphic:Dynamic = null) {
		super(x, y);
		if (graphic != null) {
			this.loadGraphic(graphic);
		}
		enterAnimations = [];
		exitAnimations = [];
	}

	/**
	 * Adds an animation for entering a state.
	 */
	public function addEnterAnimation(animation:FlowAnimation):Void {
		enterAnimations.push(animation);
	}

	/**
	 * Adds an animation for exiting a state.
	 */
	public function addExitAnimation(animation:FlowAnimation):Void {
		exitAnimations.push(animation);
	}

	/**
	 * Plays all animations for entering or exiting a state.
	 */
	public function playAnimations(isEntering:Bool, callback:Void->Void):Void {
		var animations = isEntering ? enterAnimations : exitAnimations;
		playNextAnimation(animations, 0, callback);
	}

	private function playNextAnimation(animations:Array<FlowAnimation>, index:Int, callback:Void->Void):Void {
		if (index < animations.length) {
			animations[index].play(this, function() playNextAnimation(animations, index + 1, callback));
		} else {
			callback();
		}
	}
}
