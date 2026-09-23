package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import lime.app.Future;
import lime.app.Promise;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;

/**
 * Handles caching of textures and sounds for the game.
 * I did this hello, this can be improved later on and I have ideas on how, but for now this functions well enough. -Zack
 */
@:nullSafety
class FunkinMemory
{
  static var permanentCachedTextures:Map<String, FlxGraphic> = [];
  static var currentCachedTextures:Map<String, FlxGraphic> = [];
  static var previousCachedTextures:Map<String, FlxGraphic> = [];
  static var permanentCachedSounds:Map<String, Sound> = [];
  static var currentCachedSounds:Map<String, Sound> = [];
  static var previousCachedSounds:Map<String, Sound> = [];
  static var currentCachedFrames:Map<String, FlxFramesCollection> = [];
  static var purgeFilter:Array<String> = ['/week', '/characters', '/charSelect', '/results'];

  /**
   * Caches textures that are always required.
   */
  public static inline function initialCache():Void
  {
    var allImages:Array<String> = Assets.list();

    for (file in allImages)
    {
      if (!(file.endsWith('.png') #if FEATURE_COMPRESSED_TEXTURES || file.endsWith('.astc') #end)
        || file.contains('chart-editor')
        || !file.contains('ui/'))
      {
        continue;
      }

      file = file.replace(' ', ''); // Handle stray spaces.

      if (file.contains('shared') || Assets.exists('shared:$file', AssetType.IMAGE))
      {
        file = 'shared:$file';
      }
      permanentCacheTexture(file);
    }

    permanentCacheTexture(Paths.imagePath('healthBar'));
    permanentCacheTexture(Paths.imagePath('menuDesat'));
    permanentCacheTexture(Paths.imagePath('noteSkins/NOTE_assets', 'shared'));
    permanentCacheTexture(Paths.imagePath('noteSkins/strums', 'shared'));
    // dude
    permanentCacheTexture(Paths.imagePath('fonts/capsule-text', null));
    permanentCacheTexture(Paths.imagePath('fonts/freeplay-clear', null));

    var allSounds:Array<String> = Assets.list(AssetType.SOUND);

    for (file in allSounds)
    {
      if (!file.endsWith('.ogg') || !file.contains('countdown/')) continue;

      file = file.replace(' ', '');

      if (file.contains('shared') || Assets.exists('shared:$file', AssetType.SOUND))
      {
        file = 'shared:$file';
      }

      permanentCacheSound(file);
    }

    permanentCacheSound(Paths.soundP('cancelMenu'));
    permanentCacheSound(Paths.soundP('confirmMenu'));
    permanentCacheSound(Paths.soundP('screenshot'));
    permanentCacheSound(Paths.soundP('scrollMenu'));
    permanentCacheSound(Paths.soundP('soundtray/Voldown'));
    permanentCacheSound(Paths.soundP('soundtray/VolMAX'));
    permanentCacheSound(Paths.soundP('soundtray/Volup'));
    permanentCacheSound(Paths.musicPath('freakyMenu/freakyMenu'));
    permanentCacheSound(Paths.musicPath('offsetsLoop/offsetsLoop'));
    permanentCacheSound(Paths.musicPath('offsetsLoop/drumsLoop'));
    permanentCacheSound(Paths.soundP('missnote1'));
    permanentCacheSound(Paths.soundP('missnote2'));
    permanentCacheSound(Paths.soundP('missnote3'));
  }

  /**
   * Clears the current texture and sound caches.
   * @param callGarbageCollector Whether to call the system's garbage collector after purging.
   */
  public static inline function purgeCache(callGarbageCollector:Bool = false):Void
  {
    trace(' CLEARING CACHE: Disposing all cached textures, assets and sounds...');

    preparePurgeTextureCache();
    purgeTextureCache();
    preparePurgeSoundCache();
    purgeSoundCache();
    #if (cpp || neko || hl)
    if (callGarbageCollector) backend.util.MemoryUtil.collect(true);
    #end
  }

  ///// TEXTURES /////

  /**
   * Ensures a texture with the given key is cached.
   * @param key The key of the texture to cache.
   */
  public static function cacheTexture(key:String):Void
  {
    if (currentCachedTextures.exists(key)) return;

    if (previousCachedTextures.exists(key))
    {
      // Move the texture from the previous cache to the current cache.
      var graphic:Null<FlxGraphic> = previousCachedTextures.get(key);
      previousCachedTextures.remove(key);
      if (graphic != null) currentCachedTextures.set(key, graphic);
      return;
    }

    var graphic:Null<FlxGraphic> = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
      return;
    }

    log('Cached asset $key');
    graphic.persist = true;
    currentCachedTextures.set(key, graphic);
    forceRender(graphic);
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCacheTexture(key:String):Void
  {
    if (permanentCachedTextures.exists(key)) return;

    var graphic:Null<FlxGraphic> = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
      return;
    }

    log('Cached graphic $key');
    graphic.persist = true;
    permanentCachedTextures.set(key, graphic);
    forceRender(graphic);
    currentCachedTextures = permanentCachedTextures.copy();
  }

