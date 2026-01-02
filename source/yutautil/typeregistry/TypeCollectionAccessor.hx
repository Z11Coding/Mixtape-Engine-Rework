package yutautil.typeregistry;

/**
 * Auto-generated type collection data accessor
 * Generated at: 2026-01-01 00:07:48
 */
class TypeCollectionAccessor {
    public static var buildTimestamp:Float = 1.76724404e+012;
    public static var targetPlatform:String = "cpp";
    public static var classCount:Int = 984;
    public static var abstractCount:Int = 532;
    public static var functionCount:Int = 8516;
    public static var enumCount:Int = 197;
    public static var typedefCount:Int = 720;
    
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
