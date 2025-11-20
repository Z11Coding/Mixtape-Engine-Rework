package yutautil.save;

import flixel.FlxG;
import flixel.FlxState;
import haxe.Json;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Structure to hold serialized class information with JSON support
 */
typedef SerializedClass = {
    var CLASS:String;           // Class name
    var TYPE:String;            // Full type path
    var FIELDS:Dynamic;         // JSON-converted field data
    var TIMESTAMP:Float;        // When it was saved
    var VERSION:String;         // Serializer version
    var IS_ANONYMOUS:Bool;      // Whether this is an anonymous structure
    var QUEUED_OBJECTS:Map<String, Dynamic>; // Queue of nested objects
    var MAIN_OBJECT_ID:String;  // ID of the main object
    var METADATA:SerializationMetadata; // Additional metadata
}

typedef SerializationMetadata = {
    var totalObjects:Int;       // Total number of objects
    var maxDepth:Int;          // Maximum nesting depth
    var hasCircularRefs:Bool;  // Whether circular references were found
    var objectTypes:Array<String>; // List of all object types found
}

typedef QueuedObject = {
    obj: Dynamic,
    objectId: String,
    parentId: String,
    fieldName: String,
    depth: Int,
    processed: Bool
}

typedef QueuedDeserialization = {
    serializedData: Dynamic,
    targetObject: Dynamic,
    fieldName: String,
    objectId: String
}

/**
 * Advanced StateSerializer that handles complex object graphs using JSON conversion
 * instead of Haxe serialization, making data more portable and debuggable.
 */
class StateSerializer {

    private static var SERIALIZER_VERSION:String = "3.0.0";
    private static var SAVE_DIRECTORY:String = "save/states/";
    private static var MAX_RECURSION_DEPTH:Int = 50;

    // Static variables for queue-based processing
    private static var _nextObjectId:Int = 0;
    private static var _objectRegistry:Map<Dynamic, String> = new Map<Dynamic, String>();
    private static var _idToObject:Map<String, Dynamic> = new Map<String, Dynamic>();
    private static var _serializationQueue:Array<QueuedObject> = [];
    private static var _deserializationQueue:Array<QueuedDeserialization> = [];
    private static var _processedObjects:Map<String, Bool> = new Map<String, Bool>();
    private static var _currentMaxDepth:Int = 0;
    private static var _foundTypes:Array<String> = [];
    private static var _circularRefs:Bool = false;

    /**
     * Creates a JSON-convertible object from any instance
     * @param instance The object instance to convert
     * @return SerializedClass structure containing JSON data
     */
    public static function createSerializableObject(instance:Dynamic):SerializedClass {
        if (instance == null) return null;

        // Reset state
        resetSerializationState();

        var mainObjectId = generateObjectId();
        var className = getClassName(instance);
        var typePath = getTypePath(instance);
        var isAnonymous = isAnonymousStructure(instance);

        // Register the main object
        _objectRegistry.set(instance, mainObjectId);
        _idToObject.set(mainObjectId, instance);
        _foundTypes.push(typePath);

        var result:SerializedClass = {
            CLASS: className,
            TYPE: typePath,
            FIELDS: {},
            TIMESTAMP: haxe.Timer.stamp(),
            VERSION: SERIALIZER_VERSION,
            IS_ANONYMOUS: isAnonymous,
            QUEUED_OBJECTS: new Map<String, Dynamic>(),
            MAIN_OBJECT_ID: mainObjectId,
            METADATA: {
                totalObjects: 0,
                maxDepth: 0,
                hasCircularRefs: false,
                objectTypes: []
            }
        };

        // Start with the main object
        result.FIELDS = convertObjectToJSON(instance, mainObjectId, 0);

        // Process the queue
        processSerializationQueue(result);

        // Update metadata
        updateSerializationMetadata(result);

        return result;
    }

