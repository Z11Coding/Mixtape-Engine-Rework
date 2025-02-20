package options;

class ToggleOption extends Option {
	public var enabled:Bool;

	public function new(name:String, type:String, defaultValue:Dynamic, changeValue:Dynamic, minValue:Dynamic = null, maxValue:Dynamic = null) {
		super(name, type, defaultValue, changeValue, minValue, maxValue);
		this.enabled = Reflect.getProperty(ClientPrefs.data, variable) != null ? Reflect.getProperty(ClientPrefs.data, variable).isEnabled : false;
	}

	public function toggle():Void {
		this.enabled = !this.enabled;
	}

	override public function setValue(value:Dynamic):Void {
		if (this.enabled) {
			Reflect.callMethod(this, Reflect.field(this, "setValue"), [value]);
		}
	}

	override public function getValue():Dynamic {
		if (this.enabled) {
			var value = Reflect.getProperty(ClientPrefs.data, variable).value;
			if(type == 'keybind') return !Controls.instance.controllerMode ? value.keyboard : value.gamepad;
			return value;
		}
		return null;
	}

    // override public function onChange():Void {
    //     if (this.enabled) {
    //         Reflect.callMethod(this, Reflect.field(this, "onChange"), []);
    //     }
    // }
}

