package yutautil;

import flixel.FlxState;
import flixel.FlxG;

class StateTick extends flixel.FlxBasic {
    public var tickInterval:Float;
    private var lastTick:Float;
    private var onTick:Void->Void;

    public static var current:StateTick;

    public function new(onTick:Void->Void, tickInterval:Float = 2000.0) {
        this.onTick = onTick;
        this.tickInterval = tickInterval;
        this.lastTick = FlxG.game.ticks / FlxG.updateFramerate;
        super();
        trace("StateTick created with interval: " + tickInterval);
        current = this;

    }

    public override function update(elapsed:Float):Void {
        trace("StateTick updating, elapsed: " + elapsed);
        super.update(elapsed);
        var currentTime = FlxG.game.ticks / FlxG.updateFramerate;
        if (currentTime - lastTick >= tickInterval) {
            lastTick = currentTime;
            if (onTick != null) onTick();
        }
        trace("StateTick updated, current time: " + currentTime + ", last tick: " + lastTick);
    }
}