    /**
     * Restores an object from JSON data in a SerializedClass structure
     * @param serializedClass The serialized class data
     * @return The restored instance, or null if restoration failed
     */
    public static function restoreFromSerializedObject(serializedClass:SerializedClass):Dynamic {
        if (serializedClass == null) {
            trace('Error: serializedClass is null');
            return null;
        }

        trace('Starting restoration of ${serializedClass.TYPE} (${serializedClass.METADATA.totalObjects} objects)');

        try {
            // Reset deserialization state
            resetDeserializationState();

            var mainInstance:Dynamic;

            if (serializedClass.IS_ANONYMOUS) {
                // Create plain object for anonymous structures
                mainInstance = {};
            } else {
                // Create empty instance of the main class
                mainInstance = createEmptyInstance(serializedClass.TYPE);
                if (mainInstance == null) {
                    trace('Warning: Failed to create empty instance of ${serializedClass.TYPE}, treating as anonymous');
                    mainInstance = {};
                }
            }

            // Register the main instance
            _idToObject.set(serializedClass.MAIN_OBJECT_ID, mainInstance);

            // Always restore fields for the main object first
            try {
                restoreObjectFromJSON(mainInstance, serializedClass.FIELDS);
            } catch (e:Dynamic) {
                trace('Warning: Error restoring main object fields: ${e}');
                throw e;
            }

            // Check if queued objects exists and handle JSON deserialization issue
            if (serializedClass.QUEUED_OBJECTS == null) {
                trace('No queued objects to process - restoration completed');
                return mainInstance;
            }

            // After JSON parsing, QUEUED_OBJECTS might be a regular object instead of a Map
            var queuedObjectsMap:Map<String, Dynamic>;
            if (serializedClass.QUEUED_OBJECTS.isMap()) {
                queuedObjectsMap = cast serializedClass.QUEUED_OBJECTS;
            } else {
                // Convert from regular object to Map
                queuedObjectsMap = new Map<String, Dynamic>();
                try {
                    for (field in Reflect.fields(serializedClass.QUEUED_OBJECTS)) {
                        var value = Reflect.field(serializedClass.QUEUED_OBJECTS, field);
                        queuedObjectsMap.set(field, value);
                    }
                } catch (e:Dynamic) {
                    trace('Warning: Error converting QUEUED_OBJECTS to Map: ${e}');
                    return mainInstance; // Still return main instance with its fields restored
                }
            }

            // Create empty instances for all queued objects first
            var queuedObjectCount = Lambda.count(queuedObjectsMap);
            if (queuedObjectCount > 0) {
                trace('Processing ${queuedObjectCount} queued objects');
            }

            for (objectId in queuedObjectsMap.keys()) {
                var queuedData = queuedObjectsMap.get(objectId);
                if (queuedData != null && Reflect.hasField(queuedData, "TYPE")) {
                    var typePath = Reflect.field(queuedData, "TYPE");
                    var isAnonymous = Reflect.hasField(queuedData, "IS_ANONYMOUS") ?
                                    Reflect.field(queuedData, "IS_ANONYMOUS") : false;

                    var emptyInstance:Dynamic;
                    if (isAnonymous) {
                        emptyInstance = {};
                    } else {
                        emptyInstance = createEmptyInstance(typePath);
                        if (emptyInstance == null) {
                            trace('Warning: Failed to create instance of ${typePath}, using anonymous object');
                            emptyInstance = {};
                        }
                    }
                    _idToObject.set(objectId, emptyInstance);
                } else {
                    trace('Warning: Queued object ${objectId} missing TYPE field or is null');
                }
            }

            // Process queued object fields
            var processedCount = 0;
            for (objectId in queuedObjectsMap.keys()) {
                var queuedData = queuedObjectsMap.get(objectId);
                var targetObject = _idToObject.get(objectId);
                if (targetObject != null && queuedData != null && Reflect.hasField(queuedData, "FIELDS")) {
                    try {
                        var fields = Reflect.field(queuedData, "FIELDS");
                        restoreObjectFromJSON(targetObject, fields);
                        processedCount++;
                    } catch (e:Dynamic) {
                        trace('Warning: Error restoring queued object ${objectId}: ${e}');
                        // Continue with other objects instead of failing completely
                    }
                } else {
                    trace('Warning: Skipping queued object ${objectId} - missing data or target object');
                }
            }

            if (processedCount > 0) {
                trace('Successfully processed ${processedCount} queued objects');
            }
            trace('Restoration completed successfully');
            return mainInstance;        } catch (e:Dynamic) {
            trace('Critical error in restoreFromSerializedObject: ${e}');
            trace('Error occurred while restoring ${serializedClass != null ? serializedClass.TYPE : "unknown type"}');
            trace('Stack trace: ${haxe.CallStack.toString(haxe.CallStack.callStack())}');
            return null;
        }
    }

