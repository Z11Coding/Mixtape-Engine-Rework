package archipelago;

import archipelago.PacketTypes.NetworkItem;

class APNote extends objects.Note {
    var APItem:NetworkItem;
    var APItemLocation:Null<Int> = null;

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
    public static function replaceNotes(notes:Array<objects.Note>, locations:Array<Int>, ?ignoreNonEmptyNoteType:Bool = true):Array<APNote> {
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
            note.isCheck = true;
            note = apNote; // Replace the original note with the APNote
        }

        return newNotes;
    }

    public function sendCheck():Void {
        if (APItemLocation != null) {
            APEntryState.apGame.info().LocationChecks([APItemLocation]);
        }
    }
}