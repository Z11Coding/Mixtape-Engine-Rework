package objects.notes;

import backend.modchartSystem.ModConstants;
import backend.modchartSystem.ModHandler;
import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import lime.math.Vector2;
import objects.funkin.data.SongNoteData;
import objects.funkin.graphics.FunkinSprite;
import objects.funkin.graphics.ZSprite;
import objects.notes.StrumNote;
import openfl.display.BitmapData; // for converting data to pass into the shader
import openfl.display.TriangleCulling;
import openfl.geom.Vector3D;
import shaders.HSVNotesShader;

using backend.funkin.util.tools.ArraySortTools;
using backend.funkin.util.tools.FloatTools;


/**
 * This is based heavily on the `FlxStrip` class. It uses `drawTriangles()` to clip a sustain note
 * trail at a certain time.
 * The whole `FlxGraphic` is used as a texture map. See the `NOTE_hold_assets.fla` file for specifics
 * on how it should be constructed.
 *
 * @author MtH
 */
class SustainTrail extends ZSprite
{
  // Arrow paths are regenerated every frame, so an unconstrained time-based
  // hold resolution can turn a decorative path into hundreds of modifier samples
  // per lane per frame. Normal sustain notes keep their configured resolution.
  public static inline var MAX_ARROWPATH_SAMPLES:Int = 4;
  public var isArrowPathPiece:Bool = false;

  // Cache lane-filtered modifier lists once per trail rebuild rather than
  // repeating the same target-lane tests for every sampled point.
  var sampleSpeedMods:Array<Modifier> = [];
  var sampleArrowpathMods:Array<Modifier> = [];
  var sampleNoteMods:Array<Modifier> = [];

  #if debug
  static var arrowPathClipPerfLastReport:Float = 0;
  static var arrowPathClipPerfCalls:Int = 0;
  static var arrowPathClipPerfTotalMs:Float = 0;
  static var arrowPathClipPerfMaxMs:Float = 0;
  static var arrowPathClipPerfTotalSamples:Float = 0;
  static var arrowPathClipPerfMaxResolution:Int = 0;
  static var arrowPathClipPerfMaxSpeedMods:Int = 0;
  static var arrowPathClipPerfMaxPathMods:Int = 0;
  static var arrowPathClipPerfMaxNoteMods:Int = 0;
  #end

  /**
   * The triangles corresponding to the hold, followed by the endcap.
   * `top left, top right, bottom left`
   * `top left, bottom left, bottom right`
   */
  static final TRIANGLE_VERTEX_INDICES:Array<Int> = [
    0,
    1,
    2,
    1,
    2,
    3,
    4,
    5,
    6,
    5,
    6,
    7
  ];

  public var strumTime:Float = 0; // millis
  public var noteDirection:Int = 0;
  public var sustainLength(default, set):Float = 0; // millis
  public var fullSustainLength:Float = 0;
  public var parentStrumline:Strumline;
  public var cover:SustainSplash = null;

  /**
   * The note data associated with this hold note sprite.
   * This is used to store the strum time, length, and other properties.
   */
  public var noteData:Null<SongNoteData>;

  /**
   * Set this to `false` to disable scoring for this note.
   * The note will no longer count towards ratings, points, or accuracy.
   * @default `true` to enable scoring.
   */
  public var scoreable:Bool = true;

  /**
   * The Y Offset of the note.
   */
  public var yOffset:Float = 0.0;

  /**
   * Set to `true` if the user hit the note and is currently holding the sustain.
   * Should display associated effects.
   */
  public var hitNote:Bool = false;

  /**
   * Set to `true` if the user missed the note or released the sustain.
   * Should make the trail transparent.
   */
  public var missedNote:Bool = false;

  /**
   * Set to `true` after handling additional logic for missing notes.
   */
  public var handledMiss:Bool = false;

  // maybe BlendMode.MULTIPLY if missed somehow, drawTriangles does not support!

  /**
   * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
   */
  public var vertices:DrawData<Float> = new DrawData<Float>();

  public var vertices_array:Array<Float> = [];

  /**
   * A `Vector` of integers or indexes, where every three indexes define a triangle.
   */
  public var indices:DrawData<Int> = new DrawData<Int>();

  /**
   * A `Vector` of normalized coordinates used to apply texture mapping.
   */
  public var uvtData:DrawData<Float> = new DrawData<Float>();

  /**
   * A `Vector` representing each vertex colour. Doesn't work though :(
   */
  public var colors:DrawData<Int> = null;

  var zoom:Float = 1;

  /**
   * What part of the trail's end actually represents the end of the note.
   * This can be used to have a little bit sticking out.
   */
  public var endOffset:Float = 0.5; // 0.73 is roughly the bottom of the sprite in the normal graphic!

  /**
   * At what point the bottom for the trail's end should be clipped off.
   * Used in cases where there's an extra bit of the graphic on the bottom to avoid antialiasing issues with overflow.
   */
  public var bottomClip:Float = 0.9;

  /**
   * Whether the note will receive custom vertex data
   */
  public var customVertexData:Bool = false;

  public var isPixel:Bool;

  var graphicWidth:Float = 0;
  var graphicHeight:Float = 0;

  // Makes the mesh all wobbly! Taken from ZProjectSprite_Note.hx
  public var vibrateEffect:Float = 0.0;

  /**
   * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
   * @param NoteData
   * @param SustainLength Length in milliseconds.
   * @param fileName
   */
  public function new(?newStrumTime:Float, ?newNoteData:Int, ?sustainLength:Float, ?parentStrum:Strumline)
  {
    super(0, 0);
    this.parentStrumline = parentStrum;

    // BASIC SETUP
    if (!Math.isNaN(sustainLength)) {
      this.sustainLength = sustainLength;
      this.fullSustainLength = sustainLength;
    }
    if (!Math.isNaN(newNoteData) && isPixel) this.noteDirection = newNoteData;
    if (!Math.isNaN(newStrumTime)) strumTime = newStrumTime;

    noteModData = new NoteData();

    setIndices(TRIANGLE_VERTEX_INDICES);
    setupHoldNoteGraphic();

    this.active = true; // This NEEDS to be true for the note to be drawn!
  }

  /**
   * Sets the indices for the triangles.
   * @param indices The indices to set.
   */
  public function setIndices(indices:Array<Int>):Void
  {
    if (this.indices.length == indices.length)
    {
      for (i in 0...indices.length)
      {
        this.indices[i] = indices[i];
      }
    }
    else
    {
      this.indices = new DrawData<Int>(indices.length, false, indices);
    }
  }

  /**
   * Sets the vertices for the triangles.
   * @param vertices The vertices to set.
   */
  public function setVertices(vertices:Array<Float>):Void
  {
    if (this.vertices.length == vertices.length)
    {
      for (i in 0...vertices.length)
      {
        this.vertices[i] = vertices[i];
      }
    }
    else
    {
      this.vertices = new DrawData<Float>(vertices.length, false, vertices);
    }
  }

  /**
   * Sets the UV data for the triangles.
   * @param uvtData The UV data to set.
   */
  public function setUVTData(uvtData:Array<Float>):Void
  {
    if (this.uvtData.length == uvtData.length)
    {
      for (i in 0...uvtData.length)
      {
        this.uvtData[i] = uvtData[i];
      }
    }
    else
    {
      this.uvtData = new DrawData<Float>(uvtData.length, false, uvtData);
    }
  }

  /**
   * Creates hold note graphic and applies correct zooming
   */
  public function setupHoldNoteGraphic():Void
  {
    loadGraphic(Paths.image('NOTE_ArrowPath'));

    antialiasing = true;

    if (isPixel)
    {
      endOffset = bottomClip = 1;
      antialiasing = false;
    }
    else
    {
      endOffset = 0.5;
      bottomClip = 0.9;
    }

    zoom = 1.0;
    zoom *= 0.7; // based of funkin notestyle

    // CALCULATE SIZE
    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
    // instead of scrollSpeed, PlayState.SONG.speed

    flipY = ClientPrefs.data.downScroll;

    // alpha = 0.6;
    alpha = 1.0;
    updateColorTransform();

    if (useHSVShader)
    {
      if (hsvShader == null) hsvShader = new HSVNotesShader();
      this.shader = hsvShader;
    }

    updateClipping();
  }

