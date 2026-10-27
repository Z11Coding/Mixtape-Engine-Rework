package objects.notes;

import backend.funkin.util.GRhythmUtil;
import backend.funkin.util.SortUtil;
import backend.modchartSystem.HazardArrowpath;
import backend.modchartSystem.ModConstants;
import backend.modchartSystem.ModHandler;
import backend.modchartSystem.NoteData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSort;
import managers.PlayfieldManager;
import objects.funkin.graphics.FunkinSprite;
import objects.funkin.graphics.ZSprite;
import objects.notes.Note;
import objects.notes.NoteSplash;
import objects.notes.SustainSplash;
import objects.notes.SustainTrail;

using backend.funkin.util.tools.ArraySortTools;
using thx.Arrays;

/**
 * A group of sprites which handles the receptor, the note splashes, and the notes (with sustains) for a given player.
 */
class Strumline extends FlxSpriteGroup
{
  var renderDistanceMs(get, never):Float;

   /**
   * A magic number for the size of the strumline, in pixels.
   */
  public static final STRUMLINE_SIZE:Int = 104;

  /**
   * The spacing between notes on the strumline, in pixels.
   */
  public static final NOTE_SPACING:Int = STRUMLINE_SIZE + 8;

  /**
   * The custom render distance for the strumline.
   * This should be in miliseconds only! Not pixels.
   */
  public var customRenderDistanceMs:Float = 0.0;

  /**
   * Whether to use the custom render distance.
   * If false, the render distance will be calculated based on the screen height.
   */
  public var useCustomRenderDistance:Bool = false;

  function get_renderDistanceMs():Float
  {
    if (useCustomRenderDistance) return customRenderDistanceMs;
    // Only divide by lower scroll speeds to fix renderDistance being too short.
    // Dividing by higher scroll speeds breaks the input system by hitting later notes first!
    return FlxG.height / Constants.PIXELS_PER_MS / (scrollSpeed < 1 ? scrollSpeed : 1);
  }

  /**
   * The thingy used to control modifiers.
   */
  public var mods:ModHandler;

  // The name of the arrowPath file name to use in shared.
  public var arrowPathFileName:String = "NOTE_ArrowPath";
  // If set to true, this strumline will just be set to do the bare minimum work for performance.
  public var asleep(default, set):Bool = false;

  private var wasDebugVisible:Bool = false;

  // if true, will automatically hide this strumline when set to sleep!
  public var hideOnSleep:Bool = true;

  function set_asleep(value:Bool):Bool
  {
    wasDebugVisible = txtActiveMods.visible;
    asleep = value;
    if (hideOnSleep)
    {
      this.visible = !asleep;
      if (!value) txtActiveMods.visible = wasDebugVisible;
    }
    this.update(0);
    return asleep;
  }

  public function requestMeshCullUpdateForPaths():Void
  {
    arrowPaths.forEach(function(note:SustainTrail)
    {
      note.cullMode = note.whichStrumNote?.strumExtraModData?.cullModeArrowpath ?? "none";
    });
  }

  public function requestMeshCullUpdateForNotes(forNotes:Bool = false):Void
  {
    if (forNotes)
    {
      for (note in notes.members)
      {
        if (note != null)
        {
          var c:String = note.noteModData?.whichStrumNote?.strumExtraModData?.cullModeNotes ?? "none";
          note.cullMode = c;
        }
      }
      for (note in notesVwoosh.members)
      {
        if (note != null)
        {
          var c:String = note.noteModData?.whichStrumNote?.strumExtraModData?.cullModeNotes ?? "none";
          note.cullMode = c;
        }
      }
    }
    else
    {
      for (note in sustainNotes.members)
      {
        if (note != null && note.alive) note.cullMode = note.whichStrumNote?.strumExtraModData?.cullModeSustain ?? "none";
      }
      for (note in sustainNotesVwoosh.members)
      {
        if (note != null && note.alive) note.cullMode = note.whichStrumNote?.strumExtraModData?.cullModeSustain ?? "none";
      }
    }
  }

  public var arrowPaths:FlxTypedSpriteGroup<SustainTrail>;

  var notitgPaths:Array<HazardArrowpath> = [];
  var notitgPathSprite:ZSprite;

  public var sustainGraphicWidth:Null<Float> = null;
  // when set to true, arrowpath will be like NotITG. Will require different values for size
  public var notitgStyledPath:Bool = false;

  var notitgPath:HazardArrowpath;

  /* Whether to play note splashes or not
   * TODO: Make this a setting!
   * IE: Settings.noSplash
   */
  public var showNotesplash:Bool = true;

  /**
   * Whether this strumline is controlled by the player's inputs.
   * False means it's controlled by the opponent or Bot Play.
   * For WITF, this variable exists just for script parity with base game.
   * For Mixtape, it's just here for compatibility lmao
   */
  public var isPlayer(get, default):Bool;
  function get_isPlayer():Bool
  {
    return playerNum == 1; // Make sure its the player position
  }

  /**
   * Which player this strum belongs to.
   * 0 = Player, 1 = Opponent, anything higher is deemed custom.
   * For WITF, this variable decides what effect goes to what strum.
   * For Mixtape, this determins weither to count it as a player hit, opponent hit, a custom hit, or to ignore it
   */
  public var playerNum:Int;

  /**
   * Whether this strumline is controlled by the player's inputs.
   * False means it's controlled by the opponent.
   * This variable is used over the vanilla "isPlayer" variable!
   */
  public var isPlayerControlled(default, set):Bool;

  function set_isPlayerControlled(value:Bool):Bool
  {
    debugNeedsUpdate = true;
    isPlayerControlled = value;
    return isPlayerControlled;
  }

  // isPlayedControlled is set back to this value when reseting
  public var defaultPlayerControl:Bool = false;

  /**
   * Usually you want to keep this as is, but if you are using a Strumline and
   * playing a sound that has it's own conductor, set this (LatencyState for example)
   */
  public var conductorInUse(get, set):RConductor;

  // Used in-game to control the scroll speed within a song
  public var scrollSpeed(default, set):Float = 1.0;

  function set_scrollSpeed(value:Float):Float
  {
    debugNeedsUpdate = true;
    return scrollSpeed = value;
  }

  /**
   * Reset the scroll speed to the current chart's scroll speed.
   */
  public function resetScrollSpeed(?newScrollSpeed:Float):Void
  {
    scrollSpeed = newScrollSpeed ?? MegaManager.playfield?.songSpeed ?? 1.0;
  }

  var _conductorInUse:Null<RConductor>;

  function get_conductorInUse():RConductor
  {
    if (_conductorInUse == null) return MegaManager.conductor;
    return _conductorInUse;
  }

  function set_conductorInUse(value:RConductor):RConductor
  {
    return _conductorInUse = value;
  }

  /**
   * Whether the game should auto position notes.
   */
  public var customPositionData:Bool = true;

  /**
   * The notes currently being rendered on the strumline.
   * This group iterates over this every frame to update note positions.
   * The PlayState also iterates over this to calculate user inputs.
   */
  public var notes:FlxTypedSpriteGroup<Note>;

  /**
   * The sustain notes currently being rendered on the strumline.
   * This group iterates over this every frame to update sustain note positions.
   * The PlayState also iterates over this to calculate user inputs.
   */
  public var sustainNotes:FlxTypedSpriteGroup<SustainNote>;

  /**
   * A signal that is dispatched when a note is spawned and heading towards the strumline.
   */
  public var onNoteIncoming:FlxTypedSignal<FlxSprite->Void>;

  var background:FunkinSprite;

  /**
   * The strumline notes (the receptors) themselves.
   */
  public var strumLineNotes:FlxTypedSpriteGroup<StrumNote>;

  /**
   * Note Splashes
   */
  public var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;

  /**
   * Hold note covers.
   */
  public var holdSplashes:FlxTypedSpriteGroup<SustainSplash>;

  /**
   * The notes that "Vwoosh" off screen when restarting.
   */
  public var notesVwoosh:FlxTypedSpriteGroup<Note>;

  public var sustainNotesVwoosh:FlxTypedSpriteGroup<SustainNote>;

  var noteSpacingScale:Float = 0.7;

  /**
   * The scale of the strumline. Use this to resize it rather than setting the scale directly.
   */
  public var strumlineScale(default, null):FlxPoint;

  var ghostTapTimer:Float = 0.0;

  /**
   * Whether the strumline is downscroll.
   */
  public var isDownscroll:Bool = ClientPrefs.data.downScroll;

  /**
   * The note data for the song. Should NOT be altered after the song starts (but we alter it in OffsetState :DDD),
   * so we can easily rewind.
   */
  public var unspawnNotes:Array<PreloadNotes> = [];

  /**
   * The index of the next note to be rendered.
   * This is used to avoid splicing the noteData array, which is slow.
   * It is incremented every time a note is rendered.
   */
  public var nextNoteIndex:Int = -1;

