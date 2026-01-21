package stages.objects.sserafim;
import animate.internal.Layer;
import animate.internal.SymbolItem;

class SserafimSakuraCharacter extends Character
{
  var lipSyncSprite:SserafimLipSyncSprite;

  /**
   * A map of animation names to lip sync data.
   * This is so it gets offset properly!
   */
  final LIP_SYNC_OFFSETS:Map<String, LipSyncData> = [
    'idle' =>
    {
      offset: [7, 2],
      angle: -14
    },
    'singUP' =>
    {
      offset: [8, 1],
      angle: -15
    },
    'singRIGHT' =>
    {
      offset: [7, 2],
      angle: -15
    },
    'singDOWN' =>
    {
      offset: [6, 3],
      angle: -15
    },
    'singLEFT' =>
    {
      offset: [7, 2],
      angle: -14
    },
    'singUP-both' =>
    {
      offset: [10, -1],
      angle: -14
    },
    'singRIGHT-both' =>
    {
      offset: [6, 3],
      angle: -15
    },
    'singDOWN-both' =>
    {
      offset: [5, 5],
      angle: -15
    },
    'singLEFT-both' =>
    {
      offset: [7, 2],
      angle: -16
    }
  ];

  public function new(x:Float, y:Float)
  {
    super(x, y, 'sserafim-sakura', false, OTHER);

    lipSyncSprite = new SserafimLipSyncSprite(0, 0);
    lipSyncSprite.flipX = true;

    var element:FlxSpriteElement = new FlxSpriteElement(lipSyncSprite);
    element.active = false; // We disable the element here so we can control when it updates.

    for (frame in this.getFramesWithKeyword("mouth edit"))
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

    if (name == "firstDeath")
    {
      if (!this.visible)
      {
        this.visible = true;
      }

      // Hide the opponent health icon so it doesn't show up briefly when the song restarts
      PlayState.instance.iconP2.visible = false;

      // Clear out any shaders this character might have.
      this.shader = null;
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
