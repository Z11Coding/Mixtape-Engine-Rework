package stages.objects.sserafim;

class SserafimChaewonCharacter extends Character
{
  var lipSyncSprite:SserafimLipSyncSprite;

  /**
   * A map of animation names to lip sync data.
   * This is so it gets offset properly!
   */
  final LIP_SYNC_OFFSETS:Map<String, LipSyncData> = [
    'idle' =>
    {
      offset: [41, 3],
      angle: -166
    },
    'singUP' =>
    {
      offset: [38, 0],
      angle: -168
    },
    'singRIGHT' =>
    {
      offset: [39, 1],
      angle: -165
    },
    'singDOWN' =>
    {
      offset: [41, 3],
      angle: -167
    },
    'singLEFT' =>
    {
      offset: [40, 2],
      angle: -165
    }
  ];

  public function new(x:Float, y:Float)
  {
    super(x, y, 'sserafim-chaewon', true, OTHER);

    lipSyncSprite = new SserafimLipSyncSprite(0, 0);
    lipSyncSprite.alpha = 0.5;

    var element:FlxSpriteElement = new FlxSpriteElement(lipSyncSprite);
    element.active = false; // We disable the element here so we can control when it updates.

    for (frame in this.getFramesWithKeyword("mouth default"))
    {
      frame.add(element);
    }
  }

  override public function playAnim(name:String, restart:Bool = false, reversed:Bool = false, frame:Int = 0)
  {
    super.playAnim(name, restart, reversed, frame);

    if (LIP_SYNC_OFFSETS.exists(name) && lipSyncSprite != null)
    {
      var data:LipSyncData = LIP_SYNC_OFFSETS.get(name);

      lipSyncSprite.offset.set(data.offset[0], data.offset[1]);
      lipSyncSprite.angle = data.angle;
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (lipSyncSprite != null) {
      lipSyncSprite.update(elapsed);

      lipSyncSprite.shouldSing = this.charType == CharType.BF;

      synchronizeShader();
    }
  }

  var currentShader = null;

  function synchronizeShader():Void
  {
    if (currentShader == this.shader) return;

    currentShader = this.shader;

    lipSyncSprite.shader = currentShader;

    trace("Synchronized shader between children!");
  }

  override public function isOnScreen(?camera:FlxCamera):Bool
  {
    // TODO: Figure out why she disappears when the camera zooms in too much!!
    // This is such a shit fix but it works.
    return true;
  }
}
