package objects.funkin.graphics;

import openfl.geom.Vector3D;

/**
 * A sprite's scale / rotation / skew is affine until the perspective divide.
 * Prepare that plane once, then place its vertices by multiply-adds. This keeps
 * all existing mesh parameters while avoiding the full transform chain at every
 * subdivision. Per-vertex displacements remain supported as separate basis axes.
 */
@:access(objects.funkin.graphics.ZSprite)
class TexturedPlane3D
{
  var origin:Vector3D = new Vector3D();
  var horizontal:Vector3D = new Vector3D();
  var vertical:Vector3D = new Vector3D();
  var displacementX:Vector3D = new Vector3D();
  var displacementY:Vector3D = new Vector3D();
  var displacementZ:Vector3D = new Vector3D();
  var displaced:Bool = false;
  var key:Array<Float>;
  var order:Array<String>;
  var referenceX:Float = 0;
  var referenceY:Float = 0;
  var skewFieldX:Float = 0;
  var skewFieldY:Float = 0;
  var skewFieldZ:Float = 0;
  #if projection_probe
  public static var preparations:Int = 0;
  public static var reuses:Int = 0;
  #end

  public function new() {}

  /** A bounded cache owned by one receptor/trail, shared by its note sprites. */
  public static function obtain(sprite:ZSpriteProjected, fallback:TexturedPlane3D, width:Float, height:Float,
    offsetX:Float, offsetY:Float, displaced:Bool):TexturedPlane3D
  {
    var cache = sprite.sharedProjectionPlanes;
    if (cache != null)
    {
      for (plane in cache) if (plane.matches(sprite, width, height, offsetX, offsetY, displaced))
      {
        #if projection_probe
        reuses++;
        #end
        return plane;
      }
      // Keep variants for different note/frame sizes without retaining an
      // unbounded history of moving mod values.
      var plane = cache.length < 16 ? new TexturedPlane3D() : cache.shift();
      plane.prepare(sprite, width, height, offsetX, offsetY, displaced);
      cache.push(plane);
      return plane;
    }
    fallback.prepare(sprite, width, height, offsetX, offsetY, displaced);
    return fallback;
  }

  function matches(sprite:ZSpriteProjected, width:Float, height:Float, offsetX:Float, offsetY:Float, displaced:Bool):Bool
  {
    if (this.displaced != displaced || key == null || order.length != sprite.rotationOrder.length) return false;
    for (i in 0...order.length) if (order[i] != sprite.rotationOrder[i]) return false;
    // Compare numeric inputs directly: no string keys or per-note key arrays.
    return key[0] == (width)
      && key[1] == (height)
      && key[2] == (offsetX)
      && key[3] == (offsetY)
      && key[4] == (sprite.frameWidth)
      && key[5] == (sprite.frameHeight)
      && key[6] == (sprite.spinAngle)
      && key[7] == (sprite.cropLeft)
      && key[8] == (sprite.cropRight)
      && key[9] == (sprite.cropTop)
      && key[10] == (sprite.cropBottom)
      && key[11] == (sprite.scale.x)
      && key[12] == (sprite.scale.y)
      && key[13] == (sprite.scaleX2)
      && key[14] == (sprite.scaleY2)
      && key[15] == (sprite.flipX ? 1 : 0)
      && key[16] == (sprite.flipY ? 1 : 0)
      && key[17] == (sprite.angle)
      && key[18] == (sprite.angleAngularVelocityOffset)
      && key[19] == (sprite.angleX)
      && key[20] == (sprite.angleY)
      && key[21] == (sprite.angleX2)
      && key[22] == (sprite.angleY2)
      && key[23] == (sprite.angleZ2)
      && key[24] == (sprite.pivotOffsetX)
      && key[25] == (sprite.pivotOffsetY)
      && key[26] == (sprite.pivotOffsetZ)
      && key[27] == (sprite.offsetBeforeRotation.x)
      && key[28] == (sprite.offsetBeforeRotation.y)
      && key[29] == (sprite.preRotationMoveX)
      && key[30] == (sprite.preRotationMoveY)
      && key[31] == (sprite.preRotationMoveZ)
      && key[32] == (sprite.skew.x)
      && key[33] == (sprite.skew.y)
      && key[34] == (sprite.skewZ)
      && key[35] == (sprite.skewX_playfield)
      && key[36] == (sprite.skewY_playfield)
      && key[37] == (sprite.skewZ_playfield)
      && key[38] == (sprite.skewX_offset)
      && key[39] == (sprite.skewY_offset)
      && key[40] == (sprite.skewZ_offset)
      && key[41] == (sprite.playfieldSkewCenterX)
      && key[42] == (sprite.playfieldSkewCenterY)
      && key[43] == (sprite.playfieldSkewCenterZ)
      && key[44] == (sprite.offset.x)
      && key[45] == (sprite.offset.y);
  }

