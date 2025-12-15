package yutautil.typeregistry;

import yutautil.typeregistry.EditorFileOrganizer;
import yutautil.typeregistry.SourceEditor;
import yutautil.typeregistry.SourceMapper;

/**
 * Complete in-game source code editor interface
 * Provides a comprehensive API for editing, managing, and organizing source code at runtime
 */
class InGameSourceEditor {
    private static var _instance:InGameSourceEditor;
    private var sourceEditor:SourceEditor;
    private var fileOrganizer:EditorFileOrganizer;

    public static function get():InGameSourceEditor {
        if (_instance == null) {
            _instance = new InGameSourceEditor();
        }
        return _instance;
    }

    private function new() {
        sourceEditor = SourceEditor.get();
        fileOrganizer = EditorFileOrganizer.get();
    }

    // === File Management API ===

    /**
     * Get the complete file tree for the editor UI
     */
    public function getFileTree():FileTreeNode {
        return fileOrganizer.getFileTree();
    }

    /**
     * Get all files organized by folders
     */
    public function getFolderStructure():Array<FolderInfo> {
        return fileOrganizer.getFolderStructure();
    }

    /**
     * Get all editable files
     */
    public function getEditableFiles():Array<EditorFile> {
        return fileOrganizer.getEditableFiles();
    }

    /**
     * Get all files with modifications
     */
    public function getModifiedFiles():Array<EditorFile> {
        return fileOrganizer.getModifiedFiles();
    }

    /**
     * Find files by name pattern
     */
    public function searchFiles(pattern:String):Array<EditorFile> {
        return fileOrganizer.findFilesByName(pattern);
    }

    /**
     * Get a specific file
     */
    public function getFile(filePath:String):EditorFile {
        return fileOrganizer.findFile(filePath);
    }

    // === Function Management API ===

    /**
     * Get all functions in a file
     */
    public function getFileFunctions(filePath:String):Array<FunctionInfo> {
        var file = getFile(filePath);
        return file != null ? file.getAllFunctions() : [];
    }

    /**
     * Get editable functions in a file
     */
    public function getEditableFunctions(filePath:String):Array<FunctionInfo> {
        var file = getFile(filePath);
        return file != null ? file.getEditableFunctions() : [];
    }

    /**
     * Get a specific function
     */
    public function getFunction(functionName:String, filePath:String = null):FunctionInfo {
        if (filePath != null) {
            var file = getFile(filePath);
            return file != null ? file.sourceFile.getFunctionByName(functionName) : null;
        } else {
            return SourceMapper.getFunction(functionName);
        }
    }

    /**
     * Check if a function can be edited
     */
    public function isFunctionEditable(functionName:String, filePath:String = null):Bool {
        var func = getFunction(functionName, filePath);
        return func != null && func.isEditable();
    }

    /**
     * Check if a function is modified
     */
    public function isFunctionModified(functionName:String, filePath:String = null):Bool {
        var func = getFunction(functionName, filePath);
        return func != null && func.isModified;
    }

    // === Editing API ===

    /**
     * Edit a function's source code
     */
    public function editFunction(functionName:String, newSource:String, filePath:String = null):Bool {
        var func = getFunction(functionName, filePath);
        if (func == null) {
            trace('InGameSourceEditor: Function not found: $functionName');
            return false;
        }

        if (!func.isEditable()) {
            trace('InGameSourceEditor: Function is hardcoded and cannot be edited: $functionName');
            return false;
        }

        var success = sourceEditor.modifyFunction(func.getUniqueId(), newSource);
        if (success) {
            fileOrganizer.refresh(); // Refresh to update modification status
        }

        return success;
    }

    /**
     * Revert a function to its original source
     */
    public function revertFunction(functionName:String, filePath:String = null):Bool {
        var func = getFunction(functionName, filePath);
        if (func == null) {
            return false;
        }

        var success = sourceEditor.revertFunction(func.getUniqueId());
        if (success) {
            fileOrganizer.refresh();
        }

        return success;
    }

