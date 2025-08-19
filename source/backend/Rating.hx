package backend;

import backend.ClientPrefs;

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var score:Int = 400;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;
	public var moraleFactor:Float = 3;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.hitWindow = 0;

		var window:String = name + 'Window';
		try
		{
			this.hitWindow = Reflect.field(ClientPrefs.data, window);
		}
		catch(e) FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [new Rating('marv')]; //highest rating goes first
		
		var rating:Rating = new Rating('sick');
		rating.ratingMod = 0.88;
		rating.score = 350;
		rating.noteSplash = true;
		rating.moraleFactor = 2.75;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.67;
		rating.score = 200;
		rating.noteSplash = false;
		rating.moraleFactor = 1.15;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.34;
		rating.score = 100;
		rating.noteSplash = false;
		rating.moraleFactor = Math.sqrt(3);
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		rating.moraleFactor = 0.05;
		ratingsData.push(rating);
		return ratingsData;
	}
}
