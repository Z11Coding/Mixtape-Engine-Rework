package yutautil;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxTimer;
import haxe.Timer;

/**
 * Anomaly - A corruption system that randomly modifies values in the current state
 * Uses direct reflection to traverse and modify live object properties
 */
class Anomoly {
    private var timer:FlxTimer;
    private var isActive:Bool = false;
    private var corruptionIntensity:Float = 0.1; // 0.0 to 1.0 - chance to corrupt each eligible field
    private var intervalSeconds:Float = 1.0; // How often to run corruption
    private var maxDepth:Int = 4; // Maximum object traversal depth to prevent infinite loops

    // Lists of field patterns to target or avoid
    private var targetPatterns:Array<String> = [
        "speed", "velocity", "acceleration", "x", "y", "alpha", "scale", "angle", "health", "score",
        "volume", "pitch", "time", "progress", "width", "height", "size", "visible", "rotation"
    ];

    private var avoidPatterns:Array<String> = [
        "camera", "state", "parent", "group", "class", "type", "id", "name", "path", "file",
        "sprite", "graphic", "texture", "sound", "music", "timer", "tween", "animation", "callback",
        "function", "method", "event", "listener", "members", "length", "exists", "active", "alive"
    ];

    // Track corrupted objects to avoid infinite loops
    private var visitedObjects:Map<Dynamic, Bool> = new Map();
    private var corruptedPaths:Array<String> = [];

    public function new(?intensity:Float = 0.1, ?interval:Float = 1.0) {
        this.corruptionIntensity = intensity;
        this.intervalSeconds = interval;
    }

    public function activate():Void {
        if (!isActive) {
            isActive = true;
            trace('Anomaly activated with intensity ${corruptionIntensity} and interval ${intervalSeconds}s');
            startCorruptionTimer();
        }
    }

    public function deactivate():Void {
        if (isActive) {
            isActive = false;
            if (timer != null) {
                timer.cancel();
                timer.destroy();
                timer = null;
            }
            trace('Anomaly deactivated');
        }
    }

    public function setIntensity(newIntensity:Float):Void {
        corruptionIntensity = Math.max(0.0, Math.min(1.0, newIntensity));
        trace('Anomaly intensity set to ${corruptionIntensity}');
    }

    public function setInterval(newInterval:Float):Void {
        intervalSeconds = Math.max(0.1, newInterval);
        if (isActive) {
            // Restart timer with new interval
            deactivate();
            activate();
        }
        trace('Anomaly interval set to ${intervalSeconds}s');
    }

    private function startCorruptionTimer():Void {
        timer = new FlxTimer().start(intervalSeconds, function(t:FlxTimer) {
            if (isActive) {
                performCorruption();
                // Restart timer for continuous corruption
                startCorruptionTimer();
            }
        });
    }

    public function performCorruption(?traceOutput:Bool = false):Void {
        if (FlxG.state == null) return;

        try {
            // Reset tracking for this corruption cycle
            visitedObjects.clear();
            corruptedPaths = [];

            // Start corrupting from the current state
            corruptObjectProperties(FlxG.state, "", 0, traceOutput);

            if (traceOutput && corruptedPaths.length > 0) {
                trace('Anomaly corrupted ${corruptedPaths.length} properties this cycle');
            }
        } catch (e:Dynamic) {
            if (traceOutput) trace('Anomaly corruption error: ${e}');
        }
    }

