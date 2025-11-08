package states.freeplay.vslice.capsule;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;

/**
 * Number display component for capsules
 * Adapted from P-Slice for Mixtape Engine
 */
class CapsuleNumber extends FlxSprite
{
	public var digit(default, set):Int = 0;

	function set_digit(val):Int
	{
		animation.play(numToString[val], true, false, 0);

		centerOffsets(false);

		switch (val)
		{
			case 1:
				offset.x -= 4;
			case 3:
				offset.x -= 1;

			case 6:

			case 4:
				// offset.y += 5;
			case 9:
				// offset.y += 5;
			default:
				centerOffsets(false);
		}
		return val;
	}

	public var baseY:Float = 0;
	public var baseX:Float = 0;

	var numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"];

	public function new(x:Float, y:Float, big:Bool = false, ?initDigit:Int = 0)
	{
		super(x, y);

		// Load number frames based on size
		var framesPath = big ? 'freeplay/freeplayCapsule/bignumbers' : 'freeplay/freeplayCapsule/smallnumbers';
		frames = Paths.getSparrowAtlas(framesPath, 'vslice');

		// Create fallback if frames don't exist
		if (frames == null) {
			// Create a simple colored rectangle as fallback
			makeGraphic(big ? 30 : 15, big ? 40 : 20, 0xFFFFFFFF);
		} else {
			for (i in 0...10)
			{
				var stringNum:String = numToString[i];
				animation.addByPrefix(stringNum, '$stringNum', 24, false);
			}
		}

		antialiasing = ClientPrefs.data.antialiasing;
		this.digit = initDigit;

		if (frames != null) {
			animation.play(numToString[initDigit], true);
		}

		setGraphicSize(Std.int(width * 0.9));
		updateHitbox();
	}
}
