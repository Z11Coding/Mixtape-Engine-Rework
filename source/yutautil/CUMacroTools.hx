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

                var errors:Array<{err:String, pos:Position}> = [];
                for (key in gotos.keys()) {
                    var gotosArr = gotos.get(key);
                    var tagsArr = tags.get(key);
                    for (goto in gotosArr) {
                        if (tagsArr == null || tagsArr.indexOf(goto.tag) == -1) {
                            var err = "Expected an existing goto tag in this method: '" + goto.tag + "' (" + key + ")";
                            errors.push({err: err, pos: goto.pos});
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
                    info += "Points:\n";
                    for (key in points.keys()) {
                        info += "  " + key + ": " + points.get(key) + "\n";
                    }
                    var tagCount = 0;
                    for (_ in tags.keys()) tagCount++;
                    info += "Total tags: " + tagCount + "\n";
                    if (errors.length > 0) {
                        info += "Errors:\n" + [for (e in errors) e.err].join("\n") + "\n";
                    }
                    Context.info(info, Context.currentPos());
                }

                // Now report errors after debug info
                for (e in errors) {
                    Context.error(e.err, e.pos);
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
        return macro GoTo(tag);
    }

    public static macro function CLabel(tag:String):Expr {
        return macro GoToTag(tag);
}

// Special functions that can use line pointers to create tags and gotos instead of strings.

    // Keeps track of created points: "Class.method" -> tag
    static var points:Map<String, String> = new Map();

    public static macro function CreatePoint():Expr {
        // Generate a unique tag based on class, method, and line
        var curClass = Context.getLocalClass();
        var className = curClass != null ? curClass.get().name : "UnknownClass";
        var curMethod = Context.getLocalMethod();
        var methodName = curMethod != null ? curMethod : "UnknownMethod";
        var key = className + "." + methodName;
        var pos = Context.currentPos();
        var line = Context.getPosInfos(pos).min;
        var tag = className + "_" + methodName + "_line_" + line;

        // Only allow one point per method
        if (points.exists(key)) {
            Context.error("CUMacroTools.CreatePoint: Only one point can exist in the same method ('" + key + "').", pos);
        } else {
            points.set(key, tag);
        }

        return macro GoToTag($v{tag});
    }

    public static macro function ToPoint():Expr {
        // Find the point tag for the current class+method
        var curClass = Context.getLocalClass();
        var className = curClass != null ? curClass.get().name : "UnknownClass";
        var curMethod = Context.getLocalMethod();
        var methodName = curMethod != null ? curMethod : "UnknownMethod";
        var key = className + "." + methodName;
        var pos = Context.currentPos();

        // Look up the tag created by CreatePoint
        var tag = points.get(key);
        if (tag == null) {
            Context.error("CUMacroTools.ToPoint: No point exists in this method ('" + key + "').", pos);
        }

        return macro GoTo($v{tag});
    }

    // Functions to be able to type check anonymous structures, and typedefs.

    /**
     * Checks if the given variable matches the provided type definition.
     * The `typeDef` parameter can be:
     *   - a Class<T> (normal type): uses standard type checking
     *   - a typedef (object with fields): checks if all fields exist and types match
     *   - an anonymous structure: checks if all fields exist and types match
     *
     * Returns true if the variable matches the type definition, false otherwise.
     */
    public static macro function matchesType(varExpr:Expr, typeDef:Expr):Expr {
        var pos = Context.currentPos();

        // Helper to resolve the type from an Expr (type path, typedef, anonymous, etc.)
        function resolveType(typeExpr:Expr):Type {
            Context.info("matchesType: Resolving type for typeDef", pos);
            switch (typeExpr.expr) {
                case EConst(CIdent(typeName)):
                    Context.info('matchesType: typeDef is identifier: $typeName', pos);
                    try {
                        var t = Context.getType(typeName);
                        Context.info('matchesType: Resolved type path: $typeName', pos);
                        return t;
                    } catch (e:Dynamic) {
                        Context.info('matchesType: Failed to resolve type path, falling back to typeof', pos);
                        return Context.typeof(typeExpr);
                    }
                case EObjectDecl(_):
                    Context.info('matchesType: typeDef is anonymous object', pos);
                    return Context.typeof(typeExpr);
                default:
                    Context.info('matchesType: typeDef is other expr, using typeof', pos);
                    return Context.typeof(typeExpr);
            }
        }

        // Helper to check if a type is a typedef, anonymous, or class
        function getTypeKind(t:Type):String {
            switch (t) {
                case TType(_, _): return "typedef";
                case TAnonymous(_): return "anonymous";
                case TInst(_, _): return "class";
                default: return "other";
            }
        }

        // Helper to get all fields of a typedef or anonymous structure
        function getFields(t:Type):Array<{name:String, t:Type}> {
            switch (t) {
                case TAnonymous(a):
                    Context.info('matchesType: Getting fields from anonymous structure', pos);
                    var fields = [];
                    for (f in a.get().fields) {
                        Context.info('matchesType: Found field: ' + f.name, pos);
                        fields.push({name: f.name, t: f.type});
                    }
                    return fields;
                case TType(tdef, params):
                    Context.info('matchesType: Getting fields from typedef', pos);
                    var t2 = tdef.get().type;
                    return getFields(Context.follow(t2));
                default:
                    Context.info('matchesType: No fields found for this type', pos);
                    return [];
            }
        }

        Context.info("matchesType: Starting type resolution", pos);
        var type = resolveType(typeDef);
        var kind = getTypeKind(type);
        Context.info('matchesType: Type kind is "' + kind + '"', pos);

        if (kind == "typedef" || kind == "anonymous") {
            Context.info('matchesType: Checking fields for typedef/anonymous', pos);
            var fields = getFields(type);
            if (fields.length == 0) {
                Context.info('matchesType: No fields found, falling back to Std.isOfType', pos);
                return macro Std.isOfType($varExpr, $typeDef);
            }
            // Generate code to check all fields at runtime
            var checks = [];
            for (f in fields) {
                Context.info('matchesType: Adding runtime check for field: ' + f.name, pos);
                checks.push(macro Reflect.hasField($varExpr, $v{f.name}));
                // Optionally, check type of each field (runtime, so limited)
                // This only checks if the field exists, not its type at runtime
            }
            // Combine all checks with &&
            var expr:Expr = checks.shift();
            for (c in checks) expr = macro $expr && $c;
            Context.info('matchesType: Returning combined field checks', pos);
            return expr;
        } else if (kind == "class") {
            Context.info('matchesType: Type is class, using Std.isOfType', pos);
            return macro Std.isOfType($varExpr, $typeDef);
        } else {
            Context.info('matchesType: Type is other, using Std.isOfType', pos);
            // Fallback for other types
            return macro Std.isOfType($varExpr, $typeDef);
        }
    }

    // One for checking flixel's typelimit types, so that you can specifically check and set a type from that limit.

    /**
     * Checks if a variable matches a flixel.util.typeLimit (OneOfTwo, OneOfThree, OneOfFour),
     * including nested ones, and optionally executes code based on the matched type.
     * 
     * @param varExpr The variable expression to check.
     * @param typeDef The typeLimit type (OneOfTwo, OneOfThree, OneOfFour, possibly nested).
     * @param cases   (Optional) A map of type names to expressions to execute if matched.
     *                Can include a "default" key for unmatched types.
     *                Example: { "Int" => macro trace("is int"), "String" => macro trace("is string"), "default" => macro throw "bad type" }
     */
    // public static macro function matchLimitedType(varExpr:Expr, typeDef:Expr, ?cases:Expr):Expr {
    //     var pos = Context.currentPos();

    //     // Helper to resolve type path to Type
    //     function resolveType(typeExpr:Expr):Type {
    //         switch (typeExpr.expr) {
    //             case EConst(CIdent(typeName)):
    //                 try {
    //                     return Context.getType(typeName);
    //                 } catch (e:Dynamic) {
    //                     Context.error('Could not resolve type: $typeName', pos);
    //                 }
    //             default:
    //                 return Context.typeof(typeExpr);
    //         }
    //     }

    //     // Helper to extract type parameters from OneOfX
    //     function getTypeLimitParams(t:Type):Array<Type> {
    //         switch (t) {
    //             case TType(tdef, params):
    //                 var name = tdef.get().name;
    //                 if (name == "OneOfTwo" || name == "OneOfThree" || name == "OneOfFour") {
    //                     return params;
    //                 }
    //             default:
    //         }
    //         return [];
    //     }

    //     // Helper to get type name as string
    //     function getTypeName(t:Type):String {
    //         switch (t) {
    //             case TInst(c, _): return c.get().name;
    //             case TType(tdef, _): return tdef.get().name;
    //             case TEnum(e, _): return e.get().name;
    //             default: return Std.string(t);
    //         }
    //     }

    //     // Recursively flatten all types in nested OneOfX
    //     function flattenTypes(t:Type):Array<Type> {
    //         var arr = [];
    //         var params = getTypeLimitParams(t);
    //         if (params.length > 0) {
    //             for (p in params) arr = arr.concat(flattenTypes(Context.follow(p)));
    //         } else {
    //             arr.push(t);
    //         }
    //         return arr;
    //     }

    //     // Parse the cases argument (should be a map literal)
    //     var caseMap:Map<String, Expr> = new Map();
    //     var hasDefault = false;
    //     if (cases != null) {
    //         switch (cases.expr) {
    //             case EObjectDecl(fields):
    //                 for (f in fields) {
    //                     if (f.field == "default") hasDefault = true;
    //                     caseMap.set(f.field, f.expr);
    //                 }
    //             default:
    //                 Context.error("Cases argument must be an object/map literal.", pos);
    //         }
    //     }

    //     // Resolve the typeDef to a Type
    //     var limitType = resolveType(typeDef);
    //     var allowedTypes = flattenTypes(Context.follow(limitType));
    //     var allowedTypeNames = [for (t in allowedTypes) getTypeName(t)];

    //     // Validate that the caseMap only contains allowed types or "default"
    //     for (k in caseMap.keys()) {
    //         if (k != "default" && allowedTypeNames.indexOf(k) == -1) {
    //             Context.error('Case "$k" is not a valid type for this typeLimit. Allowed: ' + allowedTypeNames.join(", "), pos);
    //         }
    //     }

    //     // Build the if-else or switch/case chain
    //     var exprs:Array<Expr> = [];
    //     for (i in 0...allowedTypes.length) {
    //         var t = allowedTypes[i];
    //         var tname = getTypeName(t);
    //         var cond = macro Std.isOfType($varExpr, $i{tname});
    //         var body = caseMap.exists(tname) ? caseMap.get(tname) : macro {};
    //         exprs.push({cond: cond, body: body});
    //     }

    //     // Add default case
    //     var defaultExpr = caseMap.exists("default") ? caseMap.get("default") : macro throw "No matching type in matchLimitedType";
    //     // Build the chain: if ... else if ... else ...
    //     var result:Expr = null;
    //     for (i in 0...exprs.length) {
    //         var e = exprs[exprs.length - 1 - i];
    //         if (result == null) {
    //             result = macro if (${e.cond}) ${e.body} else $defaultExpr;
    //         } else {
    //             result = macro if (${e.cond}) ${e.body} else $result;
    //         }
    //     }
    //     return result;
    // }

    // C++ Assembly Creation, using both strings, and enum expressions for allowing both typesafe and unsafe assembly.

    /**
     * WARNING: This macro emits C++ assembly code, which may have unintended side-effects and is not portable.
     * Use with extreme caution!
     */
    /**
     * Emits C++ inline assembly using __cpp__.
     * 
     * @param lines Array of assembly code lines. Use {0}, {1}, ... as placeholders for variables.
     * @param vars  (Optional) Array of variable expressions to substitute into the assembly code.
     */
    // public static macro function CAssembly(lines:Array<String>, ?vars:Array<Expr>):Expr {
    //     // Check if this is C++.
    //     if (!Context.defined("cpp")) {
    //         Context.error("CUMacroTools.CAssembly can only be used in C++ targets.", Context.currentPos());
    //     }

    //     // Validate the lines array
    //     if (lines == null || lines.length == 0) {
    //         Context.error("CUMacroTools.CAssembly: Lines cannot be null or empty.", Context.currentPos());
    //     }

    //     // Prepare the asm body with placeholders
    //     var asmBody = lines.map(function(line) return "    " + line).join("\n");
    //     // Replace {0}, {1}, ... with %s for C++ string formatting
    //     var pattern = ~/(\{(\d+)\})/g;
    //     var formatBody = pattern.replace(asmBody, function(r) return "%s");

    //     // Build the code string for __cpp__
    //     var code = "__asm__ (\n\"" + formatBody.split("\n").join("\\n\"\n\"") + "\");";

    //     // Build the argument list for __cpp__: code, then each variable
    //     var args:Array<Expr> = [macro $v{code}];
    //     if (vars != null && vars.length > 0) {
    //         for (v in vars) args.push(v);
    //     }

    //     // Return macro untyped __cpp__(code, var0, var1, ...)
    //     return macro untyped __cpp__($a{args});
    // }

    // public static macro function CAsmInstruction(instruction:String, ?vars:Array<Expr>):Expr {
    //     // Check if this is C++.
    //     if (!Context.defined("cpp")) {
    //         Context.error("CUMacroTools.CAsmInstruction can only be used in C++ targets.", Context.currentPos());
    //     }

    //     // Validate the instruction
    //     if (instruction == null || instruction.trim() == "") {
    //         Context.error("CUMacroTools.CAsmInstruction: Instruction cannot be null or empty.", Context.currentPos());
    //     }

    //     // Prepare the code string for __cpp__
    //     var code = "__asm__ (\"" + StringTools.replace(instruction, "\"", "\\\"") + "\");";

    //     // Build the argument list for __cpp__: code, then each variable
    //     var args:Array<Expr> = [macro $v{code}];
    //     if (vars != null && vars.length > 0) {
    //         for (v in vars) args.push(v);
    //     }

    //     // Return macro untyped __cpp__(code, var0, var1, ...)
    //     return macro untyped __cpp__($a{args});
    // }

    // Multi-Var Declarawtion. Example: CUMacroTools.Declare(String, [expr1, expr2, expr3]);

    /**
     * Declares multiple variables of the same type in a single statement.
     * 
     * @param type The type of the variables to declare (e.g., String, Int).
     * @param vars An array of expressions representing the variable names to declare.
     * @return An expression that declares the variables in a single statement.
     */

    // public static macro function Declare(type:Expr, vars:Array<Expr>):Expr {
    //     var pos = Context.currentPos();

    //     // Validate the type
    //     if (type == null) {
    //         Context.error("CUMacroTools.Declare: Type cannot be null.", pos);
    //     }

    //     // Validate the vars array
    //     if (vars == null || vars.length == 0) {
    //         Context.error("CUMacroTools.Declare: Vars cannot be null or empty.", pos);
    //     }

    //     // Build the declaration string
    //     var typeStr = Context.typeof(type).toString();
    //     var declarations = vars.map(function(v) return typeStr + " " + v.toString()).join(", ");

    //     // Return the declaration expression
    //     return macro $v{declarations};
    // }

    public static macro function NativeAsm(code:String):Expr {
        // Check if this is C++.
        if (!Context.defined("cpp")) {
            Context.error("CUMacroTools.NativeAsm can only be used in C++ targets.", Context.currentPos());
        }

        // Validate the code
        if (code == null || StringTools.trim(code) == "") {
            Context.error("CUMacroTools.NativeAsm: Code cannot be null or empty.", Context.currentPos());
        }

        // Prepare the code string for __cpp__
        var asmCode = "__asm__ (\"" + StringTools.replace(code, "\"", "\\\"") + "\");";

        // Return macro untyped __cpp__(asmCode)
        return macro untyped __cpp__($v{asmCode});
    }

    /**
     * Emits a C++ comment using __cpp__.
     * 
     * @param comment The comment text to emit.
     * @return An expression that emits the comment in C++ code.
     */
    public static macro function NativeComment(comment:String, ?showHXLine:Bool = false):Expr {
        // Check if this is C++.
        if (!Context.defined("cpp")) {
            Context.error("CUMacroTools.NativeComment can only be used in C++ targets.", Context.currentPos());
        }

        // Validate the comment
        if (comment == null || StringTools.trim(comment) == "") {
            Context.error("CUMacroTools.NativeComment: Comment cannot be null or empty.", Context.currentPos());
        }

        // Optionally show the Haxe line number in the comment
        if (showHXLine) {
            var hxLine = Context.getPosInfos(Context.currentPos()).min;
            comment = "Haxe line: " + hxLine + " | " + comment;
        }

        // Prepare the code string for __cpp__
        var code = "// " + StringTools.replace(comment, "\n", "\n// ");

        // Return macro untyped __cpp__(code)
        return macro untyped __cpp__($v{code});
    }

    public static macro function NativeTrace(message:Expr, ?showHXLine:Bool = false, ?allowToString:Bool = true):Expr {
        // Check if this is C++.
        if (!Context.defined("cpp")) {
            Context.error("CUMacroTools.NativeTrace can only be used in C++ targets.", Context.currentPos());
        }

        if (message == null) {
            Context.error("CUMacroTools.NativeTrace: Message cannot be null.", Context.currentPos());
        }

        var msgExpr:Expr = message;
        if (showHXLine) {
            var hxLine = Context.getPosInfos(Context.currentPos()).min;
            msgExpr = macro "Haxe line: " + $v{hxLine} + " | " + $msgExpr;
        }

        if (allowToString) {
            // Use {0} placeholder, which Haxe will convert to string
            return macro untyped __cpp__("std::cout << {0} << std::endl;", msgExpr);
        } else {
            // Inject the expression directly into the C++ code string
            // This will emit: std::cout << <expression> << std::endl;
            Context.error("CUMacroTools.NativeTrace: Native Tracing of direct objects is currently not working. Please use allowToString = true.", Context.currentPos());
            return macro untyped __cpp__($v{"std::cout << "}, msgExpr, $v{" << std::endl;"});
        }
    }

    // Easy way to check multiple keys with FlxKey.

    /**
     * Generates a function that checks if any of the specified keys match the given FlxKey status.
     * Example usage:
     *   CUMacroTools.generateKeyCheckFunction(["A", "B"], "justPressed")
     *   // Generates: function():Bool { if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.B) return true; return false; }
     */
    public static macro function generateKeyCheckFunction(keys:Array<String>, status:String):Expr {
        // Validate input
        if (keys == null || keys.length == 0) {
            Context.error("CUMacroTools.generateKeyCheckFunction: Keys cannot be null or empty.", Context.currentPos());
        }
        if (status == null || StringTools.trim(status) == "") {
            Context.error("CUMacroTools.generateKeyCheckFunction: Status cannot be null or empty.", Context.currentPos());
        }

        // List of valid statuses (add more if needed)
        var validStatuses = [
            "justPressed", "pressed", "anyJustPressed", "released", "justReleased",
            "anyJustReleased", "anyPressed"
        ];
        if (validStatuses.indexOf(status) == -1) {
            Context.warning('CUMacroTools.generateKeyCheckFunction: Status "' + status + '" is not a standard FlxKey status. Proceeding anyway.', Context.currentPos());
        }

        // Build the check expression: FlxG.keys.<status>[FlxKey.toString(KEY)]
        var checks = [];
        for (key in keys) {
            // Convert key to FlxKey if not already a string
            checks.push(macro Reflect.field(Reflect.field(FlxG.keys, $v{status}), FlxKey.toString($v{key})));
        }
        // Combine all checks with ||
        var expr:Expr = checks.shift();
        for (c in checks) expr = macro $expr || $c;

        // Return a function that checks and returns true if any key matches
        return macro function():Bool {
            if ($expr) return true;
            return false;
        }
    }

    /**
     * Helper macros for common FlxKey checks.
     * Usage: CUMacroTools.checkKeysJustPressed(["A", "B"])
     */
    public static macro function checkKeysJustPressed(keys:Array<Dynamic>):Expr {
        return macro CUMacroTools.generateKeyCheckFunction($a{[for (k in keys) macro $v{k}]}, "justPressed")();
    }
    public static macro function checkKeysPressed(keys:Array<Dynamic>):Expr {
        return macro CUMacroTools.generateKeyCheckFunction($a{[for (k in keys) macro $v{k}]}, "pressed")();
    }
    public static macro function checkKeysAnyJustPressed(keys:Array<Dynamic>):Expr {
        return macro CUMacroTools.generateKeyCheckFunction($a{[for (k in keys) macro $v{k}]}, "anyJustPressed")();
    }
    public static macro function checkKeysReleased(keys:Array<Dynamic>):Expr {
        return macro CUMacroTools.generateKeyCheckFunction($a{[for (k in keys) macro $v{k}]}, "released")();
    }
    public static macro function checkKeysJustReleased(keys:Array<Dynamic>):Expr {
        return macro CUMacroTools.generateKeyCheckFunction($a{[for (k in keys) macro $v{k}]}, "justReleased")();
    }
    public static macro function checkKeysAnyJustReleased(keys:Array<Dynamic>):Expr {
        return macro CUMacroTools.generateKeyCheckFunction($a{[for (k in keys) macro $v{k}]}, "anyJustReleased")();
    }
    public static macro function checkKeysAnyPressed(keys:Array<Dynamic>):Expr {
        return macro CUMacroTools.generateKeyCheckFunction($a{[for (k in keys) macro $v{k}]}, "anyPressed")();
    }
}