package archipelago;

import archipelago.PacketTypes.NetworkItem;

class APNote extends objects.Note {
    var APItem:NetworkItem;
    public var APItemLocation:Null<Int> = null;
    public var index:Int = 0;

    public function new(note:objects.Note, location:Int, ?item:NetworkItem = null) {
        super(note.strumTime, note.noteData, note.prevNote, note.isSustainNote);
        this.ignoreNote = note.ignoreNote;
        this.noteType = note.noteType;
        this.isCheck = true;
        // Copy the properties from the original note to this new note, via reflection
        trace("Copying properties from original note to new note...");
        for (field in Reflect.fields(note)) {
            if (field != "ignoreNote" && field != "noteType" && field != "strumTime" && field != "noteData" && field != "prevNote" && field != "isSustainNote") {
                try {
                    Reflect.setField(this, field, Reflect.field(note, field));
                } catch (e:Dynamic) {
                    trace('Failed to copy field: ' + field + ' with error: ' + e);
                }
            }
        }
        //note.destroy();
        trace("Properties copied. Destroying original note...");

        APItem = item;
        APItemLocation = location;

        // Set a unique RGBShader color for APNotes
        this.rgbShader.r = 0x3380CC; 
        this.rgbShader.g = 0x3380CC; 
        this.rgbShader.b = 0x3380CC; 

        this.checkInfo = {note: this, loc: location}; // Set the checkInfo for the new note
    }

    // Replace notes with a certain amount of locations.
    public static function replaceNotes(notes:Array<objects.Note>, locations:Array<Int>, ?ignoreNonEmptyNoteType:Bool = true) {
        var newNotes:Array<APNote> = [];
        var randomIndices:Array<Int> = [];

        // Generate a list of random unique indices
        while (randomIndices.length < Math.min(locations.length, notes.length)) {
            var randomIndex = Std.random(notes.length);
            var note = notes[randomIndex];

            var shouldIgnore:Bool = (note.ignoreNote || note.hitCausesMiss || note.isSustainNote || (ignoreNonEmptyNoteType && !note.noteType.isEmpty()) || !note.mustPress);
            if (shouldIgnore || randomIndices.contains(randomIndex)) continue; // Skip if the note should be ignored or already selected

            randomIndices.push(randomIndex);
        }

        for (i in 0...randomIndices.length) {
            var note:objects.Note = notes[randomIndices[i]];
            var location:Int = locations[i % locations.length];
            var apNote = new APNote(note, location, null); // Create a new APNote with the location
            // apNote.noteIndex = note.noteIndex;
            newNotes.push(apNote);

            // Replace the original note with the APNote
            notes[randomIndices[i]] = apNote;

            apNote.index = i; // Set the index for the new note


            // Set the checkInfo for the new note
            apNote.checkInfo = {note: apNote, loc: location};
        }
        return newNotes; // Return the new notes
    }

    public static function replaceInQueue(notes:Array<Array<objects.Note>>, locations:Array<Int>, ?ignoreNonEmptyNoteType:Bool = true) {
        var newNotes:Array<APNote> = [];
        var flatNotes:Array<{lane:Int, index:Int, note:objects.Note}> = [];
        
        // Flatten the notes array into a single array with lane and index information
        for (lane in 0...notes.length) {
            for (index in 0...notes[lane].length) {
                var note = notes[lane][index];
                flatNotes.push({lane: lane, index: index, note: note});
            }
        }

        var randomIndices:Array<Int> = [];

        // Generate a list of random unique indices across all notes
        while (randomIndices.length < Math.min(locations.length, flatNotes.length)) {
            var randomIndex = Std.random(flatNotes.length);
            var noteData = flatNotes[randomIndex];
            var note = noteData.note;

            var shouldIgnore:Bool = (note.ignoreNote || note.hitCausesMiss || note.isSustainNote || (ignoreNonEmptyNoteType && !note.noteType.isEmpty()) || !note.mustPress);
            if (shouldIgnore || randomIndices.contains(randomIndex)) continue; // Skip if the note should be ignored or already selected

            randomIndices.push(randomIndex);
        }

        for (i in 0...randomIndices.length) {
            var randomIndex = randomIndices[i];
            var noteData = flatNotes[randomIndex];
            var lane = noteData.lane;
            var index = noteData.index;
            var note = noteData.note;
            var location:Int = locations[i % locations.length];
            var apNote = new APNote(note, location, null); // Create a new APNote with the location
            // black coloring
            apNote.rgbShader.r = 0xFF313131;
            apNote.rgbShader.g = 0xFFFFFFFF;
            apNote.rgbShader.b = 0xFFB4B4B4;
            newNotes.push(apNote);

            // Replace the original note with the APNote
            notes[lane][index] = apNote;
            // Just in case, recolor.
            notes[lane][index].rgbShader.r = 0xFF313131;
            notes[lane][index].rgbShader.g = 0xFFFFFFFF;
            notes[lane][index].rgbShader.b = 0xFFB4B4B4;

            apNote.index = i; // Set the index for the new note

            // Set the checkInfo for the new note
            apNote.checkInfo = {note: apNote, loc: location};
        }
        return newNotes; // Return the new notes
    }

    public function sendCheck():Void {

        trace('Location ID: $APItemLocation');
        if (APItemLocation != null) {
            APEntryState.apGame.info().LocationChecks([APItemLocation]);
        }
    }
}