



package yutautil;

import yutautil.Abstract.TypeRef;
import yutautil.typeregistry.AbstractInterpreter;
import yutautil.typeregistry.AbstractValue;
import yutautil.typeregistry.BuildDataLoader;

/**
 * Classification of a type string for dispatch.
 */
enum TypeKind {
	/** Primitive types: Int, Float, String, Bool, Void, Dynamic */
	Primitive;

	/** A class or interface type (possibly with generics stripped for resolution) */
	ClassType;

	/** An anonymous structure: { name:String, ?age:Int } */
	Structure;

	/** An abstract type with @:from/@:to conversions */
	AbstractType;

	/** A typedef that resolves to another type */
	Typedef;

	/** A function signature: (Int, String) -> Bool or () -> Void */
	FunctionType;

	/** Array<T> */
	ArrayType;

	/** Map<K,V> or haxe.ds.Map<K,V> */
	MapType;

	/** Unknown or unresolvable type */
	Unknown;
}

/**
 * Parsed field from an anonymous structure type string.
 */
typedef StructField = {
	/** The field name */
	name:String,

	/** The field type string */
	type:String,

	/** Whether this field is optional (prefixed with ?) */
	optional:Bool
}

/**
 * Global type compatibility handler for the Mixtape Engine.
 *
 * Provides comprehensive type checking that works with:
 * - Plain classes (with inheritance checking)
 * - Abstract types (checking @:from and @:to conversions via build data)
 * - Typedefs (resolving to underlying types and recursing)
 * - Anonymous structures (field-by-field matching with optional support)
 * - Function types (existence check only for now)
 * - Arrays and Maps (base type matching, generic-aware)
 * - Primitive types (Int, Float, String, Bool with standard promotions)
 *
 * Usage:
 * ```haxe
 * // Check if Int can be assigned where Num is expected
 * TypeHandler.isCompatible("Int", "yutautil.Num");  // true (Num has @:from Int)
 *
 * // Check if Num can output a Float
 * TypeHandler.canAbstractOutputType("yutautil.Num", "Float");  // true (@:to Float)
 *
 * // Check structure compatibility
 * TypeHandler.isCompatible("{ name:String, age:Int }", "{ name:String, ?age:Int }");  // true
 *
 * // Function check
 * TypeHandler.isFunction("(Int) -> String");  // true
 * ```
 */
class TypeHandler {
	// ===================== Primitive Set =====================

	private static var primitives:Map<String, Bool> = [
		"int" => true, "float" => true, "string" => true, "bool" => true,
		"boolean" => true, "void" => true, "dynamic" => true, "null" => true,
		"uint" => true, "int64" => true, "single" => true, "number" => true
	];

	// ===================== Main Entry Point =====================