  function getBaseScrollSpeed():Float
  {
    return (PlayfieldManager.instance?.songSpeed ?? 1.0);
  }

  var previousScrollSpeed:Float = 1;

  override function update(elapsed):Void
  {
    super.update(elapsed);
    if (previousScrollSpeed != (parentStrumline?.scrollSpeed ?? 1.0))
    {
      triggerRedraw();
    }
    previousScrollSpeed = parentStrumline?.scrollSpeed ?? 1.0;
  }

  /**
   * Calculates height of a sustain note for a given length (milliseconds) and scroll speed.
   * @param	susLength	The length of the sustain note in milliseconds.
   * @param	scroll		The current scroll speed.
   */
  public static inline function sustainHeight(susLength:Float, scroll:Float)
  {
    return (susLength * Constants.PIXELS_PER_MS * scroll);
  }

  function set_sustainLength(s:Float):Float
  {
    if (s < 0.0) s = 0.0;

    this.sustainLength = s;
    triggerRedraw();
    return this.sustainLength;
  }

  function triggerRedraw():Void
  {
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
    if (!usingHazModHolds) // Don't update cuz we updateClipping every frame anyway in Strumline.hx
      updateClipping(); // Commenting this out = holds don't render for 1 frame when being hit. Keeping this means the hold renders incorrectly... what?
    updateHitbox();
  }

  override public function updateHitbox():Void
  {
    width = graphicWidth;
    height = graphicHeight;

    offset.set(0, 0);
    if (!usingHazModHolds || parentStrumline == null || parentStrumline.mods == null)
    {
      offset.set(0, 0);
    }

    origin.set(width * 0.5, height * 0.5);
  }

  var usingHazModHolds:Bool = true;

  /**
   * Sets up new vertex and UV data to clip the trail.
   * If flipY is true, top and bottom bounds swap places.
   * @param songTime	The time to clip the note at, in milliseconds.
   */
  public function updateClipping(songTime:Float = 0):Void
  {
    if (graphic == null || customVertexData)
    {
      return;
    }

    if (parentStrumline == null || parentStrumline.mods == null)
    {
      // trace("AW FUCK, THERE IS NO WAY TO SAMPLE MOD DATA!");
      updateClipping_Vanilla(songTime);
      usingHazModHolds = false;
      return;
    }

    if (usingHazModHolds)
    {
      if (!parentStrumline.doUpdateClipsInDraw) updateClipping_mods(songTime);
      else
        return;
    }
    else
    {
      updateClipping_Vanilla(songTime);
    }
  }

  var fakeNote:ZSprite;
  var perspectiveShift:Vector3D = new Vector3D(0, 0, 0); // z is scale dif

  function resetFakeNote():Void
  {
    fakeNote.alpha = 0;
    fakeNote.scale.set(ModConstants.arrowPathScale, ModConstants.arrowPathScale);
    return;
  }

  var noteModData:NoteData;

  public var renderEnd:Bool = true; // test
  public var piece:Int = 0; // test
  public var previousPiece:SustainTrail = null;
  public var cullMode = TriangleCulling.NONE;
  public var whichStrumNote:StrumNote;

  private var old3Dholds:Bool = false;
  private var holdResolution:Int = 4;
  private var useOldStealthGlowStyle:Bool = false;

  // Extra math for if you need information about the hold's TRUE curPos (not affected by being held down or not).

  function extraHoldRootInfo(t:Float):Void
  {
    if (this.hsvShader == null) return;
    var strumTimmy:Float = t - whichStrumNote?.strumExtraModData?.strumPos ?? 0.0;

    var notePos:Float = parentStrumline.calculateNoteYPos(strumTimmy);
    distanceFromReceptor_unscaledpos = notePos;
    updateStealthGlowV2();
  }

  var shaderColsBitmap:BitmapData; // ToDo, see below:

  /**
   * Forwards data to the hsvShader to render stealth transitions smoothly.
   * Hopefully will be updated in the future to use an array instead cuz at the moment, only supports 1 of each type (sudden, hidden, vanish)
   */
  function updateStealthGlowV2():Void
  {
    /**
     * Future code:
     * Grab an array of all the stealth samples in this hold.
     * Afterwards, we then create a bitmap using the following format:
     * y 0 = stealth glow value
     * y 1 = alpha
     * y 2 = red
     * y 3 = green
     * y 4 = blue
     * y 5 = stealth glow red
     * y 6 = stealth glow green
     * y 7 = stealth glow blue
     * and x represent what piece the data was sampled at
     *
     * So if we access shaderColsBitmap[3, 1] and get '0.5', then the 4th piece has an alpha value of 0.5.
     *
     * This bitmap data is then forwarded into the shader to then be used to apply to the texture.
     * Make sure this bitmap data is on another separate channel to avoid overwriting our base graphic.
     */

    this.hsvShader.setFloat('_holdHeight', holdResolution);
    return;
  }

  // reuse this vector2 and vector3 variable instead of creating a bunch of new ones all the time
  var tempVec2:Vector2 = new Vector2(0, 0);
  var tempVec3:Vector3D = new Vector3D(0, 0, 0);
  var clipRotateOrigin:Vector2 = new Vector2(0, 0);
  var clipPerspectivePivot:Vector2 = new Vector2(0, 0);
  var clipRotateRoot:Vector2 = new Vector2(0, 0);
  var clipRotatePoint:Vector2 = new Vector2(0, 0);
  var clipVertexBuffer:Array<Float> = [];
  var clipUVBuffer:Array<Float> = [];
  var clipIndexBuffer:Array<Int> = [];
  var clipColorBuffer:Array<Int> = [];

  // The 3D projection below transforms several vertices for every sampled
  // sustain point. These angles stay constant until the next susSample(), so
  // calculate their trigonometry once per point rather than once per vertex.
  var projectionSkewTan:Float = 0.0;
  var projectionSkewXPlayfieldTan:Float = 0.0;
  var projectionSkewYPlayfieldTan:Float = 0.0;
  var projectionSkewZPlayfieldTan:Float = 0.0;
  var projectionAngleYCos:Float = 1.0;
  var projectionAngleYSin:Float = 0.0;

  function prepareSampleModifiers():Void
  {
    sampleSpeedMods.resize(0);
    sampleArrowpathMods.resize(0);
    sampleNoteMods.resize(0);

    final lane:Int = noteDirection % (ExtraKeys.mania + 1);
    final handler:ModHandler = parentStrumline.mods;

    for (i in 0...handler.mods_speed.length)
    {
      final mod:Modifier = handler.mods_speed[i];
      if (mod.targetLane == -1 || mod.targetLane == lane) sampleSpeedMods.push(mod);
    }
    for (i in 0...handler.mods_arrowpath.length)
    {
      final mod:Modifier = handler.mods_arrowpath[i];
      if (mod.targetLane == -1 || mod.targetLane == lane) sampleArrowpathMods.push(mod);
    }
    if (noteModData != null)
    {
      for (i in 0...noteModData.noteMods.length)
      {
        final mod:Modifier = noteModData.noteMods[i];
        if (mod.targetLane == -1 || mod.targetLane == lane) sampleNoteMods.push(mod);
      }
    }
  }

