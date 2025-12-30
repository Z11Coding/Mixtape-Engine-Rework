package yutautil.typeregistry;

/**
 * Auto-generated type collection data accessor
 * Generated at: 2025-12-30 00:08:25
 */
class TypeCollectionAccessor {
    public static var buildTimestamp:Float = 1.767071277e+012;
    public static var targetPlatform:String = "cpp";
    public static var classCount:Int = 977;
    public static var abstractCount:Int = 532;
    public static var functionCount:Int = 8468;
    public static var enumCount:Int = 196;
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
