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
    if (projectionEnabled != value) invalidateMesh();
    projectionEnabled = value;
    return value;
  }

  /** Marks projected geometry as stale after a modchart changes mesh inputs. */
  public inline function invalidateMesh():Void
  {
    if (!destroying) dirty = true;
  }

  // If true, will correct the texture distortion created when transforming in 3D
  public var doPerspectiveCorrection:Bool = true;

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
    n = FlxMath.bound(n, 0.0, 1.0);
    if (cropLeft != n) invalidateMesh();
    this.cropLeft = n;
    return this.cropLeft;
  }

  // Crop the sprite starting from the right.
  public var cropRight(default, set):Float = 0;

  function set_cropRight(n:Float):Float
  {
    n = FlxMath.bound(n, 0.0, 1.0);
    if (cropRight != n) invalidateMesh();
    this.cropRight = n;
    return this.cropRight;
  }

  // Crop the sprite starting from the top.
  public var cropTop(default, set):Float = 0;

  function set_cropTop(n:Float):Float
  {
    n = FlxMath.bound(n, 0.0, 1.0);
    if (cropTop != n) invalidateMesh();
    this.cropTop = n;
    return this.cropTop;
  }

  // Crop the sprite starting from the bottom.
  public var cropBottom(default, set):Float = 0;

  function set_cropBottom(n:Float):Float
  {
    n = FlxMath.bound(n, 0.0, 1.0);
    if (cropBottom != n) invalidateMesh();
    this.cropBottom = n;
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
  public var subdivisions(default, set):Int = 2;

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
    if (destroying || vertices == null || indices == null || uvtData == null) return;

    final sideLength:Int = subdivisions + 2;
    final pointCount:Int = sideLength * sideLength;
    final nextRow:Int = sideLength;

    // Keep the 3-component UVT layout (u, v, perspective t) used by FlxCamera.
    if (vertices.length != pointCount * 2) vertices.length = pointCount * 2;
    if (uvtData.length != pointCount * 3) uvtData.length = pointCount * 3;
    resizeVertexOffsets(vertOffsetX, pointCount);
    resizeVertexOffsets(vertOffsetY, pointCount);
    resizeVertexOffsets(vertOffsetZ, pointCount);

    if (_builtSubdivisions != subdivisions)
    {
      var noteIndices:Array<Int> = [];
      for (x in 0...subdivisions + 1)
      {
        for (y in 0...subdivisions + 1)
        {
          // Indices are created from top to bottom, going along the x axis each cycle.
          var funny:Int = y + (x * nextRow);
          noteIndices.push(funny);
          noteIndices.push(nextRow + funny);
          noteIndices.push(1 + funny);

          noteIndices.push(nextRow + funny);
          noteIndices.push(nextRow + 1 + funny);
          noteIndices.push(1 + funny);
        }
      }
      indices = new DrawData<Int>(noteIndices.length, true, noteIndices);
      _builtSubdivisions = subdivisions;
    }

    if (frame != null && frame.frame != null)
    {
      updateColorTransform();
      updateTris();
      dirty = false;
    }
    else
    {
      invalidateMesh();
    }
  }

  inline function resizeVertexOffsets(values:Array<Float>, length:Int):Void
  {
    while (values.length > length) values.pop();
    while (values.length < length) values.push(0);
  }

  public var uvScale:Vector2 = new Vector2(1.0, 1.0);
  public var uvScaleOffset:Vector2 = new Vector2(0.5, 0.5); // scale from center
  public var uvOffset:Vector2 = new Vector2(0.0, 0.0);

  var destroying:Bool = false;

  var _builtSubdivisions:Int = -1;
  var texturedPlane:TexturedPlane3D = new TexturedPlane3D();
  public var sharedProjectionPlanes:Array<TexturedPlane3D>;
  public var fieldProjection3D:FieldProjection3D;
  var lastFieldProjection:FieldProjection3D;
  var lastFieldRevision:Int = -1;
  var perspectiveWeight:Float = 1;

  // A mesh uses the same six skew angles for every vertex; cache their tangents per rebuild.
  var meshTangentCacheActive:Bool = false;
  var meshTanSkewX:Float = 0;
  var meshTanSkewY:Float = 0;
  var meshTanSkewXPlayfield:Float = 0;
  var meshTanSkewYPlayfield:Float = 0;
  var meshTanSkewZ:Float = 0;
  var meshTanSkewZPlayfield:Float = 0;

  var cullCounter:Int = 0;

  var curRotationAmount:Float = 0; // Keep track of our current rotation for scale and skew to work correctly.

  /**
   * The function which will update all the vertex and UV data.
   */
  public function updateTris():Void
  {
    if (destroying || vertices == null || indices == null || uvtData == null) return;
    if (frame == null || frame.frame == null)
    {
      culled = true;
      return;
    }

    final frameData = frame;
    final w:Float = frameData.frame.width;
    final h:Float = frameData.frame.height;

    // Cache invariant trig work once per mesh, instead of once for every vertex.
    meshTanSkewX = skewX == 0 ? 0 : Math.tan(skewX * FlxAngle.TO_RAD);
    meshTanSkewY = skewY == 0 ? 0 : Math.tan(skewY * FlxAngle.TO_RAD);
    meshTanSkewXPlayfield = skewX_playfield == 0 ? 0 : Math.tan(skewX_playfield * FlxAngle.TO_RAD);
    meshTanSkewYPlayfield = skewY_playfield == 0 ? 0 : Math.tan(skewY_playfield * FlxAngle.TO_RAD);
    meshTanSkewZ = skewZ == 0 ? 0 : Math.tan(skewZ * FlxAngle.TO_RAD);
    meshTanSkewZPlayfield = skewZ_playfield == 0 ? 0 : Math.tan(skewZ_playfield * FlxAngle.TO_RAD);
    meshTangentCacheActive = true;

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

    {

      var offsetX:Float = this.frame.offset.x * scaleX;
      var offsetScaledX:Float = (frameWidth - w) * (scaleX - 1) / 2;

      var offsetY:Float = this.frame.offset.y * scaleY;
      var offsetScaledY:Float = (frameHeight - h) * (scaleY - 1) / 2;

      var displaced = vibrateEffect != 0;
      if (!displaced) for (value in vertOffsetX) if (value != 0) { displaced = true; break; }
      if (!displaced) for (value in vertOffsetY) if (value != 0) { displaced = true; break; }
      if (!displaced) for (value in vertOffsetZ) if (value != 0) { displaced = true; break; }
      // Prepare a textured plane from the current spatial transforms. No note
      // motion, animation frame, strum time or hit state is changed here.
      var plane = TexturedPlane3D.obtain(this, texturedPlane, w, h, offsetX - offsetScaledX, offsetY - offsetScaledY, displaced);

      culled = false;
      cullCounter = 0; // If every point triggers the "too close to camera" check, then we cull this sprite.
      var cullCounterCap:Int = (subdivisions + 2) * (subdivisions + 2);

      var i:Int = 0;
      for (x in 0...subdivisions + 2) // x
      {
        for (y in 0...subdivisions + 2) // y
        {
          var point3D:Vector3D = projectionPoint;

          var xPercent:Float = x / (subdivisions + 1);
          var yPercent:Float = y / (subdivisions + 1);

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

          if (vibrateEffect != 0)
          {
            curVertOffsetX += FlxG.random.float(-1, 1) * vibrateEffect;
            curVertOffsetY += FlxG.random.float(-1, 1) * vibrateEffect;
            curVertOffsetZ += FlxG.random.float(-1, 1) * vibrateEffect;
          }
          plane.transform(point3D, xPercent, yPercent, curVertOffsetX, curVertOffsetY, curVertOffsetZ, this);
          point3D = applyPerspective(point3D, xPercent, yPercent);
          if (cullCounter >= cullCounterCap) culled = true;

          vertices[i * 2] = point3D.x;
          vertices[i * 2 + 1] = point3D.y;

          if (culled)
          {
            meshTangentCacheActive = false;
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
          // Crop in frame-local coordinates before mapping into the atlas.
          var uvX:Float = cropLeft + xPercent * Math.max(0, 1 - cropLeft - cropRight);
          var uvY:Float = cropTop + yPercent * Math.max(0, 1 - cropTop - cropBottom);

          // FlxFrame.uv stores right/bottom in width/height, NOT a normal rect.
          // Using .right/.bottom adds the atlas origin a second time.
          uvX = FlxMath.remapToRange(uvX, 0, 1, frameData.uv.x, frameData.uv.width);
          uvY = FlxMath.remapToRange(uvY, 0, 1, frameData.uv.y, frameData.uv.height);

          // todo: add repeat texture to here (using %) instead so that we can use frameBorderCut to determine if we repeat the entire atlas, or just the current frame
          // 2026 me here, idk if this is possible cuz will need a vert for every time the texture repeats. Would have to be handled via shader instead :(

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
          uvtData[i * 3 + 2] = doPerspectiveCorrection ? perspectiveWeight : 1.0; // true camera-space reciprocal depth

          i++;
        }
      }
    }
    meshTangentCacheActive = false;
  }

  override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite
  {
    // FlxSprite.loadGraphic assigns `frames`, which reaches set_frames() above.
    // Let that setter build the mesh once instead of rebuilding it a second time here.
    super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
    return this;
  }

  override function set_frames(Frames:FlxFramesCollection):FlxFramesCollection
  {
    // FunkinSprite and FlxSprite both clear frames during destruction. Avoid
    // running the frame teardown twice when the second assignment is null.
    if (Frames == null && frames == null) return Frames;
    super.set_frames(Frames);
    // FlxSprite.destroy() clears frames through this virtual setter.
    if (!destroying && Frames != null) setUp();
    return Frames;
  }

  /**
   * A `Vector` representing each vertex colour. Doesn't do anything though but is needed to avoid a crash when changing colors
   */
  public var colors:DrawData<Int> = new DrawData<Int>();

  var culled:Bool = false;

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (destroying) return;
    if (fieldProjection3D != null) fieldProjection3D.prepare();
    var revision = fieldProjection3D == null ? -1 : fieldProjection3D.revision;
    if (fieldProjection3D != lastFieldProjection || revision != lastFieldRevision)
    {
      invalidateMesh();
      lastFieldProjection = fieldProjection3D;
      lastFieldRevision = revision;
    }
    if (!projectionEnabled)
    {
      super.draw();
    }
    else
    {
      if (!visible || !alive || alpha <= 0 || graphic == null || frame == null || frame.frame == null) return;

      var forceCull:Bool = cullMode == "always";
      var culling = TriangleCulling.NONE;
      switch (cullMode)
      {
        case "positive" | "front":
          culling = TriangleCulling.POSITIVE;
        case "negative" | "back":
          culling = TriangleCulling.NEGATIVE;
      }

      if (dirty)
      {
        this.updateTris();
        dirty = false;
      }

      if (forceCull || culled || vertices == null || indices == null || uvtData == null || _point == null || offset == null)
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
    if (destroying) return;
    destroying = true;
    meshTangentCacheActive = false;
    vertices = null;
    indices = null;
    uvtData = null;
    sharedProjectionPlanes = null;
    fieldProjection3D = lastFieldProjection = null;
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
    // Equivalent crop without division by zero at a fully cropped edge.
    pos.x = w * cropLeft + pos.x * Math.max(0, 1 - cropLeft - cropRight);
    pos.y = h * cropTop + pos.y * Math.max(0, 1 - cropTop - cropBottom);

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

  /** Spatial transform only, sampled when preparing the textured plane. */
  public function transformPlaneVertex(point:Vector3D, u:Float, v:Float, width:Float, height:Float):Void
  {
    curRotationAmount = 0;
    if (spinAngle != 0) applyRotZ(point, u, v, frameWidth, frameHeight, spinAngle);
    applyCrop(point, width, height);
    applyScale(point, u, v, width, height, false);
    applyFlip(point, u, v);
    applyRotation(point, u, v);
    applySkew(point, u, v, width, height);
    applyScale(point, u, v, width, height, true);
    point.x -= offset.x;
    point.y -= offset.y;
  }

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
      pos.x += yPercent_SkewOffset * (meshTangentCacheActive ? meshTanSkewX : Math.tan(skewX * FlxAngle.TO_RAD)) * h * scaleY;
    if (skewY != 0)
      pos.y += xPercent_SkewOffset * (meshTangentCacheActive ? meshTanSkewY : Math.tan(skewY * FlxAngle.TO_RAD)) * w * scaleX;

    // the %, followed by the position moved to the center of the sprite, then moved based off screen center (playfield center in future)
    var playfieldSkewOffset_Y:Float = ((rotationPoint.x - 0.5) * (h * scaleY)) + skewPosX - (playfieldSkewCenterX);
    var playfieldSkewOffset_X:Float = ((rotationPoint.y - 0.5) * (w * scaleX)) + skewPosY - (playfieldSkewCenterY);

    if (skewX_playfield != 0) pos.x += playfieldSkewOffset_X * (meshTangentCacheActive ? meshTanSkewXPlayfield : Math.tan(skewX_playfield * FlxAngle.TO_RAD));
    if (skewY_playfield != 0) pos.y += playfieldSkewOffset_Y * (meshTangentCacheActive ? meshTanSkewYPlayfield : Math.tan(skewY_playfield * FlxAngle.TO_RAD));

    // z SKEW ?

    if (skewZ != 0) pos.z += yPercent_SkewOffset * (meshTangentCacheActive ? meshTanSkewZ : Math.tan(skewZ * FlxAngle.TO_RAD)) * h * scaleY;
    var playfieldSkewOffset_Z:Float = ((rotationPoint.y - 0.5) * (w * scaleX)) + skewPosY - (playfieldSkewCenterY);
    if (skewZ_playfield != 0) pos.z += playfieldSkewOffset_Z * (meshTangentCacheActive ? meshTanSkewZPlayfield : Math.tan(skewZ_playfield * FlxAngle.TO_RAD));

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

    final angle:Float = degrees * FlxAngle.TO_RAD;
    final x:Float = point.x - originX;
    final y:Float = point.y - originY;
    point.setTo(
      originX + FlxMath.fastCos(angle) * x - FlxMath.fastSin(angle) * y,
      originY + FlxMath.fastSin(angle) * x + FlxMath.fastCos(angle) * y
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
    perspectiveWeight = 1;
    if (projectionEnabled)
    {
      pos.x += this.x + this.x2;
      pos.y += this.y + this.y2;
      pos.z += this.z + this.z2;
      if (fieldProjection3D != null) fieldProjection3D.transform(pos);
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
      // Capture the camera depth before converting the vertex back to local
      // coordinates. Object Z is not part of the texture interpolation weight.
      perspectiveWeight = -1 / pos.z;

      pos.x -= this.x + this.x2;
      pos.y -= this.y + this.y2;
      pos.z -= (this.z + this.z2) * 0.001;

      pos.x -= fovOffsetX;
      pos.y -= fovOffsetY;
    }
    return pos;
  }
}
