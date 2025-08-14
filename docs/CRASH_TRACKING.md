# Crash Tracking System

This comprehensive crash tracking system automatically monitors engine activity and helps diagnose unexpected crashes, hangs, and exceptions. It uses Haxe macros for automatic code instrumentation and provides detailed logging and crash reports.

⚠️ **WARNING**: This system instruments methods to track engine activity. It may affect performance and should be used primarily for debugging. Inline functions are automatically ignored to prevent compilation issues. While a lot of the performance hit has been resolved, a planned update to have full access to current engine activity may impact it.

## Key Features

### Unexpected Crash Detection
- Creates a lock file (`engine_running.lock`) when the engine starts
- Removes the lock file on normal exit through `ExitState`
- Detects if engine crashed unexpectedly in previous sessions
- Shows warning message and generates crash report when unexpected crash detected

### Automatic Code Instrumentation
- Uses Haxe macros to automatically inject monitoring code into classes
- Handles static vs instance methods correctly
- Avoids accessing `this` in static functions
- Preserves original function return types
- Ignores inline functions with warnings
- Better exception handling and re-throwing

### Comprehensive Monitoring
- **Real-time Activity Logging**: Tracks method entry/exit, exceptions, and custom events
- **Memory Usage Tracking**: Monitors memory usage patterns
- **State Transition Logging**: Tracks navigation between game states
- **Heartbeat Monitoring**: Detects engine hangs and freezes
- **Exception Tracking**: Detailed exception reports with stack traces

## Setup

### 1. Automatic Instrumentation (Recommended)

Add the crash tracker macro to classes you want to monitor:

```haxe
@:autoBuild(yutautil.CrashTracker.instrument())
class YourClass extends SomeBaseClass {
    // Your class code here
    // All public methods will be automatically instrumented
}
```

### 2. MusicBeatState Integration

Already applied to `MusicBeatState.hx`:

```haxe
@:autoBuild(yutautil.StatePick.addToDatabase(MusicBeatState))
@:autoBuild(yutautil.CrashTracker.instrument())
class MusicBeatState extends FlxState
```

This means all states extending MusicBeatState are automatically tracked.

### 3. Main Application Setup

Already integrated into `Main.hx` constructor:

```haxe
public function new() {
    super();
    
    // Initialize crash tracking system early
    #if !debug
    yutautil.CrashTrackerHelper.initialize();
    yutautil.CrashTrackerHelper.logCriticalActivity("Main", "new", "Application starting up");
    #end
}
```

### 4. ExitState Integration

```haxe
private function performCleanup():Void {
    // Clean up crash tracking (remove lock file for normal exit)
    yutautil.CrashReporter.cleanupOnExit();
    
    // ... rest of cleanup code
}
```

## Enhanced Macro Instrumentation

### Static vs Instance Method Handling

```haxe
// Instance method - includes crash tracking initialization
public function instanceMethod():String {
    this._initCrashTracking();
    CrashReporter.logActivity("ClassName", "instanceMethod", "enter");
    // ... original code with proper return handling
}

// Static method - no 'this' access
public static function staticMethod():String {
    CrashReporter.logActivity("ClassName", "staticMethod", "enter");
    // ... original code with proper return handling
}
```

### Return Type Preservation

The enhanced system preserves exact return types:
- Functions returning `Void` work correctly
- Functions with complex return types maintain their signatures
- Generic functions keep their type parameters

### Inline Function Handling

```haxe
public inline function inlineFunction():Void {
    // This function will be skipped during instrumentation
    // A warning will be displayed during compilation
}
```

## Files and Components

### Core Components

1. **`CrashTracker.hx`** - Enhanced macro system for automatic instrumentation
2. **`CrashReporter.hx`** - Runtime monitoring and logging with crash detection
3. **`CrashTrackerHelper.hx`** - Utility functions and API

### Generated Files

All logs and reports are saved to the `logger/` folder:

