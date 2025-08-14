package yutautil;

@:allow(yutautil.StatePick)
class StateMapStorage
{
	// Runtime storage - will be populated from resource
	private static var StateMap:Map<String, Array<String>>;
	
	// Initialize from embedded resource
	public static function initializeStateMap():Void
	{
		if (StateMap != null) return; // Already initialized
		
		try {
			var resourceData = haxe.Resource.getString("statePickData");
			if (resourceData != null) {
				var parsedData:Dynamic = haxe.Json.parse(resourceData);
				StateMap = new Map<String, Array<String>>();
				
				// Manual conversion from Dynamic to Map since JSON parsing might not preserve Map type
				for (field in Reflect.fields(parsedData)) {
					var states:Array<String> = cast Reflect.field(parsedData, field);
					StateMap.set(field, states);
				}
				
				trace('StatePick: Initialized from resource with ${StateMap.keys().hasNext() ? Lambda.count(StateMap) : 0} base classes');
				return;
			} else {
				trace('StatePick: No resource data found - resource "statePickData" does not exist');
			}
		} catch (e:Dynamic) {
			trace('StatePick: Failed to initialize from resource: $e');
		}
		
		// Fallback: Empty map
		trace('StatePick: Using fallback empty map');
		StateMap = new Map<String, Array<String>>();
	}
	
	// Private accessor methods for StatePick
	private static function getStateMap():Map<String, Array<String>>
	{
		return StateMap;
	}
	
	private static function stateMapExists(key:String):Bool
	{
		return StateMap != null && StateMap.exists(key);
	}
	
	private static function getStateArray(key:String):Array<String>
	{
		return StateMap != null && StateMap.exists(key) ? StateMap[key] : [];
	}
	
	private static function getStateMapKeys():Iterator<String>
	{
		return StateMap != null ? StateMap.keys() : [].iterator();
	}
}
