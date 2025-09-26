package yutautil;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

/**
 * ClassListMacro - A build macro that creates a comprehensive list of all classes in the project
 *
 * This macro provides:
 * - Automatic class discovery and cataloging
 * - Runtime access to all class information
 * - Metadata injection for tracking
 * - Utility functions for class inspection
 */
class ClassListMacro {
    #if macro

    // Static storage for discovered classes
    public static var allClasses:Array<ClassInfo> = [];
    public static var classMap:Map<String, ClassInfo> = new Map();

    // Track if we've already run the discovery
    private static var discoveryComplete:Bool = false;

    /**
     * Information about a discovered class
     */
    public typedef ClassInfo = {
        var name:String;
        var fullName:String;
        var module:String;
        var pack:Array<String>;
        var isInterface:Bool;
        var isAbstract:Bool;
        var isEnum:Bool;
        var superClass:Null<String>;
        var interfaces:Array<String>;
        var fields:Array<String>;
        var staticFields:Array<String>;
        var constructors:Array<String>;
        var meta:Array<String>;
        var doc:Null<String>;
        var pos:String;
    }

    /**
     * Main build macro - call this from build.hxml or compiler args
     */
    public static function build():Void {
        trace("ClassListMacro: Starting class discovery...");

        // Hook into the compilation process
        Context.onAfterTyping(discoverAllClasses);
        Context.onGenerate(finalizeClassList);

        // Add global metadata to track classes
        addGlobalTrackingMetadata();

        trace("ClassListMacro: Build hooks installed");
    }

    /**
     * Discover all classes in the compilation
     */
    public static function discoverAllClasses(types:Array<Type>):Void {
        if (discoveryComplete) return;

        trace("ClassListMacro: Discovering classes from " + types.length + " types...");

        allClasses = [];
        classMap = new Map();

        for (type in types) {
            processType(type);
        }

        // Also discover classes from Context.getModule() for each known module
        var modules = Context.getResources();
        for (moduleName in modules.keys()) {
            try {
                var moduleTypes = Context.getModule(moduleName);
                for (moduleType in moduleTypes) {
                    processType(moduleType);
                }
            } catch (e:Dynamic) {
                // Ignore modules that can't be loaded
            }
        }

        discoveryComplete = true;
        trace("ClassListMacro: Discovered " + allClasses.length + " classes total");
    }

    /**
     * Process a single type and extract class information
     */
    private static function processType(type:Type):Void {
        switch (type) {
            case TInst(t, params):
                var classType = t.get();
                if (!classMap.exists(classType.name)) {
                    var classInfo = extractClassInfo(classType, false, false, false);
                    allClasses.push(classInfo);
                    classMap.set(classType.name, classInfo);
                }

            case TEnum(t, params):
                var enumType = t.get();
                if (!classMap.exists(enumType.name)) {
                    var classInfo = extractEnumInfo(enumType);
                    allClasses.push(classInfo);
                    classMap.set(enumType.name, classInfo);
                }

            case TAbstract(t, params):
                var abstractType = t.get();
                if (!classMap.exists(abstractType.name)) {
                    var classInfo = extractAbstractInfo(abstractType);
                    allClasses.push(classInfo);
                    classMap.set(abstractType.name, classInfo);
                }

            case TType(t, params):
                var typedefType = t.get();
                if (!classMap.exists(typedefType.name)) {
                    var classInfo = extractTypedefInfo(typedefType);
                    allClasses.push(classInfo);
                    classMap.set(typedefType.name, classInfo);
                }

            default:
                // Ignore other types
        }
    }

