package yutautil.typeregistry;

#if macro
class BuildDataLoader {
    public static function initialize():Bool return false;
    public static function getDataSource():String return "none";
    public static function getAllClasses():Array<String> return [];
    public static function getClassInfo(className:String):Dynamic return null;
    public static function getAllAbstracts():Array<String> return [];
    public static function getAbstractInfo(abstractName:String):Dynamic return null;
    public static function getOriginalAbstractPath(implClassName:String):String return null;
    public static function isImplClass(className:String):Bool return false;
    public static function getAbstractFromConversions(abstractName:String):Array<Dynamic> return [];
    public static function getAbstractToConversions(abstractName:String):Array<Dynamic> return [];
    public static function getAbstractImplFields(abstractName:String):Array<Dynamic> return [];
    public static function getAbstractOperators(abstractName:String):Array<Dynamic> return [];
    public static function canConvertToAbstract(valueTypeName:String, abstractName:String):Bool return false;
    public static function canConvertFromAbstract(abstractName:String, targetTypeName:String):Bool return false;
    public static function isGenericType(typeName:String):Bool return false;
    public static function getTypeParams(typeName:String):Array<String> return [];
    public static function getAllGenericTypes():Array<{name:String, typeParams:Array<String>}> return [];
    public static function resolveOriginalTypePath(typeName:String):String return typeName;
    public static function getAllTypedefs():Array<String> return [];
    public static function getAllFunctions():Array<Dynamic> return [];
    public static function getFunctionsByClass(className:String):Array<Dynamic> return [];
    public static function searchFunctions(pattern:String):Array<Dynamic> return [];
    public static function getFunctionsWithMetadata(metadata:String):Array<Dynamic> return [];
    public static function getBuildStats():Dynamic return null;
    public static function getAllTypeNames():Array<String> return [];
    public static function hasType(typeName:String):Bool return false;
    public static function getTypeInfo(typeName:String):Dynamic return null;
    public static function getRawData():Dynamic return null;
    public static function reload():Bool return false;
}
#else

import sys.FileSystem;
import sys.io.File;
import tjson.TJSON;
import yutautil.modules.ASync.AResult;
import yutautil.modules.ASync.ASyncHelper;
import yutautil.modules.ASync;

/**
 * Build-time data loader that provides access to macro-generated metadata.
 *
 * Loading priority:
 *   1. Filesystem files (export/builddata/) - available in dev builds
 *   2. Embedded Haxe resources - always available in builds with BUILD_MACRO_ENABLED
 *
 * Enhanced features:
 *   - Generic type parameter detection
 *   - Property access info (getter/setter kinds)
 *   - Abstract "to"/"from" conversion functions with field details
 *   - Original type path resolution (without _Impl_ suffix)
 *   - Abstract impl class field enumeration
 *   - Abstract operator overload detection
 *   - Async loading for large datasets without blocking
 */
class BuildDataLoader {
    static var loadedData:AResult<Dynamic> = null;
    static var isInitialized:Bool = false;
    static var dataPath:String = "export/builddata/type_collection_compressed.json";
    static var fullDataPath:String = "export/builddata/type_collection_data.json";
    static var dataSource:String = "none"; // "file", "resource", or "none"

    // Cache maps for faster lookups
    static var abstractByOriginalPath:Map<String, Dynamic> = null;
    static var classByOriginalPath:Map<String, Dynamic> = null;
    static var implToAbstractMap:Map<String, String> = null;

