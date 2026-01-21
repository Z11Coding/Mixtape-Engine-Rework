package backend.util;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import objects.Character.AnimArray;
import objects.FunkinSprite;

class FlxAnimationUtil
{
  /**
   * Properly adds an animation to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimation(target:FlxSprite, anim:AnimArray):Void
  {
    if (anim.prefix == null) return;

    var frameRate:Int = anim.fps ?? 24;
    var looped:Bool = anim.loop ?? false;
    var flipX:Bool = false;
    var flipY:Bool = false;

    if (anim.indices != null && anim.indices.length > 0)
    {
      target.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', frameRate, looped, flipX, flipY);
    }
    else
    {
      target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
    }
  }

  /**
   * Properly adds an animation to a texture atlas sprite based on the provided animation data.
   */
  public static function addTextureAtlasAnimation(target:FunkinSprite, anim:AnimArray):Void
  {
    if (!target.isAnimate) return;
    if (anim.prefix == null) return;

    var frameRate:Int = anim.fps ?? 24;
    var looped:Bool = anim.loop ?? false;
    var flipX:Bool = false;
    var flipY:Bool = false;
    var animType:String = "framelabel";

    if (anim.indices != null && anim.indices.length > 0)
    {
      switch (animType)
      {
        case "framelabel":
          target.anim.addByFrameLabelIndices(anim.name, anim.prefix, anim.indices, frameRate, looped, flipX, flipY);
        case "symbol":
          target.anim.addBySymbolIndices(anim.name, anim.prefix, anim.indices, frameRate, looped, flipX, flipY);
      }
    }
    else
    {
      switch (animType)
      {
        case "framelabel":
          target.anim.addByFrameLabel(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
        case "symbol":
          target.anim.addBySymbol(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
      }
    }
  }

  /**
   * Properly adds multiple animations to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimations(target:FlxSprite, animations:Array<AnimArray>):Void
  {
    for (anim in animations)
    {
      addAtlasAnimation(target, anim);
    }
  }

  /**
   * Properly adds multiple animations to a texture atlas sprite based on the provided animation data.
   */
  public static function addTextureAtlasAnimations(target:FunkinSprite, animations:Array<AnimArray>):Void
  {
    for (anim in animations)
    {
      addTextureAtlasAnimation(target, anim);
    }
  }

  /**
   * Combine two FlxFramesCollection objects into one.
   * @param a The first FlxFramesCollection
   * @param b The second FlxFramesCollection
   * @return FlxFramesCollection The combined FlxFramesCollection
   */
  public static function combineFramesCollections(a:FlxFramesCollection, b:FlxFramesCollection):FlxFramesCollection
  {
    var result:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);

    for (frame in a.frames)
    {
      result.pushFrame(frame);
    }
    for (frame in b.frames)
    {
      result.pushFrame(frame);
    }

    return result;
  }
}
