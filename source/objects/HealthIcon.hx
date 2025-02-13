package objects;

enum abstract IconType(Int) to Int from Int //abstract so it can hold int values for the frame count
{
	var SINGLE = 0;
	var DEFAULT = 1;
	var WINNING = 2;
	//TODO: implement later
	var ANIMATED = 3;
	var SINGING = 4;
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var canBounce:Bool = false;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var type:IconType = DEFAULT;

	var initialWidth:Float = 0;
	var initialHeight:Float = 0;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);

		if(canBounce) {
			var mult:Float = FlxMath.lerp(1, scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old');
		else changeIcon(char);
	}

	public var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);

			if (file == null)
				file == Paths.image('icons/icon-face');
			else if (!Paths.fileExists('images/icons/icon-face.png', IMAGE)){
				file == Paths.image('icons/icon-bf');
				trace("Warning: could not find the placeholder icon, defaulting to bf");
			}
			else if (!Paths.fileExists('images/icons/icon-bf.png', IMAGE)){
				trace("Warning: could not find the placeholder icon or the backup icon, expect crashing!");
			}

			loadGraphic(file); //Load stupidly first for getting the file size
			type = (width < 200 ? SINGLE : ((width > 199 && width < 301) ? DEFAULT : WINNING));
			initialWidth = width;
			initialHeight = height;
			loadGraphic(file, true, Math.floor(width / (type+1)), Math.floor(height));
			iconOffsets[0] = iconOffsets[1] = (width - 150) / (type+1);
			var frames:Array<Int> = [];
			for (i in 0...type+1) frames.push(i);
			updateHitbox();

			animation.add(char, frames, 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.globalAntialiasing;
		}
	}

	public function bounce() {
		if(canBounce) {
			var mult:Float = 1.2;
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		if (ClientPrefs.data.iconBounceType != 'Golden Apple' && ClientPrefs.data.iconBounceType != 'Dave and Bambi' || !Std.isOfType(FlxG.state, states.PlayState))
		{
			super.updateHitbox();
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		} else {
			super.updateHitbox();
			if (initialWidth != (150 * animation.numFrames) || initialHeight != 150) //Fixes weird icon offsets when they're HUMONGUS (sussy)
			{
				offset.x = iconOffsets[0];
				offset.y = iconOffsets[1];
			}
		}

		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
