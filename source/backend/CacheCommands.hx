package backend;

import backend.CachedPaths;
import backend.SpriteSheetCache;

/**
 * Command prompt extensions for managing and testing the SpriteSheet Cache System
 * These commands can be used through Main.CommandPrompt for debugging and testing
 */
class CacheCommands
{
    /**
     * Register cache-related commands with the command prompt system
     */
    public static function registerCommands():Void
    {
        // This would integrate with Main.CommandPrompt if it exists
        trace('[CacheCommands] Cache commands are available for integration');
    }

    /**
     * Initialize cache system
     * Command: initCache
     */
    public static function initCache():String
    {
        try
        {
            CachedPaths.init();
            return 'Cache system initialized successfully';
        }
        catch (e:Dynamic)
        {
            return 'Error initializing cache: $e';
        }
    }

    /**
     * Get cache statistics
     * Command: cacheStats
     */
    public static function cacheStats():String
    {
        try
        {
            return CachedPaths.getCacheStatsString();
        }
        catch (e:Dynamic)
        {
            return 'Error getting cache stats: $e';
        }
    }

    /**
     * Enable or disable caching
     * Command: setCacheEnabled <true|false>
     */
    public static function setCacheEnabled(enabled:String):String
    {
        try
        {
            var enable = enabled.toLowerCase() == 'true';
            SpriteSheetCache.cacheEnabled = enable;
            return 'Cache ${enable ? "enabled" : "disabled"}';
        }
        catch (e:Dynamic)
        {
            return 'Error setting cache enabled: $e';
        }
    }

    /**
     * Set cache size limit
     * Command: setCacheSize <sizeInMB>
     */
    public static function setCacheSize(sizeMB:String):String
    {
        try
        {
            var size = Std.parseInt(sizeMB);
            if (size == null || size <= 0)
            {
                return 'Invalid size. Use a positive number for MB.';
            }

            SpriteSheetCache.maxCacheSize = size * 1024 * 1024;
            return 'Cache size limit set to ${size}MB';
        }
        catch (e:Dynamic)
        {
            return 'Error setting cache size: $e';
        }
    }

    /**
     * Check if a specific item is cached
     * Command: isCached <key>
     */
    public static function isCached(key:String):String
    {
        try
        {
            var cached = SpriteSheetCache.isCached(key);
            return 'Item "$key" is ${cached ? "cached" : "not cached"}';
        }
        catch (e:Dynamic)
        {
            return 'Error checking cache for "$key": $e';
        }
    }

    /**
     * Remove specific cache entry
     * Command: removeCache <key>
     */
    public static function removeCache(key:String):String
    {
        try
        {
            var success = SpriteSheetCache.removeCache(key);
            return success ? 'Cache entry "$key" removed' : 'Failed to remove cache entry "$key"';
        }
        catch (e:Dynamic)
        {
            return 'Error removing cache entry "$key": $e';
        }
    }

    /**
     * Clear all cache
     * Command: clearCache
     */
    public static function clearCache():String
    {
        try
        {
            SpriteSheetCache.clearAll();
            return 'All cache cleared';
        }
        catch (e:Dynamic)
        {
            return 'Error clearing cache: $e';
        }
    }

    /**
     * Force cache cleanup
     * Command: cleanupCache [targetSizeMB]
     */
    public static function cleanupCache(?targetSizeMB:String):String
    {
        try
        {
            var targetSize:Null<Int> = null;
            if (targetSizeMB != null)
            {
                var size = Std.parseInt(targetSizeMB);
                if (size != null && size > 0)
                {
                    targetSize = size * 1024 * 1024;
                }
            }

            SpriteSheetCache.performCleanup(targetSize);
            return 'Cache cleanup completed';
        }
        catch (e:Dynamic)
        {
            return 'Error during cache cleanup: $e';
        }
    }

    /**
     * Recalculate total cache size by scanning for .mixc files
     * Command: recalculateCache
     */
    public static function recalculateCache():String
    {
        try
        {
            var oldSize = SpriteSheetCache.getStats().totalSize;
            SpriteSheetCache.recalculateCacheSize();
            var newSize = SpriteSheetCache.getStats().totalSize;

            return 'Cache size recalculated: ${Math.round(oldSize / 1024 * 100) / 100}KB -> ${Math.round(newSize / 1024 * 100) / 100}KB';
        }
        catch (e:Dynamic)
        {
            return 'Error recalculating cache size: $e';
        }
    }

