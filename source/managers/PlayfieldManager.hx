package managers;
import backend.Song.SwagSong;
import backend.funkinmodchart.Manager;
import backend.modchart.ModManager;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import objects.Note;
import objects.NoteManager;
import objects.NoteSplash;
import objects.StrumNote;
import objects.playfields.PlayField;
import openfl.events.KeyboardEvent;
import yutautil.modules.ASync.ASyncF;
import yutautil.modules.ASync;

class PlayfieldManager {
  public static var instance:PlayfieldManager;
  public static var SONG:SwagSong = null;
  public static var mania:Array<Int> = [3, 3];

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
  public static var curChart:Array<Note> = [];
  public static var chartCache:Map<String, SongObject> = new Map<String, SongObject>();

  public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
  public var eventNotes:Array<EventNote> = [];
	public var curEvents:Array<EventNote> = [];

  public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

  public var generatedChart:Bool = false;
  public var cpuControlled:Bool = false;
  public var curSong:String = "";

  @:noCompletion function set_cpuControlled(value:Bool):Bool {
		cpuControlled = value;

		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.setOnScripts('botPlay', value);

		/// oughhh
		for (playfield in playfields.members){
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled || ClientPrefs.getGameplaySetting('showcase', false);
		}

		return value;
	}

	public var songSpeed:Float = 1;
	public var songSpeedType:String = "multiplicative";

  //Input
	public var keysPressed:Array<Int> = [];
  private static var keysPressedSet:Map<Int, Bool> = new Map();
  public static var keysArray:Array<Array<Dynamic>>;
	private var controlArray:Array<String>;

  // Cache for expensive operations
	public var _cachedStrumPositions:Array<Float> = [];
	public var _cachedNotePositions:Array<Float> = [];

  // Misc.
  public var noteRows:Array<Array<Array<Note>>> = [[],[]];
  public var ghostsAllowed:Bool = ClientPrefs.data.doubleGhosts;
  public var freezeNotes:Bool = false;
	public var localFreezeNotes:Bool = false;

  // UNO mechanic instance for chart modifier
	var unoMechanic:UnoMechanic;

  // Gameplay Modifiers
  public var chartModifier:String = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');
	public var convertMania:Int = ClientPrefs.getGameplaySetting('convertMania', 3);
  public var opponentmode:Bool = ClientPrefs.getGameplaySetting('opponentplay', false);
  public var oppDifficulty:String = 'Average FNF Player'; // Mix-Up things. You wouldn't get it.
	public var bothMode:Bool = ClientPrefs.getGameplaySetting('bothMode', false);
  public var RandomSpeedChange:Bool = ClientPrefs.getGameplaySetting('randomspeedchange', false);
	public var RandomSpeedChangeWild:Bool = false;

  //The actual playfield stuff
  public var modManager:ModManager;
	public var notefields = new NotefieldRenderer();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes
	public var playerField:PlayField;
	public var dadField:PlayField;
  public var currentSV:SpeedEvent = {position: 0, startTime: 0, speed: 1 #if EASED_SVs , startSpeed: 1 #end};
	static var speedChanges:Array<SpeedEvent> = [];
  public var skipArrowStartTween:Bool = false; //for lua

  // Skydecay Engine (our good friends)
	public var noteManager:NoteManager;

  // Because this would be really funny
  public var fmManager:Manager;

  public var songName:String;

  public var manualInputChecks:Bool = false;

  public function new() {
    instance = this;
    mania = [3, 3];
    SONG = null;
    noteManager = new NoteManager();
    if (keysArray == null)
			keysArray = backend.Keybinds.fill();
    controlArray = ['NOTE_LEFT', 'NOTE_DOWN', 'NOTE_UP', 'NOTE_RIGHT'];
    speedChanges.push({
			position: -6000 * 0.45,
			startTime: -6000,
			speed: 1,
			#if EASED_SVs
			startSpeed: 1,
			#end
		});
    #if EASED_SVs
		resetSVDeltas();
		#end
    speedChanges.sort(svSort);
    manualInputChecks = false;
  }

  /// Mania
  public function fixMania() {
    convertMania = ClientPrefs.getGameplaySetting('convertMania', 3);
    for (fMania in mania) {
      if (fMania > Note.maxMania || fMania < Note.minMania)
        fMania = Note.defaultMania;
      else if (chartModifier == "4K Only")
        fMania = 3;
      else if (chartModifier == "ManiaConverter")
        fMania = convertMania;
      else if (SONG.mania != null)
        if (SONG.startMania != null) // If its a mixtape chart, use this instead
          fMania = SONG.startMania;
        else if (SONG.mania >= 3) //Make sure it's even there
          fMania = SONG.mania;
        else {
          fMania = switch (SONG.mania) { //Convert it to make sure the older versions still work
            case 0: 3;
            case 1: 4;
            default: SONG.mania;
          }
        }
      else fMania = 3;

      trace("Mania set: " + fMania);
    }
  }

  public function changeMania(newValue:Int, field:PlayField = null, skipStrumFadeOut:Bool = false)
	{
		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('preChangeMania', [mania[field.modNumber], newValue, skipStrumFadeOut]);

    var daOldMania = mania[field.modNumber];
		mania[field.modNumber] = newValue;

		if (field != null) field.strumNotes = [];

    if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('onChangeMania', [mania[field.modNumber], daOldMania]);


		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.setOnScripts('mania', mania[field.modNumber]);

    notes.forEachAlive(function(note:Note)
		{
			updateNote(note);
		});

		for (noteI in 0...allNotes.length)
		{
			var note:Note = allNotes[noteI];
			updateNote(note);
		}

		if (MusicBeatState.getState() == PlayState.instance) {
      PlayState.instance?.callOnScripts('preReceptorGeneration'); // backwards compat, deprecated
  		PlayState.instance?.callOnScripts('onReceptorGeneration');
    }

		field.keyCount = Note.ammo[mania[field.modNumber]];
		field.generateStrums();

		if (MusicBeatState.getState() == PlayState.instance) {
      PlayState.instance?.callOnScripts('postReceptorGeneration'); // deprecated
  		PlayState.instance?.callOnScripts('onReceptorGenerationPost');
	  	PlayState.instance?.callOnScripts('onChangeMania', [mania[field.modNumber], newValue, skipStrumFadeOut]);
    }

		for (field in playfields.members)
			field.fadeIn(skipStrumFadeOut); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode

		field.singAnimations = Note.keysShit.get(mania[field.modNumber]).get('singAnims');

		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('postChangeMania', [mania, newValue, skipStrumFadeOut]);
	}

  function updateNote(note:Note)
	{
		if (note != null) {
			var tMania:Int = note.field.keyCount;
			var noteData:Int = note.noteData;

			note.scale.set(1, 1);
			note.updateHitbox();

			// Like reloadNote()

			var lastScaleY:Float = note.scale.y;
			if (PlayState.isPixelStage)
			{
				// if (note.isSustainNote) {note.originalHeightForCalcs = note.height;}

				note.setGraphicSize(Std.int(note.width * PlayState.daPixelZoom * Note.pixelScales[mania[note.fieldIndex]]));
			}
			else
			{
				// Like loadNoteAnims()

				note.setGraphicSize(Std.int(note.width * Note.scales[mania[note.fieldIndex]]));
				note.updateHitbox();
			}

			if (note.isSustainNote)
			{
				note.scale.y = lastScaleY;
			}
			note.updateHitbox();

			// Like new()

			var prevNote:Note = note.prevNote;

			if (note.isSustainNote && prevNote != null)
			{
				note.offsetX += note.width / 2;

				note.animation.play(Note.keysShit.get(mania[note.fieldIndex]).get('letters')[noteData] + ' tail');

				note.updateHitbox();

				note.offsetX -= note.width / 2;

				if (note != null && prevNote != null && prevNote.isSustainNote && prevNote.animation != null)
				{ // haxe flixel
					prevNote.animation.play(Note.keysShit.get(mania[note.fieldIndex]).get('letters')[noteData % tMania] + ' hold');

					prevNote.scale.y *= MegaManager.conductor.stepLengthMs / 100 * 1.05;
					prevNote.scale.y *= PlayfieldManager.instance.songSpeed;

					if (PlayState.isPixelStage)
					{
						prevNote.scale.y *= 1.19;
						prevNote.scale.y *= (6 / note.height);
					}

					prevNote.updateHitbox();
					// trace(prevNote.scale.y);
				}

				if (PlayState.isPixelStage && prevNote != null)
				{
					prevNote.scale.y *= PlayState.daPixelZoom * (Note.pixelScales[mania[prevNote.fieldIndex]]); // Fuck urself
					prevNote.updateHitbox();
				}
			}
			else if (!note.isSustainNote && noteData > -1 && noteData < tMania)
			{
				if (note.changeAnim)
				{
					var animToPlay:String = '';

					animToPlay = Note.keysShit.get(mania[note.fieldIndex]).get('letters')[noteData % tMania];

					note.animation.play(animToPlay);
				}
			}

			note.defaultRGB();

			// Like set_noteType()
		}
	}

  public function generateStrums():Void
	{
		trace('GENERATING STRUMS!');
		if (MusicBeatState.getState() == PlayState.instance) {
      #if ALLOW_DEPRECATION PlayState.instance?.callOnScripts('preReceptorGeneration'); #end // backwards compat, deprecated
		  PlayState.instance?.callOnScripts('onReceptorGeneration');
    }

		for(field in playfields.members) {
      if (field != null) {
        field.strumNotes = [];
        trace('Generating Strums for field ${field.modNumber}');
        field.keyCount = Note.ammo[3];
        field.generateStrums();

        field.fadeIn(skipArrowStartTween);

        if (field.modNumber == 0) {
          for (strum in field.strumNotes) {
            playerStrums.add(strum);
            strumLineNotes.add(strum);
          }
        } else if (field.modNumber == 1) {
          for (strum in field.strumNotes) {
            opponentStrums.add(strum);
            strumLineNotes.add(strum);
          }
        }
      }
		}

    if (MusicBeatState.getState() == PlayState.instance) {
      #if ALLOW_DEPRECATION
      PlayState.instance?.callOnScripts('postReceptorGeneration'); // deprecated
      #end
      PlayState.instance?.callOnScripts('onReceptorGenerationPost');
    }
    trace("Finished Note Generation!");
	}

  private function generatePlayerStrums(player:Int):Void
	{
		//trace('GENERATING STRUMS!');
    if (MusicBeatState.getState() == PlayState.instance) {
      #if ALLOW_DEPRECATION
      PlayState.instance?.callOnScripts('prePlayerReceptorGeneration'); // backwards compat, deprecated
      #end
      PlayState.instance?.callOnScripts('onPlayerReceptorGeneration');
    }

    playfields.members[player].keyCount = Note.ammo[mania[playfields.members[player].modNumber]];
    playfields.members[player].generateStrums();

		playfields.members[player].fadeIn(skipArrowStartTween);

		#if PE_MOD_COMPATIBILITY
		for (i in playfields.members[player].strumNotes) {
      if (player == 0)
        opponentStrums.add(i);
      else if (player == 1)
        playerStrums.add(i);

      strumLineNotes.add(i);
		}
		#end

    if (MusicBeatState.getState() == PlayState.instance) {
      #if ALLOW_DEPRECATION
      PlayState.instance?.callOnScripts('postPlayerReceptorGeneration'); // deprecated
      #end
      PlayState.instance?.callOnScripts('onPlayerReceptorGenerationPost');
    }
	}

  /// Playfields
  public function setModMan(state:FlxState) {
    modManager = new ModManager(state);
  }

  private var svIndex:Int = 0;
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

		if (!freezeNotes) RConductor.visualPosition = getTimeFromSV(MegaManager.conductor.musicPosition, event);
	}