    /**
     * Initialize the build data loader.
     * Attempts filesystem first, then embedded Haxe resources as fallback.
     * Uses async loading to prevent blocking on large datasets.
     */
    public static function initialize():Bool {
        if (isInitialized) return true;

        trace('BuildDataLoader: Starting async initialization...');

        try {
            // Create async loading function
            var asyncLoad:ASync<Void -> Dynamic> = function():Dynamic {
                trace('BuildDataLoader: Async worker started');

                // Strategy 1: Try filesystem (dev builds)
                if (FileSystem.exists(dataPath)) {
                    trace('BuildDataLoader: Found compressed build data file, reading...');
                    var content = File.getContent(dataPath);
                    trace('BuildDataLoader: Read ${content.length} bytes, parsing with TJSON...');
                    var data = TJSON.parse(content);
                    dataSource = "file";
                    trace('BuildDataLoader: Loaded compressed build data from filesystem ($dataPath)');
                    return data;
                }

                if (FileSystem.exists(fullDataPath)) {
                    trace('BuildDataLoader: Found full build data file, reading...');
                    var content = File.getContent(fullDataPath);
                    trace('BuildDataLoader: Read ${content.length} bytes, parsing with TJSON...');
                    var data = TJSON.parse(content);
                    dataSource = "file";
                    trace('BuildDataLoader: Loaded full type collection data from filesystem ($fullDataPath)');
                    return data;
                }

                // Strategy 2: Try embedded Haxe resources (release builds)
                trace('BuildDataLoader: No filesystem files found, trying embedded resources...');
                var compressedResource = haxe.Resource.getString("typeregistry_compressed_data");
                if (compressedResource != null) {
                    trace('BuildDataLoader: Found compressed embedded resource (${compressedResource.length} chars), parsing with TJSON...');
                    var data = TJSON.parse(compressedResource);
                    dataSource = "resource";
                    trace('BuildDataLoader: Loaded compressed build data from embedded resource.');
                    return data;
                }

                var fullResource = haxe.Resource.getString("typeregistry_full_data");
                if (fullResource != null) {
                    trace('BuildDataLoader: Found full embedded resource (${fullResource.length} chars), parsing with TJSON...');
                    var data = TJSON.parse(fullResource);
                    dataSource = "resource";
                    trace('BuildDataLoader: Loaded full type collection data from embedded resource');
                    return data;
                }

                trace('BuildDataLoader: No type collection data found - neither filesystem nor embedded resources available');
                throw "No build data available";
            };

            // Start async loading
            loadedData = cast asyncLoad();

            // Add completion callback with trace
            loadedData.onReady(function(data:Dynamic) {
                try {
                    var classCount = data.classes != null ? (cast(data.classes, Array<Dynamic>)).length : 0;
                    var abstractCount = data.abstracts != null ? (cast(data.abstracts, Array<Dynamic>)).length : 0;
                    var functionCount = data.functions != null ? (cast(data.functions, Array<Dynamic>)).length : 0;
                    var editableFunctionCount = data.editableFunctions != null ? (cast(data.editableFunctions, Array<Dynamic>)).length : 0;

                    trace('BuildDataLoader: Async loading complete - loaded $classCount classes, $abstractCount abstracts, $functionCount functions ($editableFunctionCount editable)');

                    // Build caches after data is ready
                    buildCaches();
                    trace('BuildDataLoader: Cache building complete');
                } catch (e:Dynamic) {
                    trace('BuildDataLoader: Error in completion callback: $e');
                }
            });

            // Add error callback
            loadedData.onError(function(error:Dynamic) {
                trace('BuildDataLoader: Async loading failed: $error');
            });

            isInitialized = true;
            return true;
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error during initialization: $e');
            return false;
        }
    }

    /**
     * Build internal caches for fast lookup by original type path and impl class name.
     */
    static function buildCaches():Void {
        abstractByOriginalPath = new Map();
        classByOriginalPath = new Map();
        implToAbstractMap = new Map();

        try {
            var data = loadedData.get(); // Get data from AResult
            var abstracts:Array<Dynamic> = data.abstracts;
            if (abstracts != null) {
                for (abs in abstracts) {
                    if (abs.originalTypePath != null) {
                        abstractByOriginalPath.set(abs.originalTypePath, abs);
                    }
                    // Also index by simple name
                    abstractByOriginalPath.set(abs.name, abs);
                    // Map impl class name -> original abstract name
                    if (abs.implClassName != null) {
                        implToAbstractMap.set(abs.implClassName, abs.originalTypePath != null ? abs.originalTypePath : abs.name);
                    }
                    if (abs.implFullName != null) {
                        implToAbstractMap.set(abs.implFullName, abs.originalTypePath != null ? abs.originalTypePath : abs.name);
                    }
                }
            }
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Warning - failed to build abstract caches: $e');
        }

        try {
            var data = loadedData.get(); // Get data from AResult
            var classes:Array<Dynamic> = data.classes;
            if (classes != null) {
                for (cls in classes) {
                    if (cls.originalTypePath != null) {
                        classByOriginalPath.set(cls.originalTypePath, cls);
                    }
                    // Also index by simple name for backward compatibility
                    classByOriginalPath.set(cls.name, cls);
                }
            }
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Warning - failed to build class caches: $e');
        }
    }

