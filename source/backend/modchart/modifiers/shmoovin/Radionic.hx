package backend.modchart.modifiers.shmoovin;

import backend.funkinmodchart.backend.util.ModchartUtil;

// Circular motion based on the lane.
// Naming this `Radionic` since it seems like a Radionic Graphic.
// Inspired by `The Poenix NotITG Modchart` at 0:35
// Warning!: This should be AFTER regular modifiers (drunk, beat, transform, etc) and BEFORE rotation modifiers.
class Radionic extends NoteModifier {
	override function getName()return 'radionic';
	override function getPos( visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:NoteObject, field:NoteField) {
		final perc = getValue(player);

		if (perc == 0)
			return pos;

		final modArray = modMgr.getActiveMods(player);

		final reverse = modMgr.register.get('reverse');

		final angle = ((1 / Conductor.crochet) * ((Conductor.songPosition + visualDiff) * Math.PI * .25) + (Math.PI * player));
		final offsetX = pos.x - field.field.strumNotes[data].x;
		final offsetY = (reverse != null ? (pos.y - reverse.getPos(visualDiff, timeDiff, beat, pos, data, player, obj, field).y) : 0);

		final circf = Note.swagWidth + data * Note.swagWidth;

		final sinAng = sin(angle);
		final cosAng = cos(angle);

		final radionicVec = new Vector3();

		radionicVec.x = FlxG.width * 0.5 + ((sinAng * offsetY + cosAng * (circf + offsetX)) * 0.7) * 1.125;
		radionicVec.y = FlxG.height * 0.5 + ((cosAng * offsetY + sinAng * (circf + offsetX)) * 0.7) * 0.875;
		radionicVec.z = pos.z;

		return pos.lerp(radionicVec, perc, pos);
	}

	// should i include this?
	// nah i will do this manually

	/*
		override public function visuals(data:Visuals, params:RenderParams):Visuals
		{
			final perc = getPercent('radionic', params.player);
			final amount = 0.6;

			vis.scaleX = perc * (vis.scaleY = 1 + amount - FlxEase.cubeOut((params.curBeat - Math.floor(params.curBeat))) * amount);
			vis.glow = perc * (-(amount - FlxEase.cubeOut((params.curBeat - Math.floor(params.curBeat))) * amount) * 2);

			return vis;
	}*/
}