	/**
	 * Check if a value of `sourceType` can be used where `targetType` is expected.
	 *
	 * This is the primary entry point. It classifies both types and dispatches
	 * to the appropriate compatibility checker.
	 *
	 * @param sourceType The type of the value being assigned/passed
	 * @param targetType The type that is expected at the destination
	 * @return true if the source can be used as the target
	 */
	public static function isCompatible(sourceType:TypeRef, targetType:TypeRef):Bool {
		if (sourceType == null || targetType == null) return true;

		// Normalize whitespace
		sourceType = StringTools.trim(sourceType);
		targetType = StringTools.trim(targetType);

		// Exact match (fast path)
		if (sourceType == targetType) return true;

		// Case-insensitive exact match
		if (sourceType.toLowerCase() == targetType.toLowerCase()) return true;

		// Dynamic accepts/produces anything
		if (targetType.toLowerCase() == "dynamic" || sourceType.toLowerCase() == "dynamic") return true;

		// Null is assignable to any nullable type
		if (sourceType.toLowerCase() == "null") return true;

		// Void compatibility
		if (sourceType.toLowerCase() == "void" || targetType.toLowerCase() == "void") return sourceType.toLowerCase() == targetType.toLowerCase();

		// Classify both types
		var sourceKind = classifyType(sourceType);
		var targetKind = classifyType(targetType);

		// --- Primitive promotions ---
		if (sourceKind == Primitive && targetKind == Primitive) {
			return arePrimitivesCompatible(sourceType, targetType);
		}

		// --- Function type: just check if both are functions ---
		if (targetKind == FunctionType) {
			return sourceKind == FunctionType;
		}

		// --- Target is an abstract: check @:from ---
		if (targetKind == AbstractType) {
			return canAssignToAbstract(sourceType, targetType);
		}

		// --- Source is an abstract: check @:to ---
		if (sourceKind == AbstractType) {
			return canAbstractOutputType(sourceType, targetType);
		}

		// --- Target is a typedef: resolve and recurse ---
		if (targetKind == Typedef) {
			var resolved = resolveTypedef(targetType);
			if (resolved != null && resolved != targetType) {
				return isCompatible(sourceType, resolved);
			}
		}

		// --- Source is a typedef: resolve and recurse ---
		if (sourceKind == Typedef) {
			var resolved = resolveTypedef(sourceType);
			if (resolved != null && resolved != sourceType) {
				return isCompatible(resolved, targetType);
			}
		}

		// --- Structure matching ---
		if (targetKind == Structure) {
			if (sourceKind == Structure) {
				return isStructureCompatible(sourceType, targetType);
			}
			// A class might satisfy a structural type (duck typing)
			return false;
		}

		// --- Array matching ---
		if (targetKind == ArrayType && sourceKind == ArrayType) {
			return areArraysCompatible(sourceType, targetType);
		}

		// --- Map matching ---
		if (targetKind == MapType && sourceKind == MapType) {
			return areMapsCompatible(sourceType, targetType);
		}

		// --- Class matching ---
		if (targetKind == ClassType && sourceKind == ClassType) {
			return isClassCompatible(sourceType, targetType);
		}

		// --- Primitive source to abstract/class target ---
		if (sourceKind == Primitive && targetKind == AbstractType) {
			return canAssignToAbstract(sourceType, targetType);
		}

		// --- Abstract source to primitive target ---
		if (sourceKind == AbstractType && targetKind == Primitive) {
			return canAbstractOutputType(sourceType, targetType);
		}

		// --- Primitive source to class target (limited: String) ---
		if (sourceKind == Primitive && targetKind == ClassType) {
			// String is a class in Haxe
			if (sourceType.toLowerCase() == "string" && stripGenerics(targetType).toLowerCase() == "string") return true;
			return false;
		}

		return false;
	}

	// ===================== Type Classification =====================

	/**
	 * Classify a type string into its kind.
	 *
	 * Detection priority:
	 * 1. Structure: starts with `{` and ends with `}`
	 * 2. Function: contains `->` (outside of structures)
	 * 3. Primitive: matches known primitive names
	 * 4. Array: starts with `Array<` or equals `Array`
	 * 5. Map: starts with `Map<` or `haxe.ds.Map<` or equals `Map`
	 * 6. Abstract: found in build data as an abstract
	 * 7. Typedef: found in build data as a typedef
	 * 8. Class: default for anything else resolvable
	 * 9. Unknown: fallback
	 */
	public static function classifyType(typeString:TypeRef):TypeKind {
		if (typeString == null || typeString.length == 0) return Unknown;

		typeString = StringTools.trim(typeString);

		// Structure: { ... }
		if (StringTools.startsWith(typeString, "{") && StringTools.endsWith(typeString, "}")) {
			return Structure;
		}

		// Function: contains -> (but not inside a structure)
		if (isFunctionType(typeString)) {
			return FunctionType;
		}

		// Primitive check (case-insensitive)
		var lower = typeString.toLowerCase();
		var baseLower = stripGenerics(typeString).toLowerCase();
		// Also strip packages for primitive check
		var lastDot = baseLower.lastIndexOf(".");
		if (lastDot >= 0) baseLower = baseLower.substring(lastDot + 1);

		if (primitives.exists(baseLower)) {
			return Primitive;
		}

		// Array
		if (baseLower == "array" || StringTools.startsWith(lower, "array<")) {
			return ArrayType;
		}

		// Map
		if (baseLower == "map" || StringTools.startsWith(lower, "map<")
			|| StringTools.startsWith(lower, "haxe.ds.map<") || baseLower == "haxe.ds.map") {
			return MapType;
		}

		// Check build data for abstract
		var strippedType = stripGenerics(typeString);
		var abstractInfo = BuildDataLoader.getAbstractInfo(strippedType);
		if (abstractInfo != null) {
			return AbstractType;
		}

		// Check build data for typedef
		var typeInfo = BuildDataLoader.getTypeInfo(strippedType);
		if (typeInfo != null && typeInfo.type == "typedef") {
			return Typedef;
		}

		// Check build data for class
		var classInfo = BuildDataLoader.getClassInfo(strippedType);
		if (classInfo != null) {
			return ClassType;
		}

		// Try resolving without package
		var simpleName = strippedType;
		var dot = simpleName.lastIndexOf(".");
		if (dot >= 0) simpleName = simpleName.substring(dot + 1);

		// Recheck with simple name
		if (BuildDataLoader.getAbstractInfo(simpleName) != null) return AbstractType;
		if (BuildDataLoader.getClassInfo(simpleName) != null) return ClassType;

		// Unknown but treat as ClassType if it looks like a type name
		if (typeString.charAt(0) == typeString.charAt(0).toUpperCase() && typeString.charAt(0) != "{") {
			return ClassType;
		}

		return Unknown;
	}

