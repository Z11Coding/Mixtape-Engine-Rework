package states.freeplay.vslice;

import backend.Paths;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Atlas text implementation for Mixtape Engine
 * Simplified version of P-Slice's AtlasText
 */
class AtlasText extends FlxText {
    public function new(x:Float = 0, y:Float = 0, text:String = "", font:AtlasFont = null) {
        super(x, y, 0, text);

        // Use VCR font as fallback
        setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
    }
}

/**
 * Atlas font enum - simplified for Mixtape Engine
 */
enum AtlasFont {
    CAPSULE_TEXT;
    DEFAULT;
}
