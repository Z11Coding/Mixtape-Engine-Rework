import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

// a unique object for santa getting KILLED
class DadShootsSprite extends FlxAnimate
{
  public function new(x:Float, y:Float)
  {
    super(x, y);

    showPivot = false;
    Paths.loadAnimateAtlas(this, "christmas/parents_shoot_assets");
    antialiasing = ClientPrefs.data.antialiasing;
  }

  public function playCutscene():Void
  {
    this.animation.play("parents whole scene");
  }
}
