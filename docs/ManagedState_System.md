# ManagedState System Documentation

## Overview

The `ManagedState` class is a comprehensive memory management system designed to extend `FlxState` and provide automatic asset tracking and cleanup capabilities. It's intended to serve as the base class for `MusicBeatState` to provide engine-wide memory management.

## Features

### 🔍 Automatic Asset Tracking
- **Object Lifecycle Monitoring**: Automatically tracks all objects added via `add()`, `insert()`, or removed via `remove()`
- **Deep Asset Inspection**: Recursively inspects objects to find:
  - `FlxGraphic` objects and their associated `BitmapData`
  - `FlxSound` and native `Sound` objects
  - Nested group members and their assets
  - Custom bitmaps and graphics in object fields
- **Reflective Discovery**: Uses reflection to find assets in object properties

### 🧹 Comprehensive Cleanup
- **Individual Object Cleanup**: Properly disposes graphics, bitmaps, and sounds when objects are removed
- **Recursive Group Cleanup**: Traverses `FlxGroup` hierarchies to clean up all nested objects
- **Asset Registry Management**: Maintains global registries to prevent memory leaks
- **Safe Disposal**: Handles errors gracefully during cleanup operations

### ⚡ EndOfLife System
- **Aggressive Cleanup**: `EndOfLife()` method provides immediate, comprehensive cleanup
- **Global State Clearing**: Stops all tweens, timers, and clears all tracked objects
- **Force Cleanup**: Can be called at any time to immediately free all resources
- **Emergency Memory Recovery**: Triggers garbage collection when available

### 📊 Memory Management Statistics
- **Real-time Tracking**: Monitor objects and assets being managed
- **Debug Information**: Detailed statistics about memory usage
- **Performance Monitoring**: Track cleanup efficiency and resource usage

## Usage

### Basic Usage

```haxe
// Extend ManagedState instead of FlxState
class MyGameState extends ManagedState {
    override public function create():Void {
        super.create();

        // Add objects normally - they'll be automatically tracked
        var sprite = new FlxSprite(100, 100);
        sprite.makeGraphic(64, 64, FlxColor.WHITE);
        add(sprite); // Automatically tracked

        var text = new FlxText(0, 0, 200, "Hello World");
        add(text); // Also tracked with font assets
    }
}
```

### Manual Cleanup

```haxe
// Force cleanup of specific objects
forceCleanupObject(someSprite);

// Get memory statistics
var stats = getMemoryStats();
trace('Tracking ${stats.currentObjectsTracked} objects');

// Enable/disable tracking
setTrackingEnabled(false); // Temporarily disable tracking
```

### Emergency Cleanup

```haxe
// Aggressive cleanup when needed (e.g., memory pressure, state transitions)
EndOfLife(); // Cleans up everything immediately
```

### Debug Information

```haxe
// Print comprehensive debug information
printDebugInfo();

// Expected output:
// === ManagedState Debug Info ===
// Total Objects Tracked: 25
// Current Objects Tracked: 20
// Total Assets Managed: 45
// Current Graphics: 15
// Current Sounds: 3
// Current Bitmaps: 12
// Tracking Enabled: true
// Is Destroying: false
// End Of Life Triggered: false
// ==============================
```

## Architecture

### Core Components

1. **Asset Tracking System**
   - `trackedObjects`: Array of all tracked `FlxBasic` objects
   - `assetMap`: Maps objects to their associated assets
   - `graphicsRegistry`, `soundRegistry`, `bitmapRegistry`: Global asset registries

2. **AssetInfo Class**
   - Containers for different asset types per object
   - Tracks `FlxGraphic`, `BitmapData`, `FlxSound`, and native `Sound` objects
   - Provides asset counting and clearing functionality

3. **Cleanup Utilities**
   - `cleanupObjectAssets()`: Clean assets for specific objects
   - `cleanupGraphic()`, `cleanupBitmap()`, `cleanupFlxSound()`: Type-specific cleanup
   - `performCompleteCleanup()`: Full state cleanup
   - `cleanupGlobalRegistries()`: Clean up global asset registries

### Memory Management Flow

1. **Object Addition**
   ```
   add(object) → trackObject() → inspectObjectAssets() → Register in assetMap
   ```

2. **Object Removal**
   ```
   remove(object) → untrackObject() → cleanupObjectAssets() → Remove from registries
   ```

3. **State Destruction**
   ```
   destroy() → performCompleteCleanup() → Clean all objects → Clear registries
   ```

4. **EndOfLife**
   ```
   EndOfLife() → Stop tweens/timers → performCompleteCleanup() → Force GC
   ```

## Performance Considerations

### Tracking Overhead
- Minimal performance impact during normal operation
- Reflection-based asset discovery only occurs during object addition
- Registry operations use efficient array/map structures

### Memory Benefits
- Prevents memory leaks from undisposed graphics and sounds
- Reduces GC pressure through proper asset lifecycle management
- Immediate cleanup prevents accumulation of unused resources

### Optimization Features
- **Tracking Toggle**: Can disable tracking for performance-critical sections
- **Lazy Cleanup**: Only cleans up assets when objects are actually removed
- **Error Resilience**: Continues cleanup even if individual operations fail

## Integration with MusicBeatState

The `ManagedState` is designed to be the base class for `MusicBeatState`:

```haxe
// Proposed integration
class MusicBeatState extends ManagedState {
    // Existing MusicBeatState functionality
    // + Automatic memory management from ManagedState
}
```

This provides:
- Automatic memory management for all FNF states
- Consistent cleanup behavior across the engine
- Emergency cleanup capabilities for crash recovery
- Performance monitoring for memory usage

## Testing

Use `ManagedStateTest` to verify functionality:

```haxe
// Run the test
ManagedStateTestRunner.runTest();

// Test controls:
// SPACE - Print debug information
// E - Test EndOfLife functionality
// ESCAPE - Exit test
```

The test creates various object types, demonstrates tracking, and verifies cleanup functionality.

## Best Practices

### When to Use EndOfLife
- State transitions with memory pressure
- Error recovery scenarios
- Testing cleanup behavior
- Before switching to memory-intensive states

### Tracking Management
- Keep tracking enabled for normal gameplay
- Disable temporarily for bulk object operations
- Re-enable after bulk operations complete

### Error Handling
- All cleanup operations are wrapped in try-catch blocks
- Cleanup continues even if individual operations fail
- Monitor debug output for cleanup issues

### Performance Monitoring
- Use `getMemoryStats()` to monitor resource usage
- Call `printDebugInfo()` during development to understand memory patterns
- Consider `EndOfLife()` if asset counts grow unexpectedly

## Compatibility

- **FlxState Compatibility**: Full drop-in replacement for `FlxState`
- **Existing Code**: No changes required to existing object management code
- **Group Support**: Recursive tracking through `FlxGroup` hierarchies
- **Asset Types**: Supports all common Flixel asset types plus custom assets

This system provides a robust foundation for memory management throughout the Mixtape Engine, ensuring consistent cleanup behavior and preventing memory leaks across all game states.
