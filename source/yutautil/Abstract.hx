package yutautil;

import yutautil.typeregistry.AbstractInterpreter;
import yutautil.typeregistry.AbstractValue;

/**
 * A runtime representation of a Haxe abstract type that holds both type metadata
 * AND a current value. Operator overloads dispatch through the abstract's interpreter,
 * so an `Abstract` behaves like the real abstract in expressions.
 *
 * Explicitly constructed with a type path string.
 * Values are stored via `setValue()` or the two-argument constructor.
 * `@:from AbstractValue` enables implicit construction from wrapped values.
 * `@:to Dynamic` enables implicit unwrapping to the stored raw value.
 * Operator overloads dispatch through the abstract's interpreter using the stored value.
 *
 * Usage:
 * ```haxe
 * var num = new Abstract("yutautil.Num", 42);  // Num wrapping 42
 * var result = num + 10;                        // operator dispatch -> 52
 * trace(num.name);                              // "Num"
 * trace(num.canConvertTo(Float));                // true (TypeRef accepts Class)
 * trace(num.canConvertTo("Int"));                // true (TypeRef accepts String)
 * ```
 */
abstract Abstract(AbstractRuntimeInfo) from AbstractRuntimeInfo {
	/**
	 * Construct an Abstract from a type path string with an optional initial value.
	 *
	 * @param typePath Full Haxe type path (e.g. "yutautil.Num") or simple name
	 * @param initialValue Optional value to store; will be validated against @:from rules
	 * @throws String if the abstract type is not found or initialValue is incompatible
	 */
	public inline function new(typePath:String, ?initialValue:Dynamic) {
		this = new AbstractRuntimeInfo(typePath, initialValue);
	}

	/**
	 * Implicit conversion from an AbstractValue.
	 * Constructs an Abstract using the AbstractValue's interpreter context and raw value.
	 */
	@:from
	public static function fromAbstractValue(av:AbstractValue):Abstract {
		return cast new AbstractRuntimeInfo(av.interpreter.abstractPath, av.rawValue);
	}

	/**
	 * Implicit conversion to Dynamic.
	 * Returns the stored raw value for use in dynamic contexts.
	 */
	@:to
	public inline function toDynamic():Dynamic {
		return this.value;
	}

	// ===================== Property Accessors =====================

	/** The abstract's simple name (e.g. "Num") */
	public var name(get, never):String;

	inline function get_name():String
		return this.name;

	/** The abstract's full type path (e.g. "yutautil.Num") */
	public var path(get, never):String;

	inline function get_path():String
		return this.path;

	/** The underlying type name (e.g. "Float") */
	public var underlyingType(get, never):String;

	inline function get_underlyingType():String
		return this.underlyingType;

	/** Whether the abstract has generic type parameters */
	public var isGeneric(get, never):Bool;

	inline function get_isGeneric():Bool
		return this.isGeneric;

	/** Generic type parameter names */
	public var typeParams(get, never):Array<String>;

	inline function get_typeParams():Array<String>
		return this.typeParams;

	/** Whether the abstract has an impl class resolved at runtime */
	public var hasImpl(get, never):Bool;

	inline function get_hasImpl():Bool
		return this.hasImpl;

	/** The backing AbstractInterpreter for advanced operations */
	public var interpreter(get, never):AbstractInterpreter;

	inline function get_interpreter():AbstractInterpreter
		return this.interpreter;

	/** All @:from conversion entries */
	public var fromConversions(get, never):Array<ConversionInfo>;

	inline function get_fromConversions():Array<ConversionInfo>
		return this.fromConversions;

	/** All @:to conversion entries */
	public var toConversions(get, never):Array<ConversionInfo>;

	inline function get_toConversions():Array<ConversionInfo>
		return this.toConversions;

	/** All instance (non-static) methods */
	public var methods(get, never):Array<MethodInfo>;

	inline function get_methods():Array<MethodInfo>
		return this.methods;

	/** All static methods */
	public var staticMethods(get, never):Array<MethodInfo>;

	inline function get_staticMethods():Array<MethodInfo>
		return this.staticMethods;

	/** All operator overload symbols */
	public var operators(get, never):Array<String>;

	inline function get_operators():Array<String>
		return this.operators;

	/** The currently stored raw value */
	public var value(get, never):Dynamic;

	inline function get_value():Dynamic
		return this.value;

	// ===================== Conversion & Wrapping =====================

	/**
	 * Check if a value can be implicitly converted into this abstract type.
	 * Returns true if the value matches the underlying type or any @:from conversion.
	 */
	public inline function canAccept(value:Dynamic):Bool {
		return this.canAccept(value);
	}

	/**
	 * Check if this abstract can be implicitly converted to the given target type.
	 * Accepts a String type name or a Class<Dynamic> via TypeRef.
	 */
	public inline function canConvertTo(target:TypeRef):Bool {
		return this.canConvertTo(cast target);
	}

	/**
	 * Convert a value into this abstract type via @:from conversion.
	 * Returns an AbstractValue wrapping the (possibly converted) value.
	 * Returns null if no conversion is possible.
	 */
	public inline function convert(value:Dynamic):AbstractValue {
		return this.convert(value);
	}

	/**
	 * Convert this abstract value to a target type via @:to conversion.
	 * Accepts a String type name or a Class<Dynamic> via TypeRef.
	 * Returns the converted value, or null if conversion is not possible.
	 */
	public inline function convertValueTo(value:Dynamic, targetType:TypeRef):Dynamic {
		return this.convertValueTo(value, cast targetType);
	}

	/**
	 * Wrap a raw value as an AbstractValue of this abstract type.
	 * Performs a compatibility check first; returns null if incompatible.
	 */
	public inline function wrap(value:Dynamic):AbstractValue {
		return this.wrap(value);
	}

	/**
	 * Force-wrap a value as this abstract type (no compatibility check).
	 */
	public inline function forceWrap(value:Dynamic):AbstractValue {
		return this.forceWrap(value);
	}

	/**
	 * Store a new value into this Abstract.
	 * Validates via @:from rules and throws if incompatible.
	 */
	public inline function setValue(val:Dynamic):Void {
		this.setValue(val);
	}

	/**
	 * Get the stored value unwrapped to its raw form.
	 */
	public inline function unwrap():Dynamic {
		return this.value;
	}

	// ===================== Method & Operator Dispatch =====================

	/**
	 * Call an instance method on a value interpreted as this abstract.
	 *
	 * @param value The value (raw or wrapped)
	 * @param methodName Method name
	 * @param args Arguments (NOT including `this`)
	 */
	public inline function callMethod(value:Dynamic, methodName:String, args:Array<Dynamic>):Dynamic {
		return this.callMethod(value, methodName, args);
	}

	/**
	 * Call a static method on this abstract type.
	 */
	public inline function callStaticMethod(methodName:String, args:Array<Dynamic>):Dynamic {
		return this.callStaticMethod(methodName, args);
	}

	/**
	 * Apply an operator overload.
	 */
	public inline function applyOperator(opSymbol:String, lhs:Dynamic, rhs:Dynamic = null):Dynamic {
		return this.applyOperator(opSymbol, lhs, rhs);
	}

	// ===================== Introspection =====================

	/**
	 * Check if a specific method exists on this abstract.
	 */
	public inline function hasMethod(methodName:String):Bool {
		return this.hasMethod(methodName);
	}

	/**
	 * Check if a specific operator is overloaded on this abstract.
	 */
	public inline function hasOperator(opSymbol:String):Bool {
		return this.hasOperator(opSymbol);
	}

	/**
	 * Get a human-readable description of this abstract type and its capabilities.
	 */
	public inline function describe():String {
		return this.describe();
	}

	/**
	 * String representation (explicit, not implicit).
	 */
	public inline function toString():String {
		return this.toString();
	}

	// ===================== Helper =====================

	/**
	 * Extract the raw value from a Dynamic that might be an Abstract or AbstractValue.
	 */
	private static function extractRaw(val:Dynamic):Dynamic {
		if (Std.isOfType(val, AbstractRuntimeInfo))
			return (cast(val, AbstractRuntimeInfo)).value;
		if (Std.isOfType(val, AbstractValue))
			return (cast(val, AbstractValue)).rawValue;
		return val;
	}

	// ===================== Operator Overloads =====================
	// All operators dispatch through the interpreter using the stored value.
	// Reverse (static) variants handle cases where Abstract is on the right-hand side.

	// ---- Arithmetic (Abstract on LHS) ----

	@:op(A + B)
	public function add(rhs:Dynamic):Dynamic
		return this.applyOperator("+", this.value, extractRaw(rhs));

	@:op(A - B)
	public function sub(rhs:Dynamic):Dynamic
		return this.applyOperator("-", this.value, extractRaw(rhs));

	@:op(A * B)
	public function mul(rhs:Dynamic):Dynamic
		return this.applyOperator("*", this.value, extractRaw(rhs));

	@:op(A / B)
	public function div(rhs:Dynamic):Dynamic
		return this.applyOperator("/", this.value, extractRaw(rhs));

	@:op(A % B)
	public function modulo(rhs:Dynamic):Dynamic
		return this.applyOperator("%", this.value, extractRaw(rhs));

	// ---- Arithmetic Reverse (Abstract on RHS) ----

	@:op(A + B)
	public static function addReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("+", lhs, info.value);
	}

	@:op(A - B)
	public static function subReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("-", lhs, info.value);
	}

	@:op(A * B)
	public static function mulReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("*", lhs, info.value);
	}

	@:op(A / B)
	public static function divReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("/", lhs, info.value);
	}

	@:op(A % B)
	public static function modReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("%", lhs, info.value);
	}

	// ---- Unary ----

	@:op(-A)
	public function neg():Dynamic
		return this.applyOperator("-", this.value, null);

	@:op(++A)
	public function preIncrement():Abstract {
		var result = this.applyOperator("+", this.value, 1);
		this.setValue(result);
		return cast this;
	}

	@:op(A++)
	public function postIncrement():Dynamic {
		var old = this.value;
		var result = this.applyOperator("+", this.value, 1);
		this.setValue(result);
		return old;
	}

	@:op(--A)
	public function preDecrement():Abstract {
		var result = this.applyOperator("-", this.value, 1);
		this.setValue(result);
		return cast this;
	}

	@:op(A--)
	public function postDecrement():Dynamic {
		var old = this.value;
		var result = this.applyOperator("-", this.value, 1);
		this.setValue(result);
		return old;
	}

	// ---- Comparison (Abstract on LHS) ----

	@:op(A == B)
	public function eq(rhs:Dynamic):Bool
		return this.applyOperator("==", this.value, extractRaw(rhs));

	@:op(A != B)
	public function neq(rhs:Dynamic):Bool
		return this.applyOperator("!=", this.value, extractRaw(rhs));

	@:op(A < B)
	public function lt(rhs:Dynamic):Bool
		return this.applyOperator("<", this.value, extractRaw(rhs));

	@:op(A <= B)
	public function lte(rhs:Dynamic):Bool
		return this.applyOperator("<=", this.value, extractRaw(rhs));

	@:op(A > B)
	public function gt(rhs:Dynamic):Bool
		return this.applyOperator(">", this.value, extractRaw(rhs));

	@:op(A >= B)
	public function gte(rhs:Dynamic):Bool
		return this.applyOperator(">=", this.value, extractRaw(rhs));

	// ---- Comparison Reverse (Abstract on RHS) ----

	@:op(A == B)
	public static function eqReverse(lhs:Dynamic, rhs:Abstract):Bool {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("==", lhs, info.value);
	}

	@:op(A != B)
	public static function neqReverse(lhs:Dynamic, rhs:Abstract):Bool {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("!=", lhs, info.value);
	}

	@:op(A < B)
	public static function ltReverse(lhs:Dynamic, rhs:Abstract):Bool {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("<", lhs, info.value);
	}

	@:op(A <= B)
	public static function lteReverse(lhs:Dynamic, rhs:Abstract):Bool {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("<=", lhs, info.value);
	}

	@:op(A > B)
	public static function gtReverse(lhs:Dynamic, rhs:Abstract):Bool {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator(">", lhs, info.value);
	}

	@:op(A >= B)
	public static function gteReverse(lhs:Dynamic, rhs:Abstract):Bool {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator(">=", lhs, info.value);
	}

	// ---- Compound Assignment (Abstract on LHS) ----

	@:op(A += B)
	public function addAssign(rhs:Dynamic):Abstract {
		this.setValue(this.applyOperator("+", this.value, extractRaw(rhs)));
		return cast this;
	}

	@:op(A -= B)
	public function subAssign(rhs:Dynamic):Abstract {
		this.setValue(this.applyOperator("-", this.value, extractRaw(rhs)));
		return cast this;
	}

	@:op(A *= B)
	public function mulAssign(rhs:Dynamic):Abstract {
		this.setValue(this.applyOperator("*", this.value, extractRaw(rhs)));
		return cast this;
	}

	@:op(A /= B)
	public function divAssign(rhs:Dynamic):Abstract {
		this.setValue(this.applyOperator("/", this.value, extractRaw(rhs)));
		return cast this;
	}

	@:op(A %= B)
	public function modAssign(rhs:Dynamic):Abstract {
		this.setValue(this.applyOperator("%", this.value, extractRaw(rhs)));
		return cast this;
	}

	// ---- Compound Assignment Reverse (Abstract on RHS) ----

	@:op(A += B)
	public static function addAssignReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("+", lhs, info.value);
	}

	@:op(A -= B)
	public static function subAssignReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("-", lhs, info.value);
	}

	@:op(A *= B)
	public static function mulAssignReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("*", lhs, info.value);
	}

	@:op(A /= B)
	public static function divAssignReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("/", lhs, info.value);
	}

	@:op(A %= B)
	public static function modAssignReverse(lhs:Dynamic, rhs:Abstract):Dynamic {
		var info:AbstractRuntimeInfo = cast rhs;
		return info.applyOperator("%", lhs, info.value);
	}
}