	// ===================== Primitive Compatibility =====================

	/**
	 * Check if two primitive types are compatible.
	 * Handles standard numeric promotions (Int -> Float, UInt -> Int, etc.)
	 */
	public static function arePrimitivesCompatible(source:TypeRef, target:TypeRef):Bool {
		var s = normalizePrimitive(source);
		var t = normalizePrimitive(target);

		if (s == t) return true;

		// Dynamic accepts anything
		if (t == "dynamic" || s == "dynamic") return true;

		// Numeric promotions
		if (s == "int" && (t == "float" || t == "number" || t == "single" || t == "uint")) return true;
		if (s == "uint" && (t == "int" || t == "float" || t == "number")) return true;
		if (s == "int64" && (t == "int" || t == "float")) return true;
		if (s == "float" && (t == "number" || t == "single")) return true;
		if (s == "single" && (t == "float" || t == "number" || t == "int")) return true;
		if (s == "number" && (t == "float" || t == "int")) return true;

		// Bool is not numeric-compatible
		return false;
	}

	private static function normalizePrimitive(type:String):String {
		var t = StringTools.trim(type).toLowerCase();
		var dot = t.lastIndexOf(".");
		if (dot >= 0) t = t.substring(dot + 1);

		return switch (t) {
			case "integer": "int";
			case "boolean": "bool";
			case "double": "float";
			case _: t;
		}
	}

	// ===================== Abstract Compatibility =====================

	/**
	 * Check if a value of `sourceType` can be assigned to an abstract `abstractPath`.
	 * Checks:
	 * 1. Underlying type match
	 * 2. All @:from conversions in the abstract's build data
	 */
	public static function canAssignToAbstract(sourceType:TypeRef, abstractPath:TypeRef):Bool {
		var strippedAbstract = stripGenerics(abstractPath);

		// Try AbstractInterpreter first (has runtime resolution)
		var interp = AbstractInterpreter.forAbstract(strippedAbstract);
		if (interp != null) {
			// Check underlying type
			if (interp.underlyingType != null) {
				if (isCompatible(sourceType, interp.underlyingType)) return true;
			}

			// Check @:from conversions
			var fromTypes = interp.getFromTypes();
			for (entry in fromTypes) {
				if (isCompatible(sourceType, entry.typeName)) return true;
			}
			return false;
		}

		// Fallback to build data
		return BuildDataLoader.canConvertToAbstract(sourceType, strippedAbstract);
	}

	/**
	 * Check if an abstract at `abstractPath` can output/convert to `targetType`.
	 * Checks:
	 * 1. Underlying type match
	 * 2. All @:to conversions in the abstract's build data
	 */
	public static function canAbstractOutputType(abstractPath:TypeRef, targetType:TypeRef):Bool {
		var strippedAbstract = stripGenerics(abstractPath);

		// Try AbstractInterpreter first
		var interp = AbstractInterpreter.forAbstract(strippedAbstract);
		if (interp != null) {
			// Check underlying type
			if (interp.underlyingType != null) {
				if (isCompatible(interp.underlyingType, targetType)) return true;
			}

			// Check @:to conversions
			var toTypes = interp.getToTypes();
			for (entry in toTypes) {
				if (isCompatible(entry.typeName, targetType)) return true;
			}
			return false;
		}

		// Fallback to build data
		return BuildDataLoader.canConvertFromAbstract(strippedAbstract, targetType);
	}

