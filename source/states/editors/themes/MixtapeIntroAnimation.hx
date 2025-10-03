package states.editors.themes;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Intro animation for Mixtape chart theme
 */
class MixtapeIntroAnimation extends FlxSprite
{
    var theme:MixtapeChartTheme;

    public function new(theme:MixtapeChartTheme)
    {
        super();
        this.theme = theme;
        makeGraphic(1, 1, 0x00000000); // Invisible sprite
    }

    public function play(onComplete:Void->Void):Void
    {
        // Simple fade-in animation
        alpha = 0;
        FlxTween.tween(this, {alpha: 1}, 0.5, {
            ease: FlxEase.circOut,
            onComplete: function(t) {
                if (onComplete != null) onComplete();
            }
        });
    }
}
