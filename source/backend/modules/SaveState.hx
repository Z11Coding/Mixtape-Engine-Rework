package backend.modules;

import flixel.FlxState;
import haxe.Serializer;
import haxe.Unserializer;
// import haxe.Reflect;

class SaveState {
	private static var savedStates:Map<String, String> = new Map<String, String>();

	// Save the current state
	public static function saveState(stateName:String, state:FlxState):Void {
		var stateData = getStateData(state);
		var serializedStateData = Serializer.run(stateData);
		savedStates.set(stateName, serializedStateData);
	}

	// Load a saved state
	public static function loadState(stateName:String):FlxState {
		var serializedStateData = savedStates.get(stateName);
		if (serializedStateData != null) {
			var stateData = Unserializer.run(serializedStateData);
			return rebuildState(stateData);
		}
		return null;
	}



	private static function getStateData(state:FlxState):Dynamic {
		var stateData = {};
		for (field in Type.getInstanceFields(state)) {
			trace("Saving field: " + field + " = " + Reflect.field(state, field));
			stateData[field] = Reflect.field(state, field);
		}
		stateData["name"] = Type.getClassName(Type.getClass(state));
		stateData["class"] = Type.getClass(state);
		stateData["super"] = Type.getSuperClass(Type.getClass(state));
		stateData["args"] = []; // You better not have any constructor arguments...
		return stateData;
	}

	private static function rebuildState(stateData:Dynamic):FlxState {
		var state = Type.createInstance(stateData["class"], []);
		for (field in Reflect.fields(stateData)) {
			trace("Rebuilding field: " + field + " = " + stateData[field]);
			Reflect.setField(state, field, stateData[field]);
		}
		return state;
	}
	// Switch to a saved state
	public static function switchToState(stateName:String):Void {
		var state = loadState(stateName);
		if (state != null) {
			FlxG.switchState(state);
		}
	}
}

