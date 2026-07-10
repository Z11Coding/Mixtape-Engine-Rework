package objects.playfields;

import backend.MusicBeatState.pubCurDecBeat as curDecBeat;
import backend.modchart.ModManager;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import lime.app.Event;
import objects.notes.*;
import states.PlayState.instance as game;
import states.PlayState;

/*
The system is seperated into 3 classes:

- PlayField
	- This is the gameplay component.
	- This keeps track of notes and updates them
	- This is typically per-player, and can control multiple characters, can be locked up, etc.
	- You can also swap which PlayField a player is actually controlling n all that

- NoteField
	- This is the rendering component.
	- This can be created seperately from a PlayField to duplicate the notes multiple times, for example.
	- Needs to be linked to a PlayField though, so it can keep track of what notes exist, when notes get hit (to update receptors), etc.

- ProxyField
	- Clones a NoteField
	- This cannot have its own modifiers, etc applied. All this does is render whatever's in the NoteField
	- If you need to duplicate one PlayField a bunch, you should be using ProxyFields as they are far more optimized it only calls the mod manager for the initial notefield, and not any ProxyFields
	- One use case is if you wanna include an infinite NoteField effect (i.e the end of The Government Knows by FMS_Cat, or get f**ked from UKSRT8)
*/

/*
	If you use this code, please credit me (Nebula) and 4mbr0s3 2
	Or ATLEAST credit 4mbr0s3 2 since he did the cool stuff of this system (hold note manipulation)

	Note that if you want to use this in other mods, you'll have to do some pretty drastic changes to a bunch of classes (PlayState, Note, Conductor, etc)
	If you can make it work in other engines then epic but its best to just use this engine tbh
 */

typedef NoteCallback = (Note, PlayField) -> Void;

class PlayField extends FlxTypedGroup<FlxBasic>
{
	/** character that owns this playfield **/
	public var owner:Character;
	/** character(s) that owns this playfield (OVERRIDES OWNER VARIABLE IF NOT NULL/EMPTY!) **/
	public var owners:Array<Character>;
	/** tracks managed by this field **/
	public var tracks:Array<FlxSound> = [];
	/** used to calculate the base position of the strums **/
	public var playerId(default, set):Int = 0;

	/** spawn time for notes **/
	public var spawnTime:Float = 1750;
	/** spawned notes **/
	public var spawnedNotes:Array<Note> = [];

