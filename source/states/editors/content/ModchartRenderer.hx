package states.editors.content;

import backend.modchart.ModManager;
import backend.modchart.Modifier;
import flixel.util.FlxSort;
import objects.*;
import objects.Note.SustainPart;
import objects.NoteObject;
import objects.playfields.*;
import states.PlayState.SpeedEvent;

class ModchartRenderer extends FlxSprite // Apparently this is the best way to do this???
{

  public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

  public var modManager:ModManager;
	public var notefields = new NotefieldRenderer();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes
  public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var playerField:PlayField;
	public var dadField:PlayField;

  public var currentSV:SpeedEvent = {position: 0, startTime: 0, speed: 1 #if EASED_SVs , startSpeed: 1 #end};
	var speedChanges:Array<SpeedEvent> = [];

  public var inEditor:Bool = false;
  public var editorPaused:Bool = false;
  public var speed:Float = 3;

  public function new(?modManager:ModManager, ?allNotes:Array<Note>, ?instance:MusicBeatState, ?instance2:MusicBeatSubstate)
  {
    super();
    notes = new FlxTypedGroup<Note>();
    this.modManager = modManager ?? new ModManager((instance ?? (cast instance2 ?? null)));
    loadPlayfields();
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    modManager.update(elapsed, MusicBeatState.pubCurDecBeat, MusicBeatState.pubCurDecStep);
    updateVisualPosition();
    for (field in playfields)
			field.noteField.songSpeed = speed;
    currentSV = getSV(Conductor.songPosition);
  }

  override public function draw()
  {
    if (alpha == 0 || !visible)
      return;

    if (notes != null) notes.cameras = this.cameras;
    if (notefields != null) notefields.cameras = this.cameras;
    if (playfields != null) playfields.cameras = this.cameras;
    if (playerField != null) playerField.cameras = this.cameras;
    if (dadField != null) dadField.cameras = this.cameras;

    playfields.draw();
    notefields.draw();
    PlayField.extraStuff.draw();
    //draw notes to screen
  }

  public function loadPlayfields() {
    setupPlayFields();

    if (playerField != null) playerField.strumNotes = [];
		if (dadField != null) dadField.strumNotes = [];

    for(field in playfields.members) {
      field.keyCount = Note.ammo[PlayState.mania];
			field.generateStrums();
		}

    for(field in playfields.members)
			field.fadeIn(true);

    modManager.registerDefaultModifiers();

    speedChanges.push({
			position: -6000 * 0.45,
			startTime: -6000,
			speed: 1,
			#if EASED_SVs
			startSpeed: 1,
			#end
		});

    speedChanges.sort(svSort);
		#if EASED_SVs
		resetSVDeltas();
		#end
  }

  function setupPlayFields() {
    trace("Making New Playfields!");
    modManager.playerAmount = modManager.modchartFile.data.playfields;
		for (i in 0...modManager.playerAmount) {
			newPlayfield();
    }

		trace("Making PlayerField!");
		playerField = playfields.members[0];
		if (playerField != null) {
			playerField.isPlayer = true;
			playerField.autoPlayed = true;
			playerField.owner = null;
			playerField.owners = [];
		}

		trace("Making DadField!");
		dadField = playfields.members[1];
		if (dadField != null) {
			dadField.isPlayer = false;
			dadField.autoPlayed = true;
			dadField.AIPlayer = false;
			dadField.owner = null;
			dadField.owners = [];
		}

		PlayField.initExtras();

		trace("Adding Playfields!");
  }

  public function newPlayfield()
  {
    var field = new PlayField(modManager);
    field.modNumber = playfields.members.length;
    field.playerId = field.modNumber;
    field.cameras = playfields.cameras;
    initPlayfield(field);
    playfields.add(field);
    return field;
  }

  // good to call this whenever you make a playfield
  public function initPlayfield(field:PlayField){
    notefields.add(field.noteField);

    field.holdPressCallback = pressHold;
    field.holdStepCallback = stepHold;
    field.holdReleaseCallback = releaseHold;

    field.noteRemoved.add((note:Note, field:PlayField) -> {
      allNotes.remove(note);
      unspawnNotes.remove(note);
      notes.remove(note, true);
    });
    field.noteMissed.add((daNote:Note, field:PlayField) -> {
      trace("Missed!");
      if (field.isPlayer && !field.autoPlayed && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
      {
        allNotes.remove(daNote);
        unspawnNotes.remove(daNote);
        notes.remove(daNote, true);
      }

    });

    field.noteSpawned.add((dunceNote:Note, field:PlayField) -> {
      notes.add(dunceNote);
      var index:Int = unspawnNotes.indexOf(dunceNote);
      unspawnNotes.splice(index, 1);
    });


    field.holdDropped.add((daNote:Note, field:PlayField) -> {
      if (!field.isPlayer)return;
    });

    field.holdFinished.add((daNote:Note, field:PlayField) -> {
      if (!field.isPlayer)return;
    });

  }

  public function getSV(time:Float){
		var svIndex:Int = 0;

		var event:SpeedEvent = speedChanges[svIndex];
		if (svIndex < speedChanges.length - 1) {
			while (speedChanges[svIndex + 1] != null && speedChanges[svIndex + 1].startTime <= time) {
				event = speedChanges[svIndex + 1];
				svIndex++;
			}
		}

		return event;
	}

  public function getNoteInitialTime(time:Float)
  {
    var event:SpeedEvent = getSV(time);
    return PlayState.getTimeFromSV(time, event);
  }

  //Yes this is all these do
  inline function stepHold(note:Note, field:PlayField)
  {
    // sumthin idk
  }
  inline function pressHold(note:Note, field:PlayField) {
    // sumthin idk
  }

  inline function releaseHold(note:Note, field:PlayField):Void {
    // sumthin idk
  }
  //No im not kidding

  public function addNoteToField(note:Note, ?field:Int = 0)
  {
    if (field < 0 || field >= playfields.members.length)
      field = if (note.mustPress) 0 else 1;
    playfields.members[field].queue(note);
  }

  public function clearNotesBefore(time:Float)
  {
    var i:Int = allNotes.length - 1;
    while (i >= 0)
    {
      var daNote:Note = allNotes[i];
      if (daNote.strumTime - 350 < time)
      {
        daNote.ignoreNote = true;
        for (field in playfields.members)
          field.removeNote(daNote);
      }
      --i;
    }
  }

  private var svIndex:Int =0;
	private inline function updateVisualPosition() {
		var event:SpeedEvent = null;

		for (i in svIndex+1...speedChanges.length) {
			var nextEvent = speedChanges[i];
			if (nextEvent.startTime > Conductor.songPosition)
				break;

			svIndex = i;
			event = nextEvent;
		}
		event ??= speedChanges[svIndex];

		Conductor.visualPosition = PlayState.getTimeFromSV(Conductor.songPosition, event);
		FlxG.watch.addQuick("visualPos", Conductor.visualPosition);
	}

  #if EASED_SVs
	var lastSVTime:Float = 0;
	var lastSVElapsed:Float = 0;
	var lastSVPos:Float = 0;

	inline function resetSVDeltas(){
		if(speedChanges.length > 0){
			lastSVTime = speedChanges[0].startTime;
			lastSVElapsed = 0;
			lastSVPos = speedChanges[0].position;
		}else{
			lastSVTime = -5000;
			lastSVElapsed = 0;
			lastSVPos = -5000 * 0.45;
		}
	}
	#end

  function svSort(Obj1:SpeedEvent, Obj2:SpeedEvent):Int
    return FlxSort.byValues(FlxSort.ASCENDING, Obj1.startTime, Obj2.startTime);

}
