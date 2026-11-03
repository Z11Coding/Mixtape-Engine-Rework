package backend.modchartSystem.modifiers.shmoovin;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import backend.modchartSystem.modifiers.CustomPathModifier;
import flixel.math.FlxMath;
import haxe.ds.Vector;
import objects.notes.Strumline;

// From Shmoovin': Makes the notes path in an eye shape (no way)
class EyeShape extends TrollCustomPathMod {
	var SCALE:Float = 600;

  public function new(name:String)
  {
    super(name);
  }

	override function loadPath() {
		_path = new List<TimeVector>();

		for (node in CoolUtil.coolTextFile('assets/modchart/eyeShape.csv')) {
			final coords = node.split(';');
			_path.push(new TimeVector(Std.parseFloat(coords[0]) * SCALE, Std.parseFloat(coords[1]) * SCALE, Std.parseFloat(coords[2]) * SCALE,
				Std.parseFloat(coords[3]) * SCALE));
		}

		_pathDistance = calculatePathDistances(_path);
	}
}
