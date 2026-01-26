package yutautil;

#if macro
import haxe.io.Path;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import sys.FileSystem;
import sys.io.File;
import yutautil.YScript.YExpression;
import yutautil.YScript.YFunctionBody;
import yutautil.YScript.YScriptParser;
import yutautil.YScript.YStatement;
import yutautil.YScript.YType;
import yutautil.YScript.YVar;
import yutautil.YScript;

using StringTools;
#end

#if !macro
import yutautil.YScript.YClassInstance;
import yutautil.YScript;
#end

/**
 * Base interface for all YScript interpreted classes
 * Provides type safety and unified handling in interpretation mode
 */
interface YInterpClass {
    /**
     * Get the underlying YScript runtime instance
     */
    function getYScriptRuntime():yutautil.YScript;

    /**
     * Get the YScript class instance
     */
    function getYClassInstance():yutautil.YScript.YClassInstance;

    /**
     * Call a method on the YScript class
     */
    function callYMethod(methodName:String, args:Array<Dynamic>):Dynamic;

    /**
     * Get a field value from the YScript class
     */
    function getYField(fieldName:String):Dynamic;

    /**
     * Set a field value in the YScript class
     */
    function setYField(fieldName:String, value:Dynamic):Void;

    /**
     * Get the class name of this YScript class
     */
    function getYClassName():String;
}

/**
 * Conversion mode for YScript compilation
 */
enum ConversionMode {
    /**
     * Full conversion to native Haxe code with proper type conversion and optimization
     */
    FullConversion;

    /**
     * Interpreter mode - generates wrapper classes that run YScript via interpreter
     */
    InterpreterMode;
}

/**
 * Configuration for YScript compilation
 */
typedef YSCompConfig = {
    /**
     * Conversion mode to use
     */
    var mode:ConversionMode;

    /**
     * Source directories to scan for .ys files (relative to project root)
     */
    var sourceDirs:Array<String>;

    /**
     * Debug information enabled
     */
    var debugInfo:Bool;
}

/**
 * Information extracted from a YScript module
 */
typedef ModuleInfo = {
    var packageName:Null<String>;
    var imports:Array<{path:String, alias:Null<String>}>;
    var classes:Array<ClassInfo>;
    var moduleLevelVars:Array<VarInfo>;
    var moduleLevelFunctions:Array<FunctionInfo>;
    var moduleLevelCalls:Array<YExpression>;
    var moduleName:String;
    var hasMainClass:Bool; // True if there's a class with the same name as the module
}

/**
 * Information about a YScript class
 */
typedef ClassInfo = {
    var name:String;
    var superClass:Null<String>;
    var interfaces:Array<String>;
    var fields:Array<VarInfo>;
    var methods:Array<FunctionInfo>;
    var constructors:Array<FunctionInfo>;
    var isNested:Bool; // True if this is a nested class
    var parentClass:Null<String>; // Parent class name if nested
}

/**
 * Information about a YScript variable/field
 */
typedef VarInfo = {
    var name:String;
    var type:Dynamic; // YType - stored as Dynamic for macro compatibility
    var value:Dynamic; // Default value
}

/**
 * Information about a YScript function/method
 */
typedef FunctionInfo = {
    var name:String;
    var parameters:Array<VarInfo>;
    var returnType:Dynamic; // YType - stored as Dynamic for macro compatibility
    var body:Dynamic; // YFunctionBody - stored as Dynamic for macro compatibility
}

/**
 * YScript Compiler (YSComp) - Macro system for converting YScript files to Haxe types
 */
class YSComp {

    #if macro

    /**
     * Default configuration for YSComp
     */
    static var defaultConfig:YSCompConfig = {
        mode: ConversionMode.InterpreterMode,
        sourceDirs: ["source"],
        debugInfo: false
    };

    /**
     * Processed modules cache to avoid duplicates
     */
    static var processedModules:Map<String, Bool> = new Map();

    /**
     * Auto-initialization flag to prevent multiple calls
     */
    static var initialized:Bool = false;

    /**
     * Auto-initialization function that can be called from Project.xml
     * Usage: --macro yutautil.YSComp.initialize()
     */
    public static function initialize():Void {
        if (initialized) {
            return; // Prevent multiple initializations
        }
        initialized = true;

        var config = getConfigFromDefines();

        try {
            Context.onAfterInitMacros(function() {
                processYScriptFiles(config);
                trace('[YSComp] Initialization complete');
                Context.addResource("haxe_compiler_defines", haxe.io.Bytes.ofString(haxe.Json.stringify(Context.getDefines())));
            });

            if (config.debugInfo) {
                Context.info('YSComp initialization complete - will process YScript files after macro initialization', Context.currentPos());
            }
        } catch (e:Dynamic) {
            Context.error('YSComp initialization error: $e', Context.currentPos());
        }
    }


    /**
     * Main macro entry point - processes all YScript files in the project
     * Can be called directly or via initialize()
     */
    public static function process(?config:YSCompConfig):Void {
        var cfg = config ?? getConfigFromDefines();

        try {
            Context.onAfterInitMacros(function() {
                processYScriptFiles(cfg);
            });
        } catch (e:Dynamic) {
            Context.error('YSComp initialization error: $e', Context.currentPos());
        }
    }

    /**
     * Get configuration from compiler defines
     */
    static function getConfigFromDefines():YSCompConfig {
        var config = defaultConfig;

        // Read mode from compiler define
        var modeStr = Context.definedValue("YSCOMP_MODE");
        if (modeStr != null) {
            switch (modeStr) {
                case "FullConversion": config.mode = FullConversion;
                case "InterpreterMode": config.mode = InterpreterMode;
                default:
                    Context.warning('Unknown YSComp mode: $modeStr, using default', Context.currentPos());
            }
        }

        // Read debug info setting
        var debugStr = Context.definedValue("YSCOMP_DEBUG_INFO");
        if (debugStr != null) {
            config.debugInfo = debugStr.toLowerCase() == "true";
        }

        return config;
    }

    /**
     * Process all YScript files found in source directories
     */
    static function processYScriptFiles(config:YSCompConfig):Void {
        trace('[YSComp] Starting YScript file processing...');
        var projectRoot = Sys.getCwd();
        var ysFiles:Array<String> = [];

        trace('[YSComp] Scanning source directories: ' + config.sourceDirs.join(', '));

        // Scan for .ys files
        for (sourceDir in config.sourceDirs) {
            var fullSourcePath = Path.join([projectRoot, sourceDir]);
            trace('[YSComp] Checking directory: ' + fullSourcePath);
            if (FileSystem.exists(fullSourcePath) && FileSystem.isDirectory(fullSourcePath)) {
                scanDirectory(fullSourcePath, ysFiles, projectRoot);
                trace('[YSComp] Found ${ysFiles.length} .ys files so far');
            } else {
                trace('[YSComp] Directory not found: ' + fullSourcePath);
            }
        }

        trace('[YSComp] Total .ys files found: ' + ysFiles.length);
        for (file in ysFiles) {
            trace('[YSComp] Discovered: ' + file);
        }

        // Process each found .ys file
        for (ysFile in ysFiles) {
            trace('[YSComp] Processing file: ' + ysFile);
            try {
                processYScriptFile(ysFile, config);
                trace('[YSComp] Successfully processed: ' + ysFile);
            } catch (e:Dynamic) {
                trace('[YSComp] ERROR processing ' + ysFile + ': ' + e);
                Context.error('Failed to process YScript file $ysFile: $e', Context.currentPos());
            }
        }

        if (ysFiles.length > 0) {
            trace('[YSComp] Completed processing ${ysFiles.length} YScript files in ${config.mode} mode');
            Context.info('YSComp processed ${ysFiles.length} YScript files in ${config.mode} mode', Context.currentPos());
        } else {
            trace('[YSComp] No .ys files found to process');
        }
    }

    /**
     * Recursively scan directory for .ys files
     */
    static function scanDirectory(dir:String, ysFiles:Array<String>, projectRoot:String):Void {
        for (item in FileSystem.readDirectory(dir)) {
            var fullPath = Path.join([dir, item]);

            if (FileSystem.isDirectory(fullPath)) {
                // Skip common non-source directories
                if (item == "node_modules" || item == ".git" || item == "export" || item == "dump") {
                    continue;
                }
                scanDirectory(fullPath, ysFiles, projectRoot);
            } else if (item.endsWith(".ys")) {
                // Normalize paths to use forward slashes for consistent comparison
                var normalizedFullPath = fullPath.replace("\\", "/");
                var normalizedProjectRoot = projectRoot.replace("\\", "/");
                if (!normalizedProjectRoot.endsWith("/")) {
                    normalizedProjectRoot += "/";
                }

                var relativePath = normalizedFullPath.substring(normalizedProjectRoot.length);
                trace('[YSComp] Path calculation: fullPath=' + normalizedFullPath + ', projectRoot=' + normalizedProjectRoot + ', result=' + relativePath);
                trace('[YSComp] Found .ys file: ' + relativePath);
                ysFiles.push(relativePath);
            }
        }
    }

