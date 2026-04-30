package backend.modchart.modifiers;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import math.*;
import modchart.*;
import ui.*;

class AngleModifier extends Modifier {

  override function getName()
		return 'scrollAngle';

  override function getPos(diff:Float, tDiff:Float, beat:Float, pos:Vector3, column:Int, player:Int, obj:FlxSprite, field:NoteField) {
    if(getPercent(player)==0&&getSubmodPercent('scrollAngle${column}', player)==0)return pos;

    //pos.copyFrom(CoolUtil.rotate(pos.x,pos.y,getPercent(player)));
    var rotated = CoolUtil.rotate(pos.x,pos.y,(getPercent(player)*100+getSubmodPercent('scrollAngle${column}', player)*100));
    pos.x = rotated.x;
    pos.y = rotated.y;

    return pos;
  }

  override function getSubmods(){
		var shid:Array<String> = ['scrollAngle'];

		var submods:Array<String> = [
			for (d in 0...Note.ammo[PlayfieldManager.mania[0]])
			{
				for (s in shid)
					'$s$d';
			}
		];
		return submods;
	}
}