	public static function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return MegaManager.playfield?.getTimeFromSV(time, event);
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

	public function getTimeFromSV(time:Float, event:SpeedEvent):Float {
		#if EASED_SVs
		var func:EaseFunction = event?.easeFunc;
		if (event?.endTime != null) {
			var timeElapsed:Float = FlxMath.remapToRange(time, event.startTime, event.endTime, 0, 1);
			if(timeElapsed > 1)timeElapsed = 1;
			if(timeElapsed < 0)timeElapsed = 0;
			var currentSpeed = FlxMath.lerp(event.startSpeed, event.speed, func(lastSVElapsed));

			var toAdd:Float = time - lastSVTime;
			var finalPosition:Float = lastSVPos + toAdd * currentSpeed;

			lastSVPos = finalPosition;
			lastSVTime = time;
			lastSVElapsed = timeElapsed;
			return finalPosition;
		}
		#end

		return event?.position + ((time - event?.startTime) * 0.45 * event?.speed);
	}

	public static function getSV(time:Float){
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

		field.holdPressCallback.add(pressHold);
		field.holdStepCallback.add(stepHold);
		field.holdReleaseCallback.add(releaseHold);

		field.noteRemoved.add((note:Note, field:PlayField) -> {
			allNotes.remove(note);
			unspawnNotes.remove(note);
			notes.remove(note, true);
		});

		field.noteSpawned.add((dunceNote:Note, field:PlayField) -> {
			if (MusicBeatState.getState() == PlayState.instance)
        PlayState.instance?.callOnScripts('onSpawnNote', [dunceNote.noteReflection]);
      if (MusicBeatState.getState() == PlayState.instance) {
        #if LUA_ALLOWED
        PlayState.instance?.callOnLuas('onSpawnNote', [
          allNotes.indexOf(dunceNote),
          dunceNote.column,
          dunceNote.noteType,
          dunceNote.isSustainNote,
          dunceNote.strumTime
        ]);
        #end
      }

			notes.add(dunceNote);
			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.splice(index, 1);

			if (MusicBeatState.getState() == PlayState.instance)
        PlayState.instance?.callOnScripts('onSpawnNotePost', [dunceNote.noteReflection]);
		});


		field.holdDropped.add((daNote:Note, field:PlayField) -> {
			if (!field.isPlayer)return;
		});

		field.holdFinished.add((daNote:Note, field:PlayField) -> {
			if (!field.isPlayer)return;
		});

	}

  public function addHoldPressCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.holdPressCallback.add(callback);
  public function addHoldStepCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.holdStepCallback.add(callback);
  public function addHoldReleaseCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.holdReleaseCallback.add(callback);
  public function addNoteRemovedCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.noteRemoved.add(callback);
  public function addNoteMissCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.noteMissed.add(callback);
  public function addNoteHitCallbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.noteHitCallback.add(callback);
  public function addNoteSpawnedCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.noteSpawned.add(callback);
  public function addHoldDroppedCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.holdDropped.add(callback);
  public function addHoldFinishedCalbackToField(callback:PlayField.NoteCallback, field:PlayField)
    field.holdFinished.add(callback);

  //Yes this is all these do
	inline function stepHold(note:Note, field:PlayField)
	{
		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts("onHoldStep", [note, field]);

    if (MusicBeatState.getState() == PlayState.instance) {
      if(field.isPlayer){
        if (PlayState.instance?.holdsGiveHP #if MECHANICS_MOD_ALLOWED && (PlayState.mechanicsMod != null && !PlayState.mechanicsMod.restoreActivated) #end){
          PlayState.instance.health += note.hitHealth * PlayState.instance.healthGain;
        }
      }
    }
	}

	inline function pressHold(note:Note, field:PlayField) {
		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts("onHoldPress", [note, field]);
	}

	inline function releaseHold(note:Note, field:PlayField):Void {
		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts("onHoldRelease", [note, field]);
	}
	//No im not kidding

  // Chart Loading
  public function loadChart(songName:String, folder:String, ?preload:Bool = false, ?loadDirectly:Bool = false) {
    var tempSongObj:String = new SongObjectType(songName, folder).toString();
    trace('Song Info: $tempSongObj\nCache: $chartCache\nDoes it exist?: ${chartCache.exists(tempSongObj)}');
    this.songName = Paths.formatToSongPath(SONG.song).toLowerCase();
    songSpeed = SONG?.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG?.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
    if (chartCache.exists(tempSongObj) && !loadDirectly) {
      trace("USING CACHED CHART FOR: "+songName+"\nFROM MOD: "+folder);
      var tempChart = chartCache.get(tempSongObj).copyChart();
      allNotes = tempChart.copy();
      for (note in allNotes) {
        note = Note.quickMakeNote(note);
        if (playerField != null)
          if (note.mustPress) {
            note.field = playerField;
            updateNote(note);
            playerField.queue(note);
          }

        if (dadField != null)
          if (!note.mustPress) {
            note.field = dadField;
            updateNote(note);
            dadField.queue(note);
          }
      }
      unspawnNotes = curChart = allNotes;

      try
      {
        var eventsChart:SwagSong = Song.getChart('events-${Difficulty.getString().toLowerCase()}', this.songName);
        if(eventsChart != null)
          for (event in eventsChart.events) //Event Notes
            for (i in 0...event[1].length) {
              makeEvent(event, i);
            }
      }
      catch(e:Dynamic) {
        trace('events-${Difficulty.getString().toLowerCase()} DOESN\'T EXSIST FOR SONG ${this.songName}!');
      }

      try
      {
        var eventsChart:SwagSong = Song.getChart('events', this.songName);
        if(eventsChart != null)
          for (event in eventsChart.events) //Event Notes
            for (i in 0...event[1].length) {
              makeEvent(event, i);
            }
      }
      catch(e:Dynamic) {
        trace('events DOESN\'T EXSIST FOR SONG ${this.songName}!');
      }

      try
      {
        for (event in SONG.events) //Event Notes
          for (i in 0...event[1].length) {
            makeEvent(event, i);
          }
      }
      catch(e:Dynamic) {
        trace('in-chart events DOESN\'T EXSIST FOR SONG ${this.songName}!');
      }
    } else {
      trace("Generate chart normally");
      generateChart(SONG, preload);
    }
    trace("Chart Generated");
  }

  public var noteTypes:Array<String> = [];
	public var eventsPushed:Array<String> = [];
	private var totalColumns:Int = Note.ammo[SONG?.mania != null ? SONG?.mania : 3];
	var prevNoteData:Int = -1;
	var initialNoteData:Int = -1;
	var caseExecutionCount:Int = FlxG.random.int(-50, 50);
	var currentModifier:Int = -1;
	var stair:Int = 0;

