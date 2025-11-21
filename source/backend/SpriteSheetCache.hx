package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#end

#if (target.threaded)
import sys.thread.Mutex;
import sys.thread.Thread;
#end

/**
 * Advanced SpriteSheet Cache System for Mixtape Engine
 * Supports caching of partial or full spritesheets in .mixc format (JSON-based)
 * Optimized for efficient loading and memory management
 */
class SpriteSheetCache
{
    // Cache storage maps
    private static var cacheMap:Map<String, CachedSpriteSheet> = new Map<String, CachedSpriteSheet>();

    // Configuration settings
    public static var cacheEnabled:Bool = true;
    public static var maxCacheSize:Int = 100 * 1024 * 1024; // 100MB default
    public static var compressionLevel:Int = 6; // 0-9, higher = more compression
    public static var autoCleanup:Bool = true;

    // Statistics
    public static var totalCachedSize:Int = 0;
    public static var cacheHits:Int = 0;
    public static var cacheMisses:Int = 0;

    // Background validation system
    #if (target.threaded)
    private static var validationMutex:Mutex = new Mutex();
    private static var cacheMutex:Mutex = new Mutex();
    private static var validationQueue:Array<String> = [];
    private static var validationThreadRunning:Bool = false;
    #end

    /**
     * Initialize the cache system
     */
    public static function init():Void
    {
        if (!cacheEnabled) return;

        trace('[SpriteSheetCache] Initializing cache system...');
        trace('[SpriteSheetCache] Cache files will be stored alongside original assets');

        // Load existing cache metadata
        loadCacheMetadata();
    }

    /**
     * Cache a spritesheet with its frames and metadata
     * @param key Unique identifier for the cached spritesheet (should be the asset path)
     * @param graphic FlxGraphic containing the spritesheet texture
     * @param frames FlxFramesCollection containing frame data
     * @return Success status
     */
    public static function cacheSpriteSheet(key:String, graphic:FlxGraphic, frames:FlxFramesCollection):Bool
    {
        if (!cacheEnabled || graphic == null || frames == null) return false;

        try
        {
            // Get original asset modification time
            var assetPath = Paths.getPath('images/$key.png', IMAGE);
            var lastModified:Float = 0;
            try
            {
                if (FileSystem.exists(assetPath))
                {
                    var stat = FileSystem.stat(assetPath);
                    lastModified = stat.mtime.getTime();
                }
            }
            catch (e:Dynamic)
            {
                trace('[SpriteSheetCache] Could not get modification time for $assetPath: $e');
                lastModified = Date.now().getTime();
            }

            var cacheData:CachedSpriteSheet = {
                key: key,
                timestamp: Date.now().getTime(),
                lastModified: lastModified,
                compression: compressionLevel,
                texture: {
                    width: graphic.bitmap.width,
                    height: graphic.bitmap.height,
                    data: encodeBitmapData(graphic.bitmap)
                },
                frames: []
            };

            // Cache all frames
            for (i in 0...frames.numFrames)
            {
                var frame = frames.getByIndex(i);
                if (frame != null)
                {
                    cacheData.frames.push(encodeFrame(frame));
                }
            }

            // Calculate size and check limits
            var estimatedSize = estimateDataSize(cacheData);
            if (totalCachedSize + estimatedSize > maxCacheSize)
            {
                if (autoCleanup)
                {
                    performCleanup(estimatedSize);
                }
                else
                {
                    trace('[SpriteSheetCache] Cache size limit exceeded for: $key');
                    return false;
                }
            }

            // Store in memory cache with thread safety
            #if (target.threaded)
            cacheMutex.acquire();
            try
            {
                cacheMap.set(key, cacheData);
                totalCachedSize += estimatedSize;
            }
            finally
            {
                cacheMutex.release();
            }
            #else
            cacheMap.set(key, cacheData);
            totalCachedSize += estimatedSize;
            #end

            // Save to disk
            saveCacheFile(key, cacheData);

            trace('[SpriteSheetCache] Cached spritesheet: $key (${estimatedSize} bytes)');
            return true;
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error caching spritesheet $key: $e');
            return false;
        }
    }