    /**
     * Get the source from which data was loaded: "file", "resource", or "none"
     */
    public static function getDataSource():String {
        return dataSource;
    }

    // ========================= Class Accessors =========================

    /**
     * Get all class names from build data
     */
    public static function getAllClasses():Array<String> {
        if (!ensureInitialized()) return [];

        try {
            var classes:Array<Dynamic> = loadedData.get().classes;
            return [for (cls in classes) '${cls.pack}.${cls.name}'];
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting classes: $e');
            return [];
        }
    }

    /**
     * Get class information by name
     */
    public static function getClassInfo(className:String):Dynamic {
        if (!ensureInitialized()) return null;

        // Try cache first
        if (classByOriginalPath != null && classByOriginalPath.exists(className)) {
            return classByOriginalPath.get(className);
        }

        try {
            var classes:Array<Dynamic> = loadedData.get().classes;
            for (cls in classes) {
                var fullName = '${cls.pack}.${cls.name}';
                if (fullName == className || cls.name == className) {
                    return cls;
                }
                // Also check originalTypePath
                if (cls.originalTypePath != null && cls.originalTypePath == className) {
                    return cls;
                }
            }
            return null;
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting class info: $e');
            return null;
        }
    }

    // ========================= Abstract Accessors =========================

    /**
     * Get all abstract names from build data
     */
    public static function getAllAbstracts():Array<String> {
        if (!ensureInitialized()) return [];

        try {
            var abstracts:Array<Dynamic> = loadedData.get().abstracts;
            return [for (abs in abstracts) '${abs.pack}.${abs.name}'];
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting abstracts: $e');
            return [];
        }
    }

    /**
     * Get abstract information by name (supports both simple name and full path)
     */
    public static function getAbstractInfo(abstractName:String):Dynamic {
        if (!ensureInitialized()) return null;

        // Try cache first (indexed by original path and simple name)
        if (abstractByOriginalPath != null && abstractByOriginalPath.exists(abstractName)) {
            return abstractByOriginalPath.get(abstractName);
        }

        try {
            var abstracts:Array<Dynamic> = loadedData.get().abstracts;
            for (abs in abstracts) {
                var fullName = '${abs.pack}.${abs.name}';
                if (fullName == abstractName || abs.name == abstractName) {
                    return abs;
                }
                // Also check originalTypePath
                if (abs.originalTypePath != null && abs.originalTypePath == abstractName) {
                    return abs;
                }
            }
            return null;
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting abstract info: $e');
            return null;
        }
    }

    /**
     * Get the original abstract type path for an _Impl_ class name.
     * E.g., "Num_Impl_" -> "yutautil.Num"
     */
    public static function getOriginalAbstractPath(implClassName:String):String {
        if (!ensureInitialized()) return null;

        if (implToAbstractMap != null && implToAbstractMap.exists(implClassName)) {
            return implToAbstractMap.get(implClassName);
        }
        return null;
    }

    /**
     * Check if a class name is an abstract's _Impl_ class
     */
    public static function isImplClass(className:String):Bool {
        if (!ensureInitialized()) return false;

        if (implToAbstractMap != null) {
            return implToAbstractMap.exists(className);
        }
        return StringTools.endsWith(className, "_Impl_");
    }

