package managers;

class PlayfieldManager {
  public static var instance:PlayfieldManager;
  public static var SONG:SwagSong = null;
  public static var mania:Array<Int> = [3, 3];

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
  public static var curChart:Array<Note> = [];
  public static var chartCache:Map<{songName:String, modName:String}, SongObject> = new Map<{songName:String, modName:String}, SongObject>();

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

		setOnScripts('botPlay', value);

		/// oughhh
		for (playfield in playfields.members){
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled || ClientPrefs.getGameplaySetting('showcase', false);
		}

		return value;
	}

	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";

  //Input
  private static var keysPressedSet:Map<Int, Bool> = new Map();
  public static var keysArray:Array<Array<Dynamic>>;
	private var controlArray:Array<String>;

  // Cache for expensive operations
	private var _cachedStrumPositions:Array<Float> = [];
	private var _cachedNotePositions:Array<Float> = [];

  // Misc.
  var noteRows:Array<Array<Array<Note>>> = [[],[]];
  public var ghostsAllowed:Bool = ClientPrefs.data.doubleGhosts;
  var oppDifficulty:String = 'Average FNF Player'; // Mix-Up things. You wouldn't get it.
  public var freezeNotes:Bool = false;
	public var localFreezeNotes:Bool = false;

  // Gameplay Modifiers
  public var chartModifier:String = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');
	public var convertMania:Int = ClientPrefs.getGameplaySetting('convertMania', 3);
  public var opponentmode:Bool = ClientPrefs.getGameplaySetting('opponentplay', false);
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
	var speedChanges:Array<SpeedEvent> = [];

  // Skydecay Engine (our good friends)
	public var noteManager:NoteManager;

  // Because this would be really funny
  public var fmManager:Manager;

  public function new() {
    instance = this;
    mania = [3, 3];
    SONG = null;
    noteManager = new NoteManager();
    if (keysArray == null)
			keysArray = backend.Keybinds.fill();
    controlArray = ['NOTE_LEFT', 'NOTE_DOWN', 'NOTE_UP', 'NOTE_RIGHT'];
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

  public function changeMania(newValue:Int, field:Playfield = null, skipStrumFadeOut:Bool = false)
	{
		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('preChangeMania', [mania, newValue, skipStrumFadeOut]);

    var daOldMania = mania;
		mania = newValue;

		if (field != null) field.strumNotes = [];

    if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('onChangeMania', [mania, daOldMania]);


		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.setOnScripts('mania', mania);

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

		field.keyCount = Note.ammo[mania];
		field.generateStrums();

		if (MusicBeatState.getState() == PlayState.instance) {
      PlayState.instance?.callOnScripts('postReceptorGeneration'); // deprecated
  		PlayState.instance?.callOnScripts('onReceptorGenerationPost');
	  	PlayState.instance?.callOnScripts('onChangeMania', [mania, newValue, skipStrumFadeOut]);
    }

		for (field in playfields.members)
			field.fadeIn(skipStrumFadeOut); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode

		singAnimations = Note.keysShit.get(mania).get('singAnims');

		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.callOnScripts('postChangeMania', [mania, newValue, skipStrumFadeOut]);
	}

  /// Playfields


  /// Chart Loading
  var genChartInBG:ASync<Void -> String> = generateChart;
  public function loadChart(songName:String, folder:String, ?preload:Bool = false, ?loadDirectly:Bool = true) {
    if (chartCache.exists(songName)) {
      allNotes = chartCache.get(songName).copy();
      unspawnNotes = curChart = allNotes;
  		noteQueueCheck();
    } else {
      var ss:SwagSong = Song.getChart(songName, folder);
      if (loadDirectly)
        generateChart(ss, preload);
      else
        cast genChartInBG(ss, preload);
    }
  }

  var noteQueueCheck:ASync<Void -> String> = addNotesToQueue;
  function addNotesToQueue():String {
    for (note in allNotes) {
      if (playerField != null)
        if (note.mustPress)
          playerField.queue(note);

      if (dadField != null)
        if (!note.mustPress)
          dadField.queue(note);
    }
    return "Notes Queued";
  }

  private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns:Int = Note.ammo[SONG?.mania != null ? SONG?.mania : 3];
	var prevNoteData:Int = -1;
	var initialNoteData:Int = -1;
	var caseExecutionCount:Int = FlxG.random.int(-50, 50);
	var currentModifier:Int = -1;
	var stair:Int = 0;

  public function generateChart(songData:SwagSong = null, ?preload:Bool = false):Void
	{
    if (songData == null) {
      trace("The chart file was null! Canceling generation...");
      return;
    }

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
      noteGroup.add(notes);
		curChart = [];

    if (!preload) {
      try
      {
        var eventsChart:SwagSong = Song.getChart('events-${Difficulty.getString().toLowerCase()}', songName);
        if(eventsChart != null)
          for (event in eventsChart.events) //Event Notes
            for (i in 0...event[1].length)
              makeEventPreload(event, i, preload);
      }
      catch(e:Dynamic) {
        try
        {
          var eventsChart:SwagSong = Song.getChart('events', songName);
          if(eventsChart != null)
            for (event in eventsChart.events) //Event Notes
              for (i in 0...event[1].length)
                makeEventPreload(event, i, preload);
        }
        catch(e:Dynamic) {}
      }
    }

		var ghostNotesCaught:Int = 0;
		var AIPlayMap:Array<Array<Float>> = AIPlayer.active ? AIPlayer.GeneratePlayMap(songData, AIPlayer.diff) : null;
    var oldNote:Note = null;
    var sectionsData:Array<SwagSection> = songData.notes;
    var daBpm:Float = Conductor.bpm;

    var sectionLoopCount:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

    if (chartingMode)
      chartModifier = "Normal";
    else if (preload)
      chartModifier = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');

    if (preload) {
      var convertMania = ClientPrefs.getGameplaySetting('convertMania', 3);
      if (mania > Note.maxMania)
        mania = Note.defaultMania;
      else if (chartModifier == "4K Only")
        mania = 3;
      else if (chartModifier == "ManiaConverter")
        mania = convertMania;
      else if (songData.mania != null)
        if (songData.mania >= 3) //Make sure it's even there
          mania = songData.mania;
        else {
          mania = switch (songData.mania) { //Convert it to make sure the older versions still work
            case 0: 3;
            case 1: 4;
            default: songData.mania;
          }
        }
      else mania = 3;

      trace("Mania set: " + mania);
    }

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

        if (!chartingMode) {
          switch (chartModifier)
          {
            case "Random":
              noteColumn = FlxG.random.int(0, mania);
            case "RandomBasic":
              var randomDirection:Int;
              do
              {
                randomDirection = FlxG.random.int(0, mania);
              }
              while (randomDirection == prevNoteData && mania > 1);
              prevNoteData = randomDirection;
              noteColumn = randomDirection;
            case "RandomComplex":
              var thisNoteData = noteColumn;
              if (initialNoteData == -1)
              {
                initialNoteData = noteColumn;
                noteColumn = FlxG.random.int(0, mania);
              }
              else
              {
                var newNoteData:Int;
                do
                {
                  newNoteData = FlxG.random.int(0, mania);
                }
                while (newNoteData == prevNoteData && mania > 1);
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
            // 	} else if (prevNoteData == mania - 1) {
            // 		noteColumn = mania - 2;
            // 		direction = -1;
            // 	} else {
            // 		noteColumn = prevNoteData + direction;
            // 	}
            // 	break;
            case "Mirror": // Broken
              var length = mania;
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
              var median:Float = (mania + 1) / 2;
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
              noteColumn = Std.int(Math.max(0, Math.min(noteColumn, mania - 1)));

            case "Skip":
              var skipStep = 2; // Define the step size for skipping notes.
              var randomLane = Math.random() < 0.5 ? prevNoteData : (prevNoteData + skipStep) % mania;
              var randomDuration = Math.random() * 30; // Randomize the duration before switching lanes (in notes).
              noteColumn = randomLane;
            case "Flip":
              if (gottaHitNote)
              {
                noteColumn = mania - Std.int(songNotes[1] % Note.ammo[mania]);
              }
            case "Pain":
              noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[mania]);
            case "4K Only":
              //trace("4K Only: " + noteColumn);
              noteColumn = getNumberFromAnimsSmall(noteColumn, 3);
              //trace("Note: " + noteColumn + " Mania: " + mania + " GottaHit: " + gottaHitNote);
            case "ManiaConverter":
              //trace("ManiaConverter: " + noteColumn);
              noteColumn = getNumberFromAnims(noteColumn, mania);
              //trace("Note: " + noteColumn + " Mania: " + mania + " GottaHit: " + gottaHitNote);
            case "Stairs":
              noteColumn = stair % Note.ammo[mania];
              stair++;
            case "Wave":
              // Sketchie... WHY?!
              var ammoFromFortnite:Int = Note.ammo[mania];
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
              var ammoFromFortnite:Int = Note.ammo[mania];
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
              while (noteColumn == prevNoteData && mania > 1);
              prevNoteData = noteColumn;
            case "Ew":
              // I hate that I used Sketchie's variables as a base for this... ;-;
              var ammoFromFortnite:Int = Note.ammo[mania];
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
              var ammoFromFortnite:Int = Note.ammo[mania];
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
              switch (stair % (2 * Note.ammo[mania]))
              {
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                  noteColumn = stair % Note.ammo[mania];
                default:
                  noteColumn = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
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
                    noteColumn = FlxG.random.int(0, mania);
                  case 1: // "RandomBasic"
                    var randomDirection:Int;
                    do
                    {
                      randomDirection = FlxG.random.int(0, mania);
                    }
                    while (randomDirection == prevNoteData && mania > 1);
                    prevNoteData = randomDirection;
                    noteColumn = randomDirection;
                  case 2: // "RandomComplex"
                    var thisNoteData = noteColumn;
                    if (initialNoteData == -1)
                    {
                      initialNoteData = noteColumn;
                      noteColumn = FlxG.random.int(0, mania);
                    }
                    else
                    {
                      var newNoteData:Int;
                      do
                      {
                        newNoteData = FlxG.random.int(0, mania);
                      }
                      while (newNoteData == prevNoteData && mania > 1);
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
                      noteColumn = mania - Std.int(songNotes[1] % Note.ammo[mania]);
                    }
                  case 4: // "Pain"
                    noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[mania]);
                  case 5: // "Stairs"
                    noteColumn = stair % Note.ammo[mania];
                    stair++;
                  case 6: // "Wave"
                    // Sketchie... WHY?!
                    var ammoFromFortnite:Int = Note.ammo[mania];
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
                    var ammoFromFortnite:Int = Note.ammo[mania];
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
                    var ammoFromFortnite:Int = Note.ammo[mania];
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
                    switch (stair % (2 * Note.ammo[mania]))
                    {
                      case 0:
                      case 1:
                      case 2:
                      case 3:
                      case 4:
                        noteColumn = stair % Note.ammo[mania];
                      default:
                        noteColumn = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
                    }
                    stair++;
                  case 10: // Jack Wave
                    var ammoFromFortnite:Int = Note.ammo[mania];
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
                    var ammoFromFortnite:Int = Note.ammo[mania];
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
                    while (noteColumn == prevNoteData && mania > 1);
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

        if (!preload) {
          // UNO Chart Modifier Processing
          if (chartModifier == "UNO") {
            if (unoMechanic == null) {
              unoMechanic = new UnoMechanic();
            }
            unoMechanic.processNote(swagNote, mania, spawnTime, gottaHitNote);
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
            var specialNotes = unoMechanic.generateSpecialNotes(swagNote, mania, allNotes);
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

            var sustainNote:Note = Note(spawnTime + (stepCrochet * susNote) + stepCrochet, noteColumn, oldNote, true, false, null, false);

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
          if (PlayState.instance.mechanicsMod != null) {
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
              moveStrumSections[sectionLoopCount] = true;
              weightedChances[7] = 0;
            }
            else
            {
              moveStrumSections[sectionLoopCount] = false;
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

          if (mechanicsMod != null) {
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


      trace('["${songData.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
      if (!preload) {
        for (event in songData.events) //Event Notes
          for (i in 0...event[1].length)
            makeEventPreload(event, i, preload);
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
        if (!chartCache.exists({songName: songData.song, modName: Mods.softloadDirectory})) {
          var songObject:SongObject = new SongObject(songData.song, Mods.softloadDirectory);
          songObject.chart = allNotes;
          songObject.events = eventNotes;
          songObject.noteTypes = noteTypes;
          chartCache.set({songName: songData.song, Mods.softloadDirectory}, songObject);
        }
      }
      generatedChart = true;
      trace('Finished Generating Notes for ${songData.song}!');
    }
  }

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
		if (!preload) {
			curEvents.push(subEvent);
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

		if (inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("BF's Mic"))
			return;

		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed)
				continue;

			controlledFields.push(field);
			field.keysPressed[column] = true;

			if (endingSong)
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
        if (MusicBeatState.getState() == PlayState.instance)
          PlayState.instance?.callOnScripts('onGhostTap', [column, field]);

				if (!ClientPrefs.data.ghostTapping)
					noteMissPress(column, field);
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
	var reverseNoteRules:Bool = false;
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
				if (!controls.controllerMode)
				{
					if (paused || !startedCountdown || inCutscene) return;
					if (pressed.contains(eventKey)) return;
					pressed.push(eventKey);
					if (key != -1) strumKeyDown(key);
				}
			}
			else {
				if (paused || !startedCountdown || inCutscene) return;
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
							if (generatedMusic && !endingSong)
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
              if (MusicBeatState.getState() == PlayState.instance)
                PlayState.instance?.callOnScripts('onGhostTap', [key]);

							if (!ClientPrefs.data.ghostTapping)
								noteMissPress(key, field);
						}
					}
				}
			}
		}
	}

  private function keyPressed(key:Int, player:Int = -1)
	{
		if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;
		if (strumsBlocked[key]) return;

		// Early script callback optimization - only call if scripts exist
		if (hasLuaScripts || hasHScripts) {
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

			if (endingSong) continue;

			var note:Note = null;

			// Optimize script callback - only call if scripts exist and return early if stopped
			if (hasLuaScripts || hasHScripts) {
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
				if (hasLuaScripts || hasHScripts) {
          if (MusicBeatState.getState() == PlayState.instance)
            PlayState.instance?.callOnScripts('onGhostTap', [key, field]);
				}

				if (!ClientPrefs.data.ghostTapping)
					noteMissPress(key, field);
			}
		}

		// Optimize keysPressed tracking with Map
		keysPressedSet[key] = true;
		if(!keysPressed.contains(key)) keysPressed.push(key);

		// Restore conductor position ONCE
		Conductor.songPosition = lastTime;

		// Final script callback - only if scripts exist
		if (hasLuaScripts || hasHScripts) {
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
				if (!controls.controllerMode)
				{
					if (paused || !startedCountdown || inCutscene) return;
					if (keyDirection != -1) strumKeyDown(keyDirection);
				}
			}
			else {
				if (paused || !startedCountdown || inCutscene) return;
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
							if (generatedMusic && !endingSong)
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
              if (MusicBeatState.getState() == PlayState.instance)
                PlayState.instance?.callOnScripts('onGhostTap', [keyDirection]);

							if (!ClientPrefs.data.ghostTapping)
								noteMissPress(keyDirection, field);
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
			if (paused || !startedCountdown || inCutscene) return;
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
						if (generatedMusic && !endingSong)
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
            if (MusicBeatState.getState() == PlayState.instance)
              PlayState.instance?.callOnScripts('onGhostTap', [direction]);

						if (!ClientPrefs.data.ghostTapping)
							noteMissPress(direction, field);
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
				if (!controls.controllerMode)
				{
					if (paused || !startedCountdown || inCutscene) return;
					if (pressed.contains(eventKey)) return;
					pressed.push(eventKey);
					if (key != -1) strumKeyDown(key);
				}
			}
			else {
				if (paused || !startedCountdown || inCutscene) return;
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
							if (generatedMusic && !endingSong)
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
              if (MusicBeatState.getState() == PlayState.instance)
                PlayState.instance?.callOnScripts('onGhostTap', [key]);

							if (!ClientPrefs.data.ghostTapping)
								noteMissPress(key, field);
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
		if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

    if (MusicBeatState.getState() == PlayState.instance)
      var ret:Dynamic = PlayState.instance?.callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

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

	public static function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
			for (i in 0...keysArray[mania].length)
				for (j in 0...keysArray[mania][i].length)
					if (key == keysArray[mania][i][j])
						return i;
		return -1;
	}

	public static function getMouseFromEvent(pressed:Int):Int
	{
		if (pressed != -1)
			for (i in 0...keysArray[mania].length)
				for (j in 0...keysArray[mania][i].length)
					if (pressed == keysArray[mania][i][j])
						return i;
		return -1;
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
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

			var keyArrayLength = keysArray[mania].length;
			holdArray.resize(keyArrayLength);
			pressArray.resize(keyArrayLength);
			releaseArray.resize(keyArrayLength);

			// Use direct indexing instead of push
			for (i in 0...keyArrayLength) {
				var key = keysArray[mania][i];
				holdArray[i] = controls.pressed(key);
				pressArray[i] = controls.justPressed(key);
				releaseArray[i] = controls.justReleased(key);
			}

			// Optimize controller input handling
			if(controls.controllerMode) {
				for (i in 0...pressArray.length) {
					if(pressArray[i] && strumsBlocked[i] != true) {
						keyPressed(i);
					}
				}
			}

			// Optimize hold checking
			if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic) {
				var hasHoldInput = false;
				for (hold in holdArray) {
					if (hold) {
						hasHoldInput = true;
						break;
					}
				}

				if (!hasHoldInput && !endingSong) {
					playerDance();
				}
				#if ACHIEVEMENTS_ALLOWED
				else if (hasHoldInput) {
					checkForAchievement(['oversinging']);
				}
				#end
			}

			// Optimize release handling
			if((controls.controllerMode || strumsBlocked.contains(true))) {
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
			if (startedCountdown && !boyfriend.stunned && generatedMusic)
			{
				// rewritten inputs???
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (parsedHoldArray.contains(true) && !endingSong)
					{
						#if ACHIEVEMENTS_ALLOWED
						checkForAchievement(['oversinging']);
						#end
					}
				});

				if (boyfriend != null && boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
					boyfriend.dance();

				if (bf2 != null && bf2.holdTimer > Conductor.stepCrochet * 0.001 * bf2.singDuration
					&& bf2.animation.curAnim.name.startsWith('sing')
					&& !bf2.animation.curAnim.name.endsWith('miss'))
					bf2.dance();

				if (strumsBlocked.contains(true))
				{
					var parsedArray:Array<Bool> = parseKeys('_R');
					if (parsedArray.contains(true))
					{
						for (i in 0...parsedArray.length)
						{
							if (parsedArray[i] || strumsBlocked[i] == true)
								onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[mania][i][0]));
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
      field.destroy();
      field = null;
    }
    playfields.clear();
    playfields = new FlxTypedGroup<PlayField>();

    // Clear strum note references
		if (playerStrums != null) {
			playerStrums.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			playerStrums.clear();
			playerStrums = null;
		}

		if (opponentStrums != null) {
			opponentStrums.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			opponentStrums.clear();
			opponentStrums = null;
		}

		if (strumLineNotes != null) {
			strumLineNotes.clear();
			strumLineNotes = null;
		}

    // Clear event and callback references
		if (eventNotes != null) {
			eventNotes.splice(0, eventNotes.length);
			eventNotes = null;
		}

		if (curEvents != null) {
			curEvents.splice(0, curEvents.length);
			curEvents = null;
		}

    // Clear input optimization variables
		if (keysPressedSet != null) {
			keysPressedSet.clear();
		}
		_cachedHoldArray = null;
		_cachedPressArray = null;
		_cachedReleaseArray = null;
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
class SongObject
{
	public var songName:String; // the y position where the change happens (modManager.getVisPos(songTime))
	public var modName:Float; // the song position (conductor.songTime) where the change starts
  public var chart:Array<Note>; // the song position (conductor.songTime) where the change starts
  public var events:Array<EventNote>; // the song position (conductor.songTime) where the change starts
  public var noteTypes:Array<Note>; // the song position (conductor.songTime) where the change starts
  public function new (?name:String, ?mod:String) {
    if (name != null)
      this.songName = name;
    if (mod != null)
      this.modName = mod;
  }
}
