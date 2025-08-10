package yutautil.save;

import yutautil.save.StateSerializer;
import backend.MixSave;

/**
 * Simplified wrapper around StateSerializer for general object serialization
 * Provides an easy-to-use interface for serializing any object with the advanced queue-based system.
 */
class ObjectSerializer {
    
    /**
     * Serialize any object using the advanced StateSerializer
     * @param obj The object to serialize
     * @param saveKey Optional key for MixSave integration
     * @return Serialized object data
     */
    public static function serialize(obj:Dynamic, ?saveKey:String):Dynamic {
        var serializedData = StateSerializer.createSerializableObject(obj);
        
        if (saveKey != null && serializedData != null) {
            // Save to MixSave system if key provided
            var mixSave = new MixSave();
            mixSave.addContent(saveKey, serializedData);
            // Note: Individual MixSave instances need to be handled by the caller
            // for persistence, as each instance manages its own content
        }
        
        return serializedData;
    }
    
    /**
     * Deserialize an object using the advanced StateSerializer
     * @param serializedData The serialized object data
     * @param saveKey Optional key for MixSave integration (requires external MixSave instance)
     * @return Restored object instance
     */
    public static function deserialize(serializedData:Dynamic, ?saveKey:String):Dynamic {
        // Note: For MixSave integration with saveKey, use deserializeFromMixSave instead
        if (serializedData == null && saveKey != null) {
            trace('Warning: Cannot load from saveKey without external MixSave instance. Use deserializeFromMixSave instead.');
            return null;
        }
        
        if (serializedData == null) return null;
        
        return StateSerializer.restoreFromSerializedObject(serializedData);
    }
    
    /**
     * Deserialize an object from a MixSave instance
     * @param mixSave The MixSave instance to load from
     * @param saveKey The key to load
     * @return Restored object instance
     */
    public static function deserializeFromMixSave(mixSave:MixSave, saveKey:String):Dynamic {
        if (mixSave == null || saveKey == null) return null;
        
        var serializedData = mixSave.getContent(saveKey);
        if (serializedData == null) return null;
        
        return StateSerializer.restoreFromSerializedObject(serializedData);
    }
    
    /**
     * Create a deep clone of an object using serialization
     * @param obj The object to clone
     * @return Deep copy of the object
     */
    public static function deepClone(obj:Dynamic):Dynamic {
        var serialized = serialize(obj);
        return deserialize(serialized);
    }
    
    /**
     * Check if an object can be serialized
     * @param obj The object to check
     * @return True if serializable
     */
    public static function canSerialize(obj:Dynamic):Bool {
        if (obj == null) return true;
        
        try {
            var serialized = serialize(obj);
            return serialized != null;
        } catch (e:Dynamic) {
            return false;
        }
    }
    
    /**
     * Get metadata about a serialized object without fully deserializing it
     * @param serializedData The serialized object data
     * @return Object metadata
     */
    public static function getMetadata(serializedData:Dynamic):Dynamic {
        if (serializedData == null) return null;
        
        return {
            className: Reflect.hasField(serializedData, "CLASS") ? Reflect.field(serializedData, "CLASS") : "Unknown",
            typePath: Reflect.hasField(serializedData, "TYPE") ? Reflect.field(serializedData, "TYPE") : "Unknown",
            timestamp: Reflect.hasField(serializedData, "TIMESTAMP") ? Reflect.field(serializedData, "TIMESTAMP") : 0,
            version: Reflect.hasField(serializedData, "VERSION") ? Reflect.field(serializedData, "VERSION") : "Unknown",
            metadata: Reflect.hasField(serializedData, "METADATA") ? Reflect.field(serializedData, "METADATA") : null,
            hasQueuedObjects: Reflect.hasField(serializedData, "QUEUED_OBJECTS"),
            queuedObjectCount: Reflect.hasField(serializedData, "QUEUED_OBJECTS") ? 
                Lambda.count(Reflect.field(serializedData, "QUEUED_OBJECTS")) : 0
        };
    }
    