    /**
     * Process a single YScript file
     */
    static function processYScriptFile(ysFilePath:String, config:YSCompConfig):Void {
        trace('[YSComp] === Processing: ' + ysFilePath + ' ===');
        var projectRoot = Sys.getCwd();
        var fullYSPath = Path.join([projectRoot, ysFilePath]);

        if (!FileSystem.exists(fullYSPath)) {
            trace('[YSComp] ERROR: File not found: ' + fullYSPath);
            Context.error('YScript file not found: $ysFilePath', Context.currentPos());
            return;
        }

        try {
            trace('[YSComp] Reading file content: ' + fullYSPath);
            var ysContent = File.getContent(fullYSPath);
            trace('[YSComp] File size: ' + ysContent.length + ' characters');

            trace('[YSComp] Creating YScript parser...');
            var ysParser = new YScriptParser();
            trace('[YSComp] Parsing YScript content...');
            var statements = ysParser.parse(ysContent, ysFilePath);
            trace('[YSComp] Parsed ' + statements.length + ' statements');

            // Extract module information
            trace('[YSComp] Extracting module information...');
            var moduleInfo = extractModuleInfo(statements, ysFilePath);
            trace('[YSComp] Module name: ' + moduleInfo.moduleName);
            trace('[YSComp] Package: ' + (moduleInfo.packageName ?? 'null'));
            trace('[YSComp] Classes found: ' + moduleInfo.classes.length);
            trace('[YSComp] Module functions: ' + moduleInfo.moduleLevelFunctions.length);
            trace('[YSComp] Module variables: ' + moduleInfo.moduleLevelVars.length);

            // Get module path for registration
            var modulePath = getModulePathFromFile(ysFilePath);
            trace('[YSComp] Module path: ' + modulePath);

            // Skip if already processed
            if (processedModules.exists(modulePath)) {
                trace('[YSComp] Module already processed, skipping: ' + modulePath);
                return;
            }
            processedModules.set(modulePath, true);

            // Generate and register types based on mode
            trace('[YSComp] Generating types in ' + config.mode + ' mode...');
            switch (config.mode) {
                case FullConversion:
                    trace('[YSComp] Using FullConversion mode');
                    generateFullConversionTypes(moduleInfo, modulePath, ysFilePath, config);
                case InterpreterMode:
                    trace('[YSComp] Using InterpreterMode');
                    generateInterpreterModeTypes(moduleInfo, modulePath, ysFilePath, config);
            }

            trace('[YSComp] Type generation completed for: ' + modulePath);
            if (config.debugInfo) {
                Context.info('Generated types for: $modulePath from $ysFilePath', Context.currentPos());
            }
        } catch (e:Dynamic) {
            Context.error('Failed to process YScript file $ysFilePath: $e', Context.currentPos());
        }
    }

    /**
     * Get module path from YScript file path
     */
    static function getModulePathFromFile(ysFilePath:String):String {
        var pathObj = new Path(ysFilePath);

        // Convert file path to module path
        var parts = [];
        if (pathObj.dir != null && pathObj.dir.length > 0) {
            var dirParts = pathObj.dir.replace("\\", "/").split("/");
            for (part in dirParts) {
                if (part.length > 0 && part != "source") {
                    parts.push(part);
                }
            }
        }
        parts.push(pathObj.file);

        return parts.join(".");
    }

    /**
     * Extract module information from YScript statements
     */
    static function extractModuleInfo(statements:Array<YStatement>, filePath:String):ModuleInfo {
        trace('[YSComp] === Extracting Module Info ===');
        trace('[YSComp] Processing ' + statements.length + ' statements');

        var moduleInfo:ModuleInfo = {
            packageName: null,
            imports: [],
            classes: [],
            moduleLevelVars: [],
            moduleLevelFunctions: [],
            moduleLevelCalls: [],
            moduleName: Path.withoutExtension(Path.withoutDirectory(filePath)),
            hasMainClass: false
        };

        trace('[YSComp] Base module name: ' + moduleInfo.moduleName);

        // Extract package name from file path
        var pathObj = new Path(filePath);
        if (pathObj.dir != null && pathObj.dir.length > 0) {
            var dirParts = pathObj.dir.replace("\\", "/").split("/");
            var packageParts = [];
            for (part in dirParts) {
                if (part.length > 0 && part != "source") {
                    packageParts.push(part);
                }
            }
            if (packageParts.length > 0) {
                moduleInfo.packageName = packageParts.join(".");
            }
        }

        var classStack:Array<String> = []; // Track nested classes

        trace('[YSComp] Processing statements...');
        for (i in 0...statements.length) {
            var stmt = statements[i];
            trace('[YSComp] Statement ' + (i + 1) + '/' + statements.length + ': ' + Std.string(stmt).substring(0, 50) + '...');

            switch (stmt) {
                case Import(path, alias):
                    trace('[YSComp] Found import: ' + path + (alias != null ? ' as ' + alias : ''));
                    moduleInfo.imports.push({path: path, alias: alias});

                case VarDecl(name, type, init):
                    if (classStack.length == 0) {
                        trace('[YSComp] Found module-level variable: ' + name);
                        moduleInfo.moduleLevelVars.push({name: name, type: type, value: init != null ? evalConstExpression(init) : null});
                    }

                case FuncDecl(name, params, returnType, body):
                    if (classStack.length == 0) {
                        trace('[YSComp] Found module-level function: ' + name + ' with ' + params.length + ' parameters');
                        var paramInfos = [for (p in params) {name: p.name, type: p.type, value: null}];
                        moduleInfo.moduleLevelFunctions.push({name: name, parameters: paramInfos, returnType: returnType, body: body});
                    }

                case ClassDecl(name, extend, implement, body):
                    trace('[YSComp] Found class declaration: ' + name + (extend != null ? ' extends ' + extend : ''));
                    trace('[YSComp] Class body has ' + body.length + ' statements:');
                    for (j in 0...body.length) {
                        var bodyStmt = body[j];
                        trace('[YSComp]   Body[' + j + ']: ' + Std.string(bodyStmt).substring(0, 80) + '...');
                    }
                    var classInfo = extractClassInfo(name, extend, implement, body, classStack.copy());
                    trace('[YSComp] Extracted class info - Fields: ' + classInfo.fields.length + ', Methods: ' + classInfo.methods.length + ', Constructors: ' + classInfo.constructors.length);
                    for (method in classInfo.methods) {
                        trace('[YSComp]   Extracted method: ' + method.name);
                    }
                    for (constructor in classInfo.constructors) {
                        trace('[YSComp]   Extracted constructor: ' + constructor.name);
                    }
                    moduleInfo.classes.push(classInfo);

                    if (name == moduleInfo.moduleName) {
                        trace('[YSComp] Class ' + name + ' matches module name - setting hasMainClass = true');
                        moduleInfo.hasMainClass = true;
                    }

                case Expression(expr):
                    if (classStack.length == 0) {
                        trace('[YSComp] Found module-level expression: ' + expr);
                        trace('[YSComp] Expression type: ' + Type.getEnum(expr));
                        // Check if this expression is a function call or assignment
                        switch (expr) {
                            case FunctionCall(func, args):
                                trace('[YSComp] Capturing module-level function call: ' + func + ' with ' + args.length + ' args');
                                moduleInfo.moduleLevelCalls.push(expr);
                            case Assignment(left, right):
                                trace('[YSComp] Capturing module-level assignment: ' + left + ' = ' + right);
                                moduleInfo.moduleLevelCalls.push(expr);
                            default:
                                trace('[YSComp] Other module-level expression: ' + expr);
                                trace('[YSComp] Expression details: ' + Std.string(expr));
                        }
                    } else {
                        trace('[YSComp] Skipping expression inside class (classStack.length = ' + classStack.length + ')');
                    }

                default:
                    trace('[YSComp] Skipping statement type: ' + Std.string(stmt).substring(0, 30));
                    // Other statements ignored at module level
            }
        }

        trace('[YSComp] Module extraction complete:');
        trace('[YSComp]   Package: ' + (moduleInfo.packageName ?? 'none'));
        trace('[YSComp]   Classes: ' + moduleInfo.classes.length);
        trace('[YSComp]   Functions: ' + moduleInfo.moduleLevelFunctions.length);
        trace('[YSComp]   Variables: ' + moduleInfo.moduleLevelVars.length);
        trace('[YSComp]   Module Calls: ' + moduleInfo.moduleLevelCalls.length);
        trace('[YSComp]   Has main class: ' + moduleInfo.hasMainClass);

        return moduleInfo;
    }

