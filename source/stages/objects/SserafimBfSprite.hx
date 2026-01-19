package stages.objects;

// object used when bf gets up during the second half of the intro animation for SPAGHETTI
class SserafimBfSprite extends FunkinSprite
{
  public function new(x:Float, y:Float)
  {
    super(x, y);

    loadTextureAtlas("cutscene/bfGetUp", "sserafim");
    antialiasing = ClientPrefs.data.antialiasing;
  }

  public function resetAnim():Void
  {
    this.anim.play("static", true);
  }

  public function doAnim():Void
  {
    this.anim.play("getup", true);
  }
}
