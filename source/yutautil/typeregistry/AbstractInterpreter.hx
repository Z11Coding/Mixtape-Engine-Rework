package yutautil.typeregistry;

/**
 * Runtime abstract type interpreter using build-time collected data.
 *
 * Haxe abstracts are compile-time constructs; at runtime their methods live on
 * `_Impl_` static classes. This interpreter bridges that gap:
 *
 * - Resolves abstract `_Impl_` classes and dispatches method calls to them.
 * - Wraps raw values into AbstractValue containers that carry abstract type info.
 * - Applies `@:from` / `@:to` conversion rules at runtime.
 * - Dispatches operator overloads (like `+`, `-`, `==`) to the correct `_Impl_` statics.
 * - Provides a bridge so YScript can `import` and use abstracts as intended.
 *
 * Usage:
 *   var interp = AbstractInterpreter.forAbstract("yutautil.Num");
 *   var wrapped = interp.wrapValue(42);           // Interpret 42 as Num
 *   var result = interp.callMethod(wrapped, "toInt", []);  // Call Num method
 *   var added  = interp.applyOperator("+", wrapped, otherWrapped);
 */
class AbstractInterpreter {
	// Cache of resolved interpreters keyed by abstract originalTypePath
	private static var cache:Map<String, AbstractInterpreter> = new Map();

	/** The abstract's original Haxe type path (e.g. "yutautil.Num") */
	public var abstractPath(default, null):String;

	/** The abstract's simple name (e.g. "Num") */
	public var abstractName(default, null):String;

	/** The underlying type name (e.g. "Float") */
	public var underlyingType(default, null):String;

	/** The resolved _Impl_ class, or null if not resolvable at runtime */
	public var implClass(default, null):Class<Dynamic>;

	/** The full _Impl_ class path (e.g. "yutautil._Num.Num_Impl_") */
	public var implClassPath(default, null):String;

	/** Whether the abstract has an impl class */
	public var hasImpl(default, null):Bool;

	/** Whether the abstract has generic type parameters */
	public var isGeneric(default, null):Bool;

	/** Generic type parameter names */
	public var typeParams(default, null):Array<String>;

	/** Cached abstract build data from BuildDataLoader */
	private var buildData:Dynamic;

	/** Cached impl field info for fast method lookup */
	private var methodCache:Map<String, ImplMethodInfo>;

	/** Cached operator info */
	private var operatorCache:Map<String, ImplMethodInfo>;

	/** Cached from-conversion types */
	private var fromTypes:Array<ConversionEntry>;

	/** Cached to-conversion types */
	private var toTypes:Array<ConversionEntry>;

	/**
	 * Get or create an AbstractInterpreter for a given abstract type path.
	 * Returns null if the abstract is not found in build data.
	 *
	 * @param abstractPath Full Haxe type path (e.g. "yutautil.Num") or simple name (e.g. "Num")
	 */
	public static function forAbstract(abstractPath:String):AbstractInterpreter {
		if (cache.exists(abstractPath)) {
			return cache.get(abstractPath);
		}

		var interp = new AbstractInterpreter(abstractPath);
		if (interp.buildData == null) {
			return null; // Abstract not found in build data
		}

		cache.set(abstractPath, interp);
		// Also cache by simple name if different
		if (interp.abstractName != abstractPath) {
			cache.set(interp.abstractName, interp);
		}
		// Also cache by originalTypePath if different
		if (interp.abstractPath != abstractPath && interp.abstractPath != null) {
			cache.set(interp.abstractPath, interp);
		}
		return interp;
	}

	/**
	 * Check if a given type name refers to a known abstract.
	 */
	public static function isAbstractType(typeName:String):Bool {
		if (!BuildDataLoader.initialize()) return false;
		return BuildDataLoader.getAbstractInfo(typeName) != null;
	}

	/**
	 * Clear the interpreter cache (useful if build data is reloaded).
	 */
	public static function clearCache():Void {
		cache.clear();
	}