    /**
     * Extract information about a YScript class
     */
    static function extractClassInfo(name:String, extend:Null<String>, implement:Array<String>,
                                   body:Array<YStatement>, classStack:Array<String>):ClassInfo {
        trace('[YSComp] === Extracting Class Info for: ' + name + ' ===');
        trace('[YSComp] Class body has ' + body.length + ' statements');
        trace('[YSComp] Class extends: ' + (extend ?? 'null'));
        trace('[YSComp] Class implements: ' + implement.join(', '));

        var classInfo:ClassInfo = {
            name: name,
            superClass: extend,
            interfaces: implement,
            fields: [],
            methods: [],
            constructors: [],
            isNested: classStack.length > 0,
            parentClass: classStack.length > 0 ? classStack[classStack.length - 1] : null
        };

        classStack.push(name); // Add current class to stack for nested classes

        classStack.push(name); // Add current class to stack for nested classes

        trace('[YSComp] Processing class body statements...');
        for (i in 0...body.length) {
            var stmt = body[i];
            trace('[YSComp] Class body statement ' + (i + 1) + '/' + body.length + ': ' + Std.string(stmt).substring(0, 100) + '...');

            switch (stmt) {
                case VarDecl(name, type, init):
                    trace('[YSComp]   Found field: ' + name + ' of type ' + Std.string(type));
                    classInfo.fields.push({name: name, type: type, value: init != null ? evalConstExpression(init) : null});

                case FuncDecl(name, params, returnType, body):
                    trace('[YSComp]   Found method: ' + name + ' with ' + params.length + ' parameters, return type: ' + Std.string(returnType));
                    var paramInfos = [for (p in params) {name: p.name, type: p.type, value: null}];
                    if (name == "new" || name == classInfo.name) {
                        // Constructor - YScript uses both 'new' and class-name constructors
                        trace('[YSComp]     -> Treating as constructor');
                        classInfo.constructors.push({name: name, parameters: paramInfos, returnType: returnType, body: body});
                    } else {
                        // Regular method
                        trace('[YSComp]     -> Treating as method');
                        classInfo.methods.push({name: name, parameters: paramInfos, returnType: returnType, body: body});
                    }

                case ClassDecl(nestedName, nestedExtend, nestedImplement, nestedBody):
                    trace('[YSComp]   Found nested class: ' + nestedName);
                    // Handle nested class - add to module classes with nesting info
                    var nestedInfo = extractClassInfo(nestedName, nestedExtend, nestedImplement, nestedBody, classStack.copy());
                    // Note: This would need to be handled by caller to add to module classes

                default:
                    trace('[YSComp]   Unknown statement in class body: ' + Std.string(stmt).substring(0, 50));
                    // Other statements in class body
            }
        }

        classStack.pop(); // Remove current class from stack

        trace('[YSComp] Class extraction completed for: ' + name);
        trace('[YSComp]   Final fields count: ' + classInfo.fields.length);
        trace('[YSComp]   Final methods count: ' + classInfo.methods.length);
        trace('[YSComp]   Final constructors count: ' + classInfo.constructors.length);
        for (method in classInfo.methods) {
            trace('[YSComp]   Final method: ' + method.name);
        }
        for (constructor in classInfo.constructors) {
            trace('[YSComp]   Final constructor: ' + constructor.name);
        }

        return classInfo;
    }

    /**
     * Generate full conversion types using Context.defineModule
     */
    static function generateFullConversionTypes(moduleInfo:ModuleInfo, modulePath:String, filePath:String, config:YSCompConfig):Void {
        var types:Array<TypeDefinition> = [];
        var imports:Array<ImportExpr> = [];

        // Convert YScript imports to Haxe imports
        for (imp in moduleInfo.imports) {
            var pathParts = imp.path.split(".").map(function(part) {
                return {pos: Context.currentPos(), name: part};
            });
            imports.push({
                path: pathParts,
                mode: imp.alias != null ? IAsName(imp.alias) : IAll
            });
        }

        // Generate classes
        for (classInfo in moduleInfo.classes) {
            trace('[YSComp] Generating class: ' + classInfo.name);
            trace('[YSComp]   Fields: ' + classInfo.fields.length);
            trace('[YSComp]   Methods: ' + classInfo.methods.length);
            trace('[YSComp]   Constructors: ' + classInfo.constructors.length);

            // Debug: List methods
            for (method in classInfo.methods) {
                trace('[YSComp]   Method: ' + method.name + '(' + [for (p in method.parameters) p.name + ':' + Std.string(p.type)].join(', ') + ')');
            }

            var classTypeDef = generateFullConversionClass(classInfo, moduleInfo);
            types.push(classTypeDef);
        }

        // Generate main module class if needed
        if (!moduleInfo.hasMainClass && (moduleInfo.moduleLevelVars.length > 0 || moduleInfo.moduleLevelFunctions.length > 0 || moduleInfo.moduleLevelCalls.length > 0)) {
            var mainClassTypeDef = generateFullConversionMainClass(moduleInfo);
            types.push(mainClassTypeDef);
        }

        // Define the module
        if (types.length > 0) {
            Context.defineModule(modulePath, types, imports);
        }
    }

    /**
     * Generate interpreter mode types using Context.defineModule
     */
    static function generateInterpreterModeTypes(moduleInfo:ModuleInfo, modulePath:String, filePath:String, config:YSCompConfig):Void {
        trace('[YSComp] === Generating Interpreter Mode Types ===');
        trace('[YSComp] Target module path: ' + modulePath);

        var types:Array<TypeDefinition> = [];
        var imports:Array<ImportExpr> = [
            {path: [{pos: Context.currentPos(), name: "yutautil"}, {pos: Context.currentPos(), name: "YScript"}], mode: IAll}
        ];
        trace('[YSComp] Base imports configured');

        // Convert YScript imports to Haxe imports
        for (imp in moduleInfo.imports) {
            var pathParts = imp.path.split(".").map(function(part) {
                return {pos: Context.currentPos(), name: part};
            });
            imports.push({
                path: pathParts,
                mode: imp.alias != null ? IAsName(imp.alias) : IAll
            });
        }

        // Get YScript source content
        var ysContent = getYScriptSourceForEmbed(filePath);

        // Generate wrapper classes for each YScript class
        trace('[YSComp] Generating ' + moduleInfo.classes.length + ' class wrappers...');
        for (classInfo in moduleInfo.classes) {
            trace('[YSComp] Generating wrapper for class: ' + classInfo.name);
            var classTypeDef = generateInterpreterClass(classInfo, moduleInfo, ysContent, filePath);
            types.push(classTypeDef);
            trace('[YSComp] Generated wrapper class: ' + classInfo.name);
        }

        // Generate main module class if needed
        if (!moduleInfo.hasMainClass && (moduleInfo.moduleLevelVars.length > 0 || moduleInfo.moduleLevelFunctions.length > 0 || moduleInfo.moduleLevelCalls.length > 0)) {
            trace('[YSComp] Generating main module class for module-level items...');
            var mainClassTypeDef = generateInterpreterMainClass(moduleInfo, ysContent, filePath);
            types.push(mainClassTypeDef);
            trace('[YSComp] Generated main module class: ' + moduleInfo.moduleName);
        }

        // Define the module
        trace('[YSComp] Defining module with ' + types.length + ' types...');
        if (types.length > 0) {
            try {
                Context.defineModule(modulePath, types, imports);
                trace('[YSComp] Successfully defined module: ' + modulePath);
            } catch (e:Dynamic) {
                trace('[YSComp] ERROR defining module ' + modulePath + ': ' + e);
                throw e;
            }
        } else {
            trace('[YSComp] No types generated for module: ' + modulePath);
        }
    }

    /**
     * Get YScript source content for embedding
     */
    static function getYScriptSourceForEmbed(filePath:String):Expr {
        var fullPath = Path.join([Sys.getCwd(), filePath]);
        var content = File.getContent(fullPath);
        return Context.makeExpr(content, Context.currentPos());
    }

