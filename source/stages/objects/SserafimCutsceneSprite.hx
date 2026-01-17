package stages.objects;

// object used for the first half of the intro animation for SPAGHETTI
class SserafimCutsceneSprite extends FlxAnimate
{
  public function new(x:Float, y:Float)
  {
    super(x, y);

    showPivot = false;
    Paths.loadAnimateAtlas(this, "cutscene/cutsceneMain");
    antialiasing = ClientPrefs.data.antialiasing;
  }

  public function doAnim():Void
  {
    this.animation.play("", true);
  }
}
