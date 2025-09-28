package shapeEx;

import flixel.graphics.FlxGraphic;
class Rect extends FlxSprite
{
	public var mainRound:Float;
	public function new(X:Float = 0, Y:Float = 0, width:Float = 0, height:Float = 0, roundWidth:Float = 0, roundHeight:Float = 0, Color:FlxColor = FlxColor.WHITE, ?Alpha:Float = 1, ?lineStyle:Int = 0, ?lineColor:FlxColor = FlxColor.WHITE)
	{
		super(X, Y);

		this.mainRound = roundWidth;

		if (Paths.currentTrackedFrames.get('rect-w'+Std.int(width)+'-h:'+Std.int(height)+'-rw:'+Std.int(roundWidth)+'-rh:'+Std.int(roundHeight)) == null) addCache(width, height, roundWidth, roundHeight, lineStyle, lineColor);
		frames = Paths.currentTrackedFrames.get('rect-w'+Std.int(width)+'-h:'+Std.int(height)+'-rw:'+Std.int(roundWidth)+'-rh:'+Std.int(roundHeight));
		antialiasing = ClientPrefs.data.antialiasing;
		color = Color;
		alpha = Alpha;
	}

	function addCache(width:Float = 0, height:Float = 0, roundWidth:Float = 0, roundHeight:Float = 0, lineStyle:Int, lineColor:FlxColor) {
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(drawRect(width, height, roundWidth, roundHeight, lineStyle, lineColor));
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;

		Paths.currentTrackedFrames.set('rect-w'+Std.int(width)+'-h:'+Std.int(height)+'-rw:'+Std.int(roundWidth)+'-rh:'+Std.int(roundHeight), newGraphic.imageFrame);
	}

	function drawRect(width:Float, height:Float, roundWidth:Float, roundHeight:Float, lineStyle:Int, lineColor:FlxColor):BitmapData
	{
		var shape:Shape = new Shape();

		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.drawRoundRect(0, 0, Std.int(width), Std.int(height), roundWidth, roundHeight);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0);
		bitmap.draw(shape);
		if (lineStyle > 0) drawLine(bitmap, lineStyle, roundWidth, roundHeight, lineColor);
		return bitmap;
	}

	static var lineShape:Shape = null;
  function drawLine(bitmap:BitmapData, lineStyle:Int, roundWidth:Float, roundHeight:Float, lineColor:FlxColor)
	{
    if (lineShape == null) {
      lineShape = new Shape();
      var lineSize:Int = lineStyle;
      lineShape.graphics.beginFill(lineColor);
      lineShape.graphics.lineStyle(1, lineColor, 1);
      lineShape.graphics.drawRoundRect(0, 0, bitmap.width, bitmap.height, roundWidth, roundHeight);
      lineShape.graphics.lineStyle(0, 0, 0);
      lineShape.graphics.drawRoundRect(lineSize, lineSize, bitmap.width - lineSize * 2, bitmap.height - lineSize * 2, roundWidth - lineSize * 2, roundHeight - lineSize * 2);
      lineShape.graphics.endFill();
    }

		bitmap.draw(lineShape);
	}
}
