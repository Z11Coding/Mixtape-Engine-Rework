package backend.modchart.modifiers;
import flixel.FlxSprite;
import backend.modchart.*;
import backend.math.Vector3;

// this'll be psychTransformX in ModManager
// It's literally just transform, but for regular psych scripts
class PsychTransformModifier extends NoteModifier {
    inline function lerp(a:Float,b:Float,c:Float){
        return a+(b-a)*c;
    }

	override function getName()
		return 'psychTransformX';

    override function getOrder()
        return Modifier.ModifierOrder.LAST;

    override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField)
    {   
        pos.x += getValue(player) + getSubmodValue("psychTransformX-a",player);
		pos.y += getSubmodValue("psychTransformY", player) + getSubmodValue("psychTransformY-a",player);
        pos.z += getSubmodValue('psychTransformZ', player) + getSubmodValue("psychTransformZ-a",player);
        
		pos.x += (field.field.baseXPositions[data]*1.5) - getSubmodValue('psychTransform${data}X', player) + getSubmodValue('psychTransform${data}X-a', player);
		pos.y += getSubmodValue('psychTransform${data}Y', player) + getSubmodValue('psychTransform${data}Y-a', player);
		pos.z += getSubmodValue('psychTransform${data}Z', player) + getSubmodValue('psychTransform${data}Z-a', player);
        
        return pos;
    }

    override function getSubmods(){
		var subMods:Array<String> = ["psychTransformY", "psychTransformZ", "psychTransformX-a", "psychTransformY-a", "psychTransformZ-a"];

        for(i in 0...Note.ammo[PlayState.mania]){
			subMods.push('psychTransform${i}X');
			subMods.push('psychTransform${i}Y');
			subMods.push('psychTransform${i}Z');
			subMods.push('psychTransform${i}X-a');
			subMods.push('psychTransform${i}Y-a');
			subMods.push('psychTransform${i}Z-a');
        }
        return subMods;
    }
}