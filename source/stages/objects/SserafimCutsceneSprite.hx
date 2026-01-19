package stages.objects;

// object used for the first half of the intro animation for SPAGHETTI
class SserafimCutsceneSprite extends FunkinSprite
{
  public function new(x:Float, y:Float)
  {
    super(x, y);

    loadTextureAtlas("cutscene/cutsceneMain", "sserafim");
    antialiasing = ClientPrefs.data.antialiasing;
  }

  public function doAnim():Void
  {
    this.anim.play("", true);
  }
}
