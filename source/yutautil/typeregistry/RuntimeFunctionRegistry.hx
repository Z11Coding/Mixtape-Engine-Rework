package yutautil.typeregistry;

import haxe.Json;

#if HSCRIPT_ALLOWED
import hscript.Interp;
import hscript.Parser;
#end

/**
 * Runtime function replacement registry for the in-game source editor.
 *
 * Stores edited function source code and compiled HScript closures. Provides
 * a check-and-dispatch mechanism so that engine code can call:
 *
 * ```haxe
 * var result = RuntimeFunctionRegistry.intercept("myFunction", this, [arg1, arg2]);
 * if (result.intercepted) return result.value;
 * // ... original code ...
 * ```
 *
 * Edited functions are compiled via HScript and executed in a sandboxed
 * interpreter environment with access to standard Haxe utilities, the
 * calling object's context, and the TypeRegistry API.
 *
 * Modifications are persisted to disk as JSON so they survive restarts.
 */
class RuntimeFunctionRegistry {
    private static var _instance:RuntimeFunctionRegistry;

    /** Map of functionId -> edited source code */
    private var editedSources:Map<String, String>;

    /** Map of functionId -> original source code (for revert) */
    private var originalSources:Map<String, String>;

    /** Map of functionId -> metadata about the edit */
    private var editMetadata:Map<String, EditMetadata>;

    #if HSCRIPT_ALLOWED
    /** Shared HScript parser */
    private var parser:Parser;
    #end

    /** Path used for persistence */
    private static final SAVE_FILE = "source_editor_modifications.json";

    public static function get():RuntimeFunctionRegistry {
        if (_instance == null) {
            _instance = new RuntimeFunctionRegistry();
        }
        return _instance;
    }

    private function new() {
        editedSources = new Map();
        originalSources = new Map();
        editMetadata = new Map();

        #if HSCRIPT_ALLOWED
        parser = new Parser();
        parser.allowJSON = true;
        parser.allowTypes = true;
        #end

        // Load any persisted modifications
        loadFromDisk();
    }

    // ===================== Registration API =====================

    /**
     * Register an edited function replacement.
     *
     * @param functionId  Unique identifier (typically "filePath:functionName:startLine")
     * @param functionName  The simple function name
     * @param filePath  Source file path
     * @param originalSource  Original source code (for revert)
     * @param editedSource  New source code to execute instead
     * @return true if registration succeeded
     */
    public function registerEdit(functionId:String, functionName:String, filePath:String, originalSource:String,
            editedSource:String):Bool {
        if (functionId == null || editedSource == null) return false;

        editedSources.set(functionId, editedSource);
        originalSources.set(functionId, originalSource);
        editMetadata.set(functionId, {
            functionName: functionName,
            filePath: filePath,
            editTime: Date.now().toString(),
            active: true
        });

        trace('RuntimeFunctionRegistry: Registered edit for $functionName ($functionId)');

        // Auto-persist
        saveToDisk();
        return true;
    }

    /**
     * Remove an edited function, reverting to original behaviour.
     *
     * @param functionId  The function's unique ID
     * @return true if a replacement was removed
     */
    public function removeEdit(functionId:String):Bool {
        if (!editedSources.exists(functionId)) return false;

        var meta = editMetadata.get(functionId);
        var name = meta != null ? meta.functionName : functionId;

        editedSources.remove(functionId);
        originalSources.remove(functionId);
        editMetadata.remove(functionId);

        trace('RuntimeFunctionRegistry: Removed edit for $name ($functionId)');

        saveToDisk();
        return true;
    }

    /**
     * Check if a function has an active replacement registered.
     */
    public function hasReplacement(functionId:String):Bool {
        if (!editedSources.exists(functionId)) return false;
        var meta = editMetadata.get(functionId);
        return meta != null && meta.active;
    }

    /**
     * Get the edited source code for a function (or null if not edited).
     */
    public function getEditedSource(functionId:String):String {
        return editedSources.get(functionId);
    }

