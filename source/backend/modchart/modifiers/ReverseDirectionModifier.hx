package backend.modchart.modifiers;

import backend.modchart.Modifier.ModifierOrder;
import backend.modchart.*;
import backend.math.*;

import flixel.FlxG;
import flixel.FlxSprite;
import objects.playfields.NoteField;
import objects.NoteObject.ObjectType;
class ReverseDirectionModifier extends NoteModifier 
{
	inline function lerp(a:Float, b:Float, c:Float) 
		return a + (b - a) * c;

	override function getOrder() 
		return REVERSE;
	override function getName() 
		return 'reverseD';

	override function shouldExecute(player:Int, val:Float)
		return true;
	override function ignoreUpdateNote()
		return false;

    public function getReverseValue(dir:Int, player:Int){
        var kNum = Note.ammo[PlayState.mania];
        var val:Float = 0;
        if(dir>=kNum * 0.5)
            val += getSubmodValue("splitD", player);

        if((dir%2)==1)
            val += getSubmodValue("alternateD", player);

        var first = kNum * 0.25;
        var last = kNum-1-first;

        if(dir>=first && dir<=last)
            val += getSubmodValue("crossD" ,player);

        val += getValue(player) + getSubmodValue("reverseD" + Std.string(dir), player);


        if(getSubmodValue("unboundedReverseD", player)==0){
            val %=2;
            if(val>1)val=2-val;
        }

       	if(ClientPrefs.data.downScroll)
            val = 1 - val;

        return val;
    }

	private inline function getCenterValue(player:Int){
		var centerPercent = getSubmodValue("centeredD", player);
		return centerPercent;
	}

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:NoteObject, field:NoteField)
	{
		var swagOffset = Note.halfWidth + modMgr.vPadding; // maybe vPadding can be a field variable?
		var reversePerc = getReverseValue(data, player);
		var shift = lerp(swagOffset, FlxG.height - swagOffset, reversePerc);
		
		var centerPercent = getCenterValue(player);		
		shift = lerp(shift, (FlxG.height * 0.5), centerPercent);

		var ogpos:Vector3 = pos;
		
		pos.y = shift + lerp(visualDiff, -visualDiff, reversePerc);

		if ((obj.objType == NOTE))
		{
			var n:Note = cast obj;
			pos.y += n.typeOffsetY;
		}

        pos.y += obj.offsetY;

		if ((obj.objType == NOTE))
			return pos;
		
		return ogpos;
	}

    override function getSubmods(){
        var subMods:Array<String> = ["crossD", "splitD", "alternateD", "centeredD", "unboundedReverseD"];

		for (i in 0...Note.ammo[PlayState.mania]){
            subMods.push('reverseD${i}');
        }

        return subMods;
    }
}