    /**
     * Get the current source code for a function (modified or original)
     */
    public function getFunctionSource(functionName:String, filePath:String = null):String {
        var func = getFunction(functionName, filePath);
        return func != null ? func.getEffectiveSource() : null;
    }

    /**
     * Get the original source code for a function
     */
    public function getOriginalFunctionSource(functionName:String, filePath:String = null):String {
        var func = getFunction(functionName, filePath);
        return func != null ? func.sourceCode : null;
    }

    /**
     * Validate function source code before editing
     */
    public function validateFunctionSource(functionName:String, source:String, filePath:String = null):Bool {
        var func = getFunction(functionName, filePath);
        if (func == null) return false;

        // Basic validation - check function name matches
        var functionRegex = new EReg('function\\s+${func.name}\\s*\\(', "g");
        return functionRegex.match(source);
    }

    // === Modification Management ===

    /**
     * Get all modified functions
     */
    public function getAllModifications():Array<ModifiedFunction> {
        return sourceEditor.getModifiedFunctions();
    }

    /**
     * Export all modifications as JSON
     */
    public function exportModifications():String {
        return sourceEditor.exportModifications();
    }

    /**
     * Import modifications from JSON
     */
    public function importModifications(jsonData:String):Bool {
        var success = sourceEditor.importModifications(jsonData);
        if (success) {
            fileOrganizer.refresh();
        }
        return success;
    }

    /**
     * Clear all modifications
     */
    public function clearAllModifications():Void {
        sourceEditor.clearAllModifications();
        fileOrganizer.refresh();
    }

    /**
     * Save modifications to a file
     */
    public function saveModifications(filePath:String):Bool {
        try {
            var json = exportModifications();
            sys.io.File.saveContent(filePath, json);
            return true;
        } catch (e:Dynamic) {
            trace('InGameSourceEditor: Failed to save modifications: $e');
            return false;
        }
    }

    /**
     * Load modifications from a file
     */
    public function loadModifications(filePath:String):Bool {
        try {
            var json = sys.io.File.getContent(filePath);
            return importModifications(json);
        } catch (e:Dynamic) {
            trace('InGameSourceEditor: Failed to load modifications: $e');
            return false;
        }
    }

    // === Search and Navigation ===

    /**
     * Search for functions by name pattern
     */
    public function searchFunctions(pattern:String):Array<{func:FunctionInfo, file:EditorFile}> {
        var results = [];
        var lowerPattern = pattern.toLowerCase();

        for (file in fileOrganizer.getAllFiles()) {
            for (func in file.getAllFunctions()) {
                if (func.name.toLowerCase().indexOf(lowerPattern) >= 0) {
                    results.push({func: func, file: file});
                }
            }
        }

        return results;
    }

    /**
     * Search in function source code
     */
    public function searchInSource(pattern:String):Array<{func:FunctionInfo, file:EditorFile, matches:Array<Int>}> {
        var results = [];
        var regex = new EReg(pattern, "gi");

        for (file in fileOrganizer.getAllFiles()) {
            for (func in file.getAllFunctions()) {
                var source = func.getEffectiveSource();
                var matches = [];

                var pos = 0;
                while (regex.match(source.substring(pos))) {
                    var matchPos = regex.matchedPos();
                    matches.push(pos + matchPos.pos);
                    pos += matchPos.pos + matchPos.len;
                }

                if (matches.length > 0) {
                    results.push({func: func, file: file, matches: matches});
                }
            }
        }

        return results;
    }

