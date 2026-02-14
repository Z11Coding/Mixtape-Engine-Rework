package psychlua;

import stages.objects.PerspectiveSprite;

class ModchartPerspectiveSprite extends PerspectiveSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public function new()
	{
		super(false);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		animation.play(name, forced, reverse, startFrame);

		var daOffset = animOffsets.get(name);
		if (animOffsets.exists(name)) offset.set(daOffset[0], daOffset[1]);
	}

	public function addOffset(name:String, x:Float, y:Float)
	{
		animOffsets.set(name, [x, y]);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		this.updateSkew(this.cameras[0]);
	}
}
