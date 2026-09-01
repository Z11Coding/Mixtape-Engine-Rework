package games.brun.objects.player;

class BaseChar extends FlxSprite {
  // Character Info
  public var charName:String = "???";
  public var charSpeed:Int = 100;
  public var charVelocity:Float = 4;
  public var charGravity:Int = 600;

  // For Dialogue
  public var charPortrait:String = "???";
  public var charPronouns:String = "???/???";

  // Internal Stuff
  var controls(get, never):Controls;
  private function get_controls()
    return Controls.instance;

  override public function new(charImage:String, charInfo:CharInfo) {
    super(0, 0);
    loadGraphic(Paths.image('assets/characters/$charImage'));
    if (charInfo != null) {
      charName = charInfo.charName;
      charSpeed = charInfo.charSpeed;
      charVelocity = charInfo.charVelocity;
      charGravity = charInfo.charGravity;
    }

    // Movement Stuff
    drag.x = (charSpeed * charVelocity);
    acceleration.y = charGravity;
  }

  function doMovement() {
    if (controls.UI_LEFT)
      velocity.x = -charSpeed;
    else if (controls.UI_RIGHT)
      velocity.x = charSpeed;

    if (controls.UI_UP_P && isTouching(FlxObject.FLOOR)) {
      velocity.y = -charGravity / 1.5;
    }
  }

  function jumpCheck() {
    if (controls.UI_UP_P && isTouching(FlxObject.FLOOR)) {
      velocity.y = -charGravity / 1.5;
    }
  }

  override function update(e:Float) {
    jumpCheck();
    super.update(e);
    doMovement();
  }
}

typedef CharInfo = {
  charName:String,
  charPortrait:String,
  charPronouns:String,
  charSpeed:Int,
  charVelocity:Float,
  charGravity:Int
}
