package yutautil.typeregistry;

import yutautil.typeregistry.FieldInfo;
import yutautil.typeregistry.TypeInfo;

/**
 * Extended type information for typedef types
 */
class TypedefInfo extends yutautil.typeregistry.TypeInfo {
    public var type:String; // Underlying type structure
    public var isAnonymousStructure:Bool;

    public function new() {
        super();
        isAbstract = false;
        isAnonymousStructure = false;
    }

    /**
     * Check if an object matches this typedef structure
     */
    public function matchesStructure(obj:Dynamic):Bool {
        if (obj == null) return false;

        if (!isAnonymousStructure) {
            // For non-anonymous typedefs, do basic type checking
            return true;
        }

        // Check if object has all required fields
        for (field in fields) {
            if (!field.optional && !Reflect.hasField(obj, field.name)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Get missing fields for an object
     */
    public function getMissingFields(obj:Dynamic):Array<String> {
        var missing = [];

        if (obj == null) {
            for (field in fields) {
                if (!field.optional) {
                    missing.push(field.name);
                }
            }
            return missing;
        }

        for (field in fields) {
            if (!field.optional && !Reflect.hasField(obj, field.name)) {
                missing.push(field.name);
            }
        }

        return missing;
    }

    /**
     * Get extra fields that the object has but the typedef doesn't define
     */
    public function getExtraFields(obj:Dynamic):Array<String> {
        if (obj == null) return [];

        var extra = [];
        var objFields = Reflect.fields(obj);

        for (objField in objFields) {
            var found = false;
            for (typedefField in fields) {
                if (typedefField.name == objField) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                extra.push(objField);
            }
        }

        return extra;
    }
}