    /**
     * Extract information from a class type
     */
    private static function extractClassInfo(classType:ClassType, isInterface:Bool, isAbstract:Bool, isEnum:Bool):ClassInfo {
        var fields:Array<String> = [];
        var staticFields:Array<String> = [];
        var constructors:Array<String> = [];

        // Extract instance fields
        for (field in classType.fields.get()) {
            switch (field.kind) {
                case FMethod(k):
                    if (field.name == "new") {
                        constructors.push(field.name + getMethodSignature(field));
                    } else {
                        fields.push(field.name + getMethodSignature(field));
                    }
                case FVar(read, write):
                    fields.push(field.name + ":" + getFieldType(field));
            }
        }

        // Extract static fields
        for (field in classType.statics.get()) {
            switch (field.kind) {
                case FMethod(k):
                    staticFields.push(field.name + getMethodSignature(field));
                case FVar(read, write):
                    staticFields.push(field.name + ":" + getFieldType(field));
            }
        }

        // Extract interfaces
        var interfaces:Array<String> = [];
        for (iface in classType.interfaces) {
            interfaces.push(iface.t.toString());
        }

        // Extract metadata
        var meta:Array<String> = [];
        for (m in classType.meta.get()) {
            meta.push("@" + m.name);
        }

        var superClass:Null<String> = null;
        if (classType.superClass != null) {
            superClass = classType.superClass.t.toString();
        }

        return {
            name: classType.name,
            fullName: classType.module + "." + classType.name,
            module: classType.module,
            pack: classType.pack,
            isInterface: classType.isInterface,
            isAbstract: isAbstract,
            isEnum: isEnum,
            superClass: superClass,
            interfaces: interfaces,
            fields: fields,
            staticFields: staticFields,
            constructors: constructors,
            meta: meta,
            doc: classType.doc,
            pos: Context.getPosInfos(classType.pos).fileName + ":" + Context.getPosInfos(classType.pos).min
        };
    }

    /**
     * Extract information from an enum type
     */
    private static function extractEnumInfo(enumType:EnumType):ClassInfo {
        var fields:Array<String> = [];

        // Extract enum constructors
        for (name in enumType.constructs.keys()) {
            var construct = enumType.constructs.get(name);
            switch (construct.type) {
                case TFun(args, ret):
                    var argStr = args.map(arg -> arg.name + ":" + arg.t.toString()).join(", ");
                    fields.push(name + "(" + argStr + ")");
                default:
                    fields.push(name);
            }
        }

        var meta:Array<String> = [];
        for (m in enumType.meta.get()) {
            meta.push("@" + m.name);
        }

        return {
            name: enumType.name,
            fullName: enumType.module + "." + enumType.name,
            module: enumType.module,
            pack: enumType.pack,
            isInterface: false,
            isAbstract: false,
            isEnum: true,
            superClass: null,
            interfaces: [],
            fields: fields,
            staticFields: [],
            constructors: [],
            meta: meta,
            doc: enumType.doc,
            pos: Context.getPosInfos(enumType.pos).fileName + ":" + Context.getPosInfos(enumType.pos).min
        };
    }

    /**
     * Extract information from an abstract type
     */
    private static function extractAbstractInfo(abstractType:AbstractType):ClassInfo {
        var fields:Array<String> = [];
        var staticFields:Array<String> = [];

        // Extract array access operations
        if (abstractType.array.length > 0) {
            fields.push("@:arrayAccess methods: " + abstractType.array.length);
        }

        // Extract from/to conversions
        var fromTypes:Array<String> = [];
        var toTypes:Array<String> = [];

        for (fromType in abstractType.from) {
            fromTypes.push("@:from " + fromType.t.toString());
        }

        for (toType in abstractType.to) {
            toTypes.push("@:to " + toType.t.toString());
        }

        fields = fields.concat(fromTypes).concat(toTypes);

        var meta:Array<String> = [];
        for (m in abstractType.meta.get()) {
            meta.push("@" + m.name);
        }

        return {
            name: abstractType.name,
            fullName: abstractType.module + "." + abstractType.name,
            module: abstractType.module,
            pack: abstractType.pack,
            isInterface: false,
            isAbstract: true,
            isEnum: false,
            superClass: null,
            interfaces: [],
            fields: fields,
            staticFields: staticFields,
            constructors: [],
            meta: meta,
            doc: abstractType.doc,
            pos: Context.getPosInfos(abstractType.pos).fileName + ":" + Context.getPosInfos(abstractType.pos).min
        };
    }

    /**
     * Extract information from a typedef
     */
    private static function extractTypedefInfo(typedefType:DefType):ClassInfo {
        var meta:Array<String> = [];
        for (m in typedefType.meta.get()) {
            meta.push("@" + m.name);
        }

        var typeStr = typedefType.type.toString();

        return {
            name: typedefType.name,
            fullName: typedefType.module + "." + typedefType.name,
            module: typedefType.module,
            pack: typedefType.pack,
            isInterface: false,
            isAbstract: false,
            isEnum: false,
            superClass: null,
            interfaces: [],
            fields: ["typedef: " + typeStr],
            staticFields: [],
            constructors: [],
            meta: meta,
            doc: typedefType.doc,
            pos: Context.getPosInfos(typedefType.pos).fileName + ":" + Context.getPosInfos(typedefType.pos).min
        };
    }

