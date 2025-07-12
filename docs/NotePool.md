# NotePool Documentation

## Overview

The `NotePool` class is a high-performance object pooling system designed specifically for managing `Note` objects in the Mixtape Engine. Instead of constantly creating and destroying note objects (which can cause memory allocation overhead and garbage collection spikes), the pool maintains a cache of pre-created notes that can be reused.

## Benefits

- **Performance**: Reduces memory allocations and garbage collection overhead
- **Consistency**: Eliminates frame rate drops caused by frequent object creation/destruction
- **Memory Efficiency**: Reuses existing objects instead of creating new ones
- **Statistics**: Provides detailed metrics about pool usage and efficiency

## Basic Usage

### 1. Create a Note Pool

```haxe
var notePool = new NotePool();
```

### 2. Get Notes from the Pool

```haxe
// Get a regular note
var note = notePool.getNote(strumTime, noteData);

// Get a sustain note
var sustainNote = notePool.getNote(strumTime, noteData, prevNote, true);

// Get a note for the editor
var editorNote = notePool.getNote(strumTime, noteData, null, false, true);
```

### 3. Return Notes to the Pool

```haxe
// Return a single note
notePool.returnNote(note);

// Return multiple notes
notePool.returnNotes([note1, note2, note3]);

// Clear all active notes
notePool.clearActiveNotes();
```

## Configuration

### Pool Size Settings

```haxe
// Adjust maximum pool size (default: 200)
NotePool.MAX_POOL_SIZE = 300;

// Adjust minimum pool size (default: 50)
NotePool.MIN_POOL_SIZE = 100;
```

### Enable/Disable Pool

```haxe
// Disable the pool (falls back to normal note creation)
notePool.setEnabled(false);

// Re-enable the pool
notePool.setEnabled(true);
```

## Integration Examples

### PlayState Integration

```haxe
class PlayState extends MusicBeatState
{
    private var notePool:NotePool;
    private var activeNotes:Array<Note>;
    
    override public function create():Void
    {
        super.create();
        
        // Initialize note pool
        notePool = new NotePool();
        activeNotes = [];
    }
    
    private function spawnNote(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false):Note
    {
        // Use pool instead of creating new note
        var note = notePool.getNote(strumTime, noteData, prevNote, sustainNote);
        activeNotes.push(note);
        notesGroup.add(note);
        return note;
    }
    
    private function removeNote(note:Note):Void
    {
        activeNotes.remove(note);
        notesGroup.remove(note);
        notePool.returnNote(note); // Return to pool instead of destroying
    }
    
    override public function destroy():Void
    {
        if (notePool != null)
        {
            notePool.destroy();
            notePool = null;
        }
        super.destroy();
    }
}
```

### Chart Editor Integration

```haxe
class ChartingState extends MusicBeatState
{
    private var notePool:NotePool;
    
    override public function create():Void
    {
        super.create();
        notePool = new NotePool();
    }
    
    private function createChartNote(strumTime:Float, noteData:Int):Note
    {
        // Create note for editor
        var note = notePool.getNote(strumTime, noteData, null, false, true);
        return note;
    }
    
    private function deleteChartNote(note:Note):Void
    {
        // Return to pool instead of destroying
        notePool.returnNote(note);
    }
}
```

## Performance Monitoring

### Get Pool Statistics

```haxe
var stats = notePool.getStats();
trace("Total created: " + stats.totalCreated);
trace("Total reused: " + stats.totalReused);
trace("Active notes: " + stats.activeNotes);
trace("Pool efficiency: " + stats.efficiency + "%");
```

### Monitor Pool Usage

```haxe
// Check active note count
var activeCount = notePool.getActiveCount();

// Check pooled note count
var pooledCount = notePool.getPooledCount();

// Monitor efficiency
var efficiency = (stats.totalReused / (stats.totalCreated + stats.totalReused)) * 100;
```

## Best Practices

### 1. Always Return Notes

```haxe
// ✅ Good
var note = notePool.getNote(strumTime, noteData);
// ... use note ...
notePool.returnNote(note);

// ❌ Bad - creates memory leak
var note = notePool.getNote(strumTime, noteData);
// ... use note ...
// Never returned to pool
```

### 2. Clear Pool When Changing Songs

```haxe
override public function switchSong():Void
{
    notePool.clearActiveNotes();
    super.switchSong();
}
```

### 3. Handle Sustain Notes Properly

```haxe
// Create sustain chain
var headNote = notePool.getNote(strumTime, noteData);
var sustainNote = notePool.getNote(strumTime + 100, noteData, headNote, true);
var tailNote = notePool.getNote(strumTime + 200, noteData, sustainNote, true);

// Return in reverse order
notePool.returnNote(tailNote);
notePool.returnNote(sustainNote);
notePool.returnNote(headNote);
```

### 4. Monitor Pool Efficiency

```haxe
#if debug
var stats = notePool.getStats();
if (stats.efficiency < 50) {
    trace("Warning: Pool efficiency is low (" + stats.efficiency + "%)");
}
#end
```

## Troubleshooting

### Common Issues

