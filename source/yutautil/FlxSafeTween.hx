package yutautil;

// This will be a class which simply takes FlxTween, and manages if it crashes, so that the Global Error Handler can simply handle
// the crash, and this class will just kill the tween and return to the game.

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxTimer;


class FlxSafeTween
{
    // This will be a list of all the tweens that are currently running in "safe" mode.
    private static var _tweens:Array<FlxTween> = [];


    public static function tween(
        start:Dynamic,
        end:Dynamic,
        duration:Float,
        ?ease:Dynamic = null,
        ?onUpdate:Dynamic = null,
        ?onComplete:Dynamic = null
    ):FlxTween
    {
        var tween = FlxTween.num(start, end, duration, {
            ease: ease,
            onUpdate: function(progress:Float):Void
            {
                try
                {
                    if (onUpdate != null)
                    {
                        onUpdate(progress);
                    }
                }
                catch (e:Dynamic)
                {
                    FlxG.log("Error in tween onUpdate callback: " + e);
                    FlxG.log("Killing tween.");
                    tween.destroy();
                    FlxArrayUtil.remove(_tweens, tween);
                }
            },
            onComplete: function(tween:FlxTween):Void
            {
                try
                {
                    if (onComplete != null)
                    {
                        onComplete(tween);
                    }
                }
                catch (e:Dynamic)
                {
                    FlxG.log("Error in tween onComplete callback: " + e);
                    FlxG.log("Killing tween.");
                    tween.destroy();
                    FlxArrayUtil.remove(_tweens, tween);
                }
            }
        });

        _tweens.push(tween);
        return tween;
}

    public static function cancelAll():Void
    {
        for (tween in _tweens)
        {
            tween.destroy();
        }
        _tweens = [];
    }

    // // NumTween type.
    // public static function numTween(
    //     start:Dynamic,
    //     end:Dynamic,
    //     duration:Float,
    //     ?ease:Dynamic = null,
    //     ?onUpdate:Dynamic = null,
    //     ?onComplete:Dynamic = null
    // ):NumTween
    // {
    //     var tween = FlxTween.num(start, end, duration, {
    //         ease: ease,
    //         onUpdate: function(progress:Float):Void
    //         {
    //             try
    //             {
    //                 if (onUpdate != null)
    //                 {
    //                     onUpdate(progress);
    //                 }
    //             }
    //             catch (e:Dynamic)
    //             {
    //                 FlxG.log("Error in tween onUpdate callback: " + e);
    //                 FlxG.log("Killing tween.");
    //                 tween.destroy();
    //                 FlxArrayUtil.remove(_tweens, tween);
    //             }
    //         },
    //         onComplete: function(tween:FlxTween):Void
    //         {
    //             try
    //             {
    //                 if (onComplete != null)
    //                 {
    //                     onComplete(tween);
    //                 }
    //             }
    //             catch (e:Dynamic)
    //             {
    //                 FlxG.log("Error in tween onComplete callback: " + e);
    //                 FlxG.log("Killing tween.");
    //                 tween.destroy();
    //                 FlxArrayUtil.remove(_tweens, tween);
    //             }
    //         }
    //     });

    //     _tweens.push(tween);
    //     return tween;
    // }

}