    /**
     * Get method signature string
     */
    private static function getMethodSignature(field:ClassField):String {
        return switch (field.type) {
            case TFun(args, ret):
                var argStr = args.map(arg -> arg.name + ":" + arg.t.toString()).join(", ");
                "(" + argStr + "):" + ret.toString();
            default:
                ":" + field.type.toString();
        }
    }

    /**
     * Get field type string
     */
    private static function getFieldType(field:ClassField):String {
        return field.type.toString();
    }

    /**
     * Finalize the class list and generate the runtime accessor
     */
    public static function finalizeClassList(types:Array<Type>):Void {
        trace("ClassListMacro: Finalizing class list with " + allClasses.length + " classes");

        // Generate runtime class list accessor
        generateClassListAccessor();

        // Generate summary
        generateClassSummary();
    }

    /**
     * Generate the runtime class list accessor
     */
    private static function generateClassListAccessor():Void {
        var classListCode = "package yutautil;\n\n";
        classListCode += "/**\n";
        classListCode += " * Auto-generated class list - DO NOT EDIT MANUALLY\n";
        classListCode += " * Generated by ClassListMacro at compile time\n";
        classListCode += " */\n";
        classListCode += "class GeneratedClassList {\n";
        classListCode += "\tpublic static var allClasses:Array<Dynamic> = [\n";

        for (i in 0...allClasses.length) {
            var cls = allClasses[i];
            classListCode += "\t\t{\n";
            classListCode += '\t\t\tname: "${cls.name}",\n';
            classListCode += '\t\t\tfullName: "${cls.fullName}",\n';
            classListCode += '\t\t\tmodule: "${cls.module}",\n';
            classListCode += '\t\t\tpack: ${haxe.Json.stringify(cls.pack)},\n';
            classListCode += '\t\t\tisInterface: ${cls.isInterface},\n';
            classListCode += '\t\t\tisAbstract: ${cls.isAbstract},\n';
            classListCode += '\t\t\tisEnum: ${cls.isEnum},\n';
            classListCode += '\t\t\tsuperClass: ${cls.superClass != null ? '"${cls.superClass}"' : 'null'},\n';
            classListCode += '\t\t\tinterfaces: ${haxe.Json.stringify(cls.interfaces)},\n';
            classListCode += '\t\t\tfields: ${haxe.Json.stringify(cls.fields)},\n';
            classListCode += '\t\t\tstaticFields: ${haxe.Json.stringify(cls.staticFields)},\n';
            classListCode += '\t\t\tconstructors: ${haxe.Json.stringify(cls.constructors)},\n';
            classListCode += '\t\t\tmeta: ${haxe.Json.stringify(cls.meta)},\n';
            classListCode += '\t\t\tdoc: ${cls.doc != null ? '"${StringTools.replace(cls.doc, '"', '\\"')}"' : 'null'},\n';
            classListCode += '\t\t\tpos: "${cls.pos}"\n';
            classListCode += "\t\t}" + (i < allClasses.length - 1 ? "," : "") + "\n";
        }

        classListCode += "\t];\n\n";

        // Add utility functions
        classListCode += "\tpublic static function getAllClasses():Array<Dynamic> {\n";
        classListCode += "\t\treturn allClasses;\n";
        classListCode += "\t}\n\n";

        classListCode += "\tpublic static function traceAllClasses():Void {\n";
        classListCode += '\t\ttrace("=== ALL CLASSES (${allClasses.length} total) ===");\n';
        classListCode += "\t\tfor (i in 0...allClasses.length) {\n";
        classListCode += "\t\t\tvar cls = allClasses[i];\n";
        classListCode += '\t\t\ttrace(\'[${i + 1}/${allClasses.length}] ${cls.fullName}\');\n';
        classListCode += '\t\t\ttrace(\'  Type: ${cls.isInterface ? "Interface" : cls.isAbstract ? "Abstract" : cls.isEnum ? "Enum" : "Class"}\');\n';
        classListCode += "\t\t\tif (cls.superClass != null) trace('  Extends: ${cls.superClass}');\n";
        classListCode += "\t\t\tif (cls.interfaces.length > 0) trace('  Implements: ${cls.interfaces.join(\", \")}');\n";
        classListCode += "\t\t\ttrace('  Fields: ${cls.fields.length}, Static Fields: ${cls.staticFields.length}');\n";
        classListCode += "\t\t\tif (cls.constructors.length > 0) trace('  Constructors: ${cls.constructors.join(\", \")}');\n";
        classListCode += "\t\t\tif (cls.meta.length > 0) trace('  Metadata: ${cls.meta.join(\", \")}');\n";
        classListCode += "\t\t\ttrace('  Location: ${cls.pos}');\n";
        classListCode += '\t\t\ttrace("");\n';
        classListCode += "\t\t}\n";
        classListCode += "\t}\n\n";

        classListCode += "\tpublic static function findClass(name:String):Dynamic {\n";
        classListCode += "\t\tfor (cls in allClasses) {\n";
        classListCode += "\t\t\tif (cls.name == name || cls.fullName == name) {\n";
        classListCode += "\t\t\t\treturn cls;\n";
        classListCode += "\t\t\t}\n";
        classListCode += "\t\t}\n";
        classListCode += "\t\treturn null;\n";
        classListCode += "\t}\n\n";

        classListCode += "\tpublic static function getClassesByPackage(packageName:String):Array<Dynamic> {\n";
        classListCode += "\t\tvar result:Array<Dynamic> = [];\n";
        classListCode += "\t\tfor (cls in allClasses) {\n";
        classListCode += "\t\t\tif (cls.pack.join('.') == packageName) {\n";
        classListCode += "\t\t\t\tresult.push(cls);\n";
        classListCode += "\t\t\t}\n";
        classListCode += "\t\t}\n";
        classListCode += "\t\treturn result;\n";
        classListCode += "\t}\n\n";

        classListCode += "\tpublic static function getClassStats():Dynamic {\n";
        classListCode += "\t\tvar stats = {\n";
        classListCode += "\t\t\ttotal: allClasses.length,\n";
        classListCode += "\t\t\tclasses: 0,\n";
        classListCode += "\t\t\tinterfaces: 0,\n";
        classListCode += "\t\t\tabstracts: 0,\n";
        classListCode += "\t\t\tenums: 0,\n";
        classListCode += "\t\t\ttypedefs: 0,\n";
        classListCode += "\t\t\tpackages: new Map<String, Int>()\n";
        classListCode += "\t\t};\n";
        classListCode += "\t\tfor (cls in allClasses) {\n";
        classListCode += "\t\t\tif (cls.isInterface) stats.interfaces++;\n";
        classListCode += "\t\t\telse if (cls.isAbstract) stats.abstracts++;\n";
        classListCode += "\t\t\telse if (cls.isEnum) stats.enums++;\n";
        classListCode += "\t\t\telse if (cls.fields.length > 0 && cls.fields[0].indexOf('typedef:') == 0) stats.typedefs++;\n";
        classListCode += "\t\t\telse stats.classes++;\n";
        classListCode += "\t\t\t\n";
        classListCode += "\t\t\tvar pkg = cls.pack.join('.');\n";
        classListCode += "\t\t\tif (!stats.packages.exists(pkg)) stats.packages.set(pkg, 0);\n";
        classListCode += "\t\t\tstats.packages.set(pkg, stats.packages.get(pkg) + 1);\n";
        classListCode += "\t\t}\n";
        classListCode += "\t\treturn stats;\n";
        classListCode += "\t}\n";

        classListCode += "}\n";

        // Write the generated file
        var filePath = Context.definedValue("output-dir") + "/yutautil/GeneratedClassList.hx";
        if (Context.definedValue("output-dir") == null) {
            filePath = "src/yutautil/GeneratedClassList.hx";
        }

        try {
            sys.io.File.saveContent(filePath, classListCode);
            trace("ClassListMacro: Generated class list accessor at: " + filePath);
        } catch (e:Dynamic) {
            trace("ClassListMacro: Warning - Could not write generated class list: " + e);
        }
    }