  /**
   * Indicates which keys are pressed for which directions.
   * The direction is pressed as long as at least one key is held,
   * and released when no keys are held.
   */
  var heldKeys:Array<Array<Int>>;

  static final BACKGROUND_PAD:Int = 16;

  public static final INITIAL_OFFSET:Float = -0.275 * STRUMLINE_SIZE;
  public static final NUDGE:Float = 2.0;
  static final NOTE_SPLASH_CAP:Int = 6;


  // JS-Engine stuff
  var noteLimit:Int = ClientPrefs.data.maxNotes == 0 ? 2147483647 : ClientPrefs.data.maxNotes;
	public var renderedTxt:FlxText;
	var limitNC = 0;
	public var amountOfRenderedNotes:Float = 0;
	public var maxRenderedNotes:Float = 0;
	public var skippedCount:Float = 0;
	public var maxSkipped:Float = 0;
  var notesAddedCount:Int = 0;

  /**
   * For a note's strumTime, calculate its Y position relative to the strumline.
   * NOTE: Assumes Conductor and PlayState are both initialized.
   * NOTE 2: While this function was removed in FNF V0.7, it remains for WITF to function properly. It also uses songPosition instead of songPositionWithDelta.
   * @param strumTime The strumtime of the note.
   * @return The Y position of the note.
   */
  public function calculateNoteYPos(strumTime:Float):Float
  {
    #if FEATURE_WITF_USE_TIME_DELTA
    return GRhythmUtil.getNoteY(strumTime, scrollSpeed, isDownscroll, conductorInUse);
    #else
    return Constants.PIXELS_PER_MS * (conductorInUse.musicPosition - strumTime) * scrollSpeed * (isDownscroll ? 1 : -1);
    #end
  }

  function arrowPathSetup():Void
  {
    this.arrowPaths = new FlxTypedSpriteGroup<SustainTrail>();
    this.arrowPaths.zIndex = 6;
    this.add(this.arrowPaths);

    notitgPathSprite = new ZSprite();
    notitgPathSprite.x = 0;
    notitgPathSprite.y = 0;
    notitgPathSprite.zIndex = 6;
    notitgPathSprite.visible = false;
    this.add(notitgPathSprite);
  }

  function setupNoteGroup(groupStr:String, index:Int)
  {
    var group:Dynamic;
    switch (groupStr)
    {
      case "sustainNotesVwoosh":
        group = new FlxTypedSpriteGroup<SustainNote>();
        this.sustainNotesVwoosh = group;
      case "sustainNotes":
        group = new FlxTypedSpriteGroup<SustainNote>();
        this.sustainNotes = group;
      case "notesVwoosh":
        group = new FlxTypedSpriteGroup<Note>();
        this.notesVwoosh = group;
      case "notes":
        group = new FlxTypedSpriteGroup<Note>();
        this.notes = group;
      case "strumLineNotes":
        group = new FlxTypedSpriteGroup<StrumNote>();
        this.strumLineNotes = group;
      case "holdSplashes":
        group = new FlxTypedSpriteGroup<SustainSplash>(0, 0, 4);
        this.holdSplashes = group;
      case "noteSplashes":
        var splash:NoteSplash = new NoteSplash(100, 100, 0);
        group = new FlxTypedSpriteGroup<NoteSplash>(0, 0, NOTE_SPLASH_CAP);
        this.noteSplashes = group;
        noteSplashes.add(splash);
        splash.alpha = 0.0001;
      default:
        return null;
    }
    group.zIndex = index;
    this.add(group);
    return group;
  }

  public var noteSkin:String = Paths.defaultSkin;
  public var StrumlineObj:StrumlineObj = null;

  public function new(strumlineObj:StrumlineObj, ?isPlayer:Bool, ?scrollSpeed:Float, ?modchartSong:Bool = false)
  {
    super();

    this.playerNum = strumlineObj.player;
    this.isPlayer = isPlayer;
    this.isPlayerControlled = isPlayer;
    this.defaultPlayerControl = isPlayer;
    this.StrumlineObj = strumlineObj;

    var holdsBehindStrums:Bool = false;
    var holdCoversBehindStrums:Bool = false;

    if (modchartSong)
    {
      arrowPathSetup();
    }

    if (holdsBehindStrums)
    {
      setupNoteGroup("sustainNotes", 8);
      setupNoteGroup("sustainNotesVwoosh", 9);
    }

    if (holdCoversBehindStrums)
    {
      setupNoteGroup("holdSplashes", 10);
    }
    setupNoteGroup("strumLineNotes", 11);

    if (!holdsBehindStrums)
    {
      setupNoteGroup("sustainNotes", 20);
      setupNoteGroup("sustainNotesVwoosh", 21);
    }

    setupNoteGroup("notes", 30);
    setupNoteGroup("notesVwoosh", 31);

    if (!holdCoversBehindStrums)
    {
      setupNoteGroup("holdSplashes", 40);
    }

    setupNoteGroup("noteSplashes", 50);

    if (modchartSong)
    {
      setupModStuff();
    }
    else
    { // Fuckin, background won't work when the notes go all over the screen!!! Wasn't expecting this to be a feature, but it won't be supported.
      var backgroundWidth:Float = (ExtraKeys.mania+1) * (Strumline.NOTE_SPACING/ExtraKeys.xPosButBetter2[ExtraKeys.mania]) + BACKGROUND_PAD * 2;
      this.background = new FunkinSprite(0, 0).makeSolidColor(Std.int(backgroundWidth), FlxG.height, 0xFF000000);
      // Convert the percent to a number between 0 and 1.
      this.background.alpha = ClientPrefs.data.strumlineBackgroundOpacity / 100.0;
      this.background.scrollFactor.set(0, 0);
      this.background.x = this.x + backgroundWidth + 240;
      this.add(this.background);
    }
    strumlineScale = new FlxCallbackPoint(strumlineScaleCallback);

    this.refresh();

    this.onNoteIncoming = new FlxTypedSignal<FlxSprite->Void>();
    resetScrollSpeed(scrollSpeed);

    /*for (i in 0...(ExtraKeys.mania+1))
    {
      var child:StrumNote = new StrumNote(strumlineObj.strumlinePos.x, strumlineObj.strumlinePos.y, i, strumlineObj.player);
      child.downScroll = ClientPrefs.data.downScroll;

      this.strumLineNotes.add(child);
      this.strumLineNotesAlt.push(child);

      child.weBelongTo = this;
    }*/

    generateStaticArrows();

    this.heldKeys = [];
    for (i in 0...(ExtraKeys.mania+1))
    {
      this.heldKeys[i] = [];
    }

    strumlineScale.set(1, 1);

    // This MUST be true for children to update!
    this.active = true;

  }

  override function set_y(value:Float):Float
  {
    super.set_y(value);

    // Keep the background on the screen.
    if (this.background != null) this.background.y = 0;

    return value;
  }

  override function set_alpha(value:Float):Float
  {
    super.set_alpha(value);

    if (this.background != null) this.background.alpha = ClientPrefs.data.strumlineBackgroundOpacity / 100.0 * alpha;

    return value;
  }

  public function generateStaticArrows():Void
	{
    #if ALLOW_DEPRECATION
    MegaManager.scriptManager.callOnScripts('prePlayerReceptorGeneration'); // backwards compat, deprecated
    #end
    MegaManager.scriptManager.callOnScripts('onPlayerReceptorGeneration');

		final strumLine:FlxPoint = FlxPoint.get(ClientPrefs.data.middleScroll ? PlayfieldManager.STRUM_X_MIDDLESCROLL : PlayfieldManager.STRUM_X, (ClientPrefs.data.downScroll) ? FlxG.height - 150 : 50);
		for (i in 0...(ExtraKeys.mania+1))
		{
			var targetAlpha:Float = 1;
			if (playerNum == 0)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = ClientPrefs.data.oppNoteAlpha;
			}

			var babyArrow:StrumNote = new StrumNote(strumLine.x, strumLine.y, i, playerNum);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!MegaManager.playfield.skipArrowStartTween && !MegaManager.playfield.isModchartSong)
			{
				babyArrow.y -= 150;
				babyArrow.alpha = 0;
				babyArrow.angle = 360;
        final playbackRate:Float = ClientPrefs.getGameplaySetting('songspeed');
			}
			else if (!MegaManager.playfield.skipArrowStartTween && MegaManager.playfield.isModchartSong) {
        babyArrow.alpha = 0;
      }
      else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (playerNum == 1) {
        // Do nothing and win
      } else {
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}

