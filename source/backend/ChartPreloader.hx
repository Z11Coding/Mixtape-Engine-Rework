 package backend;

import backend.ClientPrefs;
import backend.Conductor;
import backend.Song;
import objects.Note.EventNote;
import objects.Note.SustainPart;
import objects.Note;
import objects.NoteManager;
import states.PlayState;

using objects.Note.SustainPart;

/**
 * System for pre-generating chart data during loading screen
 */
class ChartPreloader
{
	// Static data storage for pre-generated chart
	public static var preGeneratedNotes:Array<Note> = [];
	public static var preGeneratedEvents:Array<EventNote> = [];
	public static var isPreGenerated:Bool = false;
	public static var songData:SwagSong = null;
	public static var noteManager:NoteManager = null;

	// Simple data structure to hold note information
	public static var chartGenerationProgress:Int = 0;
	public static var chartGenerationMax:Int = 0;

	/**
	 * Clear pre-generated data
	 */
	public static function clear():Void
	{
		// Clean up existing Note objects to prevent memory leaks
		for (note in preGeneratedNotes)
		{
			if (note != null) note.destroy();
		}

		preGeneratedNotes = [];
		preGeneratedEvents = [];
		isPreGenerated = false;
		songData = null;
		chartGenerationProgress = 0;
		chartGenerationMax = 0;

		if (noteManager != null)
		{
			noteManager = null;
		}
	}