  private function generateChart(songData:SwagSong, ?preload:Bool = false):Void
	{
    if (songData == null) {
      trace("The chart file was null! Canceling generation...");
      return;
    }

    songName = Paths.formatToSongPath(SONG.song).toLowerCase();

		// If this is a preload call, just note it
		if (preload) {
			trace("Starting preload generation for: " + songData.song);
		}
		songSpeed = songData.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = songData.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

    Conductor.bpm = songData.bpm;
		curSong = songData.song;
		notes = new FlxTypedGroup<Note>();
		if (!preload && MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.noteGroup.add(notes);
		curChart = [];

    try
    {
      var eventsChart:SwagSong = Song.getChart('events-${Difficulty.getString().toLowerCase()}', songName);
      if(eventsChart != null)
        for (event in eventsChart.events) //Event Notes
          for (i in 0...event[1].length) {
            if (preload) {
              var subEvent:EventNote = {
                strumTime: event[0] + ClientPrefs.data.noteOffset,
                event: event[1][i][0],
                value1: event[1][i][1],
                value2: event[1][i][2]
              };

              eventNotes.push(subEvent);
              curEvents.push(subEvent);
              eventPushed(subEvent);
            } else makeEventPreload(event, i, preload);
          }
    }
    catch(e:Dynamic) {
      trace('events-${Difficulty.getString().toLowerCase()} DOESN\'T EXSIST FOR SONG $songName!');
    }

    try
    {
      var eventsChart:SwagSong = Song.getChart('events', songName);
      if(eventsChart != null)
        for (event in eventsChart.events) //Event Notes
          for (i in 0...event[1].length) {
            if (preload) {
              var subEvent:EventNote = {
                strumTime: event[0] + ClientPrefs.data.noteOffset,
                event: event[1][i][0],
                value1: event[1][i][1],
                value2: event[1][i][2]
              };

              eventNotes.push(subEvent);
              curEvents.push(subEvent);
              eventPushed(subEvent);
            } else makeEventPreload(event, i, preload);
          }
    }
    catch(e:Dynamic) {
      trace('events DOESN\'T EXSIST FOR SONG $songName!');
    }

		var ghostNotesCaught:Int = 0;
		var AIPlayMap:Array<Array<Float>> = AIPlayer.active ? AIPlayer.GeneratePlayMap(songData, AIPlayer.diff) : null;
    var oldNote:Note = null;
    var sectionsData:Array<SwagSection> = songData.notes;
    var daBpm:Float = Conductor.bpm;

    var sectionLoopCount:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

    if (PlayState.chartingMode || preload)
      chartModifier = "Normal";
    else if (!preload)
      chartModifier = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');

    for (section in sectionsData)
    {
      if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
        daBpm = section.bpm;

      for (i in 0...section.sectionNotes.length)
      {
        final songNotes: Array<Dynamic> = section.sectionNotes[i];
        var spawnTime:Float = songNotes[0];
        var noteColumn:Int = Std.int(songNotes[1]);
        var noteStartColumn:Int = Std.int(songNotes[1] % Note.ammo[songData.mania != null ? songData.mania : 3]);
        var holdLength:Float = songNotes[2];
        var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
        if (Math.isNaN(holdLength)) holdLength = 0.0;

        var gottaHitNote:Bool;
        noteColumn = Std.int(songNotes[1] % Note.ammo[songData.mania != null ? songData.mania : 3]);
        gottaHitNote = (songNotes[1] < (songData.mania != null ? totalColumns : Note.ammo[songData.mania != null ? songData.mania : 3]));

        //if (songData.format.contains("mixtape_v1")) gottaHitNote = section.mustHitSection;

        if (i != 0) {
          // CLEAR ANY POSSIBLE GHOST NOTES
          for (evilNote in allNotes) {
            var matches:Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
            if (matches && Math.abs(spawnTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON) {
              var playfield:PlayField = playfields.members[evilNote.fieldIndex];
              if (evilNote.tail.length > 0)
                for (tail in evilNote.tail)
                {
                  tail.destroy();
                  allNotes.remove(tail);
                  if (playfield != null) playfield.unqueue(tail);
                }
              evilNote.destroy();
              allNotes.remove(evilNote);
              if (playfield != null) playfield.unqueue(evilNote);
              ghostNotesCaught++;
              //continue;
            }
          }
        }

        if (!PlayState.chartingMode) {
          switch (chartModifier)
          {
            case "Random":
              noteColumn = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
            case "RandomBasic":
              var randomDirection:Int;
              do
              {
                randomDirection = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
              }
              while (randomDirection == prevNoteData && mania[gottaHitNote ? 1 : 0] > 1);
              prevNoteData = randomDirection;
              noteColumn = randomDirection;
            case "RandomComplex":
              var thisNoteData = noteColumn;
              if (initialNoteData == -1)
              {
                initialNoteData = noteColumn;
                noteColumn = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
              }
              else
              {
                var newNoteData:Int;
                do
                {
                  newNoteData = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
                }
                while (newNoteData == prevNoteData && mania[gottaHitNote ? 1 : 0] > 1);
                if (thisNoteData == initialNoteData)
                {
                  noteColumn = prevNoteData;
                }
                else
                {
                  noteColumn = newNoteData;
                }
              }
              prevNoteData = noteColumn;
              initialNoteData = thisNoteData;

            // case "Sequential":
            // 	if (prevNoteData == 0) {
            // 		noteColumn = 1;
            // 		direction = 1;
            // 	} else if (prevNoteData == mania[gottaHitNote ? 1 : 0] - 1) {
            // 		noteColumn = mania[gottaHitNote ? 1 : 0] - 2;
            // 		direction = -1;
            // 	} else {
            // 		noteColumn = prevNoteData + direction;
            // 	}
            // 	break;
            case "Mirror": // Broken
              var length = mania[gottaHitNote ? 1 : 0];
              var mirroredIndex:Int;
              var middle = Math.floor(length / 2);
              if (noteColumn < middle)
              {
                mirroredIndex = (middle - noteColumn) + middle - 1;
              }
              else if (noteColumn > middle)
              {
                mirroredIndex = middle - (noteColumn - middle);
              }
              else
              {
                mirroredIndex = noteColumn;
              }
              noteColumn = mirroredIndex;
            case "ReverseMirror":
              var median:Float = (mania[gottaHitNote ? 1 : 0] + 1) / 2;
              if (noteColumn <= median)
              {
                // For values below the median, mirror downwards
                noteColumn = Std.int(median - (median - noteColumn) - 1);
              }
              else
              {
                // For values above the median, mirror upwards
                noteColumn = Std.int(median + (noteColumn - median) + 1);
              }
              noteColumn = Std.int(Math.max(0, Math.min(noteColumn, mania[gottaHitNote ? 1 : 0] - 1)));

            case "Skip":
              var skipStep = 2; // Define the step size for skipping notes.
              var randomLane = Math.random() < 0.5 ? prevNoteData : (prevNoteData + skipStep) % mania[gottaHitNote ? 1 : 0];
              var randomDuration = Math.random() * 30; // Randomize the duration before switching lanes (in notes).
              noteColumn = randomLane;
            case "Flip":
              if (gottaHitNote)
              {
                noteColumn = mania[gottaHitNote ? 1 : 0] - Std.int(songNotes[1] % Note.ammo[mania[gottaHitNote ? 1 : 0]]);
              }
            case "Pain":
              noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[mania[gottaHitNote ? 1 : 0]]);
            case "4K Only":
              //trace("4K Only: " + noteColumn);
              noteColumn = getNumberFromAnimsSmall(noteColumn, 3);
              //trace("Note: " + noteColumn + " mania[gottaHitNote ? 1 : 0]: " + mania[gottaHitNote ? 1 : 0] + " GottaHit: " + gottaHitNote);
            case "mania[gottaHitNote ? 1 : 0]Converter":
              //trace("mania[gottaHitNote ? 1 : 0]Converter: " + noteColumn);
              noteColumn = getNumberFromAnims(noteColumn, mania[gottaHitNote ? 1 : 0]);
              //trace("Note: " + noteColumn + " mania[gottaHitNote ? 1 : 0]: " + mania[gottaHitNote ? 1 : 0] + " GottaHit: " + gottaHitNote);
            case "Stairs":
              noteColumn = stair % Note.ammo[mania[gottaHitNote ? 1 : 0]];
              stair++;
            case "Wave":
              // Sketchie... WHY?!
              var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
              var luigiSex:Int = (ammoFromFortnite * 2 - 2);
              var marioSex:Int = stair++ % luigiSex;
              if (marioSex < ammoFromFortnite)
              {
                noteColumn = marioSex;
              }
              else
              {
                noteColumn = luigiSex - marioSex;
              }
            case "Trills":
              var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
              var luigiSex:Int = (ammoFromFortnite * 2 - 2);
              var marioSex:Int;
              do
              {
                marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
                if (marioSex < ammoFromFortnite)
                {
                  noteColumn = marioSex;
                }
                else
                {
                  noteColumn = luigiSex - marioSex;
                }
              }
              while (noteColumn == prevNoteData && mania[gottaHitNote ? 1 : 0] > 1);
              prevNoteData = noteColumn;
            case "Ew":
              // I hate that I used Sketchie's variables as a base for this... ;-;
              var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
              var luigiSex:Int = (ammoFromFortnite * 2 - 2);
              var marioSex:Int = stair++ % luigiSex;
              var noteIndex:Int = Std.int(marioSex / 2);
              var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
              noteColumn = noteIndex + noteDirection;
              // If the note index is out of range, wrap it around
              if (noteColumn < 0)
              {
                noteColumn = 1;
              }
              else if (noteColumn >= ammoFromFortnite)
              {
                noteColumn = ammoFromFortnite - 2;
              }
            case "Death":
              var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
              var luigiSex:Int = (ammoFromFortnite * 4 - 4);
              var marioSex:Int = stair++ % luigiSex;
              var step:Int = Std.int(luigiSex / 3);

              if (marioSex < ammoFromFortnite)
              {
                noteColumn = marioSex % step;
              }
              else if (marioSex < ammoFromFortnite * 2)
              {
                noteColumn = (marioSex - ammoFromFortnite) % step + step;
              }
              else if (marioSex < ammoFromFortnite * 3)
              {
                noteColumn = (marioSex - ammoFromFortnite * 2) % step + step * 2;
              }
              else
              {
                noteColumn = (marioSex - ammoFromFortnite * 3) % step + step * 3;
              }
            case "What":
              switch (stair % (2 * Note.ammo[mania[gottaHitNote ? 1 : 0]]))
              {
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                  noteColumn = stair % Note.ammo[mania[gottaHitNote ? 1 : 0]];
                default:
                  noteColumn = Note.ammo[mania[gottaHitNote ? 1 : 0]] - 1 - (stair % Note.ammo[mania[gottaHitNote ? 1 : 0]]);
              }
              stair++;
            case "Amalgam":
              {
                var modifierNames:Array<String> = [
                  "Random",
                  "RandomBasic",
                  "RandomComplex",
                  "Flip",
                  "Pain",
                  "Stairs",
                  "Wave",
                  "Huh",
                  "Ew",
                  "What",
                  "Jack Wave",
                  "SpeedRando",
                  "Trills"
                ];

                if (caseExecutionCount <= 0)
                {
                  currentModifier = FlxG.random.int(-1, (modifierNames.length - 1)); // Randomly select a case from 0 to 9
                  caseExecutionCount = FlxG.random.int(1, 51); // Randomly select a number from 1 to 50
                  trace("Active Modifier: " + modifierNames[currentModifier] + ", Notes to edit: " + caseExecutionCount);
                }
                // trace('Notes remaining: ' + caseExecutionCount);
                caseExecutionCount--;
                switch (currentModifier)
                {
                  case 0: // "Random"
                    noteColumn = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
                  case 1: // "RandomBasic"
                    var randomDirection:Int;
                    do
                    {
                      randomDirection = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
                    }
                    while (randomDirection == prevNoteData && mania[gottaHitNote ? 1 : 0] > 1);
                    prevNoteData = randomDirection;
                    noteColumn = randomDirection;
                  case 2: // "RandomComplex"
                    var thisNoteData = noteColumn;
                    if (initialNoteData == -1)
                    {
                      initialNoteData = noteColumn;
                      noteColumn = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
                    }
                    else
                    {
                      var newNoteData:Int;
                      do
                      {
                        newNoteData = FlxG.random.int(0, mania[gottaHitNote ? 1 : 0]);
                      }
                      while (newNoteData == prevNoteData && mania[gottaHitNote ? 1 : 0] > 1);
                      if (thisNoteData == initialNoteData)
                      {
                        noteColumn = prevNoteData;
                      }
                      else
                      {
                        noteColumn = newNoteData;
                      }
                    }
                    prevNoteData = noteColumn;
                    initialNoteData = thisNoteData;
                  case 3: // "Flip"
                    if (gottaHitNote)
                    {
                      noteColumn = mania[gottaHitNote ? 1 : 0] - Std.int(songNotes[1] % Note.ammo[mania[gottaHitNote ? 1 : 0]]);
                    }
                  case 4: // "Pain"
                    noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[mania[gottaHitNote ? 1 : 0]]);
                  case 5: // "Stairs"
                    noteColumn = stair % Note.ammo[mania[gottaHitNote ? 1 : 0]];
                    stair++;
                  case 6: // "Wave"
                    // Sketchie... WHY?!
                    var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
                    var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                    var marioSex:Int = stair++ % luigiSex;
                    if (marioSex < ammoFromFortnite)
                    {
                      noteColumn = marioSex;
                    }
                    else
                    {
                      noteColumn = luigiSex - marioSex;
                    }
                  case 7: // "Huh"
                    var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
                    var luigiSex:Int = (ammoFromFortnite * 4 - 4);
                    var marioSex:Int = stair++ % luigiSex;
                    var step:Int = Std.int(luigiSex / 3);
                    var waveIndex:Int = Std.int(marioSex / step);
                    var waveDirection:Int = waveIndex % 2 == 0 ? 1 : -1;
                    var waveRepeat:Int = Std.int(waveIndex / 2);
                    var repeatStep:Int = marioSex % step;
                    if (repeatStep < waveRepeat)
                    {
                      noteColumn = waveIndex * step + waveDirection * repeatStep;
                    }
                    else
                    {
                      noteColumn = waveIndex * step + waveDirection * (waveRepeat * 2 - repeatStep);
                    }
                    if (noteColumn < 0)
                    {
                      noteColumn = 0;
                    }
                    else if (noteColumn >= ammoFromFortnite)
                    {
                      noteColumn = ammoFromFortnite - 1;
                    }
                  case 8: // "Ew"
                    // I hate that I used Sketchie's variables as a base for this... ;-;
                    var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
                    var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                    var marioSex:Int = stair++ % luigiSex;
                    var noteIndex:Int = Std.int(marioSex / 2);
                    var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
                    noteColumn = noteIndex + noteDirection;
                    // If the note index is out of range, wrap it around
                    if (noteColumn < 0)
                    {
                      noteColumn = 1;
                    }
                    else if (noteColumn >= ammoFromFortnite)
                    {
                      noteColumn = ammoFromFortnite - 2;
                    }
                  case 9: // "What"
                    switch (stair % (2 * Note.ammo[mania[gottaHitNote ? 1 : 0]]))
                    {
                      case 0:
                      case 1:
                      case 2:
                      case 3:
                      case 4:
                        noteColumn = stair % Note.ammo[mania[gottaHitNote ? 1 : 0]];
                      default:
                        noteColumn = Note.ammo[mania[gottaHitNote ? 1 : 0]] - 1 - (stair % Note.ammo[mania[gottaHitNote ? 1 : 0]]);
                    }
                    stair++;
                  case 10: // Jack Wave
                    var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
                    var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                    var marioSex:Int = Std.int((stair++ % (luigiSex * 4)) / 4);
                    if (marioSex < ammoFromFortnite)
                    {
                      noteColumn = marioSex;
                    }
                    else
                    {
                      noteColumn = luigiSex - marioSex;
                    }
                  case 11: // SpeedRando
                    // Handled by SpeedRando Code below!
                  case 12: // Trills
                    var ammoFromFortnite:Int = Note.ammo[mania[gottaHitNote ? 1 : 0]];
                    var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                    var marioSex:Int;
                    do
                    {
                      marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
                      if (marioSex < ammoFromFortnite)
                      {
                        noteColumn = marioSex;
                      }
                      else
                      {
                        noteColumn = luigiSex - marioSex;
                      }
                    }
                    while (noteColumn == prevNoteData && mania[gottaHitNote ? 1 : 0] > 1);
                    prevNoteData = noteColumn;
                  default:
                    // Default case (optional)
                }
              }
          }
        }

        var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
        holdLength = Math.round(songNotes[2] / curStepCrochet) - 1;
        if (allNotes.length > 0)
          oldNote = allNotes[Std.int(allNotes.length - 1)];
        else
          oldNote = null;

        var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);
        swagNote.noteIndex = Std.int(allNotes.length);
        swagNote.formerPress = swagNote.mustPress = gottaHitNote;
        swagNote.visualTime = getNoteInitialTime(swagNote.strumTime);
        swagNote.ID = allNotes.length;

        if (!preload) {
          // UNO Chart Modifier Processing
          if (chartModifier == "UNO") {
            if (unoMechanic == null) {
              unoMechanic = new UnoMechanic();
            }
            unoMechanic.processNote(swagNote, mania[gottaHitNote ? 1 : 0], spawnTime, gottaHitNote);
          }
        }

        swagNote.row = Conductor.secsToRow(spawnTime);
        var rowArray = noteRows[gottaHitNote?0:1];
        if(rowArray[swagNote.row]==null)
          rowArray[swagNote.row]=[];
        rowArray[swagNote.row].push(swagNote);

        if (!swagNote.mustPress)
        {
          if (AIPlayMap != null && AIPlayMap.length != 0 && [sectionsData.indexOf(section)] != null)
          {
            swagNote.AIStrumTime = AIPlayMap[sectionsData.indexOf(section)][section.sectionNotes.indexOf(songNotes)];
            if (Math.abs(swagNote.AIStrumTime) > Conductor.safeZoneOffset)
              swagNote.ignoreNote = swagNote.AIMiss = true;
          }
        }

        var isAlt: Bool = section.altAnim && !gottaHitNote;
        swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
        swagNote.animSuffix = isAlt ? "-alt" : "";
        swagNote.sustainLength = songNotes[2] <= curStepCrochet ? songNotes[2] : (holdLength + 1) * curStepCrochet; // +1 because hold end
        swagNote.noteType = noteType;
        swagNote.ID = allNotes.length;
        swagNote.holdType = swagNote.sustainLength > 0 ? HEAD : TAP;
        swagNote.isParent = swagNote.sustainLength > 0;
        swagNote.scrollFactor.set();
        var setPos:Bool = true;

        if ((swagNote.noteType == null || (swagNote.noteType == '' || swagNote.noteType.length == 0)) && swagNote.mustPress)
        {
          if (FlxG.random.bool(MechanicManager.mechanics['swap_note'].points * 0.16))
          {
            setPos = false;
            swagNote.noteType = 'Swap Note';
            swagNote.copyX = false;
            swagNote.typeOffsetX += 60;
          }
        }

        if (chartModifier == 'Amalgam' && currentModifier == 11)
        {
          swagNote.multSpeed = FlxG.random.float(0.1, 2);
        }

        ////

        if (!preload && MusicBeatState.getState() == PlayState.instance)
          PlayState.instance.callOnScripts("onGeneratedNote", [swagNote, section]);

        var playfield:PlayField = swagNote.field;

        if (playfield == null && playfields.length > 0) {
          if (swagNote.fieldIndex == -1)
            swagNote.fieldIndex = swagNote.mustPress ? 0 : 1;

          if (playfields.members[swagNote.fieldIndex] != null) {
            playfield = playfields.members[swagNote.fieldIndex];
            swagNote.field = playfield;
          }
        }

        if (playfield != null)
        {
          if (!preload && playfield != null) {
            playfield.queue(swagNote); // queues the note to be spawned
          }
          allNotes.push(swagNote); // just for the sake of convenience
        }
        else if (preload) {
          // During preload, still add to allNotes even without playfield
          allNotes.push(swagNote);
          swagNote.fieldIndex = swagNote.mustPress ? 0 : 1; // Set default field index
        }

        if (!preload) {
          // Generate special UNO notes (skip, wrong, +2, +4)
          if (chartModifier == "UNO" && unoMechanic != null) {
            var specialNotes = unoMechanic.generateSpecialNotes(swagNote, mania[swagNote.fieldIndex], allNotes);
            for (specialNote in specialNotes) {
              if (playfield != null) {
                specialNote.field = playfield;
                specialNote.fieldIndex = swagNote.fieldIndex;
                if (!preload) {
                  playfield.queue(specialNote);
                }
                allNotes.push(specialNote);
              }
              else if (preload) {
                // During preload, still add to allNotes even without playfield
                specialNote.fieldIndex = swagNote.fieldIndex;
                allNotes.push(specialNote);
              }
            }
          }
        }

        var spot = 0;
        final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet) -1;
        if (roundSus > 0)
        {
          // Cache properties to avoid repeated property access
          final stepCrochet = Conductor.stepCrochet;
          final parentMustPress = swagNote.mustPress;
          final parentGfNote = swagNote.gfNote;
          final parentExNote = swagNote.exNote;
          final parentAnimSuffix = swagNote.animSuffix;
          final parentNoteType = swagNote.noteType;
          final parentNoteIndex = swagNote.noteIndex;
          final parentMultSpeed = (chartModifier == 'Amalgam' && currentModifier == 11) ? swagNote.multSpeed : 0;
          final parentFieldIndex = swagNote.fieldIndex;
          final parentField = swagNote.field;
          final usePool = ClientPrefs.data.useExperimentalNotePool;

          for (susNote in 0...roundSus)
          {
            oldNote = allNotes[Std.int(allNotes.length - 1)];

            var sustainNote:Note = new Note(spawnTime + (stepCrochet * susNote) + stepCrochet, noteColumn, oldNote, true, false, null);

            // Set properties using cached values
            sustainNote.mustPress = parentMustPress;
            sustainNote.gfNote = parentGfNote;
            sustainNote.exNote = parentExNote;
            sustainNote.animSuffix = parentAnimSuffix;
            sustainNote.noteType = parentNoteType;
            sustainNote.noteIndex = parentNoteIndex;
            if (chartModifier == 'Amalgam' && currentModifier == 11)
            {
              sustainNote.multSpeed = parentMultSpeed;
            }
            if (sustainNote == null || !sustainNote.alive)
              break;
            sustainNote.ID = allNotes.length;
            sustainNote.scrollFactor.set();
            sustainNote.holdType = roundSus > 0 ? PART : END;
            sustainNote.parent = swagNote;
            sustainNote.fieldIndex = parentFieldIndex;
            sustainNote.field = parentField;
            swagNote.tail.push(sustainNote);
            swagNote.unhitTail.push(sustainNote);
            if (!preload && playfield != null) {
              playfield.queue(sustainNote);
            }
            allNotes.push(sustainNote);
            var setPos:Bool = true;
            if (sustainNote.noteType == 'Swap Note') {
              setPos = false;
              sustainNote.typeOffsetX = swagNote.typeOffsetX;
            }
            if (setPos)
            {
              var originalSusPos:Float = sustainNote.x;

              if (sustainNote.formerPress)
              {
                sustainNote.x += FlxG.width * 0.5; // general offset
              }
            }
            else
              sustainNote.copyX = false;

            sustainNote.parent = swagNote;
            swagNote.childs.push(sustainNote);
            sustainNote.spotInLine = spot;
            spot++;
          }
        }

        if(!noteTypes.contains(swagNote.noteType))
          noteTypes.push(swagNote.noteType);

        if (!preload && MusicBeatState.getState() == PlayState.instance) {
          if (PlayState.mechanicsMod != null) {
            var sectionLength = (section.sectionBeats*4);

            var sectionStartTime:Float = (Conductor.stepCrochet * sectionLoopCount) * sectionLength;

            // note placement
            var weightedChances:Array<Null<Float>> = [];
            var getChance:Int->Float = function(i)
            {
              if (weightedChances[i] == null)
              {
                weightedChances[i] = 0;
              }

              return weightedChances[i];
            };

            // [MECHANIC NAME, NOTE TYPE]
            var generatedTypes:Array<Array<Dynamic>> = [
              [
                'hurt_note',
                'Hurt Note',
                Math.min(MechanicManager.mechanics['hurt_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
                  1),
                0.5,
                1
              ],
              [
                'kill_note',
                'Kill Note',
                Math.min(MechanicManager.mechanics['kill_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
                  1),
                0.2,
                0.5
              ],
              [
                'burst_note',
                'Burst Note',
                Math.min(MechanicManager.mechanics['burst_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
                  1),
                0.35,
                0.9
              ],
              [
                'sleep_note',
                'Sleep Note',
                Math.min(MechanicManager.mechanics['sleep_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
                  1),
                0.35,
                0.75
              ],
              [
                'fake_note',
                'Fake Note',
                Math.min((MechanicManager.mechanics['fake_note'].points / 2) * FlxMath.remapToRange(sectionLength, 0, 16, 1,
                  6) / songData.notes.length * 0.2, 1),
                0.5,
                0.9
              ],
              [
                'note_random',
                'No Animation',
                Math.min(MechanicManager.mechanics['note_random'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
                  1),
                0.9,
                1.1
              ]
            ];

            for (j in [false, true])
            {
              for (ii in 0...weightedChances.length)
              {
                weightedChances[ii] = 0;
              }
              var hitSectionMulti:Float = 1;

              if (section.mustHitSection != j)
              {
                hitSectionMulti = 0.2;
              }
              if (section.sectionNotes.length < 8)
                hitSectionMulti = 0.04;

              for (i in 0...16)
              {
                for (jj in 0...generatedTypes.length)
                {
                  var chance:Float = generatedTypes[jj][2] + (getChance(jj) * generatedTypes[jj][4]);
                  if (generatedTypes[jj][0] == 'note_random')
                    chance *= hitSectionMulti;
                  else if (generatedTypes[jj][0] == 'restore_note' && (!j && !bothMode))
                    break;
                  var placeNote:Note = placeNote(chance, generatedTypes[jj][1], [
                    sectionStartTime + (Conductor.stepCrochet * i),
                    FlxG.random.int(0, 3),
                    j,
                    generatedTypes[jj][3]
                  ]);

                  if (placeNote == null)
                  {
                    weightedChances[jj] += FlxG.random.float(0,
                      FlxMath.remapToRange(MechanicManager.mechanics[generatedTypes[jj][0]].points, 0, 20, 0, 2)) * 0.75;
                    continue;
                  }
                  var placePlayfield:PlayField = placeNote.field;

                  if (placePlayfield == null && playfields.length > 0) {
                    if (placeNote.fieldIndex == -1)
                      placeNote.fieldIndex = placeNote.mustPress ? 0 : 1;

                    if (playfields.members[placeNote.fieldIndex] != null) {
                      placePlayfield = playfields.members[placeNote.fieldIndex];
                      placeNote.field = placePlayfield;
                    }
                  }

                  if (placePlayfield != null)
                  {
                    placePlayfield.queue(placeNote); // queues the note to be spawned
                    allNotes.push(placeNote); // just for the sake of convenience
                  }
                  weightedChances[jj] = 0;
                }
              }
            }

            var strumSwapPoints:Int = MechanicManager.mechanics['strum_swap'].points;

            if (FlxG.random.bool(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 8) + getChance(7)))
            {
              PlayState.moveStrumSections[sectionLoopCount] = true;
              weightedChances[7] = 0;
            }
            else
            {
              PlayState.moveStrumSections[sectionLoopCount] = false;
              weightedChances[7] += FlxG.random.float(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 0.4));
            }

            if (archipelago.APInfo.soreThroat) {
              for (j in [false, true])
              {
                var hitSectionMulti:Float = 1;

                if (section.mustHitSection != j)
                {
                  hitSectionMulti = 0.2;
                }
                if (section.sectionNotes.length < 8)
                  hitSectionMulti = 0.04;

                for (i in 0...16)
                {
                  var throatNote:Note = placeNote(50, "Throat Note", [
                    sectionStartTime + (Conductor.stepCrochet * i),
                    FlxG.random.int(0, 3),
                    j,
                    hitSectionMulti
                  ]);

                  if (throatNote == null)
                    continue;

                  var placePlayfield:PlayField = throatNote.field;
                  if (placePlayfield == null && playfields.length > 0) {
                    if (throatNote.fieldIndex == -1) throatNote.fieldIndex = throatNote.mustPress ? 0 : 1;

                    if (playfields.members[throatNote.fieldIndex] != null) {
                      placePlayfield = playfields.members[throatNote.fieldIndex];
                      throatNote.field = placePlayfield;
                    }
                  }

                  if (placePlayfield != null)
                  {
                    placePlayfield.queue(throatNote);
                    allNotes.push(throatNote);
                  }
                }
              }
            }
            sectionLoopCount += 1;
          }

          if (PlayState.mechanicsMod != null) {
            if (MechanicManager.mechanics["note_speed"].points > 0)
            {
              for (note in allNotes)
              {
                if (note.isSustainNote)
                  continue;
                var speedBound:{min:Float, max:Float};
                var points:Float = MechanicManager.mechanics["note_speed"].points;

                speedBound = {min: FlxMath.remapToRange(points, 0, 20, -0, -0.5), max: FlxMath.remapToRange(points, 0, 20, 0, 0.5)};
                note.multSpeed = songSpeed + FlxG.random.float(speedBound.min, speedBound.max);
                for (sus in note.tail)
                {
                  sus.multSpeed = note.multSpeed;
                }
              }
            }
          }
        }
		  }
    }

    trace('["${songData.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
    for (event in songData.events) //Event Notes
      for (i in 0...event[1].length) {
        if (preload) {
          var subEvent:EventNote = {
            strumTime: event[0] + ClientPrefs.data.noteOffset,
            event: event[1][i][0],
            value1: event[1][i][1],
            value2: event[1][i][2]
          };

          eventNotes.push(subEvent);
          curEvents.push(subEvent);
          eventPushed(subEvent);
        } else makeEventPreload(event, i, preload);
      }

    allNotes.sort(sortByTime);

    if (!preload) {
      if (curChart == null || curChart.isNotEmpty())
        curChart = new Array<Note>();

      for (fuck in allNotes) {
        unspawnNotes.push(fuck);
        curChart.push(fuck);
      }

      for (field in playfields.members)
        field.clearStackedNotes();
    }

    // curChart = cast (curChart:objects.NotePool.NoteArray);

    if (preload) {
      var tempSongObj:String = new SongObjectType(songName+Difficulty.getFilePath(), Mods.currentModDirectory).toString();
      if (!chartCache.exists(tempSongObj)) {
        var songObject:SongObject = new SongObject();
        songObject.chart = allNotes;
        songObject.events = eventNotes;
        songObject.noteTypes = noteTypes;
        chartCache.set(tempSongObj, songObject);
      }
      resetChartStuff();
    } else generatedChart = true;
    trace('Finished Generating Notes for ${songData.song}!');
  }

  private function placeNote(chance:Float, noteType:String, attributes:Array<Dynamic>):Note
	{
		if (FlxG.random.bool(chance))
		{
			var dataNote:Note = ClientPrefs.data.useExperimentalNotePool ?
				NotePoolManager.createNote(attributes[0], attributes[1], null, false, false, this) :
				new Note(attributes[0], attributes[1], null, false);
			dataNote.autoGenerated = true;
			dataNote.earlyHitMult = attributes[3];
			dataNote.mustPress = dataNote.formerPress = attributes[2];
			dataNote.noteType = noteType;
			dataNote.scrollSpeed = PlayfieldManager.instance.songSpeed;
			dataNote.scrollFactor.set();

			return dataNote;
		}

		return null;
	}

  public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

  public static function getNumberFromAnimsSmall(note:Int, mania:Int):Int {
		var anims:Array<String> = Note.keysShit.get(mania).get("anims");
		var animMap:Map<String, Int> = ["LEFT" => 0, "DOWN" => 1, "UP" => 2, "RIGHT" => 3];

		if (mania == 0) {
			// Only one key, everything maps to the same key
			return 0;
		} else if (mania == 1) {
			// Two keys: LEFT and RIGHT
			var anim = anims[note % anims.length];
			if (anim == "DOWN" || anim == "LEFT") return 0; // Map to LEFT
			if (anim == "UP" || anim == "RIGHT") return 1;  // Map to RIGHT
		} else if (mania == 2) {
			// Three keys: LEFT, UP, and RIGHT
			var anim = anims[note % anims.length];
			if (anim == "LEFT") return 0;
			if (anim == "DOWN" || anim == "UP") return 1; // Map DOWN and UP to the middle key
			if (anim == "RIGHT") return 2;
		} else if (mania > 3) {
			// Handle cases where mania > 4
			var anim = anims[note % anims.length];
			var matchingIndices = [];
			for (i in 0...anims.length) {
				if (anims[i] == anim) {
					matchingIndices.push(i);
				}
			}
			return matchingIndices.length > 0 ? matchingIndices[Std.int(Math.random() * matchingIndices.length)] : note % mania;
		}

		// Default case for mania <= 4
		var anim = anims[note % anims.length];
		return animMap.exists(anim) ? animMap.get(anim) : note % mania;
	}

	public static inline function getNumberFromAnims(note:Int, mania:Int):Int
  {
    var animMap:Map<String, Int> = new Map<String, Int>();
    animMap.set("LEFT", 0);
    animMap.set("DOWN", 1);
    animMap.set("UP", 2);
    animMap.set("RIGHT", 3);

    var anims:Array<String> = Note.keysShit.get(mania).get("anims");
    var animKeys:Array<String> = [
      for (key in animMap.keys())
        if (key == "LEFT") "RIGHT" else if (key == "RIGHT") "LEFT" else key
    ];

    var result:Int;

    if (mania > 3)
    {
      var anim = animKeys[note];
      var matchingIndices:Array<Int> = [];
      if (note < animKeys.length)
      {
        for (i in 0...anims.length)
        {
          if (anims[i] == anim)
          {
            matchingIndices.push(i);
          }
        }
        if (matchingIndices.length > 0)
        {
          var randomIndex = Std.int(Math.random() * matchingIndices.length);
          result = matchingIndices[randomIndex];
        }
        else
        {
          var randomIndex = Std.int(Math.random() * mania);
          result = randomIndex;
        }
      }
      else
      {
        if (matchingIndices.length > 0)
        {
          var randomIndex = Std.int(Math.random() * matchingIndices.length);
          result = matchingIndices[randomIndex];
        }
        else
        {
          var randomIndex = Std.int(Math.random() * mania);
          result = randomIndex;
        }
      }
    }
    else
    { // mania == 3
      var anim = anims[note];
      if (note < anims.length)
      {
        if (animMap.exists(anim))
        {
          result = animMap.get(anim);
        }
        else
        {
          throw 'No matching animation found';
        }
      }
      else
      {
        result = animMap.get(anim);
      }
    }

    // Ensure result is within bounds
    if (result < 0 || result > mania)
    {
      trace("OOB NOtE: " + note + " MANIA: " + mania + " RESULT: " + result);
      var foundValidAnimation = false;
      while (!foundValidAnimation)
      {
        var randomIndex = Std.int(Math.random() * anims.length);
        var randomAnim = anims[randomIndex];
        if (animMap.exists(randomAnim))
        {
          result = animMap.get(randomAnim);
          foundValidAnimation = true;
        }
      }
    }

    return result;
  }

  public function makeEventPreload(event:Array<Dynamic>, i:Int, preload:Bool = false)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};

		eventNotes.push(subEvent);
    curEvents.push(subEvent);
    if (!preload) {
      eventPushed(subEvent);
      if (MusicBeatState.getState() == PlayState.instance)
        PlayState.instance?.callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
		}
	}