    /**
     * Load cached spritesheet and convert back to FlxFramesCollection
     * @param key Unique identifier for the cached spritesheet
     * @return FlxFramesCollection or null if not found
     */
    public static function loadCachedSpriteSheet(key:String):Null<FlxFramesCollection>
    {
        if (!cacheEnabled) return null;

        var cacheData = getCacheData(key);
        if (cacheData == null)
        {
            cacheMisses++;
            return null;
        }

        cacheHits++;

        try
        {
            // Reconstruct spritesheet
            if (cacheData.texture != null)
            {
                var bitmap = decodeBitmapData(cacheData.texture.data, cacheData.texture.width, cacheData.texture.height);
                var graphic = FlxGraphic.fromBitmapData(bitmap, false, key + '_cached');
                graphic.persist = true;
                graphic.destroyOnNoUse = false;

                // Create frames collection
                var frames = new FlxFramesCollection(graphic);
                for (frameData in cacheData.frames)
                {
                    var frame = new FlxFrame(graphic);
                    frame.name = frameData.name;
                    frame.sourceSize.set(frameData.sourceWidth, frameData.sourceHeight);
                    frame.offset.set(frameData.offsetX, frameData.offsetY);
                    frame.frame = new flixel.math.FlxRect(frameData.x, frameData.y, frameData.width, frameData.height);
                    frames.pushFrame(frame);
                }

                trace('[SpriteSheetCache] Loaded cached spritesheet: $key');

                #if (target.threaded)
                // Queue background validation to check if cache is up to date
                queueValidation(key);
                #end

                return frames;
            }

            return null;
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error loading cached spritesheet $key: $e');
            return null;
        }
    }



    /**
     * Check if a spritesheet is cached
     * @param key Unique identifier
     * @return True if cached
     */
    public static function isCached(key:String):Bool
    {
        if (!cacheEnabled) return false;

        #if (target.threaded)
        cacheMutex.acquire();
        var inMemory:Bool = false;
        try
        {
            inMemory = cacheMap.exists(key);
        }
        finally
        {
            cacheMutex.release();
        }

        return inMemory || FileSystem.exists(getCacheFilePath(key));
        #else
        return cacheMap.exists(key) || FileSystem.exists(getCacheFilePath(key));
        #end
    }

    /**
     * Remove a specific cache entry
     * @param key Unique identifier
     * @return Success status
     */
    public static function removeCache(key:String):Bool
    {
        if (!cacheEnabled) return false;

        try
        {
            // Remove from memory with thread safety
            #if (target.threaded)
            cacheMutex.acquire();
            try
            {
                if (cacheMap.exists(key))
                {
                    var cacheData = cacheMap.get(key);
                    totalCachedSize -= estimateDataSize(cacheData);
                    cacheMap.remove(key);
                }
            }
            finally
            {
                cacheMutex.release();
            }
            #else
            if (cacheMap.exists(key))
            {
                var cacheData = cacheMap.get(key);
                totalCachedSize -= estimateDataSize(cacheData);
                cacheMap.remove(key);
            }
            #end



            // Remove cache file
            var filePath = getCacheFilePath(key);
            if (FileSystem.exists(filePath))
            {
                FileSystem.deleteFile(filePath);
            }

            trace('[SpriteSheetCache] Removed cache: $key');
            return true;
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error removing cache $key: $e');
            return false;
        }
    }

    /**
     * Clear all cached data
     */
    public static function clearAll():Void
    {
        if (!cacheEnabled) return;

        try
        {
            // Clear memory caches with thread safety
            #if (target.threaded)
            cacheMutex.acquire();
            try
            {
                for (key in cacheMap.keys())
                {
                    cacheMap.remove(key);
                }
                totalCachedSize = 0;
            }
            finally
            {
                cacheMutex.release();
            }
            #else
            for (key in cacheMap.keys())
            {
                cacheMap.remove(key);
            }
            totalCachedSize = 0;
            #end

            // Remove all cache files by scanning asset directories
            var assetDirs = [
                'assets/shared/images',
                'assets/base_game/images',
                'assets/week_assets',
                'example_mods'
            ];

            for (dir in assetDirs)
            {
                if (FileSystem.exists(dir))
                {
                    clearCacheFilesInDirectory(dir);
                }
            }
            trace('[SpriteSheetCache] Cleared all cache data');
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error clearing cache: $e');
        }
    }