    /**
     * Generate a summary of discovered classes
     */
    private static function generateClassSummary():Void {
        var summary = "\n=== CLASS DISCOVERY SUMMARY ===\n";
        summary += "Total classes discovered: " + allClasses.length + "\n";

        var packages = new Map<String, Int>();
        var classCount = 0;
        var interfaceCount = 0;
        var abstractCount = 0;
        var enumCount = 0;
        var typedefCount = 0;

        for (cls in allClasses) {
            var pkg = cls.pack.join('.');
            if (!packages.exists(pkg)) packages.set(pkg, 0);
            packages.set(pkg, packages.get(pkg) + 1);

            if (cls.isInterface) interfaceCount++;
            else if (cls.isAbstract) abstractCount++;
            else if (cls.isEnum) enumCount++;
            else if (cls.fields.length > 0 && cls.fields[0].indexOf('typedef:') == 0) typedefCount++;
            else classCount++;
        }

        summary += "  Classes: " + classCount + "\n";
        summary += "  Interfaces: " + interfaceCount + "\n";
        summary += "  Abstracts: " + abstractCount + "\n";
        summary += "  Enums: " + enumCount + "\n";
        summary += "  Typedefs: " + typedefCount + "\n";
        summary += "  Packages: " + Lambda.count(packages) + "\n";

        summary += "\nTop packages by class count:\n";
        var sortedPackages = [for (pkg in packages.keys()) {name: pkg, count: packages.get(pkg)}];
        sortedPackages.sort((a, b) -> b.count - a.count);

        for (i in 0...Math.min(10, sortedPackages.length)) {
            var pkg = sortedPackages[i];
            summary += "  " + pkg.name + ": " + pkg.count + " classes\n";
        }

        summary += "================================\n";

        trace(summary);
    }

