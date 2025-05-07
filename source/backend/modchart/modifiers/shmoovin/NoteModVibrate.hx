/**
 * @ Author: 4mbr0s3 2
 * @ Create Time: 2021-07-22 20:28:12
 * @ Modified by: 4mbr0s3 2
 * @ Modified time: 2021-12-01 17:34:45
 */

package false_paradise.note_mods;

import lime.math.Vector4;
import schmovin.SchmovinPlayfield;
import schmovin.note_mods.NoteModBase;

class NoteModVibrate extends NoteModBase
{
	override function executePath(currentBeat:Float, strumTime:Float, column:Int, player:Int, pos:Vector4, playfield:SchmovinPlayfield):Vector4
	{
		var outPos = pos.clone();
		outPos.x += (Math.random() - 0.5) * getPercent(playfield) * 20;
		outPos.y += (Math.random() - 0.5) * getPercent(playfield) * 20;
		return outPos;
	}
}