    /**
     * Generate a TypeDefinition for full conversion class
     */
    static function generateFullConversionClass(classInfo:ClassInfo, moduleInfo:ModuleInfo):TypeDefinition {
        var fields:Array<Field> = [];
        var pos = Context.currentPos();

        // Generate nested class references if this class has nested classes
        for (otherClass in moduleInfo.classes) {
            if (otherClass.isNested && otherClass.parentClass == classInfo.name) {
                var nestedRefField:Field = {
                    name: otherClass.name,
                    doc: "Reference to nested class",
                    meta: [],
                    access: [APublic],
                    kind: FVar(TPath({name: "Class", pack: [], params: [TPType(TPath({name: otherClass.name, pack: []}))]}),
                              macro Type.resolveClass($v{otherClass.name})),
                    pos: pos
                };
                fields.push(nestedRefField);
            }
        }

        // Generate fields
        for (field in classInfo.fields) {
            var fieldDef:Field = {
                name: field.name,
                doc: null,
                meta: [],
                access: [APublic],
                kind: FVar(convertYTypeToComplexType(field.type), convertValueToExpr(field.value)),
                pos: pos
            };
            fields.push(fieldDef);
        }

        // Generate constructors
        if (classInfo.constructors.length == 0) {
            // Generate default constructor
            var constructorFunc:Function = {
                args: [],
                ret: null,
                expr: classInfo.superClass != null
                    ? macro { super(); }
                    : macro { },
                params: []
            };

            var constructorField:Field = {
                name: "new",
                doc: null,
                meta: [],
                access: [APublic],
                kind: FFun(constructorFunc),
                pos: pos
            };
            fields.push(constructorField);
        } else {
            // Generate all constructors
            var hasNewConstructor = false;
            var constructorOverloads:Array<FunctionInfo> = [];

            // Separate "new" constructors from class-name constructors
            for (constructor in classInfo.constructors) {
                if (constructor.name == "new") {
                    hasNewConstructor = true;
                    var constructorField = generateHaxeConstructorField(constructor, classInfo);
                    fields.push(constructorField);
                } else if (constructor.name == classInfo.name) {
                    // Class-name constructor - convert to "new"
                    constructorOverloads.push(constructor);
                }
            }

            // If we have class-name constructors but no "new", create overloaded "new" constructors
            if (!hasNewConstructor && constructorOverloads.length > 0) {
                // For multiple overloads, we'll take the first one as primary
                // TODO: Haxe doesn't support true overloading, might need different approach
                var primaryConstructor = constructorOverloads[0];
                var constructorField = generateHaxeConstructorField(primaryConstructor, classInfo);
                fields.push(constructorField);

                // Add static factory methods for additional overloads
                for (i in 1...constructorOverloads.length) {
                    var overloadConstructor = constructorOverloads[i];
                    var factoryField = generateFactoryMethodField(overloadConstructor, classInfo, i);
                    fields.push(factoryField);
                }
            }
        }

        // Generate methods
        for (method in classInfo.methods) {
            var methodField = generateHaxeMethodField(method);
            fields.push(methodField);
        }

        // Determine superclass and interfaces
        var superClass = classInfo.superClass != null
            ? resolveTypePathFromImports(classInfo.superClass, moduleInfo)
            : null;
        var interfaces = [for (iface in classInfo.interfaces) resolveTypePathFromImports(iface, moduleInfo)];

        // Extract package from module path if present
        var packageParts = moduleInfo.packageName != null
            ? moduleInfo.packageName.split(".")
            : [];

        return {
            pack: packageParts,
            name: classInfo.name,
            pos: pos,
            meta: [],
            params: [],
            isExtern: false,
            kind: TDClass(superClass, interfaces),
            fields: fields
        };
    }

    /**
     * Generate a TypeDefinition for interpreter mode class
     */
    static function generateInterpreterClass(classInfo:ClassInfo, moduleInfo:ModuleInfo, ysContent:Expr, filePath:String):TypeDefinition {
        trace('[YSComp] === Generating Interpreter Class: ' + classInfo.name + ' ===');
        trace('[YSComp] Class has ' + classInfo.methods.length + ' methods, ' + classInfo.fields.length + ' fields, ' + classInfo.constructors.length + ' constructors');

        var fields:Array<Field> = [];
        var pos = Context.currentPos();

        // Private YScript runtime fields
        fields.push({
            name: "_yscript",
            doc: null,
            meta: [],
            access: [APrivate],
            kind: FVar(TPath({name: "YScript", pack: ["yutautil"]})),
            pos: pos
        });

        fields.push({
            name: "_yinstance",
            doc: null,
            meta: [],
            access: [APrivate],
            kind: FVar(TPath({name: "YScript", pack: ["yutautil"], sub: "YClassInstance"})),
            pos: pos
        });

        fields.push({
            name: "_yScriptSource",
            doc: null,
            meta: [],
            access: [APrivate, AStatic],
            kind: FVar(TPath({name: "String", pack: []}), ysContent),
            pos: pos
        });

        // Constructor
        var constructorFunc:Function = {
            args: [{name: "args", type: TPath({name: "Array", pack: [], params: [TPType(TPath({name: "Dynamic", pack: []}))]}), opt: true}],
            ret: null,
            expr: macro {
                _yscript = new YScript();
                _yscript.loadFromSource(_yScriptSource, $v{filePath});

                var classDef = _yscript.getClass($v{classInfo.name});
                if (classDef == null) {
                    throw $v{"YScript class " + classInfo.name + " not found"};
                }

                _yinstance = new YClassInstance($v{classInfo.name}, classDef);

                // Call YScript constructor if args provided
                if (args != null && args.length > 0) {
                    callYMethod("new", args);
                }
            },
            params: []
        };

        fields.push({
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun(constructorFunc),
            pos: pos
        });

        // YInterpClass interface methods
        fields.push(generateYInterpMethod("getYScriptRuntime", [], TPath({name: "YScript", pack: ["yutautil"]}), macro return _yscript));
        fields.push(generateYInterpMethod("getYClassInstance", [], TPath({name: "YScript", pack: ["yutautil"], sub: "YClassInstance"}), macro return _yinstance));

        var callMethodFunc:Function = {
            args: [
                {name: "methodName", type: TPath({name: "String", pack: []})},
                {name: "args", type: TPath({name: "Array", pack: [], params: [TPType(TPath({name: "Dynamic", pack: []}))]})}
            ],
            ret: TPath({name: "Dynamic", pack: []}),
            expr: macro return _yscript.callMethod(_yinstance, methodName, args),
            params: []
        };
        fields.push({name: "callYMethod", doc: null, meta: [], access: [APublic], kind: FFun(callMethodFunc), pos: pos});

        var getFieldFunc:Function = {
            args: [{name: "fieldName", type: TPath({name: "String", pack: []})}],
            ret: TPath({name: "Dynamic", pack: []}),
            expr: macro return _yinstance.getField(fieldName),
            params: []
        };
        fields.push({name: "getYField", doc: null, meta: [], access: [APublic], kind: FFun(getFieldFunc), pos: pos});

        var setFieldFunc:Function = {
            args: [
                {name: "fieldName", type: TPath({name: "String", pack: []})},
                {name: "value", type: TPath({name: "Dynamic", pack: []})}
            ],
            ret: TPath({name: "Void", pack: []}),
            expr: macro _yinstance.setField(fieldName, value),
            params: []
        };
        fields.push({name: "setYField", doc: null, meta: [], access: [APublic], kind: FFun(setFieldFunc), pos: pos});

        var getClassNameFunc:Function = {
            args: [],
            ret: TPath({name: "String", pack: []}),
            expr: macro return $v{classInfo.name},
            params: []
        };
        fields.push({name: "getYClassName", doc: null, meta: [], access: [APublic], kind: FFun(getClassNameFunc), pos: pos});

        // Generate convenience methods for each YScript method
        for (method in classInfo.methods) {
            var methodField = generateInterpreterMethodField(method);
            fields.push(methodField);
        }

        // Generate property accessors for fields
        for (field in classInfo.fields) {
            var getterField = generateFieldGetterField(field);
            var setterField = generateFieldSetterField(field);
            var propField = generateFieldPropertyField(field);
            fields.push(propField);
            fields.push(getterField);
            fields.push(setterField);
        }

        // Extract package from module path if present
        var packageParts = moduleInfo.packageName != null
            ? moduleInfo.packageName.split(".")
            : [];

        return {
            pack: packageParts,
            name: classInfo.name,
            pos: pos,
            meta: [],
            params: [],
            isExtern: false,
            kind: TDClass(null, []),
            fields: fields
        };
    }

    /**
     * Generate helper method for YInterpClass interface
     */
    static function generateYInterpMethod(name:String, args:Array<FunctionArg>, ret:ComplexType, expr:Expr):Field {
        var func:Function = {
            args: args,
            ret: ret,
            expr: expr,
            params: []
        };

        return {
            name: name,
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun(func),
            pos: Context.currentPos()
        };
    }

    /**
     * Resolve TypePath for a type name from module imports
     */
    static function resolveTypePathFromImports(typeName:String, moduleInfo:ModuleInfo):TypePath {
        // Check if the type matches any imported types
        for (imp in moduleInfo.imports) {
            var pathParts = imp.path.split(".");
            var lastPart = pathParts[pathParts.length - 1];

            if (lastPart == typeName) {
                // Found exact match - use full import path
                var pack = pathParts.slice(0, pathParts.length - 1);
                return {name: typeName, pack: pack, params: []};
            }
        }

        // If not found in imports, assume it's a local type
        return {name: typeName, pack: [], params: []};
    }

