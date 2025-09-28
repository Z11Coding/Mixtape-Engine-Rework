package shapeEx;

package shapeEx;

enum OriginType
{
	LEFT_UP;
  LEFT_CENTER;
	LEFT_DOWN;

  CENTER_UP;
  CENTER_CENTER;
  CENTER_DOWN;

  RIGHT_UP;
  RIGHT_CENTER;
  RIGHT_DOWN;
}

class RoundRect extends FlxSpriteGroup
{
	public var mainColor:FlxColor;
	public var mainWidth:Float; //获取的初始宽度，不可更改否则可能会有问题
	public var mainHeight:Float; //获取的初始高度，不可更改否则可能会有问题
	public var mainRound:Float; //获取的初始圆角，不可更改否则可能会有问题
	public var mainX:Float; //可更改，如果用于flxspritegroup需要重新输入
	public var mainY:Float; //可更改，如果用于flxspritegroup需要重新输入

	public var realWidth:Float; //建议从这里获取真实数据
	public var realHeight:Float; //建议从这里获取真实数据
	public var waitWidth:Float; //建议从这里获取即将到的数据
	public var waitHeight:Float; //建议从这里获取即将到的数据

	////////////////////////////////////////////////////////////////////////////////

	var widthEase:String;
	var heightEase:String;

  public var originType:OriginType;

	////////////////////////////////////////////////////////////////////////////////

	var leftUpRound:BaseSprite;
	var midUpRect:BaseSprite;
	var rightUpRound:BaseSprite;

	var midRect:BaseSprite;

	var leftDownRound:BaseSprite;
	var midDownRect:BaseSprite;
	var rightDownRound:BaseSprite;

  public function new(X:Float, Y:Float, width:Float = 0, height:Float = 0, round:Float, ease:OriginType = LEFT_UP, color:FlxColor = 0xffffff)
  {
      super(X, Y);
      this.mainColor = color;
      mainX = X;
      mainY = Y;
      originType = ease;

		leftUpRound = drawRoundRect(0, 0, round, round, round, 1);
		add(leftUpRound);
		midUpRect = drawRect(leftUpRound.width, 0, width - round * 2, round);
		add(midUpRect);
		rightUpRound = drawRoundRect(leftUpRound.width + midUpRect.width, 0, round, round, round, 2);
		add(rightUpRound);

		midRect = drawRect(0, leftUpRound.height, leftUpRound.width + midUpRect.width + rightUpRound.width, height - round * 2);
		add(midRect);

		leftDownRound = drawRoundRect(0, leftUpRound.height + midRect.height, round, round, round, 3);
		add(leftDownRound);
		midDownRect = drawRect(leftDownRound.width, leftUpRound.height + midRect.height, width - round * 2, round);
		add(midDownRect);
		rightDownRound = drawRoundRect(leftDownRound.width + midDownRect.width, leftUpRound.height + midRect.height, round, round, round, 4);
		add(rightDownRound);

		realWidth = mainWidth = midRect.width;
        realHeight = mainHeight = leftUpRound.height + midRect.height + leftDownRound.height;
		waitWidth = realWidth;
		waitHeight = realHeight;
		mainRound = Std.int(round);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		realWidth = midRect.width * midRect.scale.x;
    realHeight = leftUpRound.height * leftUpRound.scale.y + midRect.height * midRect.scale.y + leftDownRound.height * leftDownRound.scale.y;
	}

	//////////////////////////////////////////////////////

	public function changeWidth(data:Float, time:Float = 0.6, ease:String = 'backInOut')
	{
		waitWidth = data;
		if (time == 0) setChangeWidth(data);
    else tweenChangeWidth(data, time, ease);
  }

