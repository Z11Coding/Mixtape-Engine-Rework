/**
 * @ Author: 4mbr0s3 2
 * @ Create Time: 2021-07-27 22:21:43
 * @ Modified by: 4mbr0s3 2
 * @ Modified time: 2021-12-01 17:38:13
 */

package false_paradise.note_mods;

import flixel.FlxG;
import flixel.math.FlxMath;
import lime.math.Vector4;
import schmovin.SchmovinPlayfield;
import schmovin.SchmovinUtil.Receptor;
import schmovin.note_mods.NoteModBase;

// IDK what this is called in nITG
// I think it's like centered something
// It's kinda similar to Cytus
class NoteModReceptorScroll extends NoteModBase
{
	override function executePath(currentBeat:Float, strumTime:Float, column:Int, player:Int, pos:Vector4, playfield:SchmovinPlayfield):Vector4
	{
		var outPos = pos.clone();

		var strumTime = strumTime - Conductor.songPosition;
		var time = -strumTime / Conductor.crochet / 4;
		var alt = Math.floor(time) % 2 == 0;
		var outTime = time % 1;
		if (alt)
			outTime = 1 - outTime;
		var upscrollY = Note.swagWidth / 2 + 50 + (FlxG.height - 50 - Note.swagWidth) * outTime;
		outPos.y = FlxMath.lerp(outPos.y, upscrollY, getPercent(playfield));

		return outPos;
	}

	override function executeNote(currentBeat:Float, note:Note, player:Int, pos:Vector4, playfield:SchmovinPlayfield)
	{
		super.executeNote(currentBeat, note, player, pos, playfield);
		if (getPercent(playfield) <= 0)
			return;
		var bar = Conductor.songPosition / Conductor.crochet / 4;

		var time = note.strumTime - Conductor.songPosition;
		note.alpha = FlxMath.bound((1400 - time) / 200, 0, 0.3);
		if (note.strumTime < Math.floor(bar + 1) * Conductor.crochet * 4)
			note.alpha = 1;
	}

	override function deactivate(receptors:Array<Receptor>, notes:Array<Note>)
	{
		super.deactivate(receptors, notes);
		trace(notes);
		for (n in notes)
		{
			if (!n.isSustainNote)
				n.alpha = 1;
		}
	}
}