    /**
     * Convert YScript type to Haxe ComplexType
     */
    static function convertYTypeToComplexType(type:YType):ComplexType {
        if (type == null) return TPath({name: "Dynamic", pack: []});

        return switch (type) {
            case YInt: TPath({name: "Int", pack: []});
            case YFloat: TPath({name: "Float", pack: []});
            case YString: TPath({name: "String", pack: []});
            case YBool: TPath({name: "Bool", pack: []});
            case YArray(elementType): TPath({name: "Array", pack: [], params: [TPType(convertYTypeToComplexType(elementType))]});
            case YFunction(params, returnType):
                var paramTypes = [for (p in params) convertYTypeToComplexType(p)];
                var retType = convertYTypeToComplexType(returnType);
                TFunction(paramTypes, retType);
            case YClass(className):
                try {
                    // Try to resolve the class using macro Context
                    var resolved = Context.getType(className);
                    return switch (resolved) {
                        case TInst(classRef, _):
                            var classType = classRef.get();
                            var fullName = classType.pack.concat([classType.name]).join(".");
                            var parts = fullName.split(".");
                            var name = parts.pop();
                            TPath({name: name, pack: parts});
                        default:
                            // Fallback to simple name parsing
                            if (className.indexOf(".") >= 0) {
                                var parts = className.split(".");
                                var name = parts.pop();
                                TPath({name: name, pack: parts});
                            } else {
                                TPath({name: className, pack: []});
                            }
                    };
                } catch (e:Dynamic) {
                    // Fallback to simple name parsing
                    if (className.indexOf(".") >= 0) {
                        var parts = className.split(".");
                        var name = parts.pop();
                        TPath({name: name, pack: parts});
                    } else {
                        TPath({name: className, pack: []});
                    }
                }
            case YEnum(enumName):
                try {
                    // Try to resolve the enum using macro Context
                    var resolved = Context.getType(enumName);
                    return switch (resolved) {
                        case TEnum(enumRef, _):
                            var enumType = enumRef.get();
                            var fullName = enumType.pack.concat([enumType.name]).join(".");
                            var parts = fullName.split(".");
                            var name = parts.pop();
                            TPath({name: name, pack: parts});
                        default:
                            // Fallback to simple name parsing
                            if (enumName.indexOf(".") >= 0) {
                                var parts = enumName.split(".");
                                var name = parts.pop();
                                TPath({name: name, pack: parts});
                            } else {
                                TPath({name: enumName, pack: []});
                            }
                    };
                } catch (e:Dynamic) {
                    // Fallback to simple name parsing
                    if (enumName.indexOf(".") >= 0) {
                        var parts = enumName.split(".");
                        var name = parts.pop();
                        TPath({name: name, pack: parts});
                    } else {
                        TPath({name: enumName, pack: []});
                    }
                }
            case YStruct(structName): TPath({name: structName, pack: []});
            case HaxeType(type):
                try {
                    // Try to resolve the actual Haxe type
                    if (type != null) {
                        var typeStr = Std.string(type);
                        if (typeStr.indexOf(".") >= 0) {
                            var parts = typeStr.split(".");
                            var name = parts.pop();
                            return TPath({name: name, pack: parts});
                        } else {
                            return TPath({name: typeStr, pack: []});
                        }
                    }
                    return TPath({name: "Dynamic", pack: []});
                } catch (e:Dynamic) {
                    return TPath({name: "Dynamic", pack: []});
                }
            case HaxeClass(classType):
                try {
                    // Extract class name and package from Class<T>
                    if (classType != null) {
                        var className = Type.getClassName(classType);
                        if (className != null) {
                            var parts = className.split(".");
                            var name = parts.pop();
                            return TPath({name: name, pack: parts});
                        }
                    }
                    return TPath({name: "Dynamic", pack: []});
                } catch (e:Dynamic) {
                    return TPath({name: "Dynamic", pack: []});
                }
            case HaxeAbstract(abstractType):
                try {
                    // Try to resolve abstract type name
                    if (abstractType != null) {
                        var typeStr = Std.string(abstractType);
                        if (typeStr.indexOf(".") >= 0) {
                            var parts = typeStr.split(".");
                            var name = parts.pop();
                            return TPath({name: name, pack: parts});
                        } else {
                            return TPath({name: typeStr, pack: []});
                        }
                    }
                    return TPath({name: "Dynamic", pack: []});
                } catch (e:Dynamic) {
                    return TPath({name: "Dynamic", pack: []});
                }
            case HaxeEnum(enumType):
                try {
                    // Extract enum name and package from Enum<T>
                    if (enumType != null) {
                        var enumName = Type.getEnumName(enumType);
                        if (enumName != null) {
                            var parts = enumName.split(".");
                            var name = parts.pop();
                            return TPath({name: name, pack: parts});
                        }
                    }
                    return TPath({name: "Dynamic", pack: []});
                } catch (e:Dynamic) {
                    return TPath({name: "Dynamic", pack: []});
                }
            case Dynamic: TPath({name: "Dynamic", pack: []});
            case Void: TPath({name: "Void", pack: []});
            case Unknown: TPath({name: "Dynamic", pack: []});
            default: TPath({name: "Dynamic", pack: []});
        };
    }

    /**
     * Convert YScript function body to Haxe expression
     */
    static function convertYScriptBodyToHaxe(body:Dynamic, returnType:Dynamic):Expr {
        if (body == null) {
            return generateDefaultReturn(returnType);
        }

        // Convert YFunctionBody to Haxe expressions
        try {
            return convertYScriptToHaxeExpr(body);
        } catch (e:Dynamic) {
            // Fallback to default return if conversion fails
            return generateDefaultReturn(returnType);
        }
    }

    /**
     * Convert YScript expression/statement to Haxe expression
     */
    static function convertYScriptToHaxeExpr(yscript:Dynamic):Expr {
        var pos = Context.currentPos();

        if (yscript == null) {
            return macro null;
        }

        // Handle YFunctionBody
        if (Std.isOfType(yscript, YFunctionBody)) {
            return convertYFunctionBodyToHaxe(cast yscript);
        }

        // Handle YExpression
        if (Std.isOfType(yscript, YExpression)) {
            return convertYExpressionToHaxe(cast yscript);
        }

        // Handle YStatement
        if (Std.isOfType(yscript, YStatement)) {
            var stmt = convertYStatementToHaxe(cast yscript);
            return stmt != null ? stmt : macro { };
        }

        // Handle array of statements
        if (Std.is(yscript, Array)) {
            var statements:Array<Dynamic> = cast yscript;
            var haxeExprs:Array<Expr> = [];

            for (stmt in statements) {
                var haxeExpr = convertYScriptToHaxeExpr(stmt);
                if (haxeExpr != null) {
                    haxeExprs.push(haxeExpr);
                }
            }

            return {
                expr: EBlock(haxeExprs),
                pos: pos
            };
        }

        // Default fallback
        return macro { };
    }

    /**
     * Convert YFunctionBody to Haxe expression
     */
    static function convertYFunctionBodyToHaxe(body:YFunctionBody):Expr {
        var pos = Context.currentPos();

        return switch (body) {
            case YScript(statements): {
                var haxeExprs = [for (stmt in statements) convertYStatementToHaxe(stmt)].filter(e -> e != null);
                {
                    expr: EBlock(haxeExprs),
                    pos: pos
                };
            }

            case HaxeCode(code): {
                // Parse and return embedded Haxe code
                try {
                    haxe.macro.Context.parseInlineString(code, pos);
                } catch (e:Dynamic) {
                    // Fallback to comment if parsing fails
                    macro { /* Embedded Haxe code: $v{code} */ };
                }
            }

            case LuaCode(code): {
                // Convert Lua to Haxe (placeholder for now)
                macro { /* Lua code not supported in FullConversion: $v{code} */ };
            }

            case Native(func): {
                // Native function reference
                macro { /* Native function reference */ };
            }
        };
    }

    /**
     * Convert YScript statement to Haxe expression
     */
    static function convertYStatementToHaxe(stmt:YStatement):Null<Expr> {
        var pos = Context.currentPos();

        return switch (stmt) {
            case Import(path, alias):
                // Imports are handled at module level, skip in body
                null;

            case VarDecl(name, type, init):
                if (init != null) {
                    var initExpr = convertYExpressionToHaxe(init);
                    var typeComplexType = convertYTypeToComplexType(type);
                    macro var $name:$typeComplexType = $initExpr;
                } else {
                    var typeComplexType = convertYTypeToComplexType(type);
                    macro var $name:$typeComplexType;
                }

            case FuncDecl(name, params, returnType, body):
                // Function declarations in statements become local functions
                var args = [for (p in params) {
                    name: p.name,
                    type: convertYTypeToComplexType(p.type)
                }];
                var ret = convertYTypeToComplexType(returnType);
                var bodyExpr = convertYFunctionBodyToHaxe(body);

                var func:Function = {
                    args: args,
                    ret: ret,
                    expr: bodyExpr,
                    params: []
                };

                {
                    expr: EFunction(FNamed(name), func),
                    pos: pos
                };

            case ClassDecl(name, extend, implement, body):
                // Local class declarations (not typically supported in Haxe)
                macro { /* Local class $v{name} not supported in FullConversion */ };

            case If(condition, thenStmt, elseStmt):
                var condExpr = convertYExpressionToHaxe(condition);
                var thenExpr = convertYStatementToHaxe(thenStmt);
                var elseExpr = elseStmt != null ? convertYStatementToHaxe(elseStmt) : null;

                if (elseExpr != null) {
                    macro if ($condExpr) $thenExpr else $elseExpr;
                } else {
                    macro if ($condExpr) $thenExpr;
                }

            case While(condition, body):
                var condExpr = convertYExpressionToHaxe(condition);
                var bodyExpr = convertYStatementToHaxe(body);
                macro while ($condExpr) $bodyExpr;

            case For(init, condition, increment, body):
                var initExpr = init != null ? convertYStatementToHaxe(init) : null;
                var condExpr = condition != null ? convertYExpressionToHaxe(condition) : macro true;
                var incExpr = increment != null ? convertYExpressionToHaxe(increment) : null;
                var bodyExpr = convertYStatementToHaxe(body);

                // Convert to while loop since Haxe for is different
                if (initExpr != null) {
                    if (incExpr != null) {
                        macro {
                            $initExpr;
                            while ($condExpr) {
                                $bodyExpr;
                                $incExpr;
                            }
                        };
                    } else {
                        macro {
                            $initExpr;
                            while ($condExpr) $bodyExpr;
                        };
                    }
                } else {
                    macro while ($condExpr) {
                        $bodyExpr;
                        $incExpr;
                    };
                }

            case Return(value):
                if (value != null) {
                    var valueExpr = convertYExpressionToHaxe(value);
                    macro return $valueExpr;
                } else {
                    macro return;
                }

            case Break:
                macro break;

            case Continue:
                macro continue;

            case Block(statements):
                var haxeExprs = [for (s in statements) convertYStatementToHaxe(s)].filter(e -> e != null);
                {
                    expr: EBlock(haxeExprs),
                    pos: pos
                };

            case Expression(expr):
                convertYExpressionToHaxe(expr);

            case HaxeBlock(code):
                try {
                    haxe.macro.Context.parseInlineString(code, pos);
                } catch (e:Dynamic) {
                    macro { /* Haxe block: $v{code} */ };
                }

            case LuaBlock(code):
                macro { /* Lua block not supported in FullConversion: $v{code} */ };
        };
    }

