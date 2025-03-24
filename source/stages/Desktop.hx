package stages;

import backend.window.CppAPI;

class Desktop extends BaseStage
{
    var bg:FlxSprite;
    var wasFullscreen:Bool = false;

    override function create()
    {
        wasFullscreen = FlxG.fullscreen;
        bg = new FlxSprite(0, 0, null);
        bg.makeGraphic(FlxG.width, FlxG.height, 0xff000000);
        add(bg);

        #if windows 
        CppAPI.setTransparency("Mixtape Engine", 0xff000000);
        if (!FlxG.fullscreen)
        {
            FlxG.fullscreen = true;
        }
        #end

        super.create();
    }

    override function update(elapsed:Float)
    {
        #if windows
        if (!FlxG.fullscreen)
        {
            FlxG.fullscreen = true;
        }
        #end
        super.update(elapsed);
    }

    override function destroy()
    {
        #if windows
        CppAPI.setTransparency("Mixtape Engine", 0x00000001);
        FlxG.fullscreen = wasFullscreen;
        #end
        super.destroy();
    }
}