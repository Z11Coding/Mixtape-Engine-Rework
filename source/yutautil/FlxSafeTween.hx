package yutautil;

// This will be a class which simply takes FlxTween, and manages if it crashes, so that the Global Error Handler can simply handle
// the crash, and this class will just kill the tween and return to the game.

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxTimer;


class FlxSafeTween
{
    // This will be a list of all the tweens that are currently running.
    private var _tweens:Array<FlxTween>;

    public function new()
    {
        _tweens = [];
    }
    