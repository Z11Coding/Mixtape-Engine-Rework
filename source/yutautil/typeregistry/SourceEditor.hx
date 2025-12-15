package yutautil.typeregistry;

import haxe.Json;
import yutautil.typeregistry.SourceMapper;

#if HSCRIPT_ALLOWED
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
#end

/**
 * In-game source code editor with runtime function replacement
 * Uses HScript for executing modified functions with proper import resolution
 */
class SourceEditor {
    private static var _instance:SourceEditor;
    private var modifiedFunctions:Map<String, ModifiedFunction>;
    private var activeReplacements:Map<String, Dynamic->Dynamic>;

    #if HSCRIPT_ALLOWED
    private var hscriptParser:Parser;
    private var hscriptInterp:Interp;
    #end

    public static function get():SourceEditor {
        if (_instance == null) {
            _instance = new SourceEditor();
        }
        return _instance;
    }

    private function new() {
        modifiedFunctions = new Map();
        activeReplacements = new Map();

        #if HSCRIPT_ALLOWED
        hscriptParser = new Parser();
        hscriptInterp = new Interp();
        setupHScriptEnvironment();
        #end
    }

    #if HSCRIPT_ALLOWED
    /**
     * Setup HScript environment with imports and utilities
     */
    private function setupHScriptEnvironment():Void {
        // Add standard Haxe types and utilities
        hscriptInterp.variables.set("Math", Math);
        hscriptInterp.variables.set("Std", Std);
        hscriptInterp.variables.set("Type", Type);
        hscriptInterp.variables.set("Reflect", Reflect);
        hscriptInterp.variables.set("StringTools", StringTools);

        // Add trace function
        hscriptInterp.variables.set("trace", function(v:Dynamic) {
            trace("[Modified Function] " + Std.string(v));
        });

        // Add type registry access
        hscriptInterp.variables.set("TypeRegistry", yutautil.typeregistry.TypeRegistryAPI);
    }
    #end

    /**
     * Modify a function with new source code
     */
    public function modifyFunction(functionId:String, newSource:String, className:String = null):Bool {
        var functionInfo = findFunction(functionId, className);
        if (functionInfo == null) {
            trace('SourceEditor: Function not found: $functionId');
            return false;
        }

        if (!functionInfo.isEditable()) {
            trace('SourceEditor: Function is hardcoded and cannot be modified: $functionId');
            return false;
        }

        // Validate the new source code
        if (!validateFunctionSource(newSource, functionInfo)) {
            trace('SourceEditor: Invalid function source for $functionId');
            return false;
        }

        // Create modified function tracking
        var modified = new ModifiedFunction(functionInfo, newSource);
        modifiedFunctions.set(functionInfo.getUniqueId(), modified);
        modified.apply();

        // Compile and prepare the replacement function
        #if HSCRIPT_ALLOWED
        var replacement = compileModifiedFunction(functionInfo, newSource);
        if (replacement != null) {
            activeReplacements.set(functionInfo.getUniqueId(), replacement);

            // Inject the replacement into the runtime
            injectFunctionReplacement(functionInfo, replacement);

            trace('SourceEditor: Successfully modified function: $functionId');
            return true;
        }
        #else
        trace('SourceEditor: HScript not available, cannot apply function modification');
        #end

        return false;
    }

    /**
     * Revert a function modification
     */
    public function revertFunction(functionId:String, className:String = null):Bool {
        var functionInfo = findFunction(functionId, className);
        if (functionInfo == null) {
            return false;
        }

        var uniqueId = functionInfo.getUniqueId();
        var modified = modifiedFunctions.get(uniqueId);
        if (modified == null) {
            trace('SourceEditor: No modification found for function: $functionId');
            return false;
        }

        // Revert the modification
        modified.revert();
        modifiedFunctions.remove(uniqueId);
        activeReplacements.remove(uniqueId);

        // Remove the runtime replacement
        removeDirectionReplacement(functionInfo);

        trace('SourceEditor: Reverted function: $functionId');
        return true;
    }

