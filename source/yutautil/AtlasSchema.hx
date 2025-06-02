package yutautil;

import sys.FileSystem;

// Defines rules for a specific file in the schema
typedef AtlasSchemaFileRule = {
    name:String, // base name, e.g. "note"
    allowMultipleFrames:Bool, // e.g. note0, note1, ...
    allowVariants:Bool, // e.g. note_hard, note_easy
    allowAnyType:Bool, // if true, any type (static, animated, variant) is allowed
    required:Bool // if true, must be present
};

// Custom EReg-based rule for schema
// Allows matching file names using a regular expression
typedef AtlasCustomEregRule = {
    name:String,
    ereg:EReg, // regular expression to match file names
    required:Bool
};

// Custom function-based rule for schema
typedef AtlasCustomFuncRule = {
    name:String,
    func:(files:Array<String>, file:String) -> Bool, // custom validation function
    required:Bool
};

typedef AtlasSchemaFileRuleArray = Array<AtlasSchemaFileRule>;

typedef AtlasRule = AtlasSchemaFileRule | AtlasCustomEregRule | AtlasCustomFuncRule;

typedef AtlasSchemaRuleArray = Array<AtlasRule>;

typedef AtlasRuleSet = {
    fileRules:AtlasSchemaFileRuleArray, // rules for specific files
    allowedExtensions:Array<String>, // allowed file extensions
    filePattern:EReg, // pattern to match file names
    strict:Bool, // if true, only files matching rules are allowed
    customEregRules:Array<AtlasCustomEregRule>, // custom EReg rules
    customFuncRules:Array<AtlasCustomFuncRule> // custom function rules
};

// Defines a schema for atlas folders (required files, patterns, etc)
class AtlasSchema {
    public var fileRules:Array<AtlasSchemaFileRule>;
    public var allowedExtensions:Array<String>;
    public var filePattern:EReg;
    public var strict:Bool;
    public var customEregRules:Array<AtlasCustomEregRule>;
    public var customFuncRules:Array<AtlasCustomFuncRule>;

    public function new(?fileRules:Array<AtlasSchemaFileRule>, ?allowedExtensions:Array<String>, ?filePattern:EReg, ?strict:Bool, ?customEregRules:Array<AtlasCustomEregRule>, ?customFuncRules:Array<AtlasCustomFuncRule>) {
        this.fileRules = fileRules != null ? fileRules : [];
        this.allowedExtensions = allowedExtensions != null ? allowedExtensions : ["png", "jpg", "jpeg"];
        this.filePattern = filePattern;
        this.strict = strict == true;
        this.customEregRules = customEregRules != null ? customEregRules : [];
        this.customFuncRules = customFuncRules != null ? customFuncRules : [];
    }

    public static function fromJson(json:String):AtlasSchema {
        var data = haxe.Json.parse(json);
        return new AtlasSchema(
            data.fileRules != null ? data.fileRules : [],
            data.allowedExtensions != null ? data.allowedExtensions : ["png", "jpg", "jpeg"],
            data.filePattern != null ? new EReg(data.filePattern, "") : null,
            data.strict != null ? data.strict : false
        );
    }

    public static function buildBasic(requiredFiles:Array<String>, ?allowedExtensions:Array<String>, ?filePattern:EReg, ?strict:Bool):AtlasSchema {
        var rules = [];
        for (file in requiredFiles) {
            rules.push({
                name: file,
                allowMultipleFrames: false,
                allowVariants: false,
                allowAnyType: false,
                required: true
            });
        }
        return new AtlasSchema(rules, allowedExtensions, filePattern, strict);
    }

    public static function buildSemiBasic(requiredFiles:Array<{name:String, allowMultipleFrames:Bool, allowVariants:Bool, allowAnyType:Bool}>, ?allowedExtensions:Array<String>, ?filePattern:EReg, ?strict:Bool):AtlasSchema {
        var rules = [];
        for (file in requiredFiles) {
            rules.push({
                name: file.name,
                allowMultipleFrames: file.allowMultipleFrames,
                allowVariants: file.allowVariants,
                allowAnyType: file.allowAnyType,
                required: true
            });
        }
        return new AtlasSchema(rules, allowedExtensions, filePattern, strict);
    }

