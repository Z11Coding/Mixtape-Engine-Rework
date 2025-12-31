package yutautil.typeregistry;

/**
 * Auto-generated type collection data accessor
 * Generated at: 2025-12-31 04:00:01
 */
class TypeCollectionAccessor {
    public static var buildTimestamp:Float = 1.767171113e+012;
    public static var targetPlatform:String = "cpp";
    public static var classCount:Int = 978;
    public static var abstractCount:Int = 542;
    public static var functionCount:Int = 8484;
    public static var enumCount:Int = 198;
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
