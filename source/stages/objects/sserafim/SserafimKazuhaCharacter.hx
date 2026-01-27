package stages.objects.sserafim;

class SserafimKazuhaCharacter extends Character
{
  var lipSyncSprite:SserafimLipSyncSprite;

  /**
   * A map of animation names to lip sync data.
   * This is so it gets offset properly!
   */
  final LIP_SYNC_OFFSETS:Map<String, LipSyncData> = [
    'idle' =>
    {
      offset: [5, 4],
      angle: -13
    },
    'singUP' =>
    {
      offset: [7, 2],
      angle: -14
    },
    'singRIGHT' =>
    {
      offset: [7, 2],
      angle: -13
    },
    'singDOWN' =>
    {
      offset: [4, 6],
      angle: -12
    },
    'singLEFT' =>
    {
      offset: [5, 4],
      angle: -14
    }
  ];

  public function new(x:Float, y:Float)
  {
    super(x, y, 'sserafim-kazuha', true, DAD);
    lipSyncSprite = new SserafimLipSyncSprite(0, 0);
    lipSyncSprite.flipX = true;

    var element:FlxSpriteElement = new FlxSpriteElement(lipSyncSprite);
    element.active = false; // We disable the element here so we can control when it updates.

    // hideDefaultMouth();

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
}
