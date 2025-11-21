package backend;

import backend.SpriteSheetCache;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import openfl.geom.Rectangle;

/**
 * Utility class for integrating SpriteSheetCache with the existing Paths system
 * Provides easy-to-use functions for caching common spritesheet formats
 */
class CachedPaths
{
    /**
     * Load a Sparrow atlas with caching support
     * @param key Image key (without extension)
     * @param parentFolder Optional parent folder
     * @param allowGPU Whether to allow GPU caching
     * @param forceCache Force caching even if already cached
     * @return FlxAtlasFrames or null
     */
    public static function getSparrowAtlasWithCache(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?forceCache:Bool = false):FlxAtlasFrames
    {
        var cacheKey = key + (parentFolder != null ? '_' + parentFolder : '');

        // Try to load from cache first
        if (!forceCache && SpriteSheetCache.isCached(cacheKey))
        {
            var cached = SpriteSheetCache.loadCachedSpriteSheet(cacheKey);
            if (cached != null)
            {
                trace('[CachedPaths] Loaded Sparrow atlas from cache: $key');
                return cast cached;
            }
        }

        // Load normally and cache
        var atlas = Paths.getSparrowAtlas(key, parentFolder, allowGPU);
        if (atlas != null)
        {
            SpriteSheetCache.cacheSpriteSheet(cacheKey, atlas.parent, atlas);
            trace('[CachedPaths] Cached Sparrow atlas: $key');
        }

        return atlas;
    }

    /**
     * Load a Packer atlas with caching support
     * @param key Image key (without extension)
     * @param parentFolder Optional parent folder
     * @param allowGPU Whether to allow GPU caching
     * @param forceCache Force caching even if already cached
     * @return FlxAtlasFrames or null
     */
    public static function getPackerAtlasWithCache(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?forceCache:Bool = false):FlxAtlasFrames
    {
        var cacheKey = key + (parentFolder != null ? '_' + parentFolder : '');

        // Try to load from cache first
        if (!forceCache && SpriteSheetCache.isCached(cacheKey))
        {
            var cached = SpriteSheetCache.loadCachedSpriteSheet(cacheKey);
            if (cached != null)
            {
                trace('[CachedPaths] Loaded Packer atlas from cache: $key');
                return cast cached;
            }
        }

        // Load normally and cache
        var atlas = Paths.getPackerAtlas(key, parentFolder, allowGPU);
        if (atlas != null)
        {
            SpriteSheetCache.cacheSpriteSheet(cacheKey, atlas.parent, atlas);
            trace('[CachedPaths] Cached Packer atlas: $key');
        }

        return atlas;
    }

    /**
     * Load a TexturePacker JSON atlas with caching support
     * @param key Image key (without extension)
     * @param parentFolder Optional parent folder
     * @param allowGPU Whether to allow GPU caching
     * @param forceCache Force caching even if already cached
     * @return FlxAtlasFrames or null
     */
    public static function getTexturePackerAtlasWithCache(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true, ?forceCache:Bool = false):FlxAtlasFrames
    {
        var cacheKey = key + (parentFolder != null ? '_' + parentFolder : '');

        // Try to load from cache first
        if (!forceCache && SpriteSheetCache.isCached(cacheKey))
        {
            var cached = SpriteSheetCache.loadCachedSpriteSheet(cacheKey);
            if (cached != null)
            {
                trace('[CachedPaths] Loaded TexturePacker atlas from cache: $key');
                return cast cached;
            }
        }

        // Load normally and cache
        var atlas = Paths.getAsepriteAtlas(key, parentFolder, allowGPU);
        if (atlas != null)
        {
            SpriteSheetCache.cacheSpriteSheet(cacheKey, atlas.parent, atlas);
            trace('[CachedPaths] Cached TexturePacker atlas: $key');
        }

        return atlas;
    }

    /**
     * Preload and cache commonly used spritesheets
     * This should be called during loading screens or initialization
     */
    public static function preloadCommonSpritesheets():Void
    {
        if (!SpriteSheetCache.cacheEnabled)
        {
            trace('[CachedPaths] Cache is disabled, skipping preload');
            return;
        }

        trace('[CachedPaths] Preloading common spritesheets...');

        // Cache common character spritesheets if they exist
        var commonCharacters = ['characters/bf', 'characters/gf', 'characters/dad'];
        for (char in commonCharacters)
        {
            try
            {
                if (Paths.imageExists(char))
                {
                    getSparrowAtlasWithCache(char);
                }
            }
            catch (e:Dynamic)
            {
                trace('[CachedPaths] Error preloading character $char: $e');
            }
        }

        trace('[CachedPaths] Preloading completed');
    }

    /**
     * Clear cache for a specific key
     * @param key Cache key to remove
     */
    public static function clearCache(key:String):Bool
    {
        return SpriteSheetCache.removeCache(key);
    }

    /**
     * Get cache statistics for monitoring performance
     * @return Formatted cache statistics string
     */
    public static function getCacheStatsString():String
    {
        var stats = SpriteSheetCache.getStats();
        var sizeKB = Math.round(stats.totalSize / 1024 * 100) / 100;
        var maxSizeKB = Math.round(stats.maxSize / 1024 * 100) / 100;
        var hitRatioPercent = Math.round(stats.hitRatio * 10000) / 100;

        return 'Cache Stats: ${stats.entriesCount} entries, ${sizeKB}KB / ${maxSizeKB}KB used, ${hitRatioPercent}% hit ratio';
    }

    /**
     * Initialize the caching system with engine startup
     */
    public static function init():Void
    {
        SpriteSheetCache.init();

        // Configure based on ClientPrefs if available
        if (ClientPrefs.data != null)
        {
            // Enable caching only if graphics preloading is enabled
            SpriteSheetCache.cacheEnabled = ClientPrefs.data.graphicsPreload2 != false;

            // Adjust cache size based on settings
            if (ClientPrefs.data.cacheOnGPU)
            {
                SpriteSheetCache.maxCacheSize = 200 * 1024 * 1024; // 200MB for GPU caching
            }
            else
            {
                SpriteSheetCache.maxCacheSize = 100 * 1024 * 1024; // 100MB for CPU caching
            }
        }

        trace('[CachedPaths] Initialized with caching ' + (SpriteSheetCache.cacheEnabled ? 'enabled' : 'disabled'));
    }
}