    /**
     * Get all modified functions
     */
    public function getModifiedFunctions():Array<ModifiedFunction> {
        return [for (modified in modifiedFunctions) modified];
    }

    /**
     * Check if a function is modified
     */
    public function isFunctionModified(functionId:String, className:String = null):Bool {
        var functionInfo = findFunction(functionId, className);
        if (functionInfo == null) return false;

        return modifiedFunctions.exists(functionInfo.getUniqueId());
    }

    /**
     * Get the effective source for a function (modified or original)
     */
    public function getEffectiveSource(functionId:String, className:String = null):String {
        var functionInfo = findFunction(functionId, className);
        if (functionInfo == null) return null;

        return functionInfo.getEffectiveSource();
    }

    #if HSCRIPT_ALLOWED
    /**
     * Compile a modified function using HScript
     */
    private function compileModifiedFunction(functionInfo:FunctionInfo, source:String):Dynamic->Dynamic {
        try {
            // Prepare the complete function context
            var fullSource = prepareFunctionContext(functionInfo, source);

            // Parse and compile
            var expr = hscriptParser.parseString(fullSource);
            var compiledFunction = hscriptInterp.execute(expr);

            return cast compiledFunction;
        } catch (e:Dynamic) {
            trace('SourceEditor: Failed to compile modified function ${functionInfo.name}: $e');
            return null;
        }
    }

    /**
     * Prepare the complete function context with imports and dependencies
     */
    private function prepareFunctionContext(functionInfo:FunctionInfo, functionSource:String):String {
        var sourceFile = SourceMapper.parseSourceFile(functionInfo.filePath);
        if (sourceFile == null) {
            return functionSource;
        }

        var context = new StringBuf();

        // Add available imports to HScript context
        for (importInfo in sourceFile.imports) {
            setupImportInHScript(importInfo);
        }

        // Add using statements context
        for (usingStmt in sourceFile.usingStatements) {
            setupUsingInHScript(usingStmt);
        }

        // Wrap the function in an executable context
        context.add('function executeModified() {\n');
        context.add('  $functionSource\n');
        context.add('  return ${functionInfo.name};\n');
        context.add('}\n');
        context.add('executeModified();\n');

        return context.toString();
    }

    /**
     * Setup an import in the HScript environment
     */
    private function setupImportInHScript(importInfo:ImportInfo):Void {
        try {
            var typeName = importInfo.alias != null ? importInfo.alias : importInfo.path.split(".").pop();
            var typeClass = Type.resolveClass(importInfo.path);

            if (typeClass != null) {
                hscriptInterp.variables.set(typeName, typeClass);
            } else {
                // Try to resolve as enum
                var typeEnum = Type.resolveEnum(importInfo.path);
                if (typeEnum != null) {
                    hscriptInterp.variables.set(typeName, typeEnum);
                }
            }
        } catch (e:Dynamic) {
            // Import resolution failed, continue silently
        }
    }

    /**
     * Setup a using statement in the HScript environment
     */
    private function setupUsingInHScript(usingPath:String):Void {
        try {
            var usingClass = Type.resolveClass(usingPath);
            if (usingClass != null) {
                // Make static methods available
                var className = Type.getClassName(usingClass);
                hscriptInterp.variables.set(className.split(".").pop(), usingClass);
            }
        } catch (e:Dynamic) {
            // Using resolution failed, continue silently
        }
    }
    #end

