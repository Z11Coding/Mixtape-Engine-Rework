package objects;

class GlitchyText extends FlxText
{
	public override function new(x:Float = 0, y:Float = 0)
	{
		super(x, y, 0, "", 32);

		var fullColor = FlxColor.interpolate(FlxColor.RED, FlxColor.BLACK,
			Math.min(FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music.length * 0.8, 0, 1), 1));
		var outlineColor = FlxColor.interpolate(FlxColor.BLACK, FlxColor.RED,
			Math.min(FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music.length * 0.8, 0, 1), 1));

		setFormat(Paths.font("vcr.ttf"), 32, fullColor, LEFT, OUTLINE, outlineColor);
		borderSize = 1.75;

		alpha = 0.0;

		if (FlxG.random.int(10, 20) < 10)
		{
			velocity.y += FlxG.random.float(70, 180) * FlxG.random.sign();
		}
		else
		{
			velocity.x += FlxG.random.float(70, 180) * FlxG.random.sign();
		}
	}

	var updateCounter:Float = 0;
	var lifeCounter:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		lifeCounter += elapsed;
		if (lifeCounter >= 16)
		{
			if ((alpha -= elapsed) <= 0)
				destroy();
		}
		else
			alpha += elapsed * 1.5;

		while ((updateCounter += elapsed) >= 1 / 20)
		{
			_generateRandomSymbols();
			updateCounter -= 1 / 20;
		}
	}

	static var availSymbols:String = 'abcdefghijklmnopqrstuvwxyz1234567890';

	private function _generateRandomSymbols():Void
	{
		var newText:String = '';

		for (i in 0...14)
		{
			newText += availSymbols.charAt(Math.ceil(Math.random() * availSymbols.length - 1));
		}

		text = newText;
	}
}