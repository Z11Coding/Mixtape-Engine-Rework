package stages;

import utils.window.CppAPI;

class Desktop extends backend.BaseStage
{
    var bg:FlxSprite;
    var wasFullscreen:Bool = false;

    override function create()
    {
        wasFullscreen = FlxG.fullscreen;
        bg = new FlxSprite(0, 0, null);
        bg.makeGraphic(FlxG.width, FlxG.height, 0xff000000);
        add(bg);

        CppAPI.setTransparency("Mixtape Engine", 0xff000000);
        if (!FlxG.fullscreen)
        {
            FlxG.fullscreen = true;
        }

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (!FlxG.fullscreen)
            {
                FlxG.fullscreen = true;
            }
        super.update(elapsed);
    }

    override function destroy()
    {
        CppAPI.setTransparency("Mixtape Engine", 0x00000001);
        FlxG.fullscreen = wasFullscreen;
        super.destroy();
    }
}