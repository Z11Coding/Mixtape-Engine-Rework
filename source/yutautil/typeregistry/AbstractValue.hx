package yutautil.typeregistry;

/**
 * A runtime container for an abstract-typed value.
 *
 * Carries both the raw underlying value and the AbstractInterpreter
 * that knows how to dispatch methods, operators, and conversions.
 */
class AbstractValue {
	/** The raw underlying value (e.g. the Float backing a Num) */
	public var rawValue(default, null):Dynamic;

	/** The interpreter for this abstract type */
	public var interpreter(default, null):AbstractInterpreter;

	/** The abstract type path */
	public var typePath(get, never):String;

	/** The abstract's simple name */
	public var typeName(get, never):String;

	public function new(value:Dynamic, interpreter:AbstractInterpreter) {
		this.rawValue = value;
		this.interpreter = interpreter;
	}

	private function get_typePath():String {
		return interpreter.abstractPath;
	}

	private function get_typeName():String {
		return interpreter.abstractName;
	}

	/**
	 * Call a method on this abstract value.
	 */
	public function call(methodName:String, args:Array<Dynamic>):Dynamic {
		return interpreter.callMethod(rawValue, methodName, args);
	}

	/**
	 * Access a field on this abstract value.
	 */
	public function field(fieldName:String):Dynamic {
		return interpreter.getField(rawValue, fieldName);
	}

	/**
	 * Set a field on this abstract value.
	 */
	public function setField(fieldName:String, value:Dynamic):Void {
		interpreter.setField(rawValue, fieldName, value);
	}

	/**
	 * Apply an operator with another value.
	 */
	public function op(op:String, other:Dynamic = null):Dynamic {
		return interpreter.applyOperator(op, this, other);
	}

	/**
	 * Convert this abstract to a target type via @:to conversion.
	 */
	public function convertTo(targetTypeName:String):Dynamic {
		return interpreter.applyToConversion(rawValue, targetTypeName);
	}

	/**
	 * Get the raw underlying value.
	 */
	public function unwrap():Dynamic {
		return rawValue;
	}

	public function toString():String {
		return '${typeName}(${rawValue})';
	}
}