    /**
     * Validate that a serialized object structure is complete and valid
     * @param serializedData The serialized object data
     * @return True if valid
     */
    public static function validateSerialization(serializedData:Dynamic):Bool {
        if (serializedData == null) return false;
        
        // Check required fields
        var requiredFields = ["CLASS", "TYPE", "FIELDS", "TIMESTAMP", "VERSION"];
        for (field in requiredFields) {
            if (!Reflect.hasField(serializedData, field)) {
                trace('Missing required field: ${field}');
                return false;
            }
        }
        
        // Check if version is supported
        var version = Reflect.field(serializedData, "VERSION");
        if (version != "2.0.0" && !isCompatibleVersion(version)) {
            trace('Unsupported serializer version: ${version}');
            return false;
        }
        
        // Check for queued objects consistency
        if (Reflect.hasField(serializedData, "QUEUED_OBJECTS") && Reflect.hasField(serializedData, "MAIN_OBJECT_ID")) {
            var queuedObjects = Reflect.field(serializedData, "QUEUED_OBJECTS");
            var mainObjectId = Reflect.field(serializedData, "MAIN_OBJECT_ID");
            
            // Ensure main object ID is valid
            if (mainObjectId == null || mainObjectId == "") {
                trace('Invalid main object ID');
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Check if a serializer version is compatible
     * @param version The version to check
     * @return True if compatible
     */
    private static function isCompatibleVersion(version:String):Bool {
        // Add version compatibility logic here
        // For now, accept versions 2.0.0 and 1.0.0
        return version == "2.0.0" || version == "1.0.0";
    }
    
    /**
     * Get a human-readable description of a serialized object
     * @param serializedData The serialized object data
     * @return Description string
     */
    public static function getDescription(serializedData:Dynamic):String {
        var metadata = getMetadata(serializedData);
        if (metadata == null) return "Invalid serialized data";
        
        var description = 'Object: ${metadata.className}';
        
        if (metadata.queuedObjectCount > 0) {
            description += ' (with ${metadata.queuedObjectCount} nested objects)';
        }
        
        if (metadata.metadata != null) {
            var meta = metadata.metadata;
            if (Reflect.hasField(meta, "totalObjects")) {
                description += ', Total objects: ${Reflect.field(meta, "totalObjects")}';
            }
            if (Reflect.hasField(meta, "maxDepth")) {
                description += ', Max depth: ${Reflect.field(meta, "maxDepth")}';
            }
            if (Reflect.hasField(meta, "hasCircularRefs") && Reflect.field(meta, "hasCircularRefs") == true) {
                description += ' (has circular references)';
            }
        }
        
        var timestamp = metadata.timestamp;
        if (timestamp > 0) {
            var date = Date.fromTime(timestamp * 1000); // Convert from seconds to milliseconds
            description += ', Saved: ${date.toString()}';
        }
        
        return description;
    }
    
    // Legacy compatibility methods
    
    /**
     * Legacy method for backward compatibility
     * @param obj The object to serialize
     * @param name Optional name (ignored in new version)
     * @return Serialized object data
     */
    public static function createSerializableObject(obj:Dynamic, ?name:String):Dynamic {
        return serialize(obj);
    }
    
    /**
     * Legacy method for backward compatibility
     * @param serializedObj The serialized object data
     * @return Restored object instance
     */
    public static function restoreObject(serializedObj:Dynamic):Dynamic {
        return deserialize(serializedObj);
    }
    
    /**
     * Legacy method for backward compatibility
     * @param serializedObj The serialized object data
     * @return Object metadata
     */
    public static function getObjectInfo(serializedObj:Dynamic):Dynamic {
        return getMetadata(serializedObj);
    }
    
    /**
     * Saves a serializable object to a MixSave instance
     * @param obj The object to save
     * @param key The key to save it under
     * @param mixSave The MixSave instance to save to (creates new if not provided)
     * @return The MixSave instance used (for chaining or persistence)
     */
    public static function saveToMixSave(obj:Dynamic, key:String, ?mixSave:MixSave):MixSave {
        try {
            if (mixSave == null) {
                mixSave = new MixSave();
            }
            
            var serialized = serialize(obj);
            if (serialized != null) {
                mixSave.addContent(key, serialized);
                return mixSave;
            }
            
            return null;
        } catch (e:Dynamic) {
            trace('Error saving object to MixSave: ${e}');
            return null;
        }
    }
    
    /**
     * Loads a serializable object from a MixSave instance
     * @param key The key to load from
     * @param mixSave The MixSave instance to load from (creates new if not provided)
     * @return The restored object, or null if loading failed
     */
    public static function loadFromMixSave(key:String, ?mixSave:MixSave):Dynamic {
        try {
            if (mixSave == null) {
                mixSave = new MixSave();
            }
            
            var serializedData = mixSave.getContent(key);
            if (serializedData != null) {
                return deserialize(serializedData);
            }
            
            return null;
        } catch (e:Dynamic) {
            trace('Error loading object from MixSave: ${e}');
            return null;
        }
    }
    
    /**
     * Saves an object to a file using MixSave wrapper (convenience method)
     * @param obj The object to save
     * @param key The key to save it under
     * @param filePath The file path for the MixSave file
     * @return True if save was successful
     */
    public static function saveToFile(obj:Dynamic, key:String, filePath:String = "save/serialized_objects.json"):Bool {
        try {
            var serialized = serialize(obj);
            if (serialized == null) return false;
            
            // Create a simple save structure
            var saveData = {};
            Reflect.setField(saveData, key, serialized);
            
            // Ensure directory exists
            var dir = haxe.io.Path.directory(filePath);
            if (!sys.FileSystem.exists(dir)) {
                sys.FileSystem.createDirectory(dir);
            }
            
            // Save to file
            var jsonString = haxe.Json.stringify(saveData, null, "\t");
            sys.io.File.saveContent(filePath, jsonString);
            
            return true;
        } catch (e:Dynamic) {
            trace('Error saving object to file: ${e}');
            return false;
        }
    }
    
    /**
     * Loads an object from a file (convenience method)
     * @param key The key to load from
     * @param filePath The file path for the MixSave file
     * @return The restored object, or null if loading failed
     */
    public static function loadFromFile(key:String, filePath:String = "save/serialized_objects.json"):Dynamic {
        try {
            if (!sys.FileSystem.exists(filePath)) {
                trace('File does not exist: ${filePath}');
                return null;
            }
            
            var jsonContent = sys.io.File.getContent(filePath);
            var saveData = haxe.Json.parse(jsonContent);
            
            if (!Reflect.hasField(saveData, key)) {
                trace('Key "${key}" not found in save file');
                return null;
            }
            
            var serializedData = Reflect.field(saveData, key);
            return deserialize(serializedData);
            
        } catch (e:Dynamic) {
            trace('Error loading object from file: ${e}');
            return null;
        }
    }
}