	// ===================== Typedef Resolution =====================

	/**
	 * Resolve a typedef to its underlying type string.
	 * Returns the underlying type, or null if not a typedef.
	 */
	public static function resolveTypedef(typedefPath:TypeRef):Null<String> {
		var stripped = stripGenerics(typedefPath);
		var info = BuildDataLoader.getTypeInfo(stripped);
		if (info != null && info.type == "typedef" && info.data != null) {
			var resolved:String = info.data.type;
			if (resolved != null) {
				return resolved;
			}
		}
		return null;
	}

	/**
	 * Check if a value type is compatible with a typedef's underlying type.
	 * Resolves the typedef and recurses into the resolved type.
	 */
	public static function isTypedefCompatible(sourceType:TypeRef, typedefPath:TypeRef):Bool {
		var resolved = resolveTypedef(typedefPath);
		if (resolved != null) {
			return isCompatible(sourceType, resolved);
		}
		return false;
	}

	// ===================== Structure Compatibility =====================

	/**
	 * Check if a source structure is compatible with a target structure.
	 * A source is compatible if it has all required (non-optional) fields of the target
	 * with compatible types.
	 *
	 * @param sourceType Structure type string like "{ name:String, age:Int }"
	 * @param targetType Structure type string like "{ name:String, ?age:Int }"
	 */
	public static function isStructureCompatible(sourceType:TypeRef, targetType:TypeRef):Bool {
		var sourceFields = parseStructureFields(sourceType);
		var targetFields = parseStructureFields(targetType);

		if (sourceFields == null || targetFields == null) return false;

		// Every required field in the target must exist in the source with a compatible type
		for (targetField in targetFields) {
			if (targetField.optional) continue; // Optional fields don't need to be present

			var found = false;
			for (sourceField in sourceFields) {
				if (sourceField.name == targetField.name) {
					// Field exists, check type compatibility
					// Strip generics from field types for non-Array/Map types
					var sourceFieldType = normalizeFieldType(sourceField.type);
					var targetFieldType = normalizeFieldType(targetField.type);

					if (!isCompatible(sourceFieldType, targetFieldType)) {
						return false; // Type mismatch on a required field
					}
					found = true;
					break;
				}
			}
			if (!found) return false; // Required field missing
		}

		return true;
	}

	/**
	 * Normalize a field type for structure matching.
	 * For non-Array/Map types, strip generics to check base type only.
	 * For Array and Map, keep generics intact.
	 */
	private static function normalizeFieldType(fieldType:String):String {
		var trimmed = StringTools.trim(fieldType);

		// Unwrap Null<T> → T
		if (StringTools.startsWith(trimmed, "Null<") && StringTools.endsWith(trimmed, ">")) {
			trimmed = trimmed.substring(5, trimmed.length - 1);
		}

		var lower = trimmed.toLowerCase();
		var baseLower = stripGenerics(trimmed).toLowerCase();
		var lastDot = baseLower.lastIndexOf(".");
		if (lastDot >= 0) baseLower = baseLower.substring(lastDot + 1);

		// Keep generics for Array and Map
		if (baseLower == "array" || baseLower == "map" || baseLower == "haxe.ds.map") {
			return trimmed;
		}

		// For other types, strip generics
		return stripGenerics(trimmed);
	}