    /**
     * Convert YExpression to Haxe expression
     */
    static function convertYExpressionToHaxe(expr:YExpression):Expr {
        var pos = Context.currentPos();

        return switch (expr) {
            case IntLiteral(value):
                Context.makeExpr(value, pos);

            case FloatLiteral(value):
                Context.makeExpr(value, pos);

            case StringLiteral(value):
                Context.makeExpr(value, pos);

            case BoolLiteral(value):
                Context.makeExpr(value, pos);

            case NullLiteral:
                macro null;

            case ArrayLiteral(elements):
                var elemExprs = [for (elem in elements) convertYExpressionToHaxe(elem)];
                {
                    expr: EArrayDecl(elemExprs),
                    pos: pos
                };

            case ObjectLiteral(fields):
                var objFields = [for (field in fields) {
                    field: field.name,
                    expr: convertYExpressionToHaxe(field.value)
                }];
                {
                    expr: EObjectDecl(objFields),
                    pos: pos
                };

            case Identifier(name):
                macro $i{name};

            case MemberAccess(object, member):
                var objExpr = convertYExpressionToHaxe(object);
                {
                    expr: EField(objExpr, member),
                    pos: pos
                };

            case ArrayAccess(array, index):
                var arrayExpr = convertYExpressionToHaxe(array);
                var indexExpr = convertYExpressionToHaxe(index);
                {
                    expr: EArray(arrayExpr, indexExpr),
                    pos: pos
                };

            case SuperCall(args):
                var argExprs = [for (arg in args) convertYExpressionToHaxe(arg)];
                {
                    expr: ECall(macro super, argExprs),
                    pos: pos
                };

            case SuperMemberAccess(member):
                {
                    expr: EField(macro super, member),
                    pos: pos
                };

            case SuperMethodCall(method, args):
                var argExprs = [for (arg in args) convertYExpressionToHaxe(arg)];
                var superMethod = {
                    expr: EField(macro super, method),
                    pos: pos
                };
                {
                    expr: ECall(superMethod, argExprs),
                    pos: pos
                };

            case BinaryOp(left, op, right):
                var leftExpr = convertYExpressionToHaxe(left);
                var rightExpr = convertYExpressionToHaxe(right);
                var haxeOp = convertYOpStringToHaxe(op);
                {
                    expr: EBinop(haxeOp, leftExpr, rightExpr),
                    pos: pos
                };

            case UnaryOp(op, operand):
                var operandExpr = convertYExpressionToHaxe(operand);
                var haxeOp = convertYUnaryOpToHaxe(op);
                {
                    expr: EUnop(haxeOp, false, operandExpr),
                    pos: pos
                };

            case Assignment(left, right):
                var leftExpr = convertYExpressionToHaxe(left);
                var rightExpr = convertYExpressionToHaxe(right);
                {
                    expr: EBinop(OpAssign, leftExpr, rightExpr),
                    pos: pos
                };

            case FunctionCall(func, args):
                var funcExpr = convertYExpressionToHaxe(func);
                var argExprs = [for (arg in args) convertYExpressionToHaxe(arg)];
                {
                    expr: ECall(funcExpr, argExprs),
                    pos: pos
                };

            case New(type, args):
                var argExprs = [for (arg in args) convertYExpressionToHaxe(arg)];
                var typePath = convertYTypeToTypePath(type);
                {
                    expr: ENew(typePath, argExprs),
                    pos: pos
                };

            case Cast(expr, type):
                var exprHaxe = convertYExpressionToHaxe(expr);
                var typeComplexType = convertYTypeToComplexType(type);
                {
                    expr: ECast(exprHaxe, typeComplexType),
                    pos: Context.currentPos()
                };

            case Is(expr, type):
                var exprHaxe = convertYExpressionToHaxe(expr);
                // For Std.isOfType, we need the type as a type expression, not a ComplexType
                var typePath = convertYTypeToTypePath(type);
                var typeExpr = if (typePath.pack.length > 0) {
                    // Create a field access for packaged types (e.g., flixel.FlxSprite)
                    var packageExpr = {
                        expr: EConst(CIdent(typePath.pack[0])),
                        pos: Context.currentPos()
                    };
                    for (i in 1...typePath.pack.length) {
                        packageExpr = {
                            expr: EField(packageExpr, typePath.pack[i]),
                            pos: Context.currentPos()
                        };
                    }
                    {
                        expr: EField(packageExpr, typePath.name),
                        pos: Context.currentPos()
                    };
                } else {
                    // Simple identifier for types without package
                    {
                        expr: EConst(CIdent(typePath.name)),
                        pos: Context.currentPos()
                    };
                };
                macro Std.isOfType($exprHaxe, $typeExpr);
        };
    }

    /**
     * Convert YScript string operator to Haxe binop
     */
    static function convertYOpStringToHaxe(op:String):Binop {
        return switch (op) {
            case "+": OpAdd;
            case "-": OpSub;
            case "*": OpMult;
            case "/": OpDiv;
            case "%": OpMod;
            case "==": OpEq;
            case "!=": OpNotEq;
            case "<": OpLt;
            case ">": OpGt;
            case "<=": OpLte;
            case ">=": OpGte;
            case "&&": OpBoolAnd;
            case "||": OpBoolOr;
            case "&": OpAnd;
            case "|": OpOr;
            case "^": OpXor;
            case "<<": OpShl;
            case ">>": OpShr;
            case ">>>": OpUShr;
            case "=": OpAssign;
            case "+=": OpAssignOp(OpAdd);
            case "-=": OpAssignOp(OpSub);
            case "*=": OpAssignOp(OpMult);
            case "/=": OpAssignOp(OpDiv);
            case "%=": OpAssignOp(OpMod);
            default: OpAdd; // Default fallback
        };
    }

    /**
     * Convert YScript unary operator to Haxe unop
     */
    static function convertYUnaryOpToHaxe(op:String):Unop {
        return switch (op) {
            case "!": OpNot;
            case "-": OpNeg;
            case "++": OpIncrement;
            case "--": OpDecrement;
            case "~": OpNegBits;
            default: OpNot; // Default fallback
        };
    }