	/**
	 * Pre-generate chart data during loading
	 */
	public static function preGenerateChart(song:SwagSong):Void
	{
		if (!ClientPrefs.data.preGenerateCharts || song == null) return;
		
		try {
			clear();
			songData = song;
			
			// Set the mania from the song data (same logic as PlayState)
			var mania:Int = 3; // Default mania
			if (song.mania != null)
			{
				if (song.mania >= 3) //Make sure it's even there
					mania = song.mania;
				else 
					mania = switch (song.mania) { //Convert it to make sure the older versions still work
						case 0: 3;
						case 1: 4;
						default: song.mania;
					};
			}
			
			// Set PlayState.mania for consistency
			states.PlayState.mania = mania;
			
			// Calculate songSpeed (same logic as PlayState)
			var songSpeed:Float = song.speed;
			var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
			switch(songSpeedType)
			{
				case "multiplicative":
					songSpeed = song.speed * ClientPrefs.getGameplaySetting('scrollspeed');
				case "constant":
					songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
			}
			
			// Create a NoteManager for note generation
			noteManager = new NoteManager();
			
			trace('Starting chart pre-generation for: ${song.song} (${mania + 1}K, Speed: ${songSpeed})');
			
			// Count total notes first for progress tracking
			var totalNotes:Int = 0;
			for (section in song.notes)
			{
				totalNotes += section.sectionNotes.length;
				// Add sustain notes to count
				for (noteData in section.sectionNotes)
				{
					var holdLength:Float = noteData[2];
					if (holdLength > 0)
					{
						var curStepCrochet:Float = 60 / Conductor.bpm * 1000 / 4.0;
						var roundSus:Int = Math.round(holdLength / curStepCrochet) - 1;
						if (roundSus > 0) totalNotes += roundSus;
					}
				}
			}
			
			chartGenerationMax = totalNotes;
			chartGenerationProgress = 0;
			
			// Generate events first
			try
			{
				var eventsChart:SwagSong = Song.getChart('events', song.song);
				if(eventsChart != null)
				{
					for (event in eventsChart.events)
					{
						for (i in 0...event[1].length)
						{
							var subEvent:EventNote = {
								strumTime: event[0] + ClientPrefs.data.noteOffset,
								event: event[1][i][0],
								value1: event[1][i][1],
								value2: event[1][i][2]
							};
							preGeneratedEvents.push(subEvent);
						}
					}
				}
			}
			catch(e:Dynamic) 
			{
				trace('Error pre-generating events: $e');
			}
			
			// Generate actual Note objects
			var sectionsData:Array<SwagSection> = song.notes;
			var daBpm:Float = Conductor.bpm;
			var oldNote:Note = null;
			
			for (section in sectionsData)
			{
				if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
					daBpm = section.bpm;
				
				for (i in 0...section.sectionNotes.length)
				{
					final songNotes:Array<Dynamic> = section.sectionNotes[i];
					var spawnTime:Float = songNotes[0];
					var noteColumn:Int = Std.int(songNotes[1]);
					var holdLength:Float = songNotes[2];
					var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
					
					if (Math.isNaN(holdLength)) holdLength = 0.0;
					
					var gottaHitNote:Bool = (songNotes[1] < Note.ammo[mania]);
					var isAlt:Bool = section.altAnim && !gottaHitNote;
					var gfNote:Bool = (section.gfSection && gottaHitNote == section.mustHitSection);
					
					// Create main Note object
					var swagNote:Note = noteManager.getNote(spawnTime, noteColumn, oldNote, false);
					swagNote.noteIndex = Std.int(preGeneratedNotes.length);
					swagNote.formerPress = swagNote.mustPress = gottaHitNote;
					swagNote.gfNote = gfNote;
					swagNote.animSuffix = isAlt ? "-alt" : "";
					swagNote.noteType = noteType;
					swagNote.ID = preGeneratedNotes.length;
					swagNote.scrollFactor.set();
					swagNote.sustainLength = holdLength;
					swagNote.holdType = holdLength > 0 ? HEAD : TAP;
					swagNote.isParent = holdLength > 0;
					
					// Set field index (0 = player, 1 = opponent/dad)
					swagNote.fieldIndex = gottaHitNote ? 0 : 1;
					
					// Pre-calculate visualTime using songSpeed
					// This is a simplified version of what PlayState does with getNoteInitialTime
					swagNote.visualTime = spawnTime - (1500 / songSpeed);
					
					preGeneratedNotes.push(swagNote);
					chartGenerationProgress++;
					oldNote = swagNote;
					
					// Generate sustain notes
					var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
					var roundSus:Int = Math.round(holdLength / curStepCrochet) - 1;
					if (roundSus > 0)
					{
						for (susNote in 0...roundSus)
						{
							var sustainTime:Float = spawnTime + (curStepCrochet * susNote) + curStepCrochet;
							var sustainNote:Note = noteManager.getNote(sustainTime, noteColumn, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = gfNote;
							sustainNote.animSuffix = swagNote.animSuffix;
							sustainNote.noteType = noteType;
							sustainNote.noteIndex = swagNote.noteIndex;
							sustainNote.ID = preGeneratedNotes.length;
							sustainNote.scrollFactor.set();
							sustainNote.holdType = (susNote < roundSus - 1) ? PART : END;
							sustainNote.parent = swagNote;
							
							// Set same field index as parent
							sustainNote.fieldIndex = swagNote.fieldIndex;
							
							// Pre-calculate visualTime using songSpeed
							sustainNote.visualTime = sustainTime - (1500 / songSpeed);
							
							// Add to parent's tail
							swagNote.tail.push(sustainNote);
							swagNote.unhitTail.push(sustainNote);
							
							preGeneratedNotes.push(sustainNote);
							chartGenerationProgress++;
							oldNote = sustainNote;
						}
					}
				}
			}
			
			isPreGenerated = true;
			trace('Chart pre-generation completed: ${preGeneratedNotes.length} Note objects created');
		}
		catch (e:Dynamic) 
		{
			trace('Error during chart pre-generation: $e');
			// Clear partial data on error
			clear();
		}
	}	/**
	 * Get progress percentage for loading bar
	 */
	public static function getProgress():Float
	{
		if (chartGenerationMax <= 0) return 1.0;
		return chartGenerationProgress / chartGenerationMax;
	}
}