  // Input
  public function addInput() {
    FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

    // Mouse Controls
    for (array in keysArray[18])
		{
			var daArray:Array<Int> = array;
			for (checkKey in daArray)
			{
				// no im not givin you all duplicate inputs, cuz you suck
				if (checkKey == -4)
				{
					FlxG.stage.addEventListener(MouseEvent.CLICK, leftMousePress);
					FlxG.stage.addEventListener(MouseEvent.MOUSE_UP, leftMouseRelease);
				}
				else if (checkKey == -5)
				{
					FlxG.stage.addEventListener(untyped MouseEvent.RIGHT_CLICK, rightMousePress);
					FlxG.stage.addEventListener(untyped MouseEvent.RIGHT_MOUSE_UP, rightMouseRelease);
				}
			}
		}
  }

  public function removeInput() {
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
    FlxG.stage.removeEventListener(MouseEvent.CLICK, leftMousePress);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP, leftMouseRelease);
    FlxG.stage.removeEventListener(untyped MouseEvent.RIGHT_CLICK, rightMousePress);
		FlxG.stage.removeEventListener(untyped MouseEvent.RIGHT_MOUSE_UP, rightMouseRelease);
  }

  private function strumKeyDown(column:Int, player:Int = -1) {
		if (strumsBlocked[column]) return;

    if (MusicBeatState.getState() == PlayState.instance)
      if (PlayState.instance?.callOnScripts("onKeyPress", [column]) == LuaUtils.Function_Stop)
        return;

		var hitNotes:Array<Note> = []; // what could scripts possibly do with this information
		var controlledFields:Array<PlayField> = [];

		if (APEntryState.inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("BF's Mic"))
			return;

		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed)
				continue;

			controlledFields.push(field);
			field.keysPressed[column] = true;

			if (PlayState.instance?.endingSong)
				continue;

			var note:Note = {
        if (MusicBeatState.getState() == PlayState.instance) {
          var ret:Dynamic = PlayState.instance?.callOnScripts("onFieldInput", [field, column, hitNotes]);
          if (ret == LuaUtils.Function_Stop) null;
          else if (ret is Note) ret;
          else field.input(column);
        } else {
          field.input(column);
        }
			}

			if (note == null) {
				var spr:StrumNote = field.strumNotes[column];
				if (spr != null) {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			}else {
				hitNotes.push(note);
			}
		}

		if (hitNotes.length == 0) {
			for (field in controlledFields) {
        if (MusicBeatState.getState() == PlayState.instance) {
          PlayState.instance?.callOnScripts('onGhostTap', [column, field]);

          @:privateAccess
          if (!ClientPrefs.data.ghostTapping)
            PlayState.instance?.noteMissPress(column, field);
        }
			}
		}

		//trace('strum down: $column');
	}

	private function strumKeyUp(column:Int, player:Int = -1) {
		// doesnt matter if THIS is done while paused
		// only worry would be if we implemented Lifts
		// but afaik we arent doing that
		// (though could be interesting to add)

		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed)
				continue;

			field.keysPressed[column] = false;

			if (!field.isHolding[column]) {
				var spr:StrumNote = field.strumNotes[column];
				if (spr != null){
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
		}

    if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('onKeyRelease', [column]);
	}

	public var strumsBlocked:Array<Bool> = [];
	var closestNotes:Array<Note> = [];
	var pressed:Array<FlxKey> = [];
	public var reverseNoteRules:Bool = false;
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (reverseNoteRules) {
			if (pressed.contains(eventKey))
				pressed.remove(eventKey);

			if (key != -1) strumKeyUp(key);
		} else {
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end
			if (ClientPrefs.data.inputSystem == "Native-old") {
				if (!Controls.instance.controllerMode)
				{
					if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
					if (pressed.contains(eventKey)) return;
					pressed.push(eventKey);
					if (key != -1) strumKeyDown(key);
				}
			}
			else {
				if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
				if (pressed.contains(eventKey)) return;
				pressed.push(eventKey);
        if (MusicBeatState.getState() == PlayState.instance)
          if (PlayState.instance?.callOnScripts("onKeyDown", [event]) == LuaUtils.Function_Stop) return;

				if (key > -1)
				{
					var hitNotes:Array<Note> = [];
					var controlledFields:Array<PlayField> = [];

					if (strumsBlocked[key]) return;
          if (MusicBeatState.getState() == PlayState.instance)
            if (PlayState.instance?.callOnScripts("onKeyPress", [key]) == LuaUtils.Function_Stop) return;
					for (field in playfields.members)
					{
						if (!field.autoPlayed && field.isPlayer && field.inControl)
						{
							controlledFields.push(field);
							field.keysPressed[key] = true;
              @:privateAccess
							if (PlayState.instance?.generatedMusic && !PlayState.instance?.endingSong)
							{
								var note:Note = null;
                if (MusicBeatState.getState() == PlayState.instance) {
                  var ret:Dynamic = PlayState.instance?.callOnScripts("onFieldInput", [field, key, hitNotes]);
                  if (ret == LuaUtils.Function_Stop) continue;
                  else if ((ret.objType == NOTE)) note = ret;
                  else note = field.input(key);
                } else note = field.input(key);

								if (note == null)
								{
									var spr:StrumNote = field.strumNotes[key];
									if (spr != null && spr.animation?.curAnim?.name != 'confirm')
									{
										spr.playAnim('pressed');
										spr.resetAnim = 0;
									}
								}
								else hitNotes.push(note);
							}
						}
						if (hitNotes.length == 0 && controlledFields.length > 0)
						{
              if (MusicBeatState.getState() == PlayState.instance) {
                PlayState.instance?.callOnScripts('onGhostTap', [key]);

                @:privateAccess
                if (!ClientPrefs.data.ghostTapping)
                  PlayState.instance?.noteMissPress(key, field);
              }
						}
					}
				}
			}
		}
	}

  private function keyPressed(key:Int, player:Int = -1)
	{
    @:privateAccess
		if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || PlayState.instance?.paused || PlayState.instance?.inCutscene || key < 0 || key >= playerStrums.length || !PlayState.instance?.generatedMusic || PlayState.instance?.endingSong) return;
		if (strumsBlocked[key]) return;

		// Early script callback optimization - only call if scripts exist
		if (PlayState.instance?.hasLuaScripts || PlayState.instance?.hasHScripts) {
      if (MusicBeatState.getState() == PlayState.instance) {
        var ret:Dynamic = PlayState.instance?.callOnScripts('onKeyPressPre', [key]);
        if(ret == LuaUtils.Function_Stop) return;
      }
		}

		// Store original conductor position ONCE
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var hitNotes:Array<Note> = [];
		var controlledFields:Array<PlayField> = [];

		// Pre-filter controlled fields to avoid repeated checks
		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed)
				continue;
			controlledFields.push(field);
		}

		// Process all controlled fields
		for (field in controlledFields) {
			field.keysPressed[key] = true;

			if (PlayState.instance?.endingSong) continue;

			var note:Note = null;

			// Optimize script callback - only call if scripts exist and return early if stopped
			if (PlayState.instance?.hasLuaScripts || PlayState.instance?.hasHScripts) {
        if (MusicBeatState.getState() == PlayState.instance) {
          var ret:Dynamic = PlayState.instance?.callOnScripts("onFieldInput", [field, key, hitNotes]);
          if (ret == LuaUtils.Function_Stop) {
            note = null;
          } else if (ret is Note) {
            note = ret;
          } else {
            note = field.input(key);
          }
        } else note = field.input(key);
			} else {
				note = field.input(key);
			}

			if (note == null) {
				var spr:StrumNote = field.strumNotes[key];
				if (spr != null) {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			} else {
				hitNotes.push(note);
			}
		}

		// Handle ghost tapping
		if (hitNotes.length == 0) {
			for (field in controlledFields) {
				if (PlayState.instance?.hasLuaScripts || PlayState.instance?.hasHScripts) {
          if (MusicBeatState.getState() == PlayState.instance)
            PlayState.instance?.callOnScripts('onGhostTap', [key, field]);
				}

        @:privateAccess
        if (MusicBeatState.getState() == PlayState.instance)
          if (!ClientPrefs.data.ghostTapping)
            PlayState.instance?.noteMissPress(key, field);
			}
		}

		// Optimize keysPressed tracking with Map
		keysPressedSet[key] = true;
		if(!keysPressed.contains(key)) keysPressed.push(key);

		// Restore conductor position ONCE
		Conductor.songPosition = lastTime;

		// Final script callback - only if scripts exist
		if (PlayState.instance?.hasLuaScripts || PlayState.instance?.hasHScripts) {
      if (MusicBeatState.getState() == PlayState.instance)
        PlayState.instance?.callOnScripts('onKeyPress', [key]);
		}
	}

  // very innovative?
	private function leftMousePress(event:MouseEvent):Void
	{
		onMousePress(-4);
	}

	private function rightMousePress(event:MouseEvent):Void
	{
		onMousePress(-5);
	}

	private function leftMouseRelease(event:MouseEvent):Void
	{
		onMouseRelease(-4);
	}

	private function rightMouseRelease(event:MouseEvent):Void
	{
		onMouseRelease(-5);
	}

	private function onMousePress(key:Int):Void {
		var keyDirection:Int = getMouseFromEvent(key);

		if (reverseNoteRules) {
			if (keyDirection != -1) strumKeyUp(keyDirection);
		} else {
			if (ClientPrefs.data.inputSystem == "Native-old") {
				if (!Controls.instance.controllerMode)
				{
					if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
					if (keyDirection != -1) strumKeyDown(keyDirection);
				}
			}
			else {
				if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
        if (MusicBeatState.getState() == PlayState.instance)
          if (PlayState.instance?.callOnScripts("onKeyDown", [keyDirection]) == LuaUtils.Function_Stop) return;

				if (keyDirection > -1)
				{
					var hitNotes:Array<Note> = [];
					var controlledFields:Array<PlayField> = [];

					if (strumsBlocked[keyDirection]) return;
          if (MusicBeatState.getState() == PlayState.instance)
            if (PlayState.instance?.callOnScripts("onKeyPress", [keyDirection]) == LuaUtils.Function_Stop) return;
					for (field in playfields)
					{
						if (!field.autoPlayed && field.isPlayer && field.inControl)
						{
							controlledFields.push(field);
							field.keysPressed[keyDirection] = true;
              @:privateAccess
							if (PlayState.instance?.generatedMusic && !PlayState.instance?.endingSong)
							{
								var note:Note = null;
                if (MusicBeatState.getState() == PlayState.instance) {
                  var ret:Dynamic = PlayState.instance?.callOnScripts("onFieldInput", [field, keyDirection, hitNotes]);
                  if (ret == LuaUtils.Function_Stop) continue;
                  else if ((ret.objType == NOTE)) note = ret;
                  else note = field.input(key);
                } else note = field.input(key);

								if (note == null)
								{
									var spr:StrumNote = field.strumNotes[keyDirection];
									if (spr != null && spr.animation.curAnim.name != 'confirm')
									{
										spr.playAnim('pressed');
										spr.resetAnim = 0;
									}
								}
								else hitNotes.push(note);
							}
						}
						if (hitNotes.length == 0 && controlledFields.length > 0)
						{
              if (MusicBeatState.getState() == PlayState.instance) {
                PlayState.instance?.callOnScripts('onGhostTap', [keyDirection]);

                @:privateAccess
                if (!ClientPrefs.data.ghostTapping)
                  PlayState.instance?.noteMissPress(keyDirection, field);
              }
						}
					}
				}
			}
		}
	}

	private function onMouseRelease(key:Int):Void
	{
		var direction:Int = getMouseFromEvent(key);
		if (reverseNoteRules) {
			if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
			if (MusicBeatState.getState() == PlayState.instance)
        if (PlayState.instance?.callOnScripts("onKeyDown", [direction]) == LuaUtils.Function_Stop) return;

			if (direction > -1)
			{
				var hitNotes:Array<Note> = [];
				var controlledFields:Array<PlayField> = [];

				if (strumsBlocked[direction]) return;
				if (MusicBeatState.getState() == PlayState.instance)
          if (PlayState.instance?.callOnScripts("onKeyPress", [direction]) == LuaUtils.Function_Stop) return;
				for (field in playfields.members)
				{
					if (!field.autoPlayed && field.isPlayer && field.inControl)
					{
						controlledFields.push(field);
						field.keysPressed[direction] = true;
            @:privateAccess
						if (PlayState.instance?.generatedMusic && !PlayState.instance?.endingSong)
						{
							var note:Note = null;
              if (MusicBeatState.getState() == PlayState.instance) {
                var ret:Dynamic = PlayState.instance?.callOnScripts("onFieldInput", [field, direction, hitNotes]);
                if (ret == LuaUtils.Function_Stop) continue;
                else if ((ret.objType == NOTE)) note = ret;
                else note = field.input(key);
              } else note = field.input(key);

							if (note == null)
							{
								var spr:StrumNote = field.strumNotes[direction];
								if (spr != null && spr.animation.curAnim.name != 'confirm')
								{
									spr.playAnim('pressed');
									spr.resetAnim = 0;
								}
							}
							else hitNotes.push(note);
						}
					}
					if (hitNotes.length == 0 && controlledFields.length > 0)
					{
            if (MusicBeatState.getState() == PlayState.instance) {
              PlayState.instance?.callOnScripts('onGhostTap', [direction]);

              @:privateAccess
              if (!ClientPrefs.data.ghostTapping)
                PlayState.instance?.noteMissPress(direction, field);
            }
					}
				}
			}
		} else {
			if (direction != -1) strumKeyUp(direction);
		}
		// trace('released: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//if(!controls.controllerMode && key > -1) keyReleased(key);
		if (reverseNoteRules) {
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end
			if (ClientPrefs.data.inputSystem == "Native-old") {
				if (!Controls.instance.controllerMode)
				{
					if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
					if (pressed.contains(eventKey)) return;
					pressed.push(eventKey);
					if (key != -1) strumKeyDown(key);
				}
			}
			else {
				if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
				if (pressed.contains(eventKey)) return;
				pressed.push(eventKey);
        if (MusicBeatState.getState() == PlayState.instance)
          if (PlayState.instance?.callOnScripts("onKeyDown", [event]) == LuaUtils.Function_Stop) return;

				if (key > -1)
				{
					var hitNotes:Array<Note> = [];
					var controlledFields:Array<PlayField> = [];

					if (strumsBlocked[key]) return;
          if (MusicBeatState.getState() == PlayState.instance)
            if (PlayState.instance?.callOnScripts("onKeyPress", [key]) == LuaUtils.Function_Stop) return;
					for (field in playfields.members)
					{
						if (!field.autoPlayed && field.isPlayer && field.inControl)
						{
							controlledFields.push(field);
							field.keysPressed[key] = true;
              @:privateAccess
							if (PlayState.instance?.generatedMusic && !PlayState.instance?.endingSong)
							{
								var note:Note = null;
                if (MusicBeatState.getState() == PlayState.instance) {
                  var ret:Dynamic = PlayState.instance?.callOnScripts("onFieldInput", [field, key, hitNotes]);
                  if (ret == LuaUtils.Function_Stop) continue;
                  else if ((ret.objType == NOTE)) note = ret;
                  else note = field.input(key);
                } else note = field.input(key);

								if (note == null)
								{
									var spr:StrumNote = field.strumNotes[key];
									if (spr != null && spr.animation.curAnim.name != 'confirm')
									{
										spr.playAnim('pressed');
										spr.resetAnim = 0;
									}
								}
								else hitNotes.push(note);
							}
						}
						if (hitNotes.length == 0 && controlledFields.length > 0)
						{
              if (MusicBeatState.getState() == PlayState.instance) {
                PlayState.instance?.callOnScripts('onGhostTap', [key]);

                @:privateAccess
                if (!ClientPrefs.data.ghostTapping)
                  PlayState.instance?.noteMissPress(key, field);
              }
						}
					}
				}
			}
		} else {
			if (pressed.contains(eventKey))
				pressed.remove(eventKey);

			if (key != -1) strumKeyUp(key);
		}
	}

	private function keyReleased(key:Int, ?player:Int = -1)
	{
		if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || !PlayState.instance?.startedCountdown || PlayState.instance?.paused || key < 0 || key >= playerStrums.length) return;

    if (MusicBeatState.getState() == PlayState.instance) {
      var ret:Dynamic = PlayState.instance?.callOnScripts('onKeyReleasePre', [key]);
  		if(ret == LuaUtils.Function_Stop) return;
    }

		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed)
				continue;

			field.keysPressed[key] = false;

			if (!field.isHolding[key]) {
				var spr:StrumNote = field.strumNotes[key];
				if (spr != null){
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
		}
    if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('onKeyRelease', [key]);
	}

  // TODO: Find a better way to do this so that Both Play and Opponent Mode can be accounted for
	public static function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
			for (i in 0...keysArray[mania[instance.playerField?.modNumber]].length)
				for (j in 0...keysArray[mania[instance.playerField?.modNumber]][i].length)
					if (key == keysArray[mania[instance.playerField?.modNumber]][i][j])
						return i;
		return -1;
	}

	public static function getMouseFromEvent(pressed:Int):Int
	{
		if (pressed != -1)
			for (i in 0...keysArray[18].length)
				for (j in 0...keysArray[18][i].length)
					if (pressed == keysArray[18][i][j])
						return i;
		return -1;
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(Controls.instance, controlArray[i] + suffix);
		}
		return ret;
	}

	// Hold notes
	// This is for the old (new) input
	public static var pressedGameplayKeys:Array<Bool> = [];

	// Cache the parsed arrays to avoid recreating them every frame
	private static var _cachedHoldArray:Array<Bool> = [];
	private static var _cachedPressArray:Array<Bool> = [];
	private static var _cachedReleaseArray:Array<Bool> = [];

	private function keysCheck():Void
	{
		if (ClientPrefs.data.inputSystem == 'Native-old') {
			// Reuse arrays instead of creating new ones
			var holdArray = _cachedHoldArray;
			var pressArray = _cachedPressArray;
			var releaseArray = _cachedReleaseArray;

			// Clear and resize arrays efficiently
			holdArray.splice(0, holdArray.length);
			pressArray.splice(0, pressArray.length);
			releaseArray.splice(0, releaseArray.length);

			var keyArrayLength = keysArray[mania[1]].length;
			holdArray.resize(keyArrayLength);
			pressArray.resize(keyArrayLength);
			releaseArray.resize(keyArrayLength);

			// Use direct indexing instead of push
			for (i in 0...keyArrayLength) {
				var key = keysArray[mania[1]][i];
				holdArray[i] = Controls.instance.pressed(key);
				pressArray[i] = Controls.instance.justPressed(key);
				releaseArray[i] = Controls.instance.justReleased(key);
			}

			// Optimize controller input handling
			if(Controls.instance.controllerMode) {
				for (i in 0...pressArray.length) {
					if(pressArray[i] && strumsBlocked[i] != true) {
						keyPressed(i);
					}
				}
			}

			// Optimize hold checking
      if (MusicBeatState.getState() == PlayState.instance) {
        @:privateAccess
        if (PlayState.instance?.startedCountdown && !PlayState.instance?.inCutscene && PlayState.instance?.generatedMusic) {
          var hasHoldInput = false;
          for (hold in holdArray) {
            if (hold) {
              hasHoldInput = true;
              break;
            }
          }

          if (!hasHoldInput && !PlayState.instance?.endingSong) {
            PlayState.instance.playerDance();
          }
          #if ACHIEVEMENTS_ALLOWED
          else if (hasHoldInput) {
            PlayState.instance.checkForAchievement(['oversinging']);
          }
          #end
        }
      }

			// Optimize release handling
			if((Controls.instance.controllerMode || strumsBlocked.contains(true))) {
				for (i in 0...releaseArray.length) {
					if(releaseArray[i] || strumsBlocked[i] == true) {
						keyReleased(i);
					}
				}
			}
		} else {
			// HOLDING
			var parsedHoldArray:Array<Bool> = parseKeys();
			pressedGameplayKeys = parsedHoldArray;
			// FlxG.watch.addQuick('asdfa', upP);
      if (MusicBeatState.getState() == PlayState.instance) {
        @:privateAccess
        if (PlayState.instance?.startedCountdown && PlayState.instance?.generatedMusic)
        {
          // rewritten inputs???
          notes.forEachAlive(function(daNote:Note)
          {
            // hold note functions
            if (parsedHoldArray.contains(true) && !PlayState.instance?.endingSong)
            {
              #if ACHIEVEMENTS_ALLOWED
              PlayState.instance.checkForAchievement(['oversinging']);
              #end
            }
          });


          if (PlayState.instance.boyfriend != null && PlayState.instance.boyfriend.holdTimer > MegaManager.conductor.stepLengthMs * 0.001 * PlayState.instance.boyfriend.singDuration
            && PlayState.instance.boyfriend.animation.curAnim.name.startsWith('sing')
            && !PlayState.instance.boyfriend.animation.curAnim.name.endsWith('miss'))
            PlayState.instance.boyfriend.dance();

          if (PlayState.instance.bf2 != null && PlayState.instance.bf2.holdTimer > MegaManager.conductor.stepLengthMs * 0.001 * PlayState.instance.bf2.singDuration
            && PlayState.instance.bf2.animation.curAnim.name.startsWith('sing')
            && !PlayState.instance.bf2.animation.curAnim.name.endsWith('miss'))
            PlayState.instance.bf2.dance();
        }

				if (strumsBlocked.contains(true))
				{
					var parsedArray:Array<Bool> = parseKeys('_R');
					if (parsedArray.contains(true))
					{
						for (i in 0...parsedArray.length)
						{
							if (parsedArray[i] || strumsBlocked[i] == true)
								onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[mania[1]][i][0]));
						}
					}
				}
			}
		}
	}

  //General
  public function resetFields() {
    allNotes = unspawnNotes = curChart = [];
    for (field in playfields.members) {
      if (field != null) {
        field.destroy();
        field = null;
      }
    }
    playfields.clear();
    playfields = new FlxTypedGroup<PlayField>();

    // Clear strum note references
		if (playerStrums != null) {
			playerStrums.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			playerStrums.clear();
		}

		if (opponentStrums != null) {
			opponentStrums.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			opponentStrums.clear();
		}

		if (strumLineNotes != null) {
      strumLineNotes.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			strumLineNotes.clear();
		}

    // Clear event and callback references
		if (eventNotes != null) {
			eventNotes.splice(0, eventNotes.length);
		}

		if (curEvents != null) {
			curEvents.splice(0, curEvents.length);
		}

    // Clear input optimization variables
		if (keysPressedSet != null) {
			keysPressedSet.clear();
		}
		_cachedHoldArray = [];
		_cachedPressArray = [];
		_cachedReleaseArray = [];
    _cachedStrumPositions = [];
    _cachedNotePositions = [];

    speedChanges = [];
    speedChanges.push({
			position: -6000 * 0.45,
			startTime: -6000,
			speed: 1,
			#if EASED_SVs
			startSpeed: 1,
			#end
		});
    #if EASED_SVs
		resetSVDeltas();
		#end
    speedChanges.sort(svSort);
    mania = [3, 3];
    generatedChart = false;
    curSong = "";
    songSpeed = 1;
    songSpeedType = "multiplicative";
    noteRows = [[],[]];
    freezeNotes = false;
    localFreezeNotes = false;
    modManager = null;

    for (nField in notefields.members) {
      if (nField != null) {
        nField.destroy();
        nField = null;
      }
    }
    notefields = new NotefieldRenderer();

    for (pField in playfields) {
      if (pField != null) {
        pField.destroy();
        pField = null;
      }
    }
    playfields.clear();

    if (playerField != null) {
      playerField.destroy();
    }

    if (dadField != null) {
      dadField.destroy();
    }
    skipArrowStartTween = false;

    if (fmManager != null) {
      fmManager.destroy();
      fmManager = null;
    }

    manualInputChecks = false;
  }

  public function resetChartStuff() { //Specifically for preload stuff
    allNotes = unspawnNotes = curChart = [];
    // Clear event and callback references
		if (eventNotes != null) {
			eventNotes.splice(0, eventNotes.length);
		}

		if (curEvents != null) {
			curEvents.splice(0, curEvents.length);
		}

    speedChanges = [];
    speedChanges.push({
			position: -6000 * 0.45,
			startTime: -6000,
			speed: 1,
			#if EASED_SVs
			startSpeed: 1,
			#end
		});
    #if EASED_SVs
		resetSVDeltas();
		#end
    speedChanges.sort(svSort);
    mania = [3, 3];
    noteTypes = [];
    eventsPushed = [];
    generatedChart = false;
    curSong = "";
    songName = "";
    songSpeed = 1;
    songSpeedType = "multiplicative";
    noteRows = [[],[]];
  }

  function svSort(Obj1:SpeedEvent, Obj2:SpeedEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.startTime, Obj2.startTime);
	}

  public function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};

		eventNotes.push(subEvent);
		curEvents.push(subEvent);
		eventPushed(subEvent);
    if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

  // called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		if (eventsPushed != null) {
			eventPushedUnique(event);
			if(eventsPushed.contains(event.event)) {
				return;
			}

      @:privateAccess
			if (MusicBeatState.getState() == PlayState.instance)
        PlayState.instance?.stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
			eventsPushed.push(event.event);
		}
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		if (event.value1 == null) event.value1 = '';
		if (event.value2 == null) event.value2 = '';
		switch(event.event) {
			case 'Change Scroll Speed': // Negative duration means using the event time as the tween finish time
				var duration = Std.parseFloat(event.value2);
				if (!Math.isNaN(duration) && duration < 0.0){
					event.strumTime -= duration * 1000;
					event.value2 = Std.string(-duration);
				}

			case 'Mult SV' | 'Constant SV':
				var speed:Float = 1;
				if(event.event == 'Constant SV'){
					var b = Std.parseFloat(event.value1);
					speed = Math.isNaN(b) ? 1 : (b / songSpeed);
				}else{
					speed = Std.parseFloat(event.value1);
					if (Math.isNaN(speed)) speed = 1;
				}
				#if EASED_SVs
				var endTime:Null<Float> = null;
				var easeFunc:EaseFunction = FlxEase.linear;

				var tweenOptions = event.value2.split("/");
				if(tweenOptions.length >= 1){
					easeFunc = FlxEase.linear;
					var parsed:Float = Std.parseFloat(tweenOptions[0]);
					if(!Math.isNaN(parsed))
						endTime = event.strumTime + (parsed * 1000);

					if(tweenOptions.length > 1){
						var f:EaseFunction = LuaUtils.getTweenEaseByString(tweenOptions[1]);
						if(f != null)
							easeFunc = f;
					}
				}

				var lastChange:SpeedEvent = speedChanges[speedChanges.length - 1];
				speedChanges.push({
					position: getTimeFromSV(event.strumTime, lastChange),
					startTime: event.strumTime,
					endTime: endTime,
					easeFunc: easeFunc,
					startSpeed: lastChange.startSpeed,
					speed: speed
				});
				#else
				var lastChange:SpeedEvent = speedChanges[speedChanges.length - 1];
				speedChanges.push({
					position: getTimeFromSV(event.strumTime, lastChange),
					startTime: event.strumTime,
					speed: speed
				});
				#end

			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					case 'dad2' | 'opponent2':
						charType = 3;
					case 'bf2' | 'boyfriend2':
						charType = 4;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				if (MusicBeatState.getState() == PlayState.instance)
          PlayState.instance?.addCharacterToList(newCharacter, charType);
        else
          CharacterManager.instance.preloadCharacter(newCharacter, true, BF, BF);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound

			case 'False Timer':
        if (MusicBeatState.getState() == PlayState.instance) {
          if (PlayState.instance?.timerExtensions == null)
            PlayState.instance.timerExtensions = new Array();

          PlayState.instance?.timerExtensions.push(event.strumTime);
          PlayState.instance.maskedSongLength = PlayState.instance?.timerExtensions[0];
        }
		}
    @:privateAccess
		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
    if (MusicBeatState.getState() == PlayState.instance) {
      var returnedValue:Null<Float> = PlayState.instance.callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
      if(returnedValue != null && returnedValue != 0) {
        return returnedValue;
      }
    }

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

  public function triggerEarlyEvents() {
    if(eventNotes.length > 0)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}
  }

  public function update(elapsed:Float) {
    updateVisualPosition();
		modManager.update(elapsed, MegaManager.conductor.currentBeatTime, MegaManager.conductor.currentStepTime);
    if (!manualInputChecks) keysCheck();
  }
}