	function setChangeWidth(data:Float) {
    switch(originType)
    {
      case LEFT_UP, LEFT_CENTER, LEFT_DOWN:
          var output:Float = calcData(mainWidth, data, mainRound);
          midUpRect.scale.x = output;

          midUpRect.setX(mainX, - (mainWidth - data - mainRound * 2) / 2);
          rightUpRound.setX(mainX, data - mainRound);

          var output:Float = calcData(mainWidth, data, 0);
          midRect.scale.x = output;
          midRect.setX(mainX, - (mainWidth - data) / 2);

          var output:Float = calcData(mainWidth, data, mainRound);
          midDownRect.scale.x = output;
          midDownRect.setX(mainX, - (mainWidth - data - mainRound * 2) / 2);
          rightDownRound.setX(mainX, data - mainRound);


      case CENTER_UP, CENTER_CENTER, CENTER_DOWN:
        leftUpRound.setX(mainX, - (data - mainWidth) / 2);

        var output:Float = calcData(mainWidth, data, mainRound);
        midUpRect.scale.x = output;
        rightUpRound.setX(mainX, (mainWidth + data) / 2 - mainRound);

        var output:Float = calcData(mainWidth, data, 0);
        midRect.scale.x = output;

        leftDownRound.setX(mainX, - (data - mainWidth) / 2);
        var output:Float = calcData(mainWidth, data, mainRound);
        midDownRect.scale.x = output;
        rightDownRound.setX(mainX, (mainWidth + data) / 2 - mainRound);

      case RIGHT_UP, RIGHT_CENTER, RIGHT_DOWN:
        var output:Float = calcData(mainWidth, data, mainRound);
        midUpRect.scale.x = output;
        midUpRect.setX(mainX, (mainWidth - data) / 2 + mainRound);
        leftUpRound.setX(mainX, mainWidth - data);

        var output:Float = calcData(mainWidth, data, 0);
        midRect.scale.x = output;
        midRect.setX(mainX, (mainWidth - data) / 2);

        var output:Float = calcData(mainWidth, data, mainRound);
        midDownRect.scale.x = output;
        midDownRect.setX(mainX, (mainWidth - data) / 2 + mainRound);
        leftDownRound.setX(mainX, mainWidth - data);
    }
      realWidth = midRect.width * midRect.scale.x;
  }

  var widthTweenArray:Array<FlxTween> = [];
  public function tweenChangeWidth(data:Float, time:Float = 0.6, ease:String = 'backInOut') {
    widthEase = ease;
    for (i in 0...widthTweenArray.length)
    {
      if (widthTweenArray[i] != null) widthTweenArray[i].cancel();
    }
    widthTweenArray = [];

    switch(originType)
    {
      case LEFT_UP, LEFT_CENTER, LEFT_DOWN:
        var output:Float = calcData(mainWidth, data, mainRound);
        widthScaleTween(midUpRect.scale, output, time, widthEase);
        widthBaseTween(midUpRect, mainX - (mainWidth - data - mainRound * 2) / 2, time, widthEase);
        widthBaseTween(rightUpRound, data - mainRound, time, widthEase);

        var output:Float = calcData(mainWidth, data, 0);
        widthScaleTween(midRect.scale, output, time, widthEase);
        widthBaseTween(midRect, mainX - (mainWidth - data) / 2, time, widthEase);

        var output:Float = calcData(mainWidth, data, mainRound);
        widthScaleTween(midDownRect.scale, output, time, widthEase);
        widthBaseTween(midDownRect, mainX - (mainWidth - data - mainRound * 2) / 2, time, widthEase);
        widthBaseTween(rightDownRound, data - mainRound, time, widthEase);


      case CENTER_UP, CENTER_CENTER, CENTER_DOWN:
        widthBaseTween(leftUpRound, mainX - (data - mainWidth) / 2, time, widthEase);
        var output:Float = calcData(mainWidth, data, mainRound);
        widthScaleTween(midUpRect.scale, output, time, widthEase);
        widthBaseTween(rightUpRound, (mainWidth + data) / 2 - mainRound, time, widthEase);

        var output:Float = calcData(mainWidth, data, 0);
        widthScaleTween(midRect.scale, output, time, widthEase);

        widthBaseTween(leftDownRound, mainX - (data - mainWidth) / 2, time, widthEase);
        var output:Float = calcData(mainWidth, data, mainRound);
        widthScaleTween(midDownRect.scale, output, time, widthEase);
        widthBaseTween(rightDownRound, (mainWidth + data) / 2 - mainRound, time, widthEase);


      case RIGHT_UP, RIGHT_CENTER, RIGHT_DOWN:
        var output:Float = calcData(mainWidth, data, mainRound);
        widthScaleTween(midUpRect.scale, output, time, widthEase);
        widthBaseTween(midUpRect, (mainWidth - data) / 2 + mainRound, time, widthEase);
        widthBaseTween(leftUpRound, mainWidth - data, time, widthEase);

        var output:Float = calcData(mainWidth, data, 0);
        widthScaleTween(midRect.scale, output, time, widthEase);
        widthBaseTween(midRect, (mainWidth - data) / 2, time, widthEase);

        var output:Float = calcData(mainWidth, data, mainRound);
        widthScaleTween(midDownRect.scale, output, time, widthEase);
        widthBaseTween(midDownRect, (mainWidth - data) / 2 + mainRound, time, widthEase);
        widthBaseTween(leftDownRound, mainWidth - data, time, widthEase);
    }
  }