    /**
     * Get the original source code stored when the edit was registered.
     */
    public function getOriginalSource(functionId:String):String {
        return originalSources.get(functionId);
    }

    /**
     * Get metadata for an edit.
     */
    public function getEditMetadata(functionId:String):EditMetadata {
        return editMetadata.get(functionId);
    }

    /**
     * Temporarily disable an edit without removing it.
     */
    public function setActive(functionId:String, active:Bool):Void {
        var meta = editMetadata.get(functionId);
        if (meta != null) {
            meta.active = active;
            saveToDisk();
        }
    }

    /**
     * Get all registered function IDs.
     */
    public function getAllEditIds():Array<String> {
        return [for (id in editedSources.keys()) id];
    }

    /**
     * Get count of active edits.
     */
    public function getActiveEditCount():Int {
        var count = 0;
        for (meta in editMetadata) {
            if (meta.active) count++;
        }
        return count;
    }

    /**
     * Clear all edits.
     */
    public function clearAll():Void {
        editedSources.clear();
        originalSources.clear();
        editMetadata.clear();
        saveToDisk();
        trace("RuntimeFunctionRegistry: Cleared all edits");
    }

    // ===================== Execution API =====================

    /**
     * Attempt to intercept a function call with an edited replacement.
     *
     * Usage from engine code:
     * ```haxe
     * var result = RuntimeFunctionRegistry.get().intercept("myFile.hx:myFunc:42", this, [arg1]);
     * if (result.intercepted) return result.value;
     * // ... original code continues ...
     * ```
     *
     * @param functionId  The function's unique ID
     * @param context  The `this` object (or null for static functions)
     * @param args  Function arguments
     * @return InterceptResult with `intercepted` flag and optional `value`
     */
    public function intercept(functionId:String, context:Dynamic, args:Array<Dynamic>):InterceptResult {
        if (!hasReplacement(functionId)) {
            return {intercepted: false, value: null};
        }

        #if HSCRIPT_ALLOWED
        var editedSource = editedSources.get(functionId);
        if (editedSource == null) {
            return {intercepted: false, value: null};
        }

        try {
            var result = executeHScript(editedSource, context, args);
            return {intercepted: true, value: result};
        } catch (e:Dynamic) {
            var meta = editMetadata.get(functionId);
            var name = meta != null ? meta.functionName : functionId;
            trace('RuntimeFunctionRegistry: Error executing edited $name: $e');
            trace('RuntimeFunctionRegistry: Falling back to original implementation');
            return {intercepted: false, value: null};
        }
        #else
        // Without HScript we cannot execute edited code
        return {intercepted: false, value: null};
        #end
    }

    /**
     * Execute an arbitrary HScript snippet in a sandboxed environment.
     * Useful for testing edited code from the editor UI.
     *
     * @param source  HScript source code
     * @param context  Optional `this` binding
     * @param args  Optional positional arguments (available as `arg0`, `arg1`, ...)
     * @return The result of execution
     */
    public function executeHScript(source:String, context:Dynamic = null, args:Array<Dynamic> = null):Dynamic {
        #if HSCRIPT_ALLOWED
        var interp = new Interp();
        setupInterpreterEnvironment(interp, context, args);

        var expr = parser.parseString(source);
        return interp.execute(expr);
        #else
        trace("RuntimeFunctionRegistry: HScript not available");
        return null;
        #end
    }

