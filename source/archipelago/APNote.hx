package archipelago;

import archipelago.PacketTypes.NetworkItem;

class APNote extends objects.Note {
    var APItem:NetworkItem;
    public var APItemLocation:Null<Int> = null;

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
            if (shouldIgnore) continue; // Skip if the note should be ignored

            // Check if the note should be ignored
            if (!randomIndices.contains(randomIndex) && 
                !note.ignoreNote && 
                (!ignoreNonEmptyNoteType || note.noteType.isEmpty())) {
                randomIndices.push(randomIndex);
            }
        }

        for (i in 0...randomIndices.length) {
            var note:objects.Note = notes[randomIndices[i]];
            var location:Int = locations[i % locations.length];
            var apNote = new APNote(note, location, null); // Create a new APNote with the location
            newNotes.push(apNote);
            notes[randomIndices[i]].isCheck = true; // Replace the original note with the APNote
            note = apNote; // Also replace the original note with the APNote
            for (queue in apNote.field.noteQueue) {
                for (i in 0...queue.length) {
                    if (queue[i] == note) {
                        queue[i] = apNote; // Replace the note with apNote in the double-array
                        queue[i].rgbShader.r = 0x3380CC; // Set the color of the new note
                        queue[i].rgbShader.g = 0x3380CC; // Set the color of the new note
                        queue[i].rgbShader.b = 0x3380CC; // Set the color of the new note
                        note.rgbShader.r = 0x3380CC; // Set the color of the original note to red
                        note.rgbShader.g = 0x3380CC; // Set the color of the original note to red
                        note.rgbShader.b = 0x3380CC; // Set the color of the original note to red
                        break; // Break out of the loop once the note is found and replaced
                    }
                }
            }
            apNote.isCheck = true; // Set the isCheck property to true
        }
    }

    public function sendCheck():Void {
        trace('Location ID: $APItemLocation');
        if (APItemLocation != null) {
            APEntryState.apGame.info().LocationChecks([APItemLocation]);
        }
    }
}