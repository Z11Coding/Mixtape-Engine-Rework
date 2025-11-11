package states.freeplay.vslice;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import states.freeplay.vslice.FreeplayStyle;

#if !html5
import openfl.filters.BitmapFilterQuality;
import shaders.GaussianBlurShader;
#end

/**
 * Capsule text for V-Slice freeplay system
 * Adapted from P-Slice for Mixtape Engine
 */
class CapsuleText extends FlxSpriteGroup
{
  public var text(default, set):String;
  public var blurredText:FlxSprite;
  public var clipWidth(default, set):Int = 255;
  public var tooLong:Bool = false;

  #if !html5
  static var blurShader:GaussianBlurShader = null;
  #end

  var whiteText:FlxText;
  var glowColor:FlxColor = 0xFF00ccff;

  public function new(x:Float, y:Float, songTitle:String, size:Float)
  {
    super(x, y);

    whiteText = initText(songTitle, size);
    @:privateAccess
    whiteText.regenGraphic();

    blurredText = new FlxSprite().loadGraphic(whiteText.graphic);

    #if !html5
    if (ClientPrefs.data.shaders && blurShader == null) {
        blurShader = new GaussianBlurShader(1);
    }
    if (blurShader != null) {
        blurredText.shader = blurShader;
    }
    #end

    text = songTitle;

    blurredText.color = glowColor;
    whiteText.color = 0xFFFFFFFF;
    add(blurredText);
    add(whiteText);
  }

  function initText(songTitle:String, size:Float):FlxText
  {
    var text:FlxText = new FlxText(0, 0, 0, songTitle, Std.int(size));
    text.setFormat(Paths.font("vcr.ttf"), Std.int(size), FlxColor.WHITE, LEFT);
    text.antialiasing = ClientPrefs.data.antialiasing;
    return text;
  }

  public function applyStyle(styleData:FreeplayStyle):Void
  {
    // Simple color application for Mixtape Engine
    glowColor = 0xFF00ccff; // Default blue glow
    blurredText.color = glowColor;

    #if !html5
    if (ClientPrefs.data.shaders) {
        whiteText.textField.filters = [
            new openfl.filters.GlowFilter(glowColor, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM),
        ];
    }
    #end
  }

  // ???? none
  // 255, 27 normal
  // 220, 27 favourited

  function set_clipWidth(value:Int):Int
  {
    resetText();
    checkClipWidth(value);
    return clipWidth = value;
  }

  /**
   * Checks if the text if it's too long, and clips if it is
   * @param wid
   */
  function checkClipWidth(?wid:Int):Void
  {
    if (wid == null) wid = clipWidth;

    if (whiteText.width > wid)
    {
      tooLong = true;

      blurredText.clipRect = new FlxRect(0, 0, wid, blurredText.height);
      whiteText.clipRect = new FlxRect(0, 0, wid, whiteText.height);
    }
    else
    {
      tooLong = false;

      blurredText.clipRect = null;
      whiteText.clipRect = null;
    }
  }

  function set_text(value:String):String
  {
    if (value == null) return value;
    if (blurredText == null || whiteText == null)
    {
      trace('WARN: Capsule not initialized properly');
      return text = value;
    }

    whiteText.text = value;
    @:privateAccess
    whiteText.regenGraphic();
    blurredText.loadGraphic(whiteText.graphic);
    checkClipWidth();

    #if !html5
    if (ClientPrefs.data.shaders) {
        whiteText.textField.filters = [
            new openfl.filters.GlowFilter(glowColor, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM),
        ];
    }
    #end

    return text = value;
  }

  var moveTimer:FlxTimer = new FlxTimer();
  var moveTween:FlxTween;

  public function initMove():Void
  {
    moveTimer.start(0.6, (timer) -> {
      moveTextRight();
    });
  }

  function moveTextRight():Void
  {
    var distToMove:Float = whiteText.width - clipWidth;
    moveTween = FlxTween.tween(whiteText.offset, {x: distToMove}, 2,
      {
        onUpdate: function(_) {
          whiteText.clipRect = new FlxRect(whiteText.offset.x, 0, clipWidth, whiteText.height);
          blurredText.offset = whiteText.offset;
          blurredText.clipRect = new FlxRect(whiteText.offset.x, 0, clipWidth, blurredText.height);
        },
        onComplete: function(_) {
          moveTimer.start(0.3, (timer) -> {
            moveTextLeft();
          });
        },
        ease: FlxEase.sineInOut
      });
  }

  function moveTextLeft():Void
  {
    moveTween = FlxTween.tween(whiteText.offset, {x: 0}, 2,
      {
        onUpdate: function(_) {
          whiteText.clipRect = new FlxRect(whiteText.offset.x, 0, clipWidth, whiteText.height);
          blurredText.offset = whiteText.offset;
          blurredText.clipRect = new FlxRect(whiteText.offset.x, 0, clipWidth, blurredText.height);
        },
        onComplete: function(_) {
          moveTimer.start(0.3, (timer) -> {
            moveTextRight();
          });
        },
        ease: FlxEase.sineInOut
      });
  }

  public function resetText():Void
  {
    if (moveTween != null) moveTween.cancel();
    if (moveTimer != null) moveTimer.cancel();
    whiteText.offset.x = 0;
    whiteText.clipRect = new FlxRect(whiteText.offset.x, 0, clipWidth, whiteText.height);
    blurredText.clipRect = new FlxRect(whiteText.offset.x, 0, clipWidth, whiteText.height);
  }

  var flickerState:Bool = false;
  var flickerTimer:FlxTimer;

  public function flickerText():Void
  {
    resetText();
    flickerTimer = new FlxTimer().start(1 / 24, flickerProgress, 19);
  }

  function flickerProgress(timer:FlxTimer):Void
  {
    if (flickerState == true)
    {
      whiteText.blend = BlendMode.ADD;
      blurredText.blend = BlendMode.ADD;
      blurredText.color = 0xFFFFFFFF;
      whiteText.color = 0xFFFFFFFF;

      #if !html5
      if (ClientPrefs.data.shaders) {
          whiteText.textField.filters = [
              new openfl.filters.GlowFilter(0xFFFFFF, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM),
          ];
      }
      #end
    }
    else
    {
      blurredText.color = glowColor;
      whiteText.color = 0xFFDDDDDD;

      #if !html5
      if (ClientPrefs.data.shaders) {
          whiteText.textField.filters = [
              new openfl.filters.GlowFilter(0xDDDDDD, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM),
          ];
      }
      #end
    }
    flickerState = !flickerState;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }
}
