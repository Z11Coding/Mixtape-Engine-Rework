package backend.modchart.modifiers.shmoovin.false_paradise;

import backend.funkinmodchart.backend.util.ModchartUtil;
@:keep
class ArrowShape extends CustomPathModifier {
	override function getName() return 'arrowShape';
	override function getMoveSpeed() {
		return 3000;
	}

	override function getPath():Array<Array<Vector3>>
	{
		var path:Array<Array<Vector3>> = [for(i in 0...Note.ammo[PlayState.mania]) []];

		for (data in 0...path.length) {
			for (line in ModchartUtil.coolTextFile('assets/modchart/arrowShape.csv')) {
				var coords = line.split(';');
				path[data].push(new Vector3(
					FlxG.width * 0.5 + (Std.parseFloat(coords[0])) * 200,
					FlxG.height * 0.5 + 280 + (Std.parseFloat(coords[1])) * 200,
					Std.parseFloat(coords[2]) * 200)
				);
			}
		}
		return path;
	}
}
