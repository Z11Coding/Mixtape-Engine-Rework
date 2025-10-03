package states.editors.themes;

import flixel.FlxSprite;

/**
 * Placeholder customization panel for theme system
 */
class CustomizationPanel extends FlxSprite
{
    public function new(x:Float, y:Float)
    {
        super(x, y);
        makeGraphic(200, 150, 0xFF1F2937);
    }

    public function setPosition(x:Float, y:Float):Void
    {
        this.x = x;
        this.y = y;
    }
}
