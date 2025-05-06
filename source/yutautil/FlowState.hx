package yutautil;

import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.effects.FlxFlicker;

class FlowState extends MusicBeatState {
    private var currentSubState:BaseFlowState;
    private static var _this:FlowState;

    public function new(initialState:BaseFlowState) {
        super();
        _this = this;
        this.currentSubState = initialState;
        this.currentSubState.enter(null, function() {});
    }

    public function transitionTo(newState:BaseFlowState):Void {
        currentSubState.exit(newState, function() {
            cleanupCurrentState();
            currentSubState = newState;
            currentSubState.enter(currentSubState, function() {});
        });
    }

    public function transitionToFlxState(newState:FlxState):Void {
        currentSubState.exit(null, function() {
            cleanupCurrentState();
            FlxG.camera.fade(0xFF000000, 1, true, function() {
                MusicBeatState.switchState(newState);
            });
        });
    }

    private function cleanupCurrentState():Void {
        if (currentSubState != null) {
            for (sprite in currentSubState.sprites) {
                sprite.destroy();
            }
            currentSubState.sprites = [];
        }
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
}

class BaseFlowState {
    public var sprites:Array<FlowSprite>;

    public function new(sprites:Array<FlowSprite>) {
        this.sprites = sprites;
    }

    public function enter(fromState:BaseFlowState, callback:Void->Void):Void {
        if (sprites != null && sprites.length > 0) {
            playAnimations(sprites, true, callback);
        } else {
            callback();
        }
    }

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

    public function update(elapsed:Float):Void {
        for (sprite in sprites) {
            sprite.update(elapsed);
        }
    }
}

class FlowSprite extends FlxSprite {
    public var enterTweens:Array<FlxTween>;
    public var exitTweens:Array<FlxTween>;

    public function new() {
        super();
        enterTweens = [];
        exitTweens = [];
    }

    public function playAnimations(isEntering:Bool, callback:Void->Void):Void {
        var tweens = isEntering ? enterTweens : exitTweens;
        if (tweens.length > 0) {
            var remaining = tweens.length;
            for (tween in tweens) {
                tween.onComplete = function() {
                    remaining--;
                    if (remaining == 0) {
                        callback();
                    }
                };
                tween.start();
            }
        } else {
            callback();
        }
    }

    override public function destroy():Void {
        for (tween in enterTweens) {
            tween.cancel();
        }
        for (tween in exitTweens) {
            tween.cancel();
        }
        super.destroy();
    }
}

