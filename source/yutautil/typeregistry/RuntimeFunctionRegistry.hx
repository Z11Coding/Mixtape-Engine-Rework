package yutautil.typeregistry;

import haxe.Json;
import yutautil.modules.ASync.AResult;
import yutautil.modules.ASync.AsyncState;
import yutautil.modules.ASync;

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
 *
 * ## Asynchronous loading
 *
 * The registry loads persisted edits and editable-function metadata on a
 * background worker thread (via `yutautil.modules.ASync`), so constructing
 * the registry never blocks. Until the load finishes, `intercept()` simply
 * does not fire - the original implementation always runs. Poll
 * `getLoadProgress()` (or `isReady()`) to drive a loading UI, or use
 * `onReady(...)` to be notified the moment interception becomes live:
 *
 * ```haxe
 * var registry = FunctionRegistry;
 * if (!registry.isReady()) {
 *     var p = registry.getLoadProgress();
 *     trace('Loading: ${Math.round(p.percent * 100)}% (${p.stage})');
 * }
 * registry.onReady(function(_) trace('ready'));
 * ```
 *
 * ## Script-friendly API
 *
 * Every editable function also has a natural reflection-style alias such as
 * `states.PlayState.create` (generated at compile time). Scripts can use the
 * alias or the raw function ID interchangeably:
 *
 * ```haxe
 * // Persistent edit - original source is supplied automatically:
 * FunctionRegistry.edit("states.PlayState.create", "trace('hi');");
 *
 * // Temporary edit - only affects the current state, never saved to disk.
 * // MusicBeatState.destroy() clears state-bound temporary edits eagerly,
 * // and any leftovers expire automatically when the state changes:
 * FunctionRegistry.editTemporary("states.PlayState.create", "trace('hi');");
 *
 * // Temporary edits bind to a typesafe `StateRef` - either a specific state
 * // instance, or a state class (matching ANY current state of that class,
 * // which survives instance swaps like state resets):
 * FunctionRegistry.editTemporary("states.PlayState.create", "trace('hi');",
 *     StateRef.fromClass(states.PlayState));
 *
 * // Function references (Haxe closures, YScript getFunctionReference(),
 * // Lua callbacks bridged via Lua_helper, etc.) work everywhere a source
 * // string does:
 * FunctionRegistry.edit("states.PlayState.create", (ctx) -> trace(ctx.args));
 *
 * // Compare original vs edited source:
 * var details = FunctionRegistry.getEditDetails("states.PlayState.create");
 * trace(details.originalSource);
 * trace(details.editedSource);
 *
 * // Revert:
 * FunctionRegistry.removeEdit("states.PlayState.create");
 * FunctionRegistry.clearTemporaryEdits();
 * ```
 *
 * ## Mod edits
 *
 * Mods can register their own edits, which apply only while that mod is
 * loaded (see `backend.Mods`). When several loaded mods edit the same
 * function, the top mod (first entry in the enabled mods list, matching
 * `Mods.loadTopMod`) takes priority:
 *
 * ```haxe
 * FunctionRegistry.registerModEdit("myModFolder", "states.PlayState.create", "trace('modded');");
 * FunctionRegistry.unregisterModEdit("myModFolder", "states.PlayState.create");
 * FunctionRegistry.clearModEdits("myModFolder");
 * ```
 *
 * Overall priority when multiple overrides exist for the same function:
 *   1. State-scoped temporary edits (most ephemeral)
 *   2. Mod edits (active only while the mod is loaded, top mod wins)
 *   3. Persistent edits (saved across sessions)
 */
class RuntimeFunctionRegistry {
    private static var _instance:RuntimeFunctionRegistry;

    /** Map of functionId -> edited source code */
    private var editedSources:Map<String, String>;

    /** Map of functionId -> edited function reference (alternative to source) */
    private var editedCallbacks:Map<String, FunctionEditCallback>;

    /** Map of mod folder -> (functionId -> mod edit entry). Session-only. */
    private var modEdits:Map<String, Map<String, ModEditEntry>>;

    /** Map of functionId -> original source code (for revert) */
    private var originalSources:Map<String, String>;

    /** Map of functionId -> metadata about the edit */
    private var editMetadata:Map<String, EditMetadata>;

    /** Map of functionId -> complete function metadata (loaded from resource) */
    private var editableFunctions:Map<String, EditableFunctionInfo>;

    /** Map of reflection-style alias ("states.PlayState.create") -> functionId */
    private var aliasToId:Map<String, String>;

    /** Flag to track if editable functions have been loaded from resource */
    private var editableFunctionsLoaded:Bool = false;

    // ---- Async loading state ----
    /** Guard ensuring the background load is only kicked off once. */
    private var loadStarted:Bool = false;
    /** Handle to the background load, for progress / readiness checks. */
    private var loadResult:AResult<Dynamic> = null;
    /** Mutex protecting the progress counters (read from other threads). */
    private var loadMutex:sys.thread.Mutex = new sys.thread.Mutex();
    /** Human-readable description of the current load stage. */
    private var loadStage:String = "not started";
    /** Number of items processed so far (editable functions, disk edits). */
    private var loadProcessed:Int = 0;
    /** Total number of items expected (0 = not yet known). */
    private var loadTotal:Int = 0;

    /**
     * Optional custom provider for the "current state" used to bind temporary
     * edits. When null, defaults to `flixel.FlxG.state` (when Flixel is
     * available). Assign your own function if temporary edits should track a
     * different scope.
     */
    public var stateProvider:Null<Void->Dynamic> = null;

    #if HSCRIPT_ALLOWED
    /** Shared HScript parser */
    private var parser:Parser;

    /** Global HScript interpreter for edited functions (reused across calls for efficiency) */
    private var globalInterpreter:Interp;
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
        editedCallbacks = new Map();
        modEdits = new Map();
        originalSources = new Map();
        editMetadata = new Map();
        editableFunctions = new Map();
        aliasToId = new Map();