    /**
     * Test cache with boyfriend character
     * Command: testCacheBF
     */
    public static function testCacheBF():String
    {
        try
        {
            var atlas = CachedPaths.getSparrowAtlasWithCache('characters/bf');
            if (atlas != null)
            {
                return 'Successfully loaded/cached BF atlas with ${atlas.numFrames} frames';
            }
            else
            {
                return 'Failed to load BF atlas (file may not exist)';
            }
        }
        catch (e:Dynamic)
        {
            return 'Error testing BF cache: $e';
        }
    }

    /**
     * Preload common spritesheets
     * Command: preloadCommon
     */
    public static function preloadCommon():String
    {
        try
        {
            CachedPaths.preloadCommonSpritesheets();
            return 'Common spritesheets preloaded';
        }
        catch (e:Dynamic)
        {
            return 'Error preloading common spritesheets: $e';
        }
    }



    /**
     * Get detailed cache information
     * Command: cacheInfo
     */
    public static function cacheInfo():String
    {
        try
        {
            var stats = SpriteSheetCache.getStats();
            var info = [
                'Cache System Information:',
                '  Enabled: ${SpriteSheetCache.cacheEnabled}',
                '  Entries: ${stats.entriesCount}',
                '  Size: ${Math.round(stats.totalSize / 1024 * 100) / 100}KB / ${Math.round(stats.maxSize / 1024 / 1024 * 100) / 100}MB',
                '  Usage: ${Math.round(stats.totalSize / stats.maxSize * 10000) / 100}%',
                '  Hit Ratio: ${Math.round(stats.hitRatio * 10000) / 100}%',
                '  Cache Hits: ${stats.cacheHits}',
                '  Cache Misses: ${stats.cacheMisses}',
                '  Compression Level: ${SpriteSheetCache.compressionLevel}',
                '  Auto Cleanup: ${SpriteSheetCache.autoCleanup}'
            ];

            return info.join('\n');
        }
        catch (e:Dynamic)
        {
            return 'Error getting cache info: $e';
        }
    }

    /**
     * Set compression level
     * Command: setCacheCompression <0-9>
     */
    public static function setCacheCompression(level:String):String
    {
        try
        {
            var compressionLevel = Std.parseInt(level);
            if (compressionLevel == null || compressionLevel < 0 || compressionLevel > 9)
            {
                return 'Invalid compression level. Use 0-9 (0=no compression, 9=max compression)';
            }

            SpriteSheetCache.compressionLevel = compressionLevel;
            return 'Compression level set to $compressionLevel';
        }
        catch (e:Dynamic)
        {
            return 'Error setting compression level: $e';
        }
    }

    /**
     * Toggle auto cleanup
     * Command: toggleAutoCleanup
     */
    public static function toggleAutoCleanup():String
    {
        try
        {
            SpriteSheetCache.autoCleanup = !SpriteSheetCache.autoCleanup;
            return 'Auto cleanup ${SpriteSheetCache.autoCleanup ? "enabled" : "disabled"}';
        }
        catch (e:Dynamic)
        {
            return 'Error toggling auto cleanup: $e';
        }
    }

    /**
     * Get help for cache commands
     * Command: cacheHelp
     */
    public static function cacheHelp():String
    {
        var help = [
            'SpriteSheet Cache Commands:',
            '',
            'Basic Commands:',
            '  initCache                    - Initialize cache system',
            '  cacheStats                   - Show cache statistics',
            '  cacheInfo                    - Show detailed cache information',
            '  cacheHelp                    - Show this help',
            '',
            'Configuration:',
            '  setCacheEnabled <true|false> - Enable/disable caching',
            '  setCacheSize <MB>            - Set cache size limit in MB',
            '  setCacheCompression <0-9>    - Set compression level',
            '  toggleAutoCleanup            - Toggle automatic cleanup',
            '',
            'Cache Management:',
            '  isCached <key>               - Check if item is cached',
            '  removeCache <key>            - Remove specific cache entry',
            '  clearCache                   - Clear all cache',
            '  cleanupCache [MB]            - Force cache cleanup',
            '  recalculateCache             - Recalculate total cache size',
            '',
            'Testing:',
            '  testCacheBF                  - Test caching with BF character',
            '  preloadCommon                - Preload common spritesheets',
            '',
            'Examples:',
            '  setCacheSize 200             - Set cache limit to 200MB',
            '  isCached characters_bf       - Check if BF is cached'
        ];

        return help.join('\n');
    }
}
