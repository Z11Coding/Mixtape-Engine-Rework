package metadata;

// Mixtape Engine
typedef MetadataFile = {
    var song:SongMetaSection;
    var freeplay:FreeplayMeta;
}

typedef SongMetaSection = {
    var name:String;
    var artist:String;
    var charter:String;
    var mod:String;
}

typedef FreeplayMeta = {
    var bg:String;
    var album:String;
    var ratings:Map<String, Int>;
}

// V-Slice Compat
typedef VSliceMetadataFile = {
    var version:String;
    var timeFormat:String;
    var artist:String;
    var charter:String;
    var playData:VSlicePlayData;
    var timeChanges:Map<String, Dynamic>;
    var generatedBy:String;
}

typedef VSlicePlayData = {
    var stage:String;
    var characters:VSliceCharacterMeta;
    var songVariations:Array<String>;
    var difficulties:Array<String>;
    var ratings:Map<String, Int>;
    var noteStyle:String;
    var album:String;
    var previewStart:Int;
    var previewEnd:Int;
}

typedef VSliceCharacterMeta = {
    var player:String;
    var girlfriend:String;
    var opponent:String;
    var altInstrumentals:Array<String>;
}

// P-Slice Compat
class FreeplayMetaJSON {
    public function new() {}
    public var songRating:Int = -1;
    public var allowNewTag:Bool = false;
    public var allowErectVariants:Bool = false;
    public var freeplayPrevStart:Float = 0.0; // those are in seconds btw
    public var freeplayPrevEnd:Float = 10.0;// and this too
    public var freeplaySongLength:Float = 10;// and this too
    public var freeplayCharacter:String = "";
    public var albumId:String = "";
    public var altInstrumentalSongs:String = "";
    public var freeplayWeekName:String = "";
}

//Dustin Compat / Codename Metadata
typedef CodenameMetadata = {
	public var name:String;
	public var ?variant:String;
	public var ?displayName:String;

	public var ?bpm:Float;
	public var ?beatsPerMeasure:Float;
	public var ?stepsPerBeat:Int;

	public var ?difficulties:Array<String>;
	public var ?variants:Array<String>;
	public var ?customValues:Dynamic;

	public var ?icon:String;
	public var ?color:FlxColor;

	public var ?coopAllowed:Bool;
	public var ?opponentModeAllowed:Bool;

	public var ?metas:Map<String, ChartMetaData>;
	public var ?instSuffix:String;
	public var ?vocalsSuffix:String;
	public var ?needsVoices:Bool;
}
