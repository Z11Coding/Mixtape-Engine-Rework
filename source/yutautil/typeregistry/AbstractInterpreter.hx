package yutautil.typeregistry;

import haxe.ds.StringMap;

using StringTools;

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
typedef ImplFieldInfo = {
	name:String,
	isStatic:Bool,
	type:String,
	params:Array<String>,
	returnType:String,
	operatorName:String
};

typedef ImplMethodInfo = {
	name:String,
	isStatic:Bool,
	type:String,
	params:Array<String>,
	returnType:String,
	isPublic:Bool,
	isOperator:Bool,
	operatorName:String,
	?doc:String,
	?kind:String
};

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
				isStatic: field.isStatic == true,
				type: field.type,
				params: field.params != null ? cast field.params : [],
				returnType: field.returnType != null ? field.returnType : "Dynamic",
				isPublic: field.isPublic == true,
				isOperator: field.operatorName != null,
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
		#if !macro
		if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
			trace('[AbstractInterpreter Debug] forceWrap called with: ${Type.typeof(value)} = $value');
		}
		#end
		var result = new AbstractValue(value, this);
		#if !macro
		if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
			trace('[AbstractInterpreter Debug] forceWrap result rawValue: ${Type.typeof(result.rawValue)} = ${result.rawValue}');
		}
		#end
		return result;
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

		// Extract the raw values properly
		var rawLhs:Dynamic;
		var rawRhs:Dynamic;

		if (Std.isOfType(lhs, yutautil.typeregistry.AbstractValue)) {
			rawLhs = (cast(lhs, yutautil.typeregistry.AbstractValue)).rawValue;
		} else {
			rawLhs = lhs;
		}

		if (rhs != null && Std.isOfType(rhs, yutautil.typeregistry.AbstractValue)) {
			rawRhs = (cast(rhs, yutautil.typeregistry.AbstractValue)).rawValue;
		} else {
			rawRhs = rhs;
		}

		// Find the best matching operator method based on actual operand types
		var bestMethod = findBestOperatorMethod(op, rawLhs, rawRhs);
		if (bestMethod != null) {
			var method = Reflect.field(implClass, bestMethod.name);
			if (method != null && Reflect.isFunction(method)) {
				var result:Dynamic;
				if (rawRhs != null) {
					result = Reflect.callMethod(implClass, method, [rawLhs, rawRhs]);
				} else {
					result = Reflect.callMethod(implClass, method, [rawLhs]);
				}

				// Preserve numeric type - on Haxe cpp target, Dynamic variables
				// can lose their type tag through various operations.
				result = preserveNumericType(result);
				return result;
			}
		}

		// Special case: String concatenation with + (moved after numeric attempts)
		if (op == "+" && (isStringType(rawLhs) || isStringType(rawRhs))) {
			return handleStringConcatenation(rawLhs, rawRhs);
		}

		#if !macro
		if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
			trace('[AbstractInterpreter Debug] No suitable method found, falling back to native operator');
		}
		#end

		// Ultimate fallback: use native Haxe operators on raw values
		return applyNativeOperator(op, rawLhs, rawRhs);
	}

	/**
	 * Apply a @:from conversion to create this abstract from a compatible value.
	 * Uses the conversion function if one was defined, otherwise just wraps the value.
	 */
	public function applyFromConversion(value:Dynamic):AbstractValue {
		var rawValue:Any = unwrap(value);

		#if !macro
		if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
			trace('[AbstractInterpreter Debug] applyFromConversion called with: ${Type.typeof(value)} = $value');
			trace('[AbstractInterpreter Debug] rawValue after unwrap: ${Type.typeof(rawValue)} = $rawValue');
		}
		#end

		// Find matching from conversion
		for (entry in fromTypes) {
			if (isTypeMatch(rawValue, entry.typeName)) {
				#if !macro
				if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
					trace('[AbstractInterpreter Debug] Found matching @:from conversion: ${entry.typeName}');
					trace('[AbstractInterpreter Debug] fieldName: ${entry.fieldName}');
				}
				#end
				if (entry.fieldName != null && implClass != null) {
					// Call the @:from function on the impl class
					var method = Reflect.field(implClass, entry.fieldName);
					if (method != null && Reflect.isFunction(method)) {
						var converted:Any = Reflect.callMethod(implClass, method, [rawValue]);
						#if !macro
						if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
							trace('[AbstractInterpreter Debug] @:from conversion result: ${Type.typeof(converted)} = $converted');
						}
						#end
						return new AbstractValue(converted, this);
					}
				}
				// No conversion function - just wrap the raw value
				#if !macro
				if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
					trace('[AbstractInterpreter Debug] No @:from function, wrapping rawValue: ${Type.typeof(rawValue)} = $rawValue');
				}
				#end
				return new AbstractValue(rawValue, this);
			}
		}

		// If the value already matches the underlying type, just wrap it
		if (matchesUnderlyingType(rawValue)) {
			#if !macro
			if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
				trace('[AbstractInterpreter Debug] Value matches underlying type ${underlyingType}, wrapping: ${Type.typeof(rawValue)} = $rawValue');
			}
			#end
			return new AbstractValue(rawValue, this);
		}

		#if !macro
		if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
			trace('[AbstractInterpreter Debug] No matching conversion found, returning null');
		}
		#end
		return null;
	}

	/**
	 * Apply a @:to conversion to convert this abstract value to a target type.
	 * Uses the conversion function if one was defined, otherwise returns the raw value.
	 */
	public function applyToConversion(value:Dynamic, targetTypeName:String):Dynamic {
		var rawValue:Any = unwrap(value);

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
		var rawValue:Any = unwrap(value);

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
		// Direct cache lookup
		if (operatorCache.exists(op)) return true;

		// Check if any cache entry matches this operator symbol
		var targetMetadata = operatorSymbolToMetadata(op);
		if (targetMetadata != null) {
			for (key => info in operatorCache) {
				if (info.operatorName == targetMetadata) {
					return true;
				}
			}
		}

		// Fallback to old method name mapping
		var normalized = getOperatorMethodName(op);
		return normalized != null && operatorCache.exists(normalized);
	}

	/**
	 * Check if this abstract can perform an operation with the given operand types.
	 * This is the specific function requested for checking operator compatibility with types.
	 */
	public function canApplyOperatorWithTypes(op:String, lhsType:String, rhsType:String):Bool {
		// First check if we have the operator at all
		if (!hasOperator(op)) return false;

		// Find all matching operator methods
		var targetMetadata = operatorSymbolToMetadata(op);
		if (targetMetadata == null) return false;

		var candidates:Array<ImplMethodInfo> = [];
		for (key => info in operatorCache) {
			if (info.operatorName == targetMetadata) {
				candidates.push(info);
			}
		}

		if (candidates.length == 0) return false;

		// Check if any candidate can handle these types
		for (candidate in candidates) {
			if (canMethodHandleTypes(candidate, lhsType, rhsType)) {
				return true;
			}
		}

		return false;
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
		#if !macro
		if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
			trace('[AbstractInterpreter Debug] getOperatorMethodName($op) called');
		}
		#end
		var result = switch (op) {
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
		#if !macro
		if (backend.ClientPrefs != null && backend.ClientPrefs.data.yscriptDebugMode) {
			trace('[AbstractInterpreter Debug] getOperatorMethodName($op) returning: $result');
		}
		#end
		return result;
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

	/**
	 * Convert simple operator symbols to metadata format (e.g. "+" -> "A + B")
	 */
	private static function operatorSymbolToMetadata(symbol:String):Null<String> {
		return switch (symbol) {
			case "+": "A + B";
			case "-": "A - B";
			case "*": "A * B";
			case "/": "A / B";
			case "%": "A % B";
			case "==": "A == B";
			case "!=": "A != B";
			case "<": "A < B";
			case "<=": "A <= B";
			case ">": "A > B";
			case ">=": "A >= B";
			case "&&": "A && B";
			case "||": "A || B";
			case "&": "A & B";
			case "|": "A | B";
			case "^": "A ^ B";
			case "<<": "A << B";
			case ">>": "A >> B";
			case ">>>": "A >>> B";
			case "++": "++A";
			case "--": "--A";
			case "+=": "A += B";
			case "-=": "A -= B";
			case "*=": "A *= B";
			case "/=": "A /= B";
			case "%=": "A %= B";
			case _: null;
		};
	}

	/**
	 * Check if a value represents a string type
	 */
	private static function isStringType(value:Dynamic):Bool {
		return Std.isOfType(value, String);
	}

	/**
	 * Handle string concatenation with automatic conversion
	 */
	private function handleStringConcatenation(lhs:Dynamic, rhs:Dynamic):String {
		var leftStr = convertToString(lhs);
		var rightStr = convertToString(rhs);
		return leftStr + rightStr;
	}

	/**
	 * Convert a value to string, checking for toString method or @:to String conversions
	 */
	private function convertToString(value:Dynamic):String {
		if (value == null) return "null";
		if (Std.isOfType(value, String)) return cast value;

		// Check if value is an AbstractValue with string conversion
		if (Std.isOfType(value, AbstractValue)) {
			var absVal:AbstractValue = cast value;
			if (absVal.interpreter.canConvertTo("String")) {
				try {
					var converted = absVal.interpreter.applyToConversion(absVal.rawValue, "String");
					if (Std.isOfType(converted, String)) return cast converted;
				} catch (e:Dynamic) {
					// Fall through to default conversion
				}
			}
		}

		// Check for toString method
		if (Reflect.hasField(value, "toString")) {
			try {
				var toStringMethod = Reflect.field(value, "toString");
				if (Reflect.isFunction(toStringMethod)) {
					return cast Reflect.callMethod(value, toStringMethod, []);
				}
			} catch (e:Dynamic) {
				// Fall through to default
			}
		}

		// Default conversion
		return Std.string(value);
	}

	/**
	 * Find the best operator method based on actual operand types
	 */
	private function findBestOperatorMethod(op:String, lhs:Dynamic, rhs:Dynamic):Null<ImplMethodInfo> {
		var targetMetadata = operatorSymbolToMetadata(op);
		if (targetMetadata == null) return null;

		var candidates:Array<ImplMethodInfo> = [];

		// Collect all methods that match the operator
		for (key => info in operatorCache) {
			if (info.operatorName == targetMetadata) {
				candidates.push(info);
			}
		}

		if (candidates.length == 0) return null;
		if (candidates.length == 1) return candidates[0];

		// Score candidates based on type compatibility
		var bestCandidate:ImplMethodInfo = null;
		var bestScore = -1;

		for (candidate in candidates) {
			var score = scoreOperatorMethod(candidate, lhs, rhs);
			if (score > bestScore) {
				bestScore = score;
				bestCandidate = candidate;
			}
		}

		return bestCandidate;
	}

	/**
	 * Score how well an operator method matches the given operands based on actual type signatures.
	 */
	private function scoreOperatorMethod(method:ImplMethodInfo, lhs:Dynamic, rhs:Dynamic):Int {
		// Parse the method type signature to get parameter types
		var paramTypes = parseMethodParameterTypes(method.type);
		if (paramTypes == null || paramTypes.length == 0) {
			return -100; // Cannot use this method
		}

		var score = 0;

		// For binary operators, check if the second parameter type matches the RHS operand
		if (rhs != null && paramTypes.length >= 2) {
			var expectedRhsType = paramTypes[1]; // Second parameter after 'this'
			var actualRhsType = getValueTypeName(rhs);

			// Exact type match gets highest score
			if (expectedRhsType == actualRhsType) {
				score += 100;
			}
			// Compatible type promotions
			else if (areTypesCompatible(actualRhsType, expectedRhsType)) {
				score += 50;
			}
			// Abstract type matches (like yutautil.Num)
			else if (expectedRhsType == abstractPath && Std.isOfType(rhs, yutautil.typeregistry.AbstractValue)) {
				score += 75;
			}
			// No match
			else {
				score -= 50;
			}
		}

		// Prefer non-reverse operators when abstract is on left side
		var methodName = method.name.toLowerCase();
		if (methodName.indexOf("reverse") >= 0) {
			score -= 10;
		}

		return score;
	}

	/**
	 * Check if a method can handle the given operand types.
	 */
	private function canMethodHandleTypes(method:ImplMethodInfo, lhsType:String, rhsType:String):Bool {
		var methodName = method.name.toLowerCase();

		// Check if method name suggests compatibility with rhsType
		if (rhsType != null) {
			var rhsLower = rhsType.toLowerCase();
			// Remove package names for comparison
			if (rhsLower.indexOf('.') >= 0) {
				rhsLower = rhsLower.substring(rhsLower.lastIndexOf('.') + 1);
			}

			if (rhsLower == "int" && methodName.indexOf("int") >= 0 && methodName.indexOf("int64") == -1) {
				return true;
			} else if (rhsLower == "float" && methodName.indexOf("float") >= 0) {
				return true;
			} else if (rhsLower == "string" && methodName.indexOf("string") >= 0) {
				return true;
			} else if (methodName == "add" || methodName == "subtract" || methodName == "multiply" || methodName == "divide") {
				// Generic methods can handle any numeric type
				return rhsLower == "int" || rhsLower == "float" || rhsLower == "uint";
			}
		}

		return false;
	}

	/**
	 * Parse method type signature to extract parameter types.
	 * E.g., "(this : Float, rhs : Int) -> yutautil.Num" returns ["Float", "Int"]
	 */
	private function parseMethodParameterTypes(typeSignature:String):Null<Array<String>> {
		if (typeSignature == null) return null;

		// Find the parameter list between first ( and )
		var startParen = typeSignature.indexOf("(");
		var endParen = typeSignature.indexOf(")");
		if (startParen == -1 || endParen == -1 || endParen <= startParen) {
			return null;
		}

		var paramString = StringTools.trim(typeSignature.substring(startParen + 1, endParen));
		if (paramString == "") return [];

		var params = paramString.split(",");
		var types:Array<String> = [];

		for (param in params) {
			param = StringTools.trim(param);
			// Extract type after " : "
			var colonIndex = param.indexOf(" : ");
			if (colonIndex >= 0) {
				var type = StringTools.trim(param.substring(colonIndex + 3));
				types.push(type);
			}
		}

		return types;
	}

	/**
	 * Get a normalized type name for a runtime value.
	 */
	private function getValueTypeName(value:Dynamic):String {
		if (value == null) return "Dynamic";

		var valueType = Type.typeof(value);
		return switch (valueType) {
			case TInt: "Int";
			case TFloat: "Float";
			case TBool: "Bool";
			case TClass(String): "String";
			case TClass(Array): "Array";
			case TClass(c):
				var className = Type.getClassName(c);
				if (className != null) className else "Dynamic";
			case TEnum(e):
				var enumName = Type.getEnumName(e);
				if (enumName != null) enumName else "Dynamic";
			case _: "Dynamic";
		};
	}

	/**
	 * Check if two types are compatible (including promotions like Int -> Float).
	 */
	private function areTypesCompatible(actualType:String, expectedType:String):Bool {
		if (actualType == expectedType) return true;

		// Type promotions
		return switch ([actualType, expectedType]) {
			case ["Int", "Float"]: true; // Int can be promoted to Float
			case ["Int", "haxe.Int64"]: true; // Int can be promoted to Int64
			case ["UInt", "Int"]: true; // UInt can be treated as Int
			case ["UInt", "Float"]: true; // UInt can be promoted to Float
			case _: false;
		};
	}

	/**
	 * Preserve numeric type of a Dynamic value.
	 * On Haxe cpp target, Dynamic values can lose their numeric type
	 * when passing through function boundaries or string interpolation.
	 * This method ensures the value retains its proper numeric type.
	 */
	private static function preserveNumericType(value:Dynamic):Dynamic {
		if (value == null) return value;
		var vt = Type.typeof(value);
		switch (vt) {
			case TInt, TFloat, TBool:
				return value; // Already correct type
			case TClass(c):
				if (c == String) {
					// A numeric value may have been converted to String by cpp Dynamic boxing
					var str:String = cast value;
					var parsedInt = Std.parseInt(str);
					if (parsedInt != null && Std.string(parsedInt) == str) {
						return parsedInt;
					}
					var parsedFloat = Std.parseFloat(str);
					if (!Math.isNaN(parsedFloat) && Std.string(parsedFloat) == str) {
						return parsedFloat;
					}
				}
				return value;
			default:
				return value;
		}
	}
}

// ===================== Supporting Types =====================

/**
 * Info about a @:from or @:to conversion.
 */
typedef ConversionEntry = {
	typeName:String,
	?fieldName:String,
	?fieldType:String
}
