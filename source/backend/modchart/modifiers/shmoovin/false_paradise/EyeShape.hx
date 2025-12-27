package backend.modchart.modifiers.shmoovin.false_paradise;

import backend.funkinmodchart.backend.util.ModchartUtil;
import flixel.math.FlxMath;
import haxe.ds.Vector;

@:dontSave
private class TimeVector extends Vector3 {
	public var startDist = 0.0;
	public var endDist = 0.0;
	public var next:TimeVector;
}

class EyeShape extends NoteModifier {
	override function getName()
		return 'eyeShape';

	override function getOrder()
		return Modifier.ModifierOrder.LAST - 8;

	var _path:Vector<TimeVector>;
	var _pathDistance:Float = 0;

	var SCALE:Float = 600;

	function getDistancesOf(path:Vector<TimeVector>) {
		var index:Int = 0;
		var last = path[index];
		last.startDist = 0;
		var dist:Float = 0;

		while (index < path.length) {
			final current = path[index];
			final diff = current.subtract(last);

			current.startDist = (dist += diff.length);
			last.next = current;
			last.endDist = current.startDist;
			last = current;

			index++;
		}
		return dist;
	}

	function getPositionAt(distance:Float):Null<Vector3> {
		for (i in 0..._path.length) {
			final vec = _path[i];

			if (FlxMath.inBounds(distance, vec.startDist, vec.endDist) && vec.next != null) {
				var ratio = (distance - vec.startDist) / vec.next.subtract(vec).length;
				return vec.lerp(vec.next, ratio, vec);
			}
		}
		return _path[0];
	}

	function loadPath():Vector<TimeVector> {
		var pathArray:Array<TimeVector> = [];

		for (node in ModchartUtil.coolTextFile('assets/modchart/eyeShape.csv')) {
			final coords = node.split(';');
			pathArray.push(new TimeVector(Std.parseFloat(coords[0]) * SCALE, Std.parseFloat(coords[1]) * SCALE, Std.parseFloat(coords[2]) * SCALE));
		}

		var pathIterable = Vector.fromArrayCopy(pathArray);
		pathArray.resize(0);

		_pathDistance = getDistancesOf(pathIterable);
		return pathIterable;
	}

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField) {
		if (_path == null)
			_path = loadPath();

		final perc = getValue(player);

		if (perc == 0)
			return pos;

		var path = getPositionAt(visualDiff / 2000.0 * _pathDistance);
		path.add(new Vector3(FlxG.width * .5 - 264 - 272, FlxG.height * .5 + 280 - 260), path);

		return pos.lerp(path, perc, pos);
	}
}
