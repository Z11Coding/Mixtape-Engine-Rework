package backend.modchartSystem.modifiers.shmoovin;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import backend.modchartSystem.modifiers.CustomPathModifier;
import objects.notes.Strumline;

// From Shmoovin': Makes the notes path in the shape of an arrow (no way)
class SchmovinArrowShape extends TrollCustomPathMod {
	static inline var SCALE:Float = 200;

	override function loadPath() {
		var file = backend.CoolUtil.coolTextFile('assets/modchart/arrowShape.csv');
		_path = new List<TimeVector>();
		for (line in file) {
			var coords = line.split(';');
			var vec = new TimeVector(Std.parseFloat(coords[0]), Std.parseFloat(coords[1]), Std.parseFloat(coords[2]), Std.parseFloat(coords[3]));
			vec.scaleBy(SCALE);
			_path.add(vec);
		}
		_pathDistance = calculatePathDistances(_path);
	}
}
