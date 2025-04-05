package yutautil;

import flixel.FlxState;

class FlowState extends MusicBeatState {
	private var currentSubState:BaseFlowState;

	public function new(initialState:BaseFlowState) {
		super();
		this.currentSubState = initialState;
		this.currentSubState.enter(null, function() {});
	}

	/**
	 * Transitions to a new FlowState.
	 * @param newState The new state to transition to.
	 */
	public function transitionTo(newState:BaseFlowState):Void {
		currentSubState.exit(newState, function() {
			currentSubState = newState;
			currentSubState.enter(currentSubState, function() {});
		});
	}
}

class BaseFlowState {
	public var sprites:Array<FlowSprite>;

	public function new(sprites:Array<FlowSprite>) {
		this.sprites = sprites;
	}

	/**
	 * Handles the transition into this state.
	 */
	public function enter(fromState:BaseFlowState, callback:Void->Void):Void {
		if (sprites != null && sprites.length > 0) {
			playAnimations(sprites, true, callback);
		} else {
			callback();
		}
	}

	/**
	 * Handles the transition out of this state.
	 */
	public function exit(toState:BaseFlowState, callback:Void->Void):Void {
		if (sprites != null && sprites.length > 0) {
			playAnimations(sprites, false, callback);
		} else {
			callback();
		}
	}

	private function playAnimations(sprites:Array<FlowSprite>, isEntering:Bool, callback:Void->Void):Void {
		var remaining = sprites.length;
		for (sprite in sprites) {
			sprite.playAnimations(isEntering, function() {
				remaining--;
				if (remaining == 0) {
					callback();
				}
			});
		}
	}
}
