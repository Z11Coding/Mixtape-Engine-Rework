package shapeEx;

class Triangle extends FlxSprite
{
	public function new(X:Float, Y:Float, Size:Float, Inner:Float)
	{
		super(X, Y);

		loadGraphic(drawHollowTriangle(Size, Inner));
		antialiasing = ClientPrefs.data.antialiasing;
	}

	function drawHollowTriangle(sideLength:Float, innerSide:Float):BitmapData
	{
		var shape:Shape = new Shape();

		// 图像的宽度和高度，确保三角形在图像中居中
		var imageSize:Float = sideLength * Math.sqrt(3); // 等边三角形的高为边长的sqrt(3)/2，乘以2得到图像大小
		// 图像中心点
		var centerX:Float = imageSize / 2;
		var centerY:Float = imageSize / 2 + 5; // +5 是修复bug

		// 计算等边三角形的三个顶点位置，确保中心位于图像中心
		var angleStep:Float = Math.PI * 2 / 3; // 顶点之间的角度差为120度，即2π/3
		var p1:Point = new Point(centerX + sideLength * Math.cos(0), centerY + sideLength * Math.sin(0));
		var p2:Point = new Point(centerX + sideLength * Math.cos(angleStep), centerY + sideLength * Math.sin(angleStep));
		var p3:Point = new Point(centerX + sideLength * Math.cos(angleStep * 2), centerY + sideLength * Math.sin(angleStep * 2));

		// 绘制外部三角形
		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.lineStyle(3, 0xFFFFFF, 1);
		shape.graphics.moveTo(p1.x, p1.y);
		shape.graphics.lineTo(p2.x, p2.y);
		shape.graphics.lineTo(p3.x, p3.y);
		shape.graphics.lineTo(p1.x, p1.y);
		shape.graphics.endFill();

		// 绘制内部三角形
		var innerSideLength:Float = sideLength * (1 - innerSide);
		var innerP1:Point = new Point(centerX + innerSideLength * Math.cos(0), centerY + innerSideLength * Math.sin(0));
		var innerP2:Point = new Point(centerX + innerSideLength * Math.cos(angleStep), centerY + innerSideLength * Math.sin(angleStep));
		var innerP3:Point = new Point(centerX + innerSideLength * Math.cos(angleStep * 2), centerY + innerSideLength * Math.sin(angleStep * 2));

		shape.graphics.beginFill(0x00); // 设置填充颜色为透明
		shape.graphics.moveTo(innerP1.x, innerP1.y);
		shape.graphics.lineTo(innerP2.x, innerP2.y);
		shape.graphics.lineTo(innerP3.x, innerP3.y);
		shape.graphics.lineTo(innerP1.x, innerP1.y);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Std.int(imageSize * 1.2), Std.int(imageSize * 1.2), true, 0);
		bitmap.draw(shape);
		return bitmap;
	}
}
