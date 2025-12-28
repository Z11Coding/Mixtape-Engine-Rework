package yutautil.typeregistry;

import haxe.Json;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Build macro that collects comprehensive type information during compilation
 * Applied automatically to all classes via global metadata
 */
class TypeCollectionMacro {
    // Storage for collected data across all classes
    static var collectedClasses:Array<Dynamic> = [];
    static var collectedAbstracts:Array<Dynamic> = [];
    static var collectedTypedefs:Array<Dynamic> = [];
    static var collectedEnums:Array<Dynamic> = [];
    static var collectedFunctions:Array<Dynamic> = [];
    static var buildMetadata:Dynamic = null;
    static var initialized:Bool = false;

    /**
     * Build macro entry point - called for each class during compilation
     * This collects detailed information from the class being compiled
     */
    macro static function collectTypeInfo():Array<Field> {
        var fields = Context.getBuildFields();
        var localClass = Context.getLocalClass();
        if (localClass == null) {
            #if verbose
            trace("TypeCollectionMacro: No local class available, skipping");
            #end
            return fields;
        }

        var classType = localClass.get();
        #if verbose
        trace('TypeCollectionMacro: Processing class ${classType.name} from ${classType.module}');
        #end

        if (!initialized) {
            initializeBuildCollection();
        }

        collectClassData(classType, fields);

        // Register completion callback on first run
        if (collectedClasses.length == 1) {
            Context.onGenerate(onGenerateComplete);
            trace("TypeCollectionMacro: Registered onGenerate callback");
        }

        return fields;
    }

    static function initializeBuildCollection():Void {
        initialized = true;
        trace('TypeCollectionMacro: Initializing build collection system');

        buildMetadata = {
            buildTimestamp: Date.now().getTime(),
            haxeVersion: Context.definedValue("haxe"),
            targetPlatform: Context.definedValue("target.name"),
            buildFlags: []
        };

        // Collect build flags
        for (flag in Context.getDefines().keys()) {
            buildMetadata.buildFlags.push({
                name: flag,
                value: Context.definedValue(flag)
            });
        }

        trace('TypeCollectionMacro: Initialized build collection, found ${buildMetadata.buildFlags.length} build flags');
    }

    static function collectClassData(classType:ClassType, fields:Array<Field>):Void {
        try {
            // Collect class information
            var classInfo:Dynamic = {
                name: classType.name,
                pack: classType.pack,
                module: classType.module,
                isInterface: classType.isInterface,
                isAbstract: false,
                superClass: classType.superClass != null ? {
                    name: classType.superClass.t.get().name,
                    pack: classType.superClass.t.get().pack
                } : null,
                interfaces: [for (i in classType.interfaces) {
                    name: i.t.get().name,
                    pack: i.t.get().pack
                }],
                fields: [],
                staticFields: [],
                metadata: extractMetadata(classType.meta),
                isExtern: classType.isExtern,
                doc: classType.doc,
                position: {
                    file: Context.getPosInfos(classType.pos).file,
                    line: Context.getPosInfos(classType.pos).min
                }
            };

            // Collect instance fields
            for (field in classType.fields.get()) {
                classInfo.fields.push(extractFieldInfo(field));
            }

            // Collect static fields
            for (field in classType.statics.get()) {
                classInfo.staticFields.push(extractFieldInfo(field));
            }

            // Collect functions from build fields
            for (field in fields) {
                collectFieldFunctions(field, classType.name);
            }

            collectedClasses.push(classInfo);

            #if verbose
            trace('TypeCollectionMacro: Collected class ${classType.name} (${classInfo.fields.length} fields)');
            #end

        } catch (e:Dynamic) {
            trace('TypeCollectionMacro: Error collecting class data for ${classType.name}: $e');
        }
    }

    static function extractMetadata(metadata:haxe.macro.MetaAccess):Array<String> {
        var result:Array<String> = [];
        for (meta in metadata.get()) {
            var metaStr = '@${meta.name}';
            if (meta.params != null && meta.params.length > 0) {
                metaStr += '(';
                for (i in 0...meta.params.length) {
                    if (i > 0) metaStr += ', ';
                    metaStr += haxe.macro.ExprTools.toString(meta.params[i]);
                }
                metaStr += ')';
            }
            result.push(metaStr);
        }
        return result;
    }