        #if HSCRIPT_ALLOWED
        parser = new Parser();
        parser.allowJSON = true;
        parser.allowTypes = true;
        globalInterpreter = new Interp();
        #end

        // Kick off the (expensive) persisted-modification load in the
        // background so constructing the registry doesn't block. Calls to
        // `intercept` simply won't fire until the load completes.
        loadFromDisk();
    }

    // ===================== Async load progress =====================

    /**
     * Whether the background registry load (persisted edits + editable
     * function metadata) has fully completed and interception is live.
     */
    public function isReady():Bool {
        return loadResult != null && loadResult.isReady;
    }

    /**
     * Whether the background load is currently in progress.
     */
    public function isLoading():Bool {
        return loadResult != null && loadResult.isPending;
    }

    /**
     * Get the current background-load progress.
     * `percent` is 0..1 (1 once ready), `processed`/`total` count the items
     * loaded so far, `stage` describes the current phase, and `elapsedTime`
     * is how many seconds the load has been running.
     */
    public function getLoadProgress():LoadProgress {
        loadMutex.acquire();
        var stage = loadStage;
        var processed = loadProcessed;
        var total = loadTotal;
        loadMutex.release();

        var elapsed:Float = loadResult != null ? loadResult.elapsedTime : 0.0;
        var ready = isReady();
        var failed = loadResult != null && loadResult.isFailed;
        var percent = ready ? 1.0 : (total > 0 ? processed / total : (loadStarted ? 0.0 : 0.0));

        return {
            stage: stage,
            processed: processed,
            total: total,
            percent: percent,
            ready: ready,
            failed: failed,
            loading: !ready && !failed && loadStarted,
            elapsedTime: elapsed
        };
    }

    /**
     * Register a callback fired when the background load completes.
     * Fires immediately if already ready. Returns `this` for chaining.
     */
    public function onReady(callback:RuntimeFunctionRegistry->Void):RuntimeFunctionRegistry {
        if (callback == null) return this;
        if (isReady()) {
            callback(this);
        } else if (loadResult != null) {
            var self = this;
            loadResult.onReady(function(_) callback(self));
            loadResult.onError(function(_) callback(self)); // still notify so callers aren't stuck
        } else {
            // Load hasn't started yet (shouldn't happen once constructed) - fire lazily.
            callback(this);
        }
        return this;
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
        return registerEditInternal(resolveFunctionId(functionId), functionName, filePath, originalSource,
            editedSource, null, true, false, null);
    }

    /**
     * Internal registration shared by persistent and temporary edits.
     *
     * @param persist  Whether to write the change to disk
     * @param temporary  Whether this edit is temporary (never persisted)
     * @param tempState  StateRef a temporary edit is bound to (null = untracked)
     */
    private function registerEditInternal(functionId:String, functionName:String, filePath:String, originalSource:String,
            editedSource:String, ?callback:FunctionEditCallback, persist:Bool, temporary:Bool, tempState:Null<StateRef>):Bool {
        if (functionId == null || (editedSource == null && callback == null)) return false;

        if (callback != null) {
            editedCallbacks.set(functionId, callback);
            editedSources.remove(functionId); // A callback edit replaces any source edit
        } else {
            editedSources.set(functionId, editedSource);
            editedCallbacks.remove(functionId); // A source edit replaces any callback edit
        }
        originalSources.set(functionId, originalSource);
        editMetadata.set(functionId, {
            functionName: functionName,
            filePath: filePath,
            editTime: Date.now().toString(),
            active: true,
            temporary: temporary,
            tempState: tempState,
            isCallback: callback != null
        });

        trace('RuntimeFunctionRegistry: Registered ${temporary ? "temporary " : ""}${callback != null ? "callback " : ""}edit for $functionName ($functionId)');

        // Auto-persist (temporary edits are never written to disk, and
        // function references cannot be serialized)
        if (persist && callback == null) {
            saveToDisk();
        }
        return true;
    }

    /**
     * Shared implementation for `edit` / `editTemporary`: accepts either an
     * HScript source String or a function reference (Haxe closure, YScript
     * function reference, Lua callback bridged through Lua_helper, ...).
     */
    private function applyEdit(info:EditableFunctionInfo, edit:Dynamic, persist:Bool, temporary:Bool, tempState:Null<StateRef>):Bool {
        if (edit == null) return false;

        if (Reflect.isFunction(edit)) {
            return registerEditInternal(info.functionId, info.functionName, info.filePath, info.originalExpression,
                null, cast edit, false, temporary, tempState);
        }
        if (Std.isOfType(edit, String)) {
            var source:String = cast edit;
            return registerEditInternal(info.functionId, info.functionName, info.filePath, info.originalExpression,
                source, null, persist, temporary, tempState);
        }

        trace('RuntimeFunctionRegistry: Unsupported edit value - expected an HScript source String or a function reference');
        return false;
    }

    /**
     * Resolve a function ID or reflection-style alias ("states.PlayState.create")
     * to the canonical function ID used by the registry. Unknown input is
     * returned unchanged so raw IDs always keep working.
     */
    public function resolveFunctionId(idOrAlias:String):String {
        if (idOrAlias == null) return null;
        // Fast path: already a canonical ID
        if (editedSources.exists(idOrAlias)) return idOrAlias;
        loadEditableFunctionsFromResource();
        if (editableFunctions.exists(idOrAlias)) return idOrAlias;
        var resolved = aliasToId.get(idOrAlias);
        return resolved != null ? resolved : idOrAlias;
    }

    /**
     * Get the reflection-style alias ("states.PlayState.create") for a function,
     * or null if the function is unknown.
     */
    public function getAlias(idOrAlias:String):String {
        var info = getEditableFunctionInfo(idOrAlias);
        return info != null ? info.alias : null;
    }

    /**
     * Get all known reflection-style aliases.
     */
    public function getAllAliases():Array<String> {
        loadEditableFunctionsFromResource();
        return [for (alias in aliasToId.keys()) alias];
    }

    /**
     * Load all editable functions from the embedded resource.
     *
     * No longer blocks: if the background load is still running this returns
     * immediately (leaving the maps empty) rather than forcing the expensive
     * `BuildDataLoader.getRawData()` call on the calling thread. Callers that
     * need the metadata (intercept, alias resolution) simply decline to act
     * until `isReady()` is true.
     */
    private function loadEditableFunctionsFromResource():Void {
        // Kick off the background load if it hasn't started (lazy - covers the
        // case where something touches the registry before construction fully
        // settled, or a manual reload is requested).
        startBackgroundLoad();
        // Intentionally do NOT wait - interception stays disabled until ready.
    }

    /**
     * Start the background load pipeline (persisted disk edits + editable
     * function metadata) exactly once, on a worker thread, tracking progress.
     */
    private function startBackgroundLoad():Void {
        if (loadStarted) return;
        loadStarted = true;

        var work:ASync<Void->Dynamic> = ASyncHelper.async0(function():Dynamic {
            setLoadStage("reading saved edits");
            var edits = readPersistedEdits();

            loadMutex.acquire();
            loadTotal = edits.length;
            loadProcessed = 0;
            loadMutex.release();

            // Apply persisted edits on the worker thread, counting progress.
            setLoadStage("applying saved edits");
            for (edit in edits) {
                applyPersistedEdit(edit);
                loadMutex.acquire();
                loadProcessed++;
                loadMutex.release();
            }

            // Now pull in editable-function metadata / aliases.
            setLoadStage("loading function metadata");
            loadEditableFunctionsData();

            setLoadStage("ready");
            return null;
        });

        loadResult = work();

        loadResult.onReady(function(_) {
            setLoadStage("ready");
            trace('RuntimeFunctionRegistry: Background load complete');
        });
        loadResult.onError(function(e) {
            setLoadStage("failed");
            trace('RuntimeFunctionRegistry: Background load failed: ' + Std.string(e));
        });
    }

    private inline function setLoadStage(stage:String):Void {
        loadMutex.acquire();
        loadStage = stage;
        loadMutex.release();
    }

    /**
     * Worker-side: read and apply editable-function metadata + aliases from
     * the build data resource. Safe to call on a background thread because it
     * only writes to this instance's maps, which the main thread does not read
     * until `isReady()`.
     */
    private function loadEditableFunctionsData():Void {
        if (editableFunctionsLoaded) return;
        editableFunctionsLoaded = true;

        try {
            var buildData = yutautil.typeregistry.BuildDataLoader.getRawData();
            if (buildData == null) {
                trace("RuntimeFunctionRegistry: No build data available");
                return;
            }

            var editableFuncs = Reflect.getProperty(buildData, "editableFunctions");
            if (editableFuncs == null) {
                trace("RuntimeFunctionRegistry: No editable functions in build data");
                return;
            }

            var funcList:Array<Dynamic> = cast editableFuncs;

            // Grow the total to include metadata items so progress stays smooth.
            loadMutex.acquire();
            loadTotal = loadTotal + funcList.length;
            loadMutex.release();

            for (funcData in funcList) {
                var funcId = Reflect.getProperty(funcData, "functionId");
                var editableInfo:EditableFunctionInfo = cast funcData;
                editableFunctions.set(funcId, editableInfo);

                var alias:String = Reflect.getProperty(funcData, "alias");
                if (alias != null && !aliasToId.exists(alias)) {
                    aliasToId.set(alias, funcId);
                }

                loadMutex.acquire();
                loadProcessed++;
                loadMutex.release();
            }

            trace('RuntimeFunctionRegistry: Loaded ${funcList.length} editable functions from resource');
        } catch (e:Dynamic) {
            trace("RuntimeFunctionRegistry: Error loading editable functions from resource: " + Std.string(e));
        }
    }

    /**
     * Get information about all editable functions.
     */
    public function getAllEditableFunctions():Array<EditableFunctionInfo> {
        loadEditableFunctionsFromResource();
        return [for (func in editableFunctions) func];
    }

    /**
     * Get information about a specific editable function.
     * Accepts a function ID or a reflection-style alias.
     */
    public function getEditableFunctionInfo(idOrAlias:String):EditableFunctionInfo {
        loadEditableFunctionsFromResource();
        var info = editableFunctions.get(idOrAlias);
        if (info == null) {
            var resolved = aliasToId.get(idOrAlias);
            if (resolved != null) info = editableFunctions.get(resolved);
        }
        return info;
    }

    /**
     * Get the original function expression (before instrumentation).
     * Accepts a function ID or a reflection-style alias.
     */
    public function getOriginalExpression(idOrAlias:String):String {
        var info = getEditableFunctionInfo(idOrAlias);
        return info != null ? info.originalExpression : null;
    }

    /**
     * Easy script-facing edit: register a persistent replacement using a
     * function ID or alias ("states.PlayState.create"). The original source,
     * function name and file path are supplied automatically from compile-time
     * data - only the new source is required.
     *
     * @param idOrAlias  Function ID or alias
     * @param newSource  New HScript source code - or a function reference
     *                   `(ctx:FunctionEditContext) -> Dynamic` - to execute
     *                   instead. Function references cannot be persisted and
     *                   are session-only.
     * @return true if the edit was registered
     */
    public function edit(idOrAlias:String, newSource:Dynamic):Bool {
        var info = getEditableFunctionInfo(idOrAlias);
        if (info == null) {
            reportUnknownLookup(idOrAlias, "edit");
            return false;
        }

        return applyEdit(info, newSource, true, false, null);
    }

    /**
     * Trace a clearer reason for a failed lookup: still loading, or genuinely
     * unknown.
     */
    private function reportUnknownLookup(idOrAlias:String, verb:String):Void {
        if (isLoading() || (loadStarted && !isReady())) {
            trace('RuntimeFunctionRegistry: Cannot $verb "$idOrAlias" yet - the registry is still loading (stage: ${getLoadProgress().stage}). Wait for isReady() / onReady().');
        } else {
            trace('RuntimeFunctionRegistry: Cannot $verb "$idOrAlias" - unknown function ID or alias');
        }
    }

    /**
     * Easy script-facing temporary edit: like `edit`, but the replacement only
     * affects the current state. It is never persisted to disk and expires
     * automatically once the bound state no longer matches (see
     * `stateProvider`; defaults to `flixel.FlxG.state`).
     *
     * @param idOrAlias  Function ID or alias
     * @param newSource  New HScript source code - or a function reference
     *                   `(ctx:FunctionEditContext) -> Dynamic` - to execute
     *                   instead while the bound state is active
     * @param state  Optional explicit `StateRef` binding: a state instance
     *               (implicitly converted) for one specific instance, or
     *               `StateRef.fromClass(states.PlayState)` to match ANY
     *               current state of that class. Defaults to the current
     *               state instance.
     * @param bindToState  When true (default) and no explicit state is given,
     *                     the edit binds to the current state instance;
     *                     when false it only lasts until `clearTemporaryEdits`
     *                     or `removeEdit` is called
     * @return true if the edit was registered
     */
    public function editTemporary(idOrAlias:String, newSource:Dynamic, ?state:Null<StateRef>, bindToState:Bool = true):Bool {
        var info = getEditableFunctionInfo(idOrAlias);
        if (info == null) {
            reportUnknownLookup(idOrAlias, "temporarily edit");
            return false;
        }

        // Resolve the state binding: an explicit StateRef (instance or class)
        // wins; otherwise bind to the current state instance when requested
        // (only MusicBeatState subclass instances are interceptable states,
        //  so a non-MusicBeat current state leaves the edit untracked).
        var tag:Null<StateRef> = null;
        if (state != null) {
            tag = state;
        } else if (bindToState) {
            tag = StateRef.fromState(currentState());
        }
        return applyEdit(info, newSource, false, true, tag);
    }

    /**
     * Remove all temporary edits (persistent edits are kept).
     * @return The number of temporary edits removed
     */
    public function clearTemporaryEdits():Int {
        var toRemove:Array<String> = [];
        for (id in editMetadata.keys()) {
            var meta = editMetadata.get(id);
            if (meta != null && meta.temporary == true) {
                toRemove.push(id);
            }
        }
        for (id in toRemove) {
            expireTemporaryEdit(id);
        }
        if (toRemove.length > 0) {
            trace('RuntimeFunctionRegistry: Cleared ${toRemove.length} temporary edits');
        }
        return toRemove.length;
    }

    /**
     * Get full details about a function and its current edit, including both
     * the original and the edited source. Accepts a function ID or alias.
     */
    public function getEditDetails(idOrAlias:String):EditDetails {
        var info = getEditableFunctionInfo(idOrAlias);
        if (info == null) return null;

        var id = info.functionId;
        var meta = editMetadata.get(id);
        var hasPersonalEdit = editedSources.exists(id) || editedCallbacks.exists(id);

        // Determine which override currently wins for this function
        var origin = "none";
        var modFolder:String = null;
        var editedSource:String = null;
        var isCallback = false;

        var tempActive = meta != null && meta.active && meta.temporary == true && hasPersonalEdit
            && !(meta.tempState != null && !meta.tempState.matches(currentState()));

        if (tempActive) {
            origin = "temporary";
            editedSource = editedSources.get(id);
            isCallback = editedCallbacks.exists(id);
        } else {
            var modEdit = getActiveModEdit(id);
            if (modEdit != null) {
                origin = "mod";
                modFolder = modEdit.modFolder;
                editedSource = modEdit.entry.source;
                isCallback = modEdit.entry.callback != null;
            } else if (hasPersonalEdit) {
                origin = "persistent";
                editedSource = editedSources.get(id);
                isCallback = editedCallbacks.exists(id);
            }
        }

        return {
            functionId: id,
            alias: info.alias,
            functionName: info.functionName,
            filePath: info.filePath,
            originalSource: originalSources.exists(id) ? originalSources.get(id) : info.originalExpression,
            editedSource: editedSource,
            hasEdit: origin != "none",
            active: origin != "none",
            temporary: origin == "temporary",
            origin: origin,
            modFolder: modFolder,
            isCallback: isCallback
        };
    }

    /**
     * Remove all temporary edits bound to a specific state reference.
     * Called automatically by MusicBeatState when a state exits, so temporary
     * edits are cleaned up eagerly instead of only expiring lazily on the
     * next intercepted call. Only edits bound to the exact same reference
     * (same instance, or same class) are removed - class-bound edits survive
     * instance swaps such as state resets.
     * @return The number of temporary edits removed
     */
    public function clearTemporaryEditsForState(state:Null<StateRef>):Int {
        if (state == null) return 0;
        var toRemove:Array<String> = [];
        for (id in editMetadata.keys()) {
            var meta = editMetadata.get(id);
            if (meta != null && meta.temporary == true && meta.tempState != null && meta.tempState.equals(state)) {
                toRemove.push(id);
            }
        }
        for (id in toRemove) {
            expireTemporaryEdit(id);
        }
        if (toRemove.length > 0) {
            trace('RuntimeFunctionRegistry: Cleared ${toRemove.length} temporary edits for exiting state');
        }
        return toRemove.length;
    }

    /**
     * Remove a temporary edit without touching disk (temporary edits are never
     * persisted, so no save is needed).
     */
    private function expireTemporaryEdit(functionId:String):Void {
        var meta = editMetadata.get(functionId);
        var name = meta != null ? meta.functionName : functionId;

        editedSources.remove(functionId);
        editedCallbacks.remove(functionId);
        originalSources.remove(functionId);
        editMetadata.remove(functionId);

        trace('RuntimeFunctionRegistry: Temporary edit for $name expired');
    }

    /**
     * Get the current state object that StateRef bindings are tested against.
     * Uses `stateProvider` when set, otherwise `flixel.FlxG.state`.
     */
    private function currentState():Dynamic {
        if (stateProvider != null) return stateProvider();
        #if flixel
        return flixel.FlxG.state;
        #else
        return null;
        #end
    }

    /**
     * Remove an edited function, reverting to original behaviour.
     *
     * @param functionId  The function's unique ID
     * @return true if a replacement was removed
     */
    public function removeEdit(idOrAlias:String):Bool {
        var functionId = resolveFunctionId(idOrAlias);
        if (!editedSources.exists(functionId) && !editedCallbacks.exists(functionId)) return false;

        var meta = editMetadata.get(functionId);
        var name = meta != null ? meta.functionName : functionId;
        var wasTemporary = meta != null && meta.temporary == true;

        editedSources.remove(functionId);
        editedCallbacks.remove(functionId);
        originalSources.remove(functionId);
        editMetadata.remove(functionId);

        trace('RuntimeFunctionRegistry: Removed edit for $name ($functionId)');

        // Temporary and callback edits were never persisted - no need to rewrite the save file
        if (!wasTemporary && (meta == null || meta.isCallback != true)) {
            saveToDisk();
        }
        return true;
    }

    /**
     * Check if a function has an active replacement registered.
     * Temporary edits bound to a state expire lazily here once that state is
     * no longer current.
     */
    public function hasReplacement(functionId:String):Bool {
        // Don't report any replacement until the background load has applied
        // persisted edits - otherwise we'd consult maps that aren't populated yet.
        if (!isReady()) return false;
        if (!editedSources.exists(functionId) && !editedCallbacks.exists(functionId)) return false;
        var meta = editMetadata.get(functionId);
        if (meta == null || !meta.active) return false;
        if (meta.temporary == true && meta.tempState != null && !meta.tempState.matches(currentState())) {
            expireTemporaryEdit(functionId);
            return false;
        }
        return true;
    }

    /**
     * Get the edited source code for a function (or null if not edited, or if
     * the edit is a function reference). Accepts a function ID or alias.
     */
    public function getEditedSource(idOrAlias:String):String {
        return editedSources.get(resolveFunctionId(idOrAlias));
    }

    /**
     * Get the edited function reference for a function (or null if not edited,
     * or if the edit is source-based). Accepts a function ID or alias.
     */
    public function getEditedCallback(idOrAlias:String):FunctionEditCallback {
        return editedCallbacks.get(resolveFunctionId(idOrAlias));
    }

    /**
     * Get the original source code for a function: the source stored when the
     * edit was registered, falling back to the compile-time original
     * expression. Accepts a function ID or a reflection-style alias.
     */
    public function getOriginalSource(idOrAlias:String):String {
        var functionId = resolveFunctionId(idOrAlias);
        var stored = originalSources.get(functionId);
        if (stored != null) return stored;
        return getOriginalExpression(functionId);
    }

    /**
     * Get metadata for an edit. Accepts a function ID or alias.
     */
    public function getEditMetadata(idOrAlias:String):EditMetadata {
        return editMetadata.get(resolveFunctionId(idOrAlias));
    }

    /**
     * Temporarily disable an edit without removing it.
     * Accepts a function ID or alias.
     */
    public function setActive(idOrAlias:String, active:Bool):Void {
        var meta = editMetadata.get(resolveFunctionId(idOrAlias));
        if (meta != null) {
            meta.active = active;
            saveToDisk();
        }
    }

    /**
     * Get all registered function IDs.
     */
    public function getAllEditIds():Array<String> {
        var ids:Array<String> = [for (id in editedSources.keys()) id];
        for (id in editedCallbacks.keys()) {
            if (ids.indexOf(id) == -1) ids.push(id);
        }
        return ids;
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
     * Clear all edits (persistent + temporary). Mod edits belong to their
     * mods and are left alone - use `clearModEdits(folder)` for those.
     */
    public function clearAll():Void {
        editedSources.clear();
        editedCallbacks.clear();
        originalSources.clear();
        editMetadata.clear();
        saveToDisk();
        trace("RuntimeFunctionRegistry: Cleared all edits");
    }

    // ===================== Mod Edit API =====================

    /**
     * Get the folders of all currently loaded mods, in priority order.
     * Index 0 is the "top" mod. Matches `Mods.loadTopMod` semantics (the
     * first enabled mod in modsList.txt is the top mod); the engine's
     * actively-loaded content mods (`Mods.currentModDirectory` /
     * `Mods.currentModDirectoryAlt`) are boosted to the front when set.
     */
    public function getLoadedModFolders():Array<String> {
        var result:Array<String> = [];
        #if MODS_ALLOWED
        try {
            var enabled = backend.Mods.parseList().enabled;
            if (enabled != null) {
                for (mod in enabled) {
                    if (mod != null && result.indexOf(mod) == -1) result.push(mod);
                }
            }
        } catch (e:Dynamic) {}

        try {
            for (mod in backend.Mods.getGlobalMods()) {
                if (mod != null && result.indexOf(mod) == -1) result.push(mod);
            }
        } catch (e:Dynamic) {}

        // The actively-loaded content mod(s) take top priority
        try {
            var current = backend.Mods.currentModDirectory;
            if (current != null && current.length > 0) {
                result.remove(current);
                result.insert(0, current);
            }
            var currentAlt = backend.Mods.currentModDirectoryAlt;
            if (currentAlt != null && currentAlt.length > 0) {
                result.remove(currentAlt);
                result.insert(0, currentAlt);
            }
        } catch (e:Dynamic) {}
        #end
        return result;
    }

    /**
     * Check whether a mod folder is currently loaded (enabled, global, or the
     * actively-loaded content mod).
     */
    public function isModLoaded(modFolder:String):Bool {
        return modFolder != null && getLoadedModFolders().indexOf(modFolder) != -1;
    }

    /**
     * Register a mod edit: a replacement that only applies while the given
     * mod is loaded. When several loaded mods edit the same function, the
     * top mod (see `getLoadedModFolders`) takes priority. Mod edits are
     * session-only and are never persisted to disk.
     *
     * @param modFolder  The owning mod's folder name (e.g. "myMod")
     * @param idOrAlias  Function ID or alias ("states.PlayState.create")
     * @param edit  HScript source String, or a function reference
     *              `(ctx:FunctionEditContext) -> Dynamic`
     * @return true if the edit was registered
     */
    public function registerModEdit(modFolder:String, idOrAlias:String, edit:Dynamic):Bool {
        if (modFolder == null || modFolder.length == 0 || edit == null) return false;

        var info = getEditableFunctionInfo(idOrAlias);
        if (info == null) {
            reportUnknownLookup(idOrAlias, 'register mod edit (from "$modFolder")');
            return false;
        }

        var entry:ModEditEntry = {
            source: null,
            callback: null,
            editTime: Date.now().toString(),
            active: true
        };

        if (Reflect.isFunction(edit)) {
            entry.callback = cast edit;
        } else if (Std.isOfType(edit, String)) {
            entry.source = cast edit;
        } else {
            trace('RuntimeFunctionRegistry: Unsupported mod edit value - expected an HScript source String or a function reference');
            return false;
        }

        var folderMap = modEdits.get(modFolder);
        if (folderMap == null) {
            folderMap = new Map();
            modEdits.set(modFolder, folderMap);
        }
        folderMap.set(info.functionId, entry);

        trace('RuntimeFunctionRegistry: Registered mod edit from "$modFolder" for ${info.functionName} (${info.functionId})');
        if (!isModLoaded(modFolder)) {
            trace('RuntimeFunctionRegistry: Note - mod "$modFolder" is not currently loaded; the edit will apply once it loads');
        }
        return true;
    }

    /**
     * Remove a mod's edit for a specific function.
     */
    public function unregisterModEdit(modFolder:String, idOrAlias:String):Bool {
        var folderMap = modEdits.get(modFolder);
        if (folderMap == null) return false;
        return folderMap.remove(resolveFunctionId(idOrAlias));
    }

    /**
     * Remove all edits owned by a mod (e.g. when the mod unloads).
     * @return The number of edits removed
     */
    public function clearModEdits(modFolder:String):Int {
        var folderMap = modEdits.get(modFolder);
        if (folderMap == null) return 0;
        var count = 0;
        for (_ in folderMap) count++;
        modEdits.remove(modFolder);
        if (count > 0) {
            trace('RuntimeFunctionRegistry: Cleared $count mod edits from "$modFolder"');
        }
        return count;
    }

    /**
     * Get the winning mod edit for a function: the edit from the
     * highest-priority loaded mod, or null if no loaded mod edits it.
     */
    public function getActiveModEdit(idOrAlias:String):{modFolder:String, entry:ModEditEntry} {
        var functionId = resolveFunctionId(idOrAlias);
        // Walk loaded mods in priority order - the top mod wins
        for (folder in getLoadedModFolders()) {
            var folderMap = modEdits.get(folder);
            if (folderMap == null) continue;
            var entry = folderMap.get(functionId);
            if (entry != null && entry.active) {
                return {modFolder: folder, entry: entry};
            }
        }
        return null;
    }

    /**
     * Check if any loaded mod has an active edit for a function.
     */
    public function hasModEdit(idOrAlias:String):Bool {
        return getActiveModEdit(idOrAlias) != null;
    }

    /**
     * Count registered mod edits (either for one mod, or all mods).
     */
    public function getModEditCount(?modFolder:String):Int {
        var count = 0;
        if (modFolder != null) {
            var folderMap = modEdits.get(modFolder);
            if (folderMap != null) for (_ in folderMap) count++;
        } else {
            for (folderMap in modEdits) for (_ in folderMap) count++;
        }
        return count;
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
        // While the registry is still loading in the background, do not
        // intercept at all - just run the original implementation.
        if (!isReady()) {
            return {intercepted: false, value: null};
        }

        // Priority order when several overrides exist for the same function:
        //   1. State-scoped temporary edits (most ephemeral)
        //   2. Mod edits (active only while the mod is loaded, top mod wins)
        //   3. Persistent edits (saved across sessions)
        var result = interceptTemporaryEdit(functionId, context, args);
        if (result != null) return result;

        result = interceptModEdit(functionId, context, args);
        if (result != null) return result;

        result = interceptPersistentEdit(functionId, context, args);
        if (result != null) return result;

        return {intercepted: false, value: null};
    }

    /**
     * Execute the state-scoped temporary edit for a function, if one is
     * active. Expires it lazily when the bound state is no longer current.
     */
    private function interceptTemporaryEdit(functionId:String, context:Dynamic, args:Array<Dynamic>):Null<InterceptResult> {
        var meta = editMetadata.get(functionId);
        if (meta == null || !meta.active || meta.temporary != true) return null;
        if (meta.tempState != null && !meta.tempState.matches(currentState())) {
            expireTemporaryEdit(functionId);
            return null;
        }
        return executeEditEntry(functionId, context, args, "temporary");
    }

    /**
     * Execute the persistent edit for a function, if one is active.
     */
    private function interceptPersistentEdit(functionId:String, context:Dynamic, args:Array<Dynamic>):Null<InterceptResult> {
        var meta = editMetadata.get(functionId);
        if (meta == null || !meta.active || meta.temporary == true) return null;
        if (!editedSources.exists(functionId) && !editedCallbacks.exists(functionId)) return null;
        return executeEditEntry(functionId, context, args, "persistent");
    }

    /**
     * Execute the winning mod edit for a function, if any loaded mod has one.
     */
    private function interceptModEdit(functionId:String, context:Dynamic, args:Array<Dynamic>):Null<InterceptResult> {
        var active = getActiveModEdit(functionId);
        if (active == null) return null;

        var entry = active.entry;
        if (entry.callback != null) {
            try {
                var value = entry.callback(makeEditContext(functionId, context, args));
                return {intercepted: true, value: value};
            } catch (e:Dynamic) {
                trace('RuntimeFunctionRegistry: Error executing mod callback edit from "${active.modFolder}" for $functionId: $e');
                trace('RuntimeFunctionRegistry: Falling back to original implementation');
                return null;
            }
        }

        if (entry.source != null) {
            #if HSCRIPT_ALLOWED
            try {
                var funcInfo = getEditableFunctionInfo(functionId);
                var isStatic = funcInfo != null ? funcInfo.isStatic : (context == null);
                var result = executeHScript(entry.source, context, args, isStatic, functionId);
                return {intercepted: true, value: result};
            } catch (e:Dynamic) {
                trace('RuntimeFunctionRegistry: Error executing mod edit from "${active.modFolder}" for $functionId: $e');
                trace('RuntimeFunctionRegistry: Falling back to original implementation');
                return null;
            }
            #else
            return null;
            #end
        }
        return null;
    }

    /**
     * Execute a registered personal (temporary or persistent) edit entry -
     * either its function reference or its HScript source.
     */
    private function executeEditEntry(functionId:String, context:Dynamic, args:Array<Dynamic>, origin:String):Null<InterceptResult> {
        var callback = editedCallbacks.get(functionId);
        if (callback != null) {
            try {
                var value = callback(makeEditContext(functionId, context, args));
                return {intercepted: true, value: value};
            } catch (e:Dynamic) {
                var meta = editMetadata.get(functionId);
                var name = meta != null ? meta.functionName : functionId;
                trace('RuntimeFunctionRegistry: Error executing $origin callback edit for $name: $e');
                trace('RuntimeFunctionRegistry: Falling back to original implementation');
                return null;
            }
        }

        var editedSource = editedSources.get(functionId);
        if (editedSource == null) return null;

        #if HSCRIPT_ALLOWED
        try {
            // Check if this is a static function from metadata
            var funcInfo = getEditableFunctionInfo(functionId);
            var isStatic = funcInfo != null ? funcInfo.isStatic : (context == null);

            var result = executeHScript(editedSource, context, args, isStatic, functionId);
            return {intercepted: true, value: result};
        } catch (e:Dynamic) {
            var meta = editMetadata.get(functionId);
            var name = meta != null ? meta.functionName : functionId;
            trace('RuntimeFunctionRegistry: Error executing $origin edited $name: $e');
            trace('RuntimeFunctionRegistry: Falling back to original implementation');
            return null;
        }
        #else
        // Without HScript we cannot execute edited code
        return null;
        #end
    }

    /**
     * Build the context passed to function-reference edits.
     */
    private function makeEditContext(functionId:String, context:Dynamic, args:Array<Dynamic>):FunctionEditContext {
        var funcInfo = getEditableFunctionInfo(functionId);
        return {
            functionId: functionId,
            alias: funcInfo != null ? funcInfo.alias : null,
            context: context,
            args: args != null ? args : [],
            isStatic: funcInfo != null ? funcInfo.isStatic : (context == null)
        };
    }

    /**
     * Execute an arbitrary HScript snippet in a sandboxed environment.
     * Useful for testing edited code from the editor UI.
     *
     * @param source  HScript source code
     * @param context  Optional `this` binding
     * @param args  Optional positional arguments (available as `arg0`, `arg1`, ...)
     * @param isStaticFunction  Whether this is a static function (affects variable access)
     * @param functionId  Optional function ID to get metadata and class variable info
     * @return The result of execution
     */
    public function executeHScript(source:String, context:Dynamic = null, args:Array<Dynamic> = null, isStaticFunction:Bool = false, functionId:String = null):Dynamic {
        #if HSCRIPT_ALLOWED
        // Reuse global interpreter with full variable reset
        var interp = globalInterpreter;

        // Clear all variables except standard APIs
        var standardKeys = ["Math", "Std", "Type", "Reflect", "StringTools", "Date", "trace", "TypeRegistry", "FunctionRegistry"];
        var keysToRemove:Array<String> = [];
        for (key in interp.variables.keys()) {
            if (standardKeys.indexOf(key) == -1) {
                keysToRemove.push(key);
            }
        }
        for (key in keysToRemove) {
            interp.variables.remove(key);
        }

        setupInterpreterEnvironment(interp, context, args, isStaticFunction, functionId);

        var expr = parser.parseString(source);
        return interp.execute(expr);
        #else
        trace("RuntimeFunctionRegistry: HScript not available");
        return null;
        #end
    }

    #if HSCRIPT_ALLOWED
    /**
     * Configure an HScript interpreter with standard bindings and context-specific access.
     * Handles both instance and static function contexts.
     *
     * @param interp  The interpreter to configure
     * @param context  The `this` object (null for static functions or if no context)
     * @param args  Function arguments available as `arg0`, `arg1`, etc.
     * @param isStaticFunction  Whether this is a static function (affects variable access)
     * @param functionId  Optional function ID to look up class metadata for variable access
     */
    private function setupInterpreterEnvironment(interp:Interp, context:Dynamic, args:Array<Dynamic>, isStaticFunction:Bool = false, functionId:String = null):Void {
        // Standard Haxe APIs (always available)
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

        // For instance methods: expose instance variables and "this"
        if (!isStaticFunction && context != null) {
            interp.variables.set("self", context);
            interp.variables.set("this", context);

            // Expose the context's instance fields
            try {
                var contextClass = Type.getClass(context);
                var fields = Type.getInstanceFields(contextClass);
                if (fields != null) {
                    for (field in fields) {
                        try {
                            var val = Reflect.getProperty(context, field);
                            interp.variables.set(field, val);
                        } catch (_:Dynamic) {}
                    }
                }

                // Also expose static fields of the class (accessible from instance methods)
                var statics = Type.getClassFields(contextClass);
                if (statics != null) {
                    for (staticField in statics) {
                        try {
                            var val = Reflect.getProperty(contextClass, staticField);
                            interp.variables.set(staticField, val);
                        } catch (_:Dynamic) {}
                    }
                }
            } catch (_:Dynamic) {}
        } else if (isStaticFunction && functionId != null) {
            // For static methods: only expose static variables of the defining class
            var funcInfo = getEditableFunctionInfo(functionId);
            if (funcInfo != null) {
                try {
                    // Resolve the class using the module path
                    var className = funcInfo.classPath;
                    var classType = Type.resolveClass(className);
                    if (classType != null) {
                        var statics = Type.getClassFields(classType);
                        if (statics != null) {
                            for (staticField in statics) {
                                try {
                                    var val = Reflect.getProperty(classType, staticField);
                                    interp.variables.set(staticField, val);
                                } catch (_:Dynamic) {}
                            }
                        }
                    }
                } catch (_:Dynamic) {}
            }
        }

        // Positional arguments (always available)
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
                // Temporary edits are session-only and must never be persisted
                if (meta != null && meta.temporary == true) continue;
                // Function references cannot be serialized
                if (editedCallbacks.exists(id)) continue;
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
     * Begin loading persisted modifications from disk. Returns immediately;
     * the heavy parse/apply happens on a background worker thread (tracked by
     * `getLoadProgress`). Interception is disabled until the load completes.
     */
    public function loadFromDisk():Void {
        startBackgroundLoad();
    }

    /**
     * Worker-side: read the persisted save file and return the raw edit list
     * (without touching the live maps). Progress counts are applied by the
     * background pipeline as each edit is applied.
     */
    private function readPersistedEdits():Array<Dynamic> {
        var result:Array<Dynamic> = [];
        try {
            var savePath = getSavePath();
            if (!sys.FileSystem.exists(savePath)) return result;

            var json = sys.io.File.getContent(savePath);
            var data = Json.parse(json);
            if (data.edits == null) return result;
            result = cast data.edits;
        } catch (e:Dynamic) {
            trace('RuntimeFunctionRegistry: Failed to read save file: $e');
        }
        return result;
    }

    /**
     * Apply a single persisted edit record to the live maps.
     */
    private function applyPersistedEdit(edit:Dynamic):Void {
        try {
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
        } catch (e:Dynamic) {
            trace('RuntimeFunctionRegistry: Failed to apply a persisted edit: $e');
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
 * Progress snapshot for the registry's background load, suitable for driving
 * a loading UI.
 */
typedef LoadProgress = {
    /** Human-readable description of the current load stage */
    stage:String,

    /** Number of items processed so far (persisted edits + editable functions) */
    processed:Int,

    /** Total number of items expected (grows as metadata count becomes known) */
    total:Int,

    /** Progress fraction, 0..1 (1 once ready) */
    percent:Float,

    /** True once the load has fully completed and interception is live */
    ready:Bool,

    /** True if the load failed */
    failed:Bool,

    /** True while the load is actively running */
    loading:Bool,

    /** Seconds the background load has been running */
    elapsedTime:Float
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
    active:Bool,

    /** Whether this edit is temporary (never persisted to disk) */
    ?temporary:Bool,

    /** State binding of a temporary edit - a specific state instance or a
     *  state class (null = untracked, lasts until manually cleared) */
    ?tempState:Null<StateRef>,

    /** Whether this edit is a function reference instead of HScript source */
    ?isCallback:Bool
}

/**
 * A function-reference edit. Receives the call context and returns the
 * replacement's return value. Any Haxe function works - including YScript
 * function references (`YScriptRuntime.getFunctionReference`) and Lua
 * callbacks bridged through `Lua_helper`.
 */
typedef FunctionEditCallback = FunctionEditContext->Dynamic;

/**
 * Context handed to a function-reference edit.
 */
typedef FunctionEditContext = {
    /** Canonical function ID (filePath:functionName:lineNumber) */
    functionId:String,

    /** Reflection-style alias ("states.PlayState.create"), if known */
    alias:String,

    /** The `this` object (null for static functions) */
    context:Dynamic,

    /** Positional call arguments */
    args:Array<Dynamic>,

    /** Whether the replaced function is static */
    isStatic:Bool
}

/**
 * A single mod-owned edit entry. Session-only, never persisted.
 */
typedef ModEditEntry = {
    /** HScript source replacement (null when a callback is used) */
    source:String,

    /** Function-reference replacement (null when source is used) */
    callback:FunctionEditCallback,

    /** When the edit was registered */
    editTime:String,

    /** Whether the edit is currently active */
    active:Bool
}

/**
 * Full details about a function and its current edit, for comparing the
 * original source against the edited source.
 */
typedef EditDetails = {
    /** Canonical function ID (filePath:functionName:lineNumber) */
    functionId:String,

    /** Reflection-style alias ("states.PlayState.create") */
    alias:String,

    /** Simple function name */
    functionName:String,

    /** Source file path */
    filePath:String,

    /** Original source (compile-time expression, or stored original) */
    originalSource:String,

    /** Current edited source (null if not edited) */
    editedSource:String,

    /** Whether an edit is currently registered */
    hasEdit:Bool,

    /** Whether the registered edit is active */
    active:Bool,

    /** Whether the registered edit is temporary */
    temporary:Bool,

    /** Which override currently wins: "temporary", "mod", "persistent", or "none" */
    origin:String,

    /** The owning mod folder when origin is "mod" (null otherwise) */
    modFolder:String,

    /** Whether the winning edit is a function reference instead of HScript source */
    isCallback:Bool
}

/**
 * Information about an editable function, loaded from compile-time resources.
 * Contains all needed metadata for the source editor.
 */
typedef EditableFunctionInfo = {
    /** Unique function ID (filePath:functionName:lineNumber) */
    functionId:String,

    /** Simple function name */
    functionName:String,

    /** Simple class name containing the function */
    className:String,

    /** Full class path (e.g. "mypackage.MyClass") */
    classPath:String,

    /** Reflection-style alias (e.g. "states.PlayState.create") */
    alias:String,

    /** Whether this is a static function */
    isStatic:Bool,

    /** Whether this function is public */
    isPublic:Bool,

    /** Return type as a string */
    returnType:String,

    /** Array of argument information */
    args:Array<{name:String, type:String, optional:Bool}>,

    /** File path where this function is defined */
    filePath:String,

    /** Line number where this function starts */
    lineNumber:Int,

    /** Original function expression as a string (before instrumentation) */
    originalExpression:String,

    /** Optional documentation */
    doc:String
}
