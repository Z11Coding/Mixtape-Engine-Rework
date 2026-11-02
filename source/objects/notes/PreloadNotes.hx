package objects.notes;

@:structInit class PreloadNotes
{
  public var strumTime:Float = 0;
  public var noteData:Int = 0;
	public var trueNoteData:Int = 0;
  public var mustPress:Bool = false;
  public var oppNote:Bool = false;
	public var noteType:String = "";
	public var animSuffix:String = "";
	public var noteskin:Null<String> = null;
	public var texture:Null<String> = null;
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var gfNote:Bool = false;
	public var exNote:Bool = false;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	public var sustainLength:Float = 0;
	public var parentST:Float = 0;
	public var parentSL:Float = 0;
	public var hitHealth:Float = 0;
	public var missHealth:Float = 0;
	public var hitCausesMiss:Bool = false;
	public var wasHit:Bool = false;
	public var multSpeed:Float = 1;
	public var multAlpha:Float = 1;
	public var noteDensity:Float = 1;
	public var ignoreNote:Bool = false;
	public var blockHit:Bool = false;
	public var lowPriority:Bool = false;
	public var row:Int = 0;
	@:optional public var rgbShader:RGBData;

	public function unregisterFromNoteRow():Void
	{
		var playfield = MegaManager.playfield;
		if (playfield == null || row < 0) return;

		var rows = playfield.noteRows[mustPress ? 0 : 1];
		if (row < rows.length && rows[row] != null)
		{
			rows[row].remove(this);
			if (rows[row].length == 0)
				rows[row] = null;
		}
	}

	public function registerInNoteRow():Void
	{
		var playfield = MegaManager.playfield;
		if (playfield == null || row < 0) return;

		var rows = playfield.noteRows[mustPress ? 0 : 1];
		if (rows[row] == null)
			rows[row] = [];
		if (!rows[row].contains(this))
			rows[row].push(this);
	}

	public function dispose() {
		// will be cleared by the GC later
		for (field in Reflect.fields(this)) {
			Reflect.setField(this, field, null);
		}
	}
}

typedef RGBData = {
	r:FlxColor,
	g:FlxColor,
	b:FlxColor
}