			this.strumLineNotes.add(babyArrow);
			this.strumLineNotesAlt.push(babyArrow);
			babyArrow.weBelongTo = this;
			babyArrow.postAddedToGroup();
		}
    #if ALLOW_DEPRECATION
    MusicBeatState.getState()?.callOnScripts('postPlayerReceptorGeneration'); // deprecated
    #end
    MusicBeatState.getState()?.callOnScripts('onPlayerReceptorGenerationPost');

		strumLine.put();
    trace("Finished Note Generation!");
	}

  public function setupModStuff():Void
  {
    if (mods == null)
    {
      this.mods = new ModHandler(!defaultPlayerControl);
      this.mods.strum = this;
    }

    if (this.txtActiveMods == null)
    {
      this.txtActiveMods = new FlxText(this.x, this.y, 0, 'wtf');
      this.txtActiveMods.borderStyle = FlxTextBorderStyle.OUTLINE;
      this.txtActiveMods.borderColor = FlxColor.BLACK;
      this.txtActiveMods.alignment = FlxTextAlign.CENTER;
      this.txtActiveMods.borderSize = 2;
      this.txtActiveMods.x += (1.5 * (Strumline.NOTE_SPACING/ExtraKeys.xPosButBetter2[ExtraKeys.mania]));
      this.txtActiveMods.zIndex = 66;
      this.add(this.txtActiveMods);
    }
  }

  /**
   * Refresh the strumline, sorting its children by z-index.
   */
  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  override function get_width():Float
  {
    if (strumlineScale == null) strumlineScale = new FlxCallbackPoint(strumlineScaleCallback);

    return (ExtraKeys.mania+1) * (Strumline.NOTE_SPACING/ExtraKeys.xPosButBetter2[ExtraKeys.mania]) * noteSpacingScale * strumlineScale.x;
  }

  // This can be changed to make the arrowpath segment into smaller chunks, making it less likely to memory leak when really long and detailed
  public var pathPieces:Int = 3;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (asleep) return;

    if (mods != null)
    {
      if (!generatedArrowPaths && drawArrowPaths)
      {
        notitgPaths = [];
        notitgPath = new HazardArrowpath(this);
        notitgPathSprite.loadGraphic(notitgPath.bitmap);

        // clear the old
        arrowPaths.forEach(function(note:SustainTrail)
        {
          arrowPaths.remove(note);
          note.destroy();
        });

        for (i in 0...(ExtraKeys.mania+1))
        {
          var prev:SustainTrail = null;
          for (p in 0...pathPieces)
          {
            var holdNote:SustainTrail = new SustainTrail(0, i, 1, this);
            // holdNote.makeGraphic(10, 20, FlxColor.WHITE);
            this.arrowPaths.add(holdNote);
            holdNote.weBelongTo = this;

            if (MegaManager.playfield.allStrumSprites != null && MegaManager.playfield.noteRenderMode)
            {
              MegaManager.playfield.allStrumSprites.add(holdNote);
            }

            if (prev != null)
            {
              holdNote.previousPiece = prev;
            }
            holdNote.piece = p;
            holdNote.renderEnd = (p == (pathPieces - 1));
            holdNote.parentStrumline = this;
            holdNote.noteData = null;
            holdNote.strumTime = 0;
            holdNote.noteDirection = i;

            @:privateAccess
            holdNote.tinyOffsetForSpiral = 0; // shouldn't need this cuz there shouldn't be any clipping

            var whichStrumNote:StrumNote = getByColumn(i);
            holdNote.alpha = whichStrumNote?.strumExtraModData?.arrowPathAlpha ?? 0;
            holdNote.fullSustainLength = holdNote.sustainLength =
              whichStrumNote.strumExtraModData.arrowpathLength
              + whichStrumNote.strumExtraModData.arrowpathBackwardsLength;

            holdNote.missedNote = false;
            holdNote.hitNote = false;
            holdNote.visible = true;
            prev = holdNote;
          }
        }
        generatedArrowPaths = true;
      }

      mods.updateSpecialMods();
      mods.updateStrums();
      updateNotes();
      #if FEATURE_GHOST_TAPPING
      updateGhostTapTimer(elapsed);
      #end
      updateArrowPaths(elapsed);
      updateModDebug();
      for (cover in holdSplashes)
      {
        if (cover.alive)
        {
          noteCoverSetPos(cover);
        }
      }
      for (splash in noteSplashes)
      {
        if (splash.alive)
        {
          noteSplashSetPos(splash, splash.noteData);
        }
      }
      //updatePerspective();
    }
    else
    {
      updateNotes();
      #if FEATURE_GHOST_TAPPING
      updateGhostTapTimer(elapsed);
      #end
    }
  }

  // used for the reverse math (or any other math which needs to know the strumline position from PlayState).
  // Saved as a variable because accessing height mid-song will result in arrowpath and other stuff being included.
  public var heightWas:Float = 116;

  var generatedArrowPaths:Bool = false;

  // if set to false, will skip arrowpath update logic
  public var drawArrowPaths:Bool = true;

  function updateArrowPaths(elapsed:Float):Void
  {
    if (!generatedArrowPaths) return;
    if (!drawArrowPaths)
    {
      arrowPaths.forEach(function(note:SustainTrail)
      {
        note.visible = false;
      });
      // arrowPaths.visible = false;
      notitgPathSprite.visible = false;
      return;
    }
    // arrowPaths.visible = this.visible;

    notitgPathSprite.visible = notitgStyledPath && this.visible && notitgPath.hasVisiblePaths();
    if (notitgStyledPath)
    {
      notitgPath.update(elapsed);

      var isPixel:Bool = PlayState.isPixelStage; // dumb fucking fix lmfao
      isPixel = false;
      notitgPathSprite.x = isPixel ? -12 : 0; // temp fix lmao

      notitgPathSprite.y = 0;

      arrowPaths.forEach(function(note:SustainTrail)
      {
        note.visible = false;
      });
      return;
    }

    var stitchEnds:Bool = true;

    arrowPaths.forEach(function(note:SustainTrail)
    {
      note.x = ModConstants.holdNoteJankX;
      note.y = ModConstants.holdNoteJankY;

      note.visible = drawArrowPaths;
      // note.alpha = arrowPathAlpha[note.noteDirection];
      var whichStrumNote:StrumNote = getByColumn(note.noteDirection);
      note.alpha = whichStrumNote?.strumExtraModData?.arrowPathAlpha ?? 0;
      if (note.alpha <= 0)
      {
        note.visible = false;
        return;
      }

      // ay -= whichStrumNote.strumExtraModData.alphaHoldCoverMod;
      var length:Float = (whichStrumNote.strumExtraModData.arrowpathLength + whichStrumNote.strumExtraModData.arrowpathBackwardsLength) / (pathPieces);
      note.fullSustainLength = length;
      if (note.sustainLength != length) note.sustainLength = length;

      note.strumTime = ModConstants.getSongPosition();
      note.strumTime -= whichStrumNote?.strumExtraModData?.arrowpathBackwardsLength ?? 0;
      note.strumTime += length * note.piece;
      if (!doUpdateClipsInDraw)
      {
        note.updateClipping();

        // note.x += 112 / 2 * note.piece;

        // UH OH, SCUFFED CODE ALERT
        // We sow the end of the arrowpath to the start of the new piece. This is so that we don't have any gaps. Mainly occurs with spiral holds lol
        // MY NAME IS EDWIN
        if (note.previousPiece != null && stitchEnds)
        {
          // I made the mimic
          var v_prev:Array<Float> = note.previousPiece.vertices_array;
          var v:Array<Float> = note.vertices_array;

          // it was difficult, to put the pieces together
          v[3] = v_prev[v_prev.length - 1];
          v[2] = v_prev[v_prev.length - 2];
          v[1] = v_prev[v_prev.length - 3];
          v[0] = v_prev[v_prev.length - 4];

          // but unfortunately, something went so wrong.
          @:privateAccess
          note.setVerts(v);
        }
      }
    });
  }

  function updatePerspective():Void
  {
    if (mods == null) return;

    sortNotes();

    if (!doUpdateClipsInDraw)
    {
      if (sustainNotes?.members?.length > 0) {
        for (note in sustainNotes)
        {
          note.updateClipping();
        }
      }
    }
  }

  /**
   * Makes sustainTrails update their visuals in draw() instead of update() so that they work properly with draw funcs.
   * However, doing so will result in a desync between them and the notes by 1 frame.
   * This variable is automatically set to true when a drawFunc is applied, and false when it's null.
   */
  public var doUpdateClipsInDraw:Bool = false;

  /**
   * The FlxText which displays the current active mods
   */
  public var txtActiveMods:FlxText;

  public var hideZeroValueMods:Bool = true;
  public var hideSubMods:Bool = true;
  public var debugHideUtil:Bool = true;
  public var debugHideLane:Bool = true;
  public var debugShowALL:Bool = false;
  public var debugNeedsUpdate:Bool = true; // V0.7a -> Now no longer updates every frame! Only updates when needed. Will be further optimised later!

  function updateModDebug():Void
  {
    if (PlayState.instance == null) return;
    if (txtActiveMods.visible == false || txtActiveMods.alpha < 0) return;
    if (!debugNeedsUpdate) return;
    var newString = "-:Mods:-\n";
    if (isPlayerControlled)
    {
      if (PlayState.instance.cpuControlled)
      {
        newString += "\n";
        newString += "-BOTPLAY-";
      }
      if (PlayState.instance.practiceMode)
      {
        newString += "\n";
        newString += "-PRACTICE-";
      }
    }
    else
    {
      newString += "\n";
      newString += "-CPU-";
    }
    if (mods.invertValues)
    {
      newString += "\n";
      newString += "-INVERTED MOD VALUES-";
    }
    newString += "\n";
    // newString += "-ScrollSpeed: " + MegaManager.playfield.songSpeed + "-";
    newString += "-ScrollSpeed: " + this.scrollSpeed + "-";

    // for (mod in modifiers){
    for (mod in mods.mods_all)
    {
      var usePercentage:Bool = MegaManager.playfield.modchartEventHandler.percentageMods && !mod.notPercentage;
      var modVal = FlxMath.roundDecimal(mod.currentValue, 2);
      if (modVal == 0 && hideZeroValueMods && !debugShowALL) continue;
      // if (mod.currentValue == mod.baseValue && hideZeroValueMods && !debugShowALL) continue;

      if (usePercentage) modVal *= 100;

      if (mod.utility && debugHideUtil && !debugShowALL) continue;
      if (StringTools.contains(mod.tag, "--") && debugHideLane && !debugShowALL) continue;
      newString += "\n";
      newString += mod.tag + ": " + Std.string(modVal) + (usePercentage ? "%" : "");
      if (!hideSubMods || debugShowALL)
      {
        if (mod.modPriority_additive != 0)
        {
          newString += "\n-";
          newString += "priority" + ": " + Std.string(mod.modPriority_additive);
        }
        for (key in mod.subValues.keys())
        {
          newString += "\n-";
          newString += key + ": " + Std.string(mod.getSubVal(key));
        }
      }
    }

    // Don't update if nothing changed (?)
    if (txtActiveMods.text != newString)
    {
      txtActiveMods.text = newString;
      txtActiveMods.x = this.x;
      txtActiveMods.x += (2.0 * (Strumline.NOTE_SPACING/ExtraKeys.xPosButBetter2[ExtraKeys.mania]));
      txtActiveMods.x -= txtActiveMods.width / 2;
      // txtActiveMods.y = this.y + (ClientPrefs.data.downScroll ? -375 : 375);
      // v0.6.8a adjusted upscroll mod position to be further up the screen (like up arrow, up)
      txtActiveMods.y = this.y + (ClientPrefs.data.downScroll ? -375 : 200);

      txtActiveMods.x += mods.debugTxtOffsetX;
      txtActiveMods.y += mods.debugTxtOffsetY;
    }
    debugNeedsUpdate = false;
  }

  #if FEATURE_GHOST_TAPPING
  /**
   * @return `true` if no notes are in range of the strumline and the player can spam without penalty.
   */
  public function mayGhostTap():Bool
  {
    // Any notes in range of the strumline.
    if (getNotesMayHit().length > 0)
    {
      return false;
    }
    // Any hold notes in range of the strumline.
    if (getHoldNotesHitOrMissed().length > 0)
    {
      return false;
    }

    // Note has been hit recently.
    if (ghostTapTimer > 0.0) return false;

    // **yippee**
    return true;
  }
  #end

  /**
   * Return notes that are within `Constants.HIT_WINDOW` ms of the strumline.
   * If FEATURE_WITF_INPUTS is enabled, this array is sorted by strumTime.
   * @return An array of `Note` objects.
   */
  public function getNotesMayHit():Array<Note>
  {
    var notesInRange:Array<Note> = notes.members.filter(function(note:Note)
    {
      return note != null && note.alive && !note.wasGoodHit && note.canBeHit;
    });

    #if FEATURE_WITF_INPUTS
    return Arrays.order(notesInRange, (a, b) -> return FlxSort.byValues(-1, a.strumTime, b.strumTime));
    #else
    return notesInRange;
    #end
  }

  /**
   * Return hold notes that are within `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `SustainNote` objects.
   */
  public function getHoldNotesHitOrMissed():Array<SustainNote>
  {
    return sustainNotes.members.filter(function(holdNote:SustainNote)
    {
      return holdNote != null && holdNote.alive && (holdNote.hitNote || holdNote.missedNote);
    });
  }

  /**
   * Call this when resetting the playstate.
   */
  public function vwooshNotes():Void
  {
    var vwooshTime:Float = 0.5;

    for (note in notes.members)
    {
      if (note == null) continue;
      if (!note.alive) continue;

      notes.remove(note);
      notesVwoosh.add(note);

      note.vwooshing = true;

      var targetY:Float = FlxG.height + note.y;
      if (isDownscroll) targetY = note.y - FlxG.height;
      FlxTween.tween(note, {
        y: targetY
      }, vwooshTime, {
        ease: FlxEase.expoIn,
        onComplete: function(twn)
        {
          note.kill();
          notesVwoosh.remove(note, true);
          note.destroy();
        }
      });
    }

    for (holdNote in sustainNotes.members)
    {
      if (holdNote == null) continue;
      if (!holdNote.alive) continue;

      sustainNotes.remove(holdNote);
      sustainNotesVwoosh.add(holdNote);

      var targetY:Float = FlxG.height + holdNote.y;
      if (isDownscroll) targetY = holdNote.y - FlxG.height;
      FlxTween.tween(holdNote, {
        y: targetY
      }, vwooshTime, {
        ease: FlxEase.expoIn,
        onComplete: function(twn)
        {
          holdNote.kill();
          sustainNotesVwoosh.remove(holdNote, true);
          holdNote.destroy();
        }
      });
    }
  }

  /**
   * Enter mini mode, which displays only small strumline notes
   * @param scale scale of strumline
   */
  public function enterMiniMode(scale:Float = 1):Void
  {
    forEach(function(obj:flixel.FlxObject):Void
    {
      if (obj != strumLineNotes) obj.visible = false;
    });

    this.strumlineScale.set(scale, scale);
  }

  /**
   * Called whenever the `strumlineScale` value is updated.
   * @param Scale The new value.
   */
  function strumlineScaleCallback(scale:FlxPoint):Void
  {
    strumLineNotes.forEach(function(note:StrumNote):Void
    {
      var styleScale = 0.7;
      note.scale.set(styleScale * scale.x, styleScale * scale.y);
    });
    setNoteSpacing(noteSpacingScale);
  }

  /**
   * Set note spacing scale
   * @param multiplier multiply x position
   */
  public function setNoteSpacing(multiplier:Float = 1):Void
  {
    noteSpacingScale = multiplier;

    for (i in 0...(ExtraKeys.mania+1))
    {
      var note = getByColumn(i);
      if (note != null) {
        note.y = this.strumLineNotes.y;
        note.x = 0;
        note.postAddedToGroup();
      }
    }
  }

  public var strumLineNotesAlt:Array<StrumNote> = [];

  /**
   * Get a strumline note sprite by its index.
   * @param index The index of the note to get.
   * @return The note.
   */
  public function getByColumn(index:Int):StrumNote
  {
    if (mods != null) // Because the order of the strumLineNotes will be different thanks to us sorting on the z-axis, we need an alternative method...
    {
      return this.strumLineNotesAlt[index];
    }
    else
    {
      return this.strumLineNotes.members[index];
    }
  }

  /**
   * For a note's strumTime, calculate its Y position relative to the strumline.
   * NOTE: Assumes Conductor and PlayState are both initialized.
   * @param strumTime
   * @return Float
   * Reverse of vwooshNotes, we bring the notes IN (by their offsets)
   */
  public function vwooshInNotes():Void
  {
    var vwooshTime:Float = 0.5;

    for (note in notes.members)
    {
      if (note == null) continue;
      if (!note.alive) continue;

      note.yOffset = 200;
      if (isDownscroll)
      {
        note.yOffset = -200;
      }
      FlxTween.tween(note, {
        yOffset: 0
      }, vwooshTime, {
        ease: FlxEase.expoOut,
        onComplete: function(twn)
        {
          note.yOffset = 0;
        }
      });
    }

    for (holdNote in sustainNotes.members)
    {
      if (holdNote == null) continue;
      if (!holdNote.alive) continue;

      holdNote.yOffset = 200;
      if (isDownscroll)
      {
        holdNote.yOffset = -200;
      }
      FlxTween.tween(holdNote, {
        yOffset: 0
      }, vwooshTime, {
        ease: FlxEase.expoOut,
        onComplete: function(twn)
        {
          holdNote.yOffset = 0;
        }
      });
    }
  }

  // var dumbMagicNumberForX:Float = 24;
  // This value popped up again but as 24.6 when doing (-INITIAL_OFFSET + (STRUMLINE_SIZE / 2) - (ModConstants.strumSize/2.0)) while trying to figure out some offset stuff... coincidence? no idea
  var dumbMagicNumberForX:Float = 24.6;

  public function getNoteXOffset():Float
  {
    return dumbMagicNumberForX;
  }

  /**
   * Custom recycling behavior for note splashes.
   */
  public function constructNoteSplash(data:Int, ?splashSkin:String):NoteSplash
  {
    var splash:NoteSplash = null;

    // If we haven't filled the pool yet...
    if (noteSplashes.length < noteSplashes.maxSize)
    {
      // Recycle the first one
      splash = noteSplashes.recycle(NoteSplash);
      splash.setupNoteSplash(getByColumn(data).x, getByColumn(data).y, data, splashSkin);
      this.noteSplashes.add(splash);
      splash.weBelongTo = this;

      if (MegaManager.playfield != null)
      {
        if (MegaManager.playfield.allStrumSprites != null && MegaManager.playfield.noteRenderMode)
        {
          MegaManager.playfield.allStrumSprites.add(splash);
        }
      }
    }
    else
    {
      // Else, find a note splash which is inactive so we can revive it.
      splash = this.noteSplashes.getFirstAvailable();

      if (splash != null)
      {
        // Recycle it again
        splash = noteSplashes.recycle(NoteSplash);
        splash.setupNoteSplash(getByColumn(data).x, getByColumn(data).y, data, splashSkin);
      }
      else
      {
        // The note splash pool is full and all note splashes are active,
        // so we just pick one at random to destroy and restart.
        splash = FlxG.random.getObject(this.noteSplashes.members);
      }
    }

    if (mods != null)
      noteSplashSetPos(splash, data);

    return splash;
  }

  /**
   * Called every frame to update the position and hitbox of each child note.
   */
  public function updateNotes():Void
  {
    if (notes == null || sustainNotes == null) return; // if it's null, don't bother
    if (unspawnNotes.length + (notes?.countLiving() + sustainNotes?.countLiving()) == 0) return; // if it's empty, don't bother

    // Ensure note data gets reset if the song happens to loop.
    // NOTE: I had to remove this line because it was causing notes visible during the countdown to be placed multiple times.
    // I don't remember what bug I was trying to fix by adding this.
    // if (conductorInUse.currentStep == 0) nextNoteIndex = 0;

    var NOTE_SPAWN_TIME:Float = 0;
    var targetNote:PreloadNotes = null;
    var spawnedNote:Note;

    if (unspawnNotes[notesAddedCount] != null)
		{
			//notesAddedCount = 0;
			NOTE_SPAWN_TIME = (ClientPrefs.data.dynamicSpawnTime ? (1600 / MegaManager.playfield.songSpeed) : 1600 * ClientPrefs.data.noteSpawnTime);
			targetNote = unspawnNotes[notesAddedCount];
			limitNC = (notes?.countLiving() + sustainNotes?.countLiving());

			if (PlayState.instance.startedSong && targetNote != null && !targetNote.wasHit)
			{
				while (targetNote.strumTime <= conductorInUse.musicPosition - ClientPrefs.data.noteOffset) {
					targetNote.wasHit = true;
					targetNote.mustPress ? PlayState.instance.goodNoteHit(null, targetNote, null) : PlayState.instance.opponentNoteHit(null, targetNote, null);
					notesAddedCount++;
					if (unspawnNotes[notesAddedCount+1] != null) targetNote = unspawnNotes[notesAddedCount];
					else break;
					skippedCount++;
					if (skippedCount > maxSkipped) maxSkipped = skippedCount;
				}
			}
			if (ClientPrefs.data.showNotes || !ClientPrefs.data.showNotes && !PlayState.instance.cpuControlled)
			{
				while (limitNC < noteLimit && targetNote.strumTime - conductorInUse.musicPosition < (NOTE_SPAWN_TIME / targetNote.multSpeed)) {
          var drawDistanceForward:Float = 1;
          var drawDistanceBack:Float = 1;
           if (mods != null)
          {
            var whichStrumNote:StrumNote = getByColumn(targetNote.noteData % (ExtraKeys.mania+1));
            drawDistanceForward = 1 + (whichStrumNote?.strumExtraModData?.drawdistanceForward ?? 0);
            drawDistanceBack = 1 + (whichStrumNote?.strumExtraModData?.drawdistanceBack ?? 0);
          }
          var renderWindowStart_EDITED:Float = conductorInUse.musicPosition + (renderDistanceMs * drawDistanceForward);
          var renderWindowEnd_EDITED:Float = conductorInUse.musicPosition - (renderDistanceMs * drawDistanceBack);

          if (targetNote.strumTime > renderWindowStart_EDITED) break; // Note is too far ahead to render
          if (!PlayState.instance.startedSong && targetNote.strumTime < renderWindowEnd_EDITED) break; // Don't load expired notes during countdown

          var spawnedSprite:FlxSprite;
          if (targetNote.isSustainNote)
          {
            var spawnedSustain:SustainNote = sustainNotes.recycle(SustainNote);
            spawnedSustain.parentStrumline = this;
            spawnedSustain.setupNoteData(targetNote);
            spawnedSustain.cameras = cameras;
            spawnedSprite = spawnedSustain;
          }
          else
          {
            spawnedNote = notes.recycle(Note);
            spawnedNote.parentStrumline = this;
            spawnedNote.setupNoteData(targetNote);
            spawnedNote.cameras = cameras;
            spawnedNote.cullMode = getByColumn(targetNote.noteData)?.strumExtraModData?.cullModeNotes ?? "none";
            spawnedSprite = spawnedNote;
          }

          //trace('Note StrumTime: ${targetNote.strumTime}');
          //trace('Note wasHit: ${targetNote.wasHit}');
          //trace('Note Spawn Timing: music=${conductorInUse.musicPosition}, precise=${conductorInUse.getTimeWithDelta()}, delta=${targetNote.strumTime - conductorInUse.getTimeWithDelta()}, scrollSpeed=$scrollSpeed');

          onNoteIncoming.dispatch(spawnedSprite);
					notesAddedCount++; limitNC++;
					if (unspawnNotes[notesAddedCount+1] != null) targetNote = unspawnNotes[notesAddedCount];
					else break;
				}
			}
		}

    // Update rendering of notes.
    for (note in notes.members)
    {
      if (note == null || !note.alive) continue;
      // Set the note's position.
      if (mods != null)
      {
        mods.setNotePos(note);

        var drawDistanceBackkk:Float = 1;
        if (mods != null)
        {
          drawDistanceBackkk = 1 + (note?.noteModData?.whichStrumNote?.strumExtraModData?.drawdistanceBack ?? 0);
        }

        var renderWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS + (renderDistanceMs / 8 * drawDistanceBackkk);
        // If the note is missed
        // if desaturated, ,eisofnoaunawdabwo
        if ((note.missed || note.wasGoodHit) && conductorInUse.musicPosition >= renderWindowEnd)
        {
          killNote(note);
        }
      }
      else
      {
        // Set the note's position.
        if (!customPositionData)
        {
          var strum:StrumNote = getByColumn(note.noteData);
          if (strum != null) note.x = strum.x + note.offsetX;
        }
        if (!customPositionData) note.y =
          this.y
          - INITIAL_OFFSET
          + GRhythmUtil.getNoteY(note.strumTime, scrollSpeed, isDownscroll, conductorInUse)
          + note.yOffset;

        var timeUntilHit:Float = note.strumTime - conductorInUse.getTimeWithDelta();
        if (Math.abs(timeUntilHit) <= 20)
        {
          var strum:StrumNote = getByColumn(note.noteData);
          //trace('Note Approach: lane=${note.noteData}, timeUntilHit=$timeUntilHit, note=(${note.x}, ${note.y}, ${note.width}x${note.height}), receptor=(${strum?.x}, ${strum?.y}), screen=(${FlxG.width}x${FlxG.height}), visible=${note.visible}, alpha=${note.alpha}, HUDCamera=${note.cameras != null && note.cameras.length > 0 && note.cameras[0] == PlayState.instance?.camHUD}');
        }

        // If the note is miss
        var isOffscreen = ClientPrefs.data.downScroll ? note.y > FlxG.height : note.y < -note.height;
        if (note.missed && isOffscreen)
        {
          killNote(note);
        }
      }
    }

    // Update rendering of hold notes.
    for (holdNote in sustainNotes.members)
    {
      if (holdNote == null || !holdNote.alive) continue;
      if (mods == null && !customPositionData)
      {
        var strum:StrumNote = getByColumn(holdNote.noteData);
        if (strum != null) holdNote.x = strum.x + holdNote.offsetX;
      }

      if (conductorInUse.musicPosition > holdNote.strumTime && holdNote.hitNote && !holdNote.missedNote)
      {
        if ((isPlayerControlled && !PlayState.instance?.cpuControlled ?? false) && !isKeyHeld(holdNote.noteData))
        {
          // Stopped pressing the hold note.
          playStatic(holdNote.noteData);
          holdNote.missedNote = true;
          holdNote.visible = true;
          holdNote.alpha = 0.0; // Completely hide the dropped hold note.
        }
      }

      final magicNumberIGuess:Float = 8;

      var drawDistanceBack:Float = 1;
      if (mods != null)
      {
        drawDistanceBack = 1.0 + (holdNote?.whichStrumNote?.strumExtraModData?.drawdistanceBack ?? 0.0);
      }

      var renderWindowEnd =
        holdNote.strumTime
        + holdNote.fullSustainLength
        + Constants.HIT_WINDOW_MS
        + (renderDistanceMs / magicNumberIGuess * drawDistanceBack);

      if (holdNote.missedNote && conductorInUse.musicPosition >= renderWindowEnd)
      {
        // Hold note is offscreen, kill it.
        holdNote.visible = false;
        holdNote.kill(); // Do not destroy! Recycling is faster.
      }
      else if (holdNote.hitNote && holdNote.sustainLength <= 0)
      {
        // Hold note is completed, kill it.
        if (isKeyHeld(holdNote.noteData))
        {
          playPress(holdNote.noteData);
        }
        else
        {
          playStatic(holdNote.noteData);
        }

        if (holdNote.cover != null && isPlayerControlled)
        {
          holdNote.cover?.animation.play('end', true);
        }
        else if (holdNote.cover != null)
        {
          // *lightning* *zap* *crackle*
          holdNote.cover.visible = false;
          holdNote.cover.kill();
        }

        holdNote.visible = false;
        holdNote.kill();
      }
      else if (holdNote.missedNote && (holdNote.fullSustainLength > holdNote.sustainLength))
      {
        // Hold note was dropped before completing, keep it in its clipped state.
        holdNote.visible = true;

        var yOffset:Float = (holdNote.fullSustainLength - holdNote.sustainLength) * Constants.PIXELS_PER_MS;

        if (mods != null)
        {
          holdNote.x = ModConstants.holdNoteJankX;
          holdNote.y = ModConstants.holdNoteJankY;
        }
        else
        {
          if (!customPositionData)
          {
            if (isDownscroll)
            {
              holdNote.y =
                this.y
                - INITIAL_OFFSET
                + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
                - holdNote.height
                + STRUMLINE_SIZE / 2
                + holdNote.yOffset;
            }
            else
            {
              holdNote.y =
                this.y
                - INITIAL_OFFSET
                + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
                + yOffset
                + STRUMLINE_SIZE / 2
                + holdNote.yOffset;
            }
          }
        }

        // Clean up the cover.
        if (holdNote.cover != null)
        {
          holdNote.cover.visible = false;
          holdNote.cover.kill();
        }
      }
      else if (conductorInUse.musicPosition > holdNote.strumTime && holdNote.hitNote)
      {
        // Hold note is currently being hit, clip it off.
        holdConfirm(holdNote.noteData);
        holdNote.visible = true;

        holdNote.sustainLength = (holdNote.strumTime + holdNote.fullSustainLength) - conductorInUse.musicPosition;

        if (mods != null)
        {
          if (holdNote.sustainLength <= 1)
          {
            holdNote.visible = false;
          }
          holdNote.x = ModConstants.holdNoteJankX;
          holdNote.y = ModConstants.holdNoteJankY;
        }
        else
        {
          if (holdNote.sustainLength <= 10)
          {
            holdNote.visible = false;
          }
          if (!customPositionData)
          {
            if (ClientPrefs.data.downScroll)
            {
              holdNote.y = this.y - INITIAL_OFFSET - holdNote.height + STRUMLINE_SIZE / 2;
            }
            else
            {
              holdNote.y = this.y - INITIAL_OFFSET + STRUMLINE_SIZE / 2;
            }
          }
        }
      }
      else
      {
        // Hold note is new, render it normally.
        holdNote.visible = true;
        if (mods != null)
        {
          holdNote.x = ModConstants.holdNoteJankX;
          holdNote.y = ModConstants.holdNoteJankY;
        }
        else
        {
          if (!customPositionData)
          {
            if (isDownscroll)
            {
              holdNote.y =
                this.y
                - INITIAL_OFFSET
                + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
                - holdNote.height
                + STRUMLINE_SIZE / 2
                + holdNote.yOffset;
            }
            else
            {
              holdNote.y =
                this.y
                - INITIAL_OFFSET
                + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
                + STRUMLINE_SIZE / 2
                + holdNote.yOffset;
            }
          }
        }
      }
    } // Update rendering of pressed keys.

    for (dir in 0...heldKeys.length)
    {
      if (isKeyHeld(dir) && getByColumn(dir).getCurrentAnimation() == 'static')
      {
        playPress(dir);
      }
    }
  }

  /**
   * Return notes that are within, or way after, `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `Note` objects.
   */
  public function getNotesOnScreen():Array<Note>
  {
    return notes.members.filter(function(note:Note)
    {
      return note != null && note.alive && !note.wasGoodHit;
    });
  }

  function updateGhostTapTimer(elapsed:Float):Void
  {
    // If it's still our turn, don't update the ghost tap timer.
    if (getNotesOnScreen().length > 0) return;

    ghostTapTimer -= elapsed;

    if (ghostTapTimer <= 0)
    {
      ghostTapTimer = 0;
    }
  }

  /**
   * Called when the PlayState skips a large amount of time forward or backward.
   */
  public function handleSkippedNotes():Void
  {
    // By calling clean(), we remove all existing notes so they can be re-added.
    clean();
    // By setting noteIndex to 0, the next update will skip past all the notes that are in the past.
    nextNoteIndex = 0;
  }

  /**
   * Called on each beat of the song.
   */
  public function onBeatHit():Void
  {
    if (mods == null) sortNotes(); // default sorting is done every beat for some reason lol -Haz
  }

  public function sortNotes():Void
  {
    if (notes?.members?.length > 1)
      notes.members.insertionSort(compareNotes.bind(FlxSort.ASCENDING));

    if (sustainNotes?.members?.length > 1) sustainNotes.members.insertionSort(compareHoldNotes.bind(FlxSort.ASCENDING));

    if (strumLineNotes?.members?.length > 1 && mods != null) strumLineNotes.members.insertionSort(compareStrums.bind(FlxSort.ASCENDING));

    // if (StrumNotes_Visual.members.length > 1) StrumNotes_Visual.members.insertionSort(compareNotes.bind(FlxSort.ASCENDING));
  }

  /**
   * Called when a key is pressed.
   * @param dir The direction of the key that was pressed.
   * @param keyCode The key input used to press the direction. Used to distinguish when two keys for the same direction are pressed.
   */
  public function pressKey(dir:Int, keyCode:Int):Void
  {
    heldKeys[dir].push(keyCode);
  }

  /**
   * Called when a key is released.
   * @param dir The direction of the key that was released.
   * @param keyCode The key input used to press the direction. Used to distinguish when two keys for the same direction are pressed.
   *   If null, all keys for the direction are released.
   */
  public function releaseKey(dir:Int, ?keyCode:Int):Void
  {
    if (keyCode == null)
    {
      heldKeys[dir].clear();
    }
    else
    {
      heldKeys[dir].remove(keyCode);
    }
  }

  /**
   * Check if a key is held down.
   * @param dir The direction of the key to check.
   * @return `true` if the key is held down, `false` otherwise.
   */
  public function isKeyHeld(dir:Int):Bool
  {
    if (dir >= 0 && dir < PlayfieldManager.pressedGameplayKeys.length && PlayfieldManager.pressedGameplayKeys[dir])
      return true;
    return dir >= 0 && dir < heldKeys.length && heldKeys[dir].length > 0;
  }

  /**
   * Called when the song is reset.
   * Removes any special animations and the like.
   * Doesn't reset the notes from the chart, that's handled by the PlayState.
   */
  public function clean():Void
  {
    for (note in notes.members)
    {
      if (note == null) continue;
      killNote(note);
    }

    for (holdNote in sustainNotes.members)
    {
      if (holdNote == null) continue;
      holdNote.kill();
    }

    for (splash in noteSplashes)
    {
      if (splash == null) continue;
      splash.kill();
    }

    for (cover in holdSplashes)
    {
      if (cover == null) continue;
      cover.kill();
    }

    heldKeys = [[], [], [], []];

    resetScrollSpeed();

    ghostTapTimer = 0;
  }

  public function resetSongNotes():Void
  {
    clean();
    unspawnNotes = [];
    notesAddedCount = 0;
    nextNoteIndex = -1;
    amountOfRenderedNotes = 0;
    maxRenderedNotes = 0;
    skippedCount = 0;
    maxSkipped = 0;
  }

   /**
   * Hit a note.
   * @param note The note to hit.
   * @param removeNote True to remove the note immediately, false to make it transparent and let it move offscreen.
   */
  public function hitNote(note:Dynamic, removeNote:Bool = true):Void
  {
    playConfirm(note.noteData);
    note.hasBeenHit = true;

    if (removeNote)
    {
      killNote(note);
    }
    else
    {
      note.alpha = 0.5;
      note.desaturate();
    }

    if (note is SustainNote)
    {
      note.hitNote = true;
      note.missedNote = false;
      note.visible = true;
      note.sustainLength = Math.min(
        note.fullSustainLength,
        (note.strumTime + note.fullSustainLength) - conductorInUse.musicPosition
      );
    }

    ghostTapTimer = Constants.GHOST_TAP_DELAY;

    if (note.parentStrumline != null) {
      if (note.parentStrumline.defaultPlayerControl)
        PlayState.instance?.goodNoteHit(note, null, this);
      else if (note.parentStrumline.playerNum == 0)
        PlayState.instance?.opponentNoteHit(note, null, this);
      else
        PlayState.instance?.goodNoteCustom(note, this);
    }
  }

  /**
   * Play a note hold cover for a given hold note.
   * @param holdNote The hold note to play the cover animation for.
   */
   public function playNoteHoldCover(holdNote:SustainNote):Void
  {
    if (!showNotesplash) return;

    var cover:SustainSplash = null;
    if (this.holdSplashes.length == 0) {
      cover = new SustainSplash();
      cover.alpha = 0.0001;
      cover.visible = false;
    } else this.holdSplashes.recycle(SustainSplash);

    if (cover != null)
    {
      cover.sustainNote = holdNote;
      holdNote.cover = cover;
      cover.visible = true;

      cover.setupSusSplash(holdNote.parentStrumline.getByColumn(holdNote.noteData), holdNote, ClientPrefs.getGameplaySetting('songspeed'));

      /*if (holdNote != null)
      {
        cover.setHSV(holdNote.hsvShader.hue, holdNote.hsvShader.saturation, holdNote.hsvShader.value);
      }*/

      cover.holdPositioned = false;

      // todo: fix holdPositioned covers for non WITF songs.
      if (mods != null || cover.holdPositioned)
      {
        noteCoverSetPos(cover);
      }
      else
      {
        cover.x = this.x;
        cover.x += getXPos(holdNote.noteData);
        cover.x += STRUMLINE_SIZE / 2;
        cover.x -= cover.width / 2;
        cover.x += 0 * cover.scale.x;
        cover.x += -12; // hardcoded adjustment, because we are evil.

        cover.y = this.y;
        cover.y += INITIAL_OFFSET;
        cover.y += STRUMLINE_SIZE / 2;
        cover.y += 0 * cover.scale.y;
        cover.y += -96; // hardcoded adjustment, because we are evil.
      }
    }
  }

  /**
   *
   * Kill a note heading towards the strumline.
   * @param note The note to kill. Gets recycled and reused for performance.
   */
  public function killNote(note:Dynamic):Void
  {
    if (note == null) return;
    note.visible = false;
    note.kill();

    if (note is SustainNote)
    {
      note.missedNote = true;
      note.visible = false;
    }
  }

  /**
   * Play a static animation for a given direction.
   * @param direction The direction of the note to play the static animation for.
   */
  public function playStatic(direction:Int):Void
  {
    getByColumn(direction).playStatic();
  }

  /**
   * Play a press animation for a given direction.
   * @param direction The direction of the note to play the press animation for.
   */
  public function playPress(direction:Int):Void
  {
    getByColumn(direction).playPress();
  }

  /**
   * Play a confirm animation for a given direction.
   * @param direction The direction of the note to play the confirm animation for.
   */
  public function playConfirm(direction:Int):Void
  {
    getByColumn(direction).playConfirm();
  }

  /**
   * Play a confirm animation for a hold note.
   * @param direction The direction of the note to play the confirm animation for.
   */
  public function holdConfirm(direction:Int):Void
  {
    getByColumn(direction).holdConfirm();
  }

  var holdCoverSkew:Bool = false; // makes hold covers skew if true
  var holdCoverRotate:Bool = true; // requires the origin to be properly set to the center

  function noteCoverSetPos(cover:SustainSplash):Void
  {
    if (cover == null) return;

    var noteStyleScale:Float = 1;
    var whichStrumNote:StrumNote = cover.strumNote;

    if (cover.sustainNote?.alive ?? null != null)
    {
      @:privateAccess cover.isSpiralHold = cover.sustainNote?.noteModData?.usingSpiralHolds() ?? false;
    }
    var spiralHolds:Bool = cover.isSpiralHold;

    if (cover.holdPositioned)
    {
      if (cover.sustainNote != null)
      {
        var daHold:SustainNote = cover.sustainNote;

        // v[0] = first x pos
        // v[2] = second x pos
        // +1 for y
        var v = daHold.vertices;
        var holdX:Float = v[0] + ((v[2] - v[0]) / 2);
        var holdY:Float = v[0 + 1] + ((v[2 + 1] - v[0 + 1]) / 2);
        if (mods == null)
        {
          holdX += daHold.x;
          holdY += daHold.y;
        }

        @:privateAccess
        var holdZ:Float = daHold.holdRootZ;
        @:privateAccess
        var holdScaleX:Float = daHold.holdRootScaleX;
        @:privateAccess
        var holdScaleY:Float = daHold.holdRootScaleY;

        cover.x = holdX;
        cover.y = holdY;

        cover.scale.set(noteStyleScale);
        cover.scale.x *= holdScaleX;
        cover.scale.y *= holdScaleY;

        // todo, rotate this offset based on angle
        var offsetX:Float = 0 * cover.scale.x;
        var offsetY:Float = 0 * cover.scale.y;
        var daAngle:Float = 0;
        if (spiralHolds && holdCoverRotate)
        {
          if (cover.strumNote != null) daAngle = cover.strumNote.angle;
        }

        cover.x += offsetX;
        cover.y += offsetY;

        cover.x -= cover.width / 2;
        cover.y -= cover.height / 2;
        cover.z = holdZ;

        cover.alpha = daHold.alpha - whichStrumNote.strumExtraModData.alphaHoldCoverMod;

        if (holdCoverSkew)
        {
          cover.skew.x = whichStrumNote.skew.x;
          cover.skew.y = whichStrumNote.skew.y;
          cover.skew.x += whichStrumNote.noteModData.skewX_playfield;
          cover.skew.y += whichStrumNote.noteModData.skewY_playfield;
        }

        ModConstants.applyPerspective(cover, cover.width, cover.height);
        cover.x = cover.x;
        cover.y = cover.y;
      }
    }
    else
    {
      var ay:Float = whichStrumNote.alpha;
      ay -= whichStrumNote.strumExtraModData.alphaHoldCoverMod;

      cover.scale.set(noteStyleScale, noteStyleScale);

      if (whichStrumNote.strumExtraModData.holdCoverCopyStrumScale)
      {
        cover.scale.x += whichStrumNote.strumExtraModData.strumScaleDifX;
        cover.scale.y += whichStrumNote.strumExtraModData.strumScaleDifY;
      }

      // default holdCover positioning
      cover.x = this.x;
      cover.x += getXPos(cover.strumNote.noteData);
      cover.x += STRUMLINE_SIZE / 2;
      cover.x -= cover.width / 2;
      //cover.x += noteStyle.getHoldCoverOffsets()[0] * cover.scale.x;
      cover.x += -12; // hardcoded adjustment, because we are evil.
      cover.y = this.y;
      cover.y += INITIAL_OFFSET;
      cover.y += STRUMLINE_SIZE / 2;
      //cover.y += noteStyle.getHoldCoverOffsets()[1] * cover.scale.y;
      cover.y += -96; // hardcoded adjustment, because we are evil.

      // Move the cover to where the strum is
      var strumStartX:Float = whichStrumNote.formerPosition.x;
      var strumStartY:Float = whichStrumNote.formerPosition.y;
      cover.x += (whichStrumNote.x - strumStartX);
      cover.y += (whichStrumNote.y - strumStartY);
      cover.alpha = ay;
      cover.z = whichStrumNote.z;

      if (holdCoverSkew)
      {
        cover.skew.x = whichStrumNote.skew.x;
        cover.skew.y = whichStrumNote.skew.y;
      }

      // attempt to position when skewing in 3D
      if (whichStrumNote.strumExtraModData.threeD)
      {
        ModConstants.playfieldSkew(
          cover,
          whichStrumNote.noteModData.skewX_playfield,
          whichStrumNote.noteModData.skewY_playfield,
          whichStrumNote.strumExtraModData.playfieldX,
          whichStrumNote.strumExtraModData.playfieldY,
          cover.frameWidth * 0.5,
          cover.frameHeight * 0.5
        );
        if (holdCoverSkew)
        {
          cover.skew.x += whichStrumNote.noteModData.skewX_playfield;
          cover.skew.y += whichStrumNote.noteModData.skewY_playfield;
        }
      }
    }

    if (spiralHolds && holdCoverRotate)
    {
      if (cover.strumNote != null)
      {
        if (cover.strumNote != null && cover.strumNote.alive)
        {
          cover.angle = cover.strumNote.angle;
        }
      }
    }
    else // Fix for if spiral holds get disabled, the covers stay rotated.
    {
      cover.angle = 0;
    }

    cover.perspectiveCenterOffset = whichStrumNote.noteModData.perspectiveOffset;
  }

  function noteSplashSetPos(splash:NoteSplash, direction:Int):Void
  {
    splash.scale.set(1, 1);

    // default notesplash positioning
    var whichStrumNote:StrumNote = getByColumn(direction % (ExtraKeys.mania+1));
    if (whichStrumNote.strumExtraModData.splashCopyStrumScale)
    {
      splash.scale.x += whichStrumNote.strumExtraModData.strumScaleDifX;
      splash.scale.y += whichStrumNote.strumExtraModData.strumScaleDifY;
    }

    // Move the splash to where the strum is
    var strumStartX:Float = INITIAL_OFFSET + this.x + getXPos(direction) + 0;
    var strumStartY:Float = this.y + 0;
    splash.x += (whichStrumNote.x - strumStartX);
    splash.y += (whichStrumNote.y - strumStartY);

    splash.z = whichStrumNote.z; // copy Z!

    var ay:Float = whichStrumNote.alpha;
    ay -= whichStrumNote.strumExtraModData.alphaSplashMod;
    splash.alpha = ay * 1.0;

    splash.skew.x = whichStrumNote.skew.x;
    splash.skew.y = whichStrumNote.skew.y;
    // attempt to position when skewing in 3D
    if (whichStrumNote.strumExtraModData.threeD)
    {
      ModConstants.playfieldSkew(
        splash,
        whichStrumNote.noteModData.skewX_playfield,
        whichStrumNote.noteModData.skewY_playfield,
        whichStrumNote.strumExtraModData.playfieldX,
        whichStrumNote.strumExtraModData.playfieldY,
        splash.frameWidth * 0.3,
        splash.frameHeight * 0.3
      );

      splash.skew.x += whichStrumNote.noteModData.skewX_playfield;
      splash.skew.y += whichStrumNote.noteModData.skewY_playfield;
    }

    splash.perspectiveCenterOffset = whichStrumNote.noteModData.perspectiveOffset;
  }

  /**
   * Converts a noteDirection into a Float corrosponding to the direction's x Position.
   * @param direction The direction to input.
   * @return The x position this noteDirection is!
   */
  public function getXPos(direction:Int):Float
  {
    var pos:Float = 0;
    return switch (direction)
    {
      case 0:
        -pos * 2;
      case 1:
        -(pos * 2) + (1 * Strumline.NOTE_SPACING) * (noteSpacingScale * strumlineScale.x);
      case 2:
        pos + (2 * Strumline.NOTE_SPACING) * (noteSpacingScale * strumlineScale.x);
      case 3:
        pos + (3 * Strumline.NOTE_SPACING) * (noteSpacingScale * strumlineScale.x);
      default:
        -pos * 2;
    }
  }

  /**
   * Apply a small animation which moves the arrow down and fades it in.
   * Only plays at the start of Free Play songs.
   *
   * Note that modifying the offset of the whole strumline won't have the
   * @param arrow The arrow to animate.
   * @param index The index of the arrow in the strumline.
   */
  function fadeInArrow(index:Int, arrow:StrumNote):Void
  {
    final playbackRate:Float = ClientPrefs.getGameplaySetting('songspeed');
    if (mods != null)
    {
      arrow.strumExtraModData.introTweenPercentage = 0;
      FlxTween.tween(arrow.strumExtraModData, {
        introTweenPercentage: 1
      }, 1, {
        ease: FlxEase.circOut,
        startDelay: 0.5 + (0.2 * index) / (Conductor.bpm/240) / playbackRate
      });
    }
    else
    {
      FlxTween.tween(arrow, {
        y: (ClientPrefs.data.downScroll) ? FlxG.height - 150 : 50,
        alpha: 1,
        angle: 0
      }, 1, {
        ease: FlxEase.circOut,
        startDelay: 0.5 + (0.2 * index) / (Conductor.bpm/240) / playbackRate
      });
    }
  }

  /**
   * Apply a small animation which moves the arrow up and fades it out.
   * Used when the song ends in Freeplay mode.
   *
   * @param index The index of the arrow in the strumline.
   * @param arrow The arrow to animate.
   */
  public function fadeOutArrow(index:Int, arrow:StrumNote):Void
  {
    FlxTween.tween(arrow, {
      y: arrow.y - 10,
      alpha: 0
    }, 0.5, {
      ease: FlxEase.circIn
    });
  }

  /**
   * Play a fade in animation on all arrows in the strumline.
   * Used when starting a song in Freeplay mode.
   */
  public function fadeInArrows():Void
  {
    for (index => arrow in this.strumLineNotes.members.keyValueIterator())
    {
      fadeInArrow(index, arrow);
    }
  }

  /**
   * Play a fade out animation on all arrows in the strumline.
   * Used when ending a song in Freeplay mode.
   */
  public function fadeOutArrows():Void
  {
    for (index => arrow in this.strumLineNotes.members.keyValueIterator())
    {
      fadeOutArrow(index, arrow);
    }
  }

  function compareZSprites(order:Int, a:ZSprite, b:ZSprite):Int
  {
    return FlxSort.byValues(order, a?.z, b?.z);
  }

  function compareStrums(order:Int, a:StrumNote, b:StrumNote):Int
  {
    if (mods != null && zSortMode)
    {
      return FlxSort.byValues(order, a?.z, b?.z);
    }
    else
    {
      return FlxSort.byValues(order, a?.direction, b?.direction);
    }
  }

  public var zSortMode:Bool = true;

  // Note

  function compareNotes(order:Int, a:Note, b:Note):Int
  {
    if (mods != null && zSortMode)
    {
      // Default to sorting by z. If the z values are equal, sort by strumTime instead.
      if (a?.z == b?.z)
      {
        // Should the strumTimes be the same, then add 1 to the strumTime if the note is low priority.
        if (a?.strumTime == b?.strumTime)
        {
          return FlxSort.byValues(order, a.strumTime + (a.lowPriority ? 0 : 1), b.strumTime + (b.lowPriority ? 0 : 1));
        }
        else
          return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
      }
      else
        return FlxSort.byValues(order, a?.z, b?.z);
    }
    else
    {
      return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
    }
  }

  /**
   * Compare two hold note sprites by their strumtime.
   * @param order The order to sort the notes in.
   * @param a The first hold note sprite.
   * @param b The second hold note sprite.
   * @return The comparison result, based on the time of the notes.
   */
  function compareHoldNotes(order:Int, a:SustainNote, b:SustainNote):Int
  {
    if (mods != null && zSortMode)
    {
      // Default to sorting by z. If the z values are equal, sort by strumTime instead.
      if (a?.z == b?.z)
      {
        return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
      }
      else
        return FlxSort.byValues(order, a?.z, b?.z);
    }
    else
    {
      return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
    }
  }

  /**
   * Find the minimum Y position of the strumline.
   * Ignores the background to ensure the strumline is positioned correctly.
   * @return The minimum Y position of the strumline.
   */
  override function findMinYHelper():Float
  {
    var value:Float = Math.POSITIVE_INFINITY;
    for (member in group.members)
    {
      if (member == null) continue;
      // SKIP THE BACKGROUND
      if (member == this.background) continue;

      var minY:Float;
      if (member.flixelType == SPRITEGROUP)
      {
        minY = (cast member : FlxSpriteGroup).findMinY();
      }
      else
      {
        minY = member.y;
      }

      if (minY < value) value = minY;
    }
    return value;
  }

  /**
   * Find the maximum Y position of the strumline.
   * Ignores the background to ensure the strumline is positioned correctly.
   * @return The maximum Y position of the strumline.
   */
  override function findMaxYHelper():Float
  {
    var value:Float = Math.NEGATIVE_INFINITY;
    for (member in group.members)
    {
      if (member == null) continue;
      // SKIP THE BACKGROUND
      if (member == this.background) continue;

      var maxY:Float;
      if (member.flixelType == SPRITEGROUP)
      {
        maxY = (cast member : FlxSpriteGroup).findMaxY();
      }
      else
      {
        maxY = member.y + member.height;
      }

      if (maxY > value) value = maxY;
    }
    return value;
  }

  // WITF Draw Function logic
  public var drawFunc:Null<Void->Void>;

  private var doingDrawFunc:Bool = false;

  override public function draw():Void
  {
    if (drawFunc != null && !doingDrawFunc)
    {
      doUpdateClipsInDraw = true;
      doingDrawFunc = true;
      drawFunc();
      doingDrawFunc = false;
      doUpdateClipsInDraw = false;
    }
    else
    {
      super.draw();
    }
  }
}

typedef StrumlineObj = {
  var strumlinePos:FlxPoint;
  var player:Int;
}
