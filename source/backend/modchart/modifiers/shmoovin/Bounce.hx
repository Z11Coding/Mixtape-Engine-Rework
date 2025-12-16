package backend.modchart.modifiers.shmoovin;

class Bounce extends NoteModifier {
	override function getName() return 'shmoovinBounce';
	override function getPos( visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField) {
		var speed = getSubmodValue('shmoovinBounceSpeed', player);
		var offset = getSubmodValue('shmoovinBounceOffset', player);

		var bounce = Math.abs(sin((beat + offset) * (1 + speed) * Math.PI)) * Note.swagWidth;

		pos.x += bounce * getSubmodValue('shmoovinBounceX', player);
		pos.y += bounce * (getValue(player) + getSubmodValue('shmoovinBounceY', player));
		pos.z += bounce * getSubmodValue('shmoovinBounceZ', player);

		return pos;
	}

	override function getSubmods(){
		var subMods:Array<String> = ["shmoovinBounceSpeed", "shmoovinBounceOffset", "shmoovinBounceX", "shmoovinBounceY", "shmoovinBounceZ"];

		return subMods;
	}
}