    /**
     * Add global metadata to all classes for tracking
     */
    public static function addGlobalTrackingMetadata():Void {
        // Add metadata to mark classes as discovered by our macro
        Compiler.addGlobalMetadata("", "@:build(yutautil.ClassListMacro.addClassMetadata())", true, true, false);

        trace("ClassListMacro: Added global tracking metadata");
    }

    /**
     * Build macro to add metadata to individual classes
     */
    public static function addClassMetadata():Array<Field> {
        var fields = Context.getBuildFields();
        var localClass = Context.getLocalClass();

        if (localClass != null) {
            var cls = localClass.get();
            // Add metadata to track this class was processed
            cls.meta.add(":classListDiscovered", [], cls.pos);

            // Add build timestamp
            var timestamp = Date.now().toString();
            cls.meta.add(":buildTimestamp", [macro $v{timestamp}], cls.pos);

            // Add macro version
            cls.meta.add(":classListMacroVersion", [macro $v{"1.0.0"}], cls.pos);
        }

        return fields;
    }

    #end // macro
}

/**
 * Runtime utilities for accessing the class list
 * Available even when not in macro context
 */
class ClassListUtils {
    /**
     * Access the generated class list at runtime
     * Note: Requires the macro to have been run during compilation
     */
    public static function getAllClasses():Array<Dynamic> {
        #if macro
        return ClassListMacro.allClasses.map(cls -> {
            name: cls.name,
            fullName: cls.fullName,
            module: cls.module,
            pack: cls.pack,
            isInterface: cls.isInterface,
            isAbstract: cls.isAbstract,
            isEnum: cls.isEnum,
            superClass: cls.superClass,
            interfaces: cls.interfaces,
            fields: cls.fields,
            staticFields: cls.staticFields,
            constructors: cls.constructors,
            meta: cls.meta,
            doc: cls.doc,
            pos: cls.pos
        });
        #else
        // At runtime, try to access the generated class list
        try {
            var generatedClassList = Type.resolveClass("yutautil.GeneratedClassList");
            if (generatedClassList != null) {
                return Reflect.callMethod(generatedClassList, Reflect.field(generatedClassList, "getAllClasses"), []);
            }
        } catch (e:Dynamic) {
            trace("ClassListUtils: Generated class list not available: " + e);
        }
        return [];
        #end
    }

    /**
     * Trace all discovered classes
     */
    public static function traceAllClasses():Void {
        #if macro
        ClassListMacro.trace("=== ALL CLASSES (macro context) ===");
        for (cls in ClassListMacro.allClasses) {
            trace(cls.fullName + " (" + cls.fields.length + " fields)");
        }
        #else
        // At runtime, try to access the generated class list
        try {
            var generatedClassList = Type.resolveClass("yutautil.GeneratedClassList");
            if (generatedClassList != null) {
                Reflect.callMethod(generatedClassList, Reflect.field(generatedClassList, "traceAllClasses"), []);
                return;
            }
        } catch (e:Dynamic) {
            trace("ClassListUtils: Generated class list not available: " + e);
        }

        trace("ClassListUtils: No class list available - macro may not have been run");
        #end
    }

    /**
     * Initialize the class list macro
     * Call this during initialization to trigger class discovery
     */
    public static function initialize():Void {
        #if macro
        ClassListMacro.build();
        #else
        trace("ClassListUtils: Initialize called at runtime (class discovery happens at compile time)");
        #end
    }
}
