package backend;

typedef MetadataFile = {
    var song:SongMetaSection;
}

typedef SongMetaSection = {
    var name:String;
    var artist:String;
    var charter:String;
    var mod:String;
}