    /**
     * Get abstract "from" conversion details (enhanced with field info)
     */
    public static function getAbstractFromConversions(abstractName:String):Array<Dynamic> {
        var info = getAbstractInfo(abstractName);
        if (info == null) return [];

        try {
            if (info.fromConversions != null) {
                return cast info.fromConversions;
            }
            // Fallback to simple from array
            if (info.from != null) {
                var from:Array<Dynamic> = info.from;
                return [for (f in from) {type: f, field: null}];
            }
            return [];
        } catch (e:Dynamic) {
            return [];
        }
    }

    /**
     * Get abstract "to" conversion details (enhanced with field info)
     */
    public static function getAbstractToConversions(abstractName:String):Array<Dynamic> {
        var info = getAbstractInfo(abstractName);
        if (info == null) return [];

        try {
            if (info.toConversions != null) {
                return cast info.toConversions;
            }
            // Fallback to simple to array
            if (info.to != null) {
                var to:Array<Dynamic> = info.to;
                return [for (t in to) {type: t, field: null}];
            }
            return [];
        } catch (e:Dynamic) {
            return [];
        }
    }

    /**
     * Get impl class fields for an abstract (the actual runtime methods)
     */
    public static function getAbstractImplFields(abstractName:String):Array<Dynamic> {
        var info = getAbstractInfo(abstractName);
        if (info == null) return [];

        try {
            return info.implFields != null ? cast info.implFields : [];
        } catch (e:Dynamic) {
            return [];
        }
    }

    /**
     * Get operator overloads for an abstract
     */
    public static function getAbstractOperators(abstractName:String):Array<Dynamic> {
        var fields = getAbstractImplFields(abstractName);
        var operators:Array<Dynamic> = [];
        for (field in fields) {
            if (field.isOperator == true) {
                operators.push(field);
            }
        }
        return operators;
    }

    /**
     * Check if a value type is compatible with an abstract's "from" conversions.
     * Returns true if the value could be implicitly converted to this abstract.
     */
    public static function canConvertToAbstract(valueTypeName:String, abstractName:String):Bool {
        var info = getAbstractInfo(abstractName);
        if (info == null) return false;

        try {
            // Check underlying type
            if (info.type == valueTypeName) return true;

            // Check from conversions
            if (info.from != null) {
                var from:Array<Dynamic> = info.from;
                for (f in from) {
                    if (Std.string(f) == valueTypeName) return true;
                }
            }
            return false;
        } catch (e:Dynamic) {
            return false;
        }
    }

    /**
     * Check if an abstract can be converted to a target type via "to" conversions.
     */
    public static function canConvertFromAbstract(abstractName:String, targetTypeName:String):Bool {
        var info = getAbstractInfo(abstractName);
        if (info == null) return false;

        try {
            // Check underlying type
            if (info.type == targetTypeName) return true;

            // Check to conversions
            if (info.to != null) {
                var to:Array<Dynamic> = info.to;
                for (t in to) {
                    if (Std.string(t) == targetTypeName) return true;
                }
            }
            return false;
        } catch (e:Dynamic) {
            return false;
        }
    }

    // ========================= Generic Type Accessors =========================

    /**
     * Check if a type has generic parameters
     */
    public static function isGenericType(typeName:String):Bool {
        if (!ensureInitialized()) return false;

        // Check abstracts
        var absInfo = getAbstractInfo(typeName);
        if (absInfo != null) return absInfo.isGeneric == true;

        // Check classes
        var clsInfo = getClassInfo(typeName);
        if (clsInfo != null) return clsInfo.isGeneric == true;

        return false;
    }

    /**
     * Get generic type parameter names for a type
     */
    public static function getTypeParams(typeName:String):Array<String> {
        if (!ensureInitialized()) return [];

        var absInfo = getAbstractInfo(typeName);
        if (absInfo != null && absInfo.typeParams != null) {
            return cast absInfo.typeParams;
        }

        var clsInfo = getClassInfo(typeName);
        if (clsInfo != null && clsInfo.typeParams != null) {
            return cast clsInfo.typeParams;
        }

        return [];
    }

