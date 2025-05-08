package metadata;

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