    // Helper to build a schema easily
    public static function build(rules:Array<{name:String, allowMultipleFrames:Bool, allowVariants:Bool, allowAnyType:Bool, required:Bool}>, ?allowedExtensions:Array<String>, ?filePattern:EReg, ?strict:Bool):AtlasSchema {
        return new AtlasSchema(rules, allowedExtensions, filePattern, strict);
    }

    // Example: create a schema for notes with animation, variants, and static images
    public static function exampleNoteSchema():AtlasSchema {
        return AtlasSchema.build([
            { name: "note", allowMultipleFrames: true, allowVariants: true, allowAnyType: false, required: true },
            { name: "background", allowMultipleFrames: false, allowVariants: false, allowAnyType: false, required: true },
            { name: "icon", allowMultipleFrames: false, allowVariants: true, allowAnyType: false, required: false },
            { name: "special", allowMultipleFrames: false, allowVariants: false, allowAnyType: true, required: false }
        ], ["png", "jpg", "jpeg"], null, false);
    }

    // Checks if the folder matches the schema
    public function validate(folder:String, files:Array<String>):Bool {
        var found = new Map<String,Bool>();
        for (rule in fileRules) found.set(rule.name, false);
        for (file in files) {
            var base = file.indexOf(".") > -1 ? file.substr(0, file.lastIndexOf(".")) : file;
            for (rule in fileRules) {
                if (matchesRule(base, rule)) {
                    found.set(rule.name, true);
                }
            }
        }
        for (rule in fileRules) {
            if (rule.required && !found.get(rule.name)) return false;
        }
        if (strict) {
            for (file in files) {
                var base = file.indexOf(".") > -1 ? file.substr(0, file.lastIndexOf(".")) : file;
                var matched = false;
                for (rule in fileRules) {
                    if (matchesRule(base, rule)) matched = true;
                }
                if (!matched) return false;
            }
        }
        // Custom EReg rules
        for (rule in customEregRules) {
            var found = false;
            for (file in files) {
                var base = file.indexOf(".") > -1 ? file.substr(0, file.lastIndexOf(".")) : file;
                if (rule.ereg.match(base)) found = true;
            }
            if (rule.required && !found) return false;
        }
        // Custom func rules
        for (rule in customFuncRules) {
            var found = false;
            for (file in files) {
                if (rule.func(files, file)) found = true;
            }
            if (rule.required && !found) return false;
        }
        return true;
    }

    // Helper to match a file base name to a rule
    private function matchesRule(base:String, rule:AtlasSchemaFileRule):Bool {
        var escapedName = EReg.escape(rule.name);
        if (rule.allowAnyType) return base.indexOf(rule.name) == 0;
        if (rule.allowMultipleFrames && new EReg("^" + escapedName + "\\d+$", "").match(base)) return true;
        if (rule.allowVariants && new EReg("^" + escapedName + "(_[a-zA-Z0-9]+)?$", "").match(base)) return true;
        if (base == rule.name) return true;
        return false;
    }

    // Filters files according to allowedExtensions, filePattern, and fileRules
    public function filterFiles(files:Array<String>):Array<String> {
        var filtered = [];
        for (file in files) {
            var ext = file.substr(file.lastIndexOf(".") + 1).toLowerCase();
            if (allowedExtensions.indexOf(ext) != -1) {
                if (filePattern == null || filePattern.match(file)) {
                    var added = false;
                    if (fileRules.length == 0) {
                        filtered.push(file);
                        continue;
                    }
                    var base = file.indexOf(".") > -1 ? file.substr(0, file.lastIndexOf(".")) : file;
                    for (rule in fileRules) {
                        if (matchesRule(base, rule)) {
                            filtered.push(file);
                            added = true;
                            break;
                        }
                    }
                    if (!added) {
                        for (rule in customEregRules) {
                            if (rule.ereg.match(base)) {
                                filtered.push(file);
                                added = true;
                                break;
                            }
                        }
                    }
                    if (!added) {
                        for (rule in customFuncRules) {
                            if (rule.func(files, file)) {
                                filtered.push(file);
                                break;
                            }
                        }
                    }
                }
            }
        }
        return filtered;
    }
}
