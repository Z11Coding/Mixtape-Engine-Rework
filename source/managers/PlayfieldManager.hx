package managers;
import backend.Song.SwagSong;
import backend.modchartSystem.*;
import backend.pslice.ScaleMode;
import flixel.FlxState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxBitmapText;
import objects.funkin.graphics.ZSprite;
import objects.notes.BaseNote;
import objects.notes.Note;
import objects.notes.NoteSplash;
import objects.notes.PreloadNotes;
import objects.notes.StrumNote;
import objects.notes.Strumline;
import objects.notes.SustainSplash;
import openfl.events.KeyboardEvent;
import openfl.system.System;
import yutautil.modules.ASync.ASyncF;
import yutautil.modules.ASync;

using backend.funkin.util.tools.ArraySortTools;

class PlayfieldManager {
  public static var instance:PlayfieldManager;
  public static var SONG:SwagSong = null;

	public static final STRUM_X = 42;
	public static final STRUM_X_MIDDLESCROLL = -278;
  public static var curChart:Array<Note> = [];
  public var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

  public var notes:FlxTypedGroup<Note>; // Contains all the notes (spawned) (notes only)
	public var sustainNotes:FlxTypedGroup<Note>; // Contains all the notes (spawned) (sustains only)
	public var killNotes:Array<Note> = []; // Notes that shouldn't be there
	public var unspawnNotes:Array<PreloadNotes> = []; // Contains all the notes (unspawned)
  public var eventNotes:Array<EventNote> = []; // All Events for the current charts (actively used list)
	public var curEvents:Array<EventNote> = []; // All Events for the current charts (used for song looping)

  /**
   * an array containg every strumline! Used for easy reference to different players!
  */
  public var allStrumLines:Array<Strumline> = []; // All strums currently active
	public var opponentStrums:Strumline; // Strums for the Opponent
	public var playerStrums:Strumline; // Strums for the Player
	public var grpHoldSplashes:FlxTypedGroup<SustainSplash>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

  public var generatedChart:Bool = false;
  public var cpuControlled:Bool = false;
  public var curSong:String = "";

  public static var sectionsLoaded:Int = 0;
	public var notesLoadedRN:Int = 0;
  public var enemyHits:Float = 0;
  public var opponentNoteTotal:Float = 0;
  public var totalNotesPlayed:Float = 0;
  public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var totalNotes:Float = 0;
  public var jackingtime:Float = 0;

  public var notesAboveHUD:Bool = true;

  public var splashesPerFrame:Array<Int> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  var multiChangeEvents:Array<Array<Float>> = [[], []];

  // So that the chart is used instead of the file (will be labled differently in cache)
  public static var fromChartState:Bool = false;

