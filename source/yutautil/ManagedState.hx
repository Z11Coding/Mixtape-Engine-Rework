package yutautil;

import Reflect;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import haxe.ds.ObjectMap;
import haxe.ds.WeakMap;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;

/**
 * ManagedState - A comprehensive memory management state class that extends FlxState
 *
 * Features:
 * - Automatic tracking of all objects added to the state
 * - Deep asset inspection and cleanup for graphics, sounds, and other resources
 * - Recursive memory cleanup with proper disposal of bitmaps and assets
 * - EndOfLife function for aggressive cleanup when needed
 * - Override lifecycle methods to intercept all object management operations
 *
 * This class is designed to be the base class for MusicBeatState to provide
 * comprehensive memory management across the entire engine.
 */
class ManagedState extends FlxState {

    // Asset tracking structures
    private var trackedObjects:Array<FlxBasic> = [];
    private var assetMap:ObjectMap<FlxBasic, AssetInfo> = new ObjectMap();
    private var graphicsRegistry:Array<FlxGraphic> = [];
    private var soundRegistry:Array<FlxSound> = [];
    private var bitmapRegistry:Array<BitmapData> = [];
    private var tweenRegistry:Array<FlxTween> = [];
    private var timerRegistry:Array<FlxTimer> = [];

    // Memory management flags
    private var isDestroying:Bool = false;
    private var endOfLifeTriggered:Bool = false;
    private var trackingEnabled:Bool = true;
    private var aggressiveTracking:Bool = false; // Less aggressive by default

    // Statistics
    private var totalObjectsTracked:Int = 0;
    private var totalAssetsManaged:Int = 0;

    public function new() {
        super();
        trace("ManagedState: Initialized with comprehensive asset tracking");
    }

    // ========================================
    // OBJECT LIFECYCLE OVERRIDES
    // ========================================

    override public function add(object:FlxBasic):FlxBasic {
        var result = super.add(object);
        if (trackingEnabled && !isDestroying && result != null) {
            trackObject(result);
        }
        return result;
    }

    override public function insert(position:Int, object:FlxBasic):FlxBasic {
        var result = super.insert(position, object);
        if (trackingEnabled && !isDestroying && result != null) {
            trackObject(result);
        }
        return result;
    }

    override public function remove(object:FlxBasic, splice:Bool = false):FlxBasic {
        if (trackingEnabled && !isDestroying && object != null) {
            untrackObject(object);
        }
        return super.remove(object, splice);
    }

    override public function destroy():Void {
        if (!isDestroying) {
            isDestroying = true;
            trace("ManagedState: Starting comprehensive destruction process");
            performCompleteCleanup();
        }
        super.destroy();
    }

    // ========================================
    // ASSET TRACKING SYSTEM
    // ========================================

    /**
     * Track an object and all its associated assets
     */
    private function trackObject(object:FlxBasic):Void {
        if (object == null || trackedObjects.indexOf(object) != -1) return;

        // Special handling for recycled objects - don't track them aggressively
        if (isRecycledObject(object)) {
            return; // Don't track recycled objects to prevent interference
        }

        trackedObjects.push(object);
        totalObjectsTracked++;

        var assetInfo = new AssetInfo();
        assetMap.set(object, assetInfo);

        // Only do deep inspection if aggressive tracking is enabled
        if (aggressiveTracking) {
            inspectObjectAssets(object, assetInfo);
        } else {
            // Minimal inspection for basic tracking
            inspectObjectAssetsMinimal(object, assetInfo);
        }

        trace('ManagedState: Tracked object ${Type.getClassName(Type.getClass(object))} with ${assetInfo.getAssetCount()} assets');
    }

    /**
     * Remove object from tracking - be gentle with recycled objects
     */
    private function untrackObject(object:FlxBasic):Void {
        if (object == null) return;

        var index = trackedObjects.indexOf(object);
        if (index != -1) {
            trackedObjects.splice(index, 1);

            // Only clean up assets if this isn't a recycled object
            if (assetMap.exists(object) && !isRecycledObject(object)) {
                cleanupObjectAssets(object, assetMap.get(object));
                assetMap.remove(object);
            } else if (assetMap.exists(object)) {
                // Just remove from tracking without cleanup for recycled objects
                assetMap.remove(object);
            }
        }
    }