    #if HSCRIPT_ALLOWED
    /**
     * Configure an HScript interpreter with standard bindings.
     */
    private function setupInterpreterEnvironment(interp:Interp, context:Dynamic, args:Array<Dynamic>):Void {
        // Standard Haxe APIs
        interp.variables.set("Math", Math);
        interp.variables.set("Std", Std);
        interp.variables.set("Type", Type);
        interp.variables.set("Reflect", Reflect);
        interp.variables.set("StringTools", StringTools);
        interp.variables.set("Date", Date);

        // Trace
        interp.variables.set("trace", function(v:Dynamic) {
            trace("[Edited Function] " + Std.string(v));
        });

        // Engine access
        interp.variables.set("TypeRegistry", yutautil.typeregistry.TypeRegistryAPI);
        interp.variables.set("FunctionRegistry", RuntimeFunctionRegistry.get());

        // Context binding — the object the function was called on
        if (context != null) {
            interp.variables.set("self", context);
            interp.variables.set("this", context);

            // Expose the context's fields directly
            try {
                var fields = Type.getInstanceFields(Type.getClass(context));
                if (fields != null) {
                    for (field in fields) {
                        try {
                            var val = Reflect.getProperty(context, field);
                            interp.variables.set(field, val);
                        } catch (_:Dynamic) {}
                    }
                }
            } catch (_:Dynamic) {}
        }

        // Positional arguments
        if (args != null) {
            for (i in 0...args.length) {
                interp.variables.set("arg" + Std.string(i), args[i]);
            }
            interp.variables.set("args", args);
        }
    }
    #end

    // ===================== Persistence =====================

    /**
     * Save all modifications to disk as JSON.
     */
    public function saveToDisk():Void {
        try {
            var data:Dynamic = {
                version: 1,
                timestamp: Date.now().toString(),
                edits: []
            };

            for (id in editedSources.keys()) {
                var meta = editMetadata.get(id);
                data.edits.push({
                    functionId: id,
                    functionName: meta != null ? meta.functionName : "",
                    filePath: meta != null ? meta.filePath : "",
                    originalSource: originalSources.get(id),
                    editedSource: editedSources.get(id),
                    editTime: meta != null ? meta.editTime : "",
                    active: meta != null ? meta.active : true
                });
            }

            var json = Json.stringify(data, null, "  ");
            var savePath = getSavePath();

            // Ensure directory exists
            var dir = haxe.io.Path.directory(savePath);
            if (dir.length > 0 && !sys.FileSystem.exists(dir)) {
                sys.FileSystem.createDirectory(dir);
            }

            sys.io.File.saveContent(savePath, json);
            trace('RuntimeFunctionRegistry: Saved ${getAllEditIds().length} edits to disk');
        } catch (e:Dynamic) {
            trace('RuntimeFunctionRegistry: Failed to save to disk: $e');
        }
    }

    /**
     * Load modifications from disk.
     */
    public function loadFromDisk():Void {
        try {
            var savePath = getSavePath();
            if (!sys.FileSystem.exists(savePath)) return;

            var json = sys.io.File.getContent(savePath);
            var data = Json.parse(json);

            if (data.edits == null) return;

            var loaded = 0;
            var edits:Array<Dynamic> = cast data.edits;
            for (edit in edits) {
                editedSources.set(edit.functionId, edit.editedSource);
                if (edit.originalSource != null) {
                    originalSources.set(edit.functionId, edit.originalSource);
                }
                editMetadata.set(edit.functionId, {
                    functionName: edit.functionName,
                    filePath: edit.filePath,
                    editTime: edit.editTime,
                    active: edit.active != null ? cast edit.active : true
                });
                loaded++;
            }

            if (loaded > 0) {
                trace('RuntimeFunctionRegistry: Loaded $loaded edits from disk');
            }
        } catch (e:Dynamic) {
            trace('RuntimeFunctionRegistry: Failed to load from disk: $e');
        }
    }

    /**
     * Get the save file path for modifications.
     */
    private function getSavePath():String {
        // Use the engine's save directory
        return SAVE_FILE;
    }
}

/**
 * Result of an intercept attempt.
 */
typedef InterceptResult = {
    /** Whether the function was intercepted (edited version ran) */
    intercepted:Bool,

    /** The return value from the edited function (null if not intercepted) */
    value:Dynamic
}

/**
 * Metadata about a function edit.
 */
typedef EditMetadata = {
    /** Simple function name */
    functionName:String,

    /** Source file path */
    filePath:String,

    /** When the edit was made */
    editTime:String,

    /** Whether the edit is currently active */
    active:Bool
}