    static function extractFieldInfo(field:ClassField):Dynamic {
        return {
            name: field.name,
            type: TypeTools.toString(field.type),
            isPublic: field.isPublic,
            doc: field.doc,
            metadata: extractMetadata(field.meta),
            kind: switch(field.kind) {
                case FVar(read, write): 'var';
                case FMethod(k): 'method';
            },
            position: {
                file: Context.getPosInfos(field.pos).file,
                line: Context.getPosInfos(field.pos).min
            }
        };
    }

    static function collectFieldFunctions(field:Field, className:String):Void {
        switch (field.kind) {
            case FFun(func):
                var functionInfo:Dynamic = {
                    name: field.name,
                    className: className,
                    isStatic: field.access.indexOf(AStatic) != -1,
                    isPublic: field.access.indexOf(APrivate) == -1,
                    isOverride: field.access.indexOf(AOverride) != -1,
                    args: [for (arg in func.args) {
                        name: arg.name,
                        type: arg.type != null ? haxe.macro.ComplexTypeTools.toString(arg.type) : 'Dynamic',
                        optional: arg.opt
                    }],
                    returnType: func.ret != null ? haxe.macro.ComplexTypeTools.toString(func.ret) : 'Void',
                    metadata: extractFieldMetadata(field.meta),
                    position: Context.getPosInfos(field.pos),
                    doc: field.doc
                };

                collectedFunctions.push(functionInfo);

            default:
                // Not a function
        }
    }

    static function extractFieldMetadata(metadata:Array<MetadataEntry>):Array<String> {
        var result:Array<String> = [];
        if (metadata != null) {
            for (meta in metadata) {
                var metaStr = '@${meta.name}';
                if (meta.params != null && meta.params.length > 0) {
                    metaStr += '(';
                    for (i in 0...meta.params.length) {
                        if (i > 0) metaStr += ', ';
                        metaStr += haxe.macro.ExprTools.toString(meta.params[i]);
                    }
                    metaStr += ')';
                }
                result.push(metaStr);
            }
        }
        return result;
    }

    /**
     * Called when generation is complete - saves all collected data
     */
    static function onGenerateComplete(types:Array<Type>):Void {
        try {
            // Collect additional type information from the generated types
            for (type in types) {
                collectAdditionalTypeData(type);
            }

            // Create comprehensive build data
            var buildData = {
                buildTimestamp: buildMetadata.buildTimestamp,
                haxeVersion: buildMetadata.haxeVersion,
                targetPlatform: buildMetadata.targetPlatform,
                buildFlags: buildMetadata.buildFlags,
                classes: collectedClasses,
                abstracts: collectedAbstracts,
                typedefs: collectedTypedefs,
                enums: collectedEnums,
                functions: collectedFunctions,
                statistics: {
                    totalClasses: collectedClasses.length,
                    totalAbstracts: collectedAbstracts.length,
                    totalTypedefs: collectedTypedefs.length,
                    totalEnums: collectedEnums.length,
                    totalFunctions: collectedFunctions.length
                }
            };

            // Save the data
            saveBuildData(buildData);

            trace('TypeCollectionMacro: Build complete - collected ${collectedClasses.length} classes, ${collectedFunctions.length} functions');

        } catch (e:Dynamic) {
            trace('TypeCollectionMacro: Error in onGenerateComplete: $e');
        }
    }

    static function collectAdditionalTypeData(type:Type):Void {
        switch (type) {
            case TAbstract(abstractRef, params):
                var abstractType = abstractRef.get();
                if (!isAlreadyCollected(abstractType.name, collectedAbstracts)) {
                    collectedAbstracts.push({
                        name: abstractType.name,
                        pack: abstractType.pack,
                        module: abstractType.module,
                        type: TypeTools.toString(abstractType.type),
                        from: [for (f in abstractType.from) TypeTools.toString(f.t)],
                        to: [for (t in abstractType.to) TypeTools.toString(t.t)],
                        metadata: extractMetadata(abstractType.meta),
                        doc: abstractType.doc,
                        position: {
                            file: Context.getPosInfos(abstractType.pos).file,
                            line: Context.getPosInfos(abstractType.pos).min
                        }
                    });
                }

            case TType(typedefRef, params):
                var typedefType = typedefRef.get();
                if (!isAlreadyCollected(typedefType.name, collectedTypedefs)) {
                    collectedTypedefs.push({
                        name: typedefType.name,
                        pack: typedefType.pack,
                        module: typedefType.module,
                        type: TypeTools.toString(typedefType.type),
                        metadata: extractMetadata(typedefType.meta),
                        doc: typedefType.doc,
                        position: {
                            file: Context.getPosInfos(typedefType.pos).file,
                            line: Context.getPosInfos(typedefType.pos).min
                        }
                    });
                }

            case TEnum(enumRef, params):
                var enumType = enumRef.get();
                if (!isAlreadyCollected(enumType.name, collectedEnums)) {
                    collectedEnums.push({
                        name: enumType.name,
                        pack: enumType.pack,
                        module: enumType.module,
                        constructs: [for (name => construct in enumType.constructs) {
                            name: name,
                            type: TypeTools.toString(construct.type),
                            doc: construct.doc,
                            metadata: extractMetadata(construct.meta)
                        }],
                        metadata: extractMetadata(enumType.meta),
                        doc: enumType.doc,
                        position: {
                            file: Context.getPosInfos(enumType.pos).file,
                            line: Context.getPosInfos(enumType.pos).min
                        }
                    });
                }

            default:
                // Other types already handled by class collection
        }
    }