	/**
	 * Parse a structure type string into its constituent fields.
	 *
	 * Handles:
	 * - `{ name:String, age:Int }` → [{name:"name", type:"String", optional:false}, ...]
	 * - `{ name:String, ?age:Int }` → [..., {name:"age", type:"Int", optional:true}]
	 * - Nested structures and generics within field types
	 *
	 * @return Array of StructField, or null if parsing fails
	 */
	public static function parseStructureFields(structString:TypeRef):Array<StructField> {
		if (structString == null) return null;

		structString = StringTools.trim(structString);

		// Must start with { and end with }
		if (!StringTools.startsWith(structString, "{") || !StringTools.endsWith(structString, "}")) {
			return null;
		}

		// Strip outer braces
		var inner = StringTools.trim(structString.substring(1, structString.length - 1));
		if (inner.length == 0) return []; // Empty structure

		var fields:Array<StructField> = [];

		// Split by commas, respecting nested braces/angles/parens
		var segments = splitRespectingNesting(inner, ",");

		for (segment in segments) {
			var trimmed = StringTools.trim(segment);
			if (trimmed.length == 0) continue;

			// Check for optional prefix
			var optional = false;
			if (StringTools.startsWith(trimmed, "?")) {
				optional = true;
				trimmed = trimmed.substring(1);
			}

			// Split on first colon (respecting nested types)
			var colonIdx = findFirstColon(trimmed);
			if (colonIdx < 0) continue; // Malformed

			var fieldName = StringTools.trim(trimmed.substring(0, colonIdx));
			var fieldType = StringTools.trim(trimmed.substring(colonIdx + 1));

			fields.push({
				name: fieldName,
				type: fieldType,
				optional: optional
			});
		}

		return fields;
	}

	// ===================== Class Compatibility =====================

	/**
	 * Check if sourceType is a class compatible with targetType.
	 * Uses build data for inheritance checking.
	 */
	public static function isClassCompatible(sourceType:TypeRef, targetType:TypeRef):Bool {
		var source = stripGenerics(sourceType);
		var target = stripGenerics(targetType);

		if (source == target) return true;

		// Normalize: strip package for simple comparison
		var sourceSimple = getSimpleName(source);
		var targetSimple = getSimpleName(target);
		if (sourceSimple == targetSimple) return true;

		// Check inheritance via build data
		var visited = new Map<String, Bool>();
		return checkInheritance(source, target, visited);
	}

	/**
	 * Walk the superclass chain via build data to check inheritance.
	 */
	private static function checkInheritance(currentType:String, targetType:String, visited:Map<String, Bool>):Bool {
		if (currentType == null || currentType.length == 0) return false;
		if (visited.exists(currentType)) return false;
		visited.set(currentType, true);

		var strippedCurrent = stripGenerics(currentType);
		var strippedTarget = stripGenerics(targetType);

		if (strippedCurrent == strippedTarget) return true;
		if (getSimpleName(strippedCurrent) == getSimpleName(strippedTarget)) return true;

		var classInfo = BuildDataLoader.getClassInfo(strippedCurrent);
		if (classInfo == null) {
			// Also try simple name
			classInfo = BuildDataLoader.getClassInfo(getSimpleName(strippedCurrent));
		}
		if (classInfo == null) return false;

		// Check superclass
		if (classInfo.superClass != null) {
			var superPath:String = "";
			var superPack:Array<Dynamic> = classInfo.superClass.pack;
			if (superPack != null && superPack.length > 0) {
				superPath = superPack.join(".") + "." + classInfo.superClass.name;
			} else {
				superPath = classInfo.superClass.name;
			}

			if (superPath == strippedTarget || getSimpleName(superPath) == getSimpleName(strippedTarget)) {
				return true;
			}

			if (checkInheritance(superPath, targetType, visited)) return true;
		}

		// Check interfaces
		if (classInfo.interfaces != null) {
			var interfaces:Array<Dynamic> = classInfo.interfaces;
			for (iface in interfaces) {
				var ifacePath:String = "";
				var ifacePack:Array<Dynamic> = iface.pack;
				if (ifacePack != null && ifacePack.length > 0) {
					ifacePath = ifacePack.join(".") + "." + iface.name;
				} else {
					ifacePath = iface.name;
				}

				if (ifacePath == strippedTarget || getSimpleName(ifacePath) == getSimpleName(strippedTarget)) {
					return true;
				}

				if (checkInheritance(ifacePath, targetType, visited)) return true;
			}
		}

		return false;
	}

	// ===================== Array Compatibility =====================

	/**
	 * Check if two Array types are compatible.
	 * `Array<SourceElement>` is compatible with `Array<TargetElement>` if elements match.
	 * Plain `Array` matches any `Array<T>`.
	 */
	public static function areArraysCompatible(sourceType:TypeRef, targetType:TypeRef):Bool {
		var sourceElement = extractGenericParam(sourceType);
		var targetElement = extractGenericParam(targetType);

		// Plain Array matches any Array
		if (sourceElement == null || targetElement == null) return true;

		return isCompatible(sourceElement, targetElement);
	}

