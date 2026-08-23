package yutautil.typeregistry;

import backend.MusicBeatState;

/**
 * Underlying representation of a StateRef.
 */
enum StateRefKind {
    /** A specific state instance - matches only that exact object. */
    Instance(state:Dynamic);

    /** A state class - matches any current state that is an instance of it. */
    ClassRef(stateClass:Class<MusicBeatState>);
}

/**
 * Typesafe reference to a "state", used for scoping temporary function edits
 * (see `RuntimeFunctionRegistry.editTemporary`).
 *
 * A StateRef is either:
 *  - a specific state **instance** - the edit applies only while that exact
 *    instance is the current state; or
 *  - a state **class** - the edit applies to any current state which is an
 *    instance of that class (subclasses included), surviving instance swaps
 *    such as state resets.
 *
 * Only MusicBeatState subclasses are valid states (MusicBeatState itself is
 * excluded): those are the only interceptable states, since MusicBeatState
 * drives temporary-edit cleanup in `destroy()`.
 *
 * ```haxe
 * import yutautil.typeregistry.StateRef;
 *
 * // Instance binding (implicit conversion):
 * var ref:StateRef = cast FlxG.state;
 *
 * // Class binding (only MusicBeatState subclasses compile):
 * var ref:StateRef = StateRef.fromClass(states.PlayState);
 * ```
 */
abstract StateRef(StateRefKind) {
    private inline function new(kind:StateRefKind) {
        this = kind;
    }

    /**
     * Whether the given object can be used as an interceptable state:
     * an instance of a MusicBeatState subclass (MusicBeatState itself is not
     * interceptable - only its concrete subclasses are).
     */
    public static function isInterceptableState(value:Dynamic):Bool {
        if (value == null) return false;
        if (!Std.isOfType(value, MusicBeatState)) return false;
        return Type.getClass(value) != MusicBeatState;
    }

    /**
     * Wrap a specific state instance. Returns null when the value is not an
     * interceptable state (not a MusicBeatState subclass instance).
     */
    public static function fromState(state:Dynamic):Null<StateRef> {
        return isInterceptableState(state) ? new StateRef(StateRefKind.Instance(state)) : null;
    }

    /**
     * Bind to a state class - matches any current state of that class.
     * Only MusicBeatState subclasses are accepted: `MusicBeatState` itself
     * (the abstract, never-directly-instantiated base) is rejected, and so is
     * any non-MusicBeatState class (a compile-time error, since only
     * `Class<MusicBeatState>` unifies with the parameter type).
     */
    public static function fromClass(stateClass:Class<MusicBeatState>):StateRef {
        if (stateClass == cast MusicBeatState) {
            throw 'StateRef.fromClass: MusicBeatState itself is not interceptable - pass a concrete subclass';
        }
        return new StateRef(StateRefKind.ClassRef(stateClass));
    }

    /** The wrapped state instance, or null for class references. */
    public var instance(get, never):Null<Dynamic>;

    inline function get_instance():Null<Dynamic> {
        return switch (this) {
            case Instance(s): s;
            case ClassRef(_): null;
        };
    }

    /** The wrapped state class, or null for instance references. */
    public var stateClass(get, never):Null<Class<Dynamic>>;

    inline function get_stateClass():Null<Class<Dynamic>> {
        return switch (this) {
            case Instance(_): null;
            case ClassRef(c): c;
        };
    }

    /** True when this reference wraps a specific instance. */
    public var isInstanceRef(get, never):Bool;

    inline function get_isInstanceRef():Bool {
        return switch (this) {
            case Instance(_): true;
            case ClassRef(_): false;
        };
    }

    /**
     * Whether the given current state satisfies this reference.
     * Instance references match only that exact instance; class references
     * match any instance of the class (including subclasses).
     */
    public function matches(state:Dynamic):Bool {
        if (state == null) return false;
        return switch (this) {
            case Instance(s): state == s;
            case ClassRef(c): Std.isOfType(state, c);
        };
    }

    inline function raw():StateRefKind {
        return this;
    }

    /**
     * Structural equality between two references: two instance references are
     * equal only for the same instance; two class references only for the
     * same class.
     */
    public function equals(other:StateRef):Bool {
        return switch [this, other.raw()] {
            case [Instance(a), Instance(b)]: a == b;
            case [ClassRef(a), ClassRef(b)]: a == b;
            default: false;
        };
    }

    @:to public function toString():String {
        return switch (this) {
            case Instance(s):
                s == null ? 'StateRef(instance:null)' : 'StateRef(instance:${Type.getClassName(Type.getClass(s))})';
            case ClassRef(c):
                'StateRef(class:${Type.getClassName(c)})';
        };
    }
}