  // Call this function to sample where a note would be at this strum position.
  function susSample(strumTimmy:Float, isRoot:Bool = false, dumbHeight:Float = 0):Void
  {
    final strumNote:StrumNote = whichStrumNote;
    final strumExtraData = strumNote.strumExtraModData;
    strumTimmy -= strumExtraData.strumPos;
    final notePos:Float = parentStrumline.calculateNoteYPos(strumTimmy);
    final lane:Int = noteDirection % (ExtraKeys.mania + 1);

    if (
      parentStrumline.mods.mathCutOffCheck(notePos, noteDirection % 4)
      || (
        !isRoot
        && strumExtraData.noHoldMathShortcut < 0.5
        && hitNote
        && !missedNote
        && ((notePos < 0.5 && !flipY) || (notePos > -0.5 && flipY))
      )
    )
    {
      return;
    }

    resetFakeNote();
    noteModData.defaultValues();
    noteModData.alpha = fakeNote.alpha;
    noteModData.scaleX = fakeNote.scale.x;
    noteModData.scaleY = fakeNote.scale.y;
    noteModData.strumTime = strumTimmy;
    noteModData.direction = lane;
    noteModData.curPos_unscaled = notePos;
    noteModData.whichStrumNote = strumNote;
    noteModData.noteType = "path";
    noteModData.noteKind = "path";
    noteModData.width = graphicWidth;
    noteModData.height = 0;

    var scrollMult:Float = 1.0;
    for (i in 0...sampleSpeedMods.length)
    {
      scrollMult *= sampleSpeedMods[i].speedMath(lane, notePos, parentStrumline, true);
    }
    for (i in 0...sampleNoteMods.length)
    {
      scrollMult *= sampleNoteMods[i].speedMath(lane, notePos, parentStrumline, true);
    }
    noteModData.speedMod = scrollMult;

    // Position like vanilla
    noteModData.x = parentStrumline.x;
    noteModData.x += parentStrumline.getXPos(noteModData.direction % (ExtraKeys.mania+1));
    noteModData.x += Strumline.STRUMLINE_SIZE / 2;
    noteModData.x -= graphicWidth / 2;

    // Then offset based on the movement from the default strum position so movement it still tied to the strum receptors.
    // getDefaultStrumPos() allocates a three-element array, but this sample
    // only needs X and that value is exactly formerPosition.x.
    final xDif:Float = whichStrumNote.x - whichStrumNote.formerPosition.x;
    noteModData.x += xDif;

    final sillyPos:Float = notePos * scrollMult;
    if (flipY)
    {
      noteModData.y = (strumNote.y + sillyPos + Strumline.STRUMLINE_SIZE / 2);
    }
    else
    {
      noteModData.y = (strumNote.y - Strumline.INITIAL_OFFSET + sillyPos + Strumline.STRUMLINE_SIZE / 2);
    }

    // noteModData.x -= whichStrumNote.strumExtraModData.noteStyleOffsetX; // undo strum offset
    noteModData.y -= strumExtraData.noteStyleOffsetY;

    noteModData.z = strumNote.z;
    noteModData.curPos = sillyPos;

    for (i in 0...sampleArrowpathMods.length)
    {
      sampleArrowpathMods[i].noteMath(noteModData, parentStrumline, true, true);
    }

    for (i in 0...sampleNoteMods.length)
    {
      sampleNoteMods[i].noteMath(noteModData, parentStrumline, true, true);
    }

    noteModData.funnyOffMyself();

    is3D = strumExtraData.threeD;
    // old3Dholds = (whichStrumNote.strumExtraModData?.old3Dholds ?? false);
    old3Dholds = noteModData.old3Dholds;

    fakeNote.applyNoteData(noteModData, !is3D);

    fakeNote.scale.x *= noteModData.scaleX2; // Account for scale2! Don't need to worry about angle... for now?
    fakeNote.scale.y *= noteModData.scaleY2;

    if (flipY) fakeNote.y += 27; // fix gap for downscroll. Moved from verts so it is applied before perspective fucks it up!

    if (old3Dholds || !is3D)
    {
      tempVec2.setTo(fakeNote.x, fakeNote.y);
      perspectiveShift.z = ModConstants.applyPerspective_returnScale(fakeNote, graphicWidth, 8, noteModData.perspectiveOffset);
      perspectiveShift.x = fakeNote.x - tempVec2.x;
      perspectiveShift.y = fakeNote.y - tempVec2.y;
    }
    else
    {
      perspectiveShift.x = 0;
      perspectiveShift.y = 0;
    }

    var scaleX = FlxMath.remapToRange(fakeNote.scale.x, 0, ModConstants.arrowPathScale, 0, 1);
    var scaleY = FlxMath.remapToRange(fakeNote.scale.y, 0, ModConstants.arrowPathScale, 0, 1);

    final forwardHolds:Bool = noteModData.usingForwardHolds();
    final straightHoldsModAmount:Float = noteModData.straightHolds;

    if (isRoot)
    {
      if (previousPiece != null)
      {
        holdRootX = previousPiece.holdRootX;
        holdRootY = previousPiece.holdRootY;
        holdRootZ = previousPiece.holdRootZ;
        // holdRootAngle = previousPiece.holdRootAngle;
        holdRootScaleX = previousPiece.holdRootScaleX;
        holdRootScaleY = previousPiece.holdRootScaleY;
      }
      else
      {
        holdRootX = fakeNote.x;
        holdRootY = fakeNote.y;
        holdRootZ = fakeNote.z;
        holdRootScaleX = scaleX;
        holdRootScaleY = scaleY;
      }
    }
    else
    {
      if (forwardHolds) // Prevents holds from going backwards
      {
        var flipThingy:Bool = flipY;
        if (noteModData.getReverse() > 0.5)
        {
          flipThingy = !flipThingy;
        }

        if ((flipThingy && fakeNote.y > holdRootY) || (!flipThingy && fakeNote.y < holdRootY))
        {
          fakeNote.y = FlxMath.lerp(fakeNote.y, holdRootY, 1.0);
        }
      }

      if (straightHoldsModAmount != 0)
      {
        fakeNote.x = FlxMath.lerp(fakeNote.x, holdRootX, straightHoldsModAmount);
        fakeNote.z = FlxMath.lerp(fakeNote.z, holdRootZ, straightHoldsModAmount);
        scaleX = FlxMath.lerp(scaleX, holdRootScaleX, straightHoldsModAmount);
        scaleY = FlxMath.lerp(scaleY, holdRootScaleY, straightHoldsModAmount);
      }
    }
    fakeNote.scale.set(scaleX, scaleY);

    if (!is3D || old3Dholds)
    {
      ModConstants.playfieldSkew(
        fakeNote,
        noteModData.skewX_playfield,
        noteModData.skewY_playfield,
        whichStrumNote.strumExtraModData.playfieldX,
        whichStrumNote.strumExtraModData.playfieldY,
        (graphicWidth / 2),
        0
      );
      // undo the strum skew
      fakeNote.x -= whichStrumNote.strumExtraModData.skewMovedX;
      fakeNote.y -= whichStrumNote.strumExtraModData.skewMovedY;
      fakeNote.skew.x += noteModData.skewX_playfield;
      fakeNote.skew.y += noteModData.skewY_playfield;
    }

    // temp fix for sus notes covering the entire fucking screen
    if (fakeNote.z > zCutOff)
    {
      fakeNote.alpha = 0;
      fakeNote.scale.set(0.0, 0.0);
    }

    // These values are constant for all vertices generated from this sample.
    // Keep the old/fake-3D path untouched; it does not use these cached values.
    if (is3D && !old3Dholds)
    {
      projectionSkewTan = fakeNote.skew.y != 0 ? Math.tan(fakeNote.skew.y * FlxAngle.TO_RAD) : 0.0;
      projectionSkewXPlayfieldTan = noteModData.skewX_playfield != 0
        ? Math.tan(noteModData.skewX_playfield * FlxAngle.TO_RAD) : 0.0;
      projectionSkewYPlayfieldTan = noteModData.skewY_playfield != 0
        ? Math.tan(noteModData.skewY_playfield * FlxAngle.TO_RAD) : 0.0;
      projectionSkewZPlayfieldTan = noteModData.skewZ_playfield != 0
        ? Math.tan(noteModData.skewZ_playfield * FlxAngle.TO_RAD) : 0.0;

      if (noteModData.angleY != 0)
      {
        final angleYRad:Float = noteModData.angleY * FlxAngle.TO_RAD;
        projectionAngleYCos = FlxMath.fastCos(angleYRad);
        projectionAngleYSin = FlxMath.fastSin(angleYRad);
      }
      else
      {
        projectionAngleYCos = 1.0;
        projectionAngleYSin = 0.0;
      }
    }
  }

  var zCutOff:Float = 835;
  var is3D:Bool = false;

