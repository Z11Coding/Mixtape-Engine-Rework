package yutautil.typeregistry;

import yutautil.typeregistry.AbstractRecognizer;
import yutautil.typeregistry.BuildDataLoader;
import yutautil.typeregistry.InGameSourceEditor;
import yutautil.typeregistry.RuntimeRegistry;
import yutautil.typeregistry.SourceMapper;
import yutautil.typeregistry.Typer;

/**
 * Main API for the Type Registry System
 * Provides easy access to all type checking, recognition, and source mapping features
 */
class TypeRegistryAPI {
    private static var _initialized:Bool = false;

    /**
     * Initialize the type registry system
     */
    public static function initialize():Void {
        if (_initialized) return;

        RuntimeRegistry.get().initialize();
        _initialized = true;

        trace("TypeRegistryAPI: System initialized successfully");
    }

    // === Type Checking API ===

    /**
     * Check if an object matches a specific type
     */
    public static function checkType(obj:Dynamic, typeName:String):Typed {
        initialize();
        return Typer.type(obj, typeName);
    }

    /**
     * Auto-detect possible types for an object
     */
    public static function detectTypes(obj:Dynamic):Array<Typed> {
        initialize();
        return Typer.autoType(obj);
    }

    /**
     * Get comprehensive inspection of any object
     */
    public static function inspect(obj:Dynamic) {
        initialize();
        return Typer.inspect(obj);
    }

    /**
     * Enhanced 'is' function supporting both Class/Enum and string-based type checking
     */
    public static function is(obj:Dynamic, type:TypeIdentifier):Bool {
        initialize();
        return Typer.is(obj, type);
    }

    /**
     * Enhanced 'is' function with confidence score
     */
    public static function isWithConfidence(obj:Dynamic, type:TypeIdentifier):{result:Bool, confidence:Float} {
        initialize();
        return Typer.isWithConfidence(obj, type);
    }

    /**
     * Get all possible types for an object
     */
    public static function getAllPossibleTypes(obj:Dynamic):Array<{name:String, confidence:Float, source:String}> {
        initialize();
        return Typer.getAllPossibleTypes(obj);
    }

    /**
     * Find the most specific type for an object
     */
    public static function getMostSpecificType(obj:Dynamic):String {
        initialize();
        return Typer.getMostSpecificType(obj);
    }

    // === Abstract Recognition API ===

    /**
     * Find possible abstract types for a value
     */
    public static function findAbstracts(value:Dynamic):Array<AbstractCandidate> {
        initialize();
        return AbstractRecognizer.recognize(value);
    }

    /**
     * Get the best abstract type match for a value
     */
    public static function getBestAbstract(value:Dynamic):AbstractCandidate {
        initialize();
        return AbstractRecognizer.getBestMatch(value);
    }

    /**
     * Try to cast a value to an abstract type
     */
    public static function castToAbstract(value:Dynamic, abstractTypeName:String):Dynamic {
        initialize();
        return AbstractRecognizer.attemptCast(value, abstractTypeName);
    }

    // === Source Mapping API ===

    /**
     * Get source code for a type
     */
    public static function getSource(typeName:String):TypeSourceInfo {
        initialize();
        return SourceMapper.getTypeSource(typeName);
    }

    /**
     * Find where a type is defined
     */
    public static function findDefinition(typeName:String):TypeLocation {
        initialize();
        return SourceMapper.findTypeDefinition(typeName);
    }

    /**
     * Get comprehensive debug information for a type
     */
    public static function getDebugInfo(typeName:String):TypeDebugInfo {
        initialize();
        return SourceMapper.getDebugInfo(typeName);
    }

    /**
     * Create a debug object with full traceability
     */
    public static function createDebugObject(typeName:String, properties:Dynamic):DebugObject {
        initialize();
        return SourceMapper.createDebugObject(typeName, properties);
    }

    /**
     * Analyze source code of a type
     */
    public static function analyzeSource(typeName:String):SourceAnalysis {
        initialize();
        return SourceMapper.analyzeSource(typeName);
    }

    // === Registry Query API ===

    /**
     * Get all registered types
     */
    public static function getAllTypes():Array<String> {
        initialize();
        return RuntimeRegistry.get().getAllTypes();
    }

