package yutautil.typeregistry;

import haxe.CallStack;
import haxe.Json;
import haxe.io.Path;
import sys.io.File;
#if macro
import haxe.macro.Position;
#end

/**
 * Runtime source code access and manipulation system
 * Provides comprehensive access to source code, position mapping, and debugging capabilities
 * Enhanced with function-level tracking and in-game editing support
 */
class SourceMapper {
    private static var registry:RuntimeRegistry;
    private static var sourceCache:Map<String, String> = new Map();
    private static var sourceFiles:Map<String, SourceFile> = new Map();
    private static var modifiedFunctions:Map<String, ModifiedFunction> = new Map();

    static function __init__() {
        registry = RuntimeRegistry.get();
    }

    /**
     * Get source code for a specific type
     */
    public static function getTypeSource(typeName:String):TypeSourceInfo {
        registry.initialize();

        var sourceInfo = registry.getSourceInfo(typeName);
        if (sourceInfo == null) {
            return null;
        }

        var fullSource = getFileSource(sourceInfo.file);
        if (fullSource == null) {
            return null;
        }

        var lines = fullSource.split('\n');
        var sourceLines = extractSourceLines(lines, sourceInfo.min, sourceInfo.max);

        return new TypeSourceInfo(
            typeName,
            sourceInfo.file,
            sourceInfo.min,
            sourceInfo.max,
            sourceLines,
            fullSource
        );
    }

    /**
     * Get source code for a file with caching
     */
    public static function getFileSource(filePath:String):String {
        if (sourceCache.exists(filePath)) {
            return sourceCache.get(filePath);
        }

        try {
            if (sys.FileSystem.exists(filePath)) {
                var content = File.getContent(filePath);
                sourceCache.set(filePath, content);
                return content;
            }
        } catch (e:Dynamic) {
            trace('SourceMapper: Could not read file ${filePath}: ${e}');
        }

        return null;
    }

    /**
     * Extract specific lines from source content based on character positions
     */
    private static function extractSourceLines(lines:Array<String>, minPos:Int, maxPos:Int):Array<String> {
        // This is a simplified version - in practice, we'd need to map character positions to line numbers
        // For now, we'll return the full source
        return lines;
    }

    /**
     * Find the source location of a type definition
     */
    public static function findTypeDefinition(typeName:String):TypeLocation {
        var sourceInfo = getTypeSource(typeName);
        if (sourceInfo == null) return null;

        // Parse the source to find the exact definition location
        var definition = findDefinitionInSource(sourceInfo.sourceLines, typeName);

        return new TypeLocation(
            sourceInfo.filePath,
            definition.line,
            definition.column,
            definition.length
        );
    }

    private static function findDefinitionInSource(lines:Array<String>, typeName:String):{line:Int, column:Int, length:Int} {
        var shortName = typeName.split(".").pop();

        for (i in 0...lines.length) {
            var line = lines[i];

            // Look for class/abstract/typedef definitions
            var patterns = [
                'class\\s+$shortName',
                'abstract\\s+$shortName',
                'typedef\\s+$shortName',
                'enum\\s+$shortName'
            ];

            for (pattern in patterns) {
                var regex = new EReg(pattern, "g");
                if (regex.match(line)) {
                    var pos = regex.matchedPos();
                    return {
                        line: i + 1, // 1-based line numbers
                        column: pos.pos,
                        length: pos.len
                    };
                }
            }
        }

        return {line: 1, column: 0, length: 0};
    }

    /**
     * Get comprehensive debugging information for a type
     */
    public static function getDebugInfo(typeName:String):TypeDebugInfo {
        registry.initialize();

        var typeInfo = registry.getTypeInfo(typeName);
        var sourceInfo = getTypeSource(typeName);
        var location = findTypeDefinition(typeName);

        // Get call stack to understand context
        var callStack = CallStack.callStack();

        return new TypeDebugInfo(
            typeName,
            typeInfo,
            sourceInfo,
            location,
            callStack,
            Date.now()
        );
    }

    /**
     * Create a runtime object with full debug information
     */
    public static function createDebugObject(typeName:String, properties:Dynamic):DebugObject {
        var debugInfo = getDebugInfo(typeName);
        return new DebugObject(properties, debugInfo);
    }