- **`engine_activity_YYYY-MM-DD_HH-MM-SS.log`** - Continuous activity logs
- **`exception_YYYY-MM-DD_HH-MM-S.json`** - Detailed exception reports
- **`crash_YYYY-MM-DD_HH-MM-SS.json`** - Comprehensive crash analysis
- **`unexpected_crash_YYYY-MM-DD_HH-MM-SS.json`** - Reports for detected unexpected crashes
- **`engine_running.lock`** - Lock file indicating engine is running (deleted on normal exit)

## How Unexpected Crash Detection Works

1. **Engine Startup**: Creates `logger/engine_running.lock` with session info
2. **Normal Exit**: `ExitState` calls `CrashReporter.cleanupOnExit()` to remove lock file
3. **Next Startup**: Checks for existing lock file
4. **If Lock File Exists**: 
   - Engine didn't exit cleanly last time
   - Shows warning message in console
   - Generates `unexpected_crash_*.json` report
   - Removes old lock file

## Manual Logging

For critical code sections not automatically instrumented:

```haxe
// Log critical activities
CrashTrackerHelper.logCriticalActivity("PlayState", "loadSong", "Loading: " + songName);

// Create checkpoints
CrashTrackerHelper.checkpoint("SongStart", "Song: " + songName + ", Difficulty: " + difficulty);

// Log state transitions
CrashTrackerHelper.logStateTransition("MainMenuState", "PlayState");

// Log asset loading
CrashTrackerHelper.logAssetLoad("texture", "path/to/texture.png", success);

// Log memory usage
CrashTrackerHelper.logMemoryUsage("afterSongLoad");
```

## Output Examples

### Console Messages on Unexpected Crash

```
=================================
UNEXPECTED CRASH DETECTED!
The engine did not exit cleanly in the previous session.
Previous session started at: 2025-08-12 14:25:00
Check the logger folder for crash reports and activity logs.
=================================
```

### Activity Logs (`engine_activity_YYYY-MM-DD_HH-MM-SS.log`)
```
# Engine Activity Log - Generated by CrashReporter
# Format: [TIMESTAMP] CLASS.METHOD: ACTION (STACK)

[14:23:45.123] Main.new: CRITICAL: Application starting up (Main.hx:205)
[14:23:45.234] TitleState.create: enter (TitleState.hx:45)
[14:23:45.345] TitleState.setupBackground: enter (TitleState.hx:89)
[14:32:15.126] Player.move: exception: Null object reference (Player.hx:120)
```

### Exception Reports (`exception_YYYY-MM-DD_HH-MM-SS.json`)
```json
{
  "className": "PlayState",
  "method": "loadSong",
  "exception": "File not found: song.json",
  "stackTrace": [
    "PlayState.loadSong at PlayState.hx:234",
    "PlayState.create at PlayState.hx:123"
  ],
  "timestamp": "2025-08-12T14:23:45.000Z",
  "recentActivity": [...]
}
```

### Crash Reports (`crash_YYYY-MM-DD_HH-MM-SS.json`)
```json
{
  "reason": "Engine hang detected - 35.2s without activity",
  "timestamp": "2025-08-12T14:24:20.000Z",
  "lastHeartbeat": 1692021850.123,
  "timeSinceHeartbeat": 35.2,
  "recentActivity": [...],
  "registeredInstances": {
    "states.PlayState": 1,
    "objects.Character": 4
  },
  "stackTrace": [...],
  "systemInfo": {
    "platform": "Windows",
    "haxeVersion": "4.3.0",
    "flixelVersion": "5.2.0",
    "currentState": "states.PlayState",
    "gameTime": 123456
  }
}
```

### Unexpected Crash Report

```json
{
  "reason": "Unexpected crash detected from previous session",
  "timestamp": "2025-08-12T14:30:00.000Z",
  "previousSession": {
    "pid": "12345",
    "startTime": "2025-08-12T14:25:00.000Z",
    "version": "Mixtape Engine Rework"
  },
  "detectedAt": "Engine startup",
  "lockFileExists": true
}
```

## Configuration

### Crash Detection Settings

```haxe
// Enable/disable crash detection
CrashTrackerHelper.toggleCrashDetection(true);
CrashReporter.setCrashDetectionEnabled(false);

// Set heartbeat monitoring interval (default: 1 second)
CrashReporter.setHeartbeatInterval(0.5);

// Set maximum log buffer size (default: 1000 entries)
// This is handled internally, larger buffers use more memory
```

