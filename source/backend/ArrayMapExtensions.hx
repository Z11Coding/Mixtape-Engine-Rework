package backend;


enum ExtensionOption {
	Values;
	Keys;
	Both;
}

class ArrayMapExtensions {
    // 1. Array Extension for Single-Item Functions
    public static function applyFunctionToArray<T>(arr:Array<T>, func:T->Void):Void {
        for (item in arr) {
            func(item);
        }
    }

    // 2. Function Extension for Arrays
    public static function extendFunctionForArray<T>(func:T->Void):Array<T>->Void {
        return function(arr:Array<T>):Void {
            for (item in arr) {
                func(item);
            }
        };
    }

    // 3. Dynamic Array Extensions
    public static function applyDynamicFunctions(arr:Array<Dynamic>, typeFuncs:Map<String, Dynamic->Void>):Void {
        for (item in arr) {
            var typeName:String = Type.getClassName(Type.getClass(item));
            if (typeFuncs.exists(typeName)) {
                typeFuncs.get(typeName)(item);
            }
        }
    }

    // 4. Map Extensions
    public static function applyFunctionToMap<K, V>(map:Map<K, V>, func:Dynamic->Void, option:ExtensionOption):Void {
        switch option {
            case Values:
                for (value in map) {
                    func(value);
                }
            case Keys:
                for (key in map.keys()) {
                    func(key);
                }
            case Both:
                for (key in map.keys()) {
                    func(key);
                    func(map.get(key));
                }
        }
    }

    // 5. Array Extension for Single-Item Functions with Return
    public static function applyFunctionToArrayWithReturn<T, R>(arr:Array<T>, func:T->R):Array<R> {
        var result:Array<R> = [];
        for (item in arr) {
            result.push(func(item));
        }
        return result;
    }

    // 6. Function Extension for Arrays with Return
    public static function extendFunctionForArrayWithReturn<T, R>(func:T->R):Array<T>->Array<R> {
        return function(arr:Array<T>):Array<R> {
            var result:Array<R> = [];
            for (item in arr) {
                result.push(func(item));
            }
            return result;
        };
    }

    // 7. Map Extension with Return
    public static function applyFunctionToMapWithReturn<K, V, R>(map:Map<K, V>, func:Dynamic->R, option:ExtensionOption):Array<R> {
        var result:Array<R> = [];
        switch option {
            case Values:
                for (value in map) {
                    result.push(func(value));
                }
            case Keys:
                for (key in map.keys()) {
                    result.push(func(key));
                }
            case Both:
                for (key in map.keys()) {
                    result.push(func(key));
                    result.push(func(map.get(key)));
                }
        }
        return result;
    }
}