    /**
     * Creates an empty instance of a class without calling its constructor
     * @param typePath The full type path of the class
     * @return Empty instance or null if creation failed
     */
    private static function createEmptyInstance(typePath:String):Dynamic {
        // If the type is unknown, return null to indicate anonymous handling
        if (typePath == null || typePath == "Unknown" || typePath == "null") {
            return null;
        }

        try {
            var classType = Type.resolveClass(typePath);
            if (classType == null) {
                trace('Could not resolve class type: ${typePath}, treating as anonymous object');
                return null;
            }

            // Create empty instance without calling constructor
            var instance = Type.createEmptyInstance(classType);
            return instance;

        } catch (e:Dynamic) {
            trace('Failed to create empty instance of ${typePath}: ${e}, treating as anonymous object');
            // Fallback: try creating with empty array parameters
            try {
                var classType = Type.resolveClass(typePath);
                if (classType != null) {
                    return Type.createInstance(classType, []);
                }
            } catch (e2:Dynamic) {
                trace('Fallback creation also failed: ${e2}, treating as anonymous object');
            }
            return null;
        }
    }

    /**
     * Check if an object is an anonymous structure
     */
    private static function isAnonymousStructure(obj:Dynamic):Bool {
        if (obj == null) return false;
        return Type.typeof(obj) == TObject || Type.getClass(obj) == null;
    }

    /**
     * Convert object fields to JSON-compatible data
     */
    private static function convertObjectToJSON(obj:Dynamic, objectId:String, depth:Int):Dynamic {
        if (obj == null) return null;
        if (depth > MAX_RECURSION_DEPTH) {
            trace('Maximum recursion depth reached, skipping object');
            return { __type: "MAX_DEPTH_REACHED" };
        }

        _currentMaxDepth = Std.int(Math.max(_currentMaxDepth, depth));
        var jsonFields:Dynamic = {};
        var fields = Reflect.fields(obj);

        for (field in fields) {
            var value = Reflect.field(obj, field);

            // Skip functions as they cannot be serialized
            if (Reflect.isFunction(value)) {
                continue;
            }

            var convertedValue = convertValueToJSON(value, objectId, field, depth + 1);
            Reflect.setField(jsonFields, field, convertedValue);
        }

        return jsonFields;
    }

