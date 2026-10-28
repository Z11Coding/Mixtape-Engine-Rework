package objects.funkin.graphics;

import backend.modchartSystem.ModConstants;
import backend.modchartSystem.NoteData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import lime.math.Vector2;
import openfl.display.TriangleCulling;
import openfl.geom.Vector3D;

/*
  TODO:
  textureRepeat in updateTris instead of in draw. Can also mean the edit to drawTriangles for repeating textures is no longer needed (though still need to add culling lol so might as well keep it)
 */
class ZSpriteProjected extends ZSprite
{
  // Makes the mesh all wobbly!
  public var vibrateEffect:Float = 0.0;

  public var vertOffsetX:Array<Float> = [];
  public var vertOffsetY:Array<Float> = [];
  public var vertOffsetZ:Array<Float> = [];

  // If enabled, will apply 3D projection to this sprite. If disabled, renders like a normal sprite.
  public var projectionEnabled(default, set):Bool = false;

  function set_projectionEnabled(value:Bool):Bool
  {
    if (projectionEnabled != value) dirty = true;
    projectionEnabled = value;
    return value;
  }

  // If true, will correct the texture distortion created when transforming in 3D
  public var doPerspectiveCorrection:Bool = false;

  // If set to true, will set this sprite to be culled if all the subdivision points are considered "too close" to the camera.
  public var cullIfTooClose:Bool = false;

  // If true, will repeat the texture in the draw call. Otherwise texture will be clamped
  public var textureRepeat:Bool = false;

  // When scaling the UV, will only show the current active frame (instead of showing the entire atlas)
  public var frameBorderCut:Bool = false;

  // The culling this sprite will use (positive, negative, always_positive, always_negative, always, never)
  public var cullMode:String = "none";

  public var angleX:Float = 0;
  public var angleY:Float = 0;

  var angleZ(get, set):Float;

  function get_angleZ():Float
  {
    return this.angle ?? 0;
  }

  function set_angleZ(n:Float):Float
  {
    this.angle = n;
    return this.angle;
  }

  var angleZWithOffset(get, never):Float;

  function get_angleZWithOffset():Float
  {
    return this.angleZ + angleAngularVelocityOffset;
  }

  // for group shit
  public var angleX2:Float = 0;
  public var angleY2:Float = 0;
  public var angleZ2:Float = 0;

  public var scaleZ:Float = 1;

  var scaleX(get, set):Float;

  function get_scaleX():Float
  {
    return this.scale?.x ?? 1;
  }

  function set_scaleX(n:Float):Float
  {
    this.scale.x = n;
    return this.scale.x;
  }

  var scaleY(get, set):Float;

  function get_scaleY():Float
  {
    return this.scale?.y ?? 1;
  }

  function set_scaleY(n:Float):Float
  {
    this.scale.y = n;
    return this.scale.y;
  }

  // 0 means no crop, 1 means fully crop, 0.5 means half cropped. The variable determines the direction of the crop (so crop right will start cropping from the right, leaving the left side).
  // Crop the sprite starting from the left.
  public var cropLeft(default, set):Float = 0;

  function set_cropLeft(n:Float):Float
  {
    this.cropLeft = FlxMath.bound(n, 0.0, 1.0);
    return this.cropLeft;
  }

  // Crop the sprite starting from the right.
  public var cropRight(default, set):Float = 0;

  function set_cropRight(n:Float):Float
  {
    this.cropRight = FlxMath.bound(n, 0.0, 1.0);
    return this.cropRight;
  }

  // Crop the sprite starting from the top.
  public var cropTop(default, set):Float = 0;

  function set_cropTop(n:Float):Float
  {
    this.cropTop = FlxMath.bound(n, 0.0, 1.0);
    return this.cropTop;
  }

  // Crop the sprite starting from the bottom.
  public var cropBottom(default, set):Float = 0;

  function set_cropBottom(n:Float):Float
  {
    this.cropBottom = FlxMath.bound(n, 0.0, 1.0);
    return this.cropBottom;
  }

  var skewY(get, set):Float;

  function get_skewY():Float
  {
    return this.skew?.y ?? 0;
  }

  function set_skewY(n:Float):Float
  {
    this.skew.y = n;
    return this.skew.y;
  }

  var skewX(get, set):Float;

  function get_skewX():Float
  {
    return this.skew?.x ?? 0;
  }

  function set_skewX(n:Float):Float
  {
    this.skew.x = n;
    return this.skew.x;
  }

  public var skewZ:Float = 0;

  // in %
  public var skewX_offset:Float = 0.5;
  public var skewY_offset:Float = 0.5;
  public var skewZ_offset:Float = 0.5;

  // Playfield Skewing
  public var skewX_playfield:Float = 0;
  public var skewY_playfield:Float = 0;
  public var skewZ_playfield:Float = 0;

  // in pixels
  public var playfieldSkewCenterX:Float = FlxG.width / 2;
  public var playfieldSkewCenterY:Float = FlxG.height / 2;
  public var playfieldSkewCenterZ:Float = 0;