    /**
     * Recursively traverse an object and corrupt its properties
     */
    private function corruptObjectProperties(obj:Dynamic, basePath:String, depth:Int, traceOutput:Bool):Void {
        if (obj == null || depth >= maxDepth) return;

        // Prevent infinite loops by tracking visited objects
        if (visitedObjects.exists(obj)) return;
        visitedObjects.set(obj, true);

        try {
            // Get all fields of this object
            var fields = Reflect.fields(obj);

            for (fieldName in fields) {
                if (!shouldProcessField(obj, fieldName)) continue;

                var fullPath = basePath == "" ? fieldName : basePath + "." + fieldName;
                var currentValue = Reflect.getProperty(obj, fieldName);

                if (currentValue == null) continue;

                // Decide whether to corrupt this field or traverse deeper
                if (Math.random() < corruptionIntensity && shouldCorruptField(fieldName) && isCorruptibleValue(currentValue)) {
                    // Corrupt this field
                    var newValue = corruptValue(currentValue, fieldName);
                    if (newValue != null) {
                        try {
                            Reflect.setProperty(obj, fieldName, newValue);
                            corruptedPaths.push(fullPath);
                            if (traceOutput) {
                                trace('Anomaly corrupted ${fullPath}: ${currentValue} -> ${newValue}');
                            }
                        } catch (e:Dynamic) {
                            // Ignore reflection errors (read-only properties, etc.)
                        }
                    }
                } else if (shouldTraverseObject(currentValue, fieldName)) {
                    // Traverse deeper into this object
                    corruptObjectProperties(currentValue, fullPath, depth + 1, traceOutput);
                }
            }
        } catch (e:Dynamic) {
            // Ignore reflection errors
        }
    }

    private function shouldProcessField(obj:Dynamic, fieldName:String):Bool {
        // Only skip functions and the self-recursive constructor field
        if (fieldName == "_constructor") return false;

        try {
            // Check if the field value is a function
            var value = Reflect.getProperty(obj, fieldName);
            var type = Type.typeof(value);
            if (type == TFunction) return false;
        } catch (e:Dynamic) {
            // If we can't check the type, allow processing
        }

        return true;
    }

    private function shouldCorruptField(fieldName:String):Bool {
        // Only skip the constructor field - allow everything else
        if (fieldName == "_constructor") return false;

        // Check if field contains any target patterns (higher priority)
        var lowerFieldName = fieldName.toLowerCase();
        for (pattern in targetPatterns) {
            if (lowerFieldName.indexOf(pattern.toLowerCase()) >= 0) {
                return true;
            }
        }

        // Allow corruption of any other field with reduced intensity
        return Math.random() < (corruptionIntensity * 0.3);
    }

    private function shouldTraverseObject(value:Dynamic, fieldName:String):Bool {
        if (value == null) return false;

        // Only skip the constructor field
        if (fieldName == "_constructor") return false;

        // Traverse into any complex object type - including graphics, sprites, etc.
        var type = Type.typeof(value);
        switch (type) {
            case TClass(_):
                return Math.random() < 0.4; // 40% chance to traverse into class instances
            case TObject:
                return Math.random() < 0.6; // 60% chance for anonymous objects
            default:
                return false;
        }
    }

    private function isCorruptibleValue(value:Dynamic):Bool {
        if (value == null) return false;

        return Std.isOfType(value, Int) ||
               Std.isOfType(value, Float) ||
               Std.isOfType(value, Bool) ||
               Std.isOfType(value, String) ||
               Std.isOfType(value, Array) ||
               value.isMap(); // Use isMap() method for proper Map detection
    }

    private function corruptValue(originalValue:Dynamic, fieldName:String):Dynamic {
        if (Std.isOfType(originalValue, Bool)) {
            return corruptBoolean(originalValue);
        } else if (Std.isOfType(originalValue, Int)) {
            return corruptInteger(originalValue, fieldName);
        } else if (Std.isOfType(originalValue, Float)) {
            return corruptFloat(originalValue, fieldName);
        } else if (Std.isOfType(originalValue, String)) {
            return corruptString(originalValue);
        } else if (Std.isOfType(originalValue, Array)) {
            return corruptArray(originalValue);
        } else if (originalValue.isMap()) {
            return corruptMap(originalValue);
        }

        return null;
    }

    private function corruptBoolean(value:Bool):Bool {
        // Simple inversion for booleans
        return !value;
    }