    /**
     * Convert a single value to JSON-compatible format
     */
    private static function convertValueToJSON(value:Dynamic, parentId:String, fieldName:String, depth:Int):Dynamic {
        if (value == null) return null;

        switch (Type.typeof(value)) {
            case TNull | TBool | TInt | TFloat:
                return value;
            case TClass(String):
                return value;
            case TFunction:
                // Skip functions entirely - they cannot be serialized
                return {
                    __type: "FUNCTION_SKIPPED",
                    __info: "Function fields are not serializable"
                };
            case TClass(Array):
                var arr:Array<Dynamic> = cast value;
                return arr.map(function(item) return convertValueToJSON(item, parentId, fieldName + "[]", depth + 1));
            case TObject:
                // Handle anonymous structures/plain objects
                var obj = {
                    __type: "ANONYMOUS_OBJECT",
                    __fields: {}
                };
                for (objField in Reflect.fields(value)) {
                    var objValue = Reflect.field(value, objField);

                    // Skip functions in anonymous objects
                    if (Reflect.isFunction(objValue)) {
                        continue;
                    }

                    Reflect.setField(obj.__fields, objField, convertValueToJSON(objValue, parentId, fieldName + "." + objField, depth + 1));
                }
                return obj;
            case TClass(c):
                var className = Type.getClassName(c);
                var typePath = getTypePath(value);

                // Check for simple types that can be converted directly
                if (isSimpleConvertibleType(value)) {
                    return convertSimpleType(value, className);
                }

                // Check if we've already seen this object (circular reference)
                if (_objectRegistry.exists(value)) {
                    _circularRefs = true;
                    return {
                        __type: "OBJECT_REFERENCE",
                        __objectId: _objectRegistry.get(value)
                    };
                }

                // Queue this object for later processing
                var objectId = generateObjectId();
                _objectRegistry.set(value, objectId);
                _idToObject.set(objectId, value);

                if (_foundTypes.indexOf(typePath) == -1) {
                    _foundTypes.push(typePath);
                }

                var isAnonymous = isAnonymousStructure(value);

                _serializationQueue.push({
                    obj: value,
                    objectId: objectId,
                    parentId: parentId,
                    fieldName: fieldName,
                    depth: depth,
                    processed: false
                });

                return {
                    __type: "QUEUED_OBJECT",
                    __objectId: objectId,
                    __className: className,
                    __typePath: typePath,
                    __isAnonymous: isAnonymous
                };
            case TEnum(e):
                // Handle enums by converting to string representation
                return {
                    __type: "ENUM",
                    __enumType: Type.getEnumName(e),
                    __value: Std.string(value)
                };
            case TUnknown:
                // Handle unknown types
                return {
                    __type: "UNKNOWN",
                    __value: Std.string(value)
                };
            default:
                return {
                    __type: "UNSUPPORTED",
                    __className: getClassName(value),
                    __typeInfo: Std.string(Type.typeof(value))
                };
        }
    }

    /**
     * Process the serialization queue
     */
    private static function processSerializationQueue(result:SerializedClass):Void {
        while (_serializationQueue.length > 0) {
            var queuedObj = _serializationQueue.shift();
            if (queuedObj == null || queuedObj.processed) continue;

            queuedObj.processed = true;

            if (_processedObjects.exists(queuedObj.objectId)) continue;
            _processedObjects.set(queuedObj.objectId, true);

            var isAnonymous = isAnonymousStructure(queuedObj.obj);

            var serializedObj = {
                CLASS: getClassName(queuedObj.obj),
                TYPE: getTypePath(queuedObj.obj),
                FIELDS: convertObjectToJSON(queuedObj.obj, queuedObj.objectId, queuedObj.depth),
                IS_ANONYMOUS: isAnonymous,
                PARENT_ID: queuedObj.parentId,
                FIELD_NAME: queuedObj.fieldName,
                DEPTH: queuedObj.depth
            };

            result.QUEUED_OBJECTS.set(queuedObj.objectId, serializedObj);
        }
    }