	function widthScaleTween(tag:Dynamic, duration:Float, time:Float, easeType:String)
	{
		var tween = FlxTween.tween(tag, {x: duration}, time, {ease: getTweenEaseByString(easeType)});
		widthTweenArray.push(tween);
	}

	function widthBaseTween(tag:Dynamic, duration:Float, time:Float, easeType:String)
	{
		var tween = FlxTween.num(tag.moveX, duration, time, {ease: getTweenEaseByString(easeType)}, function(v){tag.x = mainX + v; tag.moveX = v;});
		widthTweenArray.push(tween);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function changeHeight(data:Float, time:Float = 0.6, ease:String = 'backInOut')
	{
		waitHeight = data;
		if (time == 0) setChangeHeight(data);
		else tweenChangeHeight(data, time, ease);
  }

	function setChangeHeight(data:Float) {
		switch(originType)
    {
      case LEFT_UP, CENTER_UP, RIGHT_UP :
        var output:Float = calcData(mainHeight, data, mainRound);
        midRect.scale.y = output;

				midRect.setY(mainY, - (mainHeight - data - mainRound * 2) / 2);

				leftDownRound.setY(mainY, data - mainRound);
        midDownRect.setY(mainY, data - mainRound);
				rightDownRound.setY(mainY, data - mainRound);

      case LEFT_CENTER, CENTER_CENTER, RIGHT_CENTER:
        var output:Float = calcData(mainHeight, data, mainRound);
        midRect.scale.y = output;

				leftUpRound.setY(mainY, (mainHeight - data) / 2);
				midUpRect.setY(mainY, (mainHeight - data) / 2);
				rightUpRound.setY(mainY, (mainHeight - data) / 2);

				leftDownRound.setY(mainY, (mainHeight + data) / 2 - mainRound);
        midDownRect.setY(mainY, (mainHeight + data) / 2 - mainRound);
				rightDownRound.setY(mainY, (mainHeight + data) / 2 - mainRound);

      case LEFT_DOWN, CENTER_DOWN, RIGHT_DOWN:
        var output:Float = calcData(mainHeight, data, mainRound);
        midRect.scale.y = output;
        midRect.setY(mainY, (mainHeight - data) / 2 + mainRound);

				leftUpRound.setY(mainY, height - data);
        midUpRect.setY(mainY, height - data);
				rightUpRound.setY(mainY, height - data);
    }
    realHeight = leftUpRound.height * leftUpRound.scale.y + midRect.height * midRect.scale.y + leftDownRound.height * leftDownRound.scale.y;
	}

	var heightTweenArray:Array<FlxTween> = [];
	function tweenChangeHeight(data:Float, time:Float = 0.6, ease:String = 'backInOut')
	{
		heightEase = ease;
		for (i in 0...heightTweenArray.length)
		{
			if (heightTweenArray[i] != null)
				heightTweenArray[i].cancel();
		}
		heightTweenArray = [];
    switch(originType)
    {
      case LEFT_UP, CENTER_UP, RIGHT_UP :
        var output:Float = calcData(mainHeight, data, mainRound);
        heightScaleTween(midRect.scale, output, time, heightEase);
        heightBaseTween(midRect, - (mainHeight - data - mainRound * 2) / 2, time, heightEase);

        heightBaseTween(leftDownRound, data - mainRound, time, heightEase);
        heightBaseTween(midDownRect, data - mainRound, time, heightEase);
        heightBaseTween(rightDownRound, data - mainRound, time, heightEase);


      case LEFT_CENTER, CENTER_CENTER, RIGHT_CENTER:
        var output:Float = calcData(mainHeight, data, mainRound);
        heightScaleTween(midRect.scale, output, time, heightEase);

        heightBaseTween(leftUpRound, (mainHeight - data) / 2, time, heightEase);
        heightBaseTween(midUpRect, (mainHeight - data) / 2, time, heightEase);
        heightBaseTween(rightUpRound, (mainHeight - data) / 2, time, heightEase);

        heightBaseTween(leftDownRound, (mainHeight + data) / 2 - mainRound, time, heightEase);
        heightBaseTween(midDownRect, (mainHeight + data) / 2 - mainRound, time, heightEase);
        heightBaseTween(rightDownRound, (mainHeight + data) / 2 - mainRound, time, heightEase);


      case LEFT_DOWN, CENTER_DOWN, RIGHT_DOWN:
        var output:Float = calcData(mainHeight, data, mainRound);
        heightScaleTween(midRect.scale, output, time, heightEase);
        heightBaseTween(midRect, (mainHeight - data) / 2 + mainRound, time, heightEase);

        heightBaseTween(leftUpRound, height - data, time, heightEase);
        heightBaseTween(midUpRect, height - data, time, heightEase);
        heightBaseTween(rightUpRound, height - data, time, heightEase);
    }
  }

	function heightScaleTween(tag:Dynamic, duration:Float, time:Float, easeType:String)
	{
		var tween = FlxTween.tween(tag, {y: duration}, time, {ease: getTweenEaseByString(easeType)});
		heightTweenArray.push(tween);
	}

	function heightBaseTween(tag:Dynamic, duration:Float, time:Float, easeType:String)
	{
		var tween = FlxTween.num(tag.moveY, duration, time, {ease: getTweenEaseByString(easeType)}, function(v){tag.y = mainY + v; tag.moveY = v;});
		heightTweenArray.push(tween);
	}

	//////////////////////////////////////////////////////////

	function calcData(init:Float, target:Float, assist:Float):Float
	{
		return (target - assist * 2) / (init - assist * 2);
	}

	function drawRoundRect(x:Float, y:Float, width:Float = 0, height:Float = 0, round:Float = 0, type:Int):BaseSprite
	{
		var sprite:BaseSprite = new BaseSprite(x, y);
		if (Cache.currentTrackedFrames.get('roundRect-round' +type+'-w'+width+'-h:'+height) == null) addRoundCache(width, height, round, type);
		sprite.frames = Cache.currentTrackedFrames.get('roundRect-round' +type+'-w'+width+'-h:'+height);
		return sprite;
	}

	function addRoundCache(width:Float = 0, height:Float = 0, round:Float = 0, type:Int) {
		var dataArray:Array<Float> = [0, 0, 0, 0];
		dataArray[type - 1] = round; // 选择哪个角，（左上，右上，左下，右下）

		var shape:Shape = new Shape();
		shape.graphics.beginFill(mainColor);
		shape.graphics.drawRoundRectComplex(0, 0, width, height, dataArray[0], dataArray[1], dataArray[2], dataArray[3]);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0);
		bitmap.draw(shape);

		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		Cache.currentTrackedFrames.set('roundRect-round' +type+'-w'+width+'-h:'+height, newGraphic.imageFrame);
	}

