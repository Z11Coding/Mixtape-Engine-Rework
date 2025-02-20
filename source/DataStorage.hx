import haxe.macro.Context;

class DataStorage {
    // Static variable to store data
    static var storedData:Map<String, Dynamic> = new Map<String, Dynamic>();

    // Macro to store data
    public static macro function storeData(key:String, value:Dynamic):haxe.macro.Expr {
        // Store the data at compile time
        storedData.set(key, value);
        trace('Stored data: $value');
        return macro null; // No runtime code generation needed
    }

    // Macro to retrieve and print stored data (for demonstration)
    public static macro function retrieveDataAndPrint(key:String):haxe.macro.Expr {
        var value = storedData.get(key);
        Context.info('Retrieved data: $value', Context.currentPos());
        return macro null; // No runtime code generation needed
    }
}