package stages.objects;

//This is stupid
class Sniper extends BGSprite
{
	public function new(x:Float = 0, y:Float = 0, sprite:String = 'erect/sniper', idle:String = 'Tankmanidlebaked instance 1', sip:String = 'tanksippingBaked instance 1')
	{
		super(sprite, x, y, 0.9, 0.9, [idle]);
		animation.addByPrefix('sip', sip, 24, false);
		antialiasing = ClientPrefs.data.antialiasing;
	}
}