// ===================== Backing Class =====================

/**
 * The runtime data object backing the `Abstract` abstract type.
 * Holds structured information about an abstract type's conversions,
 * methods, operators, and provides dispatch capabilities.
 */
class AbstractRuntimeInfo {
	// ---- Core identity ----

	/** The abstract's simple name (e.g. "Num") */
	public var name(default, null):String;

	/** The abstract's full type path (e.g. "yutautil.Num") */
	public var path(default, null):String;

	/** The underlying type name (e.g. "Float") */
	public var underlyingType(default, null):String;

	/** Whether the abstract has generic type parameters */
	public var isGeneric(default, null):Bool;

	/** Generic type parameter names */
	public var typeParams(default, null):Array<String>;

	/** Whether the abstract has an impl class resolved at runtime */
	public var hasImpl(default, null):Bool;

	/** The backing AbstractInterpreter */
	public var interpreter(default, null):AbstractInterpreter;

	/** The currently stored raw value (underlying type representation) */
	public var value(default, null):Dynamic;

	// ---- Structured conversion info ----

	/** All @:from conversions (types that can be implicitly converted INTO this abstract) */
	public var fromConversions(default, null):Array<ConversionInfo>;

	/** All @:to conversions (types this abstract can be implicitly converted TO) */
	public var toConversions(default, null):Array<ConversionInfo>;

