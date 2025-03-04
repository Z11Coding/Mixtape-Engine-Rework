package backend.modules;

class Variable<T> {
	var expr:Void->T;
	public function new(expr:Void->T) {
		
		this.expr = expr;
        trace("Variable created.");
        trace(this.expr);
	}

    public function evaluate():Null<T> {
        try {
            return this.expr();
        } catch (error:Dynamic) {
            trace("Evaluation failed: " + error);
            return null;
        }
    }

    // Factory method for creating a Variable from a direct value
    public static function fromValue<T>(value:T):Variable<T> {
        return new Variable(() -> value);
    }

    // Factory method for creating a Variable from a function (expression)
    public static function fromFunction<T>(func:Void->T):Variable<T> {
        return new Variable(func);
    }
}

// abstract AutoVar<T>(Variable<T>) {
// 	// Implicit conversion from a value to a Variable
// 	@:from static public function fromValue<T>(value:T):AutoVar<T> {
// 		return new AutoVar(Variable.fromValue(value));
// 	}

// 	// Implicit conversion from a function to a Variable
// 	@:from static public function fromFunction<T>(func:Void->T):AutoVar<T> {
// 		return new AutoVar(Variable.fromFunction(func));
// 	}

// 	// Constructor for automation
// 	public function new(expr:Void->T) {
// 		super(Variable.fromFunction(expr));
// 	}
// }

// }

