/**
 * @ Author: 4mbr0s3 2
 * @ Create Time: 2021-08-29 01:51:39
 * @ Modified by: 4mbr0s3 2
 * @ Modified time: 2021-12-01 17:38:30
 */

package false_paradise.note_mods;

import flixel.FlxG;
import flixel.math.FlxMath;
import groovin.util.GroovinConductor;
import lime.math.Vector4;
import schmovin.SchmovinPlayfield;
import schmovin.note_mods.NoteModBase;

using schmovin.SchmovinUtil;

class NoteModSpiral extends NoteModBase
{
	override function executePath(currentBeat:Float, strumTimeDiff:Float, column:Int, player:Int, pos:Vector4, playfield:SchmovinPlayfield):Vector4
	{
		var centerX = FlxG.width / 2;
		var centerY = FlxG.height / 2;
		var radiusOffset = -strumTimeDiff / 4;
		var radius = radiusOffset + getOtherPercent('spiraldist', playfield) * column % 4;
		var outX = centerX + Math.cos(-strumTimeDiff / GroovinConductor.getCrotchetNow() * Math.PI + currentBeat * Math.PI / 4) * radius;
		var outY = centerY + Math.sin(-strumTimeDiff / GroovinConductor.getCrotchetNow() * Math.PI - currentBeat * Math.PI / 4) * radius;

		return SchmovinUtil.vec4Lerp(pos, new Vector4(outX, outY, radius / FlxG.height * 2 - 1, 0), getPercent(playfield));
	}
}