    /**
     * Restore fields for an object instance from JSON data
     */
    private static function restoreObjectFromJSON(instance:Dynamic, fields:Dynamic):Void {
        if (instance == null || fields == null) {
            trace('Warning: restoreObjectFromJSON called with null - instance: ${instance != null}, fields: ${fields != null}');
            return;
        }

        var fieldNames = Reflect.fields(fields);

        for (field in fieldNames) {
            var value = Reflect.field(fields, field);
            try {
                var restoredValue = convertValueFromJSON(value);
                Reflect.setField(instance, field, restoredValue);
            } catch (e:Dynamic) {
                //trace('Warning: Could not restore field ${field}: ${e}');
            }
        }
    }    /**
     * Convert a value from JSON back to original form
     */
    private static function convertValueFromJSON(value:Dynamic):Dynamic {
        if (value == null) return null;

        if (Reflect.hasField(value, "__type")) {
            var type = Reflect.field(value, "__type");
            switch (type) {
                case "OBJECT_REFERENCE":
                    var objectId = Reflect.field(value, "__objectId");
                    return _idToObject.get(objectId);
                case "QUEUED_OBJECT":
                    var objectId = Reflect.field(value, "__objectId");
                    return _idToObject.get(objectId);
                case "ANONYMOUS_OBJECT":
                    // Restore anonymous object/structure
                    var fields = Reflect.field(value, "__fields");
                    if (fields == null) return {};

                    var obj = {};
                    for (field in Reflect.fields(fields)) {
                        var fieldValue = Reflect.field(fields, field);
                        Reflect.setField(obj, field, convertValueFromJSON(fieldValue));
                    }
                    return obj;
                case "FUNCTION_SKIPPED":
                    // Functions were skipped during serialization, return null
                    return null;
                case "ENUM":
                    // Try to restore enum value
                    var enumType = Reflect.field(value, "__enumType");
                    var enumValue = Reflect.field(value, "__value");
                    try {
                        var enumClass = Type.resolveEnum(enumType);
                        if (enumClass != null) {
                            // Try to create enum from string representation
                            return Type.createEnum(enumClass, enumValue);
                        }
                    } catch (e:Dynamic) {
                        trace('Could not restore enum ${enumType}: ${e}');
                    }
                    return null;
                case "UNKNOWN":
                    // Unknown types were converted to string, return as-is
                    return Reflect.field(value, "__value");
                case "Date":
                    var timestamp = Reflect.field(value, "__value");
                    return Date.fromTime(timestamp);
                case "NULL_MAP":
                    // Return null for null maps
                    return null;
                case "MAP_OBJECT":
                    // Restore Map from object data
                    var mapData = Reflect.field(value, "__value");
                    var restoredMap = new Map<Dynamic, Dynamic>();

                    for (field in Reflect.fields(mapData)) {
                        var mapValue = Reflect.field(mapData, field);

                        // Convert the value back from JSON
                        var convertedValue = convertValueFromJSON(mapValue);

                        // Try to restore the key to its original type
                        var originalKey:Dynamic = field;

                        // Simple type detection for common key types
                        if (field == "null") {
                            originalKey = null;
                        } else {
                            // Try int first
                            var intValue = Std.parseInt(field);
                            if (intValue != null && Std.string(intValue) == field) {
                                originalKey = intValue;
                            } else {
                                // Try float
                                var floatValue = Std.parseFloat(field);
                                if (!Math.isNaN(floatValue) && Std.string(floatValue) == field) {
                                    originalKey = floatValue;
                                } else if (field == "true") {
                                    originalKey = true;
                                } else if (field == "false") {
                                    originalKey = false;
                                }
                                // Otherwise keep as string
                            }
                        }

                        restoredMap.set(originalKey, convertedValue);
                    }

                    return restoredMap;
                case "MAX_DEPTH_REACHED":
                    return null;
                case "UNSUPPORTED":
                    return null;
                default:
                    // No special handling needed for other types
            }
        }

        // Handle arrays
        if (Std.isOfType(value, Array)) {
            var arr:Array<Dynamic> = cast value;
            return arr.map(function(item) return convertValueFromJSON(item));
        }

        // Handle plain objects
        if (Type.typeof(value) == TObject) {
            var obj = {};
            for (field in Reflect.fields(value)) {
                var fieldValue = Reflect.field(value, field);
                Reflect.setField(obj, field, convertValueFromJSON(fieldValue));
            }
            return obj;
        }

        return value;
    }