	/**
	 * Get all known abstract type paths.
	 */
	public static function getAllAbstractPaths():Array<String> {
		if (!BuildDataLoader.initialize()) return [];
		return BuildDataLoader.getAllAbstracts();
	}

	// ===================== Constructor =====================

	private function new(path:String) {
		methodCache = new Map();
		operatorCache = new Map();
		fromTypes = [];
		toTypes = [];

		buildData = BuildDataLoader.getAbstractInfo(path);
		if (buildData == null) return;

		// Extract core info
		abstractName = buildData.name;
		abstractPath = buildData.originalTypePath != null ? buildData.originalTypePath : path;
		underlyingType = buildData.type;
		isGeneric = buildData.isGeneric == true;
		typeParams = buildData.typeParams != null ? cast buildData.typeParams : [];
		hasImpl = buildData.hasImplClass == true;
		implClassPath = buildData.implFullName;

		// Try to resolve the _Impl_ class at runtime
		if (implClassPath != null) {
			implClass = Type.resolveClass(implClassPath);
		}
		if (implClass == null && buildData.implClassName != null) {
			// Try resolving by just the impl class name
			implClass = Type.resolveClass(Std.string(buildData.implClassName));
		}

		// Build method cache from implFields
		buildMethodCache();

		// Build conversion caches
		buildConversionCaches();
	}

	// ===================== Method Cache =====================

	private function buildMethodCache():Void {
		if (buildData.implFields == null) return;

		var fields:Array<Dynamic> = cast buildData.implFields;
		for (field in fields) {
			if (field == null) continue;
			var name:String = field.name;
			if (name == null) continue;

			var info:ImplMethodInfo = {
				name: name,
				type: field.type,
				isPublic: field.isPublic == true,
				isOperator: field.isOperator == true,
				operatorName: field.operatorName,
				doc: field.doc,
				kind: field.kind
			};

			// Store in appropriate cache
			if (info.isOperator && info.operatorName != null) {
				operatorCache.set(info.operatorName, info);
				// Also store under the haxe internal name
				operatorCache.set(name, info);
			}

			methodCache.set(name, info);
		}
	}

	// ===================== Conversion Cache =====================

	private function buildConversionCaches():Void {
		// Build "from" conversions
		if (buildData.fromConversions != null) {
			var convs:Array<Dynamic> = cast buildData.fromConversions;
			for (conv in convs) {
				if (conv == null) continue;
				fromTypes.push({
					typeName: conv.type,
					fieldName: conv.field != null ? conv.field.name : null,
					fieldType: conv.field != null ? conv.field.type : null
				});
			}
		} else if (buildData.from != null) {
			var simpleFrom:Array<Dynamic> = cast buildData.from;
			for (f in simpleFrom) {
				fromTypes.push({
					typeName: Std.string(f),
					fieldName: null,
					fieldType: null
				});
			}
		}

		// Build "to" conversions
		if (buildData.toConversions != null) {
			var convs:Array<Dynamic> = cast buildData.toConversions;
			for (conv in convs) {
				if (conv == null) continue;
				toTypes.push({
					typeName: conv.type,
					fieldName: conv.field != null ? conv.field.name : null,
					fieldType: conv.field != null ? conv.field.type : null
				});
			}
		} else if (buildData.to != null) {
			var simpleTo:Array<Dynamic> = cast buildData.to;
			for (t in simpleTo) {
				toTypes.push({
					typeName: Std.string(t),
					fieldName: null,
					fieldType: null
				});
			}
		}
	}

	// ===================== Value Wrapping =====================

	/**
	 * Wrap a raw value as an AbstractValue, interpreting it as this abstract type.
	 * Returns null if the value is not compatible with this abstract.
	 */
	public function wrapValue(value:Dynamic):AbstractValue {
		if (!isValueCompatible(value)) {
			return null;
		}
		return new AbstractValue(value, this);
	}

	/**
	 * Force-wrap a value as this abstract type (no compatibility check).
	 */
	public function forceWrap(value:Dynamic):AbstractValue {
		return new AbstractValue(value, this);
	}

