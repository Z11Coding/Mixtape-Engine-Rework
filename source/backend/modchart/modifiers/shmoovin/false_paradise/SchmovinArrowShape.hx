package backend.modchart.modifiers.shmoovin.false_paradise;

import backend.funkinmodchart.backend.util.ModchartUtil;
import flixel.math.FlxMath;
import openfl.geom.Vector3D;

@:dontSave
private class TimeVector extends Vector3 {
	public var startDist = 0.0;
	public var endDist = 0.0;
	public var next:TimeVector;
}

class SchmovinArrowShape extends NoteModifier {
	override function getName()
		return 'schmovinArrowShape';

	override function getOrder()
		return Modifier.ModifierOrder.LAST - 7;

	var _path:List<TimeVector>;
	var _pathDistance:Float = 0;

	static inline var SCALE:Float = 200;

	function CalculatePathDistances(path:List<TimeVector>) {
		var iterator = path.iterator();
		var last = iterator.next();
		last.startDist = 0;
		var dist = 0.0;
		var iteratorHasNext = iterator.hasNext;
		var iteratorNext = iterator.next;
		while (iteratorHasNext()) {
			var current = iteratorNext();
			var differential = current.subtract(last);
			dist += differential.length;
			current.startDist = dist;
			last.next = current;
			last.endDist = current.startDist;
			last = current;
		}
		return dist;
	}

	function GetPointAlongPath(distance:Float):Null<Vector3> {
		for (vec in _path) {
			if (FlxMath.inBounds(distance, vec.startDist, vec.endDist) && vec.next != null) {
				var ratio = (distance - vec.startDist) / vec.next.subtract(vec).length;
				return vec.lerp(vec.next, ratio, vec);
			}
		}
		return _path.first();
	}

	function LoadPath():List<TimeVector> {
		var file = ModchartUtil.coolTextFile('assets/modchart/arrowShape.csv');
		var path = new List<TimeVector>();
		for (line in file) {
			var coords = line.split(';');
			var vec = new TimeVector(Std.parseFloat(coords[0]), Std.parseFloat(coords[1]), Std.parseFloat(coords[2]));
			vec.scaleBy(SCALE);
			path.add(vec);
		}
		_pathDistance = CalculatePathDistances(path);
		return path;
	}

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField){
		if (_path == null)
			_path = LoadPath();

		final perc = getValue(player);

		if (perc == 0)
			return pos;

		var path = GetPointAlongPath(visualDiff / 1500.0 * _pathDistance);

		return pos.lerp(path.add(new Vector3(FlxG.width * .5, FlxG.height * .5 + 280, data * getSubmodValue('schmovinArrowShapeOffset', player) + pos.z)), perc, pos);
	}

	override function getSubmods(){
		return ['schmovinArrowShapeOffset'];
	}
}