  public static function getCachedGraphic(path:String):Null<FlxGraphic>
  {
    if (permanentCachedTextures.exists(path)) return permanentCachedTextures.get(path);
    if (currentCachedTextures.exists(path)) return currentCachedTextures.get(path);
    if (previousCachedTextures.exists(path)) return previousCachedTextures.get(path); // just in case

    return null;
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public static inline function preparePurgeTextureCache():Void
  {
    previousCachedTextures = currentCachedTextures.copy();

    for (graphicKey in previousCachedTextures.keys())
    {
      if (permanentCachedTextures.exists(graphicKey))
      {
        previousCachedTextures.remove(graphicKey);
      }
    }

    currentCachedTextures = permanentCachedTextures.copy();
  }

  /**
   * Purges unused textures from the cache.
   */
  public static function purgeTextureCache():Void
  {
    for (graphicKey in previousCachedTextures.keys())
    {
      if (permanentCachedTextures.exists(graphicKey))
      {
        previousCachedTextures.remove(graphicKey);
        continue;
      }

      if (graphicKey.contains('fonts')) continue;

      var graphic:Null<FlxGraphic> = previousCachedTextures.get(graphicKey);
      if (graphic != null)
      {
        FlxG.bitmap.remove(graphic);
        graphic.persist = false;
        graphic.destroy();
        previousCachedTextures.remove(graphicKey);
        Assets.cache.clear(graphicKey);
      }
    }

    for (frame in currentCachedFrames.keys()) {
      var graphic:Null<FlxFramesCollection> = currentCachedFrames.get(frame);
      if (graphic != null)
      {
        graphic.parent?.destroy();
        graphic.destroy();
        currentCachedFrames.remove(frame);
        Assets.cache.clear(frame);
      }
    }

    @:privateAccess
    if (FlxG.bitmap._cache == null)
    {
      @:privateAccess
      FlxG.bitmap._cache = new Map();
    }

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);

      if (obj == null || (obj.persist && permanentCachedTextures.exists(key)) || key.contains('fonts'))
      {
        continue;
      }

      if (obj.useCount > 0)
      {
        for (purgeEntry in purgeFilter)
        {
          if (key.contains(purgeEntry))
          {
            FlxG.bitmap.removeKey(key);
            obj.persist = false;
            obj.destroy();
          }
        }
      }
    }
  }

  /**
   * Forces the GPU to load and upload a FlxGraphic.
   * @param graphic The graphic to force render.
   */
  static function forceRender(graphic:FlxGraphic):Void
  {
    if (graphic == null) return;

    var bmp:Null<FlxGraphic> = FlxG.bitmap.get(graphic.key);
    if (bmp != null && bmp.bitmap != null) var _:Int = bmp.bitmap.width; // Trigger

    // Draws sprite and actually caches it.
    var sprite = new flixel.FlxSprite();
    sprite.loadGraphic(graphic);
    sprite.draw(); // Draw sprite and load it into game's memory.
    graphic.bitmap?.getTexture(FlxG.stage.context3D); // Just in case that didn't work...
    sprite.destroy();
  }

  /**
   * Determine whether the texture with the given key is cached.
   * @param key The key of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(key:String):Bool
  {
    return FlxG.bitmap.get(key) != null
      && (permanentCachedTextures.exists(key) || currentCachedTextures.exists(key) || previousCachedTextures.exists(key));
  }

  ///// SOUND //////

  /**
   * Caches a sound with the given key.
   * @param key The key of the sound to cache.
   */
  public static function cacheSound(key:String):Void
  {
    if (currentCachedSounds.exists(key)) return;

    if (previousCachedSounds.exists(key))
    {
      // Move the texture from the previous cache to the current cache.
      var sound:Null<Sound> = previousCachedSounds.get(key);
      previousCachedSounds.remove(key);
      if (sound != null) currentCachedSounds.set(key, sound);
      return;
    }

    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound == null)
    {
      return;
    }
    else
    {
      currentCachedSounds.set(key, sound);
    }
  }

  /**
   * Permanently caches a sound with the given key.
   * @param key The key of the sound to cache.
   */
  public static function permanentCacheSound(key:String):Void
  {
    if (permanentCachedSounds.exists(key)) return;

    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound == null)
    {
      return;
    }
    else
    {
      permanentCachedSounds.set(key, sound);
    }

    if (sound != null) currentCachedSounds.set(key, sound);
  }

  /**
   * Prepares the cache for purging unused sounds.
   */
  public static function preparePurgeSoundCache():Void
  {
    previousCachedSounds = currentCachedSounds.copy();

    for (key in previousCachedSounds.keys())
    {
      if (permanentCachedSounds.exists(key))
      {
        previousCachedSounds.remove(key);
      }
    }

    currentCachedSounds = permanentCachedSounds.copy();
  }

  /**
   * Purges unused sounds from the cache.
   */
  public static inline function purgeSoundCache():Void
  {
    for (key in previousCachedSounds.keys())
    {
      if (permanentCachedSounds.exists(key))
      {
        previousCachedSounds.remove(key);
        continue;
      }

      var sound:Null<Sound> = previousCachedSounds.get(key);
      if (sound != null)
      {
        Assets.cache.removeSound(key);
        previousCachedSounds.remove(key);
      }
    }
    Assets.cache.clear('songs');
    Assets.cache.clear('music');
    // Felt lazy.
    var key = Paths.musicPath('menuMusic/freakyMenu');
    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound != null)
    {
      permanentCachedSounds.set(key, sound);
      currentCachedSounds.set(key, sound);
    }
  }

  ///// MISC /////

  /**
   * Clears all Freeplay assets from memory.
   */
  public static inline function clearFreeplay():Void
  {
    var keysToRemove:Array<String> = [];

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (!key.contains('freeplay')) continue;
      if (permanentCachedTextures.exists(key) || key.contains('fonts')) continue;

      keysToRemove.push(key);
    }

    @:privateAccess
    for (key in keysToRemove)
    {
      log('Cleaning asset $key');
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);
      if (obj != null)
      {
        obj.destroy();
      }
      FlxG.bitmap.removeKey(key);
      if (currentCachedTextures.exists(key)) currentCachedTextures.remove(key);
      Assets.cache.clear(key);
    }

    preparePurgeSoundCache();
    purgeSoundCache();
  }

  /**
   * Clears all sticker assets from memory.
   */
  public static inline function clearStickers():Void
  {
    var keysToRemove:Array<String> = [];

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (!key.contains('stickers')) continue;
      if (permanentCachedTextures.exists(key) || key.contains('fonts')) continue;

      keysToRemove.push(key);
    }

    @:privateAccess
    for (key in keysToRemove)
    {
      log('Cleaning asset $key');
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);
      if (obj != null)
      {
        obj.destroy();
      }
      FlxG.bitmap.removeKey(key);
      if (currentCachedTextures.exists(key)) currentCachedTextures.remove(key);
      Assets.cache.clear(key);
    }
  }

  /**
   * Sends a trace with fancy ANSI colors.
   * @param message The message to log.
   */
  static function log(message:String):Void
  {
    trace(' MEMORY ${message}');
  }
}