1. **Memory Leaks**: Make sure to always return notes to the pool
2. **Performance Issues**: Check if pool sizes are appropriate for your use case
3. **Sustain Note Problems**: Ensure sustain notes are properly linked and returned

### Debug Mode

```haxe
#if debug
// Enable detailed logging
notePool.enabled = true;
var stats = notePool.getStats();
trace("Pool stats: " + stats);
#end
```

## Technical Details

### Pool Implementation

The `NotePool` uses two separate pools:
- **Regular Notes**: For tap notes and note heads
- **Sustain Notes**: For sustain tails and holds

### Memory Management

- Notes are reset to default values when returned to pool
- Automatic cleanup of references to prevent memory leaks
- Configurable pool sizes to balance memory usage vs. performance

### Thread Safety

The pool is designed for single-threaded use. Do not access from multiple threads simultaneously.

## API Reference

### Constructor
- `new NotePool()`: Creates a new note pool with default settings

### Methods
- `getNote(strumTime, noteData, prevNote?, sustainNote?, inEditor?, createdFrom?)`: Get a note from the pool
- `returnNote(note)`: Return a note to the pool
- `returnNotes(notes)`: Return multiple notes to the pool
- `createNotesFromTemplates(templates, inEditor?, createdFrom?)`: Create notes from templates
- `createNoteFromTemplate(template, prevNote?, inEditor?, createdFrom?)`: Create a single note from template
- `prePopulateFromTemplates(templates)`: Pre-populate pool with templated notes
- `clearActiveNotes()`: Clear all active notes and return them to the pool
- `getStats()`: Get pool statistics
- `getExtendedStats()`: Get extended pool statistics with utilization info
- `setEnabled(enabled)`: Enable or disable the pool
- `getActiveCount()`: Get number of active notes
- `getPooledCount()`: Get number of pooled notes
- `destroy()`: Clean up the pool

### NoteTemplate Methods
- `new NoteTemplate(strumTime, noteData, sustainNote?, noteType?, mustPress?)`: Create a new template
- `setCustomData(key, value)`: Set custom data for the template
- `setEventData(eventName, val1?, val2?)`: Set event data for the template
- `applyToNote(note)`: Apply template properties to a note
- `clone()`: Create a copy of the template

### AbstractNoteArray Methods
- `new AbstractNoteArray(notes?)`: Create a new note array
- `add(template)`: Add a template to the array
- `addAll(templates)`: Add multiple templates to the array
- `remove(template)`: Remove a template from the array
- `clear()`: Clear all templates from the array
- `getNext()`: Get and remove the next template
- `peekNext()`: Look at the next template without removing it
- `getByType(noteType)`: Get all templates of a specific type
- `getByTimeRange(startTime, endTime)`: Get templates within a time range
- `sortByTime()`: Sort templates by strum time
- `createNotes(pool, inEditor?, createdFrom?)`: Create actual notes from templates
- `isEmpty()`: Check if the array is empty
- `get(index)`: Get template at index
- `set(index, template)`: Set template at index

## Advanced Features

### NoteTemplate System

The `NoteTemplate` class allows you to create reusable note configurations that can be applied to notes from the pool:

```haxe
// Create a template for a hurt note
var hurtTemplate = new NoteTemplate(1000, 0, false, "Hurt Note", true)
    .setCustomData('hitCausesMiss', true)
    .setCustomData('lowPriority', true);

// Create a note from the template
var hurtNote = notePool.createNoteFromTemplate(hurtTemplate);
```

### AbstractNoteArray

The `AbstractNoteArray` provides a powerful way to work with collections of note templates:

```haxe
// Create an array of note templates
var templates:AbstractNoteArray = new AbstractNoteArray();

// Add templates
templates.add(new NoteTemplate(0, 0, false, null, true));
templates.add(new NoteTemplate(500, 1, false, null, true));
templates.add(new NoteTemplate(1000, 2, false, null, true));

// Convert existing notes to templates
var existingNotes:Array<Note> = [note1, note2, note3];
var convertedTemplates:AbstractNoteArray = existingNotes;

// Create notes from templates
var createdNotes = notePool.createNotesFromTemplates(templates);
```

### Template Features

#### Custom Data
```haxe
var template = new NoteTemplate(1000, 0, false, "Mine Note", true)
    .setCustomData('isMine', true)
    .setCustomData('specialNote', true)
    .setCustomData('ignoreMiss', true);
```

#### Event Data
```haxe
var eventTemplate = new NoteTemplate(2000, 1, false, null, true)
    .setEventData('Camera Focus', 'dad', '');
```

#### Template Filtering
```haxe
// Get templates by type
var hurtNotes = templates.getByType("Hurt Note");

// Get templates in time range
var earlyNotes = templates.getByTimeRange(0, 2000);

// Sort by time
templates.sortByTime();
```

### Pattern Creation

Create complex note patterns using templates:

```haxe
// Arpeggio pattern
var arpeggio = createArpeggiPattern(startTime, 16);

// Sustain chain
var sustain = createSustainChain(startTime, noteData, 2000);

// Chord
var chord = createChord(startTime, [0, 1, 2, 3]);
```