    /**
     * Get all generic types from build data
     */
    public static function getAllGenericTypes():Array<{name:String, typeParams:Array<String>}> {
        if (!ensureInitialized()) return [];

        var results:Array<{name:String, typeParams:Array<String>}> = [];

        try {
            var abstracts:Array<Dynamic> = loadedData.get().abstracts;
            if (abstracts != null) {
                for (abs in abstracts) {
                    if (abs.isGeneric == true && abs.typeParams != null) {
                        results.push({
                            name: abs.originalTypePath != null ? abs.originalTypePath : abs.name,
                            typeParams: cast abs.typeParams
                        });
                    }
                }
            }
        } catch (e:Dynamic) {}

        try {
            var classes:Array<Dynamic> = loadedData.get().classes;
            if (classes != null) {
                for (cls in classes) {
                    if (cls.isGeneric == true && cls.typeParams != null) {
                        results.push({
                            name: cls.originalTypePath != null ? cls.originalTypePath : cls.name,
                            typeParams: cast cls.typeParams
                        });
                    }
                }
            }
        } catch (e:Dynamic) {}

        return results;
    }

    // ========================= Original Name Resolution =========================

    /**
     * Get the original Haxe type path for any type name.
     * Handles _Impl_ class names, resolving them back to the abstract's original path.
     */
    public static function resolveOriginalTypePath(typeName:String):String {
        if (!ensureInitialized()) return typeName;

        // Check if it's an impl class
        var abstractPath = getOriginalAbstractPath(typeName);
        if (abstractPath != null) return abstractPath;

        // Check class originalTypePath
        var clsInfo = getClassInfo(typeName);
        if (clsInfo != null && clsInfo.originalTypePath != null) {
            return clsInfo.originalTypePath;
        }

        // Check abstract originalTypePath
        var absInfo = getAbstractInfo(typeName);
        if (absInfo != null && absInfo.originalTypePath != null) {
            return absInfo.originalTypePath;
        }

        return typeName;
    }

    // ========================= Typedef Accessors =========================

    /**
     * Get all typedef names from build data
     */
    public static function getAllTypedefs():Array<String> {
        if (!ensureInitialized()) return [];

        try {
            var typedefs:Array<Dynamic> = loadedData.get().typedefs;
            return [for (td in typedefs) '${td.pack}.${td.name}'];
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting typedefs: $e');
            return [];
        }
    }

    // ========================= Function Accessors =========================

    /**
     * Get all function information from build data
     */
    public static function getAllFunctions():Array<Dynamic> {
        if (!ensureInitialized()) return [];

        try {
            return cast loadedData.get().functions;
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting functions: $e');
            return [];
        }
    }

    /**
     * Get functions by class name
     */
    public static function getFunctionsByClass(className:String):Array<Dynamic> {
        if (!ensureInitialized()) return [];

        try {
            var functions:Array<Dynamic> = loadedData.get().functions;
            return functions.filter(function(f:Dynamic):Bool { return f.className == className; });
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting functions by class: $e');
            return [];
        }
    }

    /**
     * Search functions by name pattern
     */
    public static function searchFunctions(pattern:String):Array<Dynamic> {
        if (!ensureInitialized()) return [];

        try {
            var functions:Array<Dynamic> = loadedData.get().functions;
            return functions.filter(function(f:Dynamic):Bool {
                return Std.string(f.name).indexOf(pattern) != -1;
            });
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error searching functions: $e');
            return [];
        }
    }

    /**
     * Get functions with specific metadata
     */
    public static function getFunctionsWithMetadata(metadata:String):Array<Dynamic> {
        if (!ensureInitialized()) return [];

        try {
            var functions:Array<Dynamic> = loadedData.get().functions;
            return functions.filter(function(f:Dynamic):Bool {
                var meta:Array<String> = f.metadata;
                if (meta == null) return false;
                for (m in meta) {
                    if (m.indexOf(metadata) != -1) return true;
                }
                return false;
            });
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting functions with metadata: $e');
            return [];
        }
    }

