/**
 * @ Author: 4mbr0s3 2
 * @ Create Time: 2021-07-22 20:28:12
 * @ Modified by: 4mbr0s3 2
 * @ Modified time: 2021-12-01 17:34:39
 */

package false_paradise.note_mods;

import lime.math.Vector4;
import schmovin.SchmovinPlayfield;
import schmovin.note_mods.NoteModBase;

class NoteModWiggle extends NoteModBase
{
	override function executePath(currentBeat:Float, strumTime:Float, column:Int, player:Int, pos:Vector4, playfield:SchmovinPlayfield):Vector4
	{
		var outPos = pos.clone();
		// Ah yes "wiggle"
		outPos.x += Math.sin(currentBeat) * getPercent(playfield) * 20;
		outPos.y += Math.sin(currentBeat + 1) * getPercent(playfield) * 20;
		if (getPercent(playfield) > 0)
			setOtherPercent(Math.sin(currentBeat) * 0.2 * getPercent(playfield), 'rotatez', player);
		return outPos;
	}
}