    private function corruptInteger(value:Int, fieldName:String):Int {
        var lowerFieldName = fieldName.toLowerCase();

        // Use more subtle corruption for position/size related fields
        if (lowerFieldName.indexOf("x") >= 0 || lowerFieldName.indexOf("y") >= 0 ||
            lowerFieldName.indexOf("width") >= 0 || lowerFieldName.indexOf("height") >= 0) {
            var offset = Math.floor(Math.random() * 20) - 10; // -10 to 10
            return value + offset;
        } else if (lowerFieldName.indexOf("alpha") >= 0) {
            return Math.floor(Math.max(0, Math.min(255, value + (Math.random() * 50 - 25))));
        } else if (lowerFieldName.indexOf("scale") >= 0) {
            return Math.floor(Math.max(-2, Math.min(3, value + (Math.random() * 2 - 1))));
        } else {
            // General corruption
            var methods = ["multiply", "add", "invert"];
            var method = methods[Math.floor(Math.random() * methods.length)];

            switch (method) {
                case "multiply":
                    var multiplier = Math.random() * 2; // 0 to 2
                    return Math.floor(value * multiplier);
                case "add":
                    var addition = Math.floor(Math.random() * 100) - 50; // -50 to 50
                    return value + addition;
                case "invert":
                    return -value;
                default:
                    return value;
            }
        }
    }

    private function corruptFloat(value:Float, fieldName:String):Float {
        var lowerFieldName = fieldName.toLowerCase();

        // Use more subtle corruption for common field types
        if (lowerFieldName.indexOf("alpha") >= 0) {
            return Math.max(-0.2, Math.min(1.2, value + (Math.random() * 0.4 - 0.2)));
        } else if (lowerFieldName.indexOf("scale") >= 0) {
            return Math.max(-1.0, Math.min(3.0, value + (Math.random() * 1.0 - 0.5)));
        } else if (lowerFieldName.indexOf("angle") >= 0 || lowerFieldName.indexOf("rotation") >= 0) {
            return (value + (Math.random() * 180 - 90)) % 360;
        } else if (lowerFieldName.indexOf("speed") >= 0 || lowerFieldName.indexOf("velocity") >= 0) {
            var multiplier = Math.random() * 2; // 0 to 2
            return value * multiplier;
        } else {
            // General corruption
            var methods = ["multiply", "add", "invert"];
            var method = methods[Math.floor(Math.random() * methods.length)];

            switch (method) {
                case "multiply":
                    var multiplier = Math.random() * 2; // 0 to 2
                    return value * multiplier;
                case "add":
                    var addition = (Math.random() * 100) - 50; // -50 to 50
                    return value + addition;
                case "invert":
                    return -value;
                default:
                    return value;
            }
        }
    }

    private function corruptString(value:String):String {
        if (value.length == 0) return "???";
        if (value.length > 50) return value; // Don't corrupt very long strings

        var methods = ["scramble", "duplicate", "truncate"];
        var method = methods[Math.floor(Math.random() * methods.length)];

        switch (method) {
            case "scramble":
                var chars = value.split("");
                // Scramble some characters
                for (i in 0...Math.floor(chars.length * 0.3)) {
                    var i1 = Math.floor(Math.random() * chars.length);
                    var i2 = Math.floor(Math.random() * chars.length);
                    var temp = chars[i1];
                    chars[i1] = chars[i2];
                    chars[i2] = temp;
                }
                return chars.join("");

            case "duplicate":
                return value + value.substr(0, Math.floor(value.length * 0.3));

            case "truncate":
                var newLength = Math.floor(value.length * (0.5 + Math.random() * 0.4)); // 50%-90% of original
                return value.substr(0, Math.max(1, Std.int(newLength)));

            default:
                return value;
        }
    }

