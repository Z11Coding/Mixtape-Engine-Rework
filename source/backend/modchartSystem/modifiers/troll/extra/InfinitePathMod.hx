package backend.modchartSystem.modifiers.troll.extra;

class InfinitePathMod extends TrollCustomPathMod {

  public function new(name:String) {
    super(name);
  }

  override function loadPath() {
    var infPath:List<TimeVector> = [for(i in 0...Note.ammo[PlayState.mania]) []];

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

    _pathDistance = calculatePathDistances(infPath);
    _path = infPath;
  }
}
