package options;

class Toggle<T> {
	var _value:T;
	public var isEnabled:Bool;
    public var value(get, set):Null<T>; 

	public function new(value:T, isEnabled:Bool = true) {
		this._value = value;
		this.isEnabled = isEnabled;
	}

	// Custom getter for 'value' property
	function get_value():Null<T> {
		return isEnabled ? _value : null;
	}

    function set_value(newValue:T):T {
        _value = newValue; // Set the internal value
        return newValue; // Return the new value (required by Haxe property syntax)
    }

    public static function of<T>(value:T, isEnabled:Bool = true):Toggle<T> {
        return new Toggle(value, isEnabled);
    }

	public function enable():Void {
		isEnabled = true;
	}

	public function disable():Void {
		isEnabled = false;
	}

	public function toggle():Void {
		isEnabled = !isEnabled;
	}
}

