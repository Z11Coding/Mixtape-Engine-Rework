package examples;

import objects.Note;
import objects.NotePool;

/**
 * Example usage of the NotePool class
 */
class NotePoolExample
{
	private var notePool:NotePool;
	private var activeNotes:Array<Note>;
	
	public function new()
	{
		// Create a new note pool
		notePool = new NotePool();
		activeNotes = [];
		
		// Example usage
		demonstrateNotePool();
	}
	
	private function demonstrateNotePool():Void
	{
		trace("=== Note Pool Demo ===");
		
		// Get initial stats
		var stats = notePool.getStats();
		trace("Initial pool stats: " + stats);
		
		// Create some notes using the pool
		var note1 = notePool.getNote(1000, 0); // Regular note at time 1000, lane 0
		var note2 = notePool.getNote(2000, 1); // Regular note at time 2000, lane 1
		var note3 = notePool.getNote(3000, 2, note2, true); // Sustain note at time 3000, lane 2
		
		activeNotes.push(note1);
		activeNotes.push(note2);
		activeNotes.push(note3);
		
		trace("Created 3 notes");
		trace("Active notes: " + notePool.getActiveCount());
		trace("Pooled notes: " + notePool.getPooledCount());
		
		// Return notes to pool when done
		notePool.returnNote(note1);
		notePool.returnNote(note2);
		notePool.returnNote(note3);
		
		activeNotes = [];
		
		trace("Returned notes to pool");
		trace("Active notes: " + notePool.getActiveCount());
		trace("Pooled notes: " + notePool.getPooledCount());
		
		// Create more notes to demonstrate reuse
		var note4 = notePool.getNote(4000, 0); // This should reuse note1
		var note5 = notePool.getNote(5000, 1); // This should reuse note2
		
		trace("Created 2 more notes (reused from pool)");
		var finalStats = notePool.getStats();
		trace("Final pool stats: " + finalStats);
		trace("Pool efficiency: " + finalStats.efficiency + "%");
		
		// Clean up
		notePool.returnNote(note4);
		notePool.returnNote(note5);
		notePool.destroy();
	}
	
	/**
	 * Example of integrating with a game loop
	 */
	public function gameLoopExample():Void
	{
		// In your game's update loop, you might do something like:
		
		// Spawn notes for the current time
		var currentTime = Conductor.songPosition;
		var notesToSpawn = getNotesForTime(currentTime);
		
		for (noteData in notesToSpawn)
		{
			var note = notePool.getNote(noteData.strumTime, noteData.noteData);
			activeNotes.push(note);
			// Add to your game's note group/field
		}
		
		// Remove notes that are no longer needed
		var notesToRemove = [];
		for (note in activeNotes)
		{
			if (note.tooLate || note.wasGoodHit)
			{
				notesToRemove.push(note);
			}
		}
		
		for (note in notesToRemove)
		{
			activeNotes.remove(note);
			notePool.returnNote(note);
			// Remove from your game's note group/field
		}
	}
	
	/**
	 * Mock function to simulate getting notes for a specific time
	 */
	private function getNotesForTime(time:Float):Array<{strumTime:Float, noteData:Int}>
	{
		// In a real implementation, this would check your chart data
		return []; // Return empty array for this example
	}
}