    // Helper methods

    private static function resetSerializationState():Void {
        _nextObjectId = 0;
        _objectRegistry = new Map<Dynamic, String>();
        _idToObject = new Map<String, Dynamic>();
        _serializationQueue = [];
        _processedObjects = new Map<String, Bool>();
        _currentMaxDepth = 0;
        _foundTypes = [];
        _circularRefs = false;
    }

    private static function resetDeserializationState():Void {
        _idToObject = new Map<String, Dynamic>();
        _deserializationQueue = [];
    }

    private static function generateObjectId():String {
        return "obj_" + (_nextObjectId++);
    }

    private static function getClassName(obj:Dynamic):String {
        if (obj == null) return "null";
        var classType = Type.getClass(obj);
        if (classType == null) return "Unknown";
        var className = Type.getClassName(classType);
        return className != null ? className.split(".").pop() : "Unknown";
    }

    private static function getTypePath(obj:Dynamic):String {
        if (obj == null) return "null";
        var classType = Type.getClass(obj);
        if (classType == null) return "Unknown";
        return Type.getClassName(classType);
    }

    private static function isSimpleConvertibleType(value:Dynamic):Bool {
        return Std.is(value, Date) || value.isMap();
    }

    private static function convertSimpleType(value:Dynamic, className:String):Dynamic {
        // Check for Date objects directly
        if (Std.is(value, Date)) {
            var date:Date = cast value;
            return {
                __type: "Date",
                __value: date.getTime()
            };
        }

        // Check if object is actually a Map using extension method
        if (value.isMap()) {
            var mapInstance:Map<Dynamic, Dynamic> = cast value;

            // Check if the map is null and handle it specially
            if (mapInstance == null) {
                return {
                    __type: "NULL_MAP",
                    __value: null
                };
            }

            var mapData:Dynamic = {};

            // trace(mapInstance);

            // Simply convert map to object - let JSON handle simple types
            for (key in mapInstance.keys()) {
                var mapValue = mapInstance.get(key);

                // Skip function values
                if (Reflect.isFunction(mapValue)) {
                    continue;
                }

                // Use simple string conversion for all keys
                var keyString = Std.string(key);

                // Only recursively serialize the value if it's complex
                var convertedValue = convertValueToJSON(mapValue, "", "", 0);

                Reflect.setField(mapData, keyString, convertedValue);
            }

            return {
                __type: "MAP_OBJECT",
                __value: mapData
            };
        }

        return value;
    }

    private static function updateSerializationMetadata(result:SerializedClass):Void {
        result.METADATA.totalObjects = Lambda.count(result.QUEUED_OBJECTS) + 1;
        result.METADATA.maxDepth = _currentMaxDepth;
        result.METADATA.hasCircularRefs = _circularRefs;
        result.METADATA.objectTypes = _foundTypes.copy();
    }

    // Public API methods for state management

    /**
     * Saves the current FlxState to a file
     * @param filename Optional filename (without extension)
     * @return True if save was successful
     */
    public static function saveCurrentState(?filename:String):Bool {
        if (FlxG.state == null) {
            trace('Error: No active state to save');
            return false;
        }

        if (filename == null) {
            var timestamp = Std.string(Date.now().getTime());
            var stateName = getClassName(FlxG.state);
            filename = '${stateName}_${timestamp}';
        }

        return saveState(FlxG.state, filename);
    }