    /**
     * Get all registered abstracts
     * Uses build-time data when available, falls back to runtime discovery
     */
    public static function getAllAbstracts():Array<String> {
        initialize();

        // Try build data first
        try {
            if (BuildDataLoader.initialize()) {
                var buildAbstracts = BuildDataLoader.getAllAbstracts();
                if (buildAbstracts.length > 0) {
                    trace('TypeRegistryAPI: Using build data for abstracts (${buildAbstracts.length} found)');
                    return buildAbstracts;
                }
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Build data unavailable for abstracts, using runtime: $e');
        }

        // Fallback to runtime registry
        return RuntimeRegistry.get().getAllAbstracts();
    }

    /**
     * Get all registered classes
     * Uses build-time data when available, falls back to runtime discovery
     */
    public static function getAllClasses():Array<String> {
        initialize();

        // Try build data first
        try {
            if (BuildDataLoader.initialize()) {
                var buildClasses = BuildDataLoader.getAllClasses();
                if (buildClasses.length > 0) {
                    trace('TypeRegistryAPI: Using build data for classes (${buildClasses.length} found)');
                    return buildClasses;
                }
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Build data unavailable, using runtime: $e');
        }

        // Fallback to runtime registry
        return RuntimeRegistry.get().getAllClasses();
    }

    /**
     * Get all registered typedefs
     * Uses build-time data when available, falls back to runtime discovery
     */
    public static function getAllTypedefs():Array<String> {
        initialize();

        // Try build data first
        try {
            if (BuildDataLoader.initialize()) {
                var buildTypedefs = BuildDataLoader.getAllTypedefs();
                if (buildTypedefs.length > 0) {
                    trace('TypeRegistryAPI: Using build data for typedefs (${buildTypedefs.length} found)');
                    return buildTypedefs;
                }
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Build data unavailable for typedefs, using runtime: $e');
        }

        // Fallback to runtime registry
        return RuntimeRegistry.get().getAllTypedefs();
    }

    /**
     * Check if a type exists in the registry
     */
    public static function hasType(typeName:String):Bool {
        initialize();
        return RuntimeRegistry.get().hasType(typeName);
    }

    /**
     * Get detailed information about a specific type
     * Uses build-time data when available for enhanced information
     */
    public static function getTypeInfo(typeName:String):TypeInfo {
        initialize();

        // Try build data first for detailed info
        try {
            if (BuildDataLoader.initialize()) {
                var buildInfo = BuildDataLoader.getTypeInfo(typeName);
                if (buildInfo != null) {
                    return {
                        name: buildInfo.data.name,
                        pack: buildInfo.data.pack,
                        fields: buildInfo.data.fields != null ? buildInfo.data.fields : [],
                        confidence: 1.0
                    };
                }
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Error getting build type info: $e');
        }

        // Fallback to runtime info
        return RuntimeRegistry.get().getTypeInfo(typeName);
    }

    // === Utility Methods ===

    /**
     * Print comprehensive type system statistics
     */
    public static function printStats():Void {
        initialize();

        var registry = RuntimeRegistry.get();
        var totalTypes = registry.getAllTypes().length;
        var totalAbstracts = registry.getAllAbstracts().length;
        var totalClasses = registry.getAllClasses().length;
        var totalTypedefs = registry.getAllTypedefs().length;

        trace("=== Type Registry Statistics ===");
        trace('Total Types: $totalTypes');
        trace('  - Abstracts: $totalAbstracts');
        trace('  - Classes: $totalClasses');
        trace('  - Typedefs: $totalTypedefs');
        trace('  - Other: ${totalTypes - totalAbstracts - totalClasses - totalTypedefs}');
        trace("==============================");
    }

    /**
     * Search for types by name pattern
     */
    public static function searchTypes(pattern:String):Array<String> {
        initialize();

        var allTypes = RuntimeRegistry.get().getAllTypes();
        var results = [];
        var lowerPattern = pattern.toLowerCase();

        for (typeName in allTypes) {
            if (typeName.toLowerCase().indexOf(lowerPattern) >= 0) {
                results.push(typeName);
            }
        }

        return results;
    }

    /**
     * Create a runtime type checking function for a specific type
     */
    public static function createChecker(typeName:String):Dynamic->Bool {
        initialize();

        return function(obj:Dynamic):Bool {
            var typed = checkType(obj, typeName);
            return typed.isValid();
        };
    }

    /**
     * Create a runtime casting function for a specific type
     */
    public static function createCaster<T>(typeName:String, targetClass:Class<T>):Dynamic->T {
        initialize();

        return function(obj:Dynamic):T {
            return Typer.createTyped(obj, typeName, targetClass);
        };
    }

    // === In-Game Source Editor API ===

    /**
     * Get the in-game source editor instance
     */
    public static function getSourceEditor():InGameSourceEditor {
        initialize();
        return InGameSourceEditor.get();
    }

    /**
     * Edit a function's source code
     */
    public static function editFunction(functionName:String, newSource:String, filePath:String = null):Bool {
        initialize();
        return InGameSourceEditor.get().editFunction(functionName, newSource, filePath);
    }

    /**
     * Revert a function to its original source
     */
    public static function revertFunction(functionName:String, filePath:String = null):Bool {
        initialize();
        return InGameSourceEditor.get().revertFunction(functionName, filePath);
    }

    /**
     * Get all editable files
     */
    public static function getEditableFiles():Array<EditorFile> {
        initialize();
        return InGameSourceEditor.get().getEditableFiles();
    }

    /**
     * Get all modified files
     */
    public static function getModifiedFiles():Array<EditorFile> {
        initialize();
        return InGameSourceEditor.get().getModifiedFiles();
    }

    /**
     * Search for functions by name pattern
     */
    public static function searchFunctions(pattern:String):Array<{func:FunctionInfo, file:EditorFile}> {
        initialize();
        return InGameSourceEditor.get().searchFunctions(pattern);
    }

    /**
     * Get function source code (modified or original)
     */
    public static function getFunctionSource(functionName:String, filePath:String = null):String {
        initialize();
        return InGameSourceEditor.get().getFunctionSource(functionName, filePath);
    }

    /**
     * Check if a function can be edited
     */
    public static function isFunctionEditable(functionName:String, filePath:String = null):Bool {
        initialize();
        return InGameSourceEditor.get().isFunctionEditable(functionName, filePath);
    }

    /**
     * Export all function modifications as JSON
     */
    public static function exportModifications():String {
        initialize();
        return InGameSourceEditor.get().exportModifications();
    }

    /**
     * Import function modifications from JSON
     */
    public static function importModifications(jsonData:String):Bool {
        initialize();
        return InGameSourceEditor.get().importModifications(jsonData);
    }

    /**
     * Get function dependencies (what it calls)
     */
    public static function getFunctionDependencies(functionName:String, filePath:String = null):Array<String> {
        initialize();
        return InGameSourceEditor.get().getFunctionDependencies(functionName, filePath);
    }

    /**
     * Get function usage (what calls it)
     */
    public static function getFunctionUsage(functionName:String):Array<{func:FunctionInfo, file:EditorFile}> {
        initialize();
        return InGameSourceEditor.get().getFunctionUsage(functionName);
    }

    /**
     * Get comprehensive editor statistics
     */
    public static function getEditorStatistics() {
        initialize();
        return InGameSourceEditor.get().getEditorStatistics();
    }

    /**
     * Print editor status
     */
    public static function printEditorStatus():Void {
        initialize();
        InGameSourceEditor.get().printStatus();
    }

    // === Build Data API ===

    /**
     * Get all functions from build data
     */
    public static function getAllFunctions():Array<Dynamic> {
        try {
            if (BuildDataLoader.initialize()) {
                return BuildDataLoader.getAllFunctions();
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Error getting build functions: $e');
        }
        return [];
    }

    /**
     * Get functions by class name
     */
    public static function getFunctionsByClass(className:String):Array<Dynamic> {
        try {
            if (BuildDataLoader.initialize()) {
                return BuildDataLoader.getFunctionsByClass(className);
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Error getting functions by class: $e');
        }
        return [];
    }

    /**
     * Search functions by name pattern
     */
    public static function searchFunctions(pattern:String):Array<Dynamic> {
        try {
            if (BuildDataLoader.initialize()) {
                return BuildDataLoader.searchFunctions(pattern);
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Error searching functions: $e');
        }
        return [];
    }

    /**
     * Get functions with specific metadata
     */
    public static function getFunctionsWithMetadata(metadata:String):Array<Dynamic> {
        try {
            if (BuildDataLoader.initialize()) {
                return BuildDataLoader.getFunctionsWithMetadata(metadata);
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Error getting functions with metadata: $e');
        }
        return [];
    }

    /**
     * Get build statistics if available
     */
    public static function getBuildStats():Dynamic {
        try {
            if (BuildDataLoader.initialize()) {
                return BuildDataLoader.getBuildStats();
            }
        } catch (e:Dynamic) {
            trace('TypeRegistryAPI: Error getting build stats: $e');
        }
        return null;
    }

    /**
     * Check if build-time data is available
     */
    public static function hasBuildData():Bool {
        return BuildDataLoader.initialize();
    }

    /**
     * Print comprehensive system statistics including build data
     */
    public static function printComprehensiveStats():Void {
        initialize();

        var registry = RuntimeRegistry.get();
        var runtimeTypes = registry.getAllTypes().length;
        var runtimeAbstracts = registry.getAllAbstracts().length;
        var runtimeClasses = registry.getAllClasses().length;
        var runtimeTypedefs = registry.getAllTypedefs().length;

        trace("=== Comprehensive Type Registry Statistics ===");

        // Build data stats
        var buildStats = getBuildStats();
        if (buildStats != null) {
            trace("Build Data Available:");
            trace('  Build Timestamp: ${Date.fromTime(buildStats.timestamp)}');
            trace('  Target Platform: ${buildStats.platform}');
            trace('  Classes: ${buildStats.classCount}');
            trace('  Abstracts: ${buildStats.abstractCount}');
            trace('  Functions: ${buildStats.functionCount}');
            trace('  Source Files: ${buildStats.sourceFileCount}');
            trace("");
        } else {
            trace("Build Data: Not Available");
            trace("");
        }

        // Runtime stats
        trace("Runtime Discovery:");
        trace('  Total Types: $runtimeTypes');
        trace('  - Abstracts: $runtimeAbstracts');
        trace('  - Classes: $runtimeClasses');
        trace('  - Typedefs: $runtimeTypedefs');
        trace('  - Other: ${runtimeTypes - runtimeAbstracts - runtimeClasses - runtimeTypedefs}');
        trace("============================================");
    }

    // === Enhanced Testing ===

    /**
     * Test the system with sample values
     */
    public static function runSystemTest():Void {
        initialize();

        trace("=== Type Registry System Test ===");

        // Test basic type checking
        var intValue = 42;
        var stringValue = "hello";
        var boolValue = true;

        trace("Testing basic values:");
        trace('  Int 42: ${inspect(intValue)}');
        trace('  String "hello": ${inspect(stringValue)}');
        trace('  Bool true: ${inspect(boolValue)}');

        // Test enhanced 'is' function
        trace("\nTesting enhanced 'is' function:");
        trace('  is(42, "Int"): ${is(42, "Int")}');
        trace('  is("hello", String): ${is("hello", String)}');
        trace('  is(42, "String"): ${is(42, "String")}');

        // Test with confidence
        var confidence = isWithConfidence(42, "Float");
        trace('  is(42, "Float") with confidence: ${confidence.result} (${confidence.confidence * 100}%)');

        // Test abstract recognition
        if (getAllAbstracts().length > 0) {
            trace("\nTesting abstract recognition:");
            var abstractCandidates = findAbstracts(intValue);
            for (candidate in abstractCandidates.slice(0, 3)) { // Show top 3
                trace('  Candidate: ${candidate.toString()}');
            }
        }

        // Test source mapping
        var sampleType = getAllTypes()[0];
        if (sampleType != null) {
            trace('\nTesting source mapping for: $sampleType');
            var sourceInfo = getSource(sampleType);
            if (sourceInfo != null) {
                trace('  File: ${sourceInfo.filePath}');
                trace('  Lines: ${sourceInfo.sourceLines.length}');
            }
        }

        // Test in-game editor
        trace("\nTesting in-game source editor:");
        var editableFiles = getEditableFiles();
        trace('  Editable files: ${editableFiles.length}');

        if (editableFiles.length > 0) {
            var firstFile = editableFiles[0];
            trace('  Sample file: ${firstFile.getFileName()}');
            trace('  Editable functions: ${firstFile.getEditableFunctions().length}');
        }

        trace("=== System Test Complete ===");
    }

    /**
     * Run comprehensive test of all systems
     */
    public static function runCompleteSystemTest():Void {
        trace("=== Complete Type Registry System Test ===");

        // Run basic system test
        runSystemTest();

        // Run editor system test
        trace("\n=== Editor System Test ===");
        InGameSourceEditor.get().runSystemTest();

        // Print comprehensive statistics
        trace("\n=== System Statistics ===");
        printStats();
        printEditorStatus();

        trace("=== Complete System Test Finished ===");
    }
}
