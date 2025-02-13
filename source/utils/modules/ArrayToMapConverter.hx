package backend.modules;

import haxe.ds.StringMap;

class ArrayToMapConverter {
	public static function convert(input:Array<Dynamic>):StringMap<Dynamic> {
		var result = new StringMap<Dynamic>();

		// Check if input is an array of arrays
		if (Std.is(input[0], Array)) {
			for (subArray in input) {
				if (subArray.length == 2) {
					result.set(Std.string(subArray[0]), subArray[1]);
				} else {
					throw 'Sub-array does not contain exactly 2 items';
				}
			}
		} else if (input.length == 2) { // Check if input is a simple array with 2 items
			result.set(Std.string(input[0]), input[1]);
		} else {
			throw 'Input does not match expected patterns';
		}

		return result;
	}

	public static function reverseConvert(map:StringMap<Dynamic>):Array<Array<Dynamic>> {
		var result:Array<Array<Dynamic>> = [];

		for (key in map.keys()) {
			var value:Dynamic = map.get(key);
			result.push([key, value]);
		}

		return result;
	}
}