    /**
     * Get function dependencies (what it calls)
     */
    public function getFunctionDependencies(functionName:String, filePath:String = null):Array<String> {
        var func = getFunction(functionName, filePath);
        if (func == null) return [];

        var dependencies = [];
        var source = func.getEffectiveSource();

        // Simple regex-based dependency extraction
        var callRegex = ~/(\w+)\s*\(/g;
        while (callRegex.match(source)) {
            var funcCall = callRegex.matched(1);
            if (dependencies.indexOf(funcCall) == -1 && funcCall != func.name) {
                dependencies.push(funcCall);
            }
            source = callRegex.matchedRight();
        }

        return dependencies;
    }

    /**
     * Get function usage (what calls it)
     */
    public function getFunctionUsage(functionName:String):Array<{func:FunctionInfo, file:EditorFile}> {
        var results = [];
        var callRegex = new EReg('\\b$functionName\\s*\\(', "g");

        for (file in fileOrganizer.getAllFiles()) {
            for (func in file.getAllFunctions()) {
                if (func.name != functionName && callRegex.match(func.getEffectiveSource())) {
                    results.push({func: func, file: file});
                }
            }
        }

        return results;
    }

    // === Statistics and Information ===

    /**
     * Get comprehensive editor statistics
     */
    public function getEditorStatistics() {
        var fileStats = fileOrganizer.getStatistics();
        var modStats = sourceEditor.getModificationStats();

        return {
            files: fileStats,
            modifications: modStats,
            timestamp: Date.now()
        };
    }

    /**
     * Get file information
     */
    public function getFileInfo(filePath:String) {
        var file = getFile(filePath);
        return file != null ? file.getFileInfo() : null;
    }

    /**
     * Get function information
     */
    public function getFunctionInfo(functionName:String, filePath:String = null) {
        var func = getFunction(functionName, filePath);
        if (func == null) return null;

        return {
            name: func.name,
            signature: func.getSignature(),
            filePath: func.filePath,
            startLine: func.startLine,
            endLine: func.endLine,
            isEditable: func.isEditable(),
            isModified: func.isModified,
            modifiers: func.modifiers,
            parameters: [for (p in func.parameters) p.toString()],
            returnType: func.returnType,
            documentation: func.documentation,
            metadata: func.metadata,
            dependencies: getFunctionDependencies(functionName, filePath),
            usage: getFunctionUsage(functionName).length
        };
    }

    // === Utility Methods ===

    /**
     * Refresh all data (call after external changes)
     */
    public function refresh():Void {
        fileOrganizer.refresh();
    }

    /**
     * Print editor status
     */
    public function printStatus():Void {
        var stats = getEditorStatistics();

        trace("=== In-Game Source Editor Status ===");
        trace('Files: ${stats.files.totalFiles} total, ${stats.files.editableFiles} editable, ${stats.files.modifiedFiles} modified');
        trace('Functions: ${stats.files.totalFunctions} total, ${stats.files.editableFunctions} editable, ${stats.files.modifiedFunctions} modified');
        trace('Modifications: ${stats.modifications.active} active, ${stats.modifications.reverted} reverted');
        trace("===================================");
    }

    /**
     * Run a comprehensive test of the editor system
     */
    public function runSystemTest():Void {
        trace("=== In-Game Source Editor System Test ===");

        // Test file organization
        var files = getEditableFiles();
        trace('Found ${files.length} editable files');

        if (files.length > 0) {
            var testFile = files[0];
            trace('Test file: ${testFile.getFileName()}');

            var editableFuncs = testFile.getEditableFunctions();
            trace('Editable functions: ${editableFuncs.length}');

            if (editableFuncs.length > 0) {
                var testFunc = editableFuncs[0];
                trace('Test function: ${testFunc.name}');

                // Test search
                var searchResults = searchFunctions(testFunc.name);
                trace('Search results for "${testFunc.name}": ${searchResults.length}');

                // Test dependencies
                var deps = getFunctionDependencies(testFunc.name, testFile.sourceFile.filePath);
                trace('Dependencies: ${deps.join(", ")}');

                // Test usage
                var usage = getFunctionUsage(testFunc.name);
                trace('Usage count: ${usage.length}');
            }
        }

        // Test statistics
        printStatus();

        trace("=== System Test Complete ===");
    }
}