    /**
     * Get cache statistics
     * @return Cache statistics object
     */
    public static function getStats():CacheStats
    {
        #if (target.threaded)
        cacheMutex.acquire();
        var stats:CacheStats;
        try
        {
            stats = {
                totalSize: totalCachedSize,
                maxSize: maxCacheSize,
                cacheHits: cacheHits,
                cacheMisses: cacheMisses,
                hitRatio: cacheHits > 0 ? cacheHits / (cacheHits + cacheMisses) : 0.0,
                entriesCount: cacheMap.size()
            };
        }
        finally
        {
            cacheMutex.release();
        }
        return stats;
        #else
        return {
            totalSize: totalCachedSize,
            maxSize: maxCacheSize,
            cacheHits: cacheHits,
            cacheMisses: cacheMisses,
            hitRatio: cacheHits > 0 ? cacheHits / (cacheHits + cacheMisses) : 0.0,
            entriesCount: cacheMap.size()
        };
        #end
    }

    /**
     * Recalculate total cache size by scanning for .mixc files
     * Since cache files are co-located with assets, this helps maintain accurate size tracking
     */
    public static function recalculateCacheSize():Void
    {
        if (!cacheEnabled) return;

        totalCachedSize = 0;
        var scannedCount = 0;

        // Scan common asset directories for .mixc files
        var assetDirs = [
            'assets/shared/images',
            'assets/base_game/images',
            'assets/week_assets',
            'example_mods'
        ];

        for (dir in assetDirs)
        {
            if (FileSystem.exists(dir))
            {
                scannedCount += scanDirectoryForCache(dir);
            }
        }

        trace('[SpriteSheetCache] Recalculated cache size: ${totalCachedSize} bytes from ${scannedCount} files');
    }

    private static function scanDirectoryForCache(dir:String):Int
    {
        var count = 0;
        try
        {
            for (item in FileSystem.readDirectory(dir))
            {
                var fullPath = dir + '/' + item;
                if (FileSystem.isDirectory(fullPath))
                {
                    count += scanDirectoryForCache(fullPath);
                }
                else if (item.endsWith('.mixc'))
                {
                    var stat = FileSystem.stat(fullPath);
                    totalCachedSize += stat.size;
                    count++;
                }
            }
        }
        catch (e:Dynamic)
        {
            // Ignore directory scan errors
        }
        return count;
    }

    private static function clearCacheFilesInDirectory(dir:String):Void
    {
        try
        {
            for (item in FileSystem.readDirectory(dir))
            {
                var fullPath = dir + '/' + item;
                if (FileSystem.isDirectory(fullPath))
                {
                    clearCacheFilesInDirectory(fullPath);
                }
                else if (item.endsWith('.mixc'))
                {
                    FileSystem.deleteFile(fullPath);
                }
            }
        }
        catch (e:Dynamic)
        {
            // Ignore directory scan errors
        }
    }

    /**
     * Optimize cache by removing least recently used items
     * @param targetSize Target size to free up
     */
    public static function performCleanup(?targetSize:Int):Void
    {
        if (!cacheEnabled) return;

        if (targetSize == null)
            targetSize = Std.int(maxCacheSize * 0.3); // Free 30% by default

        trace('[SpriteSheetCache] Performing cache cleanup, target: ${targetSize} bytes');

        // Sort by timestamp (oldest first) with thread safety
        var entries:Array<{key:String, timestamp:Float, size:Int}> = [];

        #if (target.threaded)
        cacheMutex.acquire();
        try
        {
            for (key in cacheMap.keys())
            {
                var data = cacheMap.get(key);
                entries.push({
                    key: key,
                    timestamp: data.timestamp,
                    size: estimateDataSize(data)
                });
            }
        }
        finally
        {
            cacheMutex.release();
        }
        #else
        for (key in cacheMap.keys())
        {
            var data = cacheMap.get(key);
            entries.push({
                key: key,
                timestamp: data.timestamp,
                size: estimateDataSize(data)
            });
        }
        #end

        entries.sort((a, b) -> Std.int(a.timestamp - b.timestamp));

        var freedSize = 0;
        for (entry in entries)
        {
            if (freedSize >= targetSize) break;

            removeCache(entry.key);
            freedSize += entry.size;
        }

        // Force garbage collection
        #if cpp
        Gc.run(true);
        #elseif hl
        Gc.major();
        #end

        trace('[SpriteSheetCache] Cleanup completed, freed: ${freedSize} bytes');
    }

    // --- PRIVATE HELPER METHODS ---