    /**
     * Saves a specific FlxState to a file
     * @param state The state to save
     * @param filename Filename (without extension)
     * @return True if save was successful
     */
    public static function saveState(state:FlxState, filename:String):Bool {
        try {
            var serializedState = createSerializableObject(state);

            // Ensure save directory exists
            if (!sys.FileSystem.exists(SAVE_DIRECTORY)) {
                sys.FileSystem.createDirectory(SAVE_DIRECTORY);
            }

            var filePath = SAVE_DIRECTORY + filename + ".json";
            var jsonString = Json.stringify(serializedState, null, "\t");

            File.saveContent(filePath, jsonString);
            trace('State saved successfully to: ${filePath}');
            trace('Serialization stats: ${serializedState.METADATA.totalObjects} objects, max depth: ${serializedState.METADATA.maxDepth}');
            return true;
        } catch (e:Dynamic) {
            trace('Error saving state: ${new DetailedException(e)}');
            return false;
        }
    }

    /**
     * Loads a state from a file and switches to it
     * @param filename Filename (without extension)
     * @return True if load was successful
     */
    public static function loadAndSwitchToState(filename:String):Bool {
        var state = loadState(filename);
        if (state != null && Std.isOfType(state, FlxState)) {
            try {
                FlxG.switchState(cast state);
                trace('Successfully switched to loaded state');
                return true;
            } catch (e:Dynamic) {
                trace('Error switching to loaded state: ${e}');
                return false;
            }
        }
        return false;
    }

    /**
     * Loads a state from a file without switching to it
     * @param filename Filename (without extension)
     * @return The loaded state instance, or null if loading failed
     */
    public static function loadState(filename:String):FlxState {
        try {
            var filePath = SAVE_DIRECTORY + filename + ".json";

            if (!sys.FileSystem.exists(filePath)) {
                trace('Error: Save file not found: ${filePath}');
                return null;
            }

            var jsonContent = File.getContent(filePath);
            var serializedState:SerializedClass = Json.parse(jsonContent);

            trace('Loading state with ${serializedState.METADATA.totalObjects} objects...');

            var restoredState = restoreFromSerializedObject(serializedState);

            if (restoredState != null && Std.isOfType(restoredState, FlxState)) {
                trace('State loaded successfully from: ${filePath}');
                return cast restoredState;
            } else {
                trace('Error: Loaded object is not a valid FlxState');
                return null;
            }
        } catch (e:Dynamic) {
            trace('Error loading state: ${e}');
            return null;
        }
    }

    /**
     * Lists all available save files
     * @return Array of save file names (without extensions)
     */
    public static function listSaveFiles():Array<String> {
        var files:Array<String> = [];

        if (!sys.FileSystem.exists(SAVE_DIRECTORY)) {
            return files;
        }

        try {
            for (file in sys.FileSystem.readDirectory(SAVE_DIRECTORY)) {
                if (file.endsWith(".json")) {
                    files.push(file.substring(0, file.length - 5)); // Remove .json extension
                }
            }
        } catch (e:Dynamic) {
            trace('Error reading save directory: ${e}');
        }

        return files;
    }

    /**
     * Deletes a save file
     * @param filename Filename (without extension)
     * @return True if deletion was successful
     */
    public static function deleteSaveFile(filename:String):Bool {
        try {
            var filePath = SAVE_DIRECTORY + filename + ".json";

            if (sys.FileSystem.exists(filePath)) {
                sys.FileSystem.deleteFile(filePath);
                trace('Save file deleted: ${filePath}');
                return true;
            } else {
                trace('Save file not found: ${filePath}');
                return false;
            }
        } catch (e:Dynamic) {
            trace('Error deleting save file: ${e}');
            return false;
        }
    }

    /**
     * Gets detailed information about a save file
     * @param filename Filename (without extension)
     * @return SerializationMetadata or null if file doesn't exist
     */
    public static function getSaveFileInfo(filename:String):SerializationMetadata {
        try {
            var filePath = SAVE_DIRECTORY + filename + ".json";

            if (!sys.FileSystem.exists(filePath)) {
                return null;
            }

            var jsonContent = File.getContent(filePath);
            var serializedState:SerializedClass = Json.parse(jsonContent);

            return serializedState.METADATA;
        } catch (e:Dynamic) {
            trace('Error reading save file info: ${e}');
            return null;
        }
    }
}
