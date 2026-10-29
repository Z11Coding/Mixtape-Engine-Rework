package objects.funkin.graphics;

import openfl.geom.Vector3D;

/**
 * Render-only perspective. Inputs are a finished spatial position and a POV.
 * It has no conductor, song position, note speed, hit window or animation clock.
 * A textured plane uses the same image on both faces; only its vertices move.
 */
class ProjectionView3D
{
  var width:Int = -1;
  var height:Int = -1;
  var fov:Float = -1;
  var near:Float = -1;
  var far:Float = -1;
  var centerX:Float = 0;
  var centerY:Float = 0;
  var depthScale:Float = 1;
  var depthOffset:Float = 0;

  public function new() {}

  public function configure(width:Int, height:Int, fov:Float, near:Float, far:Float):Void
  {
    if (this.width == width && this.height == height && this.fov == fov && this.near == near && this.far == far) return;
    this.width = width;
    this.height = height;
    this.fov = fov;
    this.near = near;
    this.far = far;
    centerX = width * 0.5;
    centerY = height * 0.5;
    // Preserve the existing public FOV / normalized-Z convention.
    depthScale = fov / 90;
    var range = near - far;
    if (Math.abs(range) < 0.000001) range = range < 0 ? -0.000001 : 0.000001;
    depthOffset = 2 * far * near / range;
  }

  /** Mutates only the supplied render vertex. z becomes its signed clip depth. */
  public function project(point:Vector3D, povX:Float, povY:Float, nearAllowance:Float, offsetX:Float = 0, offsetY:Float = 0):Vector3D
  {
    var depth = Math.min(point.z * depthScale, near + nearAllowance) - 1 + depthOffset;
    // Signed floor, like ScreenStudio's geometry helpers: avoid a singular divide.
    if (Math.abs(depth) < 0.000001) depth = depth < 0 ? -0.000001 : 0.000001;
    var reciprocal = -1 / depth;
    var cx = centerX + povX;
    var cy = centerY + povY;
    point.x = cx + (point.x - cx) * reciprocal + offsetX;
    point.y = cy + (point.y - cy) * reciprocal + offsetY;
    point.z = depth;
    return point;
  }
}
