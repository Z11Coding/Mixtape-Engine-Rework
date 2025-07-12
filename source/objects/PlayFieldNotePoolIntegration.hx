package objects;

import objects.Note;
import objects.NotePool;
import objects.NoteTemplate;
import objects.AbstractNoteArray;
import objects.playfields.PlayField;

/**
 * Example showing how to integrate NotePool with PlayField's noteQueue system
 */
class PlayFieldNotePoolIntegration
{
	/**
	 * Shows how to modify PlayField to use the new NotePool system
	 */
	public static function demonstrateIntegration():Void
	{
		// STEP 1: Simple type change in PlayField
		// Change this line in PlayField.hx:
		// public var noteQueue:Array<Array<Note>> = [[], [], [], [], [], [], [], [],[], [], [], [],[], [], [], [], [], []];
		// 
		// To this:
		// public var noteQueue:PlayFieldNoteQueue = new PlayFieldNoteQueue();
		
		// STEP 2: All existing PlayField code continues to work!
		// The abstract types handle the conversion automatically
		
		trace("=== PLAYFIELD INTEGRATION EXAMPLE ===");
		
		// Create a mock PlayField setup
		var notePool = new NotePool();
		var noteQueue:PlayFieldNoteQueue = new PlayFieldNoteQueue(notePool);
		
		// Example 1: Existing PlayField queue() method works unchanged
		simulatePlayFieldQueue(noteQueue);
		
		// Example 2: Existing PlayField spawnNote() logic works unchanged  
		simulatePlayFieldSpawn(noteQueue);
		
		// Example 3: Show performance benefits
		demonstratePerformanceBenefits(noteQueue);
	}
	
	/**
	 * Simulate PlayField's queue() method
	 */
	private static function simulatePlayFieldQueue(noteQueue:PlayFieldNoteQueue):Void
	{
		trace("\n--- Simulating PlayField.queue() ---");
		
		// Create some notes to queue
		var note1 = new Note(1000, 0, null, false, false);
		var note2 = new Note(1500, 1, null, false, false);
		var note3 = new Note(2000, 2, null, false, false);
		
		// Original PlayField queue logic (works unchanged):
		function queue(note:Note) {
			// This is the EXACT same code from PlayField.hx
			if(noteQueue[note.column] == null)
				noteQueue[note.column] = new AbstractNoteArray();
			noteQueue[note.column].push(note);
			
			// Note: The sort would need a small adaptation, but the core logic is the same
			noteQueue.sort(note.column);
		}
		
		// Queue the notes
		queue(note1);
		queue(note2);
		queue(note3);
		
		trace('Queued ${noteQueue.getTotalCount()} notes across columns');
		trace('Column 0 length: ${noteQueue.length(0)}');
		trace('Column 1 length: ${noteQueue.length(1)}');
		trace('Column 2 length: ${noteQueue.length(2)}');
	}
	
	/**
	 * Simulate PlayField's spawnNote() method
	 */
	private static function simulatePlayFieldSpawn(noteQueue:PlayFieldNoteQueue):Void
	{
		trace("\n--- Simulating PlayField.spawnNote() ---");
		
		// Original PlayField spawn logic (works with minimal changes):
		function spawnNote(column:Int) {
			if (noteQueue[column] != null && noteQueue.length(column) > 0) {
				// Get the next note from the queue
				var template = noteQueue[column].getNext();
				if (template != null) {
					// Create the actual note from the template using the pool
					var note = noteQueue.getNotePool().createNoteFromTemplate(template);
					trace('Spawned note at time ${note.strumTime} for column ${column}');
					return note;
				}
			}
			return null;
		}
		
		// Spawn notes from each column
		for (column in 0...3) {
			var spawnedNote = spawnNote(column);
			if (spawnedNote != null) {
				trace('Successfully spawned note for column ${column}');
				// Return the note to the pool when done
				noteQueue.getNotePool().returnNote(spawnedNote);
			}
		}
	}
	
	/**
	 * Demonstrate the performance benefits
	 */
	private static function demonstratePerformanceBenefits(noteQueue:PlayFieldNoteQueue):Void
	{
		trace("\n--- Performance Benefits ---");
		
		var pool = noteQueue.getNotePool();
		var startStats = pool.getExtendedStats();
		
		// Simulate a busy song with lots of notes
		var notes:Array<Note> = [];
		for (i in 0...100) {
			var column = i % 4;
			var time = i * 100;
			
			// Create notes using the pool
			var note = pool.getNote(time, column);
			notes.push(note);
		}
		
		// Return all notes to pool
		pool.returnNotes(notes);
		
		var endStats = pool.getExtendedStats();
		
		trace('Notes created: ${endStats.totalCreated}');
		trace('Notes reused: ${endStats.totalReused}');
		trace('Pool efficiency: ${endStats.efficiency}%');
		trace('Pool utilization: ${endStats.poolUtilization}%');
	}
	
