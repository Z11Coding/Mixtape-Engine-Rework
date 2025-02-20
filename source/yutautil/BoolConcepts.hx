class BoolConcepts {
    // Boolable: Converts various types into a boolean based on their value
    abstract Boolable(Bool) {
        @:from static public function fromInt(value:Int):Boolable {
            return value != 0;
        }

        @:from static public function fromFloat(value:Float):Boolable {
            return value != 0.0;
        }

        @:from static public function fromString(value:String):Boolable {
            return value != "" && value.toLowerCase() != "false";
        }

        @:from static public function fromBool(value:Bool):Boolable {
            return value;
        }

        @:from static public function fromBoolit<T>(value:Boolit<T>):Boolable {
            return value;
        }

        @:from static public function fromNull(value:Null<Dynamic>):Boolable {
            return false;
        }

        // Additional conversions can be added here
    }

	// Boolit: Wraps any type and allows it to be used in boolean contexts
	abstract Boolit<T>(T) {
		// Implicit cast from any type to Boolit
		@:from static public function fromDynamic<T>(value:T):Boolit<T> {
			return (value);
		}

		// Operator overloading for boolean context
        @:op(A.Bool) public inline function toBool():Bool {
            // First, check if the wrapped value is a Boolable
            if (Std.is(this, Boolable)) {
                return cast this; // Cast this Boolit as Boolable, then implicitly to Bool
            }
        
            // Existing switch statement for basic types
            switch (Type.typeof(this)) {
                case TInt: return cast this != 0;
                case TFloat: return cast this != 0.0;
                case TString: return cast this != "" && cast this.toLowerCase() != "false";
                case TNull: return false;
                // Add other specific cases here if needed
                case _: // If none of the above, default to true for other types
                    return true;
            }
        }

		// Example usage of retaining original type operations (for Int)
	// 	public inline function add(other:Int):Int {
	// 		return cast this + other;
	// 	}
	}
}