  function applyPerspective(pos:Vector3D, rotatePivot:Vector2):Vector2
  {
    if (vibrateEffect != 0)
    {
      pos.x += FlxG.random.float(-1, 1) * vibrateEffect;
      pos.y += FlxG.random.float(-1, 1) * vibrateEffect;
      pos.z += FlxG.random.float(-1, 1) * vibrateEffect;
    }

    if (!is3D || old3Dholds)
    {
      tempVec2.setTo(pos.x, pos.y);

      // apply skew
      // Currently doesn't work when the sustain moves on the z axis!
      var xPercent_SkewOffset:Float =
        tempVec2.x
        - fakeNote.x
        - (graphicWidth / 2 * (perspectiveShift.z)); // this is dumb but at least for the time being, it makes the disconnect less bad.
      if (fakeNote.skew.y != 0) tempVec2.y += xPercent_SkewOffset * Math.tan(fakeNote.skew.y * FlxAngle.TO_RAD);
      return tempVec2;
    }
    else
    {
      tempVec3.setTo(pos.x, pos.y, pos.z);

      // apply skew
      var xPercent_SkewOffset:Float = tempVec3.x - fakeNote.x - (graphicWidth / 2);
      if (fakeNote.skew.y != 0) tempVec3.y += xPercent_SkewOffset * projectionSkewTan;

      // Rotate around Y. angleY and its trigonometric values are shared by all
      // vertices for the current susSample(), unlike the varying spiral angle.
      final angleY:Float = noteModData.angleY;

      tempVec2.setTo(tempVec3.x, tempVec3.z);
      clipPerspectivePivot.setTo(rotatePivot.x, tempVec3.z);
      final rotateModPivotPoint:Vector2 = clipPerspectivePivot;
      if (angleY != 0)
      {
        rotateAroundInPlaceCached(rotateModPivotPoint, tempVec2, projectionAngleYCos, projectionAngleYSin);
      }
      tempVec3.x = tempVec2.x;
      tempVec3.z = tempVec2.y;

      // v0.8.0a -> playfield skewing
      var playfieldSkewOffset_Y:Float = pos.x - (whichStrumNote?.strumExtraModData?.playfieldX ?? FlxG.width / 2);
      var playfieldSkewOffset_X:Float = pos.y - (whichStrumNote?.strumExtraModData?.playfieldY ?? FlxG.height / 2);

      if (noteModData.skewX_playfield != 0) tempVec3.x += playfieldSkewOffset_X * projectionSkewXPlayfieldTan;
      if (noteModData.skewY_playfield != 0) tempVec3.y += playfieldSkewOffset_Y * projectionSkewYPlayfieldTan;

      var playfieldSkewOffset_Z:Float = pos.y - (whichStrumNote?.strumExtraModData?.playfieldY ?? FlxG.height / 2);
      if (noteModData.skewZ_playfield != 0) tempVec3.z += playfieldSkewOffset_Z * projectionSkewZPlayfieldTan;

      tempVec3.z *= 0.001;
      final thisNotePos:Vector3D = ModConstants.perspectiveMath(tempVec3, 0, 0, noteModData.perspectiveOffset);
      tempVec2.setTo(thisNotePos.x, thisNotePos.y);
      return tempVec2;
    }
  }

  function rotateAroundInPlaceCached(origin:Vector2, point:Vector2, cos:Float, sin:Float):Vector2
  {
    final dx:Float = point.x - origin.x;
    final dy:Float = point.y - origin.y;
    point.setTo(origin.x + cos * dx - sin * dy, origin.y + sin * dx + cos * dy);
    return point;
  }

  function rotateAroundInPlace(origin:Vector2, point:Vector2, degrees:Float):Vector2
  {
    if (degrees == 0) return point;
    final angle:Float = degrees * FlxAngle.TO_RAD;
    final dx:Float = point.x - origin.x;
    final dy:Float = point.y - origin.y;
    final cos:Float = FlxMath.fastCos(angle);
    final sin:Float = FlxMath.fastSin(angle);
    point.setTo(origin.x + cos * dx - sin * dy, origin.y + sin * dx + cos * dy);
    return point;
  }

  var spiralHoldOldMath:Bool = false;
  var tinyOffsetForSpiral:Float = 0.01;
  var lastOrientAngle:Float = 0; // same bandaid fix for orient.
  private var holdRootX:Float = 0.0;
  private var holdRootY:Float = 0.0;
  private var holdRootZ:Float = 0.0;
  // private var holdRootAngle:Float = 0.0;
  // private var holdRootAlpha:Float = 0.0;
  private var holdRootScaleX:Float = 1.0;
  private var holdRootScaleY:Float = 1.0;

  private function clipTimeThing(songTimmy:Float, strumtimm:Float, piece:Int = 0):Float
  {
    var returnVal:Float = 0.0;
    // if (hitNote && !missedNote) returnVal = songTimmy - strumTime;
    if (!(hitNote && !missedNote)) return 0.0;
    if (songTimmy >= strumtimm)
    {
      returnVal = songTimmy - strumtimm;
      returnVal -= (grain * tinyOffsetForSpiral) * piece;
    }
    if (returnVal < 0) returnVal = 0;
    return returnVal;
  }

  // If set to false, will disable the hold being hidden when being dropped
  public var hideOnMiss:Bool = true;
  // The angle the hold note is coming from with spiral holds! used for hold covers!
  public var baseAngle:Float = 0;
  // TEST
  // public var distanceFromReceptor_pos:Float = 0;
  public var distanceFromReceptor_unscaledpos:Float = 0;
  // The lower the number, the more hold segments are rendered and calculated!
  public var grain:Float = ModConstants.defaultHoldGrain;

  var bodyLength:Float = 0;

