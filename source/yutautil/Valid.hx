package yutautil;

// Abstract for a "Valid" type that can be used as a boolean or as a conditional tree

abstract Valid(Bool) from Bool to Bool to Dynamic {
    public var expr:() -> Bool;

    // Construct from a function (expression)
    public inline function new(expr:() -> Bool) {
        this.expr = expr;
    }

    // Construct from a Bool value
    @:from
    public static inline function fromBool(b:Bool):Valid {
        return new Valid(() -> b);
    }

    // Allow using as Bool (always evaluates the expression)
    @:to
    public inline function toBool():Bool {
        return expr();
    }

    // Allow chaining if-else logic (if tree)
    @:to
    public function ifElse<T>(ifTrue:Dynamic, ifFalse:Dynamic):T {
        return expr() ? ifTrue : ifFalse;
    }

    // Static helper for building from an expression
    public static inline function fromExpr(expr:() -> Bool):Valid {
        return new Valid(expr);
    }
}