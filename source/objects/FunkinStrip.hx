package objects;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

class FunkinStrip extends FunkinSprite {
	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var colors:DrawData<Int> = new DrawData<Int>();

	public var repeat:Bool = false;

	override public function destroy():Void {
		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;

		super.destroy();
	}

	override public function draw():Void {
		if (alpha == 0 || graphic == null || vertices == null)
			return;

		final cameras = getCamerasLegacy();
		for (camera in cameras) {
			if (!camera.visible || !camera.exists) return;

			drawToCamera(camera);

			#if FLX_DEBUG FlxBasic.visibleCount ++; #end
		}
	}

	public function drawToCamera(camera:FlxCamera):Void {
		var prev:Float = alpha;
		alpha *= camera.alpha; // maybe figure out what is actually going on that causes strips not to consider alpha ...?

		getScreenPosition(_point, camera).subtractPoint(offset);
		#if !flash
		camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, repeat, antialiasing, colorTransform, shader);
		#else
		camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, repeat, antialiasing);
		#end

		alpha = prev;
	}
}
