package yutautil.save;

import flixel.FlxG;
import flixel.FlxState;
import haxe.Json;
import haxe.ds.Map;
import sys.FileSystem;
import sys.io.File;

/**
 * Information about a discovered field that can be corrupted
 */
typedef DiscoveredField = {
    var object:Dynamic;                 // The actual object containing the field
    var fieldName:String;               // Name of the field
    var originalValue:Dynamic;          // Original value of the field
    var depth:Int;                      // Nesting depth from the root object
}

/**
 * StateCorruptor - Uses StateSerializer to discover object structure, then uses reflection
 * to corrupt the actual fields of the original object in wacky ways!
 */
class StateCorruptor {

    // Static variables for corruption process
    private static var _discoveredFields:Array<DiscoveredField> = [];
    private static var _objectIdToActualObject:Map<String, Dynamic> = new Map<String, Dynamic>();

    /**
     * Corrupts an object by using StateSerializer to discover its structure,
     * then corrupting random fields at random depths
     * @param target The object to corrupt
     * @return The number of fields that were corrupted
     */
    public static function corrupt(target:Dynamic):Int {
        if (target == null) {
            trace('StateCorruptor: Cannot corrupt null object');
            return 0;
        }

        trace('StateCorruptor: Starting corruption process...');

        // Reset state
        resetCorruptionState();

        // Use StateSerializer to discover the object structure
        var serializedData = StateSerializer.createSerializableObject(target);
        if (serializedData == null) {
            trace('StateCorruptor: Failed to serialize target object');
            return 0;
        }

        trace('StateCorruptor: Discovered ${serializedData.METADATA.totalObjects} objects');

        // Build mapping of object IDs to actual objects and discover all fields
        buildObjectMapping(target, serializedData);

        // Randomly decide corruption depth (0 to the max depth found)
        var maxDepth = serializedData.METADATA.maxDepth;
        var corruptionDepth = Std.int(Math.random() * (maxDepth + 1));
        trace('StateCorruptor: Will corrupt up to depth ${corruptionDepth} (max available: ${maxDepth})');

        // Filter fields by chosen depth
        var fieldsAtDepth = _discoveredFields.filter(field -> field.depth <= corruptionDepth);

        // Randomly decide how many fields to corrupt from the available pool
        var maxCorruptible = fieldsAtDepth.length;
        var numToCorrupt = maxCorruptible > 0 ? Std.int(Math.random() * maxCorruptible) + 1 : 0;
        trace('StateCorruptor: Will corrupt ${numToCorrupt} out of ${maxCorruptible} available fields');

        // Randomly select fields to corrupt
        var fieldsToCorrupt = selectRandomFields(fieldsAtDepth, numToCorrupt);

        // Apply corruption to selected fields
        var corruptedCount = applyCorruption(fieldsToCorrupt);

        trace('StateCorruptor: Corruption complete! Corrupted ${corruptedCount} fields');
        return corruptedCount;
    }

    /**
     * Builds the mapping between serialized object IDs and actual object references,
     * and discovers all fields that can be corrupted
     */
    private static function buildObjectMapping(rootObject:Dynamic, serializedData:SerializedClass):Void {
        // Map the root object
        _objectIdToActualObject.set(serializedData.MAIN_OBJECT_ID, rootObject);

        // Discover fields in the root object
        discoverFieldsInObject(rootObject, 0);

        // Process queued objects
        if (serializedData.QUEUED_OBJECTS != null) {
            // Handle the fact that QUEUED_OBJECTS might be a regular object after JSON parsing
            var queuedObjectsMap:Map<String, Dynamic>;
            if (serializedData.QUEUED_OBJECTS.isMap()) {
                queuedObjectsMap = cast serializedData.QUEUED_OBJECTS;
            } else {
                // Convert from regular object to Map
                queuedObjectsMap = new Map<String, Dynamic>();
                for (field in Reflect.fields(serializedData.QUEUED_OBJECTS)) {
                    var value = Reflect.field(serializedData.QUEUED_OBJECTS, field);
                    queuedObjectsMap.set(field, value);
                }
            }

            // Map each queued object to its actual reference
            mapQueuedObjects(rootObject, queuedObjectsMap, serializedData.MAIN_OBJECT_ID);
        }
    }