    /**
     * Check if an object is part of a recycling system
     */
    private function isRecycledObject(object:FlxBasic):Bool {
        if (object == null) return false;

        // Check if this object belongs to a group that uses recycling
        // This includes FlxSpriteGroup members and other recyclable objects
        try {
            var parent = Reflect.field(object, "parent");
            if (parent != null) {
                var parentClass = Type.getClassName(Type.getClass(parent));
                if (parentClass != null && (
                    parentClass.indexOf("SpriteGroup") != -1 ||
                    parentClass.indexOf("Alphabet") != -1 ||
                    parentClass.indexOf("AlphaCharacter") != -1
                )) {
                    return true;
                }
            }

            // Check if the object itself is a commonly recycled type
            var className = Type.getClassName(Type.getClass(object));
            if (className != null && (
                className.indexOf("AlphaCharacter") != -1 ||
                className.indexOf("Note") != -1 ||
                className.indexOf("StrumNote") != -1
            )) {
                return true;
            }
        } catch (e:Dynamic) {
            // Ignore reflection errors
        }

        return false;
    }

    /**
     * Minimal asset inspection to avoid interfering with recycling systems
     */
    private function inspectObjectAssetsMinimal(object:FlxBasic, assetInfo:AssetInfo):Void {
        if (object == null) return;

        try {
            // Only inspect direct sprite graphics, avoid deep inspection
            if (Std.isOfType(object, FlxSprite)) {
                var sprite:FlxSprite = cast object;
                if (sprite != null && sprite.graphic != null && sprite.graphic.bitmap != null) {
                    // Only track if this isn't a shared graphic
                    var isShared = graphicsRegistry.indexOf(sprite.graphic) != -1;
                    if (!isShared) {
                        assetInfo.graphics.push(sprite.graphic);
                        graphicsRegistry.push(sprite.graphic);
                    }
                }
            }
        } catch (e:Dynamic) {
            // Ignore any errors during minimal inspection
        }

        totalAssetsManaged += assetInfo.getAssetCount();
    }

    /**
     * Deep inspection of an object to find all associated assets
     */
    private function inspectObjectAssets(object:FlxBasic, assetInfo:AssetInfo):Void {
        if (object == null) return;

        // Be extra careful with asset inspection to avoid null pointer errors
        try {
            // Handle FlxSprite graphics
            if (Std.isOfType(object, FlxSprite)) {
                var sprite:FlxSprite = cast object;
                if (sprite != null && sprite.graphic != null) {
                    assetInfo.graphics.push(sprite.graphic);
                    if (graphicsRegistry.indexOf(sprite.graphic) == -1) {
                        graphicsRegistry.push(sprite.graphic);
                    }
                }

                // Check for cached bitmaps
                if (sprite != null && sprite.pixels != null) {
                    assetInfo.bitmaps.push(sprite.pixels);
                    if (bitmapRegistry.indexOf(sprite.pixels) == -1) {
                        bitmapRegistry.push(sprite.pixels);
                    }
                }
            }

            // Handle FlxText fonts and graphics
            if (Std.isOfType(object, FlxText)) {
                var text:FlxText = cast object;
                if (text != null && text.graphic != null) {
                    assetInfo.graphics.push(text.graphic);
                    if (graphicsRegistry.indexOf(text.graphic) == -1) {
                        graphicsRegistry.push(text.graphic);
                    }
                }
            }

            // Handle FlxSound
            if (Std.isOfType(object, FlxSound)) {
                var sound:FlxSound = cast object;
                if (sound != null) {
                    assetInfo.sounds.push(sound);
                    if (soundRegistry.indexOf(sound) == -1) {
                        soundRegistry.push(sound);
                    }
                }
            }

            // Handle FlxGroup recursively (but be careful with recycling groups)
            if (Std.isOfType(object, FlxGroup)) {
                var group:FlxGroup = cast object;
                if (group != null && group.members != null && !isRecycledObject(object)) {
                    for (member in group.members) {
                        if (member != null) {
                            inspectObjectAssets(member, assetInfo);
                        }
                    }
                }
            }

            // Use reflection to find any additional assets (safer version)
            inspectReflectiveAssets(object, assetInfo);

        } catch (e:Dynamic) {
            trace('ManagedState: Error during asset inspection: $e');
            // Don't re-throw, just continue
        }

        totalAssetsManaged += assetInfo.getAssetCount();
    }

