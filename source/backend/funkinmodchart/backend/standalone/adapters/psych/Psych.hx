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
import objects.SustainSplash;
import states.PlayState;

class Psych implements IAdapter {
	private var __fCrochet:Float = 0;

	public function new() {
		try {
			setupLuaFunctions();
		} catch (e) {
			trace('[FunkinModchart Psych Adapter] Failed while adding lua functions: $e');
		}
	}

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
		return Conductor.songPosition;
	}

	public function getCurrentBeat():Float {
		@:privateAccess
		return PlayState.instance.curDecBeat;
	}

	public function getCurrentCrochet():Float {
		return Conductor.crochet;
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
			return cast(arrow, Note).noteData;
		else if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).noteData;
		#if (FM_ENGINE_VERSION >= "1.0")
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.noteData;
		#end

		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).mustPress ? 1 : 0;
		if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).player;
		#if (FM_ENGINE_VERSION >= "1.0")
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.player;
		#end
		return 0;
	}

	public function getKeyCount(?player:Int = 0):Int {
		return (PlayState.mania+1);
	}

	public function getPlayerCount():Int {
		return 2;
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

	inline function getStrumFromInfo(lane:Int, player:Float) {
		var group = player == 0 ? PlayState.instance.opponentStrums : PlayState.instance.playerStrums;
		var strum = null;
		group.forEach(str -> {
			@:privateAccess
			if (str.noteData == lane)
				strum = str;
		});
		return strum;
	}

	// Using the Troll Engine redition for consistancy
	public var playerAmount:Int = 2;
	public var playerOOBIsCentered:Bool = true; // Player Out of Bounds is centered
	public var vPadding:Float = 45;

	public function getDefaultReceptorX(lane:Int, player:Float):Float {
		var strum = getStrumFromInfo(lane, player);
		if (strum == null) return 0;
		if (playerOOBIsCentered && (player >= playerAmount || player < 0))
			player = 0.5; // replicating old behaviour for upcoming modcharts

		var spaceWidth = FlxG.width / playerAmount;
		var spaceX = spaceWidth * (playerAmount-1-player);

		var baseX:Float = spaceX + (spaceWidth - (Note.swagWidthAlt * Note.scales[getKeyCount()]) * getKeyCount()) * 0.5;
		var x:Float = baseX + (Note.swagWidthAlt * Note.scales[getKeyCount()]) * lane;

		return x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		var strum = getStrumFromInfo(lane, player);
		if (strum == null) return 0;
		return getDownscroll() ? FlxG.height - strum.y - Note.swagWidth : strum.y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float {
		return PlayState.instance.songSpeed * .45;
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