    /**
     * Maps queued objects from serialization to their actual object references
     */
    private static function mapQueuedObjects(rootObject:Dynamic, queuedObjects:Map<String, Dynamic>, rootId:String):Void {
        // We need to traverse the actual object structure to find the references
        // This is tricky because we need to match serialized structure to actual structure

        var objectQueue:Array<{obj:Dynamic, depth:Int}> = [{obj: rootObject, depth: 0}];
        var processedActualObjects:Map<Dynamic, Bool> = new Map<Dynamic, Bool>();

        while (objectQueue.length > 0) {
            var current = objectQueue.shift();
            if (processedActualObjects.exists(current.obj)) continue;

            processedActualObjects.set(current.obj, true);

            // Check all fields of this object
            var fields = Reflect.fields(current.obj);
            for (field in fields) {
                var value = Reflect.field(current.obj, field);

                if (value != null && !Reflect.isFunction(value)) {
                    // Check if this value matches any queued objects by trying to find a matching structure
                    var matchingObjectId = findMatchingQueuedObject(value, queuedObjects);
                    if (matchingObjectId != null && !_objectIdToActualObject.exists(matchingObjectId)) {
                        _objectIdToActualObject.set(matchingObjectId, value);
                        discoverFieldsInObject(value, current.depth + 1);
                    }

                    // Continue traversing for nested objects
                    switch (Type.typeof(value)) {
                        case TClass(Array):
                            var arr:Array<Dynamic> = cast value;
                            for (item in arr) {
                                if (item != null && !Reflect.isFunction(item)) {
                                    objectQueue.push({obj: item, depth: current.depth + 1});
                                }
                            }
                        case TObject | TClass(c):
                            if (!isSimpleType(value)) {
                                objectQueue.push({obj: value, depth: current.depth + 1});
                            }
                        default:
                    }
                }
            }
        }
    }

    /**
     * Attempts to find a matching queued object for a given actual object
     * This is a heuristic approach - not perfect but should work for most cases
     */
    private static function findMatchingQueuedObject(actualObj:Dynamic, queuedObjects:Map<String, Dynamic>):String {
        var actualType = getObjectTypePath(actualObj);
        var actualFields = Reflect.fields(actualObj);

        // Look for queued objects with matching type and similar field structure
        for (objectId in queuedObjects.keys()) {
            var queuedData = queuedObjects.get(objectId);
            if (queuedData != null && Reflect.hasField(queuedData, "TYPE")) {
                var queuedType = Reflect.field(queuedData, "TYPE");

                if (actualType == queuedType) {
                    // Types match, check if field structure is similar
                    if (Reflect.hasField(queuedData, "FIELDS")) {
                        var queuedFields = Reflect.fields(Reflect.field(queuedData, "FIELDS"));
                        var matchingFields = 0;

                        for (field in queuedFields) {
                            if (actualFields.indexOf(field) != -1) {
                                matchingFields++;
                            }
                        }

                        // If most fields match, consider this a match
                        if (matchingFields >= Math.floor(queuedFields.length * 0.7)) {
                            return objectId;
                        }
                    }
                }
            }
        }

        return null;
    }

    /**
     * Discovers all fields in a given object that can be corrupted
     */
    private static function discoverFieldsInObject(obj:Dynamic, depth:Int):Void {
        if (obj == null) return;

        var fields = Reflect.fields(obj);

        for (field in fields) {
            var value = Reflect.field(obj, field);

            // Skip functions - they can't be meaningfully corrupted
            if (Reflect.isFunction(value)) continue;

            var discoveredField:DiscoveredField = {
                object: obj,
                fieldName: field,
                originalValue: value,
                depth: depth
            };

            _discoveredFields.push(discoveredField);
        }
    }