	/** spawned notes by data. Used for input **/
	public var spawnedByData:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []];
	/** spawned tap notes (with requiresTap) per column. Used for input but can't change spawnedByData cus of holds n shit lol! **/
	public var tapsByData:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []];
	/** spawned tap notes (without requiresTap) per column. Used for input but can't change spawnedByData cus of holds n shit lol! **/
	public var noTapsByData:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []];
	/** unspawned notes **/
	public var noteQueue:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []];

	/** receptors **/
	public var strumNotes:Array<StrumNote> = [];
	/** characters that sing when field is hit **/
	public var characters:Array<Character> = [];
	/** default character animations to play for each column **/
	public var singAnimations:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

	/** note renderer **/
	public var noteField:NoteField;
	/** the mod manager. will be set automatically by playstate so dw bout this **/
	public var modManager:ModManager;
	/** used for the mod manager. can be set to a different number to give it a different set of modifiers. can be set to 0 to sync the modifiers w/ bf's, and 1 to sync w/ the opponent's **/
	public var modNumber:Int = 0;
	/** if this playfield takes input from the player **/
	public var isPlayer:Bool = false;
	/** if this playfield will take input at all **/
	public var inControl:Bool = true;
	/** if this playfield is played by the "AI" instead **/
	public var AIPlayer:Bool = false;
	/** How many lanes are in this field **/
	public var keyCount(default, set):Int = 4;
	/** if this playfield should be played automatically (botplay, opponent, etc) **/
	public var autoPlayed(default, set):Bool = false;
	/** Because the charting state playstate is "special" **/
	public var isEditor:Bool = false;

	public var x:Float = 0;
	public var y:Float = 0;

	/** things that get added above the receptors. **/
	public static var extraStuff:FlxTypedGroup<FlxBasic>;

	/** function that gets called when the note is hit. goodNoteHit and opponentNoteHit in playstate for eg **/
	public var noteHitCallback:NoteCallback;
	/** function that gets called when a hold is stepped on. Only really used for calling script events. Return 'false' to not do hold logic **/
	public var holdPressCallback:NoteCallback;
	/** function that gets called when a hold is released. Only really used for calling script events. **/
	public var holdReleaseCallback:NoteCallback;
	/** function that gets called for every 'step' that a hold is pressed for. **/
	public var holdStepCallback:NoteCallback;

	/** notesplashes **/
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	/** things that get "attached" to the receptors. custom splashes, etc. **/
	public var strumAttachments:FlxTypedGroup<NoteObject>;

 	/** Event that gets called every time you miss a note. **/
	public var noteMissed = new Event<NoteCallback>();
	/** Event that gets called every time a note is removed. **/
	public var noteRemoved = new Event<NoteCallback>();
	/** Event that gets called every time a note is spawned. **/
	public var noteSpawned = new Event<NoteCallback>();
	/** Event that gets called every time a hold is dropped **/
	public var holdDropped = new Event<NoteCallback>();
	/** Event that gets called every time a hold is finished **/
	public var holdFinished = new Event<NoteCallback>();
	/** Event that gets called every time a hold is updated **/
	public var holdUpdated = new Event<(Note, PlayField, Float) -> Void>();

	/** what keys are pressed rn **/
	public var keysPressed:Array<Bool> = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false];
	public var isHolding:Array<Bool> = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false];

	public var baseXPositions:Array<Float> = [];
	public var baseYPositions:Array<Float> = [];

	private var defaultSingAnimations = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
	private var garbage:Array<Note> = [];


	public function new(modMgr:ModManager, ?keyCount:Int){
		super();
		this.modManager = modMgr ?? game?.modManager;
		this.keyCount = keyCount == null ? Note.ammo[PlayState.mania] : keyCount;

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashes.visible = false; // so they dont get drawn
		add(grpNoteSplashes);

		strumAttachments = new FlxTypedGroup<NoteObject>();
		strumAttachments.visible = false;
		add(strumAttachments);

		if (ClientPrefs.data.noteSplashes) {
			var splash:NoteSplash = new NoteSplash(100, 100, 0);
			splash.handleRendering = false;
			splash.alpha = 0.0;
			grpNoteSplashes.add(splash);
		}

		////
		noteField = new NoteField(this, modMgr);
	}

	// Anything that is static/used by both strums but cant be double-initialized can be placed here
	// Keep in mind, this runs AFTER the strums are made.
	public static function initExtras()  {
		extraStuff = new FlxTypedGroup<FlxBasic>();
	}

	/** queues a note to be spawned **/
	public function queue(note:Note){
		if (noteQueue[note.column] == null)
			noteQueue[note.column] = [note];
		else{
			noteQueue[note.column].push(note);
			noteQueue[note.column].sort(sortNotesAscend);
		}
	}

	/** unqueues a note **/
	public function unqueue(note:Note)
	{
		if (noteQueue[note.column] != null) {
			noteQueue[note.column].remove(note);
			noteQueue[note.column].sort(sortNotesAscend);
		}
	}

	/** destroys a note **/
	public function removeNote(daNote:Note){
		daNote.active = false;
		daNote.visible = false;
		daNote.kill();

		noteRemoved.dispatch(daNote, this);

		daNote.kill();
		spawnedNotes.remove(daNote);
		aliveNoteCount--;
		if (spawnedByData[daNote.column] != null)
			spawnedByData[daNote.column].remove(daNote);

		if (tapsByData[daNote.column] != null)
			tapsByData[daNote.column].remove(daNote);

		if (noTapsByData[daNote.column] != null)
			noTapsByData[daNote.column].remove(daNote);

		if (noteQueue[daNote.column] != null)
			noteQueue[daNote.column].remove(daNote);

		if (daNote.unhitTail.length > 0)
			while (daNote.unhitTail.length > 0)
				removeNote(daNote.unhitTail.shift());


		if (daNote.parent != null)
			daNote.parent.tail.remove(daNote);

 		if (daNote.parent != null)
			daNote.parent.unhitTail.remove(daNote);

		if (noteQueue[daNote.column] != null)
			noteQueue[daNote.column].sort(sortNotesAscend);

		/* Keep this just in case
		if (killTail) {
			if (daNote.unhitTail.length > 0)
				while (daNote.unhitTail.length > 0)
					removeNote(daNote.unhitTail.shift());
		}

		if (daNote.parent != null && daNote.parent.tail.contains(daNote))
			daNote.parent.tail.remove(daNote);

 		if (daNote.parent != null && daNote.parent.unhitTail.contains(daNote))
			daNote.parent.unhitTail.remove(daNote);

		if (noteQueue[daNote.column] != null)
			noteQueue[daNote.column].sort(sortNotesAscend);*/

		remove(daNote);
		daNote.destroy();
	}

	/** spawns a note **/
	public function spawnNote(note:Note){
		if(note.spawned)
			return;

		if (noteQueue[note.column]!=null){
			noteQueue[note.column].remove(note);
			noteQueue[note.column].sort(sortNotesAscend);
		}

		if (spawnedByData[note.column] != null)
			spawnedByData[note.column].push(note);
		else
			return;


		if(note.holdType == HEAD || note.holdType == TAP){
			if(note.requiresTap){
				if (tapsByData[note.column] != null)
					tapsByData[note.column].push(note);
			}else{
				if (noTapsByData[note.column] != null)
					noTapsByData[note.column].push(note);
			}

		}

		// Finalize note if "Finalize at Birth" option is enabled or note is not finalized
		if (!note.finalized && (ClientPrefs.data.finalizeAtBirth || !ClientPrefs.data.preloadSong)) {
			note.finalize();
		}

		noteSpawned.dispatch(note, this);
		spawnedNotes.push(note);
		aliveNoteCount++;
		note.handleRendering = false;
		note.spawned = true;

		insert(0, note);
	}

	/** gets all notes in the playfield, spawned or otherwise. **/
	public function getAllNotes(?column:Int){
		var arr:Array<Note> = [];
		if (column == null) {
			for (queue in noteQueue) {
				for (note in queue)
					arr.push(note);
			}
		}else {
			for (note in noteQueue[column])
				arr.push(note);
		}
		for (note in spawnedNotes)
			arr.push(note);
		return arr;
	}

	/** Returns true if this PlayField has the note, false otherwise. **/
	public function hasNote(note:Note)
		return spawnedNotes.contains(note) || noteQueue[note.column]!=null && noteQueue[note.column].contains(note);

	var closestNotes:Array<Note> = [];
	var strumsBlocked:Array<Bool> = [];
	/** Sends an input to the PlayField **/
	public function inputDown(column:Int, ?hitTime:Float):Null<Note> {
		if (column < 0 || column > keyCount)
			return null;

		if (!PlayState.instance.boyfriend.stunned)
		{
			switch (ClientPrefs.data.inputSystem)
			{
				case "Troll Engine New":
					hitTime ??= Conductor.songPosition;
					keysPressed[column] = true;

					var noteList = getTapNotes(column, (note:Note) -> !note.tooLate);
					noteList.sort(sortNotesDescend); // so lowPriority actually works (even though i hate it lol!)

					var retNote:Null<Note> = null;
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						if (note.wasGoodHit && note.holdType == HEAD && note.holdingTime < note.sustainLength)
							retNote = note; // recent hold for the sake of ghost-tapping shit.
							// returned lower so that holds dont interrupt hitting other notes as, even though that'd make sense, it also feels like shit to play on some songs i.e Bopeebo
						else{
							if (note.wasGoodHit)
								continue;

							if (!note.forceBlockHit)
								noteHitCallback(note, this);
							retNote = note;
						}
					}

					if (retNote == null) {
						var receptor:StrumNote = strumNotes[column];
						if (receptor != null) {
							receptor.playAnim('pressed', true);
							receptor.resetAnim = 0;
						}
					}

					return retNote;
				case "Troll Engine":
					hitTime ??= Conductor.songPosition;

					var noteList = getTapNotes(column, (note:Note) -> !note.tooLate);
					noteList.sort(sortNotesDescend); // so lowPriority actually works (even though i hate it lol!)

					var recentHold:Null<Note> = null;

					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						if (note.wasGoodHit && note.holdType == HEAD && note.holdingTime < note.sustainLength)
							recentHold = note; // for the sake of ghost-tapping shit.
							// returned lower so that holds dont interrupt hitting other notes as, even though that'd make sense, it also feels like shit to play on some songs i.e Bopeebo
						else{
							if (note.wasGoodHit)
								continue;

							if (!note.forceBlockHit)
								noteHitCallback(note, this);
							return note;
						}
					}

					return recentHold;
				case "Native":
					if(column > keyCount || column < 0)return null;

					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.tooLate);
					#if PE_MOD_COMPATIBILITY
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)
					#else
					noteList.sort((a, b) -> Std.int(b.strumTime - a.strumTime)); //so lowPriority actually works (even though i hate it lol!)
					#end
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						if (!note.blockHit || !note.forceBlockHit) noteHitCallback(note, this);
						return note;
					}
				case "Native-old":
					if(column > keyCount || column < 0)return null;

					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> note.requiresTap);
					#if PE_MOD_COMPATIBILITY
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)
					#else
					noteList.sort((a, b) -> Std.int(b.strumTim - a.strumTime)); // so lowPriority actually works (even though i hate it lol!)
					#end
					var recentHold:Null<Note> = null;
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						if (note.wasGoodHit && note.holdingTime < note.sustainLength)
							recentHold = note; // for the sake of ghost-tapping shit.
							// returned lower so that holds dont interrupt hitting other notes as, even though that'd make sense, it also feels like shit to play on some songs i.e Bopeebo
						else {
							if (note.wasGoodHit)
								continue;
							if (!note.blockHit || !note.forceBlockHit) noteHitCallback(note, this);
							return note;
						}
					}
					return recentHold;
				case 'Rhythm':
					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						var hitDiff = Math.abs(note.strumTime - Conductor.songPosition);
						var allowedError = ClientPrefs.data.badWindow * 0.05; // 5% error margin
						if (hitDiff <= allowedError)
						{
							if (!note.forceBlockHit)
								noteHitCallback(note, this);
							return note;
						}
					}
					// Check if the note is still being held when it ends
					for (note in spawnedNotes)
					{
						if (note.column == column && note.isSustainNote && note.wasGoodHit && !note.tooLate && note.holdingTime >= note.sustainLength)
						{
							note.tooLate = true;
							note.wasGoodHit = false;
							if (inControl) noteMissed.dispatch(note, this);
							return note;
						}
					}
					if (!ClientPrefs.data.ghostTapping)
					{
						PlayState.instance.ogNoteMissPress(column);
					}
				case 'BEAT! Engine':
					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);

					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)

					// more accurate hit time for the ratings?
					var lastTime:Float = Conductor.songPosition;
					Conductor.songPosition = FlxG.sound.music.time;

					var canMiss:Bool = !ClientPrefs.data.ghostTapping;

					// heavily based on my own code LOL if it aint broke dont fix it
					var pressNotes:Array<Note> = [];
					// var notesDatas:Array<Int> = [];
					var notesStopped:Bool = false;

					if (!ClientPrefs.data.noAntimash)
					{ // shut up
						canMiss = true;
					}

					if (noteList.length > 0)
					{
						for (epicNote in noteList)
						{
							for (doubleNote in pressNotes)
							{
								if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
								{
									removeNote(doubleNote);
								}
								else
									notesStopped = true;
							}

							// eee jack detection before was not super good
							if (!notesStopped && !epicNote.forceBlockHit)
							{
								pressNotes.push(epicNote);
								var note:Note = noteList.pop();
								noteHitCallback(note, this);
								return note;
							}
						}
					}
					else if (canMiss)
					{
						PlayState.instance.ogNoteMissPress(column);
					}

					// I dunno what you need this for but here you go
					//									- Shubs

					// Shubs, this is for the "Just the Two of Us" achievement lol
					//									- Shadow Mario
					keysPressed[column] = true;

					// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
					Conductor.songPosition = lastTime;
				case 'Kade Engine': // 1.8 input btw
					var canMiss:Bool = !ClientPrefs.data.ghostTapping;

					keysPressed[column] = true;

					closestNotes = [];

					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)
					for (daNote in noteList)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.wasGoodHit)
							closestNotes.push(daNote);
					}

					closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					var dataNotes:Array<Note> = [];
					for (i in closestNotes)
						if (i.noteData == column && !i.isSustainNote)
							dataNotes.push(i);

					if (dataNotes.length != 0)
					{
						var coolNote = null;

						for (i in dataNotes)
						{
							coolNote = i;
							break;
						}

						if (dataNotes.length > 1) // stacked notes or really close ones
						{
							for (i in 0...dataNotes.length)
							{
								if (i == 0) // skip the first note
									continue;

								var note = dataNotes[i];

								if (!note.isSustainNote && ((note.strumTime - coolNote.strumTime) < 2) && note.noteData == column)
								{
									trace('found a stacked/really close note ' + (note.strumTime - coolNote.strumTime));
									// just fuckin remove it since it's a stacked note and shouldn't be there
									removeNote(note);
								}
							}
						}

						var note:Note = dataNotes.pop();
						if (!note.forceBlockHit)
							noteHitCallback(note, this);
						return note;
					}
					else if (canMiss)
					{
						PlayState.instance.ogNoteMissPress(column);
					}
				case 'ZoroForce EK':
					var hittableNotes = [];
					var closestNotes = [];

					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)
					for (daNote in noteList)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
						{
							closestNotes.push(daNote);
						}
					}
					closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					for (i in closestNotes)
						if (i.noteData == column)
							hittableNotes.push(i);

					if (hittableNotes.length != 0)
					{
						var daNote = null;

						for (i in hittableNotes)
						{
							daNote = i;
							break;
						}

						if (daNote == null)
							return null;

						if (hittableNotes.length > 1)
						{
							for (shitNote in hittableNotes)
							{
								if (shitNote.strumTime == daNote.strumTime)
								{
									if (!shitNote.forceBlockHit)
										noteHitCallback(shitNote, this);
									return shitNote;
								}
								else if ((!shitNote.isSustainNote && (shitNote.strumTime - daNote.strumTime) < 15))
								{
									if (!shitNote.forceBlockHit)
										noteHitCallback(shitNote, this);
									return shitNote;
								}
							}
						}
						if (!daNote.forceBlockHit)
							noteHitCallback(daNote, this);
					}
					else if (!ClientPrefs.data.ghostTapping)
						PlayState.instance.ogNoteMissPress(column);

				case "Mic'ed Up Engine":
					PlayState.instance.notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && keysPressed[daNote.noteData])
						{
							if (!daNote.forceBlockHit)
								noteHitCallback(daNote, this);
						}
					});

					// PRESSES, check for note hits
					var possibleNotes:Array<Note> = []; // notes that can be hit
					var directionList:Array<Int> = []; // directions that can be hit
					var dumbNotes:Array<Note> = []; // notes to kill later

					PlayState.instance.notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
						{
							if (directionList.contains(daNote.noteData))
							{
								for (coolNote in possibleNotes)
								{
									if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
									{ // if it's the same note twice at < 10ms distance, just delete it
										// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
										dumbNotes.push(daNote);
										break;
									}
									else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
									{ // if daNote is earlier than existing note (coolNote), replace
										possibleNotes.remove(coolNote);
										possibleNotes.push(daNote);
										break;
									}
								}
							}
							else
							{
								possibleNotes.push(daNote);
								directionList.push(daNote.noteData);
							}
						}
					});

					for (note in dumbNotes)
					{
						FlxG.log.add("killing dumb ass note at " + note.strumTime);
						note.kill();
						removeNote(note);
						note.destroy();
					}

					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					var dontCheck = false;

					for (i in 0...keysPressed.length)
					{
						if (keysPressed[i] && !directionList.contains(i))
							dontCheck = true;
					}

					if (possibleNotes.length > 0 && !dontCheck || possibleNotes.length > 0 && ClientPrefs.data.noAntimash)
					{
						if (!ClientPrefs.data.ghostTapping)
						{
							for (shit in 0...keysPressed.length)
							{ // if a direction is hit that shouldn't be
								if (keysPressed[shit] && !directionList.contains(shit))
									PlayState.instance.ogNoteMissPress(shit);
							}
						}
						for (coolNote in possibleNotes)
						{
							if (keysPressed[coolNote.noteData])
							{
								if (!coolNote.prevNote.isSustainNote && coolNote.isSustainNote && coolNote.prevNote != null && !ClientPrefs.data.guitarHeroSustains)
								{
									if (!coolNote.forceBlockHit)
										noteHitCallback(coolNote.prevNote, this);
									return coolNote.prevNote;
								}
								if (PlayState.instance.mashViolations != 0)
									PlayState.instance.mashViolations--;
								PlayState.instance.scoreTxt.color = FlxColor.WHITE;
								if (!coolNote.forceBlockHit)
									noteHitCallback(coolNote, this);
								return coolNote;
							}
						}
					}
					else if (!ClientPrefs.data.ghostTapping)
					{
						for (shit in 0...keysPressed.length)
							if (keysPressed[shit])
								PlayState.instance.ogNoteMissPress(shit);
					}

					if (dontCheck && possibleNotes.length > 0 || !ClientPrefs.data.noAntimash && possibleNotes.length > 0)
					{
						if (PlayState.instance.mashViolations > (Note.ammo[PlayState.mania]) && !ClientPrefs.data.noAntimash)
						{
							trace('mash violations ' + PlayState.instance.mashViolations);
							PlayState.instance.scoreTxt.color = FlxColor.RED;
							for (shit in 0...keysPressed.length)
								if (keysPressed[shit])
									PlayState.instance.ogNoteMissPress(shit);
							PlayState.instance.health -= 0.05;
							PlayState.instance.bfkilledcheck = true;
						}
						else
							PlayState.instance.mashViolations++;
					}

				case "Andromeda (legacy)":
					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a,b)->Std.int(a.strumTime-b.strumTime)); // SHOULD be in order?
					// But just incase, we do this sort
					if(noteList.length>0){
						var hitNote = noteList[0];
						if(!hitNote.wasGoodHit) // because parent tap notes
						{
							if (!hitNote.blockHit || !hitNote.forceBlockHit) noteHitCallback(hitNote, this);
							return hitNote;
						}
					}else{
						if(!ClientPrefs.data.ghostTapping)
							PlayState.instance.ogNoteMissPress(column);
					}

				case "YoshiEngine":
					var noteList = getNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)

					var possibleNotes:Array<Note> = [];
					var ignoreList:Array<Int> = [];
					var notesToHit:Array<Note> = [];

					for (i in 0...Note.ammo[PlayState.mania]) notesToHit.push(null);
					for (daNote in noteList)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
						{
							if (keysPressed[(daNote.noteData % Note.ammo[PlayState.mania]) % Note.ammo[PlayState.mania]]) {
								var can = false;
								if (notesToHit[(daNote.noteData % Note.ammo[PlayState.mania]) % Note.ammo[PlayState.mania]] != null) {
									if (notesToHit[(daNote.noteData % Note.ammo[PlayState.mania]) % Note.ammo[PlayState.mania]].strumTime > daNote.strumTime)
										can = true;
									if (notesToHit[(daNote.noteData % Note.ammo[PlayState.mania]) % Note.ammo[PlayState.mania]].strumTime == daNote.strumTime) {
										if (!daNote.forceBlockHit)
											noteHitCallback(daNote, this);
										return daNote;
									}
								} else {
									can = true;
								}
								if (can) notesToHit[(daNote.noteData % Note.ammo[PlayState.mania]) % Note.ammo[PlayState.mania]] = daNote;
							}
						}
					};
					for (note in notesToHit) {
						if (note != null) {
							if (!note.forceBlockHit)
								noteHitCallback(note, this);
							return note;
						}
					}


					for (daNote in noteList)
					{
						if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
						{
							if (keysPressed[(daNote.noteData % Note.ammo[PlayState.mania]) % Note.ammo[PlayState.mania]])
							{
								if (!daNote.forceBlockHit)
									noteHitCallback(daNote, this);
								return daNote;
							}
						}
					};

				case "Kade Engine Community":
					final lastConductorTime:Float = Conductor.songPosition;
					keysPressed[column] = true;

					final closestNotes:Array<Note> = PlayState.instance.notes.members.filter(function(aliveNote:Note)
					{
						return aliveNote != null && aliveNote.alive && aliveNote.canBeHit && aliveNote.mustPress && !aliveNote.wasGoodHit && !aliveNote.isSustainNote
							&& aliveNote.noteData == column;
					});

					final defNotes:Array<Note> = [for (v in closestNotes) v];

					haxe.ds.ArraySort.sort(defNotes, sortNotesAscend);

					if (closestNotes.length != 0)
					{
						final coolNote = defNotes[0];
						if (defNotes.length > 1) // stacked notes or really close ones
						{
							for (i in 0...defNotes.length)
							{
								if (i == 0) // skip the first note
									continue;

								var note = defNotes[i];

								if (!note.isSustainNote && ((note.strumTime - coolNote.strumTime) < 2) && note.noteData == column)
									removeNote(note);
							}
						}

						if (!coolNote.forceBlockHit)
							noteHitCallback(coolNote, this);
						return coolNote;
					}
					else if (!ClientPrefs.data.ghostTapping)
						PlayState.instance.ogNoteMissPress(column);

					Conductor.songPosition = lastConductorTime;
			}
		}
		return null;
	}

	public function inputUp(column:Int, ?hitTIme:Float) {
		keysPressed[column] = false;

		var receptor:StrumNote = strumNotes[column];
		switch(receptor?.animation.name) {
			case 'pressed' | 'confirm':
				if (!isHolding[column]) {
					receptor.playAnim('static');
					receptor.resetAnim = 0;
				}
		}
	}

	/** generates the receptors **/
	public function generateStrums(){
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		for(i in 0...keyCount){
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, this);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = 0;
			insert(0, babyArrow);
			babyArrow.x = getBaseX(i);
			babyArrow.y = strumLineY;
			// Store the initial Y position as base Y position
			baseYPositions[i] = strumLineY;
			babyArrow.handleRendering = false; // NoteField handles rendering
			babyArrow.cameras = cameras;
			@:privateAccess
			babyArrow.player = this.playerId;
			strumNotes.push(babyArrow);
			babyArrow.playerPosition();
		}
	}

	/**
		Does the fade & slide animation for the receptors.
		OYT uses this when mario comes in.
		@param skip If true, the receptors will immediately appear without any animation.
	**/
	public function fadeIn(skip:Bool = false)
	{
		if (skip) {
			for (column => strum in strumNotes)
				strum.alpha = 1;
		}else {
			for (column => strum in strumNotes) {
				FlxTween.tween(strum, {offsetY: strum.offsetY, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (Conductor.crochet / 1000) * column * PlayState.instance.playbackRate});
				strum.offsetY -= strum.downScroll ? -10 : 10;
				strum.alpha = 0;
			}
		}
	}

	/**
		Spawns a notesplash w/ specified skin.
		@param note Optional note to derive the skin and colours from.
	**/
	public function spawnSplash(note:Null<Note>, ?splashSkin:String){
		if (note == null) return null;
		/*
		var skin:String;
		var hue:Float;
		var sat:Float;
		var brt:Float;

		if (note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}else{
			skin = splashSkin;
			hue = sat = brt = 0.0;

			/*var hsb = ClientPrefs.arrowHSV[note.column % 4];
			hue = hsb[0] / 360;
			sat = hsb[1] / 100;
			brt = hsb[2] / 100;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(0, 0, note.column, skin, hue, sat, brt, note);
		splash.handleRendering = false;
		grpNoteSplashes.add(splash);
		return splash;*/

		if (ClientPrefs.data.noteSplashes == false)
			return null;

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(0, 0, note.column, splashSkin);
		splash.handleRendering = false;
		grpNoteSplashes.add(splash);

		return splash;
	}

	public function spawnNoteSplashOnNote(note:Note):NoteSplash {
		return spawnSplash(note);
	}

	// Limit note spawning per frame at high framerates to prevent spikes
	// moved here so it doesn't immediently reset rendering it useless
	var spawned = 0;
	// spawns notes, deals w/ hold inputs, etc.
	var aliveNoteCount:Int = 0;
	var aliveNoteLimiter:Int = 50;

	/** Spawns notes, deals w/ hold inputs, etc. **/
	override public function update(elapsed:Float){
		noteField.modManager = modManager;
		noteField.modNumber = modNumber;
		noteField.cameras = cameras;

		for (char in characters)
			char.controlled = isPlayer;

		// note spawning
		for (column => queue in noteQueue) {
			if (queue[0] == null)
				continue;

			var modifier = modManager.get("noteSpawnTime" + column);
			if (modifier == null || modifier.getValue(modNumber) <= 0)
				modifier = modManager.get("noteSpawnTime");

			var spawnTime:Float;
			if (modifier == null || (spawnTime = modifier.getValue(modNumber)) <= 0)
				spawnTime = this.spawnTime;
			else
				spawnTime = modifier.getValue(modNumber);

			#if MECHANICS_MOD_ALLOWED
			if (!queue[0].isSustainNote
				&& MechanicManager.mechanics['note_change'].points > 0
				&& FlxG.random.bool(FlxMath.remapToRange(MechanicManager.mechanics['note_change'].points, 0, 20, 0,
					3) * (1 + Math.abs(Conductor.songPosition / FlxG.sound.music.length))))
			{
				queue[0].expectedData = FlxG.random.int(0, 3);
				if (queue[0].tail.length > 0)
				{
					for (sustain in queue[0].tail)
					{
						sustain.expectedData = queue[0].expectedData;
					}
				}
			}
			if (PlayState.mechanicsMod?.restoreActivated
				&& (queue[0].noteType != null || queue[0].noteType.length == 0)
				&& FlxG.random.bool(30)
				&& queue[0].mustPress
				&& !queue[0].autoGenerated)
			{
				if (!queue[0].isSustainNote)
				{
					var last:Bool = queue[0].autoGenerated;
					queue[0].autoGenerated = true;
					queue[0].noteType = 'Restore Note';
					queue[0].autoGenerated = last;
				}
			}
			#end

			while (queue.length > 0 && queue[0].strumTime - Conductor.songPosition < spawnTime && aliveNoteCount <= aliveNoteLimiter) {
				((queue[0].spawned) ? queue.remove(queue[0]) : spawnNote(queue[0]));
				spawned++;
			}
		}

		super.update(elapsed);

		for(obj in strumNotes)
			modManager.updateObject(curDecBeat, obj, modNumber);

		for (daNote in spawnedNotes)
		{
			if(!daNote.alive){
				spawnedNotes.remove(daNote);
				continue;
			}
			modManager.updateObject(curDecBeat, daNote, modNumber);

			// check for hold inputs
			if(!daNote.isSustainNote){
				if(daNote.column >= keyCount){
					garbage.push(daNote);
					continue;
				}
				if(daNote.holdingTime < daNote.sustainLength && inControl && (!daNote.blockHit || !daNote.forceBlockHit)){
					if(!daNote.tooLate && daNote.wasGoodHit){
						var isHeld:Bool = autoPlayed || keysPressed[daNote.column];
						var wasHeld:Bool = daNote.isHeld;
						daNote.isHeld = isHeld;
						isHolding[daNote.column] = true;
						if(wasHeld != isHeld){
							if(isHeld){
								if(holdPressCallback != null)
									holdPressCallback(daNote, this);
							}else if(holdReleaseCallback!=null)
								holdReleaseCallback(daNote, this);
						}

						var receptor = strumNotes[daNote.column];
						var oldSteps:Int = Math.floor(daNote.holdingTime / Conductor.stepCrochet);
						var lastTime:Float = daNote.holdingTime;
						daNote.holdingTime = Conductor.songPosition - daNote.strumTime;
						if (daNote.holdingTime > daNote.sustainLength)
							daNote.holdingTime = daNote.sustainLength;
						var currentSteps:Int = Math.floor(daNote.holdingTime / Conductor.stepCrochet);
						if(oldSteps < currentSteps)
							if(holdStepCallback != null)
								holdStepCallback(daNote, this);
						holdUpdated.dispatch(daNote, this, daNote.holdingTime - lastTime);

						if(isHeld && !daNote.isRoll){
							if(daNote.unhitTail.length > 0)
								if (receptor.animation.finished || receptor.animation.name != "confirm")
									receptor.playAnim("confirm", true, daNote);

							daNote.tripProgress = 1.0;
						}else
							daNote.tripProgress -= elapsed / (daNote.maxReleaseTime * 1);

						if(daNote.isRoll && autoPlayed && daNote.tripProgress <= 0.5)
							holdPressCallback(daNote, this); // would set tripProgress back to 1 but idk maybe the roll script wants to do its own shit

						if(daNote.tripProgress <= 0){
							holdDropped.dispatch(daNote, this);
							daNote.tripProgress = 0;
							daNote.tooLate=true;
							daNote.wasGoodHit=false;
							for(tail in daNote.unhitTail){
								tail.tooLate = true;
								tail.blockHit = true;
								tail.ignoreNote = true;
							}
							isHolding[daNote.column] = false;
							if (!isHeld)
								receptor.playAnim("static", true);

						}else{
							for (tail in daNote.unhitTail)
							{
								if ((tail.strumTime - 25) <= Conductor.songPosition && !tail.wasGoodHit && !tail.tooLate){
									noteHitCallback(tail, this);
								}
							}

							if (daNote.holdingTime >= daNote.sustainLength)
							{
								//trace("finished hold");
								holdFinished.dispatch(daNote, this);
								daNote.holdingTime = daNote.sustainLength;
								isHolding[daNote.column] = false;
								if (!isHeld)
									receptor.playAnim("static", true);
							}

						}
					}
				}
			}

			//kade is just evil lmao
			if (ClientPrefs.data.inputSystem == "Kade" && daNote.isParent && daNote.tooLate && !daNote.isSustainNote)
			{
				PlayState.instance.health -= 0.15; // give a health punishment for failing a LN
				trace("hold fell over at the start");
				for (i in daNote.childs)
				{
					i.alpha = 0.3;
					i.susActive = false;
				}
			}

			// check for note deletion
			if (daNote.garbage)
				garbage.push(daNote);
			else
			{

				if (!daNote.causedMiss && daNote.active && daNote.tooLate && !daNote.isSustainNote)
				{
					daNote.causedMiss = true;
					if (!daNote.ignoreNote)
						noteMissed.dispatch(daNote, this);
				}

				if (
					(!daNote.isSustainNote || (daNote.strumTime - Conductor.songPosition < -350))
					&& (daNote.sustainLength == 0 || daNote.tooLate || daNote.wasGoodHit)
					&& daNote.strumTime - Conductor.songPosition < -(200 + ClientPrefs.data.badWindow + daNote.sustainLength)
				)
				{
					daNote.garbage = true;
					garbage.push(daNote);
				}

			}
		}

		while (garbage.length > 0)
			removeNote(garbage.pop());

		if (inControl && AIPlayer)
		{
			for(i in 0...Note.ammo[PlayState.mania]){
				for (daNote in getNotes(i, (note:Note) -> !note.ignoreNote && !note.hitCausesMiss)){
					var hitDiff = daNote.strumTime - Conductor.songPosition;
					if (daNote.AIStrumTime != 0 && !daNote.AIMiss)
					{
						if (Math.abs(daNote.strumTime - daNote.AIStrumTime) > Conductor.safeZoneOffset)
						{
							if (daNote.strumTime - daNote.AIStrumTime <= Conductor.songPosition)
								noteHitCallback(daNote, this);
						}
					}
					else if ((hitDiff + ClientPrefs.data.ratingOffset) <= (5 * 1) || hitDiff <= 0){
						noteHitCallback(daNote, this);
					}

				}
			}
		}
		else if (inControl && autoPlayed)
		{
			for(i in 0...keyCount){
				for (note in getTapNotes(i, (note:Note) -> !note.tooLate && !note.wasGoodHit && !note.ignoreNote && !note.hitCausesMiss)){
					var hitDiff = Conductor.songPosition - note.strumTime;
					if (!note.isSustainNote && hitDiff >= 0 || note.isSustainNote && hitDiff + 80 >= 0){
						noteHitCallback(note, this);
					}

				}
			}
		}else{
			// Check for Bot Notes.
			for(i in 0...keyCount){
				for (daNote in getNotes(i, (note:Note) -> !note.tooLate && !note.wasGoodHit && !note.ignoreNote && !note.hitCausesMiss && note.botNote)){
					var hitDiff = Conductor.songPosition - daNote.strumTime;
					if (!daNote.isSustainNote && hitDiff >= 0 || daNote.isSustainNote && hitDiff + 80 >= 0){
						noteHitCallback(daNote, this);
					}
				}
			}

			for(column in 0...keyCount){
				if (keysPressed[column]){
					var noteList = getTapNotesWithEnd(column, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote, false);
					noteList.sort(sortNotesDescend);
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						if (!note.forceBlockHit)
							noteHitCallback(note, this);

					}
				}
			}
		}
	}

	/** Gets all living notes w/ optional filter **/
	public function getNotes(column:Int, ?filter:Note->Bool):Array<Note>
	{
		if (spawnedByData[column]==null)
			return [];

		var collected:Array<Note> = [];
		for (note in spawnedByData[column])
		{
			if (note.alive && note.column == column)
			{
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	/** get all living TAP notes **/
	public function getTapNotes(column:Int, ?filter:Note->Bool, requiresTap:Bool = true):Array<Note> {
		var array = requiresTap ? tapsByData[column] : noTapsByData[column];

		if (array == null)
			return [];

		var collected:Array<Note> = [];
		for (note in array) {
			if (note.alive && note.column == column) {
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	/** gets all living TAP notes before a certain time w/ optional filter **/
	public function getTapNotesWithEnd(column:Int, end:Float, ?filter:Note->Bool, requiresTap:Bool = true):Array<Note> {
		var array = requiresTap ? tapsByData[column] : noTapsByData[column];

		if (array == null)
			return [];

		var collected:Array<Note> = [];
		for (note in array) {
			if (note.strumTime > end)
				break;
			if (note.alive && note.column == column && !note.wasGoodHit && !note.tooLate) {
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	/** gets all living notes before a certain time w/ optional filter **/
	public function getNotesWithEnd(column:Int, end:Float, ?filter:Note->Bool):Array<Note>
	{
		if (spawnedByData[column] == null)
			return [];
		var collected:Array<Note> = [];
		for (note in spawnedByData[column])
		{
			if (note.strumTime>end)break;
			if (note.alive && note.column == column && !note.wasGoodHit && !note.tooLate)
			{
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	/** go through every queued note and call a func on it **/
	public function forEachQueuedNote(callback:Note->Void)
	{
		for(column in noteQueue){
			var i:Int = 0;
			var note:Note = null;

			while (i < column.length)
			{
				note = column[i++];

				if (note != null && note.exists && note.alive)
					callback(note);
			}
		}
	}

	/** kills all notes which are stacked **/
	public function clearStackedNotes(){

		var goobaeg:Array<Note> = [];
		for (column in noteQueue)
		{
			if (column.length >= 2)
			{
				for (nIdx in 1...column.length)
				{
					var last = column[nIdx - 1];
					var current = column[nIdx];
					if (last == null || current == null)
						continue;
					if (last.isSustainNote || current.isSustainNote)
						continue; // holds only get fukt if their parents get fukt
					if (!last.alive || !current.alive)
						continue; // just incase
					if (Math.abs(last.strumTime - current.strumTime) <= Conductor.jackLimit)
					{
						if (last.sustainLength < current.sustainLength) // keep the longer hold
							removeNote(last);
						else
						{
							current.kill();
							goobaeg.push(current); // mark to delete after, cant delete here because otherwise it'd fuck w/ stuff
						}
					}
				}
			}
		}
		for (note in goobaeg)
			removeNote(note);
	}

	/** as is in the name, removes all dead notes **/
	public function clearDeadNotes(){
		var dead:Array<Note> = [];
		for(note in spawnedNotes){
			if(!note.alive)
				dead.push(note);
		}
		for(column in noteQueue){
			for(note in column){
				if(!note.alive)
					dead.push(note);
			}
		}

		for(note in dead)
			removeNote(note);
	}

	public function setDefaultBaseXPositions() {
		for (i in 0...keyCount)
			baseXPositions[i] = getDefaultBaseX(i);
	}

	public function setDefaultBaseYPositions() {
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...this.keyCount)
			this.baseYPositions[i] = strumLineY;
	}

	public inline function getBaseX(direction:Int)
		return baseXPositions[direction];
	public inline function getBaseY(direction:Int)
		return baseYPositions[direction];

	public inline function getDefaultBaseX(direction:Int)
		return modManager.getBaseX(direction, this.playerId, keyCount);

	public function updateBaseYPosition(direction:Int, newY:Float) {
		baseYPositions[direction] = newY;
	}

	private static inline function sortNotesAscend(a:Note, b:Note):Int
		return Std.int(a.strumTime - b.strumTime);

	private static inline function sortNotesDescend(a:Note, b:Note):Int
		return Std.int(b.strumTime - a.strumTime);

	override function destroy(){
		noteSpawned.removeAll();
		noteSpawned.cancel();
		noteMissed.removeAll();
		noteMissed.cancel();
		noteRemoved.removeAll();
		noteRemoved.cancel();
		holdDropped.removeAll();
		holdDropped.cancel();
		holdFinished.removeAll();
		holdFinished.cancel();
		holdUpdated.removeAll();
		holdUpdated.cancel();

		// Safely destroy all note splashes
		if (grpNoteSplashes != null) {
			grpNoteSplashes.forEachAlive(function(splash:NoteSplash) {
				if (splash != null) {
					splash.kill();
					splash.destroy();
				}
			});
			grpNoteSplashes.clear();
			grpNoteSplashes.destroy();
			grpNoteSplashes = null;
		}

		// Safely destroy strum attachments
		if (strumAttachments != null) {
			strumAttachments.forEachAlive(function(attachment:NoteObject) {
				if (attachment != null) {
					attachment.kill();
					attachment.destroy();
				}
			});
			strumAttachments.clear();
			strumAttachments.destroy();
			strumAttachments = null;
		}

		return super.destroy();
	}

	#if true
	function set_playerId(v) {
		playerId = v;
		setDefaultBaseXPositions();
		return playerId;
	}

	function set_keyCount(cnt:Int){
		if (cnt < 0)
			cnt=0;

		if (spawnedByData.length < cnt) {
			for (_ in (spawnedByData.length)...cnt)
				spawnedByData.push([]);
		} else if(spawnedByData.length > cnt){
			spawnedByData.resize(cnt);
		}

		if (tapsByData.length < cnt) {
			for (_ in (tapsByData.length)...cnt)
				tapsByData.push([]);
		} else if (tapsByData.length > cnt) {
			tapsByData.resize(cnt);
		}

		if (noTapsByData.length < cnt) {
			for (_ in (noTapsByData.length)...cnt)
				noTapsByData.push([]);
		} else if (noTapsByData.length > cnt) {
			noTapsByData.resize(cnt);
		}

		if (keysPressed.length < cnt) {
			for (_ in (keysPressed.length)...cnt)
				keysPressed.push(false);
		}

		if (baseXPositions.length < cnt) {
			for (_ in (baseXPositions.length)...cnt)
				baseXPositions.push(getDefaultBaseX(baseXPositions.length));
		} else if (baseXPositions.length > cnt) {
			baseXPositions.resize(cnt);
		}

		return keyCount = cnt;
	}

	function set_autoPlayed(aP:Bool){
		/*if(aP == autoPlayed)return aP;

		for (idx in 0...keysPressed.length)
			keysPressed[idx] = false;

		for(obj in strumNotes){
			obj.playAnim("static");
			obj.resetAnim = 0;
		}*/
		return autoPlayed = aP;
	}

	override function set_camera(to){
		for (strumLine in strumNotes)
			strumLine.camera = to;

		noteField.camera = to;

		return super.set_camera(to);
	}

	override function set_cameras(to){
		for (strumLine in strumNotes)
			strumLine.cameras = to;

		noteField.cameras = to;

		return super.set_cameras(to);
	}

	#end
}