  public var fovOffsetX:Float = 0;
  public var fovOffsetY:Float = 0;

  public var pivotOffsetX:Float = 0;
  public var pivotOffsetY:Float = 0;
  public var pivotOffsetZ:Float = 0;

  public var fov:Float = 90;

  // custom setter to prevent values below 0, cuz otherwise we'll divide by 0!
  public var subdivisions(default, set):Int = 0;

  function set_subdivisions(value:Int):Int
  {
    if (subdivisions == value) return subdivisions;

    if (value < 0) value = 0;
    subdivisions = value;
    setUp();
    return subdivisions;
  }

  // The depth of this object (width, length, depth). Defaults to 0 cuz... well... we can only really do flat planes lol
  public var depth:Float = 0;

  /**
   * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
   */
  public var vertices:DrawData<Float> = new DrawData<Float>();

  /**
   * A `Vector` of integers or indexes, where every three indexes define a triangle.
   */
  public var indices:DrawData<Int> = new DrawData<Int>();

  /**
   * A `Vector` of normalized coordinates used to apply texture mapping.
   */
  public var uvtData:DrawData<Float> = new DrawData<Float>();

  var projectionPoint:Vector3D = new Vector3D();
  var rotationPoint:Vector2 = new Vector2();

  public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:FlxGraphicAsset)
  {
    super(x, y, simpleGraphic);
    if (simpleGraphic != null) setUp();
    this.active = true;
  }

  public function setUp():Void
  {
    var nextRow:Int = (subdivisions + 1 + 1);
    updateColorTransform();
    var noteIndices:Array<Int> = [];
    for (x in 0...subdivisions + 1)
    {
      for (y in 0...subdivisions + 1)
      {
        // indices are created from top to bottom, going along the x axis each cycle.
        var funny:Int = y + (x * nextRow);
        noteIndices.push(0 + funny);
        noteIndices.push(nextRow + funny);
        noteIndices.push(1 + funny);

        noteIndices.push(nextRow + funny);
        noteIndices.push(nextRow + 1 + funny);
        noteIndices.push(1 + funny);
      }
    }
    indices = new DrawData<Int>(noteIndices.length, true, noteIndices);

    for (x in 0...subdivisions + 2) // x
    {
      for (y in 0...subdivisions + 2) // y
      {
        vertOffsetX.push(0);
        vertOffsetY.push(0);
        vertOffsetZ.push(0);
      }
    }
    updateTris();
  }

  public var uvScale:Vector2 = new Vector2(1.0, 1.0);
  public var uvScaleOffset:Vector2 = new Vector2(0.5, 0.5); // scale from center
  public var uvOffset:Vector2 = new Vector2(0.0, 0.0);

  var destroying:Bool = false;

  var cullCounter:Int = 0;

  var curRotationAmount:Float = 0; // Keep track of our current rotation for scale and skew to work correctly.

  // Rotation angles repeat for every vertex in a mesh. Keep a small reusable
  // cache so each distinct angle needs sine/cosine only once per rebuild.
  var rotationTrigAngles:Array<Float> = [];
  var rotationTrigCosines:Array<Float> = [];
  var rotationTrigSines:Array<Float> = [];
  var rotationTrigCount:Int = 0;

  // Skew angles are constant throughout one mesh rebuild. Avoid recalculating
  // Math.tan for every vertex (up to 16+ times per projected sprite per frame).
  var cachedSkewXAngle:Float = Math.NaN;
  var cachedSkewYAngle:Float = Math.NaN;
  var cachedSkewZAngle:Float = Math.NaN;
  var cachedPlayfieldSkewXAngle:Float = Math.NaN;
  var cachedPlayfieldSkewYAngle:Float = Math.NaN;
  var cachedPlayfieldSkewZAngle:Float = Math.NaN;
  var cachedSkewXTan:Float = 0;
  var cachedSkewYTan:Float = 0;
  var cachedSkewZTan:Float = 0;
  var cachedPlayfieldSkewXTan:Float = 0;
  var cachedPlayfieldSkewYTan:Float = 0;
  var cachedPlayfieldSkewZTan:Float = 0;

  function refreshSkewTrigCache():Void
  {
    if (cachedSkewXAngle != skewX)
    {
      cachedSkewXAngle = skewX;
      cachedSkewXTan = skewX != 0 ? Math.tan(skewX * FlxAngle.TO_RAD) : 0;
    }
    if (cachedSkewYAngle != skewY)
    {
      cachedSkewYAngle = skewY;
      cachedSkewYTan = skewY != 0 ? Math.tan(skewY * FlxAngle.TO_RAD) : 0;
    }
    if (cachedSkewZAngle != skewZ)
    {
      cachedSkewZAngle = skewZ;
      cachedSkewZTan = skewZ != 0 ? Math.tan(skewZ * FlxAngle.TO_RAD) : 0;
    }
    if (cachedPlayfieldSkewXAngle != skewX_playfield)
    {
      cachedPlayfieldSkewXAngle = skewX_playfield;
      cachedPlayfieldSkewXTan = skewX_playfield != 0 ? Math.tan(skewX_playfield * FlxAngle.TO_RAD) : 0;
    }
    if (cachedPlayfieldSkewYAngle != skewY_playfield)
    {
      cachedPlayfieldSkewYAngle = skewY_playfield;
      cachedPlayfieldSkewYTan = skewY_playfield != 0 ? Math.tan(skewY_playfield * FlxAngle.TO_RAD) : 0;
    }
    if (cachedPlayfieldSkewZAngle != skewZ_playfield)
    {
      cachedPlayfieldSkewZAngle = skewZ_playfield;
      cachedPlayfieldSkewZTan = skewZ_playfield != 0 ? Math.tan(skewZ_playfield * FlxAngle.TO_RAD) : 0;
    }
  }

  /**
   * The function which will update all the vertex and UV data.
   */
  public function updateTris():Void
  {
    if (destroying) return;
    rotationTrigCount = 0;
    refreshSkewTrigCache();

    // TODO: Improve how this gets applied!
    var wasAlreadyFlipped_X:Bool = flipX;
    var wasAlreadyFlipped_Y:Bool = flipY;

    var needsFlipX:Bool = false;
    var needsFlipY:Bool = false;
    switch (cullMode)
    {
      case "always_positive" | "always_negative":
        needsFlipX = cullMode == "always_positive" ? true : false;
        needsFlipY = cullMode == "always_positive" ? true : false;

        var xFlipCheck_vertTopLeftX = vertices[0];
        var xFlipCheck_vertBottomRightX = vertices[vertices.length - 1 - 1];
        if (!wasAlreadyFlipped_X)
        {
          if (xFlipCheck_vertTopLeftX >= xFlipCheck_vertBottomRightX)
          {
            needsFlipX = !needsFlipX;
          }
        }
        else
        {
          if (xFlipCheck_vertTopLeftX < xFlipCheck_vertBottomRightX)
          {
            needsFlipX = !needsFlipX;
          }
        }
        // y check
        if (!wasAlreadyFlipped_Y)
        {
          xFlipCheck_vertTopLeftX = vertices[1];
          xFlipCheck_vertBottomRightX = vertices[vertices.length - 1];
          if (xFlipCheck_vertTopLeftX >= xFlipCheck_vertBottomRightX)
          {
            needsFlipY = !needsFlipY;
          }
        }
        else
        {
          xFlipCheck_vertTopLeftX = vertices[1];
          xFlipCheck_vertBottomRightX = vertices[vertices.length - 1];
          if (xFlipCheck_vertTopLeftX < xFlipCheck_vertBottomRightX)
          {
            needsFlipY = !needsFlipY;
          }
        }
    }

    if (this.frame?.frame != null) {
      var w:Float = this.frame.frame.width;
      var h:Float = this.frame.frame.height;

      var offsetX:Float = this.frame.offset.x * scaleX;
      var offsetScaledX:Float = (frameWidth - w) * (scaleX - 1) / 2;

      var offsetY:Float = this.frame.offset.y * scaleY;
      var offsetScaledY:Float = (frameHeight - h) * (scaleY - 1) / 2;

      culled = false;
      cullCounter = 0; // If every point triggers the "too close to camera" check, then we cull this sprite.
      var cullCounterCap:Int = (subdivisions + 2) * (subdivisions + 2);

      var i:Int = 0;
      for (x in 0...subdivisions + 2) // x
      {
        for (y in 0...subdivisions + 2) // y
        {
          curRotationAmount = 0;

          // Setup point
          var point3D:Vector3D = projectionPoint;
          point3D.setTo((w / (subdivisions + 1)) * x, (h / (subdivisions + 1)) * y, 0);

          // Animation frame offset stuff
          point3D.x += offsetX - offsetScaledX;
          point3D.y += offsetY - offsetScaledY;

          var xPercent:Float = x / (subdivisions + 1);
          var yPercent:Float = y / (subdivisions + 1);

          // Apply vibrate effect
          if (vibrateEffect != 0)
          {
            point3D.x += FlxG.random.float(-1, 1) * vibrateEffect;
            point3D.y += FlxG.random.float(-1, 1) * vibrateEffect;
            point3D.z += FlxG.random.float(-1, 1) * vibrateEffect;
          }

          // Apply curVertOffsets
          var curVertOffsetX:Float = 0;
          var curVertOffsetY:Float = 0;
          var curVertOffsetZ:Float = 0;

          if (i < vertOffsetX.length)
          {
            curVertOffsetX = vertOffsetX[i];
          }
          if (i < vertOffsetY.length)
          {
            curVertOffsetY = vertOffsetY[i];
          }
          if (i < vertOffsetZ.length)
          {
            curVertOffsetZ = vertOffsetZ[i];
          }

          point3D.x += curVertOffsetX;
          point3D.y += curVertOffsetY;
          point3D.z += curVertOffsetZ;

          if (spinAngle != 0)
          {
            point3D = applyRotZ(point3D, xPercent, yPercent, frameWidth, frameHeight, spinAngle);
          }

          point3D = applyCrop(point3D, w, h);

          point3D = applyScale(point3D, xPercent, yPercent, w, h, false);

          point3D = applyFlip(point3D, xPercent, yPercent);
          point3D = applyRotation(point3D, xPercent, yPercent);

          point3D = applySkew(point3D, xPercent, yPercent, w, h);

          // scale2
          point3D = applyScale(point3D, xPercent, yPercent, w, h, true);

          // Apply offset here before it gets affected by z projection!
          point3D.x -= offset.x;
          point3D.y -= offset.y;
          point3D = applyPerspective(point3D, xPercent, yPercent);
          if (cullCounter >= cullCounterCap) culled = true;

          vertices[i * 2] = point3D.x;
          vertices[i * 2 + 1] = point3D.y;

          if (culled)
          {
            return; // Just stop if we are culled.
          }

          if (needsFlipX)
          {
            xPercent = 1 - xPercent;
          }
          if (needsFlipY)
          {
            yPercent = 1 - yPercent;
          }

          /* Updating the UV mapping! */
          var uvX:Float = xPercent;
          var uvY:Float = yPercent;

          var curFrame = this.frame;
          uvX = FlxMath.remapToRange(xPercent, 0, 1, curFrame.uv.left, curFrame.uv.right);
          uvY = FlxMath.remapToRange(yPercent, 0, 1, curFrame.uv.top, curFrame.uv.bottom);

          // todo: add repeat texture to here (using %) instead so that we can use frameBorderCut to determine if we repeat the entire atlas, or just the current frame
          // 2026 me here, idk if this is possible cuz will need a vert for every time the texture repeats. Would have to be handled via shader instead :(

          // crop
          uvX *= (1 - cropLeft);

          uvX -= 1 * (1 - cropLeft);
          uvX *= (1.0 - cropRight / (1.0 - cropLeft));
          uvX += 1 * (1 - cropLeft);

          uvY *= (1 - cropTop);

          uvY -= 1 * (1 - cropTop);
          uvY *= (1.0 - cropBottom / (1.0 - cropTop));
          uvY += 1 * (1 - cropTop);

          // uv scale
          uvX -= uvScaleOffset.x;
          uvY -= uvScaleOffset.y;

          uvX *= uvScale.x;
          uvY *= uvScale.y;

          uvX += uvScaleOffset.x;
          uvY += uvScaleOffset.y;

          // uv offset
          uvX += uvOffset.x;
          uvY += uvOffset.y;

          // map it
          uvtData[i * 3] = uvX; // u
          uvtData[i * 3 + 1] = uvY; // v
          uvtData[i * 3 + 2] = (doPerspectiveCorrection ? 1 / Math.max(0.0001, -point3D.z) : 1.0); // t

          i++;
        }
      }
    }
  }

  override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite
  {
    super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
    setUp();
    return this;
  }

  override function set_frames(Frames:FlxFramesCollection):FlxFramesCollection
  {
    super.set_frames(Frames);
    setUp();
    return Frames;
  }

  /**
   * A `Vector` representing each vertex colour. Doesn't do anything though but is needed to avoid a crash when changing colors
   */
  public var colors:DrawData<Int> = new DrawData<Int>();

  var culled:Bool = false;

  // Projection uses pre-transformed mesh vertices, so a regular FlxSprite dirty
  // check alone is not enough: animated frames and playfield-center changes also
  // affect those vertices even when the note's x/y/scale did not change.
  var lastProjectedFrame:Dynamic = null;
  var lastProjectionCenterX:Float = Math.NaN;
  var lastProjectionCenterY:Float = Math.NaN;
  var lastProjectionCenterZ:Float = Math.NaN;

  #if debug
  static var projectionPerfLastReport:Float = 0;
  static var projectionPerfDraws:Int = 0;
  static var projectionPerfRebuilds:Int = 0;
  static var projectionPerfRebuildMs:Float = 0;
  static var projectionPerfMaxRebuildMs:Float = 0;
  static var projectionPerfTotalVertices:Float = 0;
  static var projectionPerfMaxSubdivisions:Int = 0;
  static var projectionPerfNoteDraws:Int = 0;
  static var projectionPerfNoteRebuilds:Int = 0;
  static var projectionPerfStrumDraws:Int = 0;
  static var projectionPerfStrumRebuilds:Int = 0;
  static var projectionPerfCullNote:Int = 0;
  static var projectionPerfCullStrum:Int = 0;
  static var projectionPerfInvalidNote:Int = 0;
  static var projectionPerfInvalidStrum:Int = 0;
  static var projectionPerfNoteExample:String = "";
  #end

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (destroying) return;
    if (!projectionEnabled)
    {
      super.draw();
    }
    else
    {
      var culling = TriangleCulling.NONE;
      switch (cullMode)
      {
        case "positive" | "front":
          culling = TriangleCulling.POSITIVE;
        case "negative" | "back":
          culling = TriangleCulling.NEGATIVE;
        case "always":
          culled = true;
      }

      final frameChanged:Bool = frame != lastProjectedFrame;
      final centerChanged:Bool = playfieldSkewCenterX != lastProjectionCenterX
        || playfieldSkewCenterY != lastProjectionCenterY
        || playfieldSkewCenterZ != lastProjectionCenterZ;
      #if debug
      final projectionPerfNow:Float = haxe.Timer.stamp();
      if (projectionPerfLastReport == 0) projectionPerfLastReport = projectionPerfNow;
      projectionPerfDraws++;
      final projectionClassName:Null<String> = Type.getClassName(Type.getClass(this));
      final isPerfNote:Bool = projectionClassName == "objects.notes.Note"
        || (projectionClassName != null && projectionClassName.indexOf(".APNote") >= 0);
      final isPerfStrum:Bool = projectionClassName == "objects.notes.StrumNote";
      if (isPerfNote) projectionPerfNoteDraws++;
      if (isPerfStrum) projectionPerfStrumDraws++;
      #end

      if (frame != lastProjectedFrame)
      {
        lastProjectedFrame = frame;
        dirty = true;
      }

      if (playfieldSkewCenterX != lastProjectionCenterX
        || playfieldSkewCenterY != lastProjectionCenterY
        || playfieldSkewCenterZ != lastProjectionCenterZ)
      {
        lastProjectionCenterX = playfieldSkewCenterX;
        lastProjectionCenterY = playfieldSkewCenterY;
        lastProjectionCenterZ = playfieldSkewCenterZ;
        dirty = true;
      }

      if (dirty)
      {
        #if debug
        final projectionUpdateStart:Float = haxe.Timer.stamp();
        #end
        this.updateTris();
        #if debug
        final projectionRebuildMs:Float = (haxe.Timer.stamp() - projectionUpdateStart) * 1000;
        projectionPerfRebuilds++;
        projectionPerfRebuildMs += projectionRebuildMs;
        if (projectionRebuildMs > projectionPerfMaxRebuildMs) projectionPerfMaxRebuildMs = projectionRebuildMs;
        if (subdivisions > projectionPerfMaxSubdivisions) projectionPerfMaxSubdivisions = subdivisions;
        projectionPerfTotalVertices += (subdivisions + 2) * (subdivisions + 2);
        if (isPerfNote) projectionPerfNoteRebuilds++;
        if (isPerfStrum) projectionPerfStrumRebuilds++;
        #end
        dirty = false;
      }

      #if debug
      if (projectionPerfNow - projectionPerfLastReport >= 2.0)
      {
        final avgRebuildMs:Float = projectionPerfRebuilds > 0 ? projectionPerfRebuildMs / projectionPerfRebuilds : 0;
        final avgVertices:Float = projectionPerfRebuilds > 0 ? projectionPerfTotalVertices / projectionPerfRebuilds : 0;
        trace('[MODCHART-PERF] 3D projection: projected draws=' + projectionPerfDraws
          + ', mesh rebuilds=' + projectionPerfRebuilds
          + ', rebuild ms total=' + Math.round(projectionPerfRebuildMs * 100) / 100
          + ', rebuild ms avg=' + Math.round(avgRebuildMs * 100) / 100
          + ', rebuild ms max=' + Math.round(projectionPerfMaxRebuildMs * 100) / 100
          + ', avg vertices=' + Math.round(avgVertices * 10) / 10
          + ', max subdivisions=' + projectionPerfMaxSubdivisions);
        trace('[MODCHART-PERF] 3D render health: notes draws/rebuilds=' + projectionPerfNoteDraws + '/' + projectionPerfNoteRebuilds
          + ', strums draws/rebuilds=' + projectionPerfStrumDraws + '/' + projectionPerfStrumRebuilds
          + ', culled notes/strums=' + projectionPerfCullNote + '/' + projectionPerfCullStrum
          + ', invalid mesh notes/strums=' + projectionPerfInvalidNote + '/' + projectionPerfInvalidStrum
          + (projectionPerfNoteExample.length > 0 ? ', note mesh sample={' + projectionPerfNoteExample + '}' : ''));
        projectionPerfDraws = 0;
        projectionPerfRebuilds = 0;
        projectionPerfRebuildMs = 0;
        projectionPerfMaxRebuildMs = 0;
        projectionPerfTotalVertices = 0;
        projectionPerfMaxSubdivisions = 0;
        projectionPerfNoteDraws = 0;
        projectionPerfNoteRebuilds = 0;
        projectionPerfStrumDraws = 0;
        projectionPerfStrumRebuilds = 0;
        projectionPerfCullNote = 0;
        projectionPerfCullStrum = 0;
        projectionPerfInvalidNote = 0;
        projectionPerfInvalidStrum = 0;
        projectionPerfNoteExample = "";
        projectionPerfLastReport = projectionPerfNow;
      }
      #end

      #if debug
      if (culled)
      {
        if (isPerfNote) projectionPerfCullNote++;
        if (isPerfStrum) projectionPerfCullStrum++;
      }
      if (vertices == null || indices == null || graphic == null || uvtData == null || _point == null || offset == null)
      {
        if (isPerfNote) projectionPerfInvalidNote++;
        if (isPerfStrum) projectionPerfInvalidStrum++;
      }
      if (isPerfNote && projectionPerfNoteExample.length == 0 && vertices != null && vertices.length >= 8)
      {
        var minVertexX:Float = vertices[0];
        var maxVertexX:Float = vertices[0];
        var minVertexY:Float = vertices[1];
        var maxVertexY:Float = vertices[1];
        for (i in 0...vertices.length)
        {
          if ((i & 1) == 0)
          {
            if (vertices[i] < minVertexX) minVertexX = vertices[i];
            if (vertices[i] > maxVertexX) maxVertexX = vertices[i];
          }
          else
          {
            if (vertices[i] < minVertexY) minVertexY = vertices[i];
            if (vertices[i] > maxVertexY) maxVertexY = vertices[i];
          }
        }
        projectionPerfNoteExample = 'xy=' + Math.round(x * 10) / 10 + ',' + Math.round(y * 10) / 10
          + ' z=' + Math.round(z * 10) / 10 + ' alpha=' + Math.round(alpha * 100) / 100
          + ' cullMode=' + cullMode + ' frame=' + frameWidth + 'x' + frameHeight
          + ' verts=' + vertices.length / 2
          + ' localBounds=' + Math.round(minVertexX * 10) / 10 + ':' + Math.round(maxVertexX * 10) / 10
          + ',' + Math.round(minVertexY * 10) / 10 + ':' + Math.round(maxVertexY * 10) / 10;
      }
      #end
      if (culled || alpha < 0 || vertices == null || indices == null || graphic == null || uvtData == null || _point == null || offset == null)
      {
        return;
      }
      var alphaMemory:Float = this.alpha;
      for (camera in cameras)
      {
        if (!camera.visible || !camera.exists) continue;
        // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.
        alpha = alphaMemory * camera.alpha; // Fix for drawTriangles not fading with camera
        // getScreenPosition(_point, camera).subtractPoint(offset);
        getScreenPosition(_point, camera);
        camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, textureRepeat, antialiasing, colorTransform, shader, culling);
      }
      this.alpha = alphaMemory;

      #if FLX_DEBUG
      if (FlxG.debugger.drawDebug) drawDebug();
      #end
    }
  }

  override public function destroy():Void
  {
    destroying = true;
    vertices = null;
    indices = null;
    uvtData = null;
    super.destroy();
  }

  // Feed a noteData into this function to apply all of it's parameters to this sprite!
  override public function applyNoteData(data:NoteData, applyFake3D:Bool = false):Void
  {
    final geometryChanged:Bool =
      x != data.x
      || y != data.y
      || z != data.z
      || angle != data.angleZ
      || scale.x != data.scaleX
      || scale.y != data.scaleY
      || scaleX2 != data.scaleX2
      || scaleY2 != data.scaleY2
      || skew.x != data.skewX
      || skew.y != data.skewY
      || angleX != data.angleX
      || angleY != data.angleY
      || skewZ != data.skewZ
      || skewX_playfield != data.skewX_playfield
      || skewY_playfield != data.skewY_playfield
      || skewZ_playfield != data.skewZ_playfield
      || scaleZ != data.scaleZ
      || pivotOffsetX != data.meshOffsets_PivotX
      || pivotOffsetY != data.meshOffsets_PivotY
      || pivotOffsetZ != data.meshOffsets_PivotZ
      || skewX_offset != data.meshOffsets_SkewX
      || skewY_offset != data.meshOffsets_SkewY
      || skewZ_offset != data.meshOffsets_SkewZ
      || perspectiveCenterOffset.x != data.perspectiveOffset.x
      || perspectiveCenterOffset.y != data.perspectiveOffset.y;

    super.applyNoteData(data, applyFake3D);
    this.skewZ = data.skewZ;
    this.skewX_playfield = data.skewX_playfield;
    this.skewY_playfield = data.skewY_playfield;
    this.skewZ_playfield = data.skewZ_playfield;

    this.angleX = data.angleX;
    this.angleY = data.angleY;

    this.scaleZ = data.scaleZ;
    if (geometryChanged) dirty = true;
  }

  public function applyCrop(pos:Vector3D, w:Float, h:Float):Vector3D
  {
    // right
    pos.x *= (1.0 - cropRight / (1.0 - cropLeft));

    // left
    pos.x -= w;
    pos.x *= (1.0 - cropLeft);
    pos.x += w;

    // bottom
    pos.y *= (1.0 - cropBottom / (1.0 - cropTop));

    // top
    pos.y -= h;
    pos.y *= (1.0 - cropTop);
    pos.y += h;

    return pos;
  }

  public function applyScale(pos:Vector3D, xPercent:Float, yPercent:Float, w:Float, h:Float, isScale2:Bool = false):Vector3D
  {
    if (curRotationAmount != 0)
    {
      rotationPoint.setTo(xPercent, yPercent);
      rotatePointAround(rotationPoint, 0.5, 0.5, curRotationAmount);
      xPercent = rotationPoint.x;
      yPercent = rotationPoint.y;
    }

    xPercent = FlxMath.remapToRange(xPercent, 0, 1, cropLeft, 1 - cropRight);
    yPercent = FlxMath.remapToRange(yPercent, 0, 1, cropTop, 1 - cropBottom);

    var newWidth:Float = ((isScale2 ? scaleX2 : scaleX) - 1) * (xPercent - 0.5);
    var newHeight:Float = ((isScale2 ? scaleY2 : scaleY) - 1) * (yPercent - 0.5);
    if (isScale2)
    {
      newWidth *= scaleX;
      newHeight *= scaleY;
    }

    if (newWidth == 0 && newHeight == 0) return pos;
    else
    {
      pos.x += (newWidth) * w;
      pos.y += (newHeight) * h;
      return pos;
    }
  }

  public var offsetBeforeRotation:FlxPoint = new FlxPoint(0, 0);

  public var preRotationMoveX:Float = 0;
  public var preRotationMoveY:Float = 0;
  public var preRotationMoveZ:Float = 0;

  var skewOffsetFix:Float = 0.5;

  public function applySkew(pos:Vector3D, xPercent:Float, yPercent:Float, w:Float, h:Float):Vector3D
  {
    var skewPosX:Float = this.x + this.x2 - offset.x;
    var skewPosY:Float = this.y + this.y2 - offset.y;

    skewPosX += (w) / 2;
    skewPosY += (h) / 2;

    rotationPoint.setTo(xPercent, yPercent);
    rotatePointAround(rotationPoint, 0.5, 0.5, curRotationAmount);

    // For some reason, we need a 0.5 offset for this for it to be centered???????????????????
    var xPercent_SkewOffset:Float = rotationPoint.x - skewY_offset - skewOffsetFix;
    var yPercent_SkewOffset:Float = rotationPoint.y - skewX_offset - skewOffsetFix;
    // Keep math the same as skewedsprite for parity reasons.
    if (skewX != 0) // Small performance boost from this if check to avoid the tan math lol?
      pos.x += yPercent_SkewOffset * cachedSkewXTan * h * scaleY;
    if (skewY != 0) //
      pos.y += xPercent_SkewOffset * cachedSkewYTan * w * scaleX;

    // the %, followed by the position moved to the center of the sprite, then moved based off screen center (playfield center in future)
    var playfieldSkewOffset_Y:Float = ((rotationPoint.x - 0.5) * (h * scaleY)) + skewPosX - (playfieldSkewCenterX);
    var playfieldSkewOffset_X:Float = ((rotationPoint.y - 0.5) * (w * scaleX)) + skewPosY - (playfieldSkewCenterY);

    if (skewX_playfield != 0) pos.x += playfieldSkewOffset_X * cachedPlayfieldSkewXTan;
    if (skewY_playfield != 0) pos.y += playfieldSkewOffset_Y * cachedPlayfieldSkewYTan;

    // z SKEW ?

    if (skewZ != 0) pos.z += yPercent_SkewOffset * cachedSkewZTan * h * scaleY;
    var playfieldSkewOffset_Z:Float = ((rotationPoint.y - 0.5) * (w * scaleX)) + skewPosY - (playfieldSkewCenterY);
    if (skewZ_playfield != 0) pos.z += playfieldSkewOffset_Z * cachedPlayfieldSkewZTan;

    return pos;
  }

  function applyRotX(pos:Vector3D, xPercent, yPercent, w:Float, h:Float, degrees:Float):Vector3D
  {
    if (degrees == 0) return pos;
    rotationPoint.setTo(pos.z, pos.y);
    rotatePointAround(rotationPoint, pivotOffsetZ, (h / 2) + pivotOffsetY, degrees);
    pos.z = rotationPoint.x;
    pos.y = rotationPoint.y;
    return pos;
  }

  function applyRotY(pos:Vector3D, xPercent, yPercent, w:Float, h:Float, degrees:Float):Vector3D
  {
    if (degrees == 0) return pos;
    rotationPoint.setTo(pos.x, pos.z);
    rotatePointAround(rotationPoint, (w / 2) + pivotOffsetX, pivotOffsetZ, degrees);
    pos.x = rotationPoint.x;
    pos.z = rotationPoint.y;
    return pos;
  }

  function applyRotZ(pos:Vector3D, xPercent, yPercent, w:Float, h:Float, degrees:Float):Vector3D
  {
    if (degrees == 0) return pos;
    curRotationAmount += degrees;
    rotationPoint.setTo(pos.x, pos.y);
    rotatePointAround(rotationPoint, (w / 2) + pivotOffsetX, (h / 2) + pivotOffsetY, degrees);
    pos.x = rotationPoint.x;
    pos.y = rotationPoint.y;
    return pos;
  }

  function rotatePointAround(point:Vector2, originX:Float, originY:Float, degrees:Float):Void
  {
    if (degrees == 0) return;

    var cachedIndex:Int = -1;
    for (i in 0...rotationTrigCount)
    {
      if (rotationTrigAngles[i] == degrees)
      {
        cachedIndex = i;
        break;
      }
    }

    var cos:Float;
    var sin:Float;
    if (cachedIndex >= 0)
    {
      cos = rotationTrigCosines[cachedIndex];
      sin = rotationTrigSines[cachedIndex];
    }
    else
    {
      final angle:Float = degrees * FlxAngle.TO_RAD;
      cos = FlxMath.fastCos(angle);
      sin = FlxMath.fastSin(angle);

      if (rotationTrigCount < 16)
      {
        if (rotationTrigCount < rotationTrigAngles.length)
        {
          rotationTrigAngles[rotationTrigCount] = degrees;
          rotationTrigCosines[rotationTrigCount] = cos;
          rotationTrigSines[rotationTrigCount] = sin;
        }
        else
        {
          rotationTrigAngles.push(degrees);
          rotationTrigCosines.push(cos);
          rotationTrigSines.push(sin);
        }
        rotationTrigCount++;
      }
    }

    final x:Float = point.x - originX;
    final y:Float = point.y - originY;
    point.setTo(
      originX + cos * x - sin * y,
      originY + sin * x + cos * y
    );
  }

  public function applyFlip(pos:Vector3D, xPercent:Float = 0, yPercent:Float = 0):Vector3D
  {
    var w:Float = frameWidth;
    var h:Float = frameHeight;

    if (flipX)
    {
      pos = applyRotY(pos, xPercent, yPercent, w, h, 180);
    }
    if (flipY)
    {
      pos = applyRotX(pos, xPercent, yPercent, w, h, 180);
    }

    return pos;
  }

  // EDIT THIS ARRAY TO CHANGE HOW ROTATION IS APPLIED!
  public var rotationOrder:Array<String> = ["z", "y", "x"];

  public function applyRotation(pos:Vector3D, xPercent:Float = 0, yPercent:Float = 0, ?rotationOrderOverride:Array<String>):Vector3D
  {
    if (rotationOrderOverride == null) rotationOrderOverride = rotationOrder;
    var w:Float = frameWidth;
    var h:Float = frameHeight;

    pos.x -= offsetBeforeRotation.x;
    pos.y -= offsetBeforeRotation.y;
    pos.x += preRotationMoveX;
    pos.y += preRotationMoveY;
    pos.z += preRotationMoveZ;

    for (i in 0...rotationOrderOverride.length)
    {
      switch (rotationOrderOverride[i])
      {
        case "specialz":
          applyRotZ(pos, xPercent, yPercent, w, h, spinAngle);

        case "x":
          applyRotX(pos, xPercent, yPercent, w, h, angleX);
        case "y":
          applyRotY(pos, xPercent, yPercent, w, h, angleY);
        case "z":
          applyRotZ(pos, xPercent, yPercent, w, h, angleZWithOffset);

        case "x2":
          applyRotX(pos, xPercent, yPercent, w, h, angleX2);
        case "y2":
          applyRotY(pos, xPercent, yPercent, w, h, angleY2);
        case "z2":
          applyRotZ(pos, xPercent, yPercent, w, h, angleZ2);
      }
    }

    return pos;
  }

  public function applyPerspective(pos:Vector3D, xPercent:Float = 0, yPercent:Float = 0):Vector3D
  {
    if (projectionEnabled)
    {
      pos.x += this.x + this.x2;
      pos.y += this.y + this.y2;
      pos.z += this.z + this.z2;
      pos.x += fovOffsetX;
      pos.y += fovOffsetY;
      pos.z *= 0.001;

      if (cullIfTooClose)
      {
        var newz:Float = pos.z;
        newz *= FlxMath.lerp(0, 1, ModConstants.FOV / 90);
        // Too close to camera!
        if (newz > ModConstants.zNear + ModConstants.tooCloseToCameraFix)
        {
          cullCounter += 1;
        }
      }

      ModConstants.perspectiveMath(pos, 0, 0, perspectiveCenterOffset);

      pos.x -= this.x + this.x2;
      pos.y -= this.y + this.y2;
      pos.z -= (this.z + this.z2) * 0.001;

      pos.x -= fovOffsetX;
      pos.y -= fovOffsetY;
    }
    return pos;
  }
}
