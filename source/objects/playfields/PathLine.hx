package objects.playfields;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import openfl.geom.ColorTransform;

class PathLine extends NoteObject {
	public var strip:ArrowPathStrip;
	public var render:Bool = true;

	public var thickness(get, set):Float;
	public var multAlpha:Float = 1;

	public var adaptiveDirection:Bool = false;
	public var minDistance:Float = -180;
	public var maxDistance:Float = 720;
  public var steps:Float = 44;

  var drawData:Array<NoteTailDrawData> = [];
	var drawItems:Int = 0;

  var strumInstance:StrumNote = null;

	public function new(receptor:StrumNote) {
		super();
		this.strip = new ArrowPathStrip();
    this.objType = STRUM;
    this.strumInstance = receptor;
    this.column = receptor.column;
	}

	public function copyReceptor(receptor:StrumNote) {
		alpha = receptor.alpha * multAlpha;
		visible = receptor.visible;
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);
		strip.update(elapsed);

		copyReceptor(strumInstance);

    if (render && visible && alpha > 0)
			updateTriangles();
	}

	public override function draw():Void {
		if (!visible || !render || alpha <= 0) return;

		strip.alpha = alpha;
		strip.color = color;

		for (camera in getCamerasLegacy()) {
			if (camera.visible && camera.exists)
				drawComplex(camera);
		}
	}

	public override function drawComplex(camera:FlxCamera):Void {
		for (i in 0 ... drawItems) {
			strip.updateRender(drawData[i]);
			strip.drawToCamera(camera);
		}
	}

  public function updateTriangles():Void {
		if (steps < 5) {
			trace('$steps px/step for arrow path is too low !!');
			steps = 5;
		}

		var scrollDistance:Float = minDistance;

    drawItems = 0;
		var defaultAngle:Float = angle;
		var prevAngle:Null<Float> = null;

		while (scrollDistance < maxDistance) {
			var prevScale:FlxPoint = FlxPoint.weak(scale.x, scale.y);
			var prevPosition:FlxPoint = FlxPoint.weak(x, y);

			scrollDistance += steps;

			var curPosition:FlxPoint = FlxPoint.weak(x, y);

			if (adaptiveDirection) {
				angle = (prevPosition.degreesTo(curPosition) + 180);
				prevAngle ??= angle;
			} else {
				prevAngle ??= defaultAngle;
			}

			var data:NoteTailDrawData = (drawData[drawItems] ?? new NoteTailDrawData());
			data.copyPosition(prevPosition, curPosition);
			data.setScale(prevScale.x, scale.x);
			data.setAngle(prevAngle, angle);
			drawData[drawItems ++] = data;

			prevAngle = angle;
		}
	}

	inline function get_thickness():Float {
		return strip.thickness;
	}
	inline function set_thickness(now:Float):Float {
		return strip.thickness = now;
	}
}

class ArrowPathStrip extends objects.FunkinStrip {
	public var thickness:Float = 20;

	public function new() {
		super();

		this.antialiasing = false;
		this.makeGraphic(25, 25, FlxColor.WHITE);

		indices = new DrawData<Int>(6, true, [0, 1, 2, 1, 2, 3]);
		uvtData = new DrawData<Float>(8, true, [0, 0, 0, 1, 1, 0, 1, 1]);
		vertices = new DrawData<Float>(8, true, [0, 0, 0, 0, 0, 0, 0, 0]);
		// topleft topright bottomleft bottomright
	}

	public function updateRender(drawData:NoteTailDrawData):Void {
		if (graphic == null) return;

		// update vertices
		var width:Float = (thickness * .5 * drawData.scaleTo);
		var sin:Float = (FlxMath.fastSin(drawData.angleTo) * width);
		var cos:Float = (FlxMath.fastCos(drawData.angleTo) * width);

		vertices[0] = (-sin + drawData.xTo); // top left
		vertices[1] = (cos + drawData.yTo);
		vertices[2] = (sin + drawData.xTo); // top right
		vertices[3] = (-cos + drawData.yTo);

		width = (thickness * .5 * drawData.scaleFrom);
		sin = (FlxMath.fastSin(drawData.angleFrom) * width);
		cos = (FlxMath.fastCos(drawData.angleFrom) * width);

		vertices[4] = (-sin + drawData.xFrom); // bottom left
		vertices[5] = (cos + drawData.yFrom);
		vertices[6] = (sin + drawData.xFrom); // bottom right
		vertices[7] = (-cos + drawData.yFrom);
	}
}

class NoteTailDrawData {
	public var scaleFrom:Float = 1;
	public var angleFrom:Float = 0;
	public var xFrom:Float = 0;
	public var yFrom:Float = 0;

	public var scaleTo:Float = 1;
	public var angleTo:Float = 0;
	public var xTo:Float = 0;
	public var yTo:Float = 0;

	public var ct:ColorTransform = null;

	public var clip:Float = 0;

	public var strip:Dynamic;

	var TO_RAD:Float = (1 / 180 * Math.PI);

	public function new() {}

	public inline function setAngle(from:Float, ?to:Float):Void {
		angleFrom = from * TO_RAD;
		angleTo = (to ?? from) * TO_RAD;
	}
	public inline function setScale(from:Float, ?to:Float):Void {
		scaleFrom = from;
		scaleTo = to ?? from;
	}
	public inline function setCT(copy:ColorTransform):Void {
		ct ??= new ColorTransform();
		ct.redOffset = copy.redOffset;
    ct.greenOffset = copy.greenOffset;
    ct.blueOffset = copy.blueOffset;
    ct.alphaOffset = copy.alphaOffset;
		ct.redMultiplier = copy.redMultiplier;
    ct.greenMultiplier = copy.greenMultiplier;
    ct.blueMultiplier = copy.blueMultiplier;
    ct.alphaMultiplier = copy.alphaMultiplier;
	}
	public inline function setPosition(x:Float, y:Float, ?xT:Float, ?yT:Float):Void {
		xFrom = x;
		yFrom = y;
		if (xT != null) xTo = xT;
		if (yT != null) yTo = yT;
	}
	public inline function copyPosition(point:FlxPoint, ?pointTo:FlxPoint):Void {
		xFrom = point.x;
		yFrom = point.y;
		if (pointTo != null) {
			xTo = pointTo.x;
			yTo = pointTo.y;
		}
	}
}
