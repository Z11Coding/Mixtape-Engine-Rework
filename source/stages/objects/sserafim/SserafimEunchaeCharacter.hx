package stages.objects.sserafim;
import animate.internal.Layer;
import animate.internal.SymbolItem;

class SserafimEunchaeCharacter extends Character
{
  var lipSyncSprite:SserafimLipSyncSprite;

  /**
   * A map of animation names to lip sync data.
   * This is so it gets offset properly!
   */
  final LIP_SYNC_OFFSETS:Map<String, LipSyncData> = [
    'idle' =>
    {
      offset: [43, 6],
      angle: -168
    },
    'singUP' =>
    {
      offset: [45, 10],
      angle: -166
    },
    'singRIGHT' =>
    {
      offset: [42, 5],
      angle: -166
    },
    'singDOWN' =>
    {
      offset: [41, 3],
      angle: -168
    },
    'singLEFT' =>
    {
      offset: [43, 6],
      angle: -169
    }
  ];

  public function new(x:Float, y:Float)
  {
    super(x, y, 'sserafim-eunchae', true, OTHER);

    lipSyncSprite = new SserafimLipSyncSprite(0, 0);

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

  function hideDefaultMouth():Void
  {
    var symbolItem:SymbolItem = this.library.getSymbol('mouth default');
    var layer:Layer = symbolItem.timeline.getLayer(0);

    layer.forEachFrame((frame) -> {
      frame.forEachElement((element) -> {
        element.visible = false;
      });
    });
  }
}