    // ========================= Statistics & Utility =========================

    /**
     * Get build statistics
     */
    public static function getBuildStats():Dynamic {
        if (!ensureInitialized()) return null;

        try {
            var data = loadedData.get();
            return {
                timestamp: data.timestamp,
                platform: data.platform,
                classCount: data.classes != null ? (cast(data.classes, Array<Dynamic>)).length : 0,
                abstractCount: data.abstracts != null ? (cast(data.abstracts, Array<Dynamic>)).length : 0,
                functionCount: data.functions != null ? (cast(data.functions, Array<Dynamic>)).length : 0,
                sourceFileCount: data.sourceFileCount != null ? data.sourceFileCount : 0,
                dataSource: dataSource
            };
        } catch (e:Dynamic) {
            trace('BuildDataLoader: Error getting build stats: $e');
            return null;
        }
    }

    /**
     * Get all available type names
     */
    public static function getAllTypeNames():Array<String> {
        var types:Array<String> = [];
        types = types.concat(getAllClasses());
        types = types.concat(getAllAbstracts());
        types = types.concat(getAllTypedefs());
        return types;
    }

    /**
     * Check if a type exists in the build data
     */
    public static function hasType(typeName:String):Bool {
        return getAllTypeNames().indexOf(typeName) != -1;
    }

    /**
     * Get detailed type information (works for classes, abstracts, typedefs)
     */
    public static function getTypeInfo(typeName:String):Dynamic {
        var classInfo = getClassInfo(typeName);
        if (classInfo != null) return {type: "class", data: classInfo};

        var abstractInfo = getAbstractInfo(typeName);
        if (abstractInfo != null) return {type: "abstract", data: abstractInfo};

        // Try typedefs
        if (!ensureInitialized()) return null;

        try {
            var typedefs:Array<Dynamic> = loadedData.get().typedefs;
            if (typedefs != null) {
                for (td in typedefs) {
                    var fullName = '${td.pack}.${td.name}';
                    if (fullName == typeName || td.name == typeName) {
                        return {type: "typedef", data: td};
                    }
                    // Also check originalTypePath (handles sub-module types like states.PlayState.SpeedEvent)
                    if (td.originalTypePath != null && td.originalTypePath == typeName) {
                        return {type: "typedef", data: td};
                    }
                }
            }
        } catch (e:Dynamic) {
            // Typedef data might not be in compressed version
        }

        return null;
    }

    /**
     * Get raw loaded data (for advanced usage)
     * Returns the AResult object which can be used with .get() to retrieve data
     */
    public static function getRawData():Dynamic {
        ensureInitialized();
        return loadedData.get();
    }

    /**
     * Force reload build data
     */
    public static function reload():Bool {
        isInitialized = false;
        loadedData = null;
        abstractByOriginalPath = null;
        classByOriginalPath = null;
        implToAbstractMap = null;
        dataSource = "none";
        return initialize();
    }

    static function ensureInitialized():Bool {
        if (!isInitialized) {
            return initialize();
        }
        return true;
    }
}

/**
 * Enhanced type info structure for build data
 */
typedef BuildTypeInfo = {
    name:String,
    pack:String,
    ?fields:Array<String>,
    ?type:String,
    ?confidence:Float,
    ?typeParams:Array<String>,
    ?isGeneric:Bool,
    ?originalTypePath:String
}

/**
 * Abstract conversion info structure
 */
typedef AbstractConversionInfo = {
    type:String,
    ?field:{
        name:String,
        type:String,
        isPublic:Bool,
        ?doc:String
    }
}

/**
 * Abstract impl field info
 */
typedef AbstractImplFieldInfo = {
    name:String,
    type:String,
    isPublic:Bool,
    ?doc:String,
    ?metadata:Array<String>,
    kind:String,
    ?isOperator:Bool,
    ?operatorName:String
}
#end