	// ===================== Map Compatibility =====================

	/**
	 * Check if two Map types are compatible.
	 * `Map<K1,V1>` is compatible with `Map<K2,V2>` if both K and V match.
	 * Plain `Map` matches any `Map<K,V>`.
	 */
	public static function areMapsCompatible(sourceType:TypeRef, targetType:TypeRef):Bool {
		var sourceParams = extractMapParams(sourceType);
		var targetParams = extractMapParams(targetType);

		// Plain Map matches any Map
		if (sourceParams == null || targetParams == null) return true;

		return isCompatible(sourceParams.key, targetParams.key)
			&& isCompatible(sourceParams.value, targetParams.value);
	}

	// ===================== Function Type =====================

	/**
	 * Check if a type string represents a function type.
	 * Looks for `->` outside of nested structures/generics.
	 */
	public static function isFunction(typeString:TypeRef):Bool {
		return isFunctionType(typeString);
	}

	// ===================== Value-Based Compatibility =====================

	/**
	 * Check if a runtime value can be used where `targetType` is expected.
	 * Infers the value's type and then checks compatibility.
	 *
	 * @param value The actual runtime value
	 * @param targetType The expected type string
	 */
	public static function isValueCompatible(value:Dynamic, targetType:TypeRef):Bool {
		if (value == null) return true; // Null is assignable to any nullable type

		var sourceType = inferValueType(value);
		return isCompatible(sourceType, targetType);
	}

	/**
	 * Infer a type string from a runtime value.
	 * For anonymous objects (TObject), builds a structure type string like `{ name:String, age:Int }`
	 * by introspecting the object's fields and recursively inferring their types.
	 */
	public static function inferValueType(value:Dynamic, ?maxDepth:Int = 3):String {
		if (value == null) return "Null";

		// Check for AbstractValue first
		if (Std.isOfType(value, AbstractValue)) {
			var absVal:AbstractValue = cast value;
			return absVal.interpreter.abstractPath;
		}

		// Check for AbstractInterpreter (the type itself)
		if (Std.isOfType(value, AbstractInterpreter)) {
			var interp:AbstractInterpreter = cast value;
			return interp.abstractPath;
		}

		return switch (Type.typeof(value)) {
			case TNull: "Null";
			case TInt: "Int";
			case TFloat: "Float";
			case TBool: "Bool";
			case TClass(c):
				var name = Type.getClassName(c);
				if (name == "String") "String";
				else if (name == "Array") {
					// Infer element type from first element if possible
					var arr:Array<Dynamic> = cast value;
					if (arr.length > 0 && maxDepth > 0) {
						var elemType = inferValueType(arr[0], maxDepth - 1);
						"Array<" + elemType + ">";
					} else {
						"Array<Dynamic>";
					}
				}
				else name != null ? name : "Dynamic";
			case TEnum(e):
				var name = Type.getEnumName(e);
				name != null ? name : "Dynamic";
			case TFunction: "Function";
			case TObject:
				// Build a structure type string from the object's fields
				inferStructureType(value, maxDepth);
			case TUnknown: "Dynamic";
		}
	}

	/**
	 * Introspect an anonymous object and build a structure type string.
	 * For example, `{name: "John", age: 30}` → `{ name:String, age:Int }`
	 *
	 * Uses a depth limit to prevent infinite recursion on nested/circular structures.
	 * Falls back to "Dynamic" if depth is exhausted or the object has no fields.
	 */
	private static function inferStructureType(value:Dynamic, depth:Int):String {
		if (depth <= 0) return "Dynamic";

		var fields:Array<String> = null;
		try {
			fields = Reflect.fields(value);
		} catch (e:Dynamic) {
			return "Dynamic";
		}

		if (fields == null || fields.length == 0) return "Dynamic";

		var fieldStrs:Array<String> = [];
		for (fieldName in fields) {
			var fieldValue:Dynamic = null;
			try {
				fieldValue = Reflect.field(value, fieldName);
			} catch (e:Dynamic) {
				fieldStrs.push(fieldName + ":Dynamic");
				continue;
			}
			var fieldType = inferValueType(fieldValue, depth - 1);
			fieldStrs.push(fieldName + ":" + fieldType);
		}

		return "{ " + fieldStrs.join(", ") + " }";
	}