    /**
     * Convert YType to TypePath for use in new expressions
     */
    static function convertYTypeToTypePath(type:YType):TypePath {
        return switch (type) {
            case YInt: {name: "Int", pack: []};
            case YFloat: {name: "Float", pack: []};
            case YString: {name: "String", pack: []};
            case YBool: {name: "Bool", pack: []};
            case YArray(elementType): {name: "Array", pack: [], params: [TPType(convertYTypeToComplexType(elementType))]};
            case YClass(className):
                try {
                    // Try to resolve the class using macro Context
                    var resolved = Context.getType(className);
                    return switch (resolved) {
                        case TInst(classRef, _):
                            var classType = classRef.get();
                            var fullName = classType.pack.concat([classType.name]).join(".");
                            var parts = fullName.split(".");
                            var name = parts.pop();
                            {name: name, pack: parts};
                        default:
                            // Fallback to simple name parsing
                            if (className.indexOf(".") >= 0) {
                                var parts = className.split(".");
                                var name = parts.pop();
                                {name: name, pack: parts};
                            } else {
                                {name: className, pack: []};
                            }
                    };
                } catch (e:Dynamic) {
                    // Fallback to simple name parsing
                    if (className.indexOf(".") >= 0) {
                        var parts = className.split(".");
                        var name = parts.pop();
                        {name: name, pack: parts};
                    } else {
                        {name: className, pack: []};
                    }
                }
            case YEnum(enumName):
                try {
                    // Try to resolve the enum using macro Context
                    var resolved = Context.getType(enumName);
                    return switch (resolved) {
                        case TEnum(enumRef, _):
                            var enumType = enumRef.get();
                            var fullName = enumType.pack.concat([enumType.name]).join(".");
                            var parts = fullName.split(".");
                            var name = parts.pop();
                            {name: name, pack: parts};
                        default:
                            // Fallback to simple name parsing
                            if (enumName.indexOf(".") >= 0) {
                                var parts = enumName.split(".");
                                var name = parts.pop();
                                {name: name, pack: parts};
                            } else {
                                {name: enumName, pack: []};
                            }
                    };
                } catch (e:Dynamic) {
                    // Fallback to simple name parsing
                    if (enumName.indexOf(".") >= 0) {
                        var parts = enumName.split(".");
                        var name = parts.pop();
                        {name: name, pack: parts};
                    } else {
                        {name: enumName, pack: []};
                    }
                }
            case YStruct(structName): {name: structName, pack: []};
            case HaxeType(type):
                try {
                    if (type != null) {
                        var typeStr = Std.string(type);
                        if (typeStr.indexOf(".") >= 0) {
                            var parts = typeStr.split(".");
                            var name = parts.pop();
                            {name: name, pack: parts};
                        } else {
                            {name: typeStr, pack: []};
                        }
                    } else {
                        {name: "Dynamic", pack: []};
                    }
                } catch (e:Dynamic) {
                    {name: "Dynamic", pack: []};
                }
            case HaxeClass(classType):
                try {
                    if (classType != null) {
                        var className = Type.getClassName(classType);
                        if (className != null) {
                            var parts = className.split(".");
                            var name = parts.pop();
                            {name: name, pack: parts};
                        } else {
                            {name: "Dynamic", pack: []};
                        }
                    } else {
                        {name: "Dynamic", pack: []};
                    }
                } catch (e:Dynamic) {
                    {name: "Dynamic", pack: []};
                }
            case HaxeEnum(enumType):
                try {
                    if (enumType != null) {
                        var enumName = Type.getEnumName(enumType);
                        if (enumName != null) {
                            var parts = enumName.split(".");
                            var name = parts.pop();
                            {name: name, pack: parts};
                        } else {
                            {name: "Dynamic", pack: []};
                        }
                    } else {
                        {name: "Dynamic", pack: []};
                    }
                } catch (e:Dynamic) {
                    {name: "Dynamic", pack: []};
                }
            case HaxeAbstract(abstractType):
                try {
                    if (abstractType != null) {
                        var typeStr = Std.string(abstractType);
                        if (typeStr.indexOf(".") >= 0) {
                            var parts = typeStr.split(".");
                            var name = parts.pop();
                            {name: name, pack: parts};
                        } else {
                            {name: typeStr, pack: []};
                        }
                    } else {
                        {name: "Dynamic", pack: []};
                    }
                } catch (e:Dynamic) {
                    {name: "Dynamic", pack: []};
                }
            case Dynamic: {name: "Dynamic", pack: []};
            case Void: {name: "Void", pack: []};
            case Unknown: {name: "Dynamic", pack: []};
            default: {name: "Dynamic", pack: []};
        };
    }

    /**
     * Generate default return expression based on return type
     */
    static function generateDefaultReturn(returnType:Dynamic):Expr {
        var typeStr = Std.string(returnType);

        if (typeStr.indexOf("YInt") >= 0) return macro return 0;
        if (typeStr.indexOf("YFloat") >= 0) return macro return 0.0;
        if (typeStr.indexOf("YString") >= 0) return macro return "";
        if (typeStr.indexOf("YBool") >= 0) return macro return false;
        if (typeStr.indexOf("Void") >= 0) return macro { };

        // Default for other types
        return macro return null;
    }

    /**
     * Convert YScript value to Haxe Expr
     */
    static function convertValueToExpr(value:Dynamic):Null<Expr> {
        if (value == null) return null;
        return Context.makeExpr(value, Context.currentPos());
    }

    /**
     * Generate factory method for constructor overload
     */
    static function generateFactoryMethodField(constructor:FunctionInfo, classInfo:ClassInfo, overloadIndex:Int):Field {
        var args = [for (param in constructor.parameters) {
            name: param.name,
            type: convertYTypeToComplexType(param.type)
        }];

        var argNames = [for (param in constructor.parameters) macro $i{param.name}];
        var newCall = {expr: ENew({name: classInfo.name, pack: []}, argNames), pos: Context.currentPos()};

        var factoryFunc:Function = {
            args: args,
            ret: TPath({name: classInfo.name, pack: []}),
            expr: macro {
                var instance = $newCall;
                // Call additional initialization from constructor body
                $e{convertYScriptBodyToHaxe(constructor.body, null)};
                return instance;
            },
            params: []
        };

        return {
            name: "create" + (overloadIndex > 0 ? Std.string(overloadIndex + 1) : ""),
            doc: "Factory method for constructor overload",
            meta: [],
            access: [APublic, AStatic],
            kind: FFun(factoryFunc),
            pos: Context.currentPos()
        };
    }

    /**
     * Generate Haxe constructor field from YScript function
     */
    static function generateHaxeConstructorField(constructor:FunctionInfo, classInfo:ClassInfo):Field {
        var args = [for (param in constructor.parameters) {
            name: param.name,
            type: convertYTypeToComplexType(param.type)
        }];

        // Convert YScript constructor body
        var bodyExpr = convertYScriptBodyToHaxe(constructor.body, null);

        var constructorExpr = if (classInfo.superClass != null) {
            // Combine super call with constructor body
            macro {
                // super();
                $bodyExpr;
            };
        } else {
            bodyExpr;
        };

        var constructorFunc:Function = {
            args: args,
            ret: null,
            expr: constructorExpr,
            params: []
        };

        return {
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun(constructorFunc),
            pos: Context.currentPos()
        };
    }

    /**
     * Generate Haxe method field from YScript function
     */
    static function generateHaxeMethodField(method:FunctionInfo):Field {
        var args = [for (param in method.parameters) {
            name: param.name,
            type: convertYTypeToComplexType(param.type)
        }];

        var methodFunc:Function = {
            args: args,
            ret: convertYTypeToComplexType(method.returnType),
            expr: convertYScriptBodyToHaxe(method.body, method.returnType),
            params: []
        };

        return {
            name: method.name,
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun(methodFunc),
            pos: Context.currentPos()
        };
    }

    /**
     * Generate interpreter convenience method field
     */
    static function generateInterpreterMethodField(method:FunctionInfo):Field {
        var args = [for (param in method.parameters) {
            name: param.name,
            type: convertYTypeToComplexType(param.type)
        }];

        var argNames = [for (param in method.parameters) macro $i{param.name}];
        var argsArray = {expr: EArrayDecl(argNames), pos: Context.currentPos()};

        var methodFunc:Function = {
            args: args,
            ret: convertYTypeToComplexType(method.returnType),
            expr: macro return cast callYMethod($v{method.name}, $argsArray),
            params: []
        };

        return {
            name: method.name,
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun(methodFunc),
            pos: Context.currentPos()
        };
    }

    /**
     * Generate property field for YScript field
     */
    static function generateFieldPropertyField(field:VarInfo):Field {
        return {
            name: field.name,
            doc: null,
            meta: [],
            access: [APublic],
            kind: FProp("get", "set", TPath({name: "Dynamic", pack: []})),
            pos: Context.currentPos()
        };
    }

    /**
     * Generate getter field for YScript field
     */
    static function generateFieldGetterField(field:VarInfo):Field {
        var getterFunc:Function = {
            args: [],
            ret: TPath({name: "Dynamic", pack: []}),
            expr: macro return getYField($v{field.name}),
            params: []
        };

        return {
            name: "get_" + field.name,
            doc: null,
            meta: [],
            access: [APrivate],
            kind: FFun(getterFunc),
            pos: Context.currentPos()
        };
    }

    /**
     * Generate setter field for YScript field
     */
    static function generateFieldSetterField(field:VarInfo):Field {
        var setterFunc:Function = {
            args: [{name: "value", type: TPath({name: "Dynamic", pack: []})}],
            ret: TPath({name: "Dynamic", pack: []}),
            expr: macro {
                setYField($v{field.name}, value);
                return value;
            },
            params: []
        };

        return {
            name: "set_" + field.name,
            doc: null,
            meta: [],
            access: [APrivate],
            kind: FFun(setterFunc),
            pos: Context.currentPos()
        };
    }

