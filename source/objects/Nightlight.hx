package objects;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.events.Event;
import openfl.Lib;

class Nightlight extends Sprite {

    public function new() {
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

    var nightlight:Bitmap;
    function init(?e:Event) {
		nightlight = new Bitmap(Paths.image("mechanics/general/toplight").bitmap);
        y = 0;
        var p = FlxG.mouse.getPositionInCameraView(FlxG.cameras.list[-1]);
        x = p.x - 1280;
        addChild(nightlight);
	}

    override function __update(transformOnly:Bool, updateChildren:Bool) {
        super.__update(transformOnly, updateChildren);
        y = Lib.application.window.height;
        var p = FlxG.mouse.getPositionInCameraView(FlxG.cameras.list[-1]);
        x = p.x - 1280;
    }
}