    /**
     * Use reflection to inspect object fields for assets (safer version)
     */
    private function inspectReflectiveAssets(object:Dynamic, assetInfo:AssetInfo):Void {
        if (object == null || isRecycledObject(object)) return;

        try {
            var fields = Reflect.fields(object);
            if (fields == null) return;

            for (field in fields) {
                try {
                    var value = Reflect.field(object, field);
                    if (value == null) continue;

                    // Check for BitmapData
                    if (Std.isOfType(value, BitmapData)) {
                        var bitmap:BitmapData = cast value;
                        if (bitmap != null) {
                            assetInfo.bitmaps.push(bitmap);
                            if (bitmapRegistry.indexOf(bitmap) == -1) {
                                bitmapRegistry.push(bitmap);
                            }
                        }
                    }

                    // Check for FlxGraphic
                    if (Std.isOfType(value, FlxGraphic)) {
                        var graphic:FlxGraphic = cast value;
                        if (graphic != null) {
                            assetInfo.graphics.push(graphic);
                            if (graphicsRegistry.indexOf(graphic) == -1) {
                                graphicsRegistry.push(graphic);
                            }
                        }
                    }

                    // Check for Sound
                    if (Std.isOfType(value, Sound)) {
                        var sound:Sound = cast value;
                        if (sound != null) {
                            assetInfo.nativeSounds.push(sound);
                        }
                    }

                    // Check for Arrays that might contain assets (but be careful)
                    if (Std.isOfType(value, Array)) {
                        var array:Array<Dynamic> = cast value;
                        if (array != null && array.length < 100) { // Avoid huge arrays
                            for (item in array) {
                                if (item != null && Std.isOfType(item, FlxBasic) && !isRecycledObject(item)) {
                                    inspectObjectAssets(cast item, assetInfo);
                                }
                            }
                        }
                    }
                } catch (e:Dynamic) {
                    // Silently ignore reflection errors for private/protected fields
                    continue;
                }
            }
        } catch (e:Dynamic) {
            // Ignore reflection errors completely
        }
    }

    // ========================================
    // MEMORY CLEANUP UTILITIES
    // ========================================

    /**
     * Clean up all assets associated with a specific object
     */
    private function cleanupObjectAssets(object:FlxBasic, assetInfo:AssetInfo):Void {
        if (object == null || assetInfo == null) return;

        // Clean up graphics
        for (graphic in assetInfo.graphics) {
            cleanupGraphic(graphic);
        }

        // Clean up bitmaps
        for (bitmap in assetInfo.bitmaps) {
            cleanupBitmap(bitmap);
        }

        // Clean up sounds
        for (sound in assetInfo.sounds) {
            cleanupFlxSound(sound);
        }

        // Clean up native sounds
        for (sound in assetInfo.nativeSounds) {
            cleanupNativeSound(sound);
        }

        // Clear the asset info
        assetInfo.clear();
    }

    /**
     * Clean up a FlxGraphic and its associated bitmap
     */
    private function cleanupGraphic(graphic:FlxGraphic):Void {
        if (graphic == null) return;

        try {
            // Remove from graphics registry
            var index = graphicsRegistry.indexOf(graphic);
            if (index != -1) {
                graphicsRegistry.splice(index, 1);
            }

            // Clean up the bitmap
            if (graphic.bitmap != null) {
                cleanupBitmap(graphic.bitmap);
            }

            // Destroy the graphic
            graphic.destroy();
        } catch (e:Dynamic) {
            trace('ManagedState: Error cleaning up graphic: $e');
        }
    }

    /**
     * Clean up a BitmapData
     */
    private function cleanupBitmap(bitmap:BitmapData):Void {
        if (bitmap == null) return;

        try {
            // Remove from bitmap registry
            var index = bitmapRegistry.indexOf(bitmap);
            if (index != -1) {
                bitmapRegistry.splice(index, 1);
            }

            // Dispose the bitmap if it's not disposed already
            if (bitmap.width > 0 && bitmap.height > 0) {
                bitmap.dispose();
            }
        } catch (e:Dynamic) {
            trace('ManagedState: Error cleaning up bitmap: $e');
        }
    }