    /**
     * Analyze source code patterns to extract additional metadata
     */
    public static function analyzeSource(typeName:String):SourceAnalysis {
        var sourceInfo = getTypeSource(typeName);
        if (sourceInfo == null) return null;

        var analysis = new SourceAnalysis(typeName);

        // Analyze imports
        analysis.imports = extractImports(sourceInfo.sourceLines);

        // Analyze comments and documentation
        analysis.documentation = extractDocumentation(sourceInfo.sourceLines);

        // Analyze dependencies
        analysis.dependencies = extractDependencies(sourceInfo.sourceLines);

        // Analyze complexity metrics
        analysis.complexity = calculateComplexity(sourceInfo.sourceLines);

        return analysis;
    }

    private static function extractImports(lines:Array<String>):Array<String> {
        var imports = [];
        var importRegex = ~/^import\s+([^;]+);/;

        for (line in lines) {
            if (importRegex.match(line.trim())) {
                imports.push(importRegex.matched(1));
            }
        }

        return imports;
    }

    private static function extractDocumentation(lines:Array<String>):Array<String> {
        var docs = [];
        var inDocBlock = false;

        for (line in lines) {
            var trimmed = line.trim();

            if (trimmed.startsWith("/**")) {
                inDocBlock = true;
                docs.push(trimmed);
            } else if (inDocBlock) {
                docs.push(trimmed);
                if (trimmed.endsWith("*/")) {
                    inDocBlock = false;
                }
            } else if (trimmed.startsWith("//")) {
                docs.push(trimmed);
            }
        }

        return docs;
    }

    private static function extractDependencies(lines:Array<String>):Array<String> {
        var deps = [];

        // Look for type references in the source
        for (line in lines) {
            // This is a simplified dependency extraction
            // In practice, you'd want more sophisticated parsing
            if (line.indexOf(":") >= 0) {
                // Look for type annotations
                var typeAnnotationRegex = ~/:\s*([A-Za-z][A-Za-z0-9_\.]*)/g;
                while (typeAnnotationRegex.match(line)) {
                    var typeName = typeAnnotationRegex.matched(1);
                    if (deps.indexOf(typeName) == -1) {
                        deps.push(typeName);
                    }
                    line = typeAnnotationRegex.matchedRight();
                }
            }
        }

        return deps;
    }

    private static function calculateComplexity(lines:Array<String>):ComplexityMetrics {
        var metrics = new ComplexityMetrics();

        for (line in lines) {
            var trimmed = line.trim();

            // Count lines of code (non-empty, non-comment lines)
            if (trimmed.length > 0 && !trimmed.startsWith("//") && !trimmed.startsWith("/*") && !trimmed.startsWith("*")) {
                metrics.linesOfCode++;
            }

            // Count control flow statements
            if (trimmed.indexOf("if") >= 0) metrics.conditionals++;
            if (trimmed.indexOf("for") >= 0 || trimmed.indexOf("while") >= 0) metrics.loops++;
            if (trimmed.indexOf("function") >= 0 || trimmed.indexOf("->") >= 0) metrics.functions++;
        }

        metrics.cyclomaticComplexity = metrics.conditionals + metrics.loops + 1;

        return metrics;
    }

    /**
     * Parse a source file into a SourceFile structure with function tracking
     */
    public static function parseSourceFile(filePath:String):SourceFile {
        if (sourceFiles.exists(filePath)) {
            return sourceFiles.get(filePath);
        }

        var source = getFileSource(filePath);
        if (source == null) return null;

        var sourceFile = new SourceFile(filePath, source);

        // Parse the source to extract functions, imports, and metadata
        parseFileStructure(sourceFile);

        sourceFiles.set(filePath, sourceFile);
        return sourceFile;
    }

    /**
     * Parse the structure of a source file
     */
    private static function parseFileStructure(sourceFile:SourceFile):Void {
        var lines = sourceFile.originalSource.split('\n');

        // Extract imports
        sourceFile.imports = extractImportsDetailed(lines);

        // Extract package declaration
        sourceFile.packageName = extractPackage(lines);

        // Extract functions with their full context
        sourceFile.functions = extractFunctions(lines, sourceFile.filePath);

        // Extract class/abstract/typedef declarations
        sourceFile.typeDeclarations = extractTypeDeclarations(lines);

        // Extract using statements and other dependencies
        sourceFile.usingStatements = extractUsingStatements(lines);
    }

