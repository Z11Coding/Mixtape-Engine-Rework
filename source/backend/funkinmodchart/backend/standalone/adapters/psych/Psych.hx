package backend.funkinmodchart.backend.standalone.adapters.psych;

import backend.ClientPrefs;
import backend.Conductor;
import backend.funkinmodchart.Manager;
import backend.funkinmodchart.backend.standalone.IAdapter;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote as Strum;
import states.PlayState;

class Psych implements IAdapter {
	private var __fCrochet:Float = 0;

	public function new() {
		try {
			setupLuaFunctions();
		} catch (e) {
			trace('[FunkinModchart Mixtape Adapter] Failed while adding lua functions: $e');
		}
	}

	public function onModchartingDispose() {}

	public function onModchartingInitialization() {
		__fCrochet = (Conductor.crochet + 8) / 4;
	}

	private function setupLuaFunctions() {
		#if LUA_ALLOWED
		// todo
		#end
	}

	public function isTapNote(sprite:FlxSprite) {
		return sprite is Note;
	}

	// Song related
	public function getSongPosition():Float {
		return MegaManager.conductor.musicPosition;
	}

	public function getCurrentBeat():Float {
		@:privateAccess
		return MegaManager.conductor.currentBeatTime;
	}

	public function getCurrentCrochet():Float {
		return RConductor.crochet;
	}

	public function getBeatFromStep(step:Float)
		return step * .25;

	public function arrowHit(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).wasGoodHit;
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		if (arrow is Note) {
			final castedNote = cast(arrow, Note);

			if (castedNote.nextNote != null)
				return !castedNote.nextNote.isSustainNote;
		}
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).column;
		else if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).column;
		#if (FM_ENGINE_VERSION >= "1.0")
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.column;
		#end

		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).mustPress ? 0 : 1;
		if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).player;
		#if (FM_ENGINE_VERSION >= "1.0")
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.player;
		#end
		return 0;
	}

	public function getKeyCount(?player:Int = 0):Int {
		return (PlayfieldManager.mania[player]+1);
	}

	public function getPlayerCount():Int {
		return MegaManager.playfield.playfields.length;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).strumTime;

		return 0;
	}

	public function getHoldSubdivisions(hold:FlxSprite):Int {
		return 4;
	}

	public function getHoldLength(item:FlxSprite):Float
		return __fCrochet;

	public function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		return note.parent.strumTime;
	}

	public function getDownscroll():Bool {
		#if (FM_ENGINE_VERSION >= "0.7")
		return ClientPrefs.data.downScroll;
		#else
		return ClientPrefs.downScroll;
		#end
	}

	inline function getStrumFromInfo(lane:Int, player:Int):StrumNote {
		var group = MegaManager.playfield.playfields.members[player].strumNotes;
		var strum = null;
		for (str in group) {
			if (str.column == lane)
				strum = str;
		};
		return strum;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		return getStrumFromInfo(lane, player).x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		return getDownscroll() ? FlxG.height - getStrumFromInfo(lane, player).y - Note.swagWidth : getStrumFromInfo(lane, player).y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float {
		return PlayfieldManager.SONGSpeed * .45;
	}

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []]];

		@:privateAccess
		PlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
			if (pspr[strumNote.player] == null)
				pspr[strumNote.player] = [];

			pspr[strumNote.player][0].push(strumNote);
		});
		PlayState.instance.notes.forEachAlive(strumNote -> {
			final player = Adapter.instance.getPlayerFromArrow(strumNote);
			if (pspr[player] == null)
				pspr[player] = [];

			pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
		});
		#if (FM_ENGINE_VERSION >= "1.0")
		PlayState.instance.grpNoteSplashes.forEachAlive(splash -> {
			@:privateAccess
			if (splash.babyArrow != null && splash.active) {
				final player = splash.babyArrow.player;
				if (pspr[player] == null)
					pspr[player] = [];

				pspr[player][3].push(splash);
			}
		});
		#end

		return pspr;
	}
}