  /**
   * Sets up new vertex and UV data to clip the trail.
   * @param songTime	The time to clip the note at, in milliseconds.
   * @param uvSetup	Should UV's be updated?.
   */
  public function updateClipping_mods(songTime:Float = 0, uvSetup:Bool = true):Void
  {
    // Skip all the logic if this note is considered a 'miss' and we already was hit.
    if (hitNote && missedNote && hideOnMiss)
    {
      visible = false;
      return;
    }

    #if debug
    final arrowPathClipStart:Float = isArrowPathPiece ? haxe.Timer.stamp() : 0;
    #end

    // Make sure we're at the proper position!
    // This is cuz hold notes are always set to this exact position, then the tris are set to make it appear where it needs to be on the screen.
    // Done cuz I'm lazy and it made the calcs easier lol
    this.x = ModConstants.holdNoteJankX;
    this.y = ModConstants.holdNoteJankY;
    if (fakeNote == null) fakeNote = new ZSprite();
    var songTimmy:Float = (ModConstants.getSongPosition());
    whichStrumNote = parentStrumline.getByColumn(noteDirection);

    // Moved the first susSample point to be much earlier so that we can also get the current mod values for how we should render he rest of this hold
    // (such as are we using spiral holds for example?)
    final clippingTimeOffset:Float = clipTimeThing(songTimmy, strumTime);
    extraHoldRootInfo(this.strumTime);
    prepareSampleModifiers();
    susSample(this.strumTime + clippingTimeOffset, true, 0);

    grain = noteModData?.holdGrain ?? ModConstants.defaultPathGrain;

    // Long hold logic:
    var longHolds:Float = noteModData?.longHolds ?? 0;
    longHolds += 1;

    final endPixelSize:Float = graphic.height * endOffset * zoom;
    final scroll:Float = parentStrumline?.scrollSpeed ?? 1.0;
    final endCapTime:Float = endPixelSize / (Constants.PIXELS_PER_MS * scroll);

    // bodyLength refers to the entire sustainLength MINUS the end cap.
    bodyLength = renderEnd ? fullSustainLength - endCapTime : fullSustainLength;
    if (bodyLength < 0) bodyLength = 0;
    final sussyLength:Float = bodyLength;

    holdResolution = Math.floor(sussyLength * longHolds / grain);

    if (holdResolution < 1) // To ensure UV's dont break (lol???)
    {
      holdResolution = 1;
    }

    // Arrow-path pieces are only a visual guide, not score-bearing sustain
    // geometry. Keep the curve smooth enough to read while bounding the amount
    // of modifier math performed on every frame.
    if (isArrowPathPiece && holdResolution > MAX_ARROWPATH_SAMPLES)
    {
      holdResolution = MAX_ARROWPATH_SAMPLES;
    }

    // Renders the holds to face the direction of travel.
    final spiralHolds:Bool = noteModData.usingSpiralHolds();

    final holdNoteJankX:Float = ModConstants.holdNoteJankX * -1;
    final holdNoteJankY:Float = ModConstants.holdNoteJankY * -1;

    var testCol:Array<Int> = clipColorBuffer;
    var vertices:Array<Float> = clipVertexBuffer;
    var uvtData:Array<Float> = clipUVBuffer;
    var noteIndices:Array<Int> = clipIndexBuffer;
    testCol.resize(0);
    vertices.resize(0);
    uvtData.resize(0);
    noteIndices.resize(0);

    // to keep the face normal facing towards the camera for culling.
    var dumbAlt:Bool = true;
    for (i in 0...Std.int(holdResolution * 2))
    {
      if (dumbAlt)
      {
        noteIndices.push(i + 0);
        noteIndices.push(i + 2);
        noteIndices.push(i + 1);
      }
      else
      {
        noteIndices.push(i + 0);
        noteIndices.push(i + 1);
        noteIndices.push(i + 2);
      }
      dumbAlt = !dumbAlt;
    }
    // add cap
    var highestNumSoFar_:Int = Std.int((holdResolution * 2) - 1 + 2);
    noteIndices.push(highestNumSoFar_ + 0 + 1);
    noteIndices.push(highestNumSoFar_ + 2 + 1);
    noteIndices.push(highestNumSoFar_ + 1 + 1);

    noteIndices.push(highestNumSoFar_ + 0 + 2);
    noteIndices.push(highestNumSoFar_ + 1 + 2);
    noteIndices.push(highestNumSoFar_ + 2 + 2);

    var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength - (songTime - strumTime), parentStrumline?.scrollSpeed ?? 1.0), 0, graphicHeight);
    visible = true;

    final holdWidth = graphicWidth;

    var scaleTest = fakeNote.scale.x;
    var widthScaled = holdWidth * scaleTest;
    var scaleChange = widthScaled - holdWidth;
    var holdLeftSide = 0 - (scaleChange / 2);
    var holdRightSide = widthScaled - (scaleChange / 2);

    // ===HOLD VERTICES==
    // V0.7.4a -> Updated UV textures to not be stupid anymore. (0 -> 1 -> 2 -> 3) since we can just use the repeating texture power of drawTriangles.

    var uvClip:Float = 0.0;
    if (hitNote && !missedNote && (sussyLength * longHolds) > 0)
    {
      // Fraction of the (possibly lengthened) hold that has been clipped, in UV units
      uvClip = (clippingTimeOffset / (sussyLength * longHolds)) * holdResolution;
      uvClip = Math.max(0, uvClip);
    }
    if (uvSetup)
    {
      uvtData[0 * 2] = (1 / 4) * (noteDirection % 4); // 0%/25%/50%/75% of the way through the image
      uvtData[0 * 2 + 1] = uvClip;
      uvtData[1 * 2] = uvtData[0 * 2] + (1 / 8); // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
      uvtData[1 * 2 + 1] = uvClip;
    }

    // grab left vert
    var rotateOrigin:Vector2 = clipRotateOrigin;
    rotateOrigin.setTo(fakeNote.x + holdLeftSide, fakeNote.y);
    // move rotateOrigin to be inbetween the left and right vert so it's centered
    rotateOrigin.x += ((fakeNote.x + holdRightSide) - (fakeNote.x + holdLeftSide)) / 2;
    tempVec3.setTo(fakeNote.x + holdLeftSide, fakeNote.y, fakeNote.z);
    var vert:Vector2 = applyPerspective(tempVec3, rotateOrigin);

    // Top left
    vertices[0 * 2] = vert.x; // Inline with left side
    vertices[0 * 2 + 1] = vert.y;

    testCol[0 * 2] = fakeNote.color;
    testCol[0 * 2 + 1] = fakeNote.color;
    testCol[1 * 2] = fakeNote.color;
    testCol[1 * 2 + 1] = fakeNote.color;

    this.color = fakeNote.color;
    this.alpha = fakeNote.alpha;
    this.z = fakeNote.z; // for z ordering

    if (useHSVShader && this.hsvShader != null)
    {
      this.hsvShader.stealthGlow = fakeNote.stealthGlow;
      this.hsvShader.stealthGlowBlue = fakeNote.stealthGlowBlue;
      this.hsvShader.stealthGlowGreen = fakeNote.stealthGlowGreen;
      this.hsvShader.stealthGlowRed = fakeNote.stealthGlowRed;
    }

    // Top right
    tempVec3.setTo(fakeNote.x + holdRightSide, fakeNote.y, fakeNote.z);
    vert = applyPerspective(tempVec3, rotateOrigin);
    vertices[1 * 2] = vert.x;
    vertices[1 * 2 + 1] = vert.y; // Inline with top left vertex

    var holdPieceStrumTime:Float = 0.0;

    var previousSampleX:Float = fakeNote.x;
    var previousSampleY:Float = fakeNote.y;

    var rightSideOffX:Float = 0;
    var rightSideOffY:Float = 0;

    // THE REST, HOWEVER...
    for (k in 0...holdResolution)
    {
      var i:Int = (k + 1) * 2;

      holdPieceStrumTime = this.strumTime + ((sussyLength / holdResolution) * (k + 1) * longHolds);
      var tm:Float = holdPieceStrumTime;
      if (spiralHolds && !spiralHoldOldMath)
      {
        // ever so slightly offset the time so that it never hits 0, 0 on the strum time so spiral hold can do its magic
        tm += (k + 1) * (grain * tinyOffsetForSpiral);
      }
      susSample(tm + clipTimeThing(songTimmy, holdPieceStrumTime), false, sussyLength / holdResolution);

      scaleTest = fakeNote.scale.x;
      widthScaled = holdWidth * scaleTest;
      scaleChange = widthScaled - holdWidth;
      holdLeftSide = 0 - (scaleChange / 2);
      holdRightSide = widthScaled - (scaleChange / 2);

      // grab left vert
      var rotateOrigin:Vector2 = clipRotateOrigin;
      rotateOrigin.setTo(fakeNote.x + holdLeftSide, fakeNote.y);
      // move rotateOrigin to be inbetween the left and right vert so it's centered
      rotateOrigin.x += ((fakeNote.x + holdRightSide) - (fakeNote.x + holdLeftSide)) / 2;

      tempVec3.setTo(fakeNote.x + holdLeftSide, fakeNote.y, fakeNote.z);
      var vert:Vector2 = applyPerspective(tempVec3, rotateOrigin);

      // Bottom left
      vertices[i * 2] = vert.x; // Inline with left side
      vertices[i * 2 + 1] = vert.y;

      if (spiralHolds && spiralHoldOldMath)
      {
        var calculateAngleDif:Float = 0;
        var a:Float = (fakeNote.y - previousSampleY) * -1; // height
        var b:Float = (fakeNote.x - previousSampleX); // length
        var angle:Float = Math.atan(b / a);
        angle *= (180 / Math.PI);
        calculateAngleDif = angle;
        tempVec2.setTo(vertices[i * 2], vertices[i * 2 + 1]);
        clipRotatePoint.setTo(fakeNote.x + holdRightSide, vertices[i * 2 + 1]);
        var thing:Vector2 = rotateAroundInPlace(tempVec2, clipRotatePoint, calculateAngleDif);
        rightSideOffX = thing.x;
        rightSideOffY = thing.y;
        previousSampleX = fakeNote.x;
        previousSampleY = fakeNote.y;
        if (k == 0) // to orient the root of the hold properly!
        {
          var scuffedDifferenceX:Float = fakeNote.x + holdRightSide - rightSideOffX;
          var scuffedDifferenceY:Float = vertices[i * 2 + 1] - rightSideOffY;
          vertices[(i + 1 - 2) * 2] -= scuffedDifferenceX;
          vertices[(i + 1 - 2) * 2 + 1] -= scuffedDifferenceY;
        }
        // Bottom right
        vertices[(i + 1) * 2] = rightSideOffX;
        vertices[(i + 1) * 2 + 1] = rightSideOffY;
      }
      else if (spiralHolds)
      {
        var affectRoot:Bool = (k == 0);
        var angle:Float = 0;
        var a:Float = (fakeNote.y - previousSampleY) * -1; // height
        var b:Float = (fakeNote.x - previousSampleX); // length
        if (!(a == 0 && b == 0)) // if we're in the same spot...
        {
          angle = Math.atan2(b, a);
          lastOrientAngle = angle;
        }
        else
        {
          angle = lastOrientAngle; // alternatively, instead of previous sample we could try sampling forward instead of where we *would* be without any clipping being applied
        }
        var calculateAngleDif:Float = angle * (180 / Math.PI);

        // rotate right point
        var rotatePoint:Vector2 = clipRotatePoint;
        rotatePoint.setTo(fakeNote.x + holdRightSide, fakeNote.y);
        var thing:Vector2 = rotateAroundInPlace(rotateOrigin, rotatePoint, calculateAngleDif);
        tempVec3.setTo(thing.x, thing.y, fakeNote.z);
        thing = applyPerspective(tempVec3, rotateOrigin);
        rightSideOffX = thing.x;
        rightSideOffY = thing.y;

        // Bottom right
        vertices[(i + 1) * 2] = rightSideOffX;
        vertices[(i + 1) * 2 + 1] = rightSideOffY;

        // left
        rotatePoint.setTo(fakeNote.x + holdLeftSide, fakeNote.y);
        thing = rotateAroundInPlace(rotateOrigin, rotatePoint, calculateAngleDif);
        tempVec3.setTo(thing.x, thing.y, fakeNote.z);
        thing = applyPerspective(tempVec3, rotateOrigin);
        rightSideOffX = thing.x;
        rightSideOffY = thing.y;

        vertices[(i) * 2] = rightSideOffX;
        vertices[(i) * 2 + 1] = rightSideOffY;

        if (affectRoot)
        {
          baseAngle = calculateAngleDif;

          var rotateOrigin_rooter:Vector2 = clipRotateRoot;
          rotateOrigin_rooter.setTo(vertices[(i - 2) * 2], vertices[(i - 2) * 2 + 1]);
          // move rotateOrigin to be inbetween the left and right vert so it's centered
          rotateOrigin_rooter.x += (vertices[(i - 2 + 1) * 2] - vertices[(i - 2) * 2]) / 2;

          rotatePoint.setTo(vertices[(i - 2) * 2], vertices[(i - 2) * 2 + 1]);
          thing = rotateAroundInPlace(rotateOrigin_rooter, rotatePoint, calculateAngleDif);

          vertices[(i - 2) * 2] = thing.x;
          vertices[(i - 2) * 2 + 1] = thing.y;

          rotatePoint.setTo(vertices[(i - 2 + 1) * 2], vertices[(i - 2 + 1) * 2 + 1]);
          thing = rotateAroundInPlace(rotateOrigin_rooter, rotatePoint, calculateAngleDif);

          vertices[(i - 2 + 1) * 2] = thing.x;
          vertices[(i - 2 + 1) * 2 + 1] = thing.y;
        }
        previousSampleX = fakeNote.x;
        previousSampleY = fakeNote.y;
      }
      else
      {
        // Bottom right
        tempVec3.setTo(fakeNote.x + holdRightSide, fakeNote.y, fakeNote.z);
        var vert:Vector2 = applyPerspective(tempVec3, rotateOrigin);
        vertices[(i + 1) * 2] = vert.x;
        vertices[(i + 1) * 2 + 1] = vert.y;
      }

      testCol[i * 2] = fakeNote.color;
      testCol[i * 2 + 1] = fakeNote.color;
      testCol[(i + 1) * 2] = fakeNote.color;
      testCol[(i + 1) * 2 + 1] = fakeNote.color;
    }

    if (uvSetup)
    {
      for (k in 0...holdResolution)
      {
        final i = (k + 1) * 2;

        // Bottom left
        uvtData[i * 2] = uvtData[0 * 2]; // 0%/25%/50%/75% of the way through the image
        final originalV:Float = 1 * (k + 1);
        uvtData[i * 2 + 1] = Math.max(originalV, uvClip);

        // Bottom right
        uvtData[(i + 1) * 2] = uvtData[1 * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
        uvtData[(i + 1) * 2 + 1] = uvtData[i * 2 + 1]; // bottom bound
      }
    }

    // === END CAP VERTICES ===
    if (renderEnd)
    {
      final endvertsoftrail:Int = (holdResolution * 2);
      var highestNumSoFar:Int = endvertsoftrail + 2;

      // Top left
      vertices[highestNumSoFar * 2] = vertices[endvertsoftrail * 2]; // Inline with bottom left vertex of hold
      vertices[highestNumSoFar * 2 + 1] = vertices[endvertsoftrail * 2 + 1]; // Inline with bottom left vertex of hold
      testCol[highestNumSoFar * 2] = testCol[endvertsoftrail * 2];
      testCol[highestNumSoFar * 2 + 1] = testCol[endvertsoftrail * 2 + 1];

      // Top right
      highestNumSoFar += 1;
      vertices[highestNumSoFar * 2] = vertices[(endvertsoftrail + 1) * 2]; // Inline with bottom right vertex of hold
      vertices[highestNumSoFar * 2 + 1] = vertices[(endvertsoftrail + 1) * 2 + 1]; // Inline with bottom right vertex of hold
      testCol[highestNumSoFar * 2] = testCol[(endvertsoftrail + 1) * 2]; // Inline with bottom right vertex of hold
      testCol[highestNumSoFar * 2 + 1] = testCol[(endvertsoftrail + 1) * 2 + 1]; // Inline with bottom right vertex of hold

      // The bottom verts needs to be sampled from time!

      final sillyEndOffset:Float = endPixelSize / (Constants.PIXELS_PER_MS * scroll) * 1.75; // the magic number still lives
      holdPieceStrumTime = this.strumTime + (sussyLength * longHolds) + sillyEndOffset;
      var tm_end:Float = holdPieceStrumTime;
      if (spiralHolds && !spiralHoldOldMath)
      {
        tm_end += holdResolution * (grain * tinyOffsetForSpiral); // ever so slightly offset the time so that it never hits 0, 0 on the strum time so spiral hold can do its magic
      }
      susSample(tm_end + clipTimeThing(songTimmy, holdPieceStrumTime), false, sillyEndOffset);

      scaleTest = fakeNote.scale.x;
      widthScaled = holdWidth * scaleTest;
      scaleChange = widthScaled - holdWidth;
      holdLeftSide = 0 - (scaleChange / 2);
      holdRightSide = widthScaled - (scaleChange / 2);

      // Bottom left
      highestNumSoFar += 1;

      // grab left vert
      var rotateOrigin:Vector2 = clipRotateOrigin;
      rotateOrigin.setTo(fakeNote.x + holdLeftSide, fakeNote.y);
      // move rotateOrigin to be inbetween the left and right vert so it's centered
      rotateOrigin.x += ((fakeNote.x + holdRightSide) - (fakeNote.x + holdLeftSide)) / 2;

      tempVec3.setTo(fakeNote.x + holdLeftSide, fakeNote.y, fakeNote.z);
      vert = applyPerspective(tempVec3, rotateOrigin);
      vertices[highestNumSoFar * 2] = vert.x;
      vertices[highestNumSoFar * 2 + 1] = vert.y;
      testCol[highestNumSoFar * 2] = fakeNote.color;
      testCol[highestNumSoFar * 2 + 1] = fakeNote.color;

      // Bottom right
      highestNumSoFar += 1;
      tempVec3.setTo(fakeNote.x + holdRightSide, fakeNote.y, fakeNote.z);
      vert = applyPerspective(tempVec3, rotateOrigin);
      vertices[highestNumSoFar * 2] = vert.x;
      vertices[highestNumSoFar * 2 + 1] = vert.y;
      testCol[highestNumSoFar * 2] = fakeNote.color;
      testCol[highestNumSoFar * 2 + 1] = fakeNote.color;
      if (spiralHolds && !spiralHoldOldMath)
      {
        var a:Float = (fakeNote.y - previousSampleY) * -1; // height
        var b:Float = (fakeNote.x - previousSampleX); // length
        var angle:Float = Math.atan2(b, a);
        var calculateAngleDif:Float = angle * (180 / Math.PI);

        var ybeforerotate:Float = vertices[(highestNumSoFar - 1) * 2 + 1];

        // grab left vert
        rotateOrigin.setTo(vertices[(highestNumSoFar - 1) * 2], vertices[(highestNumSoFar - 1) * 2 + 1]);
        // move rotateOrigin to be inbetween the left and right vert so it's centered
        rotateOrigin.x += (vertices[highestNumSoFar * 2] - rotateOrigin.x) / 2;

        // rotate right point
        var rotatePoint:Vector2 = clipRotatePoint;
        rotatePoint.setTo(vertices[highestNumSoFar * 2], vertices[highestNumSoFar * 2 + 1]);

        var thing = rotateAroundInPlace(rotateOrigin, rotatePoint, calculateAngleDif);

        vertices[highestNumSoFar * 2 + 1] = thing.y;
        vertices[highestNumSoFar * 2] = thing.x;

        rotatePoint.setTo(vertices[(highestNumSoFar - 1) * 2], ybeforerotate);
        var thing = rotateAroundInPlace(rotateOrigin, rotatePoint, calculateAngleDif);
        vertices[(highestNumSoFar - 1) * 2 + 1] = thing.y;
        vertices[(highestNumSoFar - 1) * 2] = thing.x;
      }
      else if (spiralHolds && spiralHoldOldMath)
      {
        var calculateAngleDif:Float = 0;
        var a:Float = (fakeNote.y - previousSampleY) * -1; // height
        var b:Float = (fakeNote.x - previousSampleX); // length
        var angle:Float = Math.atan(b / a);
        angle *= (180 / Math.PI);
        calculateAngleDif = angle;

        tempVec2.setTo(vertices[(highestNumSoFar - 1) * 2], vertices[(highestNumSoFar - 1) * 2 + 1]);
        clipRotatePoint.setTo(vertices[highestNumSoFar * 2], vertices[highestNumSoFar * 2 + 1]);
        var thing = rotateAroundInPlace(tempVec2, clipRotatePoint, calculateAngleDif);
        vertices[highestNumSoFar * 2 + 1] = thing.y;
        vertices[highestNumSoFar * 2] = thing.x;
      }

      if (uvSetup)
      {
        highestNumSoFar = (holdResolution * 2) + 2;

        var endClipAmount:Float = 0.0;
        if (hitNote && !missedNote && sillyEndOffset > 0)
        {
          // Time that has been clipped past the end of the body
          final timePastBody:Float = clipTimeThing(songTimmy, this.strumTime + (sussyLength * longHolds));
          endClipAmount = FlxMath.bound(timePastBody / sillyEndOffset, 0, 1);
        }

        var capTopV:Float = endClipAmount * bottomClip;

        // === END CAP UVs ===
        // Top left
        uvtData[highestNumSoFar * 2] = uvtData[2 * 2] + (1 / 8); // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
        uvtData[highestNumSoFar * 2 + 1] = capTopV;

        // Top right
        uvtData[(
          highestNumSoFar
          + 1
        ) * 2] = uvtData[highestNumSoFar * 2] + (1 / 8); // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
        uvtData[(highestNumSoFar + 1) * 2 + 1] = capTopV;

        // Bottom left
        uvtData[(
          highestNumSoFar
          + 2
        ) * 2] = uvtData[highestNumSoFar * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
        uvtData[(highestNumSoFar + 2) * 2 + 1] = bottomClip; // bottom bound

        // Bottom right
        uvtData[(
          highestNumSoFar
          + 3
        ) * 2] = uvtData[(highestNumSoFar + 1) * 2]; // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
        uvtData[(highestNumSoFar + 3) * 2 + 1] = uvtData[(highestNumSoFar + 2) * 2 + 1]; // bottom bound
      }
    }

    for (k in 0...vertices.length)
    {
      if (k % 2 == 1)
      { // all y verts
        vertices[k] += holdNoteJankY;
      }
      else
      {
        vertices[k] += holdNoteJankX;

        // If for whatever reason we need to rotate based on angle (like cuz of a draw func for playfields?)
        if (this.angle != 0 && vertices.length % 2 == 0)
        {
          // assume +1 means we access the y vert
          tempVec2.setTo(vertices[k], vertices[k + 1]);
          clipRotateOrigin.setTo(holdRootX, holdRootY);
          rotateAroundInPlace(clipRotateOrigin, tempVec2, this.angle);
          vertices[k] = tempVec2.x;
          vertices[k + 1] = tempVec2.y;
        }
      }
    }
    setVerts(vertices);
    setIndices(noteIndices);
    if (colors == null || colors.length != testCol.length)
    {
      colors = new DrawData<Int>(testCol.length, false, testCol);
    }
    else
    {
      for (k in 0...testCol.length)
      {
        colors[k] = testCol[k];
      }
    }

    if (uvSetup)
    {
      // V0.8.0a -> Can now modify hold UV's!
      for (k in 0...uvtData.length)
      {
        if (k % 2 == 1)
        { // all y verts
          uvtData[k] -= 0.5;
          uvtData[k] *= uvScale.y;
          uvtData[k] += 0.5;
          uvtData[k] += uvOffset.y;
        }
        else
        {
          uvtData[k] -= 0.5; // try to scale from center
          uvtData[k] *= uvScale.x;
          uvtData[k] += 0.5;
          uvtData[k] += uvOffset.x / 4;
        }
      }

      setUVTData(uvtData);
    }
    waitTillModUpdate = false;

    #if debug
    if (isArrowPathPiece)
    {
      final clipMs:Float = (haxe.Timer.stamp() - arrowPathClipStart) * 1000;
      arrowPathClipPerfCalls++;
      arrowPathClipPerfTotalMs += clipMs;
      if (clipMs > arrowPathClipPerfMaxMs) arrowPathClipPerfMaxMs = clipMs;
      arrowPathClipPerfTotalSamples += holdResolution + (renderEnd ? 2 : 1);
      if (holdResolution > arrowPathClipPerfMaxResolution) arrowPathClipPerfMaxResolution = holdResolution;
      if (sampleSpeedMods.length > arrowPathClipPerfMaxSpeedMods) arrowPathClipPerfMaxSpeedMods = sampleSpeedMods.length;
      if (sampleArrowpathMods.length > arrowPathClipPerfMaxPathMods) arrowPathClipPerfMaxPathMods = sampleArrowpathMods.length;
      if (sampleNoteMods.length > arrowPathClipPerfMaxNoteMods) arrowPathClipPerfMaxNoteMods = sampleNoteMods.length;

      final clipNow:Float = haxe.Timer.stamp();
      if (arrowPathClipPerfLastReport == 0) arrowPathClipPerfLastReport = clipNow;
      if (clipNow - arrowPathClipPerfLastReport >= 2.0)
      {
        final avgClipMs:Float = arrowPathClipPerfCalls > 0 ? arrowPathClipPerfTotalMs / arrowPathClipPerfCalls : 0;
        final avgSamples:Float = arrowPathClipPerfCalls > 0 ? arrowPathClipPerfTotalSamples / arrowPathClipPerfCalls : 0;
        trace('[MODCHART-PERF] arrowPath clip: calls=' + arrowPathClipPerfCalls
          + ', avg=' + Math.round(avgClipMs * 100) / 100 + 'ms'
          + ', max=' + Math.round(arrowPathClipPerfMaxMs * 100) / 100 + 'ms'
          + ', avg samples=' + Math.round(avgSamples * 10) / 10
          + ', max resolution=' + arrowPathClipPerfMaxResolution
          + ', max mods speed/path/note=' + arrowPathClipPerfMaxSpeedMods + '/' + arrowPathClipPerfMaxPathMods + '/' + arrowPathClipPerfMaxNoteMods);
        arrowPathClipPerfCalls = 0;
        arrowPathClipPerfTotalMs = 0;
        arrowPathClipPerfMaxMs = 0;
        arrowPathClipPerfTotalSamples = 0;
        arrowPathClipPerfMaxResolution = 0;
        arrowPathClipPerfMaxSpeedMods = 0;
        arrowPathClipPerfMaxPathMods = 0;
        arrowPathClipPerfMaxNoteMods = 0;
        arrowPathClipPerfLastReport = clipNow;
      }
    }
    #end
  }

  function setVerts(vertices:Array<Float>):Void
  {
    this.vertices_array = vertices;
    setVertices(vertices);
  }

  public var uvScale:Vector2 = new Vector2(1.0, 1.0);
  public var uvOffset:Vector2 = new Vector2(0.0, 0.0);

  /**
   * Sets up new vertex and UV data to clip the trail.
   * If flipY is true, top and bottom bounds swap places.
   * @param songTime	The time to clip the note at, in milliseconds.
   */
  public function updateClipping_Vanilla(songTime:Float = 0):Void
  {
    var clipHeight:Float = sustainHeight(sustainLength - (songTime - strumTime), parentStrumline?.scrollSpeed ?? 1.0).clamp(0, graphicHeight);
    if (clipHeight <= 0.1)
    {
      visible = false;
      return;
    }
    else
    {
      visible = true;
    }

    var bottomHeight:Float = graphic.height * zoom * endOffset;
    var partHeight:Float = clipHeight - bottomHeight;

    // ===HOLD VERTICES==
    // Top left
    vertices[0 * 2] = 0.0; // Inline with left side
    vertices[0 * 2 + 1] = flipY ? clipHeight : graphicHeight - clipHeight;

    // Top right
    vertices[1 * 2] = graphicWidth;
    vertices[1 * 2 + 1] = vertices[0 * 2 + 1]; // Inline with top left vertex

    // Bottom left
    vertices[2 * 2] = 0.0; // Inline with left side
    vertices[2 * 2 + 1] = if (partHeight > 0)
    {
      // flipY makes the sustain render upside down.
      flipY ? 0.0 + bottomHeight : vertices[1] + partHeight;
    }
    else
    {
      vertices[0 * 2 + 1]; // Inline with top left vertex (no partHeight available)
    }

    // Bottom right
    vertices[3 * 2] = graphicWidth;
    vertices[3 * 2 + 1] = vertices[2 * 2 + 1]; // Inline with bottom left vertex

    // ===HOLD UVs===

    // The UVs are a bit more complicated.
    // UV coordinates are normalized, so they range from 0 to 1.
    // We are expecting an image containing 8 horizontal segments, each representing a different colored hold note followed by its end cap.

    uvtData[0 * 2] = 1 / 4 * (noteDirection % 4); // 0%/25%/50%/75% of the way through the image
    uvtData[0 * 2 + 1] = (-partHeight) / graphic.height / zoom; // top bound
    // Top left

    // Top right
    uvtData[1 * 2] = uvtData[0 * 2] + 1 / 8; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
    uvtData[1 * 2 + 1] = uvtData[0 * 2 + 1]; // top bound

    // Bottom left
    uvtData[2 * 2] = uvtData[0 * 2]; // 0%/25%/50%/75% of the way through the image
    uvtData[2 * 2 + 1] = 0.0; // bottom bound

    // Bottom right
    uvtData[3 * 2] = uvtData[1 * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
    uvtData[3 * 2 + 1] = uvtData[2 * 2 + 1]; // bottom bound

    // === END CAP VERTICES ===
    // Top left
    vertices[4 * 2] = vertices[2 * 2]; // Inline with bottom left vertex of hold
    vertices[4 * 2 + 1] = vertices[2 * 2 + 1]; // Inline with bottom left vertex of hold

    // Top right
    vertices[5 * 2] = vertices[3 * 2]; // Inline with bottom right vertex of hold
    vertices[5 * 2 + 1] = vertices[3 * 2 + 1]; // Inline with bottom right vertex of hold

    // Bottom left
    vertices[6 * 2] = vertices[2 * 2]; // Inline with left side
    vertices[6 * 2 + 1] = flipY ? (graphic.height * (-bottomClip + endOffset) * zoom) : (graphicHeight + graphic.height * (bottomClip - endOffset) * zoom);

    // Bottom right
    vertices[7 * 2] = vertices[3 * 2]; // Inline with right side
    vertices[7 * 2 + 1] = vertices[6 * 2 + 1]; // Inline with bottom of end cap

    // === END CAP UVs ===
    // Top left
    uvtData[4 * 2] = uvtData[2 * 2] + 1 / 8; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
    uvtData[4 * 2 + 1] = if (partHeight > 0)
    {
      0;
    }
    else
    {
      (bottomHeight - clipHeight) / zoom / graphic.height;
    };

    // Top right
    uvtData[5 * 2] = uvtData[4 * 2] + 1 / 8; // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
    uvtData[5 * 2 + 1] = uvtData[4 * 2 + 1]; // top bound

    // Bottom left
    uvtData[6 * 2] = uvtData[4 * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
    uvtData[6 * 2 + 1] = bottomClip; // bottom bound

    // Bottom right
    uvtData[7 * 2] = uvtData[5 * 2]; // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
    uvtData[7 * 2 + 1] = uvtData[6 * 2 + 1]; // bottom bound
    waitTillModUpdate = false;
  }

  /**
   * If set to true, will refuse to draw() this sustain. Is always set to false after every modUpdate pass.
   * This is to help prevent holds from flickering for a frame when they get created.
   */
  public var waitTillModUpdate:Bool = false;

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (graphic == null || !this.alive || (waitTillModUpdate && usingHazModHolds)) return;

    // Update tris if modchart system
    if (usingHazModHolds && parentStrumline.doUpdateClipsInDraw)
    {
      updateClipping_mods();

      // Stiching the verts of this sustain to the previous piece verts.
      if (this.previousPiece != null)
      {
        var v_prev:Array<Float> = this.previousPiece.vertices_array;
        var v:Array<Float> = this.vertices_array;

        v[3] = v_prev[v_prev.length - 1];
        v[2] = v_prev[v_prev.length - 2];
        v[1] = v_prev[v_prev.length - 3];
        v[0] = v_prev[v_prev.length - 4];

        this.setVerts(v);
      }
    }

    if (alpha == 0 || vertices == null || visible == false) return;

    var alphaMemory:Float = this.alpha;
    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists) continue;
      // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.

      alpha = alphaMemory * camera.alpha; // Fix for drawTriangles not fading with camera
      alpha *= this.parentStrumline?.alpha ?? 1.0; // Fix for notes not respecting their parents alpha.

      getScreenPosition(_point, camera).subtractPoint(offset);

      camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, true, antialiasing, colorTransform, shader, cullMode);
    }
    this.alpha = alphaMemory;

    #if debug
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  override public function kill():Void
  {
    super.kill();

    if (!((cover?.animation?.name ?? '').startsWith('holdCoverEnd'))) cover?.animation.play('end', true, false, 0);
    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;

    if (cover != null)
    {
      cover.strumNote = null;
      cover.sustainNote = null;
      this.cover = null;
    }
  }

  override public function revive():Void
  {
    super.revive();

    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;
    handledMiss = false;
  }

  public override function destroy():Void
  {
    if (fakeNote != null)
    {
      fakeNote.destroy();
      fakeNote = null;
    }

    previousPiece = null;
    whichStrumNote = null;
    parentStrumline = null;
    noteData = null;
    noteModData = null;
    hsvShader = null;

    // Clear triangle data
    vertices = null;
    indices = null;
    uvtData = null;
    colors = null;
    vertices_array = null;
    super.destroy();
  }

  public function desaturate():Void
  {
    this.hsvShader.saturation = 0.2;
  }

  public function setHue(hue:Float):Void
  {
    this.hsvShader.hue = hue;
  }

  var useHSVShader:Bool = true;

  public var hsvShader:HSVNotesShader = null;
}