    /**
     * Clean up a FlxSound
     */
    private function cleanupFlxSound(sound:FlxSound):Void {
        if (sound == null) return;

        try {
            // Remove from sound registry
            var index = soundRegistry.indexOf(sound);
            if (index != -1) {
                soundRegistry.splice(index, 1);
            }

            // Stop and destroy the sound
            sound.stop();
            sound.destroy();
        } catch (e:Dynamic) {
            trace('ManagedState: Error cleaning up FlxSound: $e');
        }
    }

    /**
     * Clean up a native Sound object
     */
    private function cleanupNativeSound(sound:Sound):Void {
        if (sound == null) return;

        try {
            // Close the sound if possible
            if (Reflect.hasField(sound, 'close')) {
                Reflect.callMethod(sound, Reflect.field(sound, 'close'), []);
            }
        } catch (e:Dynamic) {
            trace('ManagedState: Error cleaning up native Sound: $e');
        }
    }

    // ========================================
    // COMPREHENSIVE CLEANUP METHODS
    // ========================================

    /**
     * Perform complete cleanup of all tracked objects and assets
     */
    private function performCompleteCleanup():Void {
        trace('ManagedState: Starting complete cleanup of ${trackedObjects.length} objects and ${totalAssetsManaged} assets');

        // Stop tracking new objects
        trackingEnabled = false;

        // Clean up all tracked objects
        for (object in trackedObjects.copy()) {
            if (object != null) {
                cleanupObjectCompletely(object);
            }
        }

        // Clean up any remaining global registries
        cleanupGlobalRegistries();

        // Clear all tracking structures
        clearTrackingStructures();

        trace('ManagedState: Complete cleanup finished');
    }

    /**
     * EndOfLife - Aggressive cleanup that can be called at any time
     * This method will forcefully clean up everything, even if the state is not being destroyed
     */
    public function EndOfLife():Void {
        if (endOfLifeTriggered) return;

        endOfLifeTriggered = true;
        trace('ManagedState: EndOfLife triggered - performing aggressive cleanup');

        // Stop all tweens
        FlxTween.globalManager.clear();

        // Stop all timers
        FlxTimer.globalManager.clear();

        // Perform complete cleanup
        performCompleteCleanup();

        // Clear members aggressively
        if (members != null) {
            for (member in members.copy()) {
                if (member != null) {
                    try {
                        remove(member);
                        if (Reflect.hasField(member, 'destroy')) {
                            member.destroy();
                        }
                    } catch (e:Dynamic) {
                        trace('ManagedState: Error during EndOfLife cleanup of member: $e');
                    }
                }
            }
            members.splice(0, members.length);
        }

        // Force garbage collection if available
        #if cpp
        try {
            yutautil.MemoryHelper.clearMemoryStored();
        } catch (e:Dynamic) {
            trace('ManagedState: Error during garbage collection: $e');
        }
        #end

        trace('ManagedState: EndOfLife cleanup completed');
    }

    /**
     * Clean up a single object completely
     */
    private function cleanupObjectCompletely(object:FlxBasic):Void {
        if (object == null) return;

        try {
            // Clean up associated assets
            if (assetMap.exists(object)) {
                cleanupObjectAssets(object, assetMap.get(object));
            }

            // Recursively clean up group members
            if (Std.isOfType(object, FlxGroup)) {
                var group:FlxGroup = cast object;
                for (member in group.members) {
                    if (member != null) {
                        cleanupObjectCompletely(member);
                    }
                }
            }

            // Remove from state if still present
            if (members.indexOf(object) != -1) {
                super.remove(object);
            }

            // Destroy the object
            object.destroy();

        } catch (e:Dynamic) {
            trace('ManagedState: Error during complete object cleanup: $e');
        }
    }

    /**
     * Clean up global registries
     */
    private function cleanupGlobalRegistries():Void {
        // Clean remaining graphics
        for (graphic in graphicsRegistry.copy()) {
            cleanupGraphic(graphic);
        }

        // Clean remaining sounds
        for (sound in soundRegistry.copy()) {
            cleanupFlxSound(sound);
        }

        // Clean remaining bitmaps
        for (bitmap in bitmapRegistry.copy()) {
            cleanupBitmap(bitmap);
        }
    }

