package yutautil;

// Abstract for a "Valid" type that can be used as a boolean or as a conditional tree


typedef ComplexBool = Valid;
private class ValidImpl {
    public var expr: () -> Bool;
    public var ifTree: ValidIfTree;

    public inline function new(expr: () -> Bool, ?ifTree: ValidIfTree) {
        this.expr = expr;
        this.ifTree = ifTree != null ? ifTree : new ValidIfTree();
    }
}

// Represents a tree of if/else branches
class ValidIfTree {
    public var branches:Array<{cond:() -> Bool, action:() -> Dynamic}>;
    public var elseAction:Null<() -> Dynamic>;

    public function new() {
        branches = [];
        elseAction = null;
    }

    public function addIf(cond:() -> Bool, action:() -> Dynamic):ValidIfTree {
        branches.push({cond: cond, action: action});
        return this;
    }

    public function setElse(action:() -> Dynamic):ValidIfTree {
        elseAction = action;
        return this;
    }

    public function run():Dynamic {
        for (b in branches) {
            if (b.cond()) return b.action();
        }
        if (elseAction != null) return elseAction();
        return null;
    }
}

abstract Valid(ValidImpl) {
    // public var expr:() -> Bool;

    public inline function new(expr:() -> Bool, ?ifFunc:ValidIfTree) {
        this = new ValidImpl(expr, ifFunc);
    }

    @:from
    public static inline function fromPointedBool(b:HaxePointer<Bool>):Valid {
        return new Valid(() -> b);
    }

    // Allow using as Bool (always evaluates the expression)
    @:to
    public inline function toBool():Bool {
        return this.expr();
    }

    // Allow chaining if-else logic (if tree)
    @:to
    public inline function ifElse<T>():T {
        return if (this.ifTree != null) {
            this.ifTree.run();
        } else {
            cast this.expr();
        }
    }

    // Static helper for building from an expression
    public static inline function fromExpr(expr:() -> Bool):Valid {
        return new Valid(expr);
    }
}