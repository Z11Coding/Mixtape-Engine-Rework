package yutautil;

import flixel.FlxG;
import openfl.events.Event;

class StateTick {
    public var tickInterval:Float;
    private var lastTick:Float;
    private var onTick:Void->Void;
    private var running:Bool = false;

    public static var current:StateTick;

    public function new(onTick:Void->Void, tickInterval:Float = 2.0, ?start:Bool = true) {
        if (current != null) {
            current.stop();
            current.destroy();
        }
        this.onTick = onTick;
        this.tickInterval = tickInterval;
        this.lastTick = FlxG.game.ticks / FlxG.updateFramerate;
        current = this;
        if (start) {
            this.start();
        }
        trace("StateTick created with interval: " + tickInterval);
    }

    private function onEnterFrame(event:Event):Void {
        var currentTime = FlxG.game.ticks / FlxG.updateFramerate;
        if (currentTime - lastTick >= tickInterval) {
            lastTick = currentTime;
            if (onTick != null) onTick();
        }
    }

    public function start():Void {
        if (!running && FlxG.stage != null) {
            FlxG.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            running = true;
        }
    }

    public function stop():Void {
        if (running && FlxG.stage != null) {
            FlxG.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            running = false;
        }
    }

    public function destroy():Void {
        stop();
        onTick = null;
        current = null;
    }
}