	// ---- Structured method info ----

	/** Instance methods (require a `this` argument) */
	public var methods(default, null):Array<MethodInfo>;

	/** Static methods (no `this` argument) */
	public var staticMethods(default, null):Array<MethodInfo>;

	/** Operator overload symbols */
	public var operators(default, null):Array<String>;

	// ===================== Constructor =====================

	/**
	 * Build the runtime info for an abstract type.
	 *
	 * @param typePath The full Haxe type path or simple name
	 * @param initialValue Optional value to store; validated against @:from rules
	 * @throws String if the abstract type is not found or initialValue is incompatible
	 */
	public function new(typePath:String, ?initialValue:Dynamic) {
		interpreter = AbstractInterpreter.forAbstract(typePath);
		if (interpreter == null) {
			throw 'Abstract type not found: $typePath';
		}

		// Copy core identity from the interpreter
		name = interpreter.abstractName;
		path = interpreter.abstractPath;
		underlyingType = interpreter.underlyingType;
		isGeneric = interpreter.isGeneric;
		typeParams = interpreter.typeParams != null ? interpreter.typeParams.copy() : [];
		hasImpl = interpreter.hasImpl;

		// Store initial value if provided, otherwise use default for underlying type
		if (initialValue != null) {
			setValue(initialValue);
		} else {
			value = getDefaultForUnderlying();
		}

		// Build structured info
		buildConversionInfo();
		buildMethodInfo();
	}

