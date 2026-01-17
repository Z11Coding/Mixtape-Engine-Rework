package stages.objects;

// object used when bf gets up during the second half of the intro animation for SPAGHETTI
class SserafimBfSprite extends FlxAnimate
{
  public function new(x:Float, y:Float)
  {
    super(x, y);

    showPivot = false;
    Paths.loadAnimateAtlas(this, "cutscene/bfGetUp");
    antialiasing = ClientPrefs.data.antialiasing;
  }

  public function resetAnim():Void
  {
    this.animation.play("static", true);
  }

  public function doAnim():Void
  {
    this.animation.play("getup", true);
  }
}