	/**
	 * Unwrap an AbstractValue to get the raw underlying value.
	 */
	public function unwrap(wrapped:Dynamic):Dynamic {
		if (Std.isOfType(wrapped, AbstractValue)) {
			return (cast(wrapped, AbstractValue)).rawValue;
		}
		return wrapped; // Already unwrapped
	}

	// ===================== Type Compatibility =====================

	/**
	 * Check if a raw value is compatible with this abstract type.
	 * Uses both the underlying type and @:from conversion rules.
	 */
	public function isValueCompatible(value:Dynamic):Bool {
		if (value == null) return true; // null is generally assignable

		// Check underlying type compatibility
		if (matchesUnderlyingType(value)) return true;

		// Check @:from conversions
		return canConvertFrom(value);
	}

	/**
	 * Check if a value matches the underlying type of this abstract.
	 */
	public function matchesUnderlyingType(value:Dynamic):Bool {
		if (value == null) return false;
		return isTypeMatch(value, underlyingType);
	}

	/**
	 * Check if a value can be converted FROM its type into this abstract
	 * via one of the @:from conversion rules.
	 */
	public function canConvertFrom(value:Dynamic):Bool {
		for (entry in fromTypes) {
			if (isTypeMatch(value, entry.typeName)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Check if this abstract can be converted TO the given target type
	 * via one of the @:to conversion rules.
	 */
	public function canConvertTo(targetTypeName:String):Bool {
		for (entry in toTypes) {
			if (entry.typeName == targetTypeName) {
				return true;
			}
		}
		// Also check underlying type
		return underlyingType == targetTypeName;
	}

	/**
	 * Get all types this abstract can be created from (via @:from).
	 */
	public function getFromTypes():Array<ConversionEntry> {
		return fromTypes.copy();
	}

	/**
	 * Get all types this abstract can be converted to (via @:to).
	 */
	public function getToTypes():Array<ConversionEntry> {
		return toTypes.copy();
	}

	// ===================== Method Dispatch =====================

	/**
	 * Call a method on an abstract value via its _Impl_ class.
	 * The first argument to impl static methods is always `this` (the underlying value).
	 *
	 * @param value The abstract value (raw or wrapped)
	 * @param methodName The method name as declared in the abstract
	 * @param args Additional arguments (NOT including `this`)
	 * @return The method's return value
	 */
	public function callMethod(value:Dynamic, methodName:String, args:Array<Dynamic>):Dynamic {
		var rawValue = unwrap(value);

		if (implClass == null) {
			throw 'AbstractInterpreter: Cannot call method "$methodName" - no _Impl_ class found for $abstractPath';
		}

		// Build the full argument list: [this, ...args]
		var fullArgs:Array<Dynamic> = [rawValue];
		if (args != null) {
			for (a in args) {
				fullArgs.push(unwrap(a));
			}
		}

		// Try to call the static method on the _Impl_ class
		var method = Reflect.field(implClass, methodName);
		if (method != null && Reflect.isFunction(method)) {
			return Reflect.callMethod(implClass, method, fullArgs);
		}

		// Try with underscore prefix (Haxe sometimes renames methods)
		method = Reflect.field(implClass, '_$methodName');
		if (method != null && Reflect.isFunction(method)) {
			return Reflect.callMethod(implClass, method, fullArgs);
		}

		throw 'AbstractInterpreter: Method "$methodName" not found on impl class for $abstractPath';
	}

	/**
	 * Call a static method on the abstract (no `this` parameter).
	 *
	 * @param methodName The static method name
	 * @param args Method arguments
	 * @return The method's return value
	 */
	public function callStaticMethod(methodName:String, args:Array<Dynamic>):Dynamic {
		if (implClass == null) {
			throw 'AbstractInterpreter: Cannot call static method "$methodName" - no _Impl_ class found for $abstractPath';
		}

		var unwrappedArgs:Array<Dynamic> = [];
		if (args != null) {
			for (a in args) {
				unwrappedArgs.push(unwrap(a));
			}
		}

		var method = Reflect.field(implClass, methodName);
		if (method != null && Reflect.isFunction(method)) {
			return Reflect.callMethod(implClass, method, unwrappedArgs);
		}

		throw 'AbstractInterpreter: Static method "$methodName" not found on impl class for $abstractPath';
	}

	/**
	 * Apply an operator overload to abstract values.
	 *
	 * @param op The operator string (e.g. "+", "-", "==", "<", etc.)
	 * @param lhs Left-hand side value
	 * @param rhs Right-hand side value (null for unary operators)
	 * @return The result of the operation
	 */
	public function applyOperator(op:String, lhs:Dynamic, rhs:Dynamic = null):Dynamic {
		if (implClass == null) {
			throw 'AbstractInterpreter: Cannot apply operator "$op" - no _Impl_ class found for $abstractPath';
		}

		var rawLhs = unwrap(lhs);
		var rawRhs = rhs != null ? unwrap(rhs) : null;

		// Try to find the operator method
		var opMethodName = getOperatorMethodName(op);
		if (opMethodName != null) {
			var method = Reflect.field(implClass, opMethodName);
			if (method != null && Reflect.isFunction(method)) {
				if (rawRhs != null) {
					return Reflect.callMethod(implClass, method, [rawLhs, rawRhs]);
				} else {
					return Reflect.callMethod(implClass, method, [rawLhs]);
				}
			}
		}

		// Fallback: try each operator name variant from the cache
		for (key => info in operatorCache) {
			if (info.operatorName == op || normalizeOperator(info.operatorName) == op) {
				var method = Reflect.field(implClass, info.name);
				if (method != null && Reflect.isFunction(method)) {
					if (rawRhs != null) {
						return Reflect.callMethod(implClass, method, [rawLhs, rawRhs]);
					} else {
						return Reflect.callMethod(implClass, method, [rawLhs]);
					}
				}
			}
		}

		// Ultimate fallback: use native Haxe operators on raw values
		return applyNativeOperator(op, rawLhs, rawRhs);
	}

	/**
	 * Apply a @:from conversion to create this abstract from a compatible value.
	 * Uses the conversion function if one was defined, otherwise just wraps the value.
	 */
	public function applyFromConversion(value:Dynamic):AbstractValue {
		var rawValue = unwrap(value);

		// Find matching from conversion
		for (entry in fromTypes) {
			if (isTypeMatch(rawValue, entry.typeName)) {
				if (entry.fieldName != null && implClass != null) {
					// Call the @:from function on the impl class
					var method = Reflect.field(implClass, entry.fieldName);
					if (method != null && Reflect.isFunction(method)) {
						var converted = Reflect.callMethod(implClass, method, [rawValue]);
						return new AbstractValue(converted, this);
					}
				}
				// No conversion function - just wrap the raw value
				return new AbstractValue(rawValue, this);
			}
		}

		// If the value already matches the underlying type, just wrap it
		if (matchesUnderlyingType(rawValue)) {
			return new AbstractValue(rawValue, this);
		}

		return null;
	}

	/**
	 * Apply a @:to conversion to convert this abstract value to a target type.
	 * Uses the conversion function if one was defined, otherwise returns the raw value.
	 */
	public function applyToConversion(value:Dynamic, targetTypeName:String):Dynamic {
		var rawValue = unwrap(value);

		// Find matching to conversion
		for (entry in toTypes) {
			if (entry.typeName == targetTypeName) {
				if (entry.fieldName != null && implClass != null) {
					// Call the @:to function on the impl class (first arg is `this`)
					var method = Reflect.field(implClass, entry.fieldName);
					if (method != null && Reflect.isFunction(method)) {
						return Reflect.callMethod(implClass, method, [rawValue]);
					}
				}
				// No conversion function - return raw value
				return rawValue;
			}
		}

		// If target is the underlying type, return raw value directly
		if (targetTypeName == underlyingType) {
			return rawValue;
		}

		return null;
	}

	// ===================== Field Access =====================

	/**
	 * Access a field/property on a wrapped abstract value.
	 * Tries the _Impl_ class first, then falls back to native field access.
	 */
	public function getField(value:Dynamic, fieldName:String):Dynamic {
		var rawValue = unwrap(value);

		// Check if this field has a getter in the impl class
		if (implClass != null) {
			var getter = Reflect.field(implClass, 'get_$fieldName');
			if (getter != null && Reflect.isFunction(getter)) {
				return Reflect.callMethod(implClass, getter, [rawValue]);
			}

			// Try direct field access on impl
			var directField = Reflect.field(implClass, fieldName);
			if (directField != null && Reflect.isFunction(directField)) {
				return Reflect.callMethod(implClass, directField, [rawValue]);
			}
		}

		// Fallback to direct field access on the raw value
		return Reflect.field(rawValue, fieldName);
	}

	/**
	 * Set a field/property on a wrapped abstract value.
	 */
	public function setField(value:Dynamic, fieldName:String, newValue:Dynamic):Void {
		var rawValue = unwrap(value);
		var rawNewValue = unwrap(newValue);

		// Check if this field has a setter in the impl class
		if (implClass != null) {
			var setter = Reflect.field(implClass, 'set_$fieldName');
			if (setter != null && Reflect.isFunction(setter)) {
				Reflect.callMethod(implClass, setter, [rawValue, rawNewValue]);
				return;
			}
		}

		// Fallback to direct field set on raw value
		Reflect.setField(rawValue, fieldName, rawNewValue);
	}

	// ===================== Introspection =====================

	/**
	 * Get all available method names on this abstract.
	 */
	public function getMethodNames():Array<String> {
		var names:Array<String> = [];
		for (name => info in methodCache) {
			if (info.kind == "method" && !info.isOperator) {
				names.push(name);
			}
		}
		return names;
	}

	/**
	 * Get all available operator names on this abstract.
	 */
	public function getOperatorNames():Array<String> {
		var ops:Array<String> = [];
		for (name => info in operatorCache) {
			if (info.operatorName != null && ops.indexOf(info.operatorName) == -1) {
				ops.push(info.operatorName);
			}
		}
		return ops;
	}

	/**
	 * Check if a method exists on this abstract.
	 */
	public function hasMethod(methodName:String):Bool {
		return methodCache.exists(methodName);
	}

	/**
	 * Check if an operator is overloaded on this abstract.
	 */
	public function hasOperator(op:String):Bool {
		if (operatorCache.exists(op)) return true;
		var normalized = getOperatorMethodName(op);
		return normalized != null && operatorCache.exists(normalized);
	}

	/**
	 * Get a human-readable summary of this abstract type.
	 */
	public function describe():String {
		var sb = new StringBuf();
		sb.add('Abstract: $abstractPath\n');
		sb.add('  Underlying type: $underlyingType\n');
		sb.add('  Has impl class: $hasImpl\n');
		if (hasImpl) {
			sb.add('  Impl class: $implClassPath\n');
			sb.add('  Impl resolved: ${implClass != null}\n');
		}
		sb.add('  Is generic: $isGeneric\n');
		if (isGeneric && typeParams.length > 0) {
			sb.add('  Type params: <${typeParams.join(", ")}>\n');
		}

		if (fromTypes.length > 0) {
			sb.add('  From conversions:\n');
			for (f in fromTypes) {
				sb.add('    - ${f.typeName}');
				if (f.fieldName != null) sb.add(' (via ${f.fieldName})');
				sb.add('\n');
			}
		}

		if (toTypes.length > 0) {
			sb.add('  To conversions:\n');
			for (t in toTypes) {
				sb.add('    - ${t.typeName}');
				if (t.fieldName != null) sb.add(' (via ${t.fieldName})');
				sb.add('\n');
			}
		}

		var methods = getMethodNames();
		if (methods.length > 0) {
			sb.add('  Methods: ${methods.join(", ")}\n');
		}

		var ops = getOperatorNames();
		if (ops.length > 0) {
			sb.add('  Operators: ${ops.join(", ")}\n');
		}

		return sb.toString();
	}

	// ===================== Helper Methods =====================

	private static function isTypeMatch(value:Dynamic, typeName:String):Bool {
		if (value == null) return false;
		if (typeName == null) return false;

		// Normalize the type name for comparison
		var normalized = typeName.toLowerCase();

		// Remove package prefix for basic types
		var lastDot = typeName.lastIndexOf(".");
		if (lastDot >= 0) {
			normalized = typeName.substring(lastDot + 1).toLowerCase();
		}

		var valueType = Type.typeof(value);
		return switch (normalized) {
			case "int" | "integer": valueType.match(TInt);
			case "float" | "number" | "double": valueType.match(TFloat) || valueType.match(TInt);
			case "string": valueType.match(TClass(String));
			case "bool" | "boolean": valueType.match(TBool);
			case "array": Std.isOfType(value, Array);
			case "dynamic": true;
			case _:
				// Try class name matching
				var cls = Type.getClass(value);
				if (cls != null) {
					var className = Type.getClassName(cls);
					if (className != null) {
						className == typeName || className.indexOf(typeName) >= 0 || typeName.indexOf(className) >= 0;
					} else {
						false;
					}
				} else {
					false;
				}
		};
	}

	/**
	 * Map a user-facing operator symbol to the Haxe _Impl_ method name.
	 */
	private static function getOperatorMethodName(op:String):String {
		return switch (op) {
			case "+": "_hx_add";
			case "-": "_hx_sub";
			case "*": "_hx_mul";
			case "/": "_hx_div";
			case "%": "_hx_mod";
			case "==": "_hx_eq";
			case "!=": "_hx_neq";
			case "<": "_hx_lt";
			case "<=": "_hx_lte";
			case ">": "_hx_gt";
			case ">=": "_hx_gte";
			case "&&": "_hx_and";
			case "||": "_hx_or";
			case "!": "_hx_not";
			case "~": "_hx_bnot";
			case "&": "_hx_band";
			case "|": "_hx_bor";
			case "^": "_hx_xor";
			case "<<": "_hx_shl";
			case ">>": "_hx_shr";
			case ">>>": "_hx_ushr";
			case "++": "_hx_inc";
			case "--": "_hx_dec";
			case "[]": "_hx_arrayRead";
			case "[]=": "_hx_arrayWrite";
			case _: null;
		};
	}

	/**
	 * Normalize an operator name from Haxe's internal representation.
	 */
	private static function normalizeOperator(opName:String):String {
		if (opName == null) return null;

		// Handle "A + B" style notation
		var trimmed = StringTools.trim(opName);
		if (trimmed.length >= 3) {
			// Extract the operator symbol from "A op B" or "op A" patterns
			var parts = trimmed.split(" ");
			if (parts.length == 3) {
				return parts[1]; // "A + B" -> "+"
			} else if (parts.length == 2) {
				return parts[0]; // "- A" -> "-"
			}
		}
		return trimmed;
	}

	/**
	 * Apply a native Haxe operator as fallback when no _Impl_ override is found.
	 */
	private static function applyNativeOperator(op:String, lhs:Dynamic, rhs:Dynamic):Dynamic {
		return switch (op) {
			case "+": lhs + rhs;
			case "-": if (rhs != null) lhs - rhs else -lhs;
			case "*": lhs * rhs;
			case "/": lhs / rhs;
			case "%": lhs % rhs;
			case "==": lhs == rhs;
			case "!=": lhs != rhs;
			case "<": (lhs : Float) < (rhs : Float);
			case "<=": (lhs : Float) <= (rhs : Float);
			case ">": (lhs : Float) > (rhs : Float);
			case ">=": (lhs : Float) >= (rhs : Float);
			case _: throw 'AbstractInterpreter: Unsupported native operator: $op';
		};
	}
}

// ===================== Supporting Types =====================

/**
 * Info about a method on an abstract's _Impl_ class.
 */
typedef ImplMethodInfo = {
	name:String,
	?type:String,
	isPublic:Bool,
	isOperator:Bool,
	?operatorName:String,
	?doc:String,
	?kind:String
}

/**
 * Info about a @:from or @:to conversion.
 */
typedef ConversionEntry = {
	typeName:String,
	?fieldName:String,
	?fieldType:String
}
