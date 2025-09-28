# Experimental NotePool System

## Overview

The experimental NotePool system is an optimization feature that reuses Note objects instead of constantly creating and destroying them during gameplay. This can significantly reduce memory allocation and garbage collection, leading to better performance especially during intense songs with many notes.

## How it Works

### Traditional System
- Creates a new `Note` object every time a note needs to spawn
- Destroys the `Note` object when the note is removed
- Causes frequent memory allocation and garbage collection

### NotePool System
- Pre-creates a pool of `Note` objects at the start
- When a note is needed, it takes one from the pool and reinitializes it
- When a note is removed, it returns to the pool for reuse
- Significantly reduces memory allocation and GC pressure

## Implementation Details

### Key Components

1. **`NotePoolManager`** - Global singleton that manages the note pool
2. **`NotePool`** - The actual pool implementation with separate pools for regular and sustain notes
3. **Modified note creation** - All `new Note()` calls are conditionally replaced with pool usage

### Settings Integration

- **Setting Location**: Mixtape Settings → Experimental → "Use Experimental Note Pool"
- **Client Preference**: `ClientPrefs.data.useExperimentalNotePool`
- **Default**: Disabled (false) for safety

### Pool Configuration

- **Maximum Pool Size**: 200 notes (hard limit to prevent runaway memory usage)
- **Optimal Pool Size**: 72 notes (target for normal operation)
- **Minimum Pool Size**: 50 notes (always maintained for instant availability)
- **Dynamic Sizing**: Pool adjusts based on demand and performance settings
- **Low-Quality Adjustment**: 70% of normal pool size for low-end devices
- **Separate Pools**: Regular notes and sustain notes have independent pools

### Intelligent Pool Management

The system now features intelligent pool management that:

- **Demand Tracking**: Monitors peak simultaneous note usage
- **Dynamic Resizing**: Adjusts pool target size based on actual demand
- **Excess Cleanup**: Automatically destroys notes when pools exceed optimal size
- **Aggressive Cleanup**: Forces cleanup when exiting PlayState
- **Memory Pressure Detection**: Warns when total note count exceeds healthy limits

#### Pool Sizing Logic
- Target size = max(MIN_POOL_SIZE, min(OPTIMAL_POOL_SIZE, peak_demand * 1.2))
- Low-quality devices get 70% of calculated size
- Excess notes beyond target are destroyed rather than pooled
- Cleanup happens periodically (10% chance per note return) and on state exit

## Modified Files

### Core Implementation
- `source/managers/NotePoolManager.hx` - Global pool manager
- `source/objects/NotePool.hx` - Extended with additional pool functionality
- `source/backend/ClientPrefs.hx` - Added experimental setting
- `source/options/MixtapeSettingsSubState.hx` - Added UI setting

### PlayState Integration
- `source/states/PlayState.hx` - Modified note creation/destruction
- `source/archipelago/APPlayState.hx` - Modified Archipelago note creation
- `source/mechanics/MechanicsPlaystate.hx` - Modified mechanics note creation

### Debug Support
- `source/debug/commands/NotePoolStatsCommand.hx` - Statistics and debugging

## Usage

### Enabling the System

1. Go to **Options** → **Mixtape Settings**
2. Scroll to the **Experimental** section
3. Enable **"Use Experimental Note Pool"**
4. Restart the game or start a new song

### Performance Benefits

**Expected improvements:**
- Reduced memory allocation during gameplay
- Less frequent garbage collection pauses
- Smoother gameplay during note-heavy sections
- Better performance on lower-end devices

**When most effective:**
- Songs with many notes (e.g., high BPM songs)
- Long songs that would normally accumulate memory pressure
- Devices with limited memory or slower CPUs

## Debugging and Monitoring

### Statistics Available
- Total notes created vs. reused
- Pool efficiency percentage
- Active notes count
- Pooled notes available
- Separate tracking for sustain notes

### Debug Commands
```haxe
NotePoolStatsCommand.showStats();  // Display current statistics
NotePoolStatsCommand.resetPool();  // Reset pool and show stats
```

## Safety and Fallback

### Automatic Fallback
- If `useExperimentalNotePool` is disabled, uses traditional note creation
- No performance penalty when disabled
- Seamless switching between modes

### Error Handling
- Pool failures fall back to standard note creation
- Comprehensive note reset between uses
- Cleanup on state transitions

## Implementation Notes

### Note Reset Process
When a note is returned to the pool, it undergoes comprehensive reset:
- All gameplay properties reset to defaults
- Visual properties (position, scale, alpha) reset
- Relationships (parent/child notes) cleared
- Archipelago-specific properties reset
- Event and animation data cleared

### Memory Management
- Pool automatically manages capacity
- Excess notes are destroyed when pool is full
- Minimum pool maintained for immediate reuse
- Complete cleanup on PlayState destruction

## Performance Monitoring

### Advanced Statistics
The pool now tracks comprehensive metrics:
- **Efficiency**: Percentage of notes reused vs created
- **Pool Utilization**: How well the pool size matches demand
- **Demand Tracking**: Current and peak simultaneous note usage
- **Memory Pressure**: Warning when total notes exceed optimal levels
- **Target Pool Size**: Dynamically calculated optimal pool size

### Debug Commands
- `NotePoolStatsCommand.showStats()` - Display current statistics
- `NotePoolStatsCommand.resetPool()` - Reset entire pool system
- `NotePoolStatsCommand.forceCleanup()` - Force aggressive cleanup
- `NotePoolStatsCommand.resetDemand()` - Reset demand tracking

### Traces and Logging
When enabled, the system outputs:
```
Experimental NotePool system enabled
New peak demand: XX notes
Reusing note from pool. Pool size: XX, Demand: XX
Created new note. Active: XX
Pool full, destroying excess note. Pool size: XX
Cleaned up excess regular note. Pool size now: XX
Aggressive cleanup complete. Note pool: XX, Sustain pool: XX
```

### Statistics Structure
```haxe
{
    totalCreated: Int,      // Total notes created since start
    totalReused: Int,       // Total notes reused from pool
    efficiency: Float,      // Percentage of notes reused
    activeNotes: Int,       // Currently active regular notes
    activeSustains: Int,    // Currently active sustain notes
    pooledNotes: Int,       // Available regular notes in pool
    pooledSustains: Int     // Available sustain notes in pool
}
```

## Compatibility

### Supported Features
- ✅ All standard note types
- ✅ Sustain notes
- ✅ Note modifiers and effects
- ✅ Archipelago special notes
- ✅ Chart modifiers (UNO, etc.)
- ✅ Mechanics system notes
- ✅ Custom note types

### Limitations
- ⚠️ Experimental - may have undiscovered issues
- ⚠️ Not extensively tested with all mods
- ⚠️ Slight memory overhead from pool management

## Troubleshooting

### If Issues Occur
1. Disable the experimental setting
2. Restart the game
3. Report the issue with details about the song/mod that caused problems

### Performance Not Improved
- Check if using note-heavy songs
- Monitor with debug statistics
- Ensure system isn't falling back to standard creation

The experimental NotePool system represents a significant optimization for note-intensive gameplay while maintaining full compatibility with existing features.
