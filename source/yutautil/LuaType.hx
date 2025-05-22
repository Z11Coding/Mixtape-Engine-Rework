package yutautil;

class LuaType<T>
{
    public var value:T;
    public var stackIndex:Null<Int>;
    public var isRef:Bool;

    public function new(value:T)
    {
        this.value = value;
    }

    public function toString():String
    {
        return Std.string(value);
    }
    public function getType():String
    {
        return Type.getClassName(Std.getClass(value));
    }
    public function push():Void
    {
        // Push the value to the Lua stack
        // This is a placeholder implementation
        trace("Pushing value: " + Std.string(value));
    }
    public static function obtainFromStack(stackIndex:Int):LuaType<T>
    {
        // Obtain a LuaType from the stack at the given index
        // This is a placeholder implementation
        var value:T = null; // Replace with actual value retrieval from Lua stack
        return new LuaType<T>(value);
    }
}

enum LuaVarType
{
    NIL;
    BOOLEAN;
    NUMBER;
    STRING;
    TABLE;
    FUNCTION;
    THREAD;
    USERDATA;
}

class SpecialLuaType<T> extends LuaType<T>
{

    public var isUserdata:Bool;
    public var isThread:Bool;
    public var isFunction:Bool;
    public var isCoroutine:Bool;
    public var luaType:LuaVarType;
    public function new(value:T)
    {
        super(value);
    }

    public function push():Void
    {
        // Push the value to the Lua stack with special handling
        // This is a placeholder implementation
        trace("Pushing special value: " + Std.string(value));
    }
}

abstract LuaVar(T) {
    public function new(value:T)
    {
        this.value = value;
    }

    public function push():Void
    {
        // Push the value to the Lua stack
        // This is a placeholder implementation
        trace("Pushing value: " + Std.string(value));
    }

    public function toString():String
    {
        return Std.string(value);
    }

    public function getType():String
    {
        return Type.getClassName(Std.getClass(value));
    }

    public function isNil():Bool
    {
        return LuaUtil.isNil(value);
    }

    public function isBoolean():Bool
    {
        return LuaUtil.isBoolean(value);
    }

    public function isNumber():Bool
    {
        return LuaUtil.isNumber(value);
    }

    public function isString():Bool
    {
        return LuaUtil.isString(value);
    }

    public function isTable():Bool
    {
        return LuaUtil.isTable(value);
    }

    public function isFunction():Bool
    {
        return Type.getClassName(Std.getClass(value)) == "Function";
    }

    public function isThread():Bool
    {
        return Type.getClassName(Std.getClass(value)) == "Thread";
    }

    public function isUserdata():Bool
    {
        return Type.getClassName(Std.getClass(value)) == "Userdata";
    }

    // public function isCoroutine():Bool
    // {
    //     return Type.getClassName(Std.getClass(value)) == "Coroutine";
    // }

    // public function isError():Bool
    // {
    //     return Type.getClassName(Std.getClass(value)) == "Error";
    // }
    
}

class LuaUtil
{
    public static function isNil(value:Dynamic):Bool
    {
        return value == null;
    }

    public static function isBoolean(value:Dynamic):Bool
    {
        return Type.getClassName(Std.getClass(value)) == "Bool";
    }

    public static function isNumber(value:Dynamic):Bool
    {
        return Type.getClassName(Std.getClass(value)) == "Float";
    }

    public static function isString(value:Dynamic):Bool
    {
        return Type.getClassName(Std.getClass(value)) == "String";
    }

    public static function isTable(value:Dynamic):Bool
    {
        return Type.getClassName(Std.getClass(value)) == "Object";
    }
}