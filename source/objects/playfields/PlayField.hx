package objects.playfields;

import backend.MusicBeatState;
import backend.modchart.ModManager;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import lime.app.Event;
import objects.notes.*;
import states.PlayState;
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;

/*
The system is seperated into 3 classes:

- NoteField
	- This is the rendering component.
	- This can be created seperately from a PlayField to duplicate the notes multiple times, for example.
	- Needs to be linked to a PlayField though, so it can keep track of what notes exist, when notes get hit (to update receptors), etc.

- ProxyField
	- Clones a NoteField
	- This cannot have its own modifiers, etc applied. All this does is render whatever's in the NoteField
	- If you need to duplicate one PlayField a bunch, you should be using ProxyFields as they are far more optimized it only calls the mod manager for the initial notefield, and not any ProxyFields
	- One use case is if you wanna include an infinite NoteField effect (i.e the end of The Government Knows by FMS_Cat, or get f**ked from UKSRT8)

- PlayField
	- This is the gameplay component.
	- This keeps track of notes and updates them
	- This is typically per-player, and can control multiple characters, can be locked up, etc.
	- You can also swap which PlayField a player is actually controlling n all that
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
		grpNoteSplashes.cameras = to;

		#if debug
		trace('PlayField: Set cameras for grpNoteSplashes to: $to');
		#end

		return super.set_cameras(to);
	}

	function set_playerId(v) {
		playerId = v;
		setDefaultBaseXPositions();
		setDefaultBaseYPositions();
		return playerId;
	}

	public var tracks:Array<FlxSound> = []; // tracks managed by this field
	public var playerId(default, set):Int = 0; // used to calculate the base position of the strums

	public var spawnTime:Float = 1750; // spawn time for notes
	public var spawnedNotes:Array<Note> = []; // spawned notes

	public var spawnedByData:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]; // spawned notes by data. Used for input
	public var tapsByData:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]; // spawned tap notes (with requiresTap) by data. Used for input but can't change spawnedByData cus of holds n shit lol!
	public var noTapsByData:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]; // spawned tap notes (without requiresTap) by data. Used for input but can't change spawnedByData cus of holds n shit lol!
	public var noteQueue:Array<Array<Note>> = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]; // unspawned notes

	public var strumNotes:Array<StrumNote> = []; // receptors
	public var characters:Array<Character> = []; // characters that sing when field is hit
	public var singAnimations:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]; // default character animations to play for each column

	public var noteField:NoteField; // renderer
	public var modManager:ModManager; // the mod manager. will be set automatically by playstate so dw bout this
	public var modNumber:Int = 0; // used for the mod manager. can be set to a different number to give it a different set of modifiers. can be set to 0 to sync the modifiers w/ bf's, and 1 to sync w/ the opponent's
	public var isPlayer:Bool = false; // if this playfield takes input from the player
	public var inControl:Bool = true; // if this playfield will take input at all
	public var AIPlayer:Bool = false; // if this playfield is played by the "AI" instead
	public var keyCount(default, set):Int = 4; // How many lanes are in this field
	public var autoPlayed(default, set):Bool = false; // if this playfield should be played automatically (botplay, opponent, etc)
	public var isEditor:Bool = false; // Because the charting state playstate is "special"

	public var x:Float = 0;
	public var y:Float = 0;

	static var mutex:Mutex;
	static var threadPool:FixedThreadPool = null;

	function set_keyCount(cnt:Int){
		if (cnt < 0)
			cnt=0;
		if (spawnedByData.length < cnt){
			for (_ in (spawnedByData.length)...cnt)
				spawnedByData.push([]);
		}else if(spawnedByData.length > cnt){
			for (_ in cnt...spawnedByData.length)
				spawnedByData.pop();
		}

		if (tapsByData.length < cnt) {
			for (_ in (tapsByData.length)...cnt)
				tapsByData.push([]);
		} else if (tapsByData.length > cnt) {
			for (_ in cnt...tapsByData.length)
				tapsByData.pop();
		}

		if (noTapsByData.length < cnt) {
			for (_ in (noTapsByData.length)...cnt)
				noTapsByData.push([]);
		} else if (noTapsByData.length > cnt) {
			for (_ in cnt...noTapsByData.length)
				noTapsByData.pop();
		}

		if (keysPressed.length < cnt)
		{
			for (_ in (keysPressed.length)...cnt)
				keysPressed.push(false);
		}

		setDefaultBaseXPositions();
		setDefaultBaseYPositions();

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

	public static var extraStuff:FlxTypedGroup<FlxBasic>; // things that get added above the receptors.

	public var noteHitCallback:NoteCallback; // function that gets called when the note is hit. goodNoteHit and opponentNoteHit in playstate for eg
	public var holdPressCallback:NoteCallback; // function that gets called when a hold is stepped on. Only really used for calling script events. Return 'false' to not do hold logic
	public var holdReleaseCallback:NoteCallback; // function that gets called when a hold is released. Only really used for calling script events.
	public var holdStepCallback:NoteCallback; // function that gets called for every 'step' that a hold is pressed for.

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>; // notesplashes
	public var strumAttachments:FlxTypedGroup<NoteObject>; // things that get "attached" to the receptors. custom splashes, etc.

	public var noteMissed:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time you miss a note.
	public var noteRemoved:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time a note is removed.
	public var noteSpawned:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time a note is spawned.
	public var holdDropped:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time a hold is dropped
	public var holdFinished:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time a hold is finished
	public var holdUpdated:Event<(Note, PlayField, Float) -> Void> = new Event<(Note, PlayField, Float) -> Void>(); // event that gets called every time a hold is updated

	// Performance optimization fields
	private var sustainUpdateCounter:Int = 0;
	private var dynamicSustainInterval:Int = 2; // Adaptive sustain update interval
	private var heldNotes:Array<Note> = []; // Cache of currently held notes
	private var receptorAnimStates:Array<String> = []; // Track receptor animation states
	private var lastSustainUpdate:Float = 0;
	private var frameTimeAccumulator:Float = 0;
	private var lastFrameTime:Float = 0;
	private var avgFrameTime:Float = 0.0167; // Start assuming 60 FPS
	private var frameCounter:Int = 0;

	public var keysPressed:Array<Bool> = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]; // what keys are pressed rn
	public var isHolding:Array<Bool> = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false];

	public var baseXPositions:Array<Float> = [];
	public var baseYPositions:Array<Float> = [];
	public function setDefaultBaseXPositions() {
		for (i in 0...this.keyCount)
			this.baseXPositions[i] = modManager.getBaseX(i, this.playerId, keyCount);
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

	public function updateBaseYPosition(direction:Int, newY:Float) {
		baseYPositions[direction] = newY;
	}

	public function new(modMgr:ModManager, ?keyCount:Int){
		super();
		this.modManager = modMgr;
		this.keyCount = keyCount == null ? Note.ammo[PlayState.mania] : keyCount;

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);

		strumAttachments = new FlxTypedGroup<NoteObject>();
		strumAttachments.visible = false;
		add(strumAttachments);

		// Pre-allocate a few note splashes for better performance
		// No need, you only need one. It creates everything else for you
		if (ClientPrefs.data.noteSplashes) {
			var splash:NoteSplash = new NoteSplash();
			splash.handleRendering = false;
			grpNoteSplashes.add(splash);
			grpNoteSplashes.visible = false; // so they dont get drawn
			splash.alpha = 0.0;
		}

		////
		noteField = new NoteField(this, modMgr);

		#if MULTITHREADED_LOADING
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, LoadingState.getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		#else
		var threadCount:Int = 1;
		#end
		threadPool = new FixedThreadPool(threadCount);
		mutex = new Mutex();

		// Initialize receptor animation states
		for (i in 0...this.keyCount) {
			receptorAnimStates.push("static");
		}
	}

	// Anything that is static/used by both strums but cant be double-initialized can be placed here
	// Keep in mind, this runs AFTER the strums are made.
	public static function initExtras()  {
		extraStuff = new FlxTypedGroup<FlxBasic>();
	}

	// queues a note to be spawned
	public function queue(note:Note){
		if (noteQueue[note.column] == null)
			noteQueue[note.column] = [note];
		else{
			noteQueue[note.column].push(note);
			noteQueue[note.column].sort(sortNotesAscend);
		}
	}

	// unqueues a note
	public function unqueue(note:Note)
	{
		if (noteQueue[note.column] == null)
			noteQueue[note.column] = [];
		noteQueue[note.column].remove(note);
		noteQueue[note.column].sort(sortNotesAscend);
	}

	// destroys a note
	public function removeNote(daNote:Note, ?killTail:Bool = false){
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
			noteQueue[daNote.column].sort(sortNotesAscend);
		remove(daNote);
		daNote.destroy();
	}

	// spawns a note
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

		noteSpawned.dispatch(note, this);
		spawnedNotes.push(note);
		aliveNoteCount++;
		/*initThread(() -> function() {
			spawnedNotes.push(note);
		}, "spawnNote");*/
		note.handleRendering = false;
		note.spawned = true;

		insert(0, note);

	}

	// gets all notes in the playfield, spawned or otherwise.

	public function getAllNotes(?dir:Int){
		var arr:Array<Note> = [];
		if(dir==null){
			for(queue in noteQueue){
				for(note in queue)
					arr.push(note);

			}
		}else{
			for (note in noteQueue[dir])
				arr.push(note);
		}
		for(note in spawnedNotes)
			arr.push(note);
		return arr;
	}

	// returns true if the playfield has the note, false otherwise.
	public function hasNote(note:Note)
		return spawnedNotes.contains(note) || noteQueue[note.column]!=null && noteQueue[note.column].contains(note);

	var closestNotes:Array<Note> = [];
	var strumsBlocked:Array<Bool> = [];
	// sends an input to the playfield
	public function input(data:Int, ?hitTime:Float):Null<Note> {
		if (data < 0 || data > keyCount)
			return null;

		if (!PlayState.instance.boyfriend.stunned)
		{
			switch (ClientPrefs.data.inputSystem)
			{
				case "Troll Engine":
					hitTime ??= Conductor.songPosition;

					var noteList = getTapNotes(data, (note:Note) -> !note.tooLate);
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

							noteHitCallback(note, this);
							return note;
						}
					}

					return recentHold;
				case "Native":
					if(data > keyCount || data < 0)return null;

					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.tooLate);
					#if PE_MOD_COMPATIBILITY
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)
					#else
					noteList.sort((a, b) -> Std.int(b.strumTime - a.strumTime)); //so lowPriority actually works (even though i hate it lol!)
					#end
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						if (!note.blockHit) noteHitCallback(note, this);
						return note;
					}
				case "Native-old":
					if(data > keyCount || data < 0)return null;

					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> note.requiresTap);
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
							if (!note.blockHit) noteHitCallback(note, this);
							return note;
						}
					}
					return recentHold;
				case 'Rhythm':
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						var hitDiff = Math.abs(note.strumTime - Conductor.songPosition);
						var allowedError = ClientPrefs.data.badWindow * 0.05; // 5% error margin
						if (hitDiff <= allowedError)
						{
							noteHitCallback(note, this);
							return note;
						}
					}
					// Check if the note is still being held when it ends
					for (note in spawnedNotes)
					{
						if (note.column == data && note.isSustainNote && note.wasGoodHit && !note.tooLate && note.holdingTime >= note.sustainLength)
						{
							note.tooLate = true;
							note.wasGoodHit = false;
							if (inControl) noteMissed.dispatch(note, this);
							return note;
						}
					}
					if (!ClientPrefs.data.ghostTapping)
					{
						PlayState.instance.ogNoteMissPress(data);
					}
				case 'BEAT! Engine':
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);

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
							if (!notesStopped)
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
						PlayState.instance.ogNoteMissPress(data);
					}

					// I dunno what you need this for but here you go
					//									- Shubs

					// Shubs, this is for the "Just the Two of Us" achievement lol
					//									- Shadow Mario
					keysPressed[data] = true;

					// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
					Conductor.songPosition = lastTime;
				case 'Kade Engine': // 1.8 input btw
					var canMiss:Bool = !ClientPrefs.data.ghostTapping;

					keysPressed[data] = true;

					closestNotes = [];

					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); // so lowPriority actually works (even though i hate it lol!)
					for (daNote in noteList)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.wasGoodHit)
							closestNotes.push(daNote);
					}

					closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					var dataNotes:Array<Note> = [];
					for (i in closestNotes)
						if (i.noteData == data && !i.isSustainNote)
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

								if (!note.isSustainNote && ((note.strumTime - coolNote.strumTime) < 2) && note.noteData == data)
								{
									trace('found a stacked/really close note ' + (note.strumTime - coolNote.strumTime));
									// just fuckin remove it since it's a stacked note and shouldn't be there
									removeNote(note);
								}
							}
						}

						var note:Note = dataNotes.pop();
						noteHitCallback(note, this);
						return note;
					}
					else if (canMiss)
					{
						PlayState.instance.ogNoteMissPress(data);
					}
				case 'ZoroForce EK':
					var hittableNotes = [];
					var closestNotes = [];

					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
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
						if (i.noteData == data)
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
									noteHitCallback(shitNote, this);
									return shitNote;
								}
								else if ((!shitNote.isSustainNote && (shitNote.strumTime - daNote.strumTime) < 15))
								{
									noteHitCallback(shitNote, this);
									return shitNote;
								}
							}
						}
						noteHitCallback(daNote, this);
					}
					else if (!ClientPrefs.data.ghostTapping)
						PlayState.instance.ogNoteMissPress(data);

				case "Mic'ed Up Engine":
					PlayState.instance.notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && keysPressed[daNote.noteData])
						{
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
									noteHitCallback(coolNote.prevNote, this);
									return coolNote.prevNote;
								}
								if (PlayState.instance.mashViolations != 0)
									PlayState.instance.mashViolations--;
								PlayState.instance.scoreTxt.color = FlxColor.WHITE;
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
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a,b)->Std.int(a.strumTime-b.strumTime)); // SHOULD be in order?
					// But just incase, we do this sort
					if(noteList.length>0){
						var hitNote = noteList[0];
						if(!hitNote.wasGoodHit) // because parent tap notes
						{
							if (!hitNote.blockHit) noteHitCallback(hitNote, this);
							return hitNote;
						}
					}else{
						if(!ClientPrefs.data.ghostTapping)
							PlayState.instance.ogNoteMissPress(data);
					}

				case "YoshiEngine":
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
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
								noteHitCallback(daNote, this);
								return daNote;
							}
						}
					};

				case "Kade Engine Community":
					final lastConductorTime:Float = Conductor.songPosition;
					keysPressed[data] = true;

					final closestNotes:Array<Note> = PlayState.instance.notes.members.filter(function(aliveNote:Note)
					{
						return aliveNote != null && aliveNote.alive && aliveNote.canBeHit && aliveNote.mustPress && !aliveNote.wasGoodHit && !aliveNote.isSustainNote
							&& aliveNote.noteData == data;
					});

					final defNotes:Array<Note> = [for (v in closestNotes) v];

					haxe.ds.ArraySort.sort(defNotes, sortByOrderNote);

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

								if (!note.isSustainNote && ((note.strumTime - coolNote.strumTime) < 2) && note.noteData == data)
									removeNote(note);
							}
						}

						noteHitCallback(coolNote, this);
						return coolNote;
					}
					else if (!ClientPrefs.data.ghostTapping)
						PlayState.instance.ogNoteMissPress(data);

					Conductor.songPosition = lastConductorTime;
			}
		}

		return null;
	}

	// generates the receptors
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

	// does the introduction thing for the receptors. story mode usually sets skip to true. OYT uses this when mario comes in
	public function fadeIn(skip:Bool = false)
	{
		for (data in 0...strumNotes.length)
		{
			var babyArrow:StrumNote = strumNotes[data];
			if (skip)
				babyArrow.alpha = 1;
			else
			{
				babyArrow.alpha = 0;
				var daY = babyArrow.downScroll ? -10 : 10;
				babyArrow.offsetY -= daY;
				FlxTween.tween(babyArrow, {offsetY: babyArrow.offsetY + daY, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (Conductor.crochet / 1000) * data * PlayState.instance.playbackRate});
			}
		}
	}

	// just sorts by z indexes, not used anymore tho
	function sortByOrderNote(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	private static function sortNotesAscend(a:Note, b:Note):Int
		return Std.int(a.strumTime - b.strumTime);

	private static function sortNotesDescend(a:Note, b:Note):Int
		return Std.int(b.strumTime - a.strumTime);

	// spawns a notesplash w/ specified skin. optional note to derive the skin and colours from.

	public function spawnSplash(note:Note, ?splashSkin:String):NoteSplash {
		if (note == null) return null;

		/*var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		if (splash == null) {
			splash = new NoteSplash();
			grpNoteSplashes.add(splash);
		}

		// Ensure splash uses the same cameras as the playfield
		splash.cameras = this.cameras;

		#if debug
		trace('NoteSplash: Set splash cameras to: ${splash.cameras}');
		#end

		// Set position to match the exact strum note position
		var strumX:Float = 0;
		var strumY:Float = 0;
		if (note.column < strumNotes.length) {
			var strum = strumNotes[note.column];
			if (strum != null) {
				// Use the exact strum position - the splash will handle its own centering via offsets
				strumX = strum.x;
				strumY = strum.y;

				#if debug
				trace('NoteSplash: Spawning splash for note column ${note.column} at strum position ($strumX, $strumY)');
				#end
			}
		} else {
			#if debug
			trace('NoteSplash: Warning - note.column ${note.column} >= strumNotes.length ${strumNotes.length}');
			#end
		}

		splash.spawnSplashNote(strumX, strumY, note.noteData, note);
		splash.handleRendering = false;*/

		// do it the way god (troll engine) intended
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
	var aliveNoteLimiter:Int = 20;
	override public function update(elapsed:Float){
		noteField.modNumber = modNumber;
		noteField.cameras = cameras;

		for (char in characters)
			char.controlled = isPlayer;

		var curDecStep:Float = 0;

		if ((FlxG.state is MusicBeatState))
		{
			var state:MusicBeatState = cast FlxG.state;
			@:privateAccess
			curDecStep = state.curDecStep;
		}
		else
		{
			var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
			var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
			curDecStep = lastChange.stepTime + shit;
		}
		var curDecBeat = curDecStep / 4;

		var maxSpawnsPerFrame = (dynamicSustainInterval == 4 ? 2 : (dynamicSustainInterval == 3 ? 3 : 5));
		for (data => column in noteQueue)
		{
			if (column[0] != null)
			{
				var dataSpawnTime = modManager.get("noteSpawnTime" + data);
				var noteSpawnTime = (dataSpawnTime != null && dataSpawnTime.getValue(modNumber)>0)?dataSpawnTime:modManager.get("noteSpawnTime");
				var time:Float = noteSpawnTime == null ? spawnTime : noteSpawnTime.getValue(modNumber); // no longer averages the spawn times
				if (time <= 0)time = spawnTime;

				if (!column[0].isSustainNote
					&& MechanicManager.mechanics['note_change'].points > 0
					&& FlxG.random.bool(FlxMath.remapToRange(MechanicManager.mechanics['note_change'].points, 0, 20, 0,
						3) * (1 + Math.abs(Conductor.songPosition / FlxG.sound.music.length))))
				{
					column[0].expectedData = FlxG.random.int(0, 3);
					if (column[0].tail.length > 0)
					{
						for (sustain in column[0].tail)
						{
							sustain.expectedData = column[0].expectedData;
						}
					}
				}
				if (PlayState.mechanicsMod?.restoreActivated
					&& (column[0].noteType != null || column[0].noteType.length == 0)
					&& FlxG.random.bool(30)
					&& column[0].mustPress
					&& !column[0].autoGenerated)
				{
					if (!column[0].isSustainNote)
					{
						var last:Bool = column[0].autoGenerated;
						column[0].autoGenerated = true;
						column[0].noteType = 'Restore Note';
						column[0].autoGenerated = last;
					}
				}

				while (column.length > 0 && column[0].strumTime - Conductor.songPosition < time && (spawned < maxSpawnsPerFrame || aliveNoteCount <= aliveNoteLimiter)) {
					((column[0].spawned) ? column.remove(column[0]) : spawnNote(column[0]));
					spawned++;
				}
			}
		}

		super.update(elapsed);

		for(obj in strumNotes)
			modManager.updateObject(curDecBeat, obj, modNumber);

		// Adaptive performance optimization based on framerate
		var currentTime = haxe.Timer.stamp();
		if (lastFrameTime > 0) {
			var frameTime = currentTime - lastFrameTime;
			frameTimeAccumulator += frameTime;
			frameCounter++;

			// Update average every 30 frames for stability
			if (frameCounter >= 30) {
				avgFrameTime = frameTimeAccumulator / frameCounter;
				var fps = 1.0 / avgFrameTime;

				// Adaptive intervals: Higher FPS = less frequent heavy updates
				if (fps > 100) dynamicSustainInterval = 4;
				else if (fps > 80) dynamicSustainInterval = 3;
				else dynamicSustainInterval = 2;

				frameTimeAccumulator = 0;
				frameCounter = 0;
			}
		}
		lastFrameTime = currentTime;

		sustainUpdateCounter++;
		var shouldUpdateSustains = sustainUpdateCounter >= dynamicSustainInterval;
		if (shouldUpdateSustains) {
			sustainUpdateCounter = 0;
			lastSustainUpdate = Conductor.songPosition;
		}

		//spawnedNotes.sort(sortByOrderNote);

		var garbage:Array<Note> = [];
		for (daNote in spawnedNotes)
		{
			if(!daNote.alive){
				spawnedNotes.remove(daNote);
				continue;
			}
			modManager.updateObject(curDecBeat, daNote, modNumber);

			// daNote.clipToStrumNote(strumNotes[daNote.column]);

			// check for hold inputs
			if(!daNote.isSustainNote){
				if(daNote.column > keyCount-1){
					garbage.push(daNote);
					continue;
				}
				if(daNote.holdingTime < daNote.sustainLength && inControl && !daNote.blockHit){
					if(!daNote.tooLate && daNote.wasGoodHit){
						// Add to held notes cache for optimized processing
						if (heldNotes.indexOf(daNote) == -1) {
							heldNotes.push(daNote);
						}

						// Always update input state and animations (every frame)
						var isHeld:Bool = autoPlayed || keysPressed[daNote.column];
						var wasHeld:Bool = daNote.isHeld;
						daNote.isHeld = isHeld;
						isHolding[daNote.column] = true;

						// Handle input state changes
						if(wasHeld != isHeld){
							if(isHeld){
								if(holdPressCallback != null)
									holdPressCallback(daNote, this);
							}else if(holdReleaseCallback!=null)
								holdReleaseCallback(daNote, this);
						}

						// Update receptor animations (every frame for responsiveness)
						var receptor = strumNotes[daNote.column];
						if(isHeld && !daNote.isRoll){
							var currentAnimName = receptor.animation.curAnim?.name ?? "static";
							if (receptorAnimStates[daNote.column] != "confirm" ||
								(receptor.animation.finished || currentAnimName != "confirm")) {
								receptor.playAnim("confirm", true, daNote);
								receptorAnimStates[daNote.column] = "confirm";
							}
						} else if (!isHeld && receptorAnimStates[daNote.column] != "static") {
							receptor.playAnim("static", true);
							receptorAnimStates[daNote.column] = "static";
						}

						// Only update heavy sustain logic periodically with adaptive timing
						if (shouldUpdateSustains) {
							updateHeldNoteLogic(daNote, elapsed * dynamicSustainInterval);
						}
					} else {
						// Note finished or was never held
						heldNotes.remove(daNote);
					}
				} else {
					// note is done being held
					isHolding[daNote.column] = false;
					heldNotes.remove(daNote);
				}
			} else {
				// also set sustain notes to being held
				if(daNote.parent != null){
					daNote.isHeld = daNote.parent.isHeld;
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

				if (daNote.tooLate && daNote.active && !daNote.causedMiss && !daNote.isSustainNote)
				{
					daNote.causedMiss = true;
					if (!daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit) && inControl) {
						noteMissed.dispatch(daNote, this);
					}
				}

				if((
					(daNote.holdingTime>=daNote.sustainLength) && daNote.sustainLength>0 ||
					daNote.isSustainNote && daNote.strumTime - Conductor.songPosition < -350 ||
					!daNote.isSustainNote
					&& (daNote.sustainLength == 0 || daNote.tooLate)
					&& daNote.strumTime - Conductor.songPosition < -(200 + ClientPrefs.data.badWindow + daNote.sustainLength)) && (daNote.tooLate || daNote.wasGoodHit))
				{
					daNote.garbage = true;
					garbage.push(daNote);
				}

			}
		}

		for(note in garbage)removeNote(note);


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
				for (daNote in getNotes(i, (note:Note) -> !note.tooLate && !note.wasGoodHit && !note.ignoreNote && !note.hitCausesMiss)){
					var hitDiff = Conductor.songPosition - daNote.strumTime;
					if (!daNote.isSustainNote && hitDiff >= 0 || daNote.isSustainNote && hitDiff + 80 >= 0){
						noteHitCallback(daNote, this);
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



			for(data in 0...keyCount){
				if (keysPressed[data]){
					var noteList = getNotesWithEnd(data, Conductor.songPosition, (note:Note) -> (note.isSustainNote || note.istail) && (note.prevNote != null || note.unhitTail.length > -1));
					noteList.sort(sortNotesDescend);
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						noteHitCallback(note, this);
					}
				}
			}
		}
	}


	// gets all living notes w/ optional filter

	public function getNotes(dir:Int, ?filter:Note->Bool):Array<Note>
	{
		if (spawnedByData[dir]==null)
			return [];

		var collected:Array<Note> = [];
		for (note in spawnedByData[dir])
		{
			if (note.alive && note.column == dir)
			{
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	// get all living TAP notes
	public function getTapNotes(dir:Int, ?filter:Note->Bool, requiresTap:Bool = true):Array<Note> {
		var array = requiresTap ? tapsByData[dir] : noTapsByData[dir];

		if (array == null)
			return [];

		var collected:Array<Note> = [];
		for (note in array) {
			if (note.alive && note.column == dir) {
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	// gets all living TAP notes before a certain time w/ optional filter
	public function getTapNotesWithEnd(dir:Int, end:Float, ?filter:Note->Bool, requiresTap:Bool = true):Array<Note> {
		var array = requiresTap ? tapsByData[dir] : noTapsByData[dir];

		if (array == null)
			return [];

		var collected:Array<Note> = [];
		for (note in array) {
			if (note.strumTime > end)
				break;
			if (note.alive && note.column == dir && !note.wasGoodHit && !note.tooLate) {
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	// gets all living notes before a certain time w/ optional filter
	public function getNotesWithEnd(dir:Int, end:Float, ?filter:Note->Bool):Array<Note>
	{
		if (spawnedByData[dir] == null)
			return [];
		var collected:Array<Note> = [];
		for (note in spawnedByData[dir])
		{
			if (note.strumTime>end)break;
			if (note.alive && note.column == dir && !note.wasGoodHit && !note.tooLate)
			{
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	// go through every queued note and call a func on it
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

	// kills all notes which are stacked
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

	// as is in the name, removes all dead notes
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

		// Clear held notes cache
		if (heldNotes != null) {
			heldNotes.splice(0, heldNotes.length);
			heldNotes = null;
		}

		// Clear receptor animation states
		if (receptorAnimStates != null) {
			receptorAnimStates.splice(0, receptorAnimStates.length);
			receptorAnimStates = null;
		}

		if (threadPool != null) threadPool.shutdown(); // kill all workers safely
		threadPool = null;
		mutex = null;

		return super.destroy();
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		// trace('scheduled $func in threadPool');
		#if debug
		var threadSchedule = Sys.time();
		#end
		threadPool.run(() -> {
			#if debug
			var threadStart = Sys.time();
			trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try {
				if (func() != null) {
					#if debug
					var diff = Sys.time() - threadStart;
					trace('finished preloading $traceData in ${diff}s');
					#end
				} else trace('ERROR! fail on preloading $traceData ');
			}
			catch(e:Dynamic) {
				trace('ERROR! fail on preloading $traceData: $e');
			}
		});
	}

	/**
	 * Optimized function to handle heavy sustain note logic less frequently
	 * This reduces CPU usage by updating sustain timing, events, and tail processing periodically
	 */
	private function updateHeldNoteLogic(daNote:Note, deltaTime:Float):Void
	{
		if (daNote == null || !daNote.alive || daNote.isSustainNote) return;

		// Update holding time and step tracking
		var oldSteps:Int = Math.floor(daNote.holdingTime / Conductor.stepCrochet);
		var lastTime:Float = daNote.holdingTime;
		daNote.holdingTime = Conductor.songPosition - daNote.strumTime;
		if (daNote.holdingTime > daNote.sustainLength)
			daNote.holdingTime = daNote.sustainLength;

		var currentSteps:Int = Math.floor(daNote.holdingTime / Conductor.stepCrochet);
		if(oldSteps < currentSteps)
			if(holdStepCallback != null)
				holdStepCallback(daNote, this);

		// Throttled event dispatching (reduce event spam)
		var timeDiff = daNote.holdingTime - lastTime;
		if (Math.abs(timeDiff) > 0.1) { // Only dispatch significant changes
			holdUpdated.dispatch(daNote, this, timeDiff);
		}

		var isHeld = daNote.isHeld;

		// Update trip progress
		if(isHeld && !daNote.isRoll){
			daNote.tripProgress = 1.0;
		}else
			daNote.tripProgress -= deltaTime / (daNote.maxReleaseTime * 1);

		// Handle roll notes
		if(daNote.isRoll && autoPlayed && daNote.tripProgress <= 0.5)
			holdPressCallback(daNote, this);

		// Check if hold was dropped
		if(daNote.tripProgress <= 0){
			holdDropped.dispatch(daNote, this);
			daNote.tripProgress = 0;
			daNote.tooLate = true;
			daNote.wasGoodHit = false;

			// Efficiently mark all tails as missed
			for(tail in daNote.unhitTail){
				tail.tooLate = true;
				tail.blockHit = true;
				tail.ignoreNote = true;
			}

			isHolding[daNote.column] = false;
			heldNotes.remove(daNote);
			receptorAnimStates[daNote.column] = "static";

		}else{
			// Optimized tail processing with caching
			processSustainTails(daNote);

			// Check if hold is finished
			if (daNote.holdingTime >= daNote.sustainLength)
			{
				holdFinished.dispatch(daNote, this);
				daNote.holdingTime = daNote.sustainLength;
				isHolding[daNote.column] = false;
				heldNotes.remove(daNote);

				// Only update animation if no other notes are being held on this column
				var hasOtherHolds = false;
				for (otherNote in heldNotes) {
					if (otherNote.column == daNote.column && otherNote != daNote) {
						hasOtherHolds = true;
						break;
					}
				}

				if (!hasOtherHolds && daNote.unhitTail.length == 0) {
					receptorAnimStates[daNote.column] = "static";
				}
			}
		}
	}

	/**
	 * Efficiently process sustain note tails with batching to avoid frame spikes
	 */
	private function processSustainTails(daNote:Note):Void
	{
		if (daNote.unhitTail.length == 0) return;

		// Adaptive tail processing based on framerate
		var processedCount = 0;
		// Reduce batch size at higher framerates to spread work across more frames
		var maxProcessPerFrame = dynamicSustainInterval == 4 ? 1 : (dynamicSustainInterval == 3 ? 2 : 3);

		// Process from beginning each time (simpler but still efficient for small arrays)
		for (i in 0...daNote.unhitTail.length) {
			if (processedCount >= maxProcessPerFrame) break;

			var tail = daNote.unhitTail[i];

			if ((tail.strumTime - 25) <= Conductor.songPosition) {
				if (!tail.wasGoodHit && !tail.tooLate) {
					noteHitCallback(tail, this);
					processedCount++;
				}
			} else {
				// No more tails ready to process (they're in chronological order)
				break;
			}
		}
	}
}
