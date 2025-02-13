package objects.playfields;

import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import backend.math.Vector3;
import openfl.Vector;
import openfl.geom.Vector3D;
import backend.modchart.ModManager;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSort;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.app.Event;
import flixel.math.FlxAngle;
import states.PlayState;
import states.MusicBeatState;
import backend.Rating;
import objects.Character;
import objects.notes.NoteSplash;
import objects.notes.Note;
import objects.notes.NoteObject;
import objects.notes.StrumNote;
import flixel.FlxBasic;

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

		return super.set_cameras(to);
	}

	public var spawnTime:Float = 1750; // spawn time for notes
	public var judgeManager(get, default):Rating; // for deriving judgements for input reasons
	function get_judgeManager()
		return judgeManager;
	public var spawnedNotes:Array<Note> = []; // spawned notes
	public var spawnedByData:Array<Array<Note>> = [[], [], [], [], [], [], [], [],[], [], [], [],[], [], [], [], [], []]; // spawned notes by data. Used for input
	public var noteQueue:Array<Array<Note>> = [[], [], [], [], [], [], [], [],[], [], [], [],[], [], [], [], [], []]; // unspawned notes
	public var backupQueue:Array<Array<Note>> = [[], [], [], [], [], [], [], [],[], [], [], [],[], [], [], [], [], []]; // notes for looping
	public var strumNotes:Array<StrumNote> = []; // receptors
	public var characters:Array<Character> = []; // characters that sing when field is hit
	public var noteField:NoteField; // renderer
	public var modNumber:Int = 0; // used for the mod manager. can be set to a different number to give it a different set of modifiers. can be set to 0 to sync the modifiers w/ bf's, and 1 to sync w/ the opponent's
	public var modManager:ModManager; // the mod manager. will be set automatically by playstate so dw bout this
	public var isPlayer:Bool = false; // if this playfield takes input from the player
	public var inControl:Bool = true; // if this playfield will take input at all
	public var AIPlayer:Bool = false; // if this playfield is played by the "AI" instead
	public var keyCount(default, set):Int = 4; // How many lanes are in this field
	public var autoPlayed(default, set):Bool = false; // if this playfield should be played automatically (botplay, opponent, etc)
	public var isEditor:Bool = false;

    public var x:Float = 0;
    public var y:Float = 0;
    
	function set_keyCount(cnt:Int){
		if (cnt < 0)
			cnt=0;
		if (keysPressed.length < cnt)
		{
			for (_ in (keysPressed.length)...cnt)
				keysPressed.push(false);
		}
		return keyCount = cnt;
	}

	function set_autoPlayed(aP:Bool){
		/*for (idx in 0...keysPressed.length)
			keysPressed[idx] = false;
		
		for(obj in strumNotes){
			obj.playAnim("static");
			obj.resetAnim = 0;
		}*/
		return autoPlayed = aP;
	}
	public var noteHitCallback:NoteCallback; // function that gets called when the note is hit. goodNoteHit and opponentNoteHit in playstate for eg
	public var holdPressCallback:NoteCallback; // function that gets called when a hold is stepped on. Only really used for calling script events. Return 'false' to not do hold logic
    public var holdReleaseCallback:NoteCallback; // function that gets called when a hold is released. Only really used for calling script events.

    public var grpNoteSplashes:FlxTypedGroup<NoteSplash>; // notesplashes
	public var strumAttachments:FlxTypedGroup<NoteObject>; // things that get "attached" to the receptors. custom splashes, etc.
	public static var extraStuff:FlxTypedGroup<FlxBasic>; // things that get added above the receptors.

	public var noteMissed:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time you miss a note. multiple functions can be bound here
	public var noteRemoved:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time a note is removed. multiple functions can be bound here
	public var noteSpawned:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time a note is spawned. multiple functions can be bound here
	public var noteMissPress:Event<NoteCallback> = new Event<NoteCallback>(); // event that gets called every time you tap without ghost tapping. multiple functions can be bound here

	public var keysPressed:Array<Bool> = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]; // what keys are pressed rn
    public var isHolding:Array<Bool> = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false];

	public function new(modMgr:ModManager){
		super();
		this.modManager = modMgr;

		//grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		//add(grpNoteSplashes);

		strumAttachments = new FlxTypedGroup<NoteObject>();
		strumAttachments.visible = false;
		add(strumAttachments);

		/*var splash:NoteSplash = new NoteSplash(100, 100, 0);
		splash.handleRendering = false;
		grpNoteSplashes.add(splash);
		grpNoteSplashes.visible = false; // so they dont get drawn
		splash.alpha = 0.0;*/

		////
		noteField = new NoteField(this, modMgr);
		//noteField.isEditor = isEditor;
		//add(noteField);

		// idk what haxeflixel does to regenerate the frames
		// SO! this will be how we do it
		// lil guy will sit here and regenerate the frames automatically
		// idk why this seems to work but it does	
		// TODO: figure out WHY this works
		var retard:StrumNote = new StrumNote(400, 400, 0);
		retard.playAnim("static");
		retard.alpha = 1;
		retard.visible = true;
		retard.color = 0xFF000000; // just to make it a bit harder to see
		retard.alpha = 0.9; // just to make it a bit harder to see
		retard.scale.set(0.002, 0.002);
		retard.handleRendering = false;
		retard.updateHitbox();
		retard.x = 400;
		retard.y = 400;
		@:privateAccess
		retard.draw();
		add(retard);

		extraStuff = new FlxTypedGroup<FlxBasic>();
	}

	// queues a note to be spawned
	public function queue(note:Note){
		if(noteQueue[note.column]==null)
			noteQueue[note.column] = [];
		noteQueue[note.column].push(note);
		noteQueue[note.column].sort((a, b) -> Std.int(a.strumTime - b.strumTime));
		
	}

	// unqueues a note
	public function unqueue(note:Note)
	{
		if (noteQueue[note.column] == null)
			noteQueue[note.column] = [];
		noteQueue[note.column].remove(note);
		noteQueue[note.column].sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	}

	public function requeue(note:Note)
	{
		var newColumn = note.noteData;
		if (note.column != newColumn)
		{
			removeNote(note);

			var newNote = new Note(note.strumTime, newColumn);
			// newNote.column = newColumn;
			// newNote.strumTime = note.strumTime;
			newNote.sustainLength = note.sustainLength;
			newNote.noteData = note.noteData;
			newNote.requiresTap = note.requiresTap;
			newNote.isSustainNote = note.isSustainNote;
			newNote.mustPress = note.mustPress;
			newNote.wasGoodHit = note.wasGoodHit;
			newNote.tooLate = note.tooLate;
			newNote.ignoreNote = note.ignoreNote;
			newNote.hitCausesMiss = note.hitCausesMiss;
			newNote.lowPriority = note.lowPriority;
			newNote.AIStrumTime = note.AIStrumTime;
			newNote.AIMiss = note.AIMiss;
			newNote.field = note.field;
			newNote.parent = note.parent;
			newNote.unhitTail = note.unhitTail;
			newNote.fieldIndex = note.fieldIndex;
			newNote.active = note.active;
			newNote.visible = note.visible;
			newNote.spawned = note.spawned;
			newNote.blockHit = note.blockHit;
			

			queue(newNote);
		}
	}

	// destroys a note
	public function removeNote(daNote:Note){
		daNote.active = false;
		daNote.visible = false;

		noteRemoved.dispatch(daNote, this);

		daNote.kill();
		spawnedNotes.remove(daNote);
		if (spawnedByData[daNote.column] != null)
			spawnedByData[daNote.column].remove(daNote);

		if (noteQueue[daNote.column] != null)
			noteQueue[daNote.column].remove(daNote);

		if (daNote.unhitTail.length > 0)
			while (daNote.unhitTail.length > 0)
				removeNote(daNote.unhitTail.shift());
		

		if (daNote.parent != null && daNote.parent.tail.contains(daNote))
			daNote.parent.tail.remove(daNote);

 		if (daNote.parent != null && daNote.parent.unhitTail.contains(daNote))
			daNote.parent.unhitTail.remove(daNote); 

		if (noteQueue[daNote.column] != null)
			noteQueue[daNote.column].sort((a, b) -> Std.int(a.strumTime - b.strumTime));
		remove(daNote);
		daNote.destroy();
	}

	// spawns a note
	public function spawnNote(note:Note){
		if(note.spawned)
			return;
		// trace("Loop mote: " + ClientPrefs.getGameplaySetting("loopMode"));
		
		if (noteQueue[note.column]!=null){
			noteQueue[note.column].remove(note);
			noteQueue[note.column].sort((a, b) -> Std.int(a.strumTime - b.strumTime));
			var loopMode = ClientPrefs.getGameplaySetting("loopMode") || ClientPrefs.getGameplaySetting("loopModeC");
			// trace("Loop mode: " + loopMode);
			if (loopMode)
				backupQueue[note.column].push(note);
			// trace("backup");
		}

		//trace(noteQueue[note.column]);

		if (spawnedByData[note.column]!=null)
			spawnedByData[note.column].push(note);
		else
			return;
		
		noteSpawned.dispatch(note, this);
		spawnedNotes.push(note);
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
	public function input(data:Int){
		if (!PlayState.instance.boyfriend.stunned)
		{
			switch (ClientPrefs.data.inputSystem)
			{
				case "Native":
					if(data > keyCount || data < 0)return null;
					
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
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
							noteMissed.dispatch(note, this);
							return note;
						}
					}
					if (!ClientPrefs.data.ghostTapping)
					{
						PlayState.instance.noteMissPress(data);
					}
				case 'BEAT! Engine':
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					// more accurate hit time for the ratings?
					var lastTime:Float = Conductor.songPosition;
					Conductor.songPosition = FlxG.sound.music.time;

					var canMiss:Bool = !ClientPrefs.data.ghostTapping;

					// heavily based on my own code LOL if it aint broke dont fix it
					var pressNotes:Array<Note> = [];
					// var notesDatas:Array<Int> = [];
					var notesStopped:Bool = false;

					var sortedNotesList:Array<Note> = [];
					for (daNote in noteList)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
						{
							if (daNote.noteData == data)
							{
								sortedNotesList.push(daNote);
								// notesDatas.push(daNote.noteData);
							}
							if (!ClientPrefs.data.noAntimash)
							{ // shut up
								canMiss = true;
							}
						}
					}
					sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					if (sortedNotesList.length > 0)
					{
						for (epicNote in sortedNotesList)
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
								var note:Note = sortedNotesList.pop();
								noteHitCallback(note, this);
								return note;
							}
						}
					}
					else if (canMiss)
					{
						PlayState.instance.noteMissPress(data);
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

					var dataNotes = [];
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
						PlayState.instance.noteMissPress(data);
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
						PlayState.instance.noteMissPress(data);

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
									PlayState.instance.noteMissPress(shit);
							}
						}
						for (coolNote in possibleNotes)
						{
							if (keysPressed[coolNote.noteData])
							{
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
								PlayState.instance.noteMissPress(shit);
					}

					if (dontCheck && possibleNotes.length > 0 || !ClientPrefs.data.noAntimash && possibleNotes.length > 0)
					{
						if (PlayState.instance.mashViolations > (Note.ammo[PlayState.mania]) && !ClientPrefs.data.noAntimash)
						{
							trace('mash violations ' + PlayState.instance.mashViolations);
							PlayState.instance.scoreTxt.color = FlxColor.RED;
							for (shit in 0...keysPressed.length)
								if (keysPressed[shit])
									PlayState.instance.noteMissPress(shit);
							PlayState.instance.health -= 0.05;
							PlayState.instance.bfkilledcheck = true;
						}
						else
							PlayState.instance.mashViolations++;
					}

				case "Andromeda Engine (legacy)":
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && note.requiresTap);
					noteList.sort((a,b)->Std.int(a.strumTime-b.strumTime)); // SHOULD be in order?
					// But just incase, we do this sort
					if(noteList.length>0){
						var hitNote = noteList[0];
						if(!hitNote.wasGoodHit) // because parent tap notes
						{
							noteHitCallback(hitNote, this);
							return hitNote;
						}
					}else{
						if(!ClientPrefs.data.ghostTapping)
							PlayState.instance.noteMissPress(data);
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

					haxe.ds.ArraySort.sort(defNotes, sortNotes);

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
						PlayState.instance.noteMissPress(data);

					Conductor.songPosition = lastConductorTime;
			}
		}

		return null;
	}

	//for community input
	function sortNotes(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	// generates the receptors
	public function generateStrums(){
		final strumLine:FlxPoint = FlxPoint.get(ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, (ClientPrefs.data.downScroll) ? FlxG.height - 150 : 50);
		for(i in 0...keyCount){
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, strumLine.y, i);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = 1;
			insert(0, babyArrow);
			babyArrow.handleRendering = false; // NoteField handles rendering
			babyArrow.cameras = cameras;
			strumNotes.push(babyArrow);
			babyArrow.playerPosition();
			if (ClientPrefs.data.showKeybindsOnStart && this.isPlayer)
			{
				for (j in 0...PlayState.instance.keysArray[PlayState.mania][i].length)
				{
					var keysArray = PlayState.instance.keysArray;
					var daKeyTxt:FlxText = new FlxText(babyArrow.x, babyArrow.y - 10, 0, utils.InputFormatter.getKeyName(keysArray[PlayState.mania][i][j]), 32);
					daKeyTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					daKeyTxt.borderSize = 1.25;
					daKeyTxt.alpha = 0;
					daKeyTxt.size = 32 - PlayState.mania; // essentially if i ever add 0k!?!?
					daKeyTxt.x = babyArrow.x + (babyArrow.width / 2);
					daKeyTxt.x -= daKeyTxt.width / 2;
					extraStuff.insert(1, daKeyTxt);
					daKeyTxt.cameras = cameras;
					var textY:Float = (j == 0 ? babyArrow.y - 32 : ((babyArrow.y - 32) + babyArrow.height) - daKeyTxt.height);
					// daKeyTxt.y = -daKeyTxt.height;
					

					FlxTween.tween(daKeyTxt, {y: textY, alpha: 1, angle: 360}, 5, {
						ease: FlxEase.circOut,
						onComplete: function(t) {
							new FlxTimer().start(4, function(_) {
								FlxTween.tween(daKeyTxt, {y: daKeyTxt.y + 32, alpha: 0, angle: 720}, 1, {
									ease: FlxEase.circIn,
									onComplete: function(t) {
										remove(daKeyTxt);
									}
								});
							});
						}
					});
				}
			}
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

	private function getKeyBinds(mania:Int):Array<Dynamic> {
		// Return the keybind for the given index
		var keyBinds:Array<Dynamic> = backend.Keybinds.fill()[mania];
		return keyBinds;
	}

	private function getBinding(mania:Int, index:Int):String {
		// Return the keybind for the given index
		return getKeyBinds(mania)[index];
	}

	// just sorts by z indexes, not used anymore tho
	function sortByOrderNote(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	// spawns a notesplash w/ specified skin. optional note to derive the skin and colours from.

	/*public function spawnSplash(note:Note, splashSkin:String){
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(0, 0, note.column);
		splash.handleRendering = false;
		grpNoteSplashes.add(splash);
		return splash;
	}*/

	// spawns notes, deals w/ hold inputs, etc.
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

		for (data => column in noteQueue)
		{
			if (column[0] != null)
			{
				var dataSpawnTime = modManager.get("noteSpawnTime" + data); 
				var noteSpawnTime = (dataSpawnTime != null && dataSpawnTime.getValue(modNumber)>0)?dataSpawnTime:modManager.get("noteSpawnTime");
				var time:Float = noteSpawnTime == null ? spawnTime : noteSpawnTime.getValue(modNumber); // no longer averages the spawn times
				if (time <= 0)time = spawnTime;
                
                if (column.length > 0 && column[0].strumTime - Conductor.songPosition < time)
					spawnNote(column[0]);
			}
			for (data => column in backupQueue)
				{if (column[0] != null)
					{
						var dataSpawnTime = modManager.get("noteSpawnTime" + data); 
						var noteSpawnTime = (dataSpawnTime != null && dataSpawnTime.getValue(modNumber)>0)?dataSpawnTime:modManager.get("noteSpawnTime");
						var time:Float = noteSpawnTime == null ? spawnTime : noteSpawnTime.getValue(modNumber); // no longer averages the spawn times
						if (time <= 0)time = spawnTime;
						
						if (column.length > 0 && Conductor.songPosition > column[0].strumTime)
						{
							var note = column.shift();
							note.spawned = false;
							noteQueue[data].push(note);
							// trace("backup");
						}
					}
				}
		}

		super.update(elapsed);

		for(obj in strumNotes)
			modManager.updateObject(curDecBeat, obj, modNumber);

		//spawnedNotes.sort(sortByOrderNote);

		var garbage:Array<Note> = [];
		for (daNote in spawnedNotes)
		{
			if(!daNote.alive){
				spawnedNotes.remove(daNote);
				continue;
			}
			//modManager.updateObject(curDecBeat, daNote, modNumber);

			// check for hold inputs
			if(!daNote.isSustainNote){
				if(daNote.column > keyCount-1){
					garbage.push(daNote);
					continue;
				}
				if(daNote.holdingTime < daNote.sustainLength && inControl && !daNote.blockHit){
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
						daNote.holdingTime = Conductor.songPosition - daNote.strumTime;

                        
						if(isHeld){ // TODO: find a good natural way to script the isRoll thing
							// should i do this??? idfk lol
							if (receptor.animation.finished || receptor.animation.curAnim.name != "confirm") 
								receptor.playAnim("confirm", true);
							
							daNote.tripProgress = 1.0;
						}else
							daNote.tripProgress -= elapsed / (daNote.maxReleaseTime * 1);

                        if(autoPlayed && daNote.tripProgress <= 0.5)
                            holdPressCallback(daNote, this); // would set tripProgress back to 1 but idk maybe the roll script wants to do its own shit

						if(daNote.tripProgress <= 0){
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

							if (daNote.holdingTime >= daNote.sustainLength || daNote.unhitTail.length == 0)
							{
                                //trace("finished hold");
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
			if (daNote.isParent && daNote.tooLate && !daNote.isSustainNote)
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
					if (!daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
						noteMissed.dispatch(daNote, this);
				} 

				if((
					(daNote.holdingTime>=daNote.sustainLength ) && daNote.sustainLength>0 ||
					daNote.isSustainNote && daNote.strumTime - Conductor.songPosition < -350 ||
					!daNote.isSustainNote && (daNote.sustainLength==0 || daNote.tooLate) && daNote.strumTime - Conductor.songPosition < -(200 + ClientPrefs.data.badWindow)) && (daNote.tooLate || daNote.wasGoodHit))
				{
					daNote.garbage = true;
					garbage.push(daNote);
				}
				
			}
		}

		for(note in garbage)removeNote(note);
		

		if (AIPlayer)
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
				for (daNote in getNotes(i, (note:Note) -> !note.ignoreNote && !note.hitCausesMiss)){
					if (!daNote.isSustainNote){
						var hitDiff = Conductor.songPosition - daNote.strumTime;
						if (isPlayer && (hitDiff + ClientPrefs.data.ratingOffset) >= (-5 * 1) || hitDiff >= 0){
							if (noteHitCallback!=null) noteHitCallback(daNote, this);
						}
					}
				}
			}
		}else{
			for(data in 0...keyCount){
				if (keysPressed[data]){
					var noteList = getNotesWithEnd(data, Conductor.songPosition + ClientPrefs.data.badWindow, (note:Note) -> !note.isSustainNote && !note.requiresTap);
					
					#if PE_MOD_COMPATIBILITY
					// so lowPriority actually works (even though i hate it lol!)
					noteList.sort((a, b) -> Std.int((b.strumTime + (b.lowPriority ? 10000 : 0)) - (a.strumTime + (a.lowPriority ? 10000 : 0)))); 
					#else
					noteList.sort((a, b) -> Std.int(b.strumTime - a.strumTime));
					#end
					
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
			if (note.alive && note.column == dir && !note.wasGoodHit && !note.tooLate)
			{
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
					if (Math.abs(last.strumTime - current.strumTime) <= Conductor.stepCrochet / (192 / 16))
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

		return super.destroy();
	}
}