### Conditional Compilation

The system includes conditional compilation flags:

```haxe
#if !debug
// Only enable in release builds to avoid debug overhead
CrashTrackerHelper.initialize();
#end
```

## Testing

Test the crash tracking system:

```haxe
// Generate test reports and log files
CrashTrackerHelper.testCrashReporting();

// Manually trigger a crash report
CrashTrackerHelper.reportCrash("User requested crash report");

// View recent activity
trace(CrashTrackerHelper.getActivitySummary(10));

// Check buffer size
var size = CrashReporter.getLogBufferSize();

// Manual cleanup (use carefully)
CrashReporter.clearLogBuffer();
```

### Test State Access

1. Open Debug Menu
2. Press **T** for Crash Tracker Test State
3. Use number keys 1-6 to test different features
4. Check `logger/` folder for generated reports

## Best Practices

### 1. Instrument Critical Classes
Add the macro to classes that handle:
- State management
- Asset loading
- Game logic
- User input
- Network operations

### 2. Use Checkpoints Strategically
```haxe
// At the start of complex operations
CrashTrackerHelper.checkpoint("SongLoadStart", songData);

// After major operations complete
CrashTrackerHelper.checkpoint("SongLoadComplete", "Success");

// Before risky operations
CrashTrackerHelper.checkpoint("BeforeShaderCompile", shaderCode);
```

### 3. Log Asset Operations
```haxe
// Before loading
CrashTrackerHelper.logAssetLoad("song", songPath, false);

try {
    loadSong(songPath);
    // After successful loading
    CrashTrackerHelper.logAssetLoad("song", songPath, true);
} catch (e:Dynamic) {
    CrashTrackerHelper.logAssetLoad("song", songPath, false);
    throw e;
}
```

### 4. Monitor Memory Usage
```haxe
// After loading large assets
CrashTrackerHelper.logMemoryUsage("postCharacterLoad");

// Before and after garbage collection
CrashTrackerHelper.logMemoryUsage("preGC");
// ... perform GC ...
CrashTrackerHelper.logMemoryUsage("postGC");
```

### 5. Clean Exits
Always exit through proper game exit mechanisms to ensure proper cleanup.

## Performance Considerations

- **Debug Builds**: The system is disabled in debug builds by default to avoid overhead
- **Buffer Management**: Log buffer is automatically trimmed to prevent memory bloat
- **File I/O**: Logs are flushed periodically, not on every operation
- **Selective Instrumentation**: Only public methods are instrumented by default
- **Instrumentation Overhead**: Small performance cost per method call
- **Inline Functions**: Automatically skipped to avoid compilation issues
- **Static/Instance**: Proper handling prevents runtime errors

## Troubleshooting

### Common Issues

1. **Logs not appearing**: Check that crash tracking is initialized early in Main.hx
2. **Permission errors**: Ensure the application can write to the logger directory
3. **Performance impact**: Consider reducing heartbeat frequency or disabling in debug builds
4. **"Cannot access 'this' in static function"**: Fixed automatically in enhanced version
5. **Inline function compilation errors**: Functions are now skipped with warnings
6. **Return type mismatches**: Enhanced system preserves original return types
7. **Missing crash detection**: Ensure `ExitState` cleanup is called on normal exit

### Debug Commands

```haxe
// Test the system
CrashTrackerHelper.testCrashReporting();

// Get recent activity
var activity = CrashTrackerHelper.getActivitySummary(20);

// Manual crash report
CrashTrackerHelper.reportCrash("Manual test");
```

### Analyzing Crash Reports

1. **Check recentActivity**: Shows what the engine was doing just before the crash
2. **Review stackTrace**: Identifies the exact location where problems occurred
3. **Monitor registeredInstances**: Helps identify memory leaks or instance proliferation
4. **Check systemInfo**: Provides context about the runtime environment

The crash tracking system provides comprehensive monitoring with minimal performance impact, making it easier to diagnose and fix unexpected crashes in the engine.
