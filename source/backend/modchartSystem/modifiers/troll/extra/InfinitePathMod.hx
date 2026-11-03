package backend.modchartSystem.modifiers.troll.extra;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import backend.modchartSystem.modifiers.CustomPathModifier;
import objects.notes.Strumline;

// From Troll Engine: Shapes the note path in an infinity symbol
class InfinitePathMod extends TrollCustomPathMod {

  public function new(name:String) {
    super(name);
    unknown = false;
    notesMod = true;
    holdsMod = true;
    strumsMod = true;
    pathMod = true;
  }

  override function loadPath() {
    var infPath:Array<List<TimeVector>> = [for(i in 0...ExtraKeys.ammo[ExtraKeys.mania]) new List<TimeVector>()];

		var r = 0;
		while (r < 360) {
			for (data in 0...infPath.length) {
				var rad = r * Math.PI / 180;
				infPath[data].push(new TimeVector(
					FlxG.width * 0.5 + (FlxMath.fastSin(rad)) * 600,
					FlxG.height * 0.5 + (FlxMath.fastSin(rad) * FlxMath.fastCos(rad)) * 600,
					0,
          0
				));
			}
			r += 15;
		}

    _pathDistance = calculatePathDistances(infPath[0]);
    _path = infPath[0];
  }
}
