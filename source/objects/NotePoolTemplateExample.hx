package objects;

import objects.Note;
import objects.NotePool;
import objects.NoteTemplate;
import objects.AbstractNoteArray;

/**
 * Example usage of NotePool with NoteTemplate and AbstractNoteArray
 */
class NotePoolTemplateExample
{
	public static function demonstrateUsage():Void
	{
		// Create a note pool
		var notePool = new NotePool();
		
		// Example 1: Create note templates manually
		var templates:AbstractNoteArray = new AbstractNoteArray();
		
		// Add some basic note templates
		templates.add(new NoteTemplate(0, 0, false, null, true));          // Left arrow at time 0
		templates.add(new NoteTemplate(500, 1, false, null, true));        // Down arrow at time 500
		templates.add(new NoteTemplate(1000, 2, false, null, true));       // Up arrow at time 1000
		templates.add(new NoteTemplate(1500, 3, false, null, true));       // Right arrow at time 1500
		
		// Add a sustain note
		templates.add(new NoteTemplate(2000, 0, true, null, true));        // Left sustain at time 2000
		
		// Add special note types
		templates.add(new NoteTemplate(2500, 1, false, "Hurt Note", true)
			.setCustomData('hitCausesMiss', true)
			.setCustomData('lowPriority', true));
		
		// Add a mine note (Archipelago-specific)
		templates.add(new NoteTemplate(3000, 2, false, "Mine Note", true)
			.setCustomData('isMine', true)
			.setCustomData('specialNote', true)
			.setCustomData('ignoreMiss', true));
		
		// Add an event note
		templates.add(new NoteTemplate(3500, 3, false, null, true)
			.setEventData('Camera Focus', 'dad', ''));
		
		// Sort templates by time
		templates.sortByTime();
		
		// Example 2: Create notes from templates
		var createdNotes = notePool.createNotesFromTemplates(templates);
		
		trace('Created ${createdNotes.length} notes from templates');
		
		// Example 3: Working with individual templates
		var healTemplate = new NoteTemplate(4000, 1, false, "Heal Note", true)
			.setCustomData('isHeal', true)
			.setCustomData('hitHealth', 0.1)
			.setCustomData('specialNote', true);
		
		var healNote = notePool.createNoteFromTemplate(healTemplate);
		trace('Created heal note at time: ${healNote.strumTime}');
		
		// Example 4: Convert existing notes to templates
		var existingNotes:Array<Note> = [
			new Note(5000, 0, null, false, false),
			new Note(5200, 1, null, false, false),
			new Note(5400, 2, null, false, false),
			new Note(5600, 3, null, false, false)
		];
		
		// Convert to AbstractNoteArray
		var convertedTemplates:AbstractNoteArray = existingNotes;
		
		// Create notes from converted templates
		var convertedNotes = notePool.createNotesFromTemplates(convertedTemplates);
		trace('Created ${convertedNotes.length} notes from converted templates');
		
		// Example 5: Template filtering and searching
		var allTemplates = new AbstractNoteArray();
		allTemplates.addAll(templates);
		allTemplates.addAll(convertedTemplates);
		
		// Get notes by type
		var hurtNotes = allTemplates.getByType("Hurt Note");
		trace('Found ${hurtNotes.length} hurt note templates');
		
		// Get notes in time range
		var earlyNotes = allTemplates.getByTimeRange(0, 2000);
		trace('Found ${earlyNotes.length} note templates in early time range');
		
		// Example 6: Pre-populate pool with templates
		var prePopTemplates:AbstractNoteArray = new AbstractNoteArray();
		for (i in 0...20)
		{
			prePopTemplates.add(new NoteTemplate(i * 100, i % 4, false, null, true));
		}
		
		// Pre-populate the pool
		notePool.prePopulateFromTemplates(prePopTemplates);
		
		// Check pool statistics
		var stats = notePool.getExtendedStats();
		trace('Pool efficiency: ${stats.efficiency}%');
		trace('Pool utilization: ${stats.poolUtilization}%');
		trace('Total pooled notes: ${stats.totalPooled}');
		
		// Example 7: Template chaining for complex patterns
		var patternTemplates = createArpeggiPattern(6000, 16);
		var patternNotes = notePool.createNotesFromTemplates(patternTemplates);
		trace('Created arpeggio pattern with ${patternNotes.length} notes');
		
		// Clean up - return all notes to pool
		var allCreatedNotes = createdNotes.concat(convertedNotes).concat(patternNotes);
		allCreatedNotes.push(healNote);
		
		notePool.returnNotes(allCreatedNotes);
		
		// Final statistics
		var finalStats = notePool.getExtendedStats();
		trace('Final pool state - Active: ${finalStats.totalActive}, Pooled: ${finalStats.totalPooled}');
	}
	
	/**
	 * Create an arpeggio pattern using templates
	 */
	private static function createArpeggiPattern(startTime:Float, noteCount:Int):AbstractNoteArray
	{
		var templates:AbstractNoteArray = new AbstractNoteArray();
		
		var timeStep:Float = 125; // 125ms between notes
		var currentTime:Float = startTime;
		
		for (i in 0...noteCount)
		{
			var noteData:Int = i % 4; // Cycle through 0,1,2,3
			var template = new NoteTemplate(currentTime, noteData, false, null, true);
			
			// Add some variation
			if (i % 8 == 7) // Every 8th note is a different type
			{
				template.noteType = "Alt Animation";
				template.setCustomData('animSuffix', '-alt');
			}
			
			templates.add(template);
			currentTime += timeStep;
		}
		
		return templates;
	}
	
	/**
	 * Create a sustain note chain using templates
	 */
	public static function createSustainChain(startTime:Float, noteData:Int, sustainLength:Float, stepSize:Float = 100):AbstractNoteArray
	{
		var templates:AbstractNoteArray = new AbstractNoteArray();
		
		// Create head note
		var headTemplate = new NoteTemplate(startTime, noteData, false, null, true);
		templates.add(headTemplate);
		
		// Create sustain parts
		var currentTime:Float = startTime + stepSize;
		while (currentTime < startTime + sustainLength)
		{
			var sustainTemplate = new NoteTemplate(currentTime, noteData, true, null, true);
			templates.add(sustainTemplate);
			currentTime += stepSize;
		}
		
		return templates;
	}
	
	/**
	 * Create a chord pattern using templates
	 */
	public static function createChord(startTime:Float, noteData:Array<Int>, ?noteType:String = null):AbstractNoteArray
	{
		var templates:AbstractNoteArray = new AbstractNoteArray();
		
		for (data in noteData)
		{
			var template = new NoteTemplate(startTime, data, false, noteType, true);
			templates.add(template);
		}
		
		return templates;
	}
}
