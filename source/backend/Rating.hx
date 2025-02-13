package backend;

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var counter:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var score:Int = 500;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.counter = name + 's';
		this.hitWindow = Reflect.field(ClientPrefs, name + 'Window');
		if(hitWindow == null)
		{
			hitWindow = 0;
		}
	}

	public static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [];

		if (!ClientPrefs.data.noPerfectJudge)
		{
			ratingsData.push(new Rating('perfect'));
		}

		if (ClientPrefs.data.useMarvs)
		{			
			var rating:Rating = new Rating('marverlous');
			rating.ratingMod = 1;
			rating.score = 400;
			rating.noteSplash = true;
			ratingsData.push(rating);
		}

		var rating:Rating = new Rating('sick');
		rating.ratingMod = 1;
		rating.score = 350;
		rating.noteSplash = true;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);
		return ratingsData;
	}
	
	public function increase(blah:Int = 1)
	{
		Reflect.setField(states.PlayState.instance, counter, Reflect.field(states.PlayState.instance, counter) + blah);
	}
}