    /**
     * Extract detailed import information
     */
    private static function extractImportsDetailed(lines:Array<String>):Array<ImportInfo> {
        var imports = [];
        var importRegex = ~/^import\s+([^;]+);/;

        for (i in 0...lines.length) {
            var line = lines[i].trim();
            if (importRegex.match(line)) {
                var importPath = importRegex.matched(1);
                var alias = null;

                // Check for 'as' alias
                var asRegex = ~/(.+)\s+as\s+(\w+)$/;
                if (asRegex.match(importPath)) {
                    importPath = asRegex.matched(1);
                    alias = asRegex.matched(2);
                }

                imports.push(new ImportInfo(importPath, alias, i + 1));
            }
        }

        return imports;
    }

    /**
     * Extract package declaration
     */
    private static function extractPackage(lines:Array<String>):String {
        var packageRegex = ~/^package\s+([^;]+);/;

        for (line in lines) {
            var trimmed = line.trim();
            if (packageRegex.match(trimmed)) {
                return packageRegex.matched(1);
            }
        }

        return "";
    }

    /**
     * Extract functions with full context and metadata
     */
    private static function extractFunctions(lines:Array<String>, filePath:String):Array<FunctionInfo> {
        var functions = [];
        var inFunction = false;
        var functionStart = 0;
        var braceCount = 0;
        var currentFunction:FunctionInfo = null;

        for (i in 0...lines.length) {
            var line = lines[i];
            var trimmed = line.trim();

            // Skip comments and empty lines when looking for function start
            if (trimmed.startsWith("//") || trimmed.startsWith("/*") || trimmed.length == 0) {
                continue;
            }

            // Look for function declarations
            if (!inFunction && isFunctionDeclaration(trimmed)) {
                currentFunction = parseFunctionDeclaration(trimmed, filePath, i + 1);
                if (currentFunction != null) {
                    inFunction = true;
                    functionStart = i;
                    braceCount = 0;

                    // Extract metadata from previous lines (comments, annotations)
                    extractFunctionMetadata(currentFunction, lines, i);
                }
            }

            if (inFunction) {
                // Count braces to determine function end
                for (j in 0...line.length) {
                    var char = line.charAt(j);
                    if (char == "{") braceCount++;
                    else if (char == "}") braceCount--;
                }

                // Function ended
                if (braceCount < 0) {
                    currentFunction.endLine = i + 1;
                    currentFunction.sourceCode = extractFunctionSource(lines, functionStart, i);
                    functions.push(currentFunction);

                    inFunction = false;
                    currentFunction = null;
                }
            }
        }

        return functions;
    }

    /**
     * Check if a line contains a function declaration
     */
    private static function isFunctionDeclaration(line:String):Bool {
        // Match various function declaration patterns
        var patterns = [
            ~/\bfunction\s+\w+/,  // function name
            ~/\w+\s*\([^)]*\)\s*:/,  // property function
            ~/\w+\s*\([^)]*\)\s*\{/,  // direct function
            ~/override\s+function/,   // override function
            ~/static\s+function/,     // static function
            ~/public\s+function/,     // public function
            ~/private\s+function/     // private function
        ];