    /**
     * Clear all tracking data structures
     */
    private function clearTrackingStructures():Void {
        trackedObjects = [];
        assetMap = new ObjectMap();
        graphicsRegistry = [];
        soundRegistry = [];
        bitmapRegistry = [];
        tweenRegistry = [];
        timerRegistry = [];

        totalObjectsTracked = 0;
        totalAssetsManaged = 0;
    }

    // ========================================
    // UTILITY AND DEBUG METHODS
    // ========================================

    /**
     * Get memory usage statistics
     */
    public function getMemoryStats():ManagedStateStats {
        return {
            totalObjectsTracked: totalObjectsTracked,
            currentObjectsTracked: trackedObjects.length,
            totalAssetsManaged: totalAssetsManaged,
            currentGraphics: graphicsRegistry.length,
            currentSounds: soundRegistry.length,
            currentBitmaps: bitmapRegistry.length,
            trackingEnabled: trackingEnabled,
            isDestroying: isDestroying,
            endOfLifeTriggered: endOfLifeTriggered
        };
    }

    /**
     * Enable or disable object tracking
     */
    public function setTrackingEnabled(enabled:Bool):Void {
        trackingEnabled = enabled;
        trace('ManagedState: Tracking ${enabled ? "enabled" : "disabled"}');
    }

    /**
     * Enable or disable aggressive asset tracking
     */
    public function setAggressiveTracking(enabled:Bool):Void {
        aggressiveTracking = enabled;
        trace('ManagedState: Aggressive tracking ${enabled ? "enabled" : "disabled"}');
    }

    /**
     * Temporarily disable tracking during sensitive operations like recycling
     */
    public function withTrackingDisabled<T>(func:Void->T):T {
        var wasEnabled = trackingEnabled;
        trackingEnabled = false;
        try {
            var result = func();
            trackingEnabled = wasEnabled;
            return result;
        } catch (e:Dynamic) {
            trackingEnabled = wasEnabled;
            throw e;
        }
    }

    /**
     * Force cleanup of a specific object
     */
    public function forceCleanupObject(object:FlxBasic):Void {
        if (object != null) {
            untrackObject(object);
            cleanupObjectCompletely(object);
        }
    }

    /**
     * Print debug information about tracked assets
     */
    public function printDebugInfo():Void {
        var stats = getMemoryStats();
        trace('=== ManagedState Debug Info ===');
        trace('Total Objects Tracked: ${stats.totalObjectsTracked}');
        trace('Current Objects Tracked: ${stats.currentObjectsTracked}');
        trace('Total Assets Managed: ${stats.totalAssetsManaged}');
        trace('Current Graphics: ${stats.currentGraphics}');
        trace('Current Sounds: ${stats.currentSounds}');
        trace('Current Bitmaps: ${stats.currentBitmaps}');
        trace('Tracking Enabled: ${stats.trackingEnabled}');
        trace('Is Destroying: ${stats.isDestroying}');
        trace('End Of Life Triggered: ${stats.endOfLifeTriggered}');
        trace('==============================');
    }
}

/**
 * Asset information container for tracked objects
 */
class AssetInfo {
    public var graphics:Array<FlxGraphic> = [];
    public var bitmaps:Array<BitmapData> = [];
    public var sounds:Array<FlxSound> = [];
    public var nativeSounds:Array<Sound> = [];

    public function new() {}

    public function getAssetCount():Int {
        return graphics.length + bitmaps.length + sounds.length + nativeSounds.length;
    }

    public function clear():Void {
        graphics = [];
        bitmaps = [];
        sounds = [];
        nativeSounds = [];
    }
}

/**
 * Statistics structure for ManagedState
 */
typedef ManagedStateStats = {
    totalObjectsTracked:Int,
    currentObjectsTracked:Int,
    totalAssetsManaged:Int,
    currentGraphics:Int,
    currentSounds:Int,
    currentBitmaps:Int,
    trackingEnabled:Bool,
    isDestroying:Bool,
    endOfLifeTriggered:Bool
}
