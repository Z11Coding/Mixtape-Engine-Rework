package yutautil.typeregistry;

import haxe.Json;
import yutautil.typeregistry.AbstractInfo;
import yutautil.typeregistry.ClassInfo;
import yutautil.typeregistry.TypedefInfo;

/**
 * Runtime type registry that provides comprehensive type information and checking capabilities
 */
class RuntimeRegistry {
    private static var _instance:RuntimeRegistry;

    private var typeInfos:Map<String, TypeInfo>;
    private var abstractInfos:Map<String, AbstractInfo>;
    private var classInfos:Map<String, ClassInfo>;
    private var typedefInfos:Map<String, TypedefInfo>;
    private var sourceMap:Map<String, SourceInfo>;

    private var initialized:Bool = false;

    public static function get():RuntimeRegistry {
        if (_instance == null) {
            _instance = new RuntimeRegistry();
        }
        return _instance;
    }

    private function new() {
        typeInfos = new Map();
        abstractInfos = new Map();
        classInfos = new Map();
        typedefInfos = new Map();
        sourceMap = new Map();
    }

    public function initialize():Void {
        if (initialized) return;

        try {
            #if macro
            // Load from generated registry
            var registryData = Json.parse(yutautil.typeregistry.GeneratedTypeRegistry.DATA);
            loadFromData(registryData);
            #else
            // Runtime initialization - will need to be populated differently
            trace("RuntimeRegistry: Initializing at runtime");
            #end

            initialized = true;
        } catch (e:Dynamic) {
            trace("RuntimeRegistry: Failed to initialize - " + e);
        }
    }

    private function loadFromData(data:Dynamic):Void {
        if (data.types != null) {
            for (typeData in cast(data.types, Array<Dynamic>)) {
                var info = createTypeInfoFromData(typeData.info);
                typeInfos.set(typeData.name, info);
            }
        }

        if (data.abstracts != null) {
            for (abstractData in cast(data.abstracts, Array<Dynamic>)) {
                var info = createAbstractInfoFromData(abstractData.info);
                abstractInfos.set(abstractData.name, info);
            }
        }

        if (data.classes != null) {
            for (classData in cast(data.classes, Array<Dynamic>)) {
                var info = createClassInfoFromData(classData.info);
                classInfos.set(classData.name, info);
            }
        }

        if (data.typedefs != null) {
            for (typedefData in cast(data.typedefs, Array<Dynamic>)) {
                var info = createTypedefInfoFromData(typedefData.info);
                typedefInfos.set(typedefData.name, info);
            }
        }

        if (data.sourceMap != null) {
            for (sourceData in cast(data.sourceMap, Array<Dynamic>)) {
                sourceMap.set(sourceData.name, sourceData.info);
            }
        }
    }

    // Helper methods to create type info from JSON data
    private function createTypeInfoFromData(data:Dynamic):TypeInfo {
        var info = new TypeInfo();
        info.name = data.name;
        info.pack = data.pack;
        info.module = data.module;
        info.isAbstract = data.isAbstract;
        info.fields = data.fields != null ? data.fields : [];
        return info;
    }

    private function createAbstractInfoFromData(data:Dynamic):AbstractInfo {
        var info = new AbstractInfo();
        info.name = data.name;
        info.pack = data.pack;
        info.module = data.module;
        info.type = data.type;
        info.fromCasts = data.fromCasts != null ? data.fromCasts : [];
        info.toCasts = data.toCasts != null ? data.toCasts : [];
        info.fields = data.fields != null ? data.fields : [];
        return info;
    }

    private function createClassInfoFromData(data:Dynamic):ClassInfo {
        var info = new ClassInfo();
        info.name = data.name;
        info.pack = data.pack;
        info.module = data.module;
        info.isInterface = data.isInterface;
        info.superClass = data.superClass;
        info.interfaces = data.interfaces != null ? data.interfaces : [];
        info.staticFields = data.staticFields != null ? data.staticFields : [];
        info.fields = data.fields != null ? data.fields : [];
        info.constructorInfo = data.constructorInfo;
        return info;
    }

    private function createTypedefInfoFromData(data:Dynamic):TypedefInfo {
        var info = new TypedefInfo();
        info.name = data.name;
        info.pack = data.pack;
        info.module = data.module;
        info.type = data.type;
        info.isAnonymousStructure = data.isAnonymousStructure;
        info.fields = data.fields != null ? data.fields : [];
        return info;
    }

    // Public API methods

    public function getTypeInfo(typeName:String):TypeInfo {
        initialize();
        return typeInfos.get(typeName);
    }

    public function getAbstractInfo(typeName:String):AbstractInfo {
        initialize();
        return abstractInfos.get(typeName);
    }

    public function getClassInfo(typeName:String):ClassInfo {
        initialize();
        return classInfos.get(typeName);
    }

    public function getTypedefInfo(typeName:String):TypedefInfo {
        initialize();
        return typedefInfos.get(typeName);
    }

    public function getSourceInfo(typeName:String):SourceInfo {
        initialize();
        return sourceMap.get(typeName);
    }

    public function getAllTypes():Array<String> {
        initialize();
        return [for (key in typeInfos.keys()) key];
    }

    public function getAllAbstracts():Array<String> {
        initialize();
        return [for (key in abstractInfos.keys()) key];
    }

    public function getAllClasses():Array<String> {
        initialize();
        return [for (key in classInfos.keys()) key];
    }

    public function getAllTypedefs():Array<String> {
        initialize();
        return [for (key in typedefInfos.keys()) key];
    }

    /**
     * Find potential abstract types for a given value
     */
    public function findAbstractsForValue(value:Dynamic):Array<AbstractInfo> {
        initialize();
        var results = [];

        for (abstract in abstractInfos) {
            if (abstract.couldBeType(value)) {
                results.push(abstract);
            }
        }

        return results;
    }

    /**
     * Check if a type exists in the registry
     */
    public function hasType(typeName:String):Bool {
        initialize();
        return typeInfos.exists(typeName);
    }

    /**
     * Get source code for a type
     */
    public function getSourceCode(typeName:String):String {
        initialize();
        var sourceInfo = sourceMap.get(typeName);
        return sourceInfo != null ? sourceInfo.source : null;
    }

    /**
     * Get source position for a type
     */
    public function getSourcePosition(typeName:String):{file:String, min:Int, max:Int} {
        initialize();
        var sourceInfo = sourceMap.get(typeName);
        if (sourceInfo != null) {
            return {
                file: sourceInfo.file,
                min: sourceInfo.min,
                max: sourceInfo.max
            };
        }
        return null;
    }
}