    /**
     * Randomly selects fields to corrupt from the available pool
     */
    private static function selectRandomFields(availableFields:Array<DiscoveredField>, numToCorrupt:Int):Array<DiscoveredField> {
        if (numToCorrupt >= availableFields.length) {
            return availableFields.copy();
        }

        var selected:Array<DiscoveredField> = [];
        var remaining = availableFields.copy();

        for (i in 0...numToCorrupt) {
            if (remaining.length == 0) break;

            var randomIndex = Std.int(Math.random() * remaining.length);
            selected.push(remaining[randomIndex]);
            remaining.splice(randomIndex, 1);
        }

        return selected;
    }

    /**
     * Applies corruption to the selected fields using reflection
     */
    private static function applyCorruption(fieldsToCorrupt:Array<DiscoveredField>):Int {
        var corruptedCount = 0;

        for (field in fieldsToCorrupt) {
            try {
                var newValue = generateCorruptedValue(field.originalValue);
                Reflect.setField(field.object, field.fieldName, newValue);
                corruptedCount++;

                trace('StateCorruptor: Corrupted field "${field.fieldName}" at depth ${field.depth}: ${field.originalValue} -> ${newValue}');
            } catch (e:Dynamic) {
                trace('StateCorruptor: Failed to corrupt field "${field.fieldName}": ${e}');
            }
        }

        return corruptedCount;
    }

    /**
     * Generates a corrupted value based on the original value type
     */
    private static function generateCorruptedValue(originalValue:Dynamic):Dynamic {
        if (originalValue == null) return generateRandomValue();

        switch (Type.typeof(originalValue)) {
            case TInt:
                return corruptInt(originalValue);
            case TFloat:
                return corruptFloat(originalValue);
            case TClass(String):
                return corruptString(originalValue);
            case TBool:
                return corruptBool(originalValue);
            case TClass(Array):
                return corruptArray(originalValue);
            case TClass(Date):
                return corruptDate(originalValue);
            case TClass(c):
                // For complex objects, Maps, etc.
                if (isMapType(originalValue)) {
                    return corruptMap(originalValue);
                } else {
                    // For actual class instances, corrupt their internal fields
                    return corruptComplexObject(originalValue);
                }
            case TObject:
                // Anonymous objects - corrupt their fields too
                return corruptAnonymousObject(originalValue);
            default:
                return generateRandomValue();
        }
    }

    /**
     * Corrupts a complex object by modifying its internal fields
     */
    private static function corruptComplexObject(originalObject:Dynamic):Dynamic {
        if (originalObject == null) return null;

        // Don't replace the object, just corrupt some of its fields
        var fields = Reflect.fields(originalObject);

        if (fields.length == 0) {
            // No fields to corrupt, return as-is
            return originalObject;
        }

        // Randomly decide how many fields to corrupt (1 to 3 fields, or 25% of total fields, whichever is smaller)
        var maxFieldsToCorrupt = Std.int(Math.min(3, Math.max(1, fields.length * 0.25)));
        var numFieldsToCorrupt = Std.int(Math.random() * maxFieldsToCorrupt) + 1;

        // Randomly select fields to corrupt
        var fieldsToCorrupt:Array<String> = [];
        var availableFields = fields.copy();

        for (i in 0...numFieldsToCorrupt) {
            if (availableFields.length == 0) break;

            var randomIndex = Std.int(Math.random() * availableFields.length);
            fieldsToCorrupt.push(availableFields[randomIndex]);
            availableFields.splice(randomIndex, 1);
        }

        // Corrupt the selected fields
        for (fieldName in fieldsToCorrupt) {
            try {
                var currentValue = Reflect.field(originalObject, fieldName);

                // Skip functions
                if (Reflect.isFunction(currentValue)) continue;

                var corruptedValue = generateCorruptedValue(currentValue);
                Reflect.setField(originalObject, fieldName, corruptedValue);

                trace('StateCorruptor: Corrupted internal field "${fieldName}" of complex object: ${currentValue} -> ${corruptedValue}');
            } catch (e:Dynamic) {
                trace('StateCorruptor: Failed to corrupt internal field "${fieldName}": ${e}');
            }
        }

        // Return the same object (now with corrupted internal fields)
        return originalObject;
    }