	// ===================== Conversion Info =====================

	private function buildConversionInfo():Void {
		fromConversions = [];
		toConversions = [];

		// Build from-conversion info
		var rawFrom = interpreter.getFromTypes();
		for (entry in rawFrom) {
			fromConversions.push({
				typeName: entry.typeName,
				fieldName: entry.fieldName,
				fieldType: entry.fieldType,
				isStatic: true // @:from functions are always static on the impl
			});
		}

		// Build to-conversion info
		var rawTo = interpreter.getToTypes();
		for (entry in rawTo) {
			toConversions.push({
				typeName: entry.typeName,
				fieldName: entry.fieldName,
				fieldType: entry.fieldType,
				isStatic: false // @:to functions take `this` as first arg
			});
		}
	}

	// ===================== Method Info =====================

	private function buildMethodInfo():Void {
		methods = [];
		staticMethods = [];
		operators = [];

		var allMethodNames = interpreter.getMethodNames();
		for (methodName in allMethodNames) {
			var info:MethodInfo = {
				name: methodName,
				isStatic: false, // Instance methods by default from getMethodNames
				isOperator: false,
				operatorSymbol: null
			};
			methods.push(info);
		}

		var allOps = interpreter.getOperatorNames();
		for (opName in allOps) {
			operators.push(opName);
		}

		// Extract static methods from impl fields that are public and non-operator
		// and don't take `this` as first arg (i.e. are truly static)
		// This is best-effort since we can't always distinguish at runtime
		if (interpreter.implClass != null) {
			var implFields = Type.getClassFields(interpreter.implClass);
			for (fieldName in implFields) {
				var field = Reflect.field(interpreter.implClass, fieldName);
				if (field != null && Reflect.isFunction(field)) {
					// Skip internal names and already-tracked methods
					if (StringTools.startsWith(fieldName, "_hx_")) continue;
					if (StringTools.startsWith(fieldName, "get_")) continue;
					if (StringTools.startsWith(fieldName, "set_")) continue;

					var alreadyTracked = false;
					for (m in methods) {
						if (m.name == fieldName) {
							alreadyTracked = true;
							break;
						}
					}
					if (!alreadyTracked) {
						staticMethods.push({
							name: fieldName,
							isStatic: true,
							isOperator: false,
							operatorSymbol: null
						});
					}
				}
			}
		}
	}