        for (pattern in patterns) {
            if (pattern.match(line)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Parse function declaration details
     */
    private static function parseFunctionDeclaration(line:String, filePath:String, lineNumber:Int):FunctionInfo {
        var functionRegex = ~/(?:(public|private|static|override|inline)\s+)*function\s+(\w+)\s*\(([^)]*)\)(?:\s*:\s*([^{]+))?/;

        if (functionRegex.match(line)) {
            var modifiers = functionRegex.matched(1);
            var name = functionRegex.matched(2);
            var params = functionRegex.matched(3);
            var returnType = functionRegex.matched(4);

            var functionInfo = new FunctionInfo(name, filePath);
            functionInfo.startLine = lineNumber;
            functionInfo.modifiers = modifiers != null ? modifiers.split(" ").filter(s -> s.length > 0) : [];
            functionInfo.parameters = parseParameters(params);
            functionInfo.returnType = returnType != null ? returnType.trim() : "Void";

            return functionInfo;
        }

        return null;
    }

    /**
     * Parse function parameters
     */
    private static function parseParameters(paramString:String):Array<ParameterInfo> {
        var params = [];
        if (paramString == null || paramString.trim().length == 0) {
            return params;
        }

        var paramParts = paramString.split(",");
        for (part in paramParts) {
            var trimmed = part.trim();
            if (trimmed.length == 0) continue;

            var optional = trimmed.startsWith("?");
            if (optional) trimmed = trimmed.substring(1);

            var colonIndex = trimmed.indexOf(":");
            var name = colonIndex >= 0 ? trimmed.substring(0, colonIndex).trim() : trimmed;
            var type = colonIndex >= 0 ? trimmed.substring(colonIndex + 1).trim() : "Dynamic";

            // Check for default value
            var defaultValue = null;
            var equalsIndex = type.indexOf("=");
            if (equalsIndex >= 0) {
                defaultValue = type.substring(equalsIndex + 1).trim();
                type = type.substring(0, equalsIndex).trim();
            }

            params.push(new ParameterInfo(name, type, optional, defaultValue));
        }

        return params;
    }

    /**
     * Extract function metadata (comments, annotations)
     */
    private static function extractFunctionMetadata(functionInfo:FunctionInfo, lines:Array<String>, functionLineIndex:Int):Void {
        var metadata = [];
        var documentation = [];

        // Look backwards for metadata and documentation
        var i = functionLineIndex - 1;
        while (i >= 0) {
            var line = lines[i].trim();

            if (line.length == 0) {
                i--;
                continue;
            }

            // Check for metadata annotations
            if (line.startsWith("@")) {
                metadata.unshift(line);

                // Check for hardcoded metadata
                if (line.toLowerCase().indexOf("hardcoded") >= 0) {
                    functionInfo.isHardcoded = true;
                }
            }
            // Check for documentation comments
            else if (line.startsWith("/**") || line.startsWith("*") || line.endsWith("*/")) {
                documentation.unshift(line);
            }
            // Check for single-line comments
            else if (line.startsWith("//")) {
                documentation.unshift(line);
            }
            else {
                // Hit non-comment/non-metadata line, stop looking
                break;
            }

            i--;
        }

        functionInfo.metadata = metadata;
        functionInfo.documentation = documentation;
    }

    /**
     * Extract function source code
     */
    private static function extractFunctionSource(lines:Array<String>, startLine:Int, endLine:Int):String {
        var functionLines = [];
        for (i in startLine...endLine + 1) {
            if (i < lines.length) {
                functionLines.push(lines[i]);
            }
        }
        return functionLines.join('\n');
    }

    /**
     * Extract type declarations
     */
    private static function extractTypeDeclarations(lines:Array<String>):Array<TypeDeclarationInfo> {
        var declarations = [];

        for (i in 0...lines.length) {
            var line = lines[i].trim();

            var patterns = [
                {regex: ~/^(class|abstract|typedef|enum|interface)\s+(\w+)/, type: "type"},
            ];

            for (pattern in patterns) {
                if (pattern.regex.match(line)) {
                    var declType = pattern.regex.matched(1);
                    var name = pattern.regex.matched(2);

                    declarations.push(new TypeDeclarationInfo(name, declType, i + 1));
                    break;
                }
            }
        }

        return declarations;
    }

    /**
     * Extract using statements
     */
    private static function extractUsingStatements(lines:Array<String>):Array<String> {
        var usingStatements = [];
        var usingRegex = ~/^using\s+([^;]+);/;

        for (line in lines) {
            var trimmed = line.trim();
            if (usingRegex.match(trimmed)) {
                usingStatements.push(usingRegex.matched(1));
            }
        }

        return usingStatements;
    }

    /**
     * Get all source files in the registry
     */
    public static function getAllSourceFiles():Array<SourceFile> {
        return [for (file in sourceFiles) file];
    }

    /**
     * Get a specific function from any source file
     */
    public static function getFunction(functionName:String, className:String = null):FunctionInfo {
        for (sourceFile in sourceFiles) {
            for (func in sourceFile.functions) {
                if (func.name == functionName) {
                    if (className == null || sourceFile.containsClass(className)) {
                        return func;
                    }
                }
            }
        }

        return null;
    }

    /**
     * Clear the source cache
     */
    public static function clearCache():Void {
        sourceCache.clear();
        sourceFiles.clear();
        modifiedFunctions.clear();
    }
}

/**
 * Complete source information for a type
 */
class TypeSourceInfo {
    public var typeName(default, null):String;
    public var filePath(default, null):String;
    public var minPos(default, null):Int;
    public var maxPos(default, null):Int;
    public var sourceLines(default, null):Array<String>;
    public var fullSource(default, null):String;

    public function new(typeName:String, filePath:String, minPos:Int, maxPos:Int, sourceLines:Array<String>, fullSource:String) {
        this.typeName = typeName;
        this.filePath = filePath;
        this.minPos = minPos;
        this.maxPos = maxPos;
        this.sourceLines = sourceLines;
        this.fullSource = fullSource;
    }

    public function getSourceSnippet(contextLines:Int = 5):String {
        // Return source with context lines around the definition
        return sourceLines.join('\n');
    }
}

/**
 * Type location information
 */
class TypeLocation {
    public var filePath(default, null):String;
    public var line(default, null):Int;
    public var column(default, null):Int;
    public var length(default, null):Int;

    public function new(filePath:String, line:Int, column:Int, length:Int) {
        this.filePath = filePath;
        this.line = line;
        this.column = column;
        this.length = length;
    }

    public function toString():String {
        return '${filePath}:${line}:${column}';
    }
}

/**
 * Comprehensive debug information for a type
 */
class TypeDebugInfo {
    public var typeName(default, null):String;
    public var typeInfo(default, null):TypeInfo;
    public var sourceInfo(default, null):TypeSourceInfo;
    public var location(default, null):TypeLocation;
    public var callStack(default, null):Array<StackItem>;
    public var timestamp(default, null):Date;

    public function new(typeName:String, typeInfo:TypeInfo, sourceInfo:TypeSourceInfo, location:TypeLocation, callStack:Array<StackItem>, timestamp:Date) {
        this.typeName = typeName;
        this.typeInfo = typeInfo;
        this.sourceInfo = sourceInfo;
        this.location = location;
        this.callStack = callStack;
        this.timestamp = timestamp;
    }
}

/**
 * Runtime debug object with full source traceability
 */
class DebugObject {
    public var properties(default, null):Dynamic;
    public var debugInfo(default, null):TypeDebugInfo;
    public var creationTime(default, null):Date;

    public function new(properties:Dynamic, debugInfo:TypeDebugInfo) {
        this.properties = properties;
        this.debugInfo = debugInfo;
        this.creationTime = Date.now();
    }

    public function getProperty(name:String):Dynamic {
        return Reflect.field(properties, name);
    }

    public function setProperty(name:String, value:Dynamic):Void {
        Reflect.setField(properties, name, value);
    }

    public function getSourceLocation():String {
        return debugInfo.location != null ? debugInfo.location.toString() : "unknown";
    }
}

/**
 * Source code analysis results
 */
class SourceAnalysis {
    public var typeName(default, null):String;
    public var imports(default, null):Array<String>;
    public var documentation(default, null):Array<String>;
    public var dependencies(default, null):Array<String>;
    public var complexity(default, null):ComplexityMetrics;

    public function new(typeName:String) {
        this.typeName = typeName;
        this.imports = [];
        this.documentation = [];
        this.dependencies = [];
    }
}

/**
 * Code complexity metrics
 */
class ComplexityMetrics {
    public var linesOfCode:Int = 0;
    public var conditionals:Int = 0;
    public var loops:Int = 0;
    public var functions:Int = 0;
    public var cyclomaticComplexity:Int = 0;

    public function new() {}

    public function toString():String {
        return 'LOC: $linesOfCode, Cyclomatic: $cyclomaticComplexity, Functions: $functions';
    }
}

/**
 * Complete source file structure with function-level tracking
 */
class SourceFile {
    public var filePath(default, null):String;
    public var originalSource(default, null):String;
    public var packageName(default, null):String;
    public var imports(default, null):Array<ImportInfo>;
    public var usingStatements(default, null):Array<String>;
    public var functions(default, null):Array<FunctionInfo>;
    public var typeDeclarations(default, null):Array<TypeDeclarationInfo>;
    public var lastModified(default, null):Date;

    public function new(filePath:String, source:String) {
        this.filePath = filePath;
        this.originalSource = source;
        this.lastModified = Date.now();
        this.imports = [];
        this.usingStatements = [];
        this.functions = [];
        this.typeDeclarations = [];
    }

    public function containsClass(className:String):Bool {
        for (decl in typeDeclarations) {
            if (decl.name == className && (decl.type == "class" || decl.type == "abstract")) {
                return true;
            }
        }
        return false;
    }

    public function getFunctionByName(name:String):FunctionInfo {
        for (func in functions) {
            if (func.name == name) {
                return func;
            }
        }
        return null;
    }

    public function getEditableFunctions():Array<FunctionInfo> {
        return functions.filter(func -> !func.isHardcoded);
    }

    public function getViewOnlyFunctions():Array<FunctionInfo> {
        return functions.filter(func -> func.isHardcoded);
    }
}

/**
 * Detailed import information
 */
class ImportInfo {
    public var path(default, null):String;
    public var alias(default, null):String;
    public var line(default, null):Int;

    public function new(path:String, alias:String, line:Int) {
        this.path = path;
        this.alias = alias;
        this.line = line;
    }

    public function toString():String {
        return alias != null ? '$path as $alias' : path;
    }
}

/**
 * Function information with modification tracking
 */
class FunctionInfo {
    public var name(default, null):String;
    public var filePath(default, null):String;
    public var startLine(default, null):Int;
    public var endLine(default, null):Int;
    public var sourceCode(default, null):String;
    public var modifiers(default, null):Array<String>;
    public var parameters(default, null):Array<ParameterInfo>;
    public var returnType(default, null):String;
    public var metadata(default, null):Array<String>;
    public var documentation(default, null):Array<String>;
    public var isHardcoded(default, null):Bool;
    public var isModified(default, null):Bool;
    public var modifiedSource(default, null):String;
    public var modificationTime(default, null):Date;

    public function new(name:String, filePath:String) {
        this.name = name;
        this.filePath = filePath;
        this.modifiers = [];
        this.parameters = [];
        this.returnType = "Void";
        this.metadata = [];
        this.documentation = [];
        this.isHardcoded = false;
        this.isModified = false;
    }

    public function getEffectiveSource():String {
        return isModified ? modifiedSource : sourceCode;
    }

    public function isEditable():Bool {
        return !isHardcoded;
    }

    public function getSignature():String {
        var paramStr = parameters.map(p -> p.toString()).join(", ");
        var modStr = modifiers.length > 0 ? modifiers.join(" ") + " " : "";
        return '${modStr}function $name($paramStr):$returnType';
    }

    public function getUniqueId():String {
        return '$filePath:$name:$startLine';
    }
}

/**
 * Function parameter information
 */
class ParameterInfo {
    public var name(default, null):String;
    public var type(default, null):String;
    public var optional(default, null):Bool;
    public var defaultValue(default, null):String;

    public function new(name:String, type:String, optional:Bool = false, defaultValue:String = null) {
        this.name = name;
        this.type = type;
        this.optional = optional;
        this.defaultValue = defaultValue;
    }

    public function toString():String {
        var result = optional ? "?" : "";
        result += name + ":" + type;
        if (defaultValue != null) {
            result += " = " + defaultValue;
        }
        return result;
    }
}

/**
 * Type declaration information
 */
class TypeDeclarationInfo {
    public var name(default, null):String;
    public var type(default, null):String; // class, abstract, typedef, enum, interface
    public var line(default, null):Int;

    public function new(name:String, type:String, line:Int) {
        this.name = name;
        this.type = type;
        this.line = line;
    }
}

/**
 * Modified function tracking
 */
class ModifiedFunction {
    public var functionInfo(default, null):FunctionInfo;
    public var originalSource(default, null):String;
    public var modifiedSource(default, null):String;
    public var modificationTime(default, null):Date;
    public var isActive(default, null):Bool;

    public function new(functionInfo:FunctionInfo, modifiedSource:String) {
        this.functionInfo = functionInfo;
        this.originalSource = functionInfo.sourceCode;
        this.modifiedSource = modifiedSource;
        this.modificationTime = Date.now();
        this.isActive = true;
    }

    public function revert():Void {
        functionInfo.isModified = false;
        functionInfo.modifiedSource = null;
        isActive = false;
    }

    public function apply():Void {
        functionInfo.isModified = true;
        functionInfo.modifiedSource = modifiedSource;
        functionInfo.modificationTime = modificationTime;
        isActive = true;
    }
}