	function drawRect(x:Float, y:Float, width:Float = 0, height:Float = 0):BaseSprite
	{
		var sprite:BaseSprite = new BaseSprite(x, y);
		if (Cache.currentTrackedFrames.get('roundRect-rect-w'+width+'-h:'+height) == null) addRectCache(width, height);
		sprite.frames = Cache.currentTrackedFrames.get('roundRect-rect-w'+width+'-h:'+height);
		return sprite;
	}

	function addRectCache(width:Float = 0, height:Float = 0) {
		var shape:Shape = new Shape();
		shape.graphics.beginFill(mainColor);
		shape.graphics.drawRect(0, 0, width, height);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0);
		bitmap.draw(shape);

		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		Cache.currentTrackedFrames.set('roundRect-rect-w'+width+'-h:'+height, newGraphic.imageFrame);
	}

	public static function getTweenEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}
}

class BaseSprite extends FlxSprite {
	public var moveX:Float = 0;
	public var moveY:Float = 0;

	public function new(x:Float, y:Float) {
		super(x, y);
		moveX = x;
		moveY = y;
	}

	public function setX(main:Float, off:Float):Void {
		this.x = main + off;
		moveX = off;
	}

	public function setY(main:Float, off:Float):Void {
		this.y = main + off;
		moveY = off;
	}
}