@:structInit
class SpeedEvent
{
	public var position:Float; // the y position where the change happens (modManager.getVisPos(songTime))
	public var startTime:Float; // the song position (conductor.songTime) where the change starts
	#if EASED_SVs
	public var startSpeed:Float; // the previous event's speed
	public var endTime:Null<Float> = null; // the song position (conductor.songTime) when the change ends
	public var easeFunc:EaseFunction = FlxEase.linear;
	#end
	public var speed:Float; // speed mult after the change
}

@:structInit
class SongObjectType {
	public var songName:String;
	public var folder:String;

  public function new (?songName:String, ?folder:String) {
    this.songName = (songName!=null ? songName : "");
    this.folder = (folder!=null ? folder : "");
  }

  public inline function toString():String {
    return '${this.songName}(${(this.folder.length<=0?"base":this.folder)})';
  }
}

@:structInit
class SongObject
{
  public var chart:Array<Note>;
  public var events:Array<EventNote>;
  public var noteTypes:Array<String>;
  public function new () {}

  public inline function copyChart() {
    return this.chart;
  }

  public inline function copyEvents() {
    return this.events;
  }

  public inline function toString():String {
    return 'Chart Info: Note Count(${this.chart.length}) Event Count(${this.events.length}) NoteTypes Count(${this.noteTypes.length})';
  }
}