    /**
     * Generate main class for full conversion mode
     */
    static function generateFullConversionMainClass(moduleInfo:ModuleInfo):TypeDefinition {
        var fields:Array<Field> = [];
        var pos = Context.currentPos();

        // Static fields for module-level variables
        for (variable in moduleInfo.moduleLevelVars) {
            var fieldDef:Field = {
                name: variable.name,
                doc: null,
                meta: [],
                access: [APublic, AStatic],
                kind: FVar(convertYTypeToComplexType(variable.type), convertValueToExpr(variable.value)),
                pos: pos
            };
            fields.push(fieldDef);
        }

        // Add __module__ static variable for module-level initialization if there are module items
        if (moduleInfo.moduleLevelFunctions.length > 0 || moduleInfo.moduleLevelVars.length > 0 || moduleInfo.moduleLevelCalls.length > 0) {
            trace('[YSComp] Generating __module__ field for module with:');
            trace('[YSComp]   - Functions: ' + moduleInfo.moduleLevelFunctions.length);
            trace('[YSComp]   - Variables: ' + moduleInfo.moduleLevelVars.length);
            trace('[YSComp]   - Calls: ' + moduleInfo.moduleLevelCalls.length);

            // Convert module-level function calls and assignments to Haxe expressions
            var callExprs:Array<Expr> = [];
            for (i in 0...moduleInfo.moduleLevelCalls.length) {
                var call = moduleInfo.moduleLevelCalls[i];
                trace('[YSComp] Converting call/assignment #' + i + ': ' + call);
                var callExpr = convertYExpressionToHaxe(call);
                trace('[YSComp] Generated Haxe expression: ' + callExpr);
                callExprs.push(callExpr);
                trace('[YSComp] Added module-level expression to __module__ lambda: ' + call);
            }

            // Create the module initialization function using macro syntax
            var moduleInitExpr = if (callExprs.length > 0) {
                macro {
                    $b{callExprs};
                    return true;
                };
            } else {
                macro {
                    return true;
                };
            };

            trace('[YSComp] Final __module__ will execute ' + callExprs.length + ' expressions');

            var moduleVarField:Field = {
                name: "__module__",
                doc: "Private static variable containing module-level initialization result",
                meta: [],
                access: [APrivate, AStatic],
                kind: FVar(TPath({name: "Bool", pack: []}), macro (function():Bool $moduleInitExpr)()),
                pos: pos
            };
            fields.push(moduleVarField);
            trace('[YSComp] Added __module__ field to class');
        } else {
            trace('[YSComp] No module-level items found, skipping __module__ generation');
        }

        // Static methods for module-level functions
        for (func in moduleInfo.moduleLevelFunctions) {
            var args = [for (param in func.parameters) {
                name: param.name,
                type: convertYTypeToComplexType(param.type)
            }];

            var funcDef:Function = {
                args: args,
                ret: convertYTypeToComplexType(func.returnType),
                expr: convertYScriptBodyToHaxe(func.body, func.returnType),
                params: []
            };

            var methodField:Field = {
                name: func.name,
                doc: null,
                meta: [],
                access: [APublic, AStatic],
                kind: FFun(funcDef),
                pos: pos
            };
            fields.push(methodField);
        }

        // Extract package from module path if present
        var packageParts = moduleInfo.packageName != null
            ? moduleInfo.packageName.split(".")
            : [];

        return {
            pack: packageParts,
            name: moduleInfo.moduleName,
            pos: pos,
            meta: [],
            params: [],
            isExtern: false,
            kind: TDClass(null, []),
            fields: fields
        };
    }

    /**
     * Generate main class for interpreter mode
     */
    static function generateInterpreterMainClass(moduleInfo:ModuleInfo, ysContent:Expr, filePath:String):TypeDefinition {
        var fields:Array<Field> = [];
        var pos = Context.currentPos();

        // Private YScript runtime field
        fields.push({
            name: "_yscript",
            doc: null,
            meta: [],
            access: [APrivate],
            kind: FVar(TPath({name: "YScript", pack: ["yutautil"]})),
            pos: pos
        });

        fields.push({
            name: "_yScriptSource",
            doc: null,
            meta: [],
            access: [APrivate, AStatic],
            kind: FVar(TPath({name: "String", pack: []}), ysContent),
            pos: pos
        });

        // Constructor
        var constructorFunc:Function = {
            args: [],
            ret: null,
            expr: macro {
                _yscript = new YScript();
                _yscript.loadFromSource(_yScriptSource, $v{filePath});
            },
            params: []
        };

        fields.push({
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun(constructorFunc),
            pos: pos
        });

        // YInterpClass interface methods
        fields.push(generateYInterpMethod("getYScriptRuntime", [], TPath({name: "YScript", pack: ["yutautil"]}), macro return _yscript));
        fields.push(generateYInterpMethod("getYClassInstance", [], TPath({name: "YScript", pack: ["yutautil"], sub: "YClassInstance"}), macro return null));

        var callMethodFunc:Function = {
            args: [
                {name: "methodName", type: TPath({name: "String", pack: []})},
                {name: "args", type: TPath({name: "Array", pack: [], params: [TPType(TPath({name: "Dynamic", pack: []}))]})}
            ],
            ret: TPath({name: "Dynamic", pack: []}),
            expr: macro return _yscript.callFunction(methodName, args),
            params: []
        };
        fields.push({name: "callYMethod", doc: null, meta: [], access: [APublic], kind: FFun(callMethodFunc), pos: pos});

        var getFieldFunc:Function = {
            args: [{name: "fieldName", type: TPath({name: "String", pack: []})}],
            ret: TPath({name: "Dynamic", pack: []}),
            expr: macro return _yscript.getVariable(fieldName),
            params: []
        };
        fields.push({name: "getYField", doc: null, meta: [], access: [APublic], kind: FFun(getFieldFunc), pos: pos});

        var setFieldFunc:Function = {
            args: [
                {name: "fieldName", type: TPath({name: "String", pack: []})},
                {name: "value", type: TPath({name: "Dynamic", pack: []})}
            ],
            ret: TPath({name: "Void", pack: []}),
            expr: macro _yscript.setVariable(fieldName, value),
            params: []
        };
        fields.push({name: "setYField", doc: null, meta: [], access: [APublic], kind: FFun(setFieldFunc), pos: pos});

        var getClassNameFunc:Function = {
            args: [],
            ret: TPath({name: "String", pack: []}),
            expr: macro return $v{moduleInfo.moduleName},
            params: []
        };
        fields.push({name: "getYClassName", doc: null, meta: [], access: [APublic], kind: FFun(getClassNameFunc), pos: pos});

        // Generate static convenience methods for module-level functions
        for (func in moduleInfo.moduleLevelFunctions) {
            var args = [for (param in func.parameters) {
                name: param.name,
                type: convertYTypeToComplexType(param.type)
            }];

            var argNames = [for (param in func.parameters) macro $i{param.name}];
            var argsArray = {expr: EArrayDecl(argNames), pos: Context.currentPos()};

            var moduleTypePath = moduleInfo.packageName != null
                ? {name: moduleInfo.moduleName, pack: moduleInfo.packageName.split(".")}
                : {name: moduleInfo.moduleName, pack: []};

            var instanceExpr = {expr: ENew(moduleTypePath, []), pos: Context.currentPos()};

            var methodFunc:Function = {
                args: args,
                ret: convertYTypeToComplexType(func.returnType),
                expr: macro {
                    var instance = $instanceExpr;
                    return cast instance.callYMethod($v{func.name}, $argsArray);
                },
                params: []
            };

            var methodField:Field = {
                name: func.name,
                doc: null,
                meta: [],
                access: [APublic, AStatic],
                kind: FFun(methodFunc),
                pos: pos
            };
            fields.push(methodField);
        }

        // Generate static accessors for module-level variables
        for (variable in moduleInfo.moduleLevelVars) {
            var moduleTypePath = moduleInfo.packageName != null
                ? {name: moduleInfo.moduleName, pack: moduleInfo.packageName.split(".")}
                : {name: moduleInfo.moduleName, pack: []};

            var instanceExpr = {expr: ENew(moduleTypePath, []), pos: Context.currentPos()};

            var propField:Field = {
                name: variable.name,
                doc: null,
                meta: [],
                access: [APublic, AStatic],
                kind: FProp("get", "set", convertYTypeToComplexType(variable.type)),
                pos: pos
            };

            var getterField:Field = {
                name: "get_" + variable.name,
                doc: null,
                meta: [],
                access: [APrivate, AStatic],
                kind: FFun({
                    args: [],
                    ret: convertYTypeToComplexType(variable.type),
                    expr: macro {
                        var instance = $instanceExpr;
                        return cast instance.getYField($v{variable.name});
                    },
                    params: []
                }),
                pos: pos
            };

            var setterField:Field = {
                name: "set_" + variable.name,
                doc: null,
                meta: [],
                access: [APrivate, AStatic],
                kind: FFun({
                    args: [{name: "value", type: convertYTypeToComplexType(variable.type)}],
                    ret: convertYTypeToComplexType(variable.type),
                    expr: macro {
                        var instance = $instanceExpr;
                        instance.setYField($v{variable.name}, value);
                        return value;
                    },
                    params: []
                }),
                pos: pos
            };

            fields.push(propField);
            fields.push(getterField);
            fields.push(setterField);
        }

        // Extract package from module path if present
        var packageParts = moduleInfo.packageName != null
            ? moduleInfo.packageName.split(".")
            : [];

        return {
            pack: packageParts,
            name: moduleInfo.moduleName,
            pos: pos,
            meta: [],
            params: [],
            isExtern: false,
            kind: TDClass(null, []),
            fields: fields
        };
    }

    /**
     * Evaluate constant expressions for default values
     */
    static function evalConstExpression(expr:YExpression):Dynamic {
        return switch (expr) {
            case IntLiteral(value): value;
            case FloatLiteral(value): value;
            case StringLiteral(value): value;
            case BoolLiteral(value): value;
            case NullLiteral: null;
            default: null; // Non-constant expression
        };
    }



    #end // macro
}
