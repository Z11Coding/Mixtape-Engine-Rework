package yutautil.typeregistry;

/**
 * Auto-generated type collection data accessor
 * Generated at: 2025-12-27 21:57:50
 */
class TypeCollectionAccessor {
    public static var buildTimestamp:Float = 1.766890642e+012;
    public static var targetPlatform:String = "cpp";
    public static var classCount:Int = 976;
    public static var abstractCount:Int = 529;
    public static var functionCount:Int = 8442;
    public static var enumCount:Int = 196;
    public static var typedefCount:Int = 719;

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
