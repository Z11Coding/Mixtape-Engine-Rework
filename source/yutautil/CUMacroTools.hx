package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class CUMacroTools
{
    // Static maps: "Class.method" -> array of tags/gotos
    static var tags:Map<String, Array<String>> = new Map();
    static var gotos:Map<String, Array<{tag:String, pos:Position}>> = new Map();

    public static var validate:Bool = true; // Set manually to enable validation
    public static var debug:Bool = true; // Set manually to enable debug output

    static var validationRegistered:Bool = false; // Ensure validation is only registered once
    static var needsValidation:Bool = false; // Set to true if GoTo is used

    /**
     * WARNING: This macro uses untyped C++ goto, which may have unintended side-effects and is not portable.
     * Use with extreme caution!
     */
    public static macro function GoTo(tag:String):Expr {
        // getMethodKey must be called inside the macro
        function getMethodKey():String {
            var curClass = Context.getLocalClass();
            var className = curClass != null ? curClass.get().name : "UnknownClass";
            var curMethod = Context.getLocalMethod();
            var methodName = curMethod != null ? curMethod : "UnknownMethod";
            return className + "." + methodName;
        }

        var pos = Context.currentPos();
        var key = getMethodKey();
        var arr = gotos.get(key);
        if (arr == null) {
            arr = [];
            gotos.set(key, arr);
        }
        arr.push({tag: tag, pos: pos});

        needsValidation = true;

        // Register validation function only once if needed
        if (validate && !validationRegistered) {
            validationRegistered = true;
            Context.onAfterGenerate(function() {
                // Only run on C++ targets and if validation is needed
                if (!Context.defined("cpp") || !needsValidation) return;

                var errors:Array<String> = [];
                for (key in gotos.keys()) {
                    var gotosArr = gotos.get(key);
                    var tagsArr = tags.get(key);
                    for (goto in gotosArr) {
                        if (tagsArr == null || tagsArr.indexOf(goto.tag) == -1) {
                            var err = "Expected an existing goto tag in this method: '" + goto.tag + "' (" + key + ")";
                            Context.error(err, goto.pos);
                            errors.push(err);
                        }
                    }
                }

                if (debug) {
                    var info = "CUMacroTools Debug Info:\n";
                    info += "Registered tags:\n";
                    for (key in tags.keys()) {
                        info += "  " + key + ": " + tags.get(key) + "\n";
                    }
                    info += "Registered gotos:\n";
                    for (key in gotos.keys()) {
                        info += "  " + key + ": ";
                        var arr = gotos.get(key);
                        info += [for (g in arr) g.tag].join(", ") + "\n";
                    }
                    if (errors.length > 0) {
                        info += "Errors:\n" + errors.join("\n") + "\n";
                    }
                    Context.info(info, Context.currentPos());
                }
            });
        }

        var code = 'goto ' + tag + ';';
        return macro untyped __cpp__($v{code});
    }

    /**
     * WARNING: This macro emits a C++ label, which may have unintended side-effects and is not portable.
     * Use with extreme caution!
     */
    public static macro function GoToTag(tag:String):Expr {
        // getMethodKey must be called inside the macro
        function getMethodKey():String {
            var curClass = Context.getLocalClass();
            var className = curClass != null ? curClass.get().name : "UnknownClass";
            var curMethod = Context.getLocalMethod();
            var methodName = curMethod != null ? curMethod : "UnknownMethod";
            return className + "." + methodName;
        }

        var key = getMethodKey();
        var tagArr = tags.get(key);
        if (tagArr == null) {
            tagArr = [];
            tags.set(key, tagArr);
        }
        if (tagArr.indexOf(tag) == -1) tagArr.push(tag) else {
            Context.error("CUMacroTools.GoToTag: Tag '" + tag + "' already exists in method '" + key + "'." + "You cannot have the same tag twice.", Context.currentPos());
        }

        Context.warning("CUMacroTools.GoToTag: Using C++ labels is not portable and may lead to unexpected behavior. Use with caution.", Context.currentPos());

        // Check if this is C++.
        if (!Context.defined("cpp")) {
            Context.error("CUMacroTools.GoToTag can only be used in C++ targets.", Context.currentPos());
        }

        var code = tag + ':';
        return macro untyped __cpp__($v{code});
    }

    // The same functions above, but as C++ names.

    public static macro function CGoTo(tag:String):Expr {
        return GoTo(tag);
    }

    public static macro function CLabel(tag:String):Expr {
        return GoToTag(tag);
}

}