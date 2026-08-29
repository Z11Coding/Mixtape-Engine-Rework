package undertale;

class UnderTextBox extends FlxTypedGroup<Dynamic> {
  // Default Settings
  final defaultText:Array<String> = ["You forgot the dialogue, silly!"];
  final defaultFont:String = "";
  final defaultSpeed:Float = 0.015;

  var box:FlxSprite;
  var boxB:FlxSprite;
	var underText:UnderTextParser;
  var underunderText:UnderTextParser;
	var daStatic:FlxSprite;

  public var targetW:Float = 810;
	public var targetH:Float = 200;
	public var boxX:Float = (1280 / 2) - 25;
	public var boxY:Float = (720 / 2) + 75;
  public var boxA:Float = 1;
  public var instant:Bool = false;
	var boxW:Float = 0;
	var boxH:Float = 0;

	var curDial:Int = 0;
  var curDialList:Array<String> = [];
  var alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];

  var curDial:Int = 0;

  override function new(font:String, sound:String, color:FlxColor, speed:Float) {
    super();

    curDial = 0;
    boxB = new FlxSprite().loadGraphic(Paths.image('ut/boxBorder'));
    box = new FlxSprite().loadGraphic(Paths.image('ut/box'));
    boxB.screenCenter();
    box.screenCenter();
    add(boxB);
    add(box);

    underText = new UnderTextParser(300, 400, Std.int(FlxG.width * 0.6), '', 32);
    underText.font = Paths.font(font);
    underText.color = 0xFFFFFFFF;
    underText.prefix = '* ';
    add(underText);
    if (sound == "GASTER") {
      for (letter in alphabet) {
        underText.soundOnChars.set(letter, FlxG.sound.load(Paths.sound('ut/snd-wngdng${FlxG.random.int(1, 7)}'), 1));
        underText.soundOnChars.set(letter.toUpperCase(), FlxG.sound.load(Paths.sound('ut/snd-wngdng${FlxG.random.int(1, 7)}'), 1));
      }
    } else {
      for (letter in alphabet) {
        underText.soundOnChars.set(letter, FlxG.sound.load(Paths.sound('ut/$sound'), 1));
        underText.soundOnChars.set(letter.toUpperCase(), FlxG.sound.load(Paths.sound('ut/$sound'), 1));
      }
    }
    underText.alpha = 0;

    underunderText = new UnderTextParser(300, 400, Std.int(FlxG.width * 0.6), '', 32);
		underunderText.font = Paths.font(font);
		underunderText.color = 0xFF4F4C4C;
		underunderText.prefix = '* ';
    underunderText.mute = true;
		add(underunderText);
    underunderText.alpha = (underText.alpha - 0.7);
  }


  function typeFunc(?text:String = '', ?sound:String = 'uifont', ?speed:Float = 0.2, hide:Bool = false)
  {
    var splitName:Array<String> = text.split("\n");
    var trueText:String = splitName[0];
    for (i in 0...splitName.length)
    {
      if (i > 0) trueText += '\n* ' + splitName[i];
    }

    if (hide)
    {
      underText.alpha = 0;
      underText.resetText('');
      underunderText.alpha = 0;
			underunderText.resetText('');
      box.visible = false;
      boxB.visible = false;
    }
    else
    {
      box.visible = true;
      boxB.visible = true;
      underText.alpha = 1;
      underText.resetText(trueText);
      underText.start(speed, true);
      underunderText.alpha = 0.3;
			underunderText.resetText(trueText);
			underunderText.start(speed, true);
    }
  }

  override function update(elapsed:Float)
  {
    if ((box != null && boxB != null) && (box.visible && boxB.visible) && box.scale.x != targetW) {
      var toW:Float = targetW;
      var toH:Float = targetH;

      boxW = boxW + ((toW - boxW) / (10 / (elapsed * 60)));
      boxH = boxH + ((toH - boxH) / (10 / (elapsed * 60)));

      if (Math.ceil(boxW) == toW || Math.floor(boxW) == toW) boxW = toW;
      if (Math.ceil(boxH) == toH || Math.floor(boxH) == toH) boxH = toH;

      box.scale.x = boxW / 100;
      box.scale.y = boxH / 100;

      boxB.scale.x = (boxW + 16) / 100;
      boxB.scale.y = (boxH + 16) / 100;

      box.x = boxX;
      box.y = boxY;
      boxB.x = boxX;
      boxB.y = boxY;

      box.alpha = boxA;
      boxB.alpha = boxA;
    }

    super.update(elapsed);
  }

}
