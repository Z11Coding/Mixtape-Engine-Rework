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
 * Applied automatically to all classes via global metadata.
 *
 * Enhanced features:
 * - Embeds type data as Haxe resources for release builds (no export folder needed)
 * - Detects generic type parameters on all types
 * - Collects property access info (getter/setter kinds)
 * - Collects abstract "to" and "from" conversion functions with field details
 * - Stores original type paths (without _Impl_ suffix) for proper name resolution
 * - Collects abstract impl class fields for runtime abstract method dispatch
 */
class TypeCollectionMacro {
    // Storage for collected data across all classes (public for AbstractConversionMacro access)
    public static var collectedClasses:Array<Dynamic> = [];
    public static var collectedAbstracts:Array<Dynamic> = [];
    public static var collectedTypedefs:Array<Dynamic> = [];
    public static var collectedEnums:Array<Dynamic> = [];
    public static var collectedFunctions:Array<Dynamic> = [];
    public static var collectedEditableFunctions:Array<Dynamic> = []; // Functions with original expressions for source editing
    static var buildMetadata:Dynamic = null;
    static var initialized:Bool = false;
    static var abstractDataDefined:Bool = false;

    // Resource key names for embedded data
    public static inline var RESOURCE_KEY_FULL = "typeregistry_full_data";
    public static inline var RESOURCE_KEY_COMPRESSED = "typeregistry_compressed_data";
    public static inline var INSTRUMENTED_META = ":sourceEditorInstrumented";

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

        // Collect original function expressions and metadata BEFORE instrumentation
        collectOriginalFunctions(fields, classType);

        // Create a copy of fields and instrument the copy
        var instrumentedFields = copyAndInstrumentFields(fields, classType);

        // Register completion callback on first run
        if (collectedClasses.length == 1) {
            Context.onAfterTyping(onGenerateComplete);
            trace("TypeCollectionMacro: Registered onAfterTyping callback");
        }

        return instrumentedFields;
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