	/**
	 * Set a new value, validated via @:from rules.
	 * Throws if the value is incompatible with this abstract's @:from conversions
	 * and does not match the underlying type.
	 */
	public function setValue(val:Dynamic):Void {
		if (val == null) {
			value = null;
			return;
		}

		// If it's already an AbstractValue of the same abstract, unwrap it
		if (Std.isOfType(val, AbstractValue)) {
			var absVal:AbstractValue = cast val;
			if (absVal.interpreter.abstractPath == interpreter.abstractPath) {
				value = absVal.rawValue;
				return;
			}
		}

		// Check if the value is directly compatible (matches underlying type)
		if (interpreter.matchesUnderlyingType(val)) {
			value = val;
			return;
		}

		// Try @:from conversion
		if (interpreter.canConvertFrom(val)) {
			var converted = interpreter.applyFromConversion(val);
			if (converted != null) {
				value = converted.rawValue;
				return;
			}
		}

		throw 'Abstract($name): Cannot accept value of type ${Type.typeof(val)} - no matching @:from conversion';
	}

	/**
	 * Get a default value for the underlying type.
	 */
	private function getDefaultForUnderlying():Dynamic {
		if (underlyingType == null) return null;
		var normalized = underlyingType.toLowerCase();
		var lastDot = normalized.lastIndexOf(".");
		if (lastDot >= 0) normalized = normalized.substring(lastDot + 1);

		return switch (normalized) {
			case "int" | "integer": 0;
			case "float" | "number" | "double": 0.0;
			case "string": "";
			case "bool" | "boolean": false;
			case "array": [];
			case _: null;
		};
	}

	// ===================== Conversion Operations =====================

	/**
	 * Check if a value can be implicitly accepted by this abstract.
	 * True if the value matches the underlying type or any @:from conversion.
	 */
	public function canAccept(value:Dynamic):Bool {
		return interpreter.isValueCompatible(value);
	}

	/**
	 * Check if this abstract can be implicitly converted to the given target type.
	 */
	public function canConvertTo(targetTypeName:String):Bool {
		return interpreter.canConvertTo(targetTypeName);
	}

	/**
	 * Convert a value into this abstract via @:from conversion.
	 * Returns a wrapped AbstractValue, or null if not convertible.
	 */
	public function convert(value:Dynamic):AbstractValue {
		return interpreter.applyFromConversion(value);
	}

	/**
	 * Convert a value of this abstract to a target type via @:to conversion.
	 */
	public function convertValueTo(value:Dynamic, targetTypeName:String):Dynamic {
		return interpreter.applyToConversion(value, targetTypeName);
	}

	/**
	 * Wrap a value as this abstract type (with compatibility check).
	 */
	public function wrap(value:Dynamic):AbstractValue {
		return interpreter.wrapValue(value);
	}

	/**
	 * Force-wrap a value as this abstract type (no check).
	 */
	public function forceWrap(value:Dynamic):AbstractValue {
		return interpreter.forceWrap(value);
	}

	// ===================== Method/Operator Dispatch =====================