	// ===================== Utility Methods =====================

	/**
	 * Strip generic type parameters from a type string.
	 * `SomeType<T, U>` → `SomeType`
	 * `Array<Int>` → `Array`
	 * `Map<String, Int>` → `Map`
	 * Does NOT strip from structures.
	 */
	public static function stripGenerics(typeString:TypeRef):String {
		if (typeString == null) return typeString;
		typeString = StringTools.trim(typeString);

		// Don't strip from structures
		if (StringTools.startsWith(typeString, "{")) return typeString;

		var angleIdx = typeString.indexOf("<");
		if (angleIdx < 0) return typeString;

		return typeString.substring(0, angleIdx);
	}

	/**
	 * Get the simple name from a fully qualified type path.
	 * `yutautil.Num` → `Num`
	 * `flixel.FlxSprite` → `FlxSprite`
	 */
	public static function getSimpleName(typePath:TypeRef):String {
		if (typePath == null) return typePath;
		var dot = typePath.lastIndexOf(".");
		if (dot >= 0) return typePath.substring(dot + 1);
		return typePath;
	}

	/**
	 * Extract the generic parameter from `Type<Param>`.
	 * Returns null if no generic parameter found.
	 */
	public static function extractGenericParam(typeString:TypeRef):Null<String> {
		if (typeString == null) return null;
		var start = typeString.indexOf("<");
		if (start < 0) return null;
		var end = typeString.lastIndexOf(">");
		if (end <= start) return null;
		return StringTools.trim(typeString.substring(start + 1, end));
	}

	/**
	 * Extract key and value type parameters from `Map<K, V>`.
	 */
	public static function extractMapParams(typeString:TypeRef):Null<{key:String, value:String}> {
		var inner = extractGenericParam(typeString);
		if (inner == null) return null;

		// Split on comma, respecting nesting
		var parts = splitRespectingNesting(inner, ",");
		if (parts.length < 2) return null;

		return {
			key: StringTools.trim(parts[0]),
			value: StringTools.trim(parts[1])
		};
	}

	// ===================== Parsing Helpers =====================

	/**
	 * Check if a type string represents a function type.
	 * Looks for `->` at the top level (not inside braces, angles, or parens).
	 */
	private static function isFunctionType(typeString:String):Bool {
		if (typeString == null) return false;

		var depth = 0; // tracks {}, <>, ()
		var i = 0;
		while (i < typeString.length - 1) {
			var c = typeString.charAt(i);
			switch (c) {
				case "{" | "<" | "(":
					depth++;
				case "}" | ">" | ")":
					depth--;
				case "-":
					if (depth == 0 && i + 1 < typeString.length && typeString.charAt(i + 1) == ">") {
						return true;
					}
				default:
			}
			i++;
		}
		return false;
	}

	/**
	 * Split a string by a delimiter, respecting nested braces, angles, and parens.
	 */
	private static function splitRespectingNesting(input:String, delimiter:String):Array<String> {
		var result:Array<String> = [];
		var current = new StringBuf();
		var depth = 0;
		var i = 0;

		while (i < input.length) {
			var c = input.charAt(i);

			if (c == "{" || c == "<" || c == "(") {
				depth++;
				current.add(c);
			} else if (c == "}" || c == ">" || c == ")") {
				depth--;
				current.add(c);
			} else if (depth == 0 && c == delimiter) {
				result.push(current.toString());
				current = new StringBuf();
			} else {
				current.add(c);
			}
			i++;
		}

		var remaining = current.toString();
		if (remaining.length > 0) {
			result.push(remaining);
		}

		return result;
	}

	/**
	 * Find the first colon `:` in a string that is not inside nested braces/angles/parens.
	 * Used for parsing `fieldName : FieldType` in structures.
	 */
	private static function findFirstColon(input:String):Int {
		var depth = 0;
		var i = 0;
		while (i < input.length) {
			var c = input.charAt(i);
			switch (c) {
				case "{" | "<" | "(":
					depth++;
				case "}" | ">" | ")":
					depth--;
				case ":":
					if (depth == 0) return i;
				default:
			}
			i++;
		}
		return -1;
	}
}
