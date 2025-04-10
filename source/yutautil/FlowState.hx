package yutautil;

import flixel.FlxState;

class FlowState extends MusicBeatState {
	private var currentSubState:BaseFlowState;
	private static var _this:FlowState;

	public function new(initialState:BaseFlowState) {
		super();
		this._this = this; // A FlowState is meant to handle its own state transitions, so we can use this to reference it.
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

	override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (currentSubState != null) {
            currentSubState.update(elapsed);
        }
    }

    public function toFlxState():FlxState {
        return this;
    }
    public function getCurrentSubState():BaseFlowState {
        return currentSubState;
    }
    public function transitionToFlxState(newState:FlxState):Void {
        if (currentSubState != null) {
            currentSubState.exit(null, function() {
                currentSubState = new BaseFlowState([]);
                currentSubState.enter(currentSubState, function() {MusicBeatState.switchState(newState);});
            });
        }
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

    /**
     * Updates the state.
     */
    public function update(elapsed:Float):Void {
        for (sprite in sprites) {
            sprite.update(elapsed);
        }
}
}

