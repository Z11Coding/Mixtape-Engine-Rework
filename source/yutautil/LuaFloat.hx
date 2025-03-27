package yutautil;

/**
 * A class to handle floating-point numbers with custom representations.
 */
class LuaFloat {
    private var value:Float;

    public function new(value:Float) {
        this.value = value;
    }

    /**
     * Converts the floating-point number to a Lua-style representation.
     * @return The Lua-style string representation of the number.
     */
    public function toLuaString():String {
        if (Math.isNaN(value)) return "nan";
        if (!Math.isFinite(value)) return value > 0 ? "inf" : "-inf";
        return Std.string(value);
    }

    /**
     * Parses a Lua-style string representation back into a LuaFloat.
     * @param luaString The Lua-style string representation.
     * @return A LuaFloat instance.
     */
    public static function fromLuaString(luaString:String):LuaFloat {
        switch (luaString) {
            case "nan": return new LuaFloat(Math.NaN);
            case "inf": return new LuaFloat(Math.POSITIVE_INFINITY);
            case "-inf": return new LuaFloat(Math.NEGATIVE_INFINITY);
            default: return new LuaFloat(Std.parseFloat(luaString));
        }
    }

    /**
     * Gets the raw floating-point value.
     * @return The Float value.
     */
    public function getValue():Float {
        return value;
    }

    /**
     * Sets the floating-point value.
     * @param newValue The new Float value.
     */
    public function setValue(newValue:Float):Void {
        value = newValue;
    }

    /**
     * Returns a string representation of the LuaFloat.
     * @return The string representation.
     */
    public function toString():String {
        return toLuaString();
    }
}
