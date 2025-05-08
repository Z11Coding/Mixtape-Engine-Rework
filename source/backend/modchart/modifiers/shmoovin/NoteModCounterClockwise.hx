/**
 * @ Author: 4mbr0s3 2
 * @ Create Time: 2021-07-15 16:30:14
 * @ Modified by: 4mbr0s3 2
 * @ Modified time: 2021-12-01 17:36:39
 */

package false_paradise.note_mods;

import flixel.FlxG;
import flixel.math.FlxMath;
import groovin.util.GroovinConductor;
import lime.math.Vector4;
import schmovin.SchmovinPlayfield;
import schmovin.note_mods.NoteModBase;

using schmovin.SchmovinUtil;

class NoteModCounterClockwise extends NoteModBase
{
	override function executePath(currentBeat:Float, strumTime:Float, column:Int, player:Int, pos:Vector4, playfield:SchmovinPlayfield):Vector4
	{
		var strumTime = Conductor.songPosition - strumTime;
		var centerX = FlxG.width / 2;
		var centerY = FlxG.height / 2;
		var radiusOffset = Note.swagWidth * ((column % 4) - 1.5);
		var radius = 200 + radiusOffset * Math.cos(strumTime / Conductor.stepCrochet / 16 * Math.PI);
		var outX = centerX + Math.cos(strumTime / GroovinConductor.getCrotchetNow() / 4 * Math.PI) * radius;
		var outY = centerY + Math.sin(strumTime / GroovinConductor.getCrotchetNow() / 4 * Math.PI) * radius;

		return SchmovinUtil.vec4Lerp(pos, new Vector4(outX, outY, 0, 0), getPercent(playfield));
	}

	override function executeNote(currentBeat:Float, note:Note, player:Int, pos:Vector4, playfield:SchmovinPlayfield)
	{
		var time = note.strumTime - Conductor.songPosition;
		note.alpha = FlxMath.bound((1400 - time) / 100, 0, 1);
	}

	override function deactivate(receptors:Array<Receptor>, notes:Array<Note>)
	{
		super.deactivate(receptors, notes);
		for (n in notes)
		{
			if (!n.isSustainNote)
				n.alpha = 1;
		}
	}
}