    private static function getCacheFilePath(key:String):String
    {
        // Get the original asset path and replace extension with .mixc
        var assetPath = Paths.getPath('images/$key.png', IMAGE);

        // Replace .png with .mixc to create cache file alongside original
        if (assetPath.endsWith('.png'))
        {
            return assetPath.substring(0, assetPath.length - 4) + '.mixc';
        }

        // Fallback: add .mixc extension
        return assetPath + '.mixc';
    }

    private static function sanitizeFileName(name:String):String
    {
        // Replace invalid filename characters
        var sanitized = name;
        sanitized = StringTools.replace(sanitized, '<', '_');
        sanitized = StringTools.replace(sanitized, '>', '_');
        sanitized = StringTools.replace(sanitized, ':', '_');
        sanitized = StringTools.replace(sanitized, '"', '_');
        sanitized = StringTools.replace(sanitized, '/', '_');
        sanitized = StringTools.replace(sanitized, '\\', '_');
        sanitized = StringTools.replace(sanitized, '|', '_');
        sanitized = StringTools.replace(sanitized, '?', '_');
        sanitized = StringTools.replace(sanitized, '*', '_');
        return sanitized;
    }

    private static function getCacheData(key:String):Null<CachedSpriteSheet>
    {
        #if (target.threaded)
        cacheMutex.acquire();
        #end

        try
        {
            // Check memory cache first
            if (cacheMap.exists(key))
            {
                var data = cacheMap.get(key);
                #if (target.threaded)
                cacheMutex.release();
                #end
                return data;
            }

            #if (target.threaded)
            cacheMutex.release();
            #end

            // Try to load from disk
            var filePath = getCacheFilePath(key);
            if (FileSystem.exists(filePath))
            {
                try
                {
                    var content = File.getContent(filePath);
                    var cacheData:CachedSpriteSheet = Json.parse(content);

                    #if (target.threaded)
                    cacheMutex.acquire();
                    #end

                    try
                    {
                        // Store in memory for faster access
                        cacheMap.set(key, cacheData);
                        totalCachedSize += estimateDataSize(cacheData);
                    }
                    finally
                    {
                        #if (target.threaded)
                        cacheMutex.release();
                        #end
                    }

                    return cacheData;
                }
                catch (e:Dynamic)
                {
                    trace('[SpriteSheetCache] Error loading cache file $filePath: $e');
                    // Remove corrupted file
                    try
                    {
                        FileSystem.deleteFile(filePath);
                    }
                    catch (e2:Dynamic) {}
                }
            }

            return null;
        }
        catch (e:Dynamic)
        {
            #if (target.threaded)
            cacheMutex.release();
            #end
            throw e;
        }
    }

    private static function saveCacheFile(key:String, data:CachedSpriteSheet):Void
    {
        try
        {
            var filePath = getCacheFilePath(key);
            var content = Json.stringify(data, null, compressionLevel > 0 ? null : '  ');
            File.saveContent(filePath, content);
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error saving cache file for $key: $e');
        }
    }

    private static function loadCacheMetadata():Void
    {
        // Since cache files are now co-located with assets, scan for existing .mixc files
        totalCachedSize = 0;
        trace('[SpriteSheetCache] Scanning for existing cache files...');
        recalculateCacheSize();
    }

    private static function encodeBitmapData(bitmap:BitmapData):String
    {
        try
        {
            var bytes = bitmap.encode(bitmap.rect, new openfl.display.PNGEncoderOptions());
            return Base64.encode(bytes);
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error encoding bitmap: $e');
            return '';
        }
    }

    private static function decodeBitmapData(data:String, width:Int, height:Int):BitmapData
    {
        try
        {
            var bytes = Base64.decode(data);
            return BitmapData.fromBytes(bytes);
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error decoding bitmap: $e');
            // Return fallback bitmap
            return new BitmapData(width, height, true, 0x00000000);
        }
    }



    private static function encodeFrame(frame:FlxFrame):CachedFrame
    {
        return {
            name: frame.name != null ? frame.name : 'frame_${frame.frame.x}_${frame.frame.y}',
            x: frame.frame.x,
            y: frame.frame.y,
            width: frame.frame.width,
            height: frame.frame.height,
            sourceWidth: frame.sourceSize.x,
            sourceHeight: frame.sourceSize.y,
            offsetX: frame.offset.x,
            offsetY: frame.offset.y
        };
    }

