import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

// a unique object for santa getting KILLED
class SantaDiesSprite extends FlxAnimate
{
  public function new(x:Float, y:Float)
  {
    super(x, y);
    showPivot = false;
    Paths.loadAnimateAtlas(this, "christmas/santa_speaks_assets");
    antialiasing = ClientPrefs.data.antialiasing;
  }

  public function playCutscene():Void
  {
    // this.visible = true;
    this.anim.play("santa whole scene");
  }
}