    /**
     * Corrupts an anonymous object by modifying its fields
     */
    private static function corruptAnonymousObject(originalObject:Dynamic):Dynamic {
        if (originalObject == null) return {};

        var fields = Reflect.fields(originalObject);

        if (fields.length == 0) {
            // Empty object, maybe add some chaos
            if (Math.random() < 0.5) {
                Reflect.setField(originalObject, "corrupted", true);
                Reflect.setField(originalObject, "chaos", Math.random());
            }
            return originalObject;
        }

        // For anonymous objects, corrupt 1-2 fields or up to 50% of fields
        var maxFieldsToCorrupt = Std.int(Math.min(2, Math.max(1, fields.length * 0.5)));
        var numFieldsToCorrupt = Std.int(Math.random() * maxFieldsToCorrupt) + 1;

        // Randomly select and corrupt fields
        var availableFields = fields.copy();

        for (i in 0...numFieldsToCorrupt) {
            if (availableFields.length == 0) break;

            var randomIndex = Std.int(Math.random() * availableFields.length);
            var fieldName = availableFields[randomIndex];
            availableFields.splice(randomIndex, 1);

            try {
                var currentValue = Reflect.field(originalObject, fieldName);

                // Skip functions
                if (Reflect.isFunction(currentValue)) continue;

                var corruptedValue = generateCorruptedValue(currentValue);
                Reflect.setField(originalObject, fieldName, corruptedValue);

                trace('StateCorruptor: Corrupted anonymous object field "${fieldName}": ${currentValue} -> ${corruptedValue}');
            } catch (e:Dynamic) {
                trace('StateCorruptor: Failed to corrupt anonymous field "${fieldName}": ${e}');
            }
        }

        return originalObject;
    }

    // Corruption methods for different types

    private static function corruptInt(original:Int):Dynamic {
        var choice = Math.random();

        if (choice < 0.2) return -original; // Negate
        if (choice < 0.4) return original * Std.int(Math.random() * 10 + 1); // Multiply
        if (choice < 0.6) return original + Std.int(Math.random() * 1000 - 500); // Add offset
        if (choice < 0.8) return Math.abs(original) > 1000 ? 42 : original * original; // Square or set to 42
        return Std.int(Math.random() * 2000 - 1000); // Random
    }

    private static function corruptFloat(original:Float):Dynamic {
        var choice = Math.random();

        if (choice < 0.2) return -original;
        if (choice < 0.4) return original * (Math.random() * 20 - 10);
        if (choice < 0.6) return original + (Math.random() * 200 - 100);
        if (choice < 0.8) return Math.pow(original, Math.random() * 3);
        return Math.random() * 1000 - 500;
    }

    private static function corruptString(original:String):Dynamic {
        var choice = Math.random();

        if (choice < 0.1) return original.toUpperCase();
        if (choice < 0.2) return original.toLowerCase();
        if (choice < 0.3) return reverseString(original);
        if (choice < 0.4) return shuffleString(original);
        if (choice < 0.5) return original + original; // Duplicate
        if (choice < 0.6) return original.split("").join("_"); // Add separators
        if (choice < 0.7) return replaceRandomChars(original);
        if (choice < 0.8) return original.substring(0, Std.int(original.length * Math.random()));
        if (choice < 0.9) return "¿ÇØRRUPT£D¿" + original + "¿£NĐED¿";
        return generateRandomString();
    }

    private static function corruptBool(original:Bool):Dynamic {
        // Simple boolean flip most of the time, but sometimes change type
        var choice = Math.random();
        if (choice < 0.8) return !original;
        if (choice < 0.9) return original ? "true" : "false";
        return original ? 1 : 0;
    }