    /**
     * Validate function source code
     */
    private function validateFunctionSource(source:String, functionInfo:FunctionInfo):Bool {
        if (source == null || source.trim().length == 0) {
            return false;
        }

        // Check that the function signature matches
        var functionNameRegex = new EReg('function\\s+${functionInfo.name}\\s*\\(', "g");
        if (!functionNameRegex.match(source)) {
            trace('SourceEditor: Function signature does not match: ${functionInfo.name}');
            return false;
        }

        #if HSCRIPT_ALLOWED
        // Try to parse with HScript to check for syntax errors
        try {
            var testSource = 'function test() { $source }';
            hscriptParser.parseString(testSource);
            return true;
        } catch (e:Dynamic) {
            trace('SourceEditor: Syntax error in modified function: $e');
            return false;
        }
        #else
        // Basic validation without HScript
        return true;
        #end
    }

    /**
     * Find a function by ID and optional class name
     */
    private function findFunction(functionId:String, className:String):FunctionInfo {
        // Try exact match first
        if (functionId.indexOf(":") >= 0) {
            // Full unique ID provided
            for (sourceFile in SourceMapper.getAllSourceFiles()) {
                for (func in sourceFile.functions) {
                    if (func.getUniqueId() == functionId) {
                        return func;
                    }
                }
            }
        } else {
            // Function name only, use className if provided
            return SourceMapper.getFunction(functionId, className);
        }

        return null;
    }

    /**
     * Inject function replacement into runtime (placeholder for actual implementation)
     */
    private function injectFunctionReplacement(functionInfo:FunctionInfo, replacement:Dynamic->Dynamic):Void {
        // This is a placeholder for the actual injection mechanism
        // In a real implementation, this would hook into the target class/object
        // and replace the method at runtime

        trace('SourceEditor: Injecting replacement for ${functionInfo.name}');

        // For now, we just store the replacement for potential future use
        // The actual injection would depend on the specific class structure
        // and might require additional reflection or proxy mechanisms
    }

    /**
     * Remove function replacement from runtime
     */
    private function removeDirectionReplacement(functionInfo:FunctionInfo):Void {
        // Placeholder for removing runtime replacements
        trace('SourceEditor: Removing replacement for ${functionInfo.name}');
    }

    /**
     * Get statistics about modifications
     */
    public function getModificationStats():{total:Int, active:Int, reverted:Int} {
        var active = 0;
        var reverted = 0;

        for (modified in modifiedFunctions) {
            if (modified.isActive) {
                active++;
            } else {
                reverted++;
            }
        }

        return {
            total: active + reverted,
            active: active,
            reverted: reverted
        };
    }

    /**
     * Export all modifications as JSON
     */
    public function exportModifications():String {
        var exportData = {
            timestamp: Date.now().toString(),
            modifications: []
        };

        for (modified in modifiedFunctions) {
            exportData.modifications.push({
                functionId: modified.functionInfo.getUniqueId(),
                functionName: modified.functionInfo.name,
                filePath: modified.functionInfo.filePath,
                originalSource: modified.originalSource,
                modifiedSource: modified.modifiedSource,
                modificationTime: modified.modificationTime.toString(),
                isActive: modified.isActive
            });
        }

        return Json.stringify(exportData, null, "  ");
    }

    /**
     * Import modifications from JSON
     */
    public function importModifications(jsonData:String):Bool {
        try {
            var importData = Json.parse(jsonData);
            var imported = 0;

            for (modData in cast(importData.modifications, Array<Dynamic>)) {
                var functionInfo = findFunction(modData.functionId, null);
                if (functionInfo != null && functionInfo.isEditable()) {
                    if (modifyFunction(modData.functionId, modData.modifiedSource)) {
                        imported++;
                    }
                }
            }

            trace('SourceEditor: Imported $imported modifications');
            return imported > 0;
        } catch (e:Dynamic) {
            trace('SourceEditor: Failed to import modifications: $e');
            return false;
        }
    }

    /**
     * Clear all modifications
     */
    public function clearAllModifications():Void {
        var functionIds = [for (id in modifiedFunctions.keys()) id];

        for (id in functionIds) {
            var modified = modifiedFunctions.get(id);
            if (modified != null) {
                revertFunction(modified.functionInfo.name, null);
            }
        }

        trace('SourceEditor: Cleared all modifications');
    }
}
