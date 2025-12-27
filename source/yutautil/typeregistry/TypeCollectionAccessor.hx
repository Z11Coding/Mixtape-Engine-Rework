package yutautil.typeregistry;

/**
 * Auto-generated type collection data accessor
 * Generated at: 2025-12-27 17:32:58
 */
class TypeCollectionAccessor {
    public static var buildTimestamp:Float = 1.766874663e+012;
    public static var targetPlatform:String = "cpp";
    public static var classCount:Int = 965;
    public static var abstractCount:Int = 539;
    public static var functionCount:Int = 8370;
    public static var enumCount:Int = 197;
    public static var typedefCount:Int = 730;
    
    public static function getDataPath():String {
        return "export/builddata/type_collection_compressed.json";
    }
    
    public static function getFullDataPath():String {
        return "export/builddata/type_collection_data.json";
    }
    
    public static function isDataAvailable():Bool {
        return sys.FileSystem.exists(getDataPath());
    }
}
