package yutautil.save;

// import backend.MixSave;
import yutautil.save.MixSaveWrapper;
import yutautil.save.StateSerializer.SerializedClass;
import yutautil.save.StateSerializer;

/**
 * Simplified wrapper around StateSerializer for general object JSON conversion
 * Provides an easy-to-use interface for converting any object to JSON with the advanced system.
 */
class ObjectSerializer {

    /**
     * Convert any object to SerializedClass using the advanced StateSerializer
     * @param obj The object to convert
     * @return SerializedClass object
     */
    public static function serialize(obj:Dynamic):SerializedClass {
        return StateSerializer.createSerializableObject(obj);
    }

    /**
     * Restore an object from SerializedClass data using the advanced StateSerializer
     * @param serializedClass The SerializedClass object data
     * @return Restored object instance
     */
    public static function deserialize(serializedClass:SerializedClass):Dynamic {
        return StateSerializer.restoreFromSerializedObject(serializedClass);
    }

    /**
     * Restore an object from a MixSaveWrapper file
     * @param filename The filename to load from
     * @return Restored object instance, or null if restoration failed
     */
    public static function deserializeFromMixSave(filename:String):Dynamic {
        if (filename == null) return null;

        try {
            var wrapper = new MixSaveWrapper(null, filename);
            var serializedClass:SerializedClass = cast wrapper.getItem("savedObject");
            if (serializedClass == null) return null;

            return StateSerializer.restoreFromSerializedObject(serializedClass);
        } catch (e:Dynamic) {
            trace('Error deserializing from MixSave file: ${e}');
            return null;
        }
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
     * @param serializedClass The SerializedClass object data
     * @return Object metadata
     */
    public static function getMetadata(serializedClass:SerializedClass):Dynamic {
        if (serializedClass == null) return null;

        return {
            className: serializedClass.CLASS != null ? serializedClass.CLASS : "Unknown",
            typePath: serializedClass.TYPE != null ? serializedClass.TYPE : "Unknown",
            timestamp: serializedClass.TIMESTAMP,
            version: serializedClass.VERSION != null ? serializedClass.VERSION : "Unknown",
            metadata: serializedClass.METADATA != null ? serializedClass.METADATA : null,
            hasQueuedObjects: serializedClass.QUEUED_OBJECTS != null,
            queuedObjectCount: serializedClass.QUEUED_OBJECTS != null ?
                Lambda.count(serializedClass.QUEUED_OBJECTS) : 0
        };
    }

    /**
     * Validate that a SerializedClass structure is complete and valid
     * @param serializedClass The SerializedClass object data
     * @return True if valid
     */
    public static function validateSerialization(serializedClass:SerializedClass):Bool {
        if (serializedClass == null) return false;

        // Check required fields
        if (serializedClass.CLASS == null || serializedClass.CLASS == "") {
            trace('Missing or empty CLASS field');
            return false;
        }

        if (serializedClass.TYPE == null || serializedClass.TYPE == "") {
            trace('Missing or empty TYPE field');
            return false;
        }

        if (serializedClass.FIELDS == null) {
            trace('Missing FIELDS field');
            return false;
        }

        if (serializedClass.VERSION == null) {
            trace('Missing VERSION field');
            return false;
        }

        // Check if version is supported
        var version = serializedClass.VERSION;
        if (version != "2.0.0" && !isCompatibleVersion(version)) {
            trace('Unsupported serializer version: ${version}');
            return false;
        }

        // Check for queued objects consistency
        if (serializedClass.QUEUED_OBJECTS != null && serializedClass.MAIN_OBJECT_ID != null) {
            var mainObjectId = serializedClass.MAIN_OBJECT_ID;

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
        // Accept versions 3.0.0, 2.0.0 and 1.0.0
        return version == "3.0.0" || version == "2.0.0" || version == "1.0.0";
    }

    /**
     * Get a human-readable description of a serialized object
     * @param serializedClass The SerializedClass object data
     * @return Description string
     */
    public static function getDescription(serializedClass:SerializedClass):String {
        var metadata = getMetadata(serializedClass);
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
     * @return SerializedClass object data
     */
    public static function createSerializableObject(obj:Dynamic, ?name:String):SerializedClass {
        return serialize(obj);
    }

    /**
     * Legacy method for backward compatibility
     * @param serializedObj The SerializedClass object data
     * @return Restored object instance
     */
    public static function restoreObject(serializedObj:SerializedClass):Dynamic {
        return deserialize(serializedObj);
    }

    /**
     * Legacy method for backward compatibility
     * @param serializedObj The SerializedClass object data
     * @return Object metadata
     */
    public static function getObjectInfo(serializedObj:SerializedClass):Dynamic {
        return getMetadata(serializedObj);
    }

    /**
     * Saves a serializable object to a MixSaveWrapper file
     * @param obj The object to save
     * @param filename The filename to save to
     * @return True if save was successful
     */
    public static function saveToMixSave(obj:Dynamic, filename:String):Bool {
        try {
            var serialized = serialize(obj);
            if (serialized == null) return false;

            var wrapper = new MixSaveWrapper(null, filename, false);
            wrapper.addItem("savedObject", serialized);
            wrapper.save();
            return true;
        } catch (e:Dynamic) {
            trace('Error saving object to MixSave: ${e}');
            return false;
        }
    }

    /**
     * Loads a serializable object from a MixSaveWrapper file
     * @param filename The filename to load from
     * @return The restored object, or null if loading failed
     */
    public static function loadFromMixSave(filename:String):Dynamic {
        return deserializeFromMixSave(filename);
    }

    /**
     * Saves an object to a file using MixSaveWrapper
     * @param obj The object to save
     * @param filename The filename to save to
     * @return True if save was successful
     */
    public static function saveToFile(obj:Dynamic, filename:String = "save/serialized_objects.json"):Bool {
        return saveToMixSave(obj, filename);
    }

    /**
     * Loads an object from a file using MixSaveWrapper
     * @param filename The filename to load from
     * @return The restored object, or null if loading failed
     */
    public static function loadFromFile(filename:String = "save/serialized_objects.json"):Dynamic {
        return loadFromMixSave(filename);
    }
}