        // Define AbstractData early (before Abstract.hx is typed) so Abstract can reference it.
        // AbstractData has a single @:to Dynamic method - no type scanning needed.
        if (!abstractDataDefined) {
            abstractDataDefined = true;
            try {
                yutautil.AbstractConversionMacro.generateAbstractDataModule();
            } catch (e:Dynamic) {
                trace('TypeCollectionMacro: Error generating AbstractData early: $e');
            }
        }
    }

    /**
     * Extracts generic type parameter names from a ClassType.
     * Returns an array of parameter name strings, or empty array if not generic.
     */
    static function extractTypeParams(params:Array<TypeParameter>):Array<String> {
        if (params == null || params.length == 0) return [];
        return [for (p in params) p.name];
    }

    /**
     * Determines if a type has generic parameters based on metadata or type params.
     */
    static function hasGenericParams(metadata:haxe.macro.MetaAccess, params:Array<TypeParameter>):Bool {
        // Check for @:generic metadata
        if (metadata.has(":generic")) return true;
        // Check if there are actual type parameters
        if (params != null && params.length > 0) return true;
        return false;
    }

    /**
     * Compute the original type path (the Haxe-facing name, not the _Impl_ name).
     * For a class named "Num_Impl_" in pack ["yutautil", "_Num"], the original path is "yutautil.Num".
     * For normal classes, returns the standard pack.Name path.
     * For sub-types (e.g. SpeedEvent in states.PlayState), returns module.Name (states.PlayState.SpeedEvent).
     */
    static function computeOriginalTypePath(name:String, pack:Array<String>, module:String):String {
        // If this is an _Impl_ class, derive the original abstract name
        if (name.endsWith("_Impl_")) {
            var abstractName = name.substr(0, name.length - 6); // Strip "_Impl_"
            // The module usually contains the real path, e.g. "yutautil.Num"
            if (module != null && module.length > 0) {
                return module;
            }
            // Fallback: reconstruct from pack, skipping the internal sub-package
            var cleanPack = pack.filter(function(p) return !p.startsWith("_"));
            if (cleanPack.length > 0) {
                return cleanPack.join(".") + "." + abstractName;
            }
            return abstractName;
        }
        // Normal type - check if this is a sub-type of its module
        // e.g. SpeedEvent in module states.PlayState → states.PlayState.SpeedEvent
        // vs Num in module yutautil.Num → yutautil.Num (module name matches type name)
        if (module != null && module.length > 0) {
            // Extract the module's own name (last segment)
            var moduleParts = module.split(".");
            var moduleName = moduleParts[moduleParts.length - 1];

            if (moduleName == name) {
                // Type IS the primary type of the module (e.g. Num in yutautil.Num)
                return module;
            } else {
                // Type is a sub-type defined inside another module
                // (e.g. SpeedEvent in states.PlayState → states.PlayState.SpeedEvent)
                return module + "." + name;
            }
        }
        var packStr = pack.join(".");
        return packStr.length > 0 ? packStr + "." + name : name;
    }

    static function collectClassData(classType:ClassType, fields:Array<Field>):Void {
        try {
            var typeParams = extractTypeParams(classType.params);
            var isGeneric = hasGenericParams(classType.meta, classType.params);
            var originalPath = computeOriginalTypePath(classType.name, classType.pack, classType.module);

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
                },
                // New fields
                typeParams: typeParams,
                isGeneric: isGeneric,
                originalTypePath: originalPath,
                isImplClass: classType.name.endsWith("_Impl_")
            };

            // Collect instance fields with property info
            for (field in classType.fields.get()) {
                classInfo.fields.push(extractFieldInfoEnhanced(field));
            }

            // Collect static fields with property info
            for (field in classType.statics.get()) {
                classInfo.staticFields.push(extractFieldInfoEnhanced(field));
            }

            // Collect functions from build fields
            for (field in fields) {
                collectFieldFunctions(field, classType.name);
            }

            collectedClasses.push(classInfo);

            #if verbose
            trace('TypeCollectionMacro: Collected class ${classType.name} (${classInfo.fields.length} fields, generic=${isGeneric})');
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

    /**
     * Enhanced field info extraction that includes property access kinds (getter/setter).
     */
    static function extractFieldInfoEnhanced(field:ClassField):Dynamic {
        var fieldData:Dynamic = {
            name: field.name,
            type: TypeTools.toString(field.type),
            isPublic: field.isPublic,
            doc: field.doc,
            metadata: extractMetadata(field.meta),
            kind: null,
            position: {
                file: Context.getPosInfos(field.pos).file,
                line: Context.getPosInfos(field.pos).min
            },
            // New property-related fields
            propertyAccess: null
        };

        switch (field.kind) {
            case FVar(read, write):
                fieldData.kind = 'var';
                fieldData.propertyAccess = {
                    read: varAccessToString(read),
                    write: varAccessToString(write)
                };
            case FMethod(k):
                fieldData.kind = 'method';
                fieldData.propertyAccess = null;
        }

        return fieldData;
    }

    /**
     * Convert a VarAccess enum to a human-readable string.
     */
    static function varAccessToString(access:VarAccess):String {
        if (access == null) return "default";
        return switch (access) {
            case AccNormal: "default";
            case AccNo: "null";
            case AccNever: "never";
            case AccCall: "get/set";
            case AccInline: "inline";
            case AccRequire(_, _): "require";
            case AccCtor: "ctor";
            case _: "default";
        };
    }

    /**
     * Legacy field extraction for backward compatibility with non-enhanced consumers.
     */
    static function extractFieldInfo(field:ClassField):Dynamic {
        return extractFieldInfoEnhanced(field);
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
     * Collect original function data (expressions, metadata) before any instrumentation.
     * This captures the original function code for the source editor.
     */
    static function collectOriginalFunctions(fields:Array<Field>, classType:ClassType):Void {
        var classPath = classType.pack.concat([classType.name]).join(".");

        for (field in fields) {
            switch (field.kind) {
                case FFun(func):
                    // Skip constructors
                    if (field.name == "new") continue;

                    var functionPos = Context.getPosInfos(field.pos);
                    var filePath = functionPos.file;
                    var lineNum = functionPos.min;
                    var functionId = '$filePath:${field.name}:$lineNum';

                    // Capture the ORIGINAL expression as a string BEFORE any modification
                    var originalExpr = haxe.macro.ExprTools.toString(func.expr);

                    var isStatic = field.access.indexOf(AStatic) != -1;
                    var isPublic = field.access.indexOf(APrivate) == -1;

                    // Get return type
                    var returnType = "Void";
                    if (func.ret != null) {
                        returnType = haxe.macro.ComplexTypeTools.toString(func.ret);
                    }

                    // Get arguments
                    var args:Array<Dynamic> = [];
                    for (arg in func.args) {
                        var argType = arg.type != null ? haxe.macro.ComplexTypeTools.toString(arg.type) : 'Dynamic';
                        args.push({
                            name: arg.name,
                            type: argType,
                            optional: arg.opt
                        });
                    }

                    var editableFunction:Dynamic = {
                        functionId: functionId,
                        functionName: field.name,
                        className: classType.name,
                        classPath: classPath,
                        isStatic: isStatic,
                        isPublic: isPublic,
                        returnType: returnType,
                        args: args,
                        filePath: filePath,
                        lineNumber: lineNum,
                        originalExpression: originalExpr,
                        doc: field.doc
                    };

                    collectedEditableFunctions.push(editableFunction);

                default:
            }
        }
    }

    /**
     * Create a copy of the fields array and instrument the copy with intercept checks.
     * Returns the instrumented copy; original field data is preserved in compilation data.
     */
    static function copyAndInstrumentFields(fields:Array<Field>, classType:ClassType):Array<Field> {
        // Deep copy the fields array
        var instrumentedFields:Array<Field> = [];

        for (field in fields) {
            var copiedField:Field = {
                name: field.name,
                kind: field.kind,
                access: field.access.copy(),
                pos: field.pos,
                meta: field.meta,
                doc: field.doc
            };

            // Instrument this copy
            switch (copiedField.kind) {
                case FFun(func):
                    if (hasMeta(copiedField.meta, INSTRUMENTED_META)) {
                        instrumentedFields.push(copiedField);
                        continue;
                    }

                    // Skip constructors
                    if (copiedField.name == "new") {
                        instrumentedFields.push(copiedField);
                        continue;
                    }

                    var functionPos = Context.getPosInfos(copiedField.pos);
                    var filePath = functionPos.file;
                    var lineNum = functionPos.min;
                    var functionId = '$filePath:${copiedField.name}:$lineNum';

                    // Build argument expressions for the intercept call
                    var argNames:Array<String> = [for (arg in func.args) arg.name];
                    var argExprs:Array<Expr> = [for (name in argNames) macro $i{name}];

                    // Determine context for this function
                    var isStatic = copiedField.access.indexOf(AStatic) != -1;
                    var contextExpr:Expr = if (isStatic) {
                        macro null;
                    } else {
                        macro this;
                    };

                    var hadInline = copiedField.access.indexOf(AInline) != -1;
                    var hasAnyReturn = hasReturnStatement(func.expr);
                    if (hadInline && hasAnyReturn) {
                        copiedField.access = copiedField.access.filter(function(access) return access != AInline);
                    }

                    var isInline = copiedField.access.indexOf(AInline) != -1;
                    var isVoidReturn = isVoidReturnType(func.ret, func.expr);

                    if (isInline) {
                        if (isVoidReturn) {
                            var originalExpr = func.expr != null ? func.expr : macro {};
                            func.expr = macro {
                                var _interceptResult = yutautil.typeregistry.RuntimeFunctionRegistry.get().intercept($v{functionId}, $contextExpr, $a{argExprs});
                                if (!_interceptResult.intercepted) {
                                    $e{originalExpr};
                                }
                            };
                        } else {
                            var originalValueExpr = buildInlineValueExpr(func.expr);
                            func.expr = macro {
                                var _interceptResult = yutautil.typeregistry.RuntimeFunctionRegistry.get().intercept($v{functionId}, $contextExpr, $a{argExprs});
                                return _interceptResult.intercepted ? cast _interceptResult.value : $e{originalValueExpr};
                            };
                        }
                    } else {
                        var interceptCall = if (isVoidReturn) {
                            macro {
                                var _interceptResult = yutautil.typeregistry.RuntimeFunctionRegistry.get().intercept($v{functionId}, $contextExpr, $a{argExprs});
                                if (_interceptResult.intercepted) {
                                    return;
                                }
                            };
                        } else {
                            macro {
                                var _interceptResult = yutautil.typeregistry.RuntimeFunctionRegistry.get().intercept($v{functionId}, $contextExpr, $a{argExprs});
                                if (_interceptResult.intercepted) {
                                    return cast _interceptResult.value;
                                }
                            };
                        };

                        // Prepend intercept check to function body
                        if (func.expr != null) {
                            func.expr = {
                                expr: EBlock([interceptCall, func.expr]),
                                pos: func.expr.pos
                            };
                        }
                    }

                    if (!hasMeta(copiedField.meta, INSTRUMENTED_META)) {
                        if (copiedField.meta == null) {
                            copiedField.meta = [];
                        }
                        copiedField.meta.push({
                            name: INSTRUMENTED_META,
                            params: [],
                            pos: copiedField.pos
                        });
                    }

                    copiedField.kind = FFun(func);

                default:
            }

            instrumentedFields.push(copiedField);
        }

        return instrumentedFields;
    }

    static function hasMeta(meta:Array<MetadataEntry>, name:String):Bool {
        if (meta == null) return false;
        for (entry in meta) {
            if (entry.name == name) return true;
        }
        return false;
    }

    static function isVoidReturnType(ret:ComplexType, expr:Expr):Bool {
        if (ret == null) {
            return !hasReturnValue(expr);
        }
        return switch (ret) {
            case TPath(path):
                path.name == "Void" && (path.pack == null || path.pack.length == 0);
            default:
                false;
        };
    }

    static function hasReturnValue(expr:Expr):Bool {
        if (expr == null || expr.expr == null) return false;
        return switch (expr?.expr) {
            case EReturn(e):
                e != null;
            case EFunction(_):
                false;
            case EBlock(exprs):
                Lambda.exists(exprs, hasReturnValue);
            case EIf(cond, ifExpr, elseExpr):
                hasReturnValue(ifExpr) || (elseExpr != null && hasReturnValue(elseExpr));
            case ESwitch(switchExpr, cases, defaultExpr):
                var found = false;
                for (caseItem in cases) {
                    if (hasReturnValue(caseItem.expr)) {
                        found = true;
                        break;
                    }
                }
                found || (defaultExpr != null && hasReturnValue(defaultExpr));
            case ETry(tryExpr, catches):
                if (hasReturnValue(tryExpr)) {
                    true;
                } else {
                    var found = false;
                    for (catchItem in catches) {
                        if (hasReturnValue(catchItem.expr)) {
                            found = true;
                            break;
                        }
                    }
                    found;
                }
            case EWhile(_, body, _):
                hasReturnValue(body);
            case EFor(_, body):
                hasReturnValue(body);
            case EBinop(_, left, right):
                hasReturnValue(left) || hasReturnValue(right);
            case EUnop(_, _, sub):
                hasReturnValue(sub);
            case ECall(target, params):
                hasReturnValue(target) || Lambda.exists(params, hasReturnValue);
            case EArray(arrayExpr, indexExpr):
                hasReturnValue(arrayExpr) || hasReturnValue(indexExpr);
            case EField(owner, _):
                hasReturnValue(owner);
            case EParenthesis(inner):
                hasReturnValue(inner);
            case EObjectDecl(fields):
                Lambda.exists(fields, function(field) return hasReturnValue(field.expr));
            case EArrayDecl(values):
                Lambda.exists(values, hasReturnValue);
            case ENew(_, params):
                Lambda.exists(params, hasReturnValue);
            case ETernary(cond, ifExpr, elseExpr):
                hasReturnValue(cond) || hasReturnValue(ifExpr) || hasReturnValue(elseExpr);
            case ECheckType(value, _):
                hasReturnValue(value);
            case ECast(value, _):
                value != null && hasReturnValue(value);
            case EMeta(_, inner):
                hasReturnValue(inner);
            default:
                false;
        };
    }

    static function buildInlineValueExpr(expr:Expr):Expr {
        if (expr == null) return macro null;
        return macro (function() return $e{expr})();
    }

    static function hasReturnStatement(expr:Expr):Bool {
        if (expr == null || expr.expr == null) return false;
        return switch (expr.expr) {
            case EReturn(_):
                true;
            case EFunction(_):
                false;
            case EBlock(exprs):
                Lambda.exists(exprs, hasReturnStatement);
            case EIf(_, ifExpr, elseExpr):
                hasReturnStatement(ifExpr) || (elseExpr != null && hasReturnStatement(elseExpr));
            case ESwitch(_, cases, defaultExpr):
                var found = false;
                for (caseItem in cases) {
                    if (hasReturnStatement(caseItem.expr)) {
                        found = true;
                        break;
                    }
                }
                found || (defaultExpr != null && hasReturnStatement(defaultExpr));
            case ETry(tryExpr, catches):
                if (hasReturnStatement(tryExpr)) {
                    true;
                } else {
                    var found = false;
                    for (catchItem in catches) {
                        if (hasReturnStatement(catchItem.expr)) {
                            found = true;
                            break;
                        }
                    }
                    found;
                }
            case EWhile(_, body, _):
                hasReturnStatement(body);
            case EFor(_, body):
                hasReturnStatement(body);
            case EBinop(_, left, right):
                hasReturnStatement(left) || hasReturnStatement(right);
            case EUnop(_, _, sub):
                hasReturnStatement(sub);
            case ECall(target, params):
                hasReturnStatement(target) || Lambda.exists(params, hasReturnStatement);
            case EArray(arrayExpr, indexExpr):
                hasReturnStatement(arrayExpr) || hasReturnStatement(indexExpr);
            case EField(owner, _):
                hasReturnStatement(owner);
            case EParenthesis(inner):
                hasReturnStatement(inner);
            case EObjectDecl(fields):
                Lambda.exists(fields, function(field) return hasReturnStatement(field.expr));
            case EArrayDecl(values):
                Lambda.exists(values, hasReturnStatement);
            case ENew(_, params):
                Lambda.exists(params, hasReturnStatement);
            case ETernary(cond, ifExpr, elseExpr):
                hasReturnStatement(cond) || hasReturnStatement(ifExpr) || hasReturnStatement(elseExpr);
            case ECheckType(value, _):
                hasReturnStatement(value);
            case ECast(value, _):
                value != null && hasReturnStatement(value);
            case EMeta(_, inner):
                hasReturnStatement(inner);
            default:
                false;
        };
    }

    /**
     * Called when generation is complete - saves all collected data and embeds as resources
     */
    static function onGenerateComplete(types:Array<ModuleType>):Void {
        try {
            // Collect additional type information from the generated types
            for (type in types.map(t -> haxe.macro.TypeTools.fromModuleType(t))) {
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
                editableFunctions: collectedEditableFunctions,
                statistics: {
                    totalClasses: collectedClasses.length,
                    totalAbstracts: collectedAbstracts.length,
                    totalTypedefs: collectedTypedefs.length,
                    totalEnums: collectedEnums.length,
                    totalFunctions: collectedFunctions.length,
                    totalEditableFunctions: collectedEditableFunctions.length
                }
            };

            // Save the data to files AND embed as resources
            saveBuildData(buildData);

            trace('TypeCollectionMacro: Build complete - collected ${collectedClasses.length} classes, '
                + '${collectedAbstracts.length} abstracts, ${collectedFunctions.length} functions');

            // AbstractData is already defined in initializeBuildCollection() with a single @:to Dynamic.
            // It must be defined before Abstract.hx is typed so Abstract can reference it.

        } catch (e:Dynamic) {
            trace('TypeCollectionMacro: Error in onGenerateComplete: $e');
        }
    }

    static function collectAdditionalTypeData(type:Type):Void {
        switch (type) {
            case TAbstract(abstractRef, params):
                var abstractType = abstractRef.get();
                if (!isAlreadyCollected(abstractType.name, collectedAbstracts)) {
                    var typeParams = extractTypeParams(abstractType.params);
                    var isGeneric = hasGenericParams(abstractType.meta, abstractType.params);

                    // Build the original type path for this abstract
                    var originalPath = computeOriginalTypePath(abstractType.name, abstractType.pack, abstractType.module);

                    // Build the _Impl_ class name that Haxe generates
                    var implClassName = abstractType.name + "_Impl_";
                    // The impl class lives in a sub-package like pack._ModuleName
                    var moduleParts = abstractType.module.split(".");
                    var moduleName = moduleParts.length > 0 ? moduleParts[moduleParts.length - 1] : abstractType.name;
                    var implPack = abstractType.pack.copy();
                    implPack.push("_" + moduleName);
                    var implFullName = implPack.join(".") + "." + implClassName;

                    // Collect enhanced "from" conversion info
                    var fromConversions:Array<Dynamic> = [];
                    for (f in abstractType.from) {
                        var convInfo:Dynamic = {
                            type: TypeTools.toString(f.t),
                            field: f.field != null ? {
                                name: f.field.name,
                                type: TypeTools.toString(f.field.type),
                                isPublic: f.field.isPublic,
                                doc: f.field.doc
                            } : null
                        };
                        fromConversions.push(convInfo);
                    }

                    // Collect enhanced "to" conversion info
                    var toConversions:Array<Dynamic> = [];
                    for (t in abstractType.to) {
                        var convInfo:Dynamic = {
                            type: TypeTools.toString(t.t),
                            field: t.field != null ? {
                                name: t.field.name,
                                type: TypeTools.toString(t.field.type),
                                isPublic: t.field.isPublic,
                                doc: t.field.doc
                            } : null
                        };
                        toConversions.push(convInfo);
                    }

                    // Collect impl class fields (these are the actual runtime methods)
                    var implFields:Array<Dynamic> = [];
                    try {
                        // Try to find the corresponding _Impl_ class in already-collected classes
                        for (cls in collectedClasses) {
                            if (cls.name == implClassName) {
                                implFields = cls.staticFields;
                                break;
                            }
                        }
                    } catch (e:Dynamic) {
                        // Impl class may not be collected yet
                    }

                    // Collect abstract array fields (operator overloads, methods, etc.)
                    var abstractFields:Array<Dynamic> = [];
                    if (abstractType.impl != null) {
                        var implClass = abstractType.impl.get();
                        // Collect static fields from impl - these are the abstract's methods at runtime
                        for (field in implClass.statics.get()) {
                            abstractFields.push({
                                name: field.name,
                                type: TypeTools.toString(field.type),
                                isPublic: field.isPublic,
                                doc: field.doc,
                                metadata: extractMetadata(field.meta),
                                kind: switch (field.kind) {
                                    case FVar(_, _): 'var';
                                    case FMethod(_): 'method';
                                },
                                isOperator: field.name.startsWith("_hx_") || field.meta.has(":op"),
                                operatorName: extractOperatorName(field)
                            });
                        }
                    }

                    collectedAbstracts.push({
                        name: abstractType.name,
                        pack: abstractType.pack,
                        module: abstractType.module,
                        type: TypeTools.toString(abstractType.type),
                        // Legacy simple arrays for backward compatibility
                        from: [for (f in abstractType.from) TypeTools.toString(f.t)],
                        to: [for (t in abstractType.to) TypeTools.toString(t.t)],
                        // Enhanced conversion info with field details
                        fromConversions: fromConversions,
                        toConversions: toConversions,
                        metadata: extractMetadata(abstractType.meta),
                        doc: abstractType.doc,
                        position: {
                            file: Context.getPosInfos(abstractType.pos).file,
                            line: Context.getPosInfos(abstractType.pos).min
                        },
                        // New fields
                        typeParams: typeParams,
                        isGeneric: isGeneric,
                        originalTypePath: originalPath,
                        implClassName: implClassName,
                        implFullName: implFullName,
                        implFields: abstractFields,
                        // Whether this abstract has an impl class at runtime
                        hasImplClass: abstractType.impl != null
                    });
                }

            case TType(typedefRef, params):
                var typedefType = typedefRef.get();
                if (!isAlreadyCollected(typedefType.name, collectedTypedefs)) {
                    var typeParams = extractTypeParams(typedefType.params);

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
                        },
                        // New fields
                        typeParams: typeParams,
                        isGeneric: typeParams.length > 0,
                        originalTypePath: computeOriginalTypePath(typedefType.name, typedefType.pack, typedefType.module)
                    });
                }

            case TEnum(enumRef, params):
                var enumType = enumRef.get();
                if (!isAlreadyCollected(enumType.name, collectedEnums)) {
                    var typeParams = extractTypeParams(enumType.params);

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
                        },
                        // New fields
                        typeParams: typeParams,
                        isGeneric: typeParams.length > 0,
                        originalTypePath: computeOriginalTypePath(enumType.name, enumType.pack, enumType.module)
                    });
                }

            default:
                // Other types already handled by class collection
        }
    }

    /**
     * Extract operator name from field metadata if it's an operator overload.
     */
    static function extractOperatorName(field:ClassField):String {
        if (field.meta.has(":op")) {
            for (meta in field.meta.get()) {
                if (meta.name == ":op" && meta.params != null && meta.params.length > 0) {
                    return haxe.macro.ExprTools.toString(meta.params[0]);
                }
            }
        }
        // Detect from hx name patterns
        var name = field.name;
        if (name.startsWith("_hx_")) return name;
        return null;
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

            // Save compressed version for runtime (includes abstract detail now)
            var compressedData = {
                timestamp: data.buildTimestamp,
                platform: data.targetPlatform,
                classes: data.classes.map(function(c:Dynamic):Dynamic {
                    return {
                        name: c.name,
                        pack: c.pack.join('.'),
                        fields: c.fields.map(function(f:Dynamic):Dynamic { return f.name; }),
                        typeParams: c.typeParams,
                        isGeneric: c.isGeneric,
                        originalTypePath: c.originalTypePath,
                        isImplClass: c.isImplClass
                    };
                }),
                abstracts: data.abstracts.map(function(a:Dynamic):Dynamic {
                    return {
                        name: a.name,
                        pack: a.pack.join('.'),
                        type: a.type,
                        from: a.from,
                        to: a.to,
                        fromConversions: a.fromConversions,
                        toConversions: a.toConversions,
                        typeParams: a.typeParams,
                        isGeneric: a.isGeneric,
                        originalTypePath: a.originalTypePath,
                        implClassName: a.implClassName,
                        implFullName: a.implFullName,
                        implFields: a.implFields,
                        hasImplClass: a.hasImplClass
                    };
                }),
                functions: data.functions.map(function(f:Dynamic):Dynamic {
                    return {
                        name: f.name,
                        className: f.className,
                        isStatic: f.isStatic,
                        metadata: f.metadata
                    };
                }),
                editableFunctions: data.editableFunctions,
                statistics: data.statistics
            };

            var compressedJson = Json.stringify(compressedData, null, "");
            File.saveContent(outputPath + "type_collection_compressed.json", compressedJson);

            // Embed both data files as Haxe resources for release builds
            embedAsResources(jsonData, compressedJson);

            // Generate runtime accessor
            generateRuntimeAccessor(outputPath, data);

            trace('TypeCollectionMacro: Saved build data to ${outputPath}');

        } catch (e:Dynamic) {
            trace('TypeCollectionMacro: Error saving build data: $e');
        }
    }

    /**
     * Embed the type collection data as Haxe resources.
     * This allows the data to be available at runtime even without the export folder
     * (e.g., in release builds or distributed binaries).
     */
    static function embedAsResources(fullJson:String, compressedJson:String):Void {
        try {
            // Embed compressed data as a resource (smaller, preferred for runtime)
            Context.addResource(RESOURCE_KEY_COMPRESSED, haxe.io.Bytes.ofString(compressedJson));
            trace('TypeCollectionMacro: Embedded compressed type data as resource (${compressedJson.length} bytes)');

            // Embed full data as a resource (larger, but has complete info)
            Context.addResource(RESOURCE_KEY_FULL, haxe.io.Bytes.ofString(fullJson));
            trace('TypeCollectionMacro: Embedded full type data as resource (${fullJson.length} bytes)');
        } catch (e:Dynamic) {
            trace('TypeCollectionMacro: Warning - failed to embed resources: $e');
        }
    }

    static function generateRuntimeAccessor(outputPath:String, data:Dynamic):Void {
        var stats = data.statistics;
        var accessorCode = 'package yutautil.typeregistry;\n\n';
        accessorCode += '/**\n * Auto-generated type collection data accessor\n';
        accessorCode += ' * Generated at: ${Date.now()}\n';
        accessorCode += ' * \n';
        accessorCode += ' * Data is available via:\n';
        accessorCode += ' *   1. Embedded Haxe resources (always available, preferred for releases)\n';
        accessorCode += ' *   2. Filesystem files (available in dev builds with export folder)\n';
        accessorCode += ' */\n';
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
        accessorCode += '    \n';
        accessorCode += '    /**\n';
        accessorCode += '     * Check if embedded resource data is available (always true in builds with macro enabled)\n';
        accessorCode += '     */\n';
        accessorCode += '    public static function isResourceAvailable():Bool {\n';
        accessorCode += '        return haxe.Resource.getString("${RESOURCE_KEY_COMPRESSED}") != null;\n';
        accessorCode += '    }\n';
        accessorCode += '}\n';

        File.saveContent("source/yutautil/typeregistry/TypeCollectionAccessor.hx", accessorCode);
    }
}