  @:noCompletion function set_cpuControlled(value:Bool):Bool {
		cpuControlled = value;

		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.setOnScripts('botPlay', value);

		return (value || ClientPrefs.getGameplaySetting('showcase', false));
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
  public var noteRows:Array<Array<Array<BaseNote>>> = [[],[]];
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

  public var skipArrowStartTween:Bool = false; //for lua

  public var songName:String;

  public var manualInputChecks:Bool = false;

// HAZARD MODCHART VARS
  public var perframeFunctions:Array<Float->Void> = [];
  public var allStrumSprites:FlxTypedSpriteGroup<ZSprite>;
  public var customZspritesGroup:FlxTypedSpriteGroup<ZSprite>;

  // If true, will enable the modchart logic. If false, the game should act identical to Vanilla.
  public var isModchartSong:Bool = true;

  // basic flxSprite that can be used by lua for AFT purposes.
  public var luaAFT_sprite:HazardAFTSpriteTest;
  // basic AFT that can be used by lua for AFT purposes.
  public var luaAFT_Capture:HazardAFT;

  public function setUpLuaAft():Void
  {
    if (luaAFT_Capture != null || luaAFT_sprite != null) return; // already exists!
    luaAFT_Capture = new HazardAFT(camNotes);

    luaAFT_sprite = new HazardAFTSpriteTest(luaAFT_Capture);
    luaAFT_sprite.cameras = [camNotes];
    // luaAFT_sprite.setGraphicSize(Std.int(luaAFT_Capture.w * 0.95));
    luaAFT_sprite.zIndex = -9999;
    add(luaAFT_sprite);
  }

  function compareZSprites(order:Int, a:ZSprite, b:ZSprite):Int
  {
    // offset the z slightly so if zIndex plays a role in sorting. Useful for breaking ties if they are equal z value.
    return FlxSort.byValues(order, a?.z + ((a?.zIndex ?? 0) * 0.01), b?.z + ((b?.zIndex ?? 0) * 0.01));
  }

  // Offset for paths in zSort mode
  public var zSortMod_PathOffset:Float = -10000; // paths should always try and render below the notes!
  // Offset for sustains in zSort mode
  public var zSortMod_SustainOffset:Float = -15;
  // Offset for strumlineNotes in zSort mode
  public var zSortMod_StrumNoteOffset:Float = -0.4;
  // Offset for note splashes in zSort mode
  public var zSortMod_SplashOffset:Float = 3;
  // Offset for hold covers in zSort mode
  public var zSortMod_CoverOffset:Float = 3;
  // Offset for hold covers in zSort mode IF set to behind strums
  public var zSortMod_CoverBehindOffset:Float = -11.5;

  function offsetValueBasedOnType(a):Float
  {
    if (a.isHoldCover)
    {
      return a.coverBehindStrums ? zSortMod_CoverBehindOffset : zSortMod_CoverOffset;
    }
    else if (Std.isOfType(a, SustainNote))
    {
      var pcheck:SustainNote = cast(a, SustainNote);
      return zSortMod_SustainOffset;
    }
    else if (Std.isOfType(a, SustainTrail))
    {
      var pcheck:SustainTrail = cast(a, SustainTrail);
      return zSortMod_PathOffset;
    }
    else if (Std.isOfType(a, StrumNote))
    {
      return zSortMod_StrumNoteOffset;
    }
    else if (Std.isOfType(a, NoteSplash))
    {
      return zSortMod_SplashOffset;
    }
    else
    {
      return 0;
    }
  }

  function compareZSprites_playfields(order:Int, a:ZSprite, b:ZSprite):Int
  {
    var a_value:Float = a.z;
    var b_value:Float = b.z;

    // push the sustain and strumlinenotes back a bit to try and keep their correct layering. Note they can still layer over each other with a big enough z difference.
    // Set the offset variables to extremely high values to prevent this from ever occuring (like keep the sustains at the far back for example)

    a_value += offsetValueBasedOnType(a);
    b_value += offsetValueBasedOnType(b);

    if (a_value == b_value) // If they are equal, try and use zIndex to break the tie.
    {
      a_value = a.zIndex;
      b_value = b.zIndex;
    }

    return FlxSort.byValues(order, a_value, b_value);
  }

  /*
  * Changes the way notes are rendered (kinda) so now all the sprites are in one big group for them to have their z's sorted properly!
  */
  public var noteRenderMode(default, set):Bool = false;

  function set_noteRenderMode(v:Bool):Bool
  {
    if (v == noteRenderMode) return v; // skip, it's already set to this value
    noteRenderMode = v;

    if (allStrumSprites != null)
    {
      allStrumSprites.active = false;
      for (strumLine in allStrumLines)
      {
        if (strumLine.asleep) continue; // Skip this strumline if it's asleep lol
        strumLine.notes.visible = !v;
        strumLine.sustainNotes.visible = !v;
        strumLine.strumLineNotes.visible = !v;
        strumLine.arrowPaths.visible = !v;
        strumLine.noteSplashes.visible = !v;
        strumLine.holdSplashes.visible = !v;

        // Grab everything and throw it into the spritegroup!
        if (noteRenderMode)
        {
          strumLine.strumLineNotes.forEach(function(note:ZSprite)
          {
            allStrumSprites.add(note);
          });
          strumLine.notes.forEach(function(note:ZSprite)
          {
            allStrumSprites.add(note);
          });
          strumLine.sustainNotes.forEach(function(note:ZSprite)
          {
            allStrumSprites.add(note);
          });

          strumLine.arrowPaths.forEach(function(note:ZSprite)
          {
            allStrumSprites.add(note);
          });

          strumLine.noteSplashes.forEach(function(note:ZSprite)
          {
            allStrumSprites.add(note);
          });

          strumLine.holdSplashes.forEach(function(note:ZSprite)
          {
            allStrumSprites.add(note);
          });
        }
        else
        {
          allStrumSprites.clear();
        }
      }
      allStrumSprites.visible = v;
      trace(noteRenderMode ? "ZSort Render Method enabled!" : "ZSort Render Method disabled!");
    }
    return v;
  }

  /**
 * The camera which contains and controls the visibility of the strumlines!
 */
  public var camNotes:FlxCamera;

  /**
  * An extra camera layer stacked in front of the notes camera that can be used for effects.
  */
  public var camAFT:FlxCamera;

  // The event handler
  public var modchartEventHandler:ModEventHandler;

   /**
   * For custom playfields!
   */
  public var customStrumLines:Array<Strumline> = [];

  public var modchartTweenList:FlxBitmapText;

  function updateTweenList():Void
  {
    if (modchartTweenList == null) return;

    if (modchartTweenList.visible == false) return;
    modchartTweenList.text = "Tween List:\n";
    for (key in modchartEventHandler.modchartTweens.keys())
    {
      modchartTweenList.text += "'" + Std.string(key) + "', ";
    }
    modchartTweenList.screenCenter();
  }

  function setUpModTXT():Void
  {
    if (modchartTweenList != null) return; // We already have it created!

    modchartTweenList = new FlxBitmapText(0, 0, '', FlxBitmapFont.fromAngelCode(Paths.font("vcr-bmp.png"), Paths.font("vcr-bmp.fnt")));
    modchartTweenList.alignment = CENTER;
    modchartTweenList.borderStyle = OUTLINE;
    modchartTweenList.borderColor = FlxColor.BLACK;
    modchartTweenList.letterSpacing = -1;
    modchartTweenList.scrollFactor.set();
    modchartTweenList.zIndex = 927;
    modchartTweenList.autoSize = false;
    modchartTweenList.fieldWidth = Std.int(FlxG.width * 0.8);
    add(modchartTweenList);
    modchartTweenList.cameras = [PlayState.instance?.camHUD];
  }

  public function new() {
    instance = this;
    ExtraKeys.mania = 3;
    SONG = null;
    if (keysArray == null)
			keysArray = backend.Keybinds.fill();
    controlArray = ['NOTE_LEFT', 'NOTE_DOWN', 'NOTE_UP', 'NOTE_RIGHT'];
    manualInputChecks = false;
  }

  /// Mania
  public function fixMania() {
    convertMania = ClientPrefs.getGameplaySetting('convertMania', 3);
    if (ExtraKeys.mania > ExtraKeys.maxMania || ExtraKeys.mania < ExtraKeys.minMania)
      ExtraKeys.mania = ExtraKeys.defaultMania;
    else if (chartModifier == "4K Only")
      ExtraKeys.mania = 3;
    else if (chartModifier == "ManiaConverter")
      ExtraKeys.mania = convertMania;
    else if (SONG.mania != null)
      if (SONG.startMania != null) // If its a mixtape chart, use this instead
        ExtraKeys.mania = SONG.startMania;
      else if (SONG.mania >= 3) //Make sure it's even there
        ExtraKeys.mania = SONG.mania;
      else {
        ExtraKeys.mania = switch (SONG.mania) { //Convert it to make sure the older versions still work
          case 0: 3;
          case 1: 4;
          default: SONG.mania;
        }
      }
    else ExtraKeys.mania = 3;
    trace("Mania set: " + ExtraKeys.mania);
  }

  public function changeMania(newValue:Int, skipStrumFadeOut:Bool = false)
	{
    MegaManager.scriptManager.callOnScripts('preChangeMania', [ExtraKeys.mania, newValue, skipStrumFadeOut]);

    var daOldMania = ExtraKeys.mania;
    ExtraKeys.mania = newValue;

    if (playerStrums != null) playerStrums.strumLineNotes.clear();
    if (opponentStrums != null) opponentStrums.strumLineNotes.clear();
    if (grpHoldSplashes != null) grpHoldSplashes.clear();

    MegaManager.scriptManager.callOnScripts('onChangeMania', [ExtraKeys.mania, daOldMania]);


    MegaManager.scriptManager.setOnScripts('mania', ExtraKeys.mania);

    for (strum in allStrumLines) {
      strum.notes.forEachAlive(function(note:Note)
      {
        updateNote(note);
      });
    }

    MegaManager.scriptManager.callOnScripts('preReceptorGeneration'); // backwards compat, deprecated
    MegaManager.scriptManager.callOnScripts('onReceptorGeneration');



    for (i in 0...opponentStrums.length) {
      MegaManager.scriptManager.setOnScripts('defaultOpponentStrumX' + i, opponentStrums.getByColumn(i).x);
      MegaManager.scriptManager.setOnScripts('defaultOpponentStrumY' + i, opponentStrums.getByColumn(i).y);
    }
    for (i in 0...playerStrums.length) {
      MegaManager.scriptManager.setOnScripts('defaultPlayerStrumX' + i, playerStrums.getByColumn(i).x);
      MegaManager.scriptManager.setOnScripts('defaultPlayerStrumY' + i, playerStrums.getByColumn(i).y);
    }

    MegaManager.scriptManager.callOnScripts('postReceptorGeneration'); // deprecated
    MegaManager.scriptManager.callOnScripts('onReceptorGenerationPost');
    MegaManager.scriptManager.callOnScripts('onChangeMania', [ExtraKeys.mania, newValue, skipStrumFadeOut]);

    setStrumAlpha();

    singAnimations = ExtraKeys.keysShit.get(ExtraKeys.mania).get('singAnims');

    MegaManager.scriptManager.callOnScripts('postChangeMania', [ExtraKeys.mania, newValue, skipStrumFadeOut]);
	}

  function updateNote(note:Note)
	{
		if (note != null) {
			var tMania:Int = (ExtraKeys.mania+1);
			var noteData:Int = note.noteData;

			note.scale.set(1, 1);
			note.updateHitbox();

			// Like reloadNote()

			var lastScaleY:Float = note.scale.y;
			if (PlayState.isPixelStage)
			{
				// if (note.isSustainNote) {note.originalHeightForCalcs = note.height;}

				note.setGraphicSize(Std.int(note.width * PlayState.daPixelZoom * ExtraKeys.pixelScales[ExtraKeys.mania]));
			}
			else
			{
				// Like loadNoteAnims()

				note.setGraphicSize(Std.int(note.width * ExtraKeys.scales[ExtraKeys.mania]));
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
        note.alpha = 0.6;
        note.multAlpha = 0.6;
        note.hitsoundDisabled = true;
        if(ClientPrefs.data.downScroll)
          note.flipY = true;

        note.offsetX += note.width / 2;

				var animToPlay:String = '';
        animToPlay = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[note.noteData] + ' tail';
        if (!note.animation.exists(animToPlay))
        {
          animToPlay = ExtraKeys.colArray[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[note.noteData]] + 'holdend';
        }
        note.animation.play(animToPlay);

				note.updateHitbox();
        note.centerOffsets();

				if (prevNote != null && prevNote.isSustainNote)
				{
          // haxe flixel
					prevNote.animation.play(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[noteData % tMania] + ' hold');

					prevNote.scale.y *= MegaManager.conductor.stepLengthMs / 100 * 1.05;
					prevNote.scale.y *= PlayfieldManager.instance.songSpeed;

					if (PlayState.isPixelStage)
					{
						prevNote.scale.y *= 1.19;
						prevNote.scale.y *= (6 / note.height);
					}

					prevNote.updateHitbox();
          prevNote.centerOffsets();
					// trace(prevNote.scale.y);
				}

				if (PlayState.isPixelStage && prevNote != null)
				{
					prevNote.scale.y *= PlayState.daPixelZoom * (ExtraKeys.pixelScales[ExtraKeys.mania]); // Fuck urself
					prevNote.updateHitbox();
          prevNote.centerOffsets();
				}
			}
			else if (!note.isSustainNote && noteData > -1 && noteData < tMania)
			{
				if (note.changeAnim)
				{
					var animToPlay:String = '';

					animToPlay = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[noteData % tMania];

					note.animation.play(animToPlay);
				}
			}

			note.defaultRGB();

			// Like set_noteType()
		}
	}

  // NEW VARIABLE FOR V0.7.5A WHICH DEFAULTS TO TRUE TO COPY HUD ZOOMING!
  public var noteCamCopyHudZoom:Bool = true;

  function updateHazModchartSystem(elapsed:Float):Void
  {
    if (isModchartSong && modchartEventHandler != null)
    {
      modchartEventHandler.update(elapsed);
      updateTweenList();

      if (allStrumSprites != null)
      {
        if (
          allStrumSprites.members.length > 1
          && allStrumSprites.visible
        ) allStrumSprites.members.insertionSort(compareZSprites_playfields.bind(FlxSort.ASCENDING));
      }

      if (customZspritesGroup != null)
      {
        if (customZspritesGroup.members.length > 1 && customZspritesGroup.visible)
        {
          customZspritesGroup.members.insertionSort(compareZSprites.bind(FlxSort.ASCENDING));
        }
      }
    }
    if (luaAFT_Capture != null) luaAFT_Capture.update(elapsed);

    if (camNotes != null && noteCamCopyHudZoom)
    {
      camNotes.zoom = PlayState.instance?.camHUD.zoom;
    }
    if (camAFT != null && noteCamCopyHudZoom)
    {
      camAFT.zoom = PlayState.instance?.camHUD.zoom;
    }

    for (fun in perframeFunctions)
    {
      try
      {
        fun(elapsed);
      }
      catch (e)
      {
        perframeFunctions.remove(fun); // to avoid constantly spamming the broken function
        MegaManager.scriptManager.addTextToDebug(e.toString(), FlxColor.RED);
        trace("OH GOD OH FUCK IT NEARLY DIED CUZ OF: \n" + e.toString());
        return;
      }
    }
  }

  public function addNotes() {
    sustainNotes = new FlxTypedGroup<Note>();

		notes = new FlxTypedGroup<Note>();
		notes.visible = sustainNotes.visible = ClientPrefs.data.showNotes; //that was easier than expected

    grpHoldSplashes = new FlxTypedGroup<SustainSplash>((ClientPrefs.data.maxSplashLimit != 0 ? ClientPrefs.data.maxSplashLimit : 10000));

		SustainSplash.startCrochet = Conductor.stepCrochet;
		SustainSplash.frameRate = Math.floor(24 / 100 * SONG.bpm);
		var splash:SustainSplash = new SustainSplash();
		grpHoldSplashes.add(splash);
		splash.visible = true;
		splash.alpha = 0.0001;

		initStrumlines();

    if (isModchartSong)
    {
      camNotes = new FlxCamera();
      camNotes.bgColor.alpha = 0; // Show the game scene behind the camera.

      camAFT = new FlxCamera();
      camAFT.bgColor.alpha = 0; // Show the game scene behind the camera.
    }

    opponentStrums.cameras = [camNotes];
		playerStrums.cameras = [camNotes];
    initHazardModchart();

    /*opponentStrums.sustainNotes.visible = false;
    opponentStrums.holdSplashes.visible = false;
    opponentStrums.strumLineNotes.visible = false;
    opponentStrums.notes.visible = false;
    opponentStrums.noteSplashes.visible = false;
    playerStrums.sustainNotes.visible = false;
    playerStrums.holdSplashes.visible = false;
    playerStrums.strumLineNotes.visible = false;
    playerStrums.notes.visible = false;
    playerStrums.noteSplashes.visible = false;*/
  }

  public function setStrumAlpha() {
    for (group in [notes, sustainNotes]) group.forEachAlive(function(note:Note) {
      if(ClientPrefs.data.opponentStrums || !ClientPrefs.data.opponentStrums || ClientPrefs.data.middleScroll || !note.mustPress)
      {
        note.alpha *= 0.35;
      }
      if(ClientPrefs.data.opponentStrums || !ClientPrefs.data.opponentStrums || note.mustPress)
      {
        note.copyAlpha = false;
        note.alpha = note.multAlpha;
        if(ClientPrefs.data.middleScroll && !note.mustPress) {
          note.alpha *= 0.35;
        }
      }
    });
  }

  // Chart Loading
  public function loadChart(?startingPoint:Float = 0) {
    var offsetStart = (startingPoint > 0 ? 500 : 0);
    final startTime = haxe.Timer.stamp();

    var songData = SONG;
    songName = Paths.formatToSongPath(SONG.song).toLowerCase();
    final noteData:Array<SwagSection> = songData.notes;

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

    var currentBPMLol:Float = Conductor.bpm = songData.bpm;
		var stepCrochet:Float = 15000 / currentBPMLol;
		var currentMultiplier:Float = 1;
		var gottaHitNote:Bool = false;
		var swagNote:PreloadNotes;
		var ghostNotesCleared:Int = 0;
    var sectionLoopCount:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

    curSong = songData.song;
    songSpeed = songData.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = songData.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

    if (PlayState.chartingMode)
      chartModifier = "Normal";
    else
      chartModifier = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');
		// TODO: Optimize and clean up this mess, maybe split into functions
		// this is absolute spaghetti code
		for (section in noteData) {
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && currentBPMLol != section.bpm) {
				currentBPMLol = section.bpm;
				stepCrochet = 15000 / currentBPMLol;
			}

			for (i in 0...section.sectionNotes.length)
			{
				final songNotes:Array<Dynamic> = section.sectionNotes[i];
        var noteColumn:Int = Std.int(songNotes[1]);

				if (noteColumn == -1)
					continue;

				if (songNotes[0] >= startingPoint + offsetStart) {
					final daStrumTime:Float = songNotes[0] - songData.offset;
					var daNoteData:Int = 0;

          daNoteData = Std.int(noteColumn % ExtraKeys.ammo[songData.mania != null ? songData.mania : 3]);
					gottaHitNote = (noteColumn < (songData.mania != null ? totalColumns : ExtraKeys.ammo[songData.mania != null ? songData.mania : 3]));

          if (!PlayState.chartingMode) {
            switch (chartModifier)
            {
              case "Random":
                noteColumn = FlxG.random.int(0, ExtraKeys.mania);
              case "RandomBasic":
                var randomDirection:Int;
                do
                {
                  randomDirection = FlxG.random.int(0, ExtraKeys.mania);
                }
                while (randomDirection == prevNoteData && ExtraKeys.mania > 1);
                prevNoteData = randomDirection;
                noteColumn = randomDirection;
              case "RandomComplex":
                var thisNoteData = noteColumn;
                if (initialNoteData == -1)
                {
                  initialNoteData = noteColumn;
                  noteColumn = FlxG.random.int(0, ExtraKeys.mania);
                }
                else
                {
                  var newNoteData:Int;
                  do
                  {
                    newNoteData = FlxG.random.int(0, ExtraKeys.mania);
                  }
                  while (newNoteData == prevNoteData && ExtraKeys.mania > 1);
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
                var length = ExtraKeys.mania;
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
                var median:Float = (ExtraKeys.mania + 1) / 2;
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
                noteColumn = Std.int(Math.max(0, Math.min(noteColumn, ExtraKeys.mania - 1)));

              case "Skip":
                var skipStep = 2; // Define the step size for skipping notes.
                var randomLane = Math.random() < 0.5 ? prevNoteData : (prevNoteData + skipStep) % ExtraKeys.mania;
                var randomDuration = Math.random() * 30; // Randomize the duration before switching lanes (in notes).
                noteColumn = randomLane;
              case "Flip":
                if (gottaHitNote)
                {
                  noteColumn = ExtraKeys.mania - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
                }
              case "Pain":
                noteColumn = noteColumn - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
              case "4K Only":
                //trace("4K Only: " + noteColumn);
                noteColumn = getNumberFromAnimsSmall(noteColumn, 3);
                //trace("Note: " + noteColumn + " ExtraKeys.mania: " + ExtraKeys.mania + " GottaHit: " + gottaHitNote);
              case "ManiaConverter":
                //trace("ExtraKeys.maniaConverter: " + noteColumn);
                noteColumn = getNumberFromAnims(noteColumn, ExtraKeys.mania);
                //trace("Note: " + noteColumn + " ExtraKeys.mania: " + ExtraKeys.mania + " GottaHit: " + gottaHitNote);
              case "Stairs":
                noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
                stair++;
              case "Wave":
                // Sketchie... WHY?!
                var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                while (noteColumn == prevNoteData && ExtraKeys.mania > 1);
                prevNoteData = noteColumn;
              case "Ew":
                // I hate that I used Sketchie's variables as a base for this... ;-;
                var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                switch (stair % (2 * ExtraKeys.ammo[ExtraKeys.mania]))
                {
                  case 0:
                  case 1:
                  case 2:
                  case 3:
                  case 4:
                    noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
                  default:
                    noteColumn = ExtraKeys.ammo[ExtraKeys.mania] - 1 - (stair % ExtraKeys.ammo[ExtraKeys.mania]);
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
                      noteColumn = FlxG.random.int(0, ExtraKeys.mania);
                    case 1: // "RandomBasic"
                      var randomDirection:Int;
                      do
                      {
                        randomDirection = FlxG.random.int(0, ExtraKeys.mania);
                      }
                      while (randomDirection == prevNoteData && ExtraKeys.mania > 1);
                      prevNoteData = randomDirection;
                      noteColumn = randomDirection;
                    case 2: // "RandomComplex"
                      var thisNoteData = noteColumn;
                      if (initialNoteData == -1)
                      {
                        initialNoteData = noteColumn;
                        noteColumn = FlxG.random.int(0, ExtraKeys.mania);
                      }
                      else
                      {
                        var newNoteData:Int;
                        do
                        {
                          newNoteData = FlxG.random.int(0, ExtraKeys.mania);
                        }
                        while (newNoteData == prevNoteData && ExtraKeys.mania > 1);
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
                        noteColumn = ExtraKeys.mania - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
                      }
                    case 4: // "Pain"
                      noteColumn = noteColumn - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
                    case 5: // "Stairs"
                      noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
                      stair++;
                    case 6: // "Wave"
                      // Sketchie... WHY?!
                      var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                      var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                      var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                      switch (stair % (2 * ExtraKeys.ammo[ExtraKeys.mania]))
                      {
                        case 0:
                        case 1:
                        case 2:
                        case 3:
                        case 4:
                          noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
                        default:
                          noteColumn = ExtraKeys.ammo[ExtraKeys.mania] - 1 - (stair % ExtraKeys.ammo[ExtraKeys.mania]);
                      }
                      stair++;
                    case 10: // Jack Wave
                      var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                      var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                      while (noteColumn == prevNoteData && ExtraKeys.mania > 1);
                      prevNoteData = noteColumn;
                    default:
                      // Default case (optional)
                  }
                }
            }
          }

					if (gottaHitNote && songNotes[3] != 'Hurt Note') {
						totalNotes += 1;
					}
					if (!gottaHitNote) {
						opponentNoteTotal += 1;
					}

					if (multiChangeEvents[0].length > 0 && daStrumTime >= multiChangeEvents[0][0])
					{
						currentMultiplier = multiChangeEvents[1][0];
						multiChangeEvents[0].shift();
						multiChangeEvents[1].shift();
					}

          var isAlt: Bool = songNotes[3] == 'Alt Animation' || section.altAnim && !gottaHitNote;
					swagNote = {
						strumTime: daStrumTime,
						noteData: daNoteData,
						mustPress: gottaHitNote,
						oppNote: !gottaHitNote,
						noteType: songNotes[3],
						animSuffix: (isAlt ? '-alt' : ''),
						gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && gottaHitNote == section.mustHitSection),
            exNote: songNotes[3] == 'EX Note' || (section.exSection && gottaHitNote == section.mustHitSection),
						noAnimation: songNotes[3] == 'No Animation',
						noMissAnimation: songNotes[3] == 'No Animation',
						sustainLength: songNotes[2],
						hitHealth: 0.023,
						missHealth: songNotes[3] != 'Hurt Note' ? 0.0475 : 0.3,
						wasHit: false,
						hitCausesMiss: songNotes[3] == 'Hurt Note',
						multSpeed: 1,
						multAlpha: 1,
						noteDensity: currentMultiplier,
						ignoreNote: songNotes[3] == 'Hurt Note' && gottaHitNote
					};

          var noteType:String = !Std.isOfType(songNotes[3], String) ? NoteTypesConfig.defaultNoteTypes[songNotes[3]] : songNotes[3];
					swagNote.noteType = noteType; //Backward compatibility + compatibility with Week 7 charts

					if(Std.isOfType(songNotes[3], Bool))
            swagNote.animSuffix = (songNotes[3] || section.altAnim ? '-alt' : ''); //Compatibility with charts made by SNIFF

					if (!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}

          swagNote.row = Conductor.secsToRow(daStrumTime);

					unspawnNotes.push(swagNote);
          if (playerStrums != null && opponentStrums != null)
            (gottaHitNote ? playerStrums : opponentStrums).unspawnNotes.push(swagNote);

					if (jackingtime > 0) {
						for (j in 0...Std.int(jackingtime)) {
							final jackNote:PreloadNotes = {
								strumTime: swagNote.strumTime + (15000 / SONG.bpm) * (j + 1),
								noteData: swagNote.noteData,
								mustPress: swagNote.mustPress,
								oppNote: swagNote.oppNote,
								noteType: swagNote.noteType,
								animSuffix: (isAlt ? '-alt' : ''),
								gfNote: swagNote.gfNote,
                exNote: swagNote.exNote,
								isSustainNote: false,
								isSustainEnd: false,
								parentST: 0,
								hitHealth: swagNote.hitHealth,
								missHealth: swagNote.missHealth,
								wasHit: false,
								multSpeed: 1,
								multAlpha: 1,
								noteDensity: currentMultiplier,
								hitCausesMiss: swagNote.hitCausesMiss,
								ignoreNote: swagNote.ignoreNote
							};
							unspawnNotes.push(jackNote);
              if (playerStrums != null && opponentStrums != null)
                (gottaHitNote ? playerStrums : opponentStrums).unspawnNotes.push(jackNote);
						}
					}

					if (swagNote.sustainLength < 1) continue;

					final roundSus:Int = Math.round(swagNote.sustainLength / stepCrochet);
					if (roundSus > 0) {
						for (susNote in 0...roundSus + 1) {
							final sustainNote:PreloadNotes = {
								strumTime: daStrumTime + (stepCrochet * susNote),
								noteData: daNoteData,
								mustPress: gottaHitNote,
								oppNote: !gottaHitNote,
								noteType: songNotes[3],
								animSuffix: (songNotes[3] == 'Alt Animation' || section.altAnim ? '-alt' : ''),
								gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && songNotes[1] < ExtraKeys.mania+1),
                exNote: songNotes[3] == 'EX Note' || (section.exSection && songNotes[1] < ExtraKeys.mania+1),
								noAnimation: songNotes[3] == 'No Animation',
								isSustainNote: true,
								isSustainEnd: susNote == roundSus,
								parentST: swagNote.strumTime,
								parentSL: swagNote.sustainLength,
								hitHealth: 0.023,
								missHealth: songNotes[3] != 'Hurt Note' ? 0.0475 : 0.1,
								wasHit: false,
								multSpeed: 1,
								multAlpha: 1,
								noteDensity: currentMultiplier,
								hitCausesMiss: songNotes[3] == 'Hurt Note',
								ignoreNote: songNotes[3] == 'Hurt Note' && swagNote.mustPress
							};
							unspawnNotes.push(sustainNote);
              if (playerStrums != null && opponentStrums != null)
                (gottaHitNote ? playerStrums : opponentStrums).unspawnNotes.push(sustainNote);
						}
					}
				} else {
					final gottaHitNote:Bool = ((songNotes[1] < ExtraKeys.mania+1) ? section.mustHitSection : !section.mustHitSection);
					if (gottaHitNote && songNotes[3] != 'Hurt Note') {
						totalNotes += 1;
						totalNotesPlayed += 1;
					}
					if (!gottaHitNote) {
						opponentNoteTotal += 1;
						enemyHits += 1;
					}
				}
			}
			sectionsLoaded += 1;
			notesLoadedRN += section.sectionNotes.length;
		}

		if (ClientPrefs.data.noteColorStyle == 'Char-Based')
		{
			for (group in [notes, sustainNotes])
				for (note in group){
					if (note == null || !note.alive)
						continue;
					if (ClientPrefs.data.enableColorShader) note.updateRGBColors();
				}
		}
		// trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCleared');
		unspawnNotes.sort(sortByTime);
		eventNotes.sort(sortByTime);

    trace('["${songData.song.toUpperCase()}" CHART INFO]: Total Notes: ${unspawnNotes.length}');

		sectionsLoaded = 0;

		final endTime = haxe.Timer.stamp();

		System.gc();

		final elapsedTime = endTime - startTime;

		notesLoadedRN = 0;
    generatedChart = true;
    trace('Finished Generating Notes for ${songData.song}!');
  }

  public var noteTypes:Array<String> = [];
	public var eventsPushed:Array<String> = [];
  private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var totalColumns:Int = ExtraKeys.ammo[SONG?.mania != null ? SONG?.mania : 3];
	var prevNoteData:Int = -1;
	var initialNoteData:Int = -1;
	var caseExecutionCount:Int = FlxG.random.int(-50, 50);
	var currentModifier:Int = -1;
	var stair:Int = 0;

  /*private function generateChart(songData:SwagSong, ?preload:Bool = false):Void
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
        final songNotes:Array<Dynamic> = section.sectionNotes[i];
        var spawnTime:Float = songNotes[0];
        var noteColumn:Int = Std.int(songNotes[1]);
        var noteStartColumn:Int = Std.int(songNotes[1] % ExtraKeys.ammo[songData.mania != null ? songData.mania : 3]);
        var holdLength:Float = songNotes[2];
        var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
        if (Math.isNaN(holdLength)) holdLength = 0.0;

        var gottaHitNote:Bool;
        noteColumn = Std.int(songNotes[1] % ExtraKeys.ammo[songData.mania != null ? songData.mania : 3]);
        gottaHitNote = (songNotes[1] < (songData.mania != null ? totalColumns : ExtraKeys.ammo[songData.mania != null ? songData.mania : 3]));

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
              noteColumn = FlxG.random.int(0, ExtraKeys.mania);
            case "RandomBasic":
              var randomDirection:Int;
              do
              {
                randomDirection = FlxG.random.int(0, ExtraKeys.mania);
              }
              while (randomDirection == prevNoteData && ExtraKeys.mania > 1);
              prevNoteData = randomDirection;
              noteColumn = randomDirection;
            case "RandomComplex":
              var thisNoteData = noteColumn;
              if (initialNoteData == -1)
              {
                initialNoteData = noteColumn;
                noteColumn = FlxG.random.int(0, ExtraKeys.mania);
              }
              else
              {
                var newNoteData:Int;
                do
                {
                  newNoteData = FlxG.random.int(0, ExtraKeys.mania);
                }
                while (newNoteData == prevNoteData && ExtraKeys.mania > 1);
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
            // 	} else if (prevNoteData == ExtraKeys.mania - 1) {
            // 		noteColumn = ExtraKeys.mania - 2;
            // 		direction = -1;
            // 	} else {
            // 		noteColumn = prevNoteData + direction;
            // 	}
            // 	break;
            case "Mirror": // Broken
              var length = ExtraKeys.mania;
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
              var median:Float = (ExtraKeys.mania + 1) / 2;
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
              noteColumn = Std.int(Math.max(0, Math.min(noteColumn, ExtraKeys.mania - 1)));

            case "Skip":
              var skipStep = 2; // Define the step size for skipping notes.
              var randomLane = Math.random() < 0.5 ? prevNoteData : (prevNoteData + skipStep) % ExtraKeys.mania;
              var randomDuration = Math.random() * 30; // Randomize the duration before switching lanes (in notes).
              noteColumn = randomLane;
            case "Flip":
              if (gottaHitNote)
              {
                noteColumn = ExtraKeys.mania - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
              }
            case "Pain":
              noteColumn = noteColumn - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
            case "4K Only":
              //trace("4K Only: " + noteColumn);
              noteColumn = getNumberFromAnimsSmall(noteColumn, 3);
              //trace("Note: " + noteColumn + " ExtraKeys.mania: " + ExtraKeys.mania + " GottaHit: " + gottaHitNote);
            case "ManiaConverter":
              //trace("ExtraKeys.maniaConverter: " + noteColumn);
              noteColumn = getNumberFromAnims(noteColumn, ExtraKeys.mania);
              //trace("Note: " + noteColumn + " ExtraKeys.mania: " + ExtraKeys.mania + " GottaHit: " + gottaHitNote);
            case "Stairs":
              noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
              stair++;
            case "Wave":
              // Sketchie... WHY?!
              var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
              var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
              while (noteColumn == prevNoteData && ExtraKeys.mania > 1);
              prevNoteData = noteColumn;
            case "Ew":
              // I hate that I used Sketchie's variables as a base for this... ;-;
              var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
              var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
              switch (stair % (2 * ExtraKeys.ammo[ExtraKeys.mania]))
              {
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                  noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
                default:
                  noteColumn = ExtraKeys.ammo[ExtraKeys.mania] - 1 - (stair % ExtraKeys.ammo[ExtraKeys.mania]);
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
                    noteColumn = FlxG.random.int(0, ExtraKeys.mania);
                  case 1: // "RandomBasic"
                    var randomDirection:Int;
                    do
                    {
                      randomDirection = FlxG.random.int(0, ExtraKeys.mania);
                    }
                    while (randomDirection == prevNoteData && ExtraKeys.mania > 1);
                    prevNoteData = randomDirection;
                    noteColumn = randomDirection;
                  case 2: // "RandomComplex"
                    var thisNoteData = noteColumn;
                    if (initialNoteData == -1)
                    {
                      initialNoteData = noteColumn;
                      noteColumn = FlxG.random.int(0, ExtraKeys.mania);
                    }
                    else
                    {
                      var newNoteData:Int;
                      do
                      {
                        newNoteData = FlxG.random.int(0, ExtraKeys.mania);
                      }
                      while (newNoteData == prevNoteData && ExtraKeys.mania > 1);
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
                      noteColumn = ExtraKeys.mania - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
                    }
                  case 4: // "Pain"
                    noteColumn = noteColumn - Std.int(songNotes[1] % ExtraKeys.ammo[ExtraKeys.mania]);
                  case 5: // "Stairs"
                    noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
                    stair++;
                  case 6: // "Wave"
                    // Sketchie... WHY?!
                    var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                    var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                    var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                    switch (stair % (2 * ExtraKeys.ammo[ExtraKeys.mania]))
                    {
                      case 0:
                      case 1:
                      case 2:
                      case 3:
                      case 4:
                        noteColumn = stair % ExtraKeys.ammo[ExtraKeys.mania];
                      default:
                        noteColumn = ExtraKeys.ammo[ExtraKeys.mania] - 1 - (stair % ExtraKeys.ammo[ExtraKeys.mania]);
                    }
                    stair++;
                  case 10: // Jack Wave
                    var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                    var ammoFromFortnite:Int = ExtraKeys.ammo[ExtraKeys.mania];
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
                    while (noteColumn == prevNoteData && ExtraKeys.mania > 1);
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
            unoMechanic.processNote(swagNote, ExtraKeys.mania, spawnTime, gottaHitNote);
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
            var specialNotes = unoMechanic.generateSpecialNotes(swagNote, ExtraKeys.mania, allNotes);
            for (specialNote in specialNotes) {
              if (playfield != null) {
                specialNote.field = playfield;
                specialNote.fieldIndex = swagNote.fieldIndex;
                if (!preload) {
                  playfield.queue(specialNote);
                }
                notes.add(specialNote);
              }
              else if (preload) {
                // During preload, still add to allNotes even without playfield
                specialNote.fieldIndex = swagNote.fieldIndex;
                notes.add(specialNote);
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

          /*for (susNote in 0...roundSus)
          {
            oldNote = allNotes[Std.int(allNotes.length - 1)];

            var sustainNote:Note = new Note(spawnTime + (stepCrochet * susNote) + stepCrochet, noteColumn, null, true, false, null);

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
            //sustainNote.ID = allNotes.length;
            sustainNote.scrollFactor.set();
            //sustainNote.holdType = roundSus > 0 ? PART : END;
            sustainNote.parent = swagNote;
            sustainNote.fieldIndex = parentFieldIndex;
            sustainNote.field = parentField;
            swagNote.tail.push(sustainNote);
            swagNote.unhitTail.push(sustainNote);
            if (!preload && playfield != null) {
              playfield.queue(sustainNote);
            }
            //allNotes.push(sustainNote);
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

                  notes.insert(placeNote);
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

                  notes.insert(throatNote);
                }
              }
            }
            sectionLoopCount += 1;
          }

          if (PlayState.mechanicsMod != null) {
            if (MechanicManager.mechanics["note_speed"].points > 0)
            {
              for (note in unspawnNotes)
              {
                if (note.isSustainNote)
                  continue;
                var speedBound:{min:Float, max:Float};
                var points:Float = MechanicManager.mechanics["note_speed"].points;

                speedBound = {min: FlxMath.remapToRange(points, 0, 20, -0, -0.5), max: FlxMath.remapToRange(points, 0, 20, 0, 0.5)};
                note.multSpeed = songSpeed + FlxG.random.float(speedBound.min, speedBound.max);
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

    unspawnNotes.sort(sortByTime);

    if (!preload) {
      if (curChart == null || curChart.isNotEmpty())
        curChart = new Array<Note>();
    }

    // curChart = cast (curChart:objects.NotePool.NoteArray);

    if (preload) {
      var isTempChart:String = (fromChartState ? " (temp)" : "");
      var tempSongObj:String = new SongObjectType(songName+isTempChart+Difficulty.getFilePath(), Mods.currentModDirectory).toString();
      /*if (!chartCache.exists(tempSongObj)) {
        var songObject:SongObject = new SongObject();
        songObject.chart = allNotes;
        songObject.events = eventNotes;
        songObject.noteTypes = noteTypes;
        chartCache.set(tempSongObj, songObject);
      }
      resetChartStuff();
      fromChartState = false;
    } else generatedChart = true;
    trace('Finished Generating Notes for ${songData.song}!');
  }*/

  private function placeNote(chance:Float, noteType:String, attributes:Array<Dynamic>):Note
	{
		if (FlxG.random.bool(chance))
		{
			var dataNote:Note = new Note(attributes[0], attributes[1]);
			dataNote.autoGenerated = true;
			dataNote.earlyHitMult = attributes[3];
			dataNote.mustPress = dataNote.formerPress = attributes[2];
			dataNote.noteType = noteType;
			//dataNote.scrollSpeed = PlayfieldManager.instance.songSpeed;
			dataNote.scrollFactor.set();

			return dataNote;
		}

		return null;
	}

  public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

  public static function getNumberFromAnimsSmall(note:Int, mania:Int):Int {
		var anims:Array<String> = ExtraKeys.keysShit.get(mania).get("anims");
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

    var anims:Array<String> = ExtraKeys.keysShit.get(mania).get("anims");
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
      MegaManager.scriptManager.callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
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

			if (key != -1) keyReleased(key);
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
					if (key != -1) keyPressed(key);
				}
			}
			else {
        if (playerStrums != null && opponentStrums != null) return; // No reason to worry about it if it aint there lol
				if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
				if (pressed.contains(eventKey)) return;
				pressed.push(eventKey);
        if (MegaManager.scriptManager.callOnScripts("onKeyDown", [event]) == LuaUtils.Function_Stop) return;

				if (key > -1)
				{
					if (APInfo.inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("BF's Mic"))
            return;

          @:privateAccess
          if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || PlayState.instance?.paused || PlayState.instance?.inCutscene || key < 0 || key >= playerStrums.length || !PlayState.instance?.generatedMusic || PlayState.instance?.endingSong) return;
          if (strumsBlocked[key]) return;

          // Early script callback optimization - only call if scripts exist
          if (MegaManager.scriptManager.hasLuaScripts || MegaManager.scriptManager.hasHScripts) {
            var ret:Dynamic = MegaManager.scriptManager.callOnScripts('onKeyPressPre', [key]);
            if(ret == LuaUtils.Function_Stop) return;
          }

          //more accurate hit time for the ratings?
          var lastTime:Float = MegaManager.conductor.musicPosition;
          var canMiss:Bool = !ClientPrefs.data.ghostTapping;

          // obtain notes that the player can hit
          var plrInputNotes:Array<Note> = playerStrums.notes.members.filter(function(n:Note):Bool {
            var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
            // trace('[keyPressed] Note? ${n != null}, noteData=${n.noteData}, strumTime=${n.strumTime}, canHit=$canHit, mustPress=${n.mustPress}, tooLate=${n.tooLate}, wasGoodHit=${n.wasGoodHit}, Conductor=${Conductor.songPosition}');
            return n != null && n.exists && canHit && !n.isSustainNote && n.noteData == key;
          });
          plrInputNotes.sort(PlayState.sortHitNotes);

          if (plrInputNotes.length != 0) {
            var funnyNote:Note = plrInputNotes[0]; // front note

            if (plrInputNotes.length > 1) {
              var doubleNote:Note = plrInputNotes[1];

              //if the note has the same notedata and doOppStuff indicator as funnynote, then do the check
              if (doubleNote.noteData == funnyNote.noteData && doubleNote.doOppStuff == funnyNote.doOppStuff) {
                // if the note has a 0ms distance (is on top of the current note), kill it
                if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
                  PlayState.instance?.invalidateNote(doubleNote);
                else if (doubleNote.strumTime < funnyNote.strumTime)
                {
                  // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
                  funnyNote = doubleNote;
                }
              }
              else PlayState.instance?.goodNoteHit(doubleNote); //otherwise, hit doubleNote instead of killing it
            }
            PlayState.instance?.goodNoteHit(funnyNote);
            if (plrInputNotes.length > 2 && ClientPrefs.data.ezSpam) {
              for (i in 1...plrInputNotes.length) PlayState.instance?.goodNoteHit(plrInputNotes[i]);
            }
          }
          else {
            MegaManager.scriptManager.callOnScripts('onGhostTap', [key]);
            if (canMiss) PlayState.instance?.noteMissPress(key);
          }

          var spr:StrumNote = playerStrums.getByColumn(key);
          if(strumsBlocked[key] != true && spr != null && spr.animation != null && spr.animation.curAnim.name != 'confirm')
          {
            spr.playAnim('pressed');
            spr.resetAnim = 0;
          }

          // Optimize keysPressed tracking with Map
          keysPressedSet[key] = true;
          if(!keysPressed.contains(key))
            keysPressed.push(key);


          // Final script callback - only if scripts exist
          if (MegaManager.scriptManager.hasLuaScripts || MegaManager.scriptManager.hasHScripts) {
            MegaManager.scriptManager.callOnScripts('onKeyPress', [key]);
          }
				}
			}
		}
	}

  private function keyPressed(key:Int)
	{
    if (APInfo.inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("BF's Mic"))
			return;

    @:privateAccess
		if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || PlayState.instance?.paused || PlayState.instance?.inCutscene || key < 0 || key >= playerStrums.length || !PlayState.instance?.generatedMusic || PlayState.instance?.endingSong) return;
		if (strumsBlocked[key]) return;

		// Early script callback optimization - only call if scripts exist
		if (PlayState.instance?.hasLuaScripts || PlayState.instance?.hasHScripts) {
      var ret:Dynamic = MegaManager.scriptManager.callOnScripts('onKeyPressPre', [key]);
      if(ret == LuaUtils.Function_Stop) return;
		}

    //more accurate hit time for the ratings?
		var lastTime:Float = MegaManager.conductor.musicPosition;
		var canMiss:Bool = !ClientPrefs.data.ghostTapping;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			// trace('[keyPressed] Note? ${n != null}, noteData=${n.noteData}, strumTime=${n.strumTime}, canHit=$canHit, mustPress=${n.mustPress}, tooLate=${n.tooLate}, wasGoodHit=${n.wasGoodHit}, Conductor=${Conductor.songPosition}');
			return n != null && n.exists && canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(PlayState.sortHitNotes);

		if (plrInputNotes.length != 0) {
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				//if the note has the same notedata and doOppStuff indicator as funnynote, then do the check
				if (doubleNote.noteData == funnyNote.noteData && doubleNote.doOppStuff == funnyNote.doOppStuff) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						PlayState.instance?.invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
				else PlayState.instance?.goodNoteHit(doubleNote); //otherwise, hit doubleNote instead of killing it
			}
			PlayState.instance?.goodNoteHit(funnyNote);
			if (plrInputNotes.length > 2 && ClientPrefs.data.ezSpam) {
				for (i in 1...plrInputNotes.length) PlayState.instance?.goodNoteHit(plrInputNotes[i]);
			}
		}
		else {
			MegaManager.scriptManager.callOnScripts('onGhostTap', [key]);
			if (canMiss) PlayState.instance?.noteMissPress(key);
		}

		var spr:StrumNote = playerStrums.getByColumn(key);
		if(strumsBlocked[key] != true && spr != null && spr.animation != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}

		// Optimize keysPressed tracking with Map
		keysPressedSet[key] = true;
		if(!keysPressed.contains(key))
      keysPressed.push(key);


		// Final script callback - only if scripts exist
		if (MegaManager.scriptManager.hasLuaScripts || MegaManager.scriptManager.hasHScripts) {
      MegaManager.scriptManager.callOnScripts('onKeyPress', [key]);
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
			if (keyDirection != -1) keyReleased(keyDirection);
		} else {
			if (ClientPrefs.data.inputSystem == "Native-old") {
				if (!Controls.instance.controllerMode)
				{
					if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
					if (keyDirection != -1) keyPressed(keyDirection);
				}
			}
			else {
				if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
				if (MegaManager.scriptManager.callOnScripts("onKeyDown", [keyDirection]) == LuaUtils.Function_Stop) return;

				if (keyDirection > -1)
				{
					if (APInfo.inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("BF's Mic"))
            return;

          @:privateAccess
          if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || PlayState.instance?.paused || PlayState.instance?.inCutscene || keyDirection < 0 || keyDirection >= playerStrums.length || !PlayState.instance?.generatedMusic || PlayState.instance?.endingSong) return;
          if (strumsBlocked[keyDirection]) return;

          // Early script callback optimization - only call if scripts exist
          if (MegaManager.scriptManager.hasLuaScripts || MegaManager.scriptManager.hasHScripts) {
            var ret:Dynamic = MegaManager.scriptManager.callOnScripts('onKeyPressPre', [keyDirection]);
            if(ret == LuaUtils.Function_Stop) return;
          }

          //more accurate hit time for the ratings?
          var lastTime:Float = MegaManager.conductor.musicPosition;
          var canMiss:Bool = !ClientPrefs.data.ghostTapping;

          // obtain notes that the player can hit
          var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
            var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
            // trace('[keyPressed] Note? ${n != null}, noteData=${n.noteData}, strumTime=${n.strumTime}, canHit=$canHit, mustPress=${n.mustPress}, tooLate=${n.tooLate}, wasGoodHit=${n.wasGoodHit}, Conductor=${Conductor.songPosition}');
            return n != null && n.exists && canHit && !n.isSustainNote && n.noteData == keyDirection;
          });
          plrInputNotes.sort(PlayState.sortHitNotes);

          if (plrInputNotes.length != 0) {
            var funnyNote:Note = plrInputNotes[0]; // front note

            if (plrInputNotes.length > 1) {
              var doubleNote:Note = plrInputNotes[1];

              //if the note has the same notedata and doOppStuff indicator as funnynote, then do the check
              if (doubleNote.noteData == funnyNote.noteData && doubleNote.doOppStuff == funnyNote.doOppStuff) {
                // if the note has a 0ms distance (is on top of the current note), kill it
                if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
                  PlayState.instance?.invalidateNote(doubleNote);
                else if (doubleNote.strumTime < funnyNote.strumTime)
                {
                  // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
                  funnyNote = doubleNote;
                }
              }
              else PlayState.instance?.goodNoteHit(doubleNote); //otherwise, hit doubleNote instead of killing it
            }
            PlayState.instance?.goodNoteHit(funnyNote);
            if (plrInputNotes.length > 2 && ClientPrefs.data.ezSpam) {
              for (i in 1...plrInputNotes.length) PlayState.instance?.goodNoteHit(plrInputNotes[i]);
            }
          }
          else {
            MegaManager.scriptManager.callOnScripts('onGhostTap', [keyDirection]);
            if (canMiss) PlayState.instance?.noteMissPress(keyDirection);
          }

          var spr:StrumNote = playerStrums.getByColumn(keyDirection);
          if(strumsBlocked[keyDirection] != true && spr != null && spr.animation != null && spr.animation.curAnim.name != 'confirm')
          {
            spr.playAnim('pressed');
            spr.resetAnim = 0;
          }

          // Optimize keysPressed tracking with Map
          keysPressedSet[keyDirection] = true;
          if(!keysPressed.contains(keyDirection))
            keysPressed.push(keyDirection);


          // Final script callback - only if scripts exist
          if (MegaManager.scriptManager.hasLuaScripts || MegaManager.scriptManager.hasHScripts) {
            MegaManager.scriptManager.callOnScripts('onKeyPress', [keyDirection]);
          }
				}
			}
		}
	}

	private function onMouseRelease(key:Int):Void
	{
		var direction:Int = getMouseFromEvent(key);
		if (reverseNoteRules) {
			if (ClientPrefs.data.inputSystem == "Native-old") {
				if (!Controls.instance.controllerMode)
				{
					if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
					if (direction != -1) keyPressed(direction);
				}
			}
			else {
				if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
				if (MegaManager.scriptManager.callOnScripts("onKeyDown", [direction]) == LuaUtils.Function_Stop) return;

				if (direction > -1)
				{
					if (APInfo.inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("BF's Mic"))
            return;

          @:privateAccess
          if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || PlayState.instance?.paused || PlayState.instance?.inCutscene || direction < 0 || direction >= playerStrums.length || !PlayState.instance?.generatedMusic || PlayState.instance?.endingSong) return;
          if (strumsBlocked[direction]) return;

          // Early script callback optimization - only call if scripts exist
          if (MegaManager.scriptManager.hasLuaScripts || MegaManager.scriptManager.hasHScripts) {
            var ret:Dynamic = MegaManager.scriptManager.callOnScripts('onKeyPressPre', [direction]);
            if(ret == LuaUtils.Function_Stop) return;
          }

          //more accurate hit time for the ratings?
          var lastTime:Float = MegaManager.conductor.musicPosition;
          var canMiss:Bool = !ClientPrefs.data.ghostTapping;

          // obtain notes that the player can hit
          var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
            var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
            // trace('[keyPressed] Note? ${n != null}, noteData=${n.noteData}, strumTime=${n.strumTime}, canHit=$canHit, mustPress=${n.mustPress}, tooLate=${n.tooLate}, wasGoodHit=${n.wasGoodHit}, Conductor=${Conductor.songPosition}');
            return n != null && n.exists && canHit && !n.isSustainNote && n.noteData == direction;
          });
          plrInputNotes.sort(PlayState.sortHitNotes);

          if (plrInputNotes.length != 0) {
            var funnyNote:Note = plrInputNotes[0]; // front note

            if (plrInputNotes.length > 1) {
              var doubleNote:Note = plrInputNotes[1];

              //if the note has the same notedata and doOppStuff indicator as funnynote, then do the check
              if (doubleNote.noteData == funnyNote.noteData && doubleNote.doOppStuff == funnyNote.doOppStuff) {
                // if the note has a 0ms distance (is on top of the current note), kill it
                if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
                  PlayState.instance?.invalidateNote(doubleNote);
                else if (doubleNote.strumTime < funnyNote.strumTime)
                {
                  // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
                  funnyNote = doubleNote;
                }
              }
              else PlayState.instance?.goodNoteHit(doubleNote); //otherwise, hit doubleNote instead of killing it
            }
            PlayState.instance?.goodNoteHit(funnyNote);
            if (plrInputNotes.length > 2 && ClientPrefs.data.ezSpam) {
              for (i in 1...plrInputNotes.length) PlayState.instance?.goodNoteHit(plrInputNotes[i]);
            }
          }
          else {
            MegaManager.scriptManager.callOnScripts('onGhostTap', [direction]);
            if (canMiss) PlayState.instance?.noteMissPress(direction);
          }

          var spr:StrumNote = playerStrums.getByColumn(direction);
          if(strumsBlocked[direction] != true && spr != null && spr.animation != null && spr.animation.curAnim.name != 'confirm')
          {
            spr.playAnim('pressed');
            spr.resetAnim = 0;
          }

          // Optimize keysPressed tracking with Map
          keysPressedSet[direction] = true;
          if(!keysPressed.contains(direction))
            keysPressed.push(direction);


          // Final script callback - only if scripts exist
          if (MegaManager.scriptManager.hasLuaScripts || MegaManager.scriptManager.hasHScripts) {
            MegaManager.scriptManager.callOnScripts('onKeyPress', [direction]);
          }
				}
			}
		} else {
			if (direction != -1) keyReleased(direction);
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
					if (key != -1) keyPressed(key);
				}
			}
			else {
				if (PlayState.instance?.paused || !PlayState.instance?.startedCountdown || PlayState.instance?.inCutscene) return;
				if (pressed.contains(eventKey)) return;
				pressed.push(eventKey);
        if (MusicBeatState.getState() == PlayState.instance)
          if (MegaManager.scriptManager.callOnScripts("onKeyDown", [event]) == LuaUtils.Function_Stop) return;

				if (key > -1)
				{
					if (APInfo.inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("BF's Mic"))
            return;

          @:privateAccess
          if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || PlayState.instance?.paused || PlayState.instance?.inCutscene || key < 0 || key >= playerStrums.length || !PlayState.instance?.generatedMusic || PlayState.instance?.endingSong) return;
          if (strumsBlocked[key]) return;

          // Early script callback optimization - only call if scripts exist
          if (PlayState.instance?.hasLuaScripts || PlayState.instance?.hasHScripts) {
            if (MusicBeatState.getState() == PlayState.instance) {
              var ret:Dynamic = MegaManager.scriptManager.callOnScripts('onKeyPressPre', [key]);
              if(ret == LuaUtils.Function_Stop) return;
            }
          }

          //more accurate hit time for the ratings?
          var lastTime:Float = MegaManager.conductor.musicPosition;
          var canMiss:Bool = !ClientPrefs.data.ghostTapping;

          // obtain notes that the player can hit
          var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
            var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
            // trace('[keyPressed] Note? ${n != null}, noteData=${n.noteData}, strumTime=${n.strumTime}, canHit=$canHit, mustPress=${n.mustPress}, tooLate=${n.tooLate}, wasGoodHit=${n.wasGoodHit}, Conductor=${Conductor.songPosition}');
            return n != null && n.exists && canHit && !n.isSustainNote && n.noteData == key;
          });
          plrInputNotes.sort(PlayState.sortHitNotes);

          if (plrInputNotes.length != 0) {
            var funnyNote:Note = plrInputNotes[0]; // front note

            if (plrInputNotes.length > 1) {
              var doubleNote:Note = plrInputNotes[1];

              //if the note has the same notedata and doOppStuff indicator as funnynote, then do the check
              if (doubleNote.noteData == funnyNote.noteData && doubleNote.doOppStuff == funnyNote.doOppStuff) {
                // if the note has a 0ms distance (is on top of the current note), kill it
                if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
                  PlayState.instance?.invalidateNote(doubleNote);
                else if (doubleNote.strumTime < funnyNote.strumTime)
                {
                  // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
                  funnyNote = doubleNote;
                }
              }
              else PlayState.instance?.goodNoteHit(doubleNote); //otherwise, hit doubleNote instead of killing it
            }
            PlayState.instance?.goodNoteHit(funnyNote);
            if (plrInputNotes.length > 2 && ClientPrefs.data.ezSpam) {
              for (i in 1...plrInputNotes.length) PlayState.instance?.goodNoteHit(plrInputNotes[i]);
            }
          }
          else {
            MegaManager.scriptManager.callOnScripts('onGhostTap', [key]);
            if (canMiss) PlayState.instance?.noteMissPress(key);
          }

          var spr:StrumNote = playerStrums.getByColumn(key);
          if(strumsBlocked[key] != true && spr != null && spr.animation != null && spr.animation.curAnim.name != 'confirm')
          {
            spr.playAnim('pressed');
            spr.resetAnim = 0;
          }

          // Optimize keysPressed tracking with Map
          keysPressedSet[key] = true;
          if(!keysPressed.contains(key))
            keysPressed.push(key);


          // Final script callback - only if scripts exist
          if (PlayState.instance?.hasLuaScripts || PlayState.instance?.hasHScripts) {
            if (MusicBeatState.getState() == PlayState.instance)
              MegaManager.scriptManager.callOnScripts('onKeyPress', [key]);
          }
				}
			}
		} else {
			if (pressed.contains(eventKey))
				pressed.remove(eventKey);

			if (key != -1) keyReleased(key);
		}
	}

	private function keyReleased(key:Int)
	{
		if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || !PlayState.instance?.startedCountdown || PlayState.instance?.paused || key < 0 || key >= playerStrums.length) return;

    if (MusicBeatState.getState() == PlayState.instance) {
      var ret:Dynamic = MegaManager.scriptManager.callOnScripts('onKeyReleasePre', [key]);
  		if(ret == LuaUtils.Function_Stop) return;
    }

		var spr:StrumNote = playerStrums.getByColumn(key);
		if (spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
    if (MusicBeatState.getState() == PlayState.instance)
      MegaManager.scriptManager.callOnScripts('onKeyRelease', [key]);
	}

  // TODO: Find a better way to do this so that Both Play and Opponent Mode can be accounted for
	public static function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
			for (i in 0...keysArray[ExtraKeys.mania].length)
				for (j in 0...keysArray[ExtraKeys.mania][i].length)
					if (key == keysArray[ExtraKeys.mania][i][j])
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

			var keyArrayLength = keysArray[ExtraKeys.mania].length;
			holdArray.resize(keyArrayLength);
			pressArray.resize(keyArrayLength);
			releaseArray.resize(keyArrayLength);

			// Use direct indexing instead of push
			for (i in 0...keyArrayLength) {
				var key = keysArray[ExtraKeys.mania][i];
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
								onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[ExtraKeys.mania][i][0]));
						}
					}
				}
			}
		}
	}

  public function spawnHoldSplashOnNote(note:Note, ?isDad:Bool = false) {
		if (!ClientPrefs.data.noteSplashes || note == null || !note.alive)
			return;

		splashesPerFrame[(isDad ? 2 : 3)] += 1;

		if (note != null) {
			var strum:StrumNote = (isDad ? playerStrums : opponentStrums).getByColumn(note.noteData);
			final susLength:Float = (!note.isSustainNote ? note.sustainLength : note.parentSL);
			final tailLength:Int = Math.floor(susLength / Conductor.stepCrochet);

			if(strum != null && tailLength != 0)
				spawnHoldSplash(note);
		}
	}

	public function spawnHoldSplash(note:Note) {
		var end:Note = note;
		var splash:SustainSplash = grpHoldSplashes.recycle(SustainSplash);
    final playbackRate:Float = ClientPrefs.getGameplaySetting('songspeed');
		splash.setupSusSplash((note.mustPress ? playerStrums : opponentStrums).getByColumn(note.noteData), note, playbackRate);
		grpHoldSplashes.add(end.noteHoldSplash = splash);
	}

	public function spawnNoteSplashOnNote(note:Note, ?isDad:Bool) {
		if(ClientPrefs.data.noteSplashes && note != null) {
			splashesPerFrame[(isDad ? 0 : 1)] += 1;
			final strum:Strumline = !isDad ? playerStrums : opponentStrums;
			if(strum != null)
				strum.constructNoteSplash(note.noteData);
		}
	}

  //General
  public function resetFields() {
    unspawnNotes = [];
    curChart = [];

    // cleanup
    isModchartSong = true;
    modchartEventHandler = null;
    if (allStrumSprites != null)
    {
      allStrumSprites.clear();
      allStrumSprites.visible = false;
      remove(allStrumSprites);
    }

    if (customZspritesGroup != null)
    {
      customZspritesGroup.clear();
      customZspritesGroup.visible = false;
      remove(customZspritesGroup);
    }

    // Clear strum note references
		if (playerStrums != null) {
			playerStrums.strumLineNotes.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			playerStrums.clear();
		}

		if (opponentStrums != null) {
			opponentStrums.strumLineNotes.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			opponentStrums.clear();
		}

		if (allStrumLines != null) {
      for (strum in allStrumLines) {
				if (strum != null)
          strum.destroy();
			}
			allStrumLines.clear();
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

    ExtraKeys.mania = 3;
    generatedChart = false;
    noteTypes = [];
    curSong = "";
    songSpeed = 1;
    songSpeedType = "multiplicative";
    noteRows = [[],[]];
    freezeNotes = false;
    localFreezeNotes = false;
    skipArrowStartTween = false;

    if (notes != null) {
      notes.destroy();
      notes = new FlxTypedGroup<Note>();
    }

    manualInputChecks = false;
  }

  public function resetChartStuff() { //Specifically for preload stuff
    unspawnNotes = [];
    curChart = [];

    if (notes != null) {
      notes.destroy();
      notes = new FlxTypedGroup<Note>();
    }

    // Clear event and callback references
		if (eventNotes != null) {
			eventNotes.splice(0, eventNotes.length);
		}

		if (curEvents != null) {
			curEvents.splice(0, curEvents.length);
		}

    ExtraKeys.mania = 3;
    noteTypes = [];
    eventsPushed = [];
    generatedChart = false;
    curSong = "";
    songName = "";
    songSpeed = 1;
    songSpeedType = "multiplicative";
    noteRows = [[],[]];
  }

  public function killDaNotes()
	{
		for (group in [notes, sustainNotes]){
			if (group != null){
				while (group.length > 0) {
					group.remove(group.members[0], true);
				}
			}
		}

		unspawnNotes = [];
		eventNotes = [];
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
    MegaManager.scriptManager.callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
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

      case 'Change Note Multiplier':
				var noteMultiplier:Float = Std.parseFloat(event.value1);
				if (Math.isNaN(noteMultiplier))
					noteMultiplier = 1;

				multiChangeEvents[0].push(event.strumTime);
				multiChangeEvents[1].push(noteMultiplier);
		}
    @:privateAccess
		if (MusicBeatState.getState() == PlayState.instance)
      PlayState.instance?.stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
    var returnedValue:Null<Float> = MegaManager.scriptManager.callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
    if(returnedValue != null && returnedValue != 0) {
      return returnedValue;
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
    if (!manualInputChecks) keysCheck();
    updateHazModchartSystem(elapsed);
  }

  function initHazardModchart():Void
  {
    if (isModchartSong)
    {
      customZspritesGroup = new FlxTypedSpriteGroup<ZSprite>();
      customZspritesGroup.zIndex = -500;
      customZspritesGroup.cameras = [camNotes];
      add(customZspritesGroup);

      allStrumSprites = new FlxTypedSpriteGroup<ZSprite>();

      allStrumSprites.zIndex = 69;
      allStrumSprites.cameras = [camNotes];
      add(allStrumSprites);
      allStrumSprites.visible = false;
      allStrumSprites.active = false;
    }
  }

  /* Call this to construct a newStrumLine!
    * @param playerControlled If true, then the player can control this strumLine
    * @param noteStyle The notestyle this new strumline should use.
    */
  public function constructNewStrumLine(playerControlled:Bool, ?noteStyleName:String):Strumline
  {
    final strumLine:FlxPoint = FlxPoint.get(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, (ClientPrefs.data.downScroll) ? FlxG.height - 150 : 50);

    var newStrummer:Strumline = new Strumline({strumlinePos: strumLine, player: allStrumLines.length}, playerControlled ? !cpuControlled : false, songSpeed, isModchartSong);
    newStrummer.onNoteIncoming.add(onStrumlineNoteIncoming);
    newStrummer.defaultPlayerControl = playerControlled;
    add(newStrummer);

    // Create in center of the screen
    //newStrummer.x = (FlxG.width / 2 - newStrummer.width / 2) + 0;
    newStrummer.heightWas = newStrummer.height;
    newStrummer.y = getStrumlineY(newStrummer);

    newStrummer.zIndex = 1003 + allStrumLines.length + 1;
    newStrummer.cameras = playerStrums.cameras;

    newStrummer.mods.customTweenerName = "plr" + Std.string(allStrumLines.length + 1);

    customStrumLines.push(newStrummer);
    allStrumLines.push(newStrummer);

    return newStrummer;
  }

  // Tired of constantly changing the 'strumline.y' everywhere so it can now just be changed here. Awesome. -Haz

  public static function getStrumlineY(strummy:Strumline, invertDownscrollCheck:Bool = false):Float
  {
    var isDownscroll:Bool = ClientPrefs.data.downScroll;
    if (invertDownscrollCheck)
    {
      isDownscroll = !ClientPrefs.data.downScroll;
    }
    return
      0
      + (
        isDownscroll ? FlxG.height
        - strummy.heightWas
        - Constants.STRUMLINE_Y_OFFSET
        - 0
        : Constants.STRUMLINE_Y_OFFSET);
  }

  /**
   * Constructs the strumlines for each player.
   */
  function initStrumlines():Void
  {
    final strumLine:FlxPoint = FlxPoint.get(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, (ClientPrefs.data.downScroll) ? FlxG.height - 150 : 50);

    playerStrums = new Strumline({strumlinePos: strumLine, player: 0}, !cpuControlled, songSpeed, isModchartSong);
    playerStrums.onNoteIncoming.add(onStrumlineNoteIncoming);
    playerStrums.defaultPlayerControl = true;
    opponentStrums = new Strumline({strumlinePos: strumLine, player: 1}, false, songSpeed, isModchartSong);
    opponentStrums.onNoteIncoming.add(onStrumlineNoteIncoming);
    opponentStrums.defaultPlayerControl = false;
    add(playerStrums);
    add(opponentStrums);

    final cutoutSize = ScaleMode.gameCutoutSize.x / 2.5;

    allStrumLines = [playerStrums, opponentStrums];

    // Position the player strumline on the right half of the screen
    //playerStrums.x = FlxG.width / 2 + Constants.STRUMLINE_X_OFFSET + noteStyle.getInitialStrumlineOffsets()[0] + (cutoutSize / 2.0); // Classic style
    // playerStrums.x = FlxG.width - playerStrums.width - Constants.STRUMLINE_X_OFFSET; // Centered style
    playerStrums.heightWas = playerStrums.height;
    playerStrums.y = getStrumlineY(playerStrums);

    playerStrums.zIndex = 1001;
    playerStrums.cameras = [PlayState.instance?.camHUD];

    // Position the opponent strumline on the left half of the screen
    //opponentStrums.x = Constants.STRUMLINE_X_OFFSET + noteStyle.getInitialStrumlineOffsets()[0] + (cutoutSize / 2.0);
    opponentStrums.heightWas = opponentStrums.height;
    opponentStrums.y = getStrumlineY(opponentStrums);

    opponentStrums.zIndex = 1000;
    opponentStrums.cameras = [PlayState.instance?.camHUD];

    if (isModchartSong)
    {
      if (opponentStrums.mods != null) {
        opponentStrums.mods.customTweenerName = "opponent";
      }
      if (playerStrums.mods != null) {
        playerStrums.mods.customTweenerName = "player";
      }
      opponentStrums.cameras = [camNotes];
      playerStrums.cameras = [camNotes];

      modchartEventHandler = new ModEventHandler();
      customStrumLines = [];

      MegaManager.scriptManager.callOnScripts('setUp');

      for (strumLine in allStrumLines)
      {
        if (!strumLine.defaultPlayerControl)
        {
          if (strumLine.mods != null)
            strumLine.mods.invertValues = modchartEventHandler.invertForOpponent;
        }
      }

      modchartEventHandler.setupEvents();
      setUpModTXT();

      MegaManager.scriptManager.callOnScripts('resetModchart');
    }

    for (customStrummer in customStrumLines)
    {
      customStrummer.fadeInArrows();
    }
    playerStrums.fadeInArrows();
    opponentStrums.fadeInArrows();
  }

  function onStrumlineNoteIncoming(noteSprite:Note):Void
  {
    MegaManager.scriptManager.callOnScripts('onSpawnNote', [noteSprite]);
    trace("Spawned Note!");
  }

  function add(obj:FlxBasic) {
    MusicBeatState.getState().add(obj);
  }

  function remove(obj:FlxBasic) {
    MusicBeatState.getState().remove(obj);
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