    private static function corruptArray(original:Array<Dynamic>):Dynamic {
        var arr = original.copy();
        var choice = Math.random();

        if (choice < 0.2) {
            arr.reverse();
        } else if (choice < 0.4) {
            // Shuffle
            for (i in 0...arr.length) {
                var j = Std.int(Math.random() * arr.length);
                var temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
        } else if (choice < 0.6) {
            // Duplicate some elements
            for (i in 0...Std.int(arr.length * 0.5)) {
                var randomIndex = Std.int(Math.random() * arr.length);
                arr.push(arr[randomIndex]);
            }
        } else if (choice < 0.8) {
            // Remove random elements
            var elementsToRemove = Std.int(arr.length * Math.random() * 0.5);
            for (i in 0...elementsToRemove) {
                if (arr.length > 0) {
                    var randomIndex = Std.int(Math.random() * arr.length);
                    arr.splice(randomIndex, 1);
                }
            }
        } else {
            // Add chaos
            arr.push("CORRUPTED");
            arr.push(666);
            arr.push(null);
        }

        return arr;
    }

    private static function corruptDate(original:Date):Dynamic {
        var choice = Math.random();
        var timestamp = original.getTime();

        if (choice < 0.3) return Date.fromTime(timestamp + (Math.random() * 31536000000)); // Add up to 1 year
        if (choice < 0.6) return Date.fromTime(Math.abs(timestamp) * -1); // Negative time
        if (choice < 0.8) return Date.fromTime(Math.random() * Date.now().getTime()); // Random date
        return original.toString() + "_CORRUPTED";
    }

    private static function corruptMap(original:Dynamic):Dynamic {
        if (!isMapType(original)) return new Map<Dynamic, Dynamic>();

        var map:Map<Dynamic, Dynamic> = cast original;
        var newMap = new Map<Dynamic, Dynamic>();

        // Copy some existing entries
        for (key in map.keys()) {
            if (Math.random() < 0.7) { // 70% chance to keep
                newMap.set(key, map.get(key));
            }
        }

        // Add some chaos
        if (Math.random() < 0.5) {
            newMap.set("CORRUPTED_KEY", true);
            newMap.set(42, "chaos");
            newMap.set("random", Math.random());
        }

        return newMap;
    }

    // Helper methods

    private static function resetCorruptionState():Void {
        _discoveredFields = [];
        _objectIdToActualObject = new Map<String, Dynamic>();
    }

    private static function getObjectTypePath(obj:Dynamic):String {
        if (obj == null) return "null";
        var classType = Type.getClass(obj);
        if (classType == null) return "Object";
        return Type.getClassName(classType);
    }

    private static function isSimpleType(value:Dynamic):Bool {
        switch (Type.typeof(value)) {
            case TNull | TBool | TInt | TFloat | TClass(String) | TClass(Date):
                return true;
            default:
                return false;
        }
    }

    private static function isMapType(value:Dynamic):Bool {
        return value.isMap();
    }

    private static function generateRandomValue():Dynamic {
        var choice = Math.random();

        if (choice < 0.2) return Std.int(Math.random() * 1000 - 500);
        if (choice < 0.4) return Math.random() * 1000 - 500;
        if (choice < 0.6) return Math.random() > 0.5;
        if (choice < 0.8) return generateRandomString();
        return null;
    }

    private static function generateRandomString():String {
        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()";
        var length = Std.int(Math.random() * 15 + 1);
        var result = "";

        for (i in 0...length) {
            result += chars.charAt(Std.int(Math.random() * chars.length));
        }

        return result;
    }

    private static function reverseString(str:String):String {
        return str.split("").reverse().join("");
    }

    private static function shuffleString(str:String):String {
        var chars = str.split("");
        for (i in 0...chars.length) {
            var j = Std.int(Math.random() * chars.length);
            var temp = chars[i];
            chars[i] = chars[j];
            chars[j] = temp;
        }
        return chars.join("");
    }

    private static function replaceRandomChars(str:String):String {
        var chars = str.split("");
        var corruptChars = "!@#$%^&*(){}[]|<>?";

        for (i in 0...chars.length) {
            if (Math.random() < 0.3) {
                chars[i] = corruptChars.charAt(Std.int(Math.random() * corruptChars.length));
            }
        }

        return chars.join("");
    }

    // Public utility methods

    /**
     * Corrupts the current FlxState (be very careful!)
     */
    public static function corruptCurrentState():Int {
        if (FlxG.state == null) {
            trace('StateCorruptor: No active state to corrupt');
            return 0;
        }

        trace('StateCorruptor: WARNING - Corrupting current state! This may crash the game!');
        return corrupt(FlxG.state);
    }
}
}