    private static function estimateDataSize(data:CachedSpriteSheet):Int
    {
        var size = 1000; // Base overhead

        if (data.texture != null)
        {
            // Estimate texture size (Base64 encoded PNG is roughly 1.3x original)
            size += Std.int((data.texture.width * data.texture.height * 4) * 1.3);
        }

        // Frame metadata overhead
        size += data.frames.length * 200;

        return size;
    }

    #if (target.threaded)
    /**
     * Queue cache validation for background processing
     * @param key Cache key to validate
     */
    private static function queueValidation(key:String):Void
    {
        validationMutex.acquire();
        try
        {
            if (validationQueue.indexOf(key) == -1)
            {
                validationQueue.push(key);
            }

            // Start validation thread if not running
            if (!validationThreadRunning)
            {
                validationThreadRunning = true;
                Thread.create(validationThreadLoop);
            }
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error queuing validation: $e');
        }
        finally
        {
            validationMutex.release();
        }
    }

    /**
     * Background thread loop for cache validation
     */
    private static function validationThreadLoop():Void
    {
        while (true)
        {
            var key:String = null;

            // Get next key to validate
            validationMutex.acquire();
            try
            {
                if (validationQueue.length > 0)
                {
                    key = validationQueue.shift();
                }
                else
                {
                    validationThreadRunning = false;
                    validationMutex.release();
                    break;
                }
            }
            catch (e:Dynamic)
            {
                validationMutex.release();
                break;
            }
            finally
            {
                if (key == null)
                {
                    validationMutex.release();
                }
            }

            if (key != null)
            {
                validationMutex.release();
                validateCacheInBackground(key);
            }
        }
    }

    /**
     * Validate a single cache entry against its original asset
     * @param key Cache key to validate
     */
    private static function validateCacheInBackground(key:String):Void
    {
        try
        {
            // Get original asset path
            var assetPath = Paths.getPath('images/$key.png', IMAGE);
            if (!FileSystem.exists(assetPath))
            {
                return; // Original asset doesn't exist, cache is still valid
            }

            // Get cache data
            var cacheData = getCacheData(key);
            if (cacheData == null)
            {
                return; // No cache data found
            }

            // Check modification times
            var assetStat = FileSystem.stat(assetPath);
            var assetModTime = assetStat.mtime.getTime();

            if (assetModTime > cacheData.lastModified)
            {
                trace('[SpriteSheetCache] Cache outdated for $key, scheduling refresh');

                // Cache is outdated, reload and update
                var graphic = FlxGraphic.fromBitmapData(Assets.getBitmapData(assetPath), false, key);
                if (graphic != null)
                {
                    var frames:FlxFramesCollection = null;

                    // Try to determine frame type and load accordingly
                    var xmlPath = assetPath.substring(0, assetPath.length - 4) + '.xml';
                    var txtPath = assetPath.substring(0, assetPath.length - 4) + '.txt';

                    if (FileSystem.exists(xmlPath))
                    {
                        frames = FlxAtlasFrames.fromSparrow(graphic, xmlPath);
                    }
                    else if (FileSystem.exists(txtPath))
                    {
                        frames = FlxAtlasFrames.fromSpriteSheetPacker(graphic, txtPath);
                    }

                    if (frames != null)
                    {
                        // Update cache with new data
                        cacheSpriteSheet(key, graphic, frames);
                        trace('[SpriteSheetCache] Updated outdated cache for $key');
                    }
                }
            }
        }
        catch (e:Dynamic)
        {
            trace('[SpriteSheetCache] Error validating cache for $key: $e');
        }
    }
    #end
}

// --- TYPE DEFINITIONS ---

typedef CachedSpriteSheet = {
    var key:String;
    var timestamp:Float;
    var lastModified:Float; // Original asset modification time
    var compression:Int;
    var texture:CachedTexture;
    var frames:Array<CachedFrame>;
}

typedef CachedTexture = {
    var width:Float;
    var height:Float;
    var data:String; // Base64 encoded PNG
}

typedef CachedFrame = {
    var name:String;
    var x:Float;
    var y:Float;
    var width:Float;
    var height:Float;
    var sourceWidth:Float;
    var sourceHeight:Float;
    var offsetX:Float;
    var offsetY:Float;
}

typedef CacheStats = {
    var totalSize:Int;
    var maxSize:Int;
    var cacheHits:Int;
    var cacheMisses:Int;
    var hitRatio:Float;
    var entriesCount:Int;
}