	/**
	 * Call an instance method on a value interpreted as this abstract.
	 */
	public function callMethod(value:Dynamic, methodName:String, args:Array<Dynamic>):Dynamic {
		return interpreter.callMethod(value, methodName, args);
	}

	/**
	 * Call a static method on this abstract.
	 */
	public function callStaticMethod(methodName:String, args:Array<Dynamic>):Dynamic {
		return interpreter.callStaticMethod(methodName, args);
	}

	/**
	 * Apply an operator overload.
	 */
	public function applyOperator(opSymbol:String, lhs:Dynamic, rhs:Dynamic = null):Dynamic {
		return interpreter.applyOperator(opSymbol, lhs, rhs);
	}

	// ===================== Introspection =====================

	/**
	 * Check if a method exists on this abstract.
	 */
	public function hasMethod(methodName:String):Bool {
		return interpreter.hasMethod(methodName);
	}

	/**
	 * Check if an operator is overloaded.
	 */
	public function hasOperator(opSymbol:String):Bool {
		return interpreter.hasOperator(opSymbol);
	}

	/**
	 * Get a human-readable description of this abstract and all its capabilities.
	 */
	public function describe():String {
		var sb = new StringBuf();
		sb.add('Abstract($name)\n');
		sb.add('  Path: $path\n');
		sb.add('  Underlying: $underlyingType\n');
		sb.add('  Has impl: $hasImpl\n');
		sb.add('  Generic: $isGeneric\n');

		if (isGeneric && typeParams.length > 0) {
			sb.add('  Type params: <${typeParams.join(", ")}>\n');
		}

		if (fromConversions.length > 0) {
			sb.add('  @:from conversions:\n');
			for (c in fromConversions) {
				sb.add('    - ${c.typeName}');
				if (c.fieldName != null) sb.add(' via ${c.fieldName}()');
				sb.add(' [${c.isStatic ? "static" : "instance"}]\n');
			}
		}

		if (toConversions.length > 0) {
			sb.add('  @:to conversions:\n');
			for (c in toConversions) {
				sb.add('    - ${c.typeName}');
				if (c.fieldName != null) sb.add(' via ${c.fieldName}()');
				sb.add(' [${c.isStatic ? "static" : "instance"}]\n');
			}
		}

		if (methods.length > 0) {
			sb.add('  Methods:\n');
			for (m in methods) {
				sb.add('    - ${m.name}${m.isStatic ? " [static]" : ""}\n');
			}
		}

		if (staticMethods.length > 0) {
			sb.add('  Static methods:\n');
			for (m in staticMethods) {
				sb.add('    - ${m.name}\n');
			}
		}

		if (operators.length > 0) {
			sb.add('  Operators: ${operators.join(", ")}\n');
		}

		return sb.toString();
	}

	public function toString():String {
		return '${name}(${value})';
	}
}

// ===================== Supporting Typedefs =====================

/**
 * Structured info about a @:from or @:to conversion on an abstract.
 */
typedef ConversionInfo = {
	/** The source/target type name */
	typeName:String,
	/** The conversion function name on the _Impl_ class (null if implicit) */
	?fieldName:String,
	/** The conversion function's type signature */
	?fieldType:String,
	/** Whether this conversion is static (true for @:from, false for @:to) */
	isStatic:Bool
}

/**
 * Structured info about a method on an abstract.
 */
typedef MethodInfo = {
	/** Method name */
	name:String,
	/** Whether the method is static */
	isStatic:Bool,
	/** Whether the method is an operator overload */
	isOperator:Bool,
	/** The operator symbol if isOperator is true */
	?operatorSymbol:String
}

/**
 * A lightweight abstract over String that accepts either a String type name
 * or a Class<Dynamic>, normalizing to a String for type-name-based lookups.
 *
 * Usage:
 * ```haxe
 * abstract.canConvertTo("Float");          // String literal
 * abstract.canConvertTo(Float);            // Class reference -> "Float"
 * abstract.canConvertTo(flixel.FlxSprite); // -> "flixel.FlxSprite"
 * ```
 */
@:forward
abstract TypeRef(String) from String to String {
	/**
	 * Implicit conversion from a Class<Dynamic> to a TypeRef.
	 * Extracts the fully qualified class name.
	 */
	@:from
	public static function fromClass(cls:Class<Dynamic>):TypeRef {
		var className = Type.getClassName(cls);
		return cast(className != null ? className : "Dynamic");
	}

	/**
	 * Get the underlying String type name.
	 */
	public inline function toString():String {
		return this;
	}
}
