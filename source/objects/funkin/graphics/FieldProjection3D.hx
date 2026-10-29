package objects.funkin.graphics;

import openfl.geom.Vector3D;

/**
 * One model matrix for the ENTIRE note field, applied before perspective.
 * Notes, receptors, holds and arrowpaths use the same world-space pivot.
 * No song time, movement, input or hit state is read or written.
 */
class FieldProjection3D
{
  var dirty:Bool = true;
  public var revision(default, null):Int = 0;
  public var enabled(default, set):Bool = false;
  inline function set_enabled(v:Bool):Bool { if (enabled != v) dirty = true; return enabled = v; }
  public var mirrorX(default, set):Bool = false;
  inline function set_mirrorX(v:Bool):Bool { if (mirrorX != v) dirty = true; return mirrorX = v; }
  public var automaticPivot(default, set):Bool = true;
  inline function set_automaticPivot(v:Bool):Bool { if (automaticPivot != v) dirty = true; return automaticPivot = v; }
  /** Relative coordinates are authored for upscroll and follow the actual field anchor. */
  public var relativeCoordinates(default, set):Bool = true;
  inline function set_relativeCoordinates(v:Bool):Bool { if (relativeCoordinates != v) dirty = true; return relativeCoordinates = v; }
  public var correctScrollDirection(default, set):Bool = true;
  inline function set_correctScrollDirection(v:Bool):Bool { if (correctScrollDirection != v) dirty = true; return correctScrollDirection = v; }
  public var positionEnabled(default, set):Bool = false;
  inline function set_positionEnabled(v:Bool):Bool { if (positionEnabled != v) dirty = true; return positionEnabled = v; }
  public var positionX(default, set):Float = 0;
  inline function set_positionX(v:Float):Float { if (positionX != v) dirty = true; return positionX = v; }
  public var positionY(default, set):Float = 0;
  inline function set_positionY(v:Float):Float { if (positionY != v) dirty = true; return positionY = v; }
  public var positionZ(default, set):Float = 0;
  inline function set_positionZ(v:Float):Float { if (positionZ != v) dirty = true; return positionZ = v; }
  public var rotationX(default, set):Float = 0;
  inline function set_rotationX(v:Float):Float { if (rotationX != v) dirty = true; return rotationX = v; }
  public var rotationY(default, set):Float = 0;
  inline function set_rotationY(v:Float):Float { if (rotationY != v) dirty = true; return rotationY = v; }
  public var rotationZ(default, set):Float = 0;
  inline function set_rotationZ(v:Float):Float { if (rotationZ != v) dirty = true; return rotationZ = v; }
  public var depth(default, set):Float = 0;
  inline function set_depth(v:Float):Float { if (depth != v) dirty = true; return depth = v; }
  public var pivotX(default, set):Float = 0;
  inline function set_pivotX(v:Float):Float { if (pivotX != v) dirty = true; return pivotX = v; }
  public var pivotY(default, set):Float = 0;
  inline function set_pivotY(v:Float):Float { if (pivotY != v) dirty = true; return pivotY = v; }
  public var pivotZ(default, set):Float = 0;
  inline function set_pivotZ(v:Float):Float { if (pivotZ != v) dirty = true; return pivotZ = v; }
  public var scaleX(default, set):Float = 1;
  inline function set_scaleX(v:Float):Float { if (scaleX != v) dirty = true; return scaleX = v; }
  public var scaleY(default, set):Float = 1;
  inline function set_scaleY(v:Float):Float { if (scaleY != v) dirty = true; return scaleY = v; }
  public var scaleZ(default, set):Float = 1;
  inline function set_scaleZ(v:Float):Float { if (scaleZ != v) dirty = true; return scaleZ = v; }

  var xx:Float = 1; var xy:Float = 0; var xz:Float = 0;
  var yx:Float = 0; var yy:Float = 1; var yz:Float = 0;
  var zx:Float = 0; var zy:Float = 0; var zz:Float = 1;
  var anchorX:Float = 0; var anchorY:Float = 0;
  var downScroll:Bool = false;
  var resolvedX:Float = 0; var resolvedY:Float = 0;
  var moveX:Float = 0; var moveY:Float = 0; var moveZ:Float = 0;

  public function new() {}

  public function setRotation(x:Float, y:Float, z:Float = 0):Void
  {
    enabled = true;
    rotationX = x; rotationY = y; rotationZ = z;
  }

  public function setPivot(x:Float, y:Float, z:Float = 0):Void
  {
    automaticPivot = false;
    pivotX = x; pivotY = y; pivotZ = z;
  }

  /** Relative: offset from the field anchor. Absolute: target anchor on screen. */
  public function setPosition(x:Float, y:Float, z:Float = 0):Void
  {
    enabled = positionEnabled = true;
    positionX = x; positionY = y; positionZ = z;
  }

  public function prepareAutomaticPivot(x:Float, y:Float, downScroll:Bool = false):Void
  {
    if (anchorX != x || anchorY != y || this.downScroll != downScroll) dirty = true;
    anchorX = x; anchorY = y; this.downScroll = downScroll;
    prepare();
  }

  /** Rebuild once when the FIELD's controls change, not once per note. */
  public function prepare():Void
  {
    if (!dirty) return;
    var direction:Float = relativeCoordinates && correctScrollDirection && downScroll ? -1 : 1;
    resolvedX = automaticPivot ? anchorX : relativeCoordinates ? anchorX + pivotX : pivotX;
    resolvedY = automaticPivot ? anchorY : relativeCoordinates ? anchorY + pivotY * direction : pivotY;
    moveX = positionEnabled ? relativeCoordinates ? positionX : positionX - anchorX : 0;
    moveY = positionEnabled ? relativeCoordinates ? positionY * direction : positionY - anchorY : 0;
    moveZ = (positionEnabled ? positionZ : 0) + depth;
    // Conjugate the authored rotation by the scroll-space Y reflection.
    // Pitch and roll reverse in downscroll; yaw and camera depth keep their axes.
    var ax = rotationX * direction * Math.PI / 180;
    var ay = rotationY * Math.PI / 180;
    var az = rotationZ * direction * Math.PI / 180;
    var sx = Math.sin(ax); var cx = Math.cos(ax);
    var sy = Math.sin(ay); var cy = Math.cos(ay);
    var sz = Math.sin(az); var cz = Math.cos(az);
    var scale = mirrorX ? -scaleX : scaleX;
    // Rz * Ry * Rx, with scale baked into the columns.
    xx = cz * cy * scale;
    xy = (cz * sy * sx - sz * cx) * scaleY;
    xz = (cz * sy * cx + sz * sx) * scaleZ;
    yx = sz * cy * scale;
    yy = (sz * sy * sx + cz * cx) * scaleY;
    yz = (sz * sy * cx - cz * sx) * scaleZ;
    zx = -sy * scale;
    zy = cy * sx * scaleY;
    zz = cy * cx * scaleZ;
    dirty = false;
    revision++;
  }

  /** Transform a render vertex using the already prepared shared matrix. */
  public function transform(point:Vector3D):Void
  {
    if (!enabled) return;
    var x = point.x - resolvedX;
    var y = point.y - resolvedY;
    var z = point.z - pivotZ;
    point.setTo(resolvedX + xx * x + xy * y + xz * z + moveX,
      resolvedY + yx * x + yy * y + yz * z + moveY,
      pivotZ + zx * x + zy * y + zz * z + moveZ);
  }
}

