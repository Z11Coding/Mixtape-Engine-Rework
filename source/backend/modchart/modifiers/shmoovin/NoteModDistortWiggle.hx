/**
 * @ Author: 4mbr0s3 2
 * @ Create Time: 2021-07-28 14:01:52
 * @ Modified by: 4mbr0s3 2
 * @ Modified time: 2021-12-01 17:36:32
 */

package false_paradise.note_mods;

import lime.math.Vector4;
import schmovin.SchmovinPlayfield;
import schmovin.note_mods.NoteModBase;

class NoteModDistortWiggle extends NoteModBase
{
	override function executePath(currentBeat:Float, strumTime:Float, column:Int, player:Int, pos:Vector4, playfield:SchmovinPlayfield):Vector4
	{
		var outPos = pos.clone();
		var period = getOtherPercent('distortwiggleperiod', playfield) + 200;
		var scratch = getOtherPercent('distortwigglescratch', playfield);
		outPos.x += Math.sin(outPos.y / period + currentBeat + scratch) * getPercent(playfield) * 20;
		return outPos;
	}
}