  public function prepare(sprite:ZSpriteProjected, width:Float, height:Float, offsetX:Float, offsetY:Float, displaced:Bool):Void
  {
    this.displaced = displaced;
    #if projection_probe
    preparations++;
    #end
    key = [width, height, offsetX, offsetY, sprite.frameWidth, sprite.frameHeight, sprite.spinAngle, sprite.cropLeft, sprite.cropRight, sprite.cropTop, sprite.cropBottom, sprite.scale.x, sprite.scale.y, sprite.scaleX2, sprite.scaleY2, sprite.flipX ? 1 : 0, sprite.flipY ? 1 : 0, sprite.angle, sprite.angleAngularVelocityOffset, sprite.angleX, sprite.angleY, sprite.angleX2, sprite.angleY2, sprite.angleZ2, sprite.pivotOffsetX, sprite.pivotOffsetY, sprite.pivotOffsetZ, sprite.offsetBeforeRotation.x, sprite.offsetBeforeRotation.y, sprite.preRotationMoveX, sprite.preRotationMoveY, sprite.preRotationMoveZ, sprite.skew.x, sprite.skew.y, sprite.skewZ, sprite.skewX_playfield, sprite.skewY_playfield, sprite.skewZ_playfield, sprite.skewX_offset, sprite.skewY_offset, sprite.skewZ_offset, sprite.playfieldSkewCenterX, sprite.playfieldSkewCenterY, sprite.playfieldSkewCenterZ, sprite.offset.x, sprite.offset.y];
    order = sprite.rotationOrder.copy();
    referenceX = sprite.x + sprite.x2;
    referenceY = sprite.y + sprite.y2;
    skewFieldX = Math.tan(sprite.skewX_playfield * Math.PI / 180);
    skewFieldY = Math.tan(sprite.skewY_playfield * Math.PI / 180);
    skewFieldZ = Math.tan(sprite.skewZ_playfield * Math.PI / 180);
    sample(sprite, origin, offsetX, offsetY, 0, 0, 0, width, height);
    sample(sprite, horizontal, offsetX + width, offsetY, 0, 1, 0, width, height);
    sample(sprite, vertical, offsetX, offsetY + height, 0, 0, 1, width, height);
    subtractOrigin(horizontal);
    subtractOrigin(vertical);
    if (displaced)
    {
      sample(sprite, displacementX, offsetX + 1, offsetY, 0, 0, 0, width, height);
      sample(sprite, displacementY, offsetX, offsetY + 1, 0, 0, 0, width, height);
      sample(sprite, displacementZ, offsetX, offsetY, 1, 0, 0, width, height);
      subtractOrigin(displacementX);
      subtractOrigin(displacementY);
      subtractOrigin(displacementZ);
    }
  }

  inline function sample(sprite:ZSpriteProjected, target:Vector3D, x:Float, y:Float, z:Float, u:Float, v:Float, width:Float, height:Float):Void
  {
    target.setTo(x, y, z);
    sprite.transformPlaneVertex(target, u, v, width, height);
  }

  inline function subtractOrigin(axis:Vector3D):Void
  {
    axis.x -= origin.x;
    axis.y -= origin.y;
    axis.z -= origin.z;
  }

  public function transform(target:Vector3D, u:Float, v:Float, dx:Float, dy:Float, dz:Float, ?sprite:ZSpriteProjected):Void
  {
    target.setTo(origin.x + horizontal.x * u + vertical.x * v,
      origin.y + horizontal.y * u + vertical.y * v,
      origin.z + horizontal.z * u + vertical.z * v);
    if (displaced)
    {
      target.x += displacementX.x * dx + displacementY.x * dy + displacementZ.x * dz;
      target.y += displacementX.y * dx + displacementY.y * dy + displacementZ.y * dz;
      target.z += displacementX.z * dx + displacementY.z * dy + displacementZ.z * dz;
    }
    if (sprite != null)
    {
      // Position along the path is supplied by the existing movement system.
      // Reuse the lane's plane and adjust only its position-dependent skew.
      var moveX = sprite.x + sprite.x2 - referenceX;
      var moveY = sprite.y + sprite.y2 - referenceY;
      target.x += moveY * skewFieldX;
      target.y += moveX * skewFieldY;
      target.z += moveY * skewFieldZ;
    }
  }
}