    private function corruptArray(arr:Array<Dynamic>):Array<Dynamic> {
        if (arr == null || arr.length == 0) return arr;

        var methods = ["shuffle", "duplicate", "remove", "corrupt_values"];
        var method = methods[Math.floor(Math.random() * methods.length)];

        var newArr = arr.copy(); // Work on a copy

        switch (method) {
            case "shuffle":
                // Shuffle array elements
                for (i in 0...newArr.length) {
                    var j = Math.floor(Math.random() * newArr.length);
                    var temp = newArr[i];
                    newArr[i] = newArr[j];
                    newArr[j] = temp;
                }

            case "duplicate":
                // Duplicate some random elements
                var duplicateCount = Math.floor(newArr.length * 0.2) + 1;
                for (i in 0...duplicateCount) {
                    var randomIndex = Math.floor(Math.random() * newArr.length);
                    newArr.push(newArr[randomIndex]);
                }

            case "remove":
                // Remove some random elements (but not all)
                var removeCount = Math.floor(newArr.length * 0.3);
                for (i in 0...removeCount) {
                    if (newArr.length > 1) { // Don't remove all elements
                        var randomIndex = Math.floor(Math.random() * newArr.length);
                        newArr.splice(randomIndex, 1);
                    }
                }

            case "corrupt_values":
                // Corrupt individual values in the array
                var corruptCount = Math.floor(newArr.length * 0.4) + 1;
                for (i in 0...corruptCount) {
                    var randomIndex = Math.floor(Math.random() * newArr.length);
                    var originalValue = newArr[randomIndex];

                    if (isCorruptibleValue(originalValue)) {
                        var corruptedValue = corruptValue(originalValue, "array_element");
                        if (corruptedValue != null) {
                            newArr[randomIndex] = corruptedValue;
                        }
                    }
                }
        }

        return newArr;
    }

    private function corruptMap(map:Map<Dynamic, Dynamic>):Map<Dynamic, Dynamic> {
        if (map == null) return map;

        var methods = ["corrupt_values", "shuffle_values", "corrupt_keys"];
        var weights = [70, 25, 5]; // 70% values, 25% shuffle, 5% keys
        var random = Math.random() * 100;
        var method = "";

        if (random < weights[0]) {
            method = "corrupt_values";
        } else if (random < weights[0] + weights[1]) {
            method = "shuffle_values";
        } else {
            method = "corrupt_keys";
        }

        var newMap = new Map<Dynamic, Dynamic>();

        switch (method) {
            case "corrupt_values":
                // Corrupt map values (most common)
                for (key in map.keys()) {
                    var originalValue = map.get(key);
                    if (isCorruptibleValue(originalValue) && Math.random() < 0.4) {
                        var corruptedValue = corruptValue(originalValue, "map_value");
                        newMap.set(key, corruptedValue != null ? corruptedValue : originalValue);
                    } else {
                        newMap.set(key, originalValue);
                    }
                }

            case "shuffle_values":
                // Shuffle values between keys (rare)
                var keys = [for (key in map.keys()) key];
                var values = [for (key in keys) map.get(key)];

                // Shuffle the values array
                for (i in 0...values.length) {
                    var j = Math.floor(Math.random() * values.length);
                    var temp = values[i];
                    values[i] = values[j];
                    values[j] = temp;
                }

                // Reassign shuffled values to keys
                for (i in 0...keys.length) {
                    newMap.set(keys[i], values[i]);
                }

            case "corrupt_keys":
                // Corrupt map keys (very rare and dangerous!)
                for (key in map.keys()) {
                    var value = map.get(key);
                    var newKey = key;

                    if (isCorruptibleValue(key) && Math.random() < 0.3) {
                        var corruptedKey = corruptValue(key, "map_key");
                        if (corruptedKey != null) {
                            newKey = corruptedKey;
                        }
                    }

                    newMap.set(newKey, value);
                }
        }

        return newMap;
    }

    // Static instance for global access
    private static var globalInstance:Anomoly = null;

    public static function getGlobalInstance():Anomoly {
        if (globalInstance == null) {
            globalInstance = new Anomoly();
        }
        return globalInstance;
    }

    public static function activateGlobal(?intensity:Float = 0.1, ?interval:Float = 1.0):Void {
        var instance = getGlobalInstance();
        instance.setIntensity(intensity);
        instance.setInterval(interval);
        instance.activate();
    }

    public static function deactivateGlobal():Void {
        if (globalInstance != null) {
            globalInstance.deactivate();
        }
    }
}