    static function isAlreadyCollected(name:String, collection:Array<Dynamic>):Bool {
        for (item in collection) {
            if (item.name == name) return true;
        }
        return false;
    }

    static function saveBuildData(data:Dynamic):Void {
        try {
            var outputPath = "export/builddata/";
            if (!FileSystem.exists(outputPath)) {
                FileSystem.createDirectory(outputPath);
            }

            // Save complete build data
            var jsonData = Json.stringify(data, null, "  ");
            File.saveContent(outputPath + "type_collection_data.json", jsonData);

            // Save compressed version for runtime
            var compressedData = {
                timestamp: data.buildTimestamp,
                platform: data.targetPlatform,
                classes: data.classes.map(c -> {
                    name: c.name,
                    pack: c.pack.join('.'),
                    fields: c.fields.map(f -> f.name)
                }),
                abstracts: data.abstracts.map(a -> {
                    name: a.name,
                    pack: a.pack.join('.'),
                    type: a.type
                }),
                functions: data.functions.map(f -> {
                    name: f.name,
                    className: f.className,
                    isStatic: f.isStatic,
                    metadata: f.metadata
                }),
                statistics: data.statistics
            };

            var compressedJson = Json.stringify(compressedData, null, "");
            File.saveContent(outputPath + "type_collection_compressed.json", compressedJson);

            // Generate runtime accessor
            generateRuntimeAccessor(outputPath, data);

            #if verbose
            trace('TypeCollectionMacro: Saved build data to ${outputPath}');
            #end

        } catch (e:Dynamic) {
            #if verbose
            trace('TypeCollectionMacro: Error saving build data: $e');
            #end
        }
    }

    static function generateRuntimeAccessor(outputPath:String, data:Dynamic):Void {
        var stats = data.statistics;
        var accessorCode = 'package yutautil.typeregistry;\n\n';
        accessorCode += '/**\n * Auto-generated type collection data accessor\n';
        accessorCode += ' * Generated at: ${Date.now()}\n */\n';
        accessorCode += 'class TypeCollectionAccessor {\n';
        accessorCode += '    public static var buildTimestamp:Float = ${data.buildTimestamp};\n';
        accessorCode += '    public static var targetPlatform:String = "${data.targetPlatform}";\n';
        accessorCode += '    public static var classCount:Int = ${stats.totalClasses};\n';
        accessorCode += '    public static var abstractCount:Int = ${stats.totalAbstracts};\n';
        accessorCode += '    public static var functionCount:Int = ${stats.totalFunctions};\n';
        accessorCode += '    public static var enumCount:Int = ${stats.totalEnums};\n';
        accessorCode += '    public static var typedefCount:Int = ${stats.totalTypedefs};\n';
        accessorCode += '    \n';
        accessorCode += '    public static function getDataPath():String {\n';
        accessorCode += '        return "export/builddata/type_collection_compressed.json";\n';
        accessorCode += '    }\n';
        accessorCode += '    \n';
        accessorCode += '    public static function getFullDataPath():String {\n';
        accessorCode += '        return "export/builddata/type_collection_data.json";\n';
        accessorCode += '    }\n';
        accessorCode += '    \n';
        accessorCode += '    public static function isDataAvailable():Bool {\n';
        accessorCode += '        return sys.FileSystem.exists(getDataPath());\n';
        accessorCode += '    }\n';
        accessorCode += '}\n';

        File.saveContent("source/yutautil/typeregistry/TypeCollectionAccessor.hx", accessorCode);
    }
}