	/**
	 * Show how to modify existing PlayField methods
	 */
	public static function showPlayFieldModifications():Void
	{
		trace("\n=== REQUIRED PLAYFIELD MODIFICATIONS ===");
		
		trace("1. Change the noteQueue type declaration:");
		trace("   OLD: public var noteQueue:Array<Array<Note>> = [[], [], [], [], [], [], [], [],[], [], [], [],[], [], [], [], [], []];");
		trace("   NEW: public var noteQueue:PlayFieldNoteQueue = new PlayFieldNoteQueue();");
		
		trace("\n2. Update the queue() method:");
		trace("   OLD: noteQueue[note.column].sort((a, b) -> Std.int(a.strumTime - b.strumTime));");
		trace("   NEW: noteQueue.sort(note.column);");
		
		trace("\n3. Update spawning logic to use templates:");
		trace("   OLD: var note = noteQueue[column][0]; noteQueue[column].remove(note);");
		trace("   NEW: var note = noteQueue.createNextNote(column);");
		
		trace("\n4. Optional: Add note pool management:");
		trace("   - Call noteQueue.getNotePool().returnNote(note) when notes are destroyed");
		trace("   - Call noteQueue.clear() when changing songs");
	}
	
	/**
	 * Create a complete example PlayField integration
	 */
	public static function createExamplePlayField():ExamplePlayField
	{
		return new ExamplePlayField();
	}
}

/**
 * Example PlayField class showing the integration
 */
class ExamplePlayField
{
	// The only change needed: replace the type
	public var noteQueue:PlayFieldNoteQueue = new PlayFieldNoteQueue();
	public var spawnedNotes:Array<Note> = [];
	
	public function new()
	{
		// Initialize with a shared note pool for better performance
		var sharedPool = new NotePool();
		noteQueue = new PlayFieldNoteQueue(sharedPool);
	}
	
	// This method works exactly the same as before
	public function queue(note:Note):Void
	{
		if(noteQueue[note.column] == null)
			noteQueue[note.column] = new AbstractNoteArray();
		
		noteQueue.push(note.column, note);
		noteQueue.sort(note.column); // Now uses the optimized sort
	}
	
	// Updated spawn method using templates and pool
	public function spawnNote(column:Int):Note
	{
		if (noteQueue.isEmpty(column))
			return null;
			
		// Create note from template using pool
		var note = noteQueue.createNextNote(column);
		
		if (note != null)
		{
			spawnedNotes.push(note);
			note.spawned = true;
		}
		
		return note;
	}
	
	// Updated remove method that returns notes to pool
	public function removeNote(note:Note):Void
	{
		if (note == null) return;
		
		note.active = false;
		note.visible = false;
		spawnedNotes.remove(note);
		
		// Return to pool instead of destroying
		noteQueue.getNotePool().returnNote(note);
	}
	
	// Clear all notes and return to pool
	public function clearAllNotes():Void
	{
		// Return all spawned notes to pool
		for (note in spawnedNotes)
		{
			noteQueue.getNotePool().returnNote(note);
		}
		spawnedNotes = [];
		
		// Clear the queue
		noteQueue.clear();
	}
	
	// Get performance statistics
	public function getPerformanceStats():Dynamic
	{
		return {
			queueStats: noteQueue.getStats(),
			spawnedCount: spawnedNotes.length
		};
	}
}

/**
 * Utility class for migrating existing PlayField code
 */
class PlayFieldMigrationHelper
{
	/**
	 * Convert existing Array<Array<Note>> to PlayFieldNoteQueue
	 */
	public static function migrateNoteQueue(oldQueue:Array<Array<Note>>):PlayFieldNoteQueue
	{
		return PlayFieldNoteQueue.fromNoteArrays(oldQueue);
	}
	
	/**
	 * Convert PlayFieldNoteQueue back to Array<Array<Note>> if needed
	 */
	public static function convertToLegacyFormat(newQueue:PlayFieldNoteQueue):Array<Array<Note>>
	{
		return newQueue.toNoteArrays();
	}
	
	/**
	 * Batch migration for multiple PlayFields
	 */
	public static function migrateMultipleFields(fields:Array<Dynamic>):Void
	{
		for (field in fields)
		{
			if (Reflect.hasField(field, 'noteQueue'))
			{
				var oldQueue = Reflect.field(field, 'noteQueue');
				if (Std.isOfType(oldQueue, Array))
				{
					var newQueue = migrateNoteQueue(oldQueue);
					Reflect.setField(field, 'noteQueue', newQueue);
					trace('Migrated noteQueue for field');
				}
			}
		}
	}
}
