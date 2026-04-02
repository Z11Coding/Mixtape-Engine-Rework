package archipelago;

import archipelago.PacketTypes.NetworkItem;
import objects.Note;

class APNote extends objects.Note {
    var APItem:NetworkItem;
    public var APItemLocation:Null<Int> = null;
    public var index:Int = 0;

    public function new(note:objects.Note, location:Int, ?item:NetworkItem = null) {
        super(note.strumTime, note.noteData, note.prevNote, note.isSustainNote);
        this.ignoreNote = note.ignoreNote;
        this.noteType = note.noteType;
        this.isCheck = true;
        // Set a unique RGBShader color for APNotes (matching the replaceInQueue method)
        this.rgbShader.enabled = true;
        this.rgbShader.r = 0xFF313131;
        this.rgbShader.g = 0xFFFFFFFF;
        this.rgbShader.b = 0xFFB4B4B4;
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

        this.checkInfo = {note: this, loc: location}; // Set the checkInfo for the new note

        // Special handling for pixel stages to avoid crashes
        if (!states.PlayState.isPixelStage) {
            // Only set up AP note texture and animations for non-pixel stages
            this.texture = 'noteSkins/ap_assets/AP_NOTE';

            // Set up lane-based animations like standard notes
            // Create animations for each lane using the same 'ap' prefix since there's only one AP texture
            for (i in 0...Note.gfxLetter.length) {
                // Regular note animations for each lane (A, B, C, D, etc.)
                this.animation.addByPrefix(Note.gfxLetter[i], 'ap0', 24, false);

                // Sustain note animations if this is a sustain note
                if (this.isSustainNote) {
                    this.animation.addByPrefix(Note.gfxLetter[i] + ' hold', 'ap hold piece', 24, true);
                    this.animation.addByPrefix(Note.gfxLetter[i] + ' tail', 'ap hold end', 24, false);
                }
            }

            // Play the appropriate animation based on note data
            if (this.noteData >= 0 && this.noteData < Note.gfxLetter.length) {
                if (this.isSustainNote) {
                    if (this.prevNote != null && this.prevNote.isSustainNote) {
                        this.animation.play(Note.gfxLetter[this.noteData] + ' hold');
                    } else {
                        this.animation.play(Note.gfxLetter[this.noteData] + ' tail');
                    }
                } else {
                    this.animation.play(Note.gfxLetter[this.noteData]);
                }
            } else {
                // Fallback to first animation
                if (this.isSustainNote) {
                    if (this.prevNote != null && this.prevNote.isSustainNote) {
                        this.animation.play(Note.gfxLetter[0] + ' hold');
                    } else {
                        this.animation.play(Note.gfxLetter[0] + ' tail');
                    }
                } else {
                    this.animation.play(Note.gfxLetter[0]);
                }
            }
        }
        // For pixel stages, we keep the original texture and animations but use RGB shader for coloring
    }

    // Replace notes with a certain amount of locations.
    public static function replaceNotes(notes:Array<objects.Note>, locations:Array<Int>, ?ignoreNonEmptyNoteType:Bool = true) { // This needs to stay, since this will be useful for regular engines.
        var newNotes:Array<APNote> = [];
        var randomIndices:Array<Int> = [];
        var isAprilFools:Bool = yutautil.AprilFools.allowAF;

        // Generate a list of random unique indices
        while (randomIndices.length < Math.min(locations.length, notes.length)) {
            var randomIndex = Std.random(notes.length);
            var note = notes[randomIndex];

            var shouldIgnore:Bool = (note.ignoreNote || note.hitCausesMiss || note.isSustainNote || (ignoreNonEmptyNoteType && !note.noteType.isEmpty()) || !note.mustPress);

            if (isAprilFools) {
                // On April Fools, allow sustainNotes and rarely ignoreNotes or non-empty noteTypes
                if (note.isSustainNote && Std.random(100) < 20) shouldIgnore = false; // 20% chance to allow sustainNotes
                if (note.ignoreNote && Std.random(100) < 10) shouldIgnore = false; // 10% chance to allow ignoreNotes
                if (!note.noteType.isEmpty() && Std.random(100) < 10) shouldIgnore = false; // 10% chance to allow non-empty noteTypes
            }

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
            notes[randomIndices[i]].rgbShader.enabled = true;
            notes[randomIndices[i]].rgbShader.r = 0xFF313131;
            notes[randomIndices[i]].rgbShader.g = 0xFFFFFFFF;
            notes[randomIndices[i]].rgbShader.b = 0xFFB4B4B4;
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
        var isAprilFools:Bool = yutautil.AprilFools.allowAF;

        // Flatten the notes array into a single array with lane and index information
        for (lane in 0...notes.length) {
            for (index in 0...notes[lane].length) {
                var note = notes[lane][index];
                flatNotes.push({lane: lane, index: index, note: note});
            }
        }

        var randomIndices:Array<Int> = [];
        var availableNotes:Array<Int> = [];

        if (flatNotes.length == 0) {
            trace("No notes available to replace.");
            trace(archipelago.APEntryState.apGame.info().LocationChecks(locations));
            trace("Couldn't place any notes, so we're just sending the checks.");
            return newNotes; // Return an empty array if there are no notes
        }

        if (flatNotes.length < locations.length) {
            // Take the difference and pop some locations out of the array.
            trace("Not enough notes available to replace. Reducing locations.");
            for (i in 0...locations.length) {
                if (locations[i] >= flatNotes.length) {
                    locations.splice(i, 1); // Remove the location if it exceeds the available notes
                    // i--;
                }
            }
        }

        // Check for available notes based on the ignoreNonEmptyNoteType rule
        for (i in 0...flatNotes.length) {
            var note = flatNotes[i].note;
            var shouldIgnore:Bool = (note.ignoreNote || note.hitCausesMiss || note.isSustainNote || (ignoreNonEmptyNoteType && !note.noteType.isEmpty()) || !note.mustPress);

            if (isAprilFools) {
                // On April Fools, allow sustainNotes and rarely ignoreNotes or non-empty noteTypes
                if (note.isSustainNote && Std.random(100) < 20) shouldIgnore = false; // 20% chance to allow sustainNotes
                if (note.ignoreNote && Std.random(100) < 10) shouldIgnore = false; // 10% chance to allow ignoreNotes
                if (!note.noteType.isEmpty() && Std.random(100) < 10) shouldIgnore = false; // 10% chance to allow non-empty noteTypes
            }

            if (!shouldIgnore) {
                availableNotes.push(i);
            }
        }

        // If there aren't enough available notes, make an exception for the ignoreNonEmptyNoteType rule
        if (availableNotes.length < locations.length) {
            trace("Not enough available notes, ignoring non-empty note type rule.");
            ignoreNonEmptyNoteType = false;
        }

        // Generate a list of random unique indices across all notes
        while (randomIndices.length < Math.min(locations.length, flatNotes.length)) {
            var randomIndex = Std.random(flatNotes.length);
            var noteData = flatNotes[randomIndex];
            var note = noteData.note;

            var shouldIgnore:Bool = (note.ignoreNote || note.hitCausesMiss || note.isSustainNote || (ignoreNonEmptyNoteType && !note.noteType.isEmpty()) || !note.mustPress);

            if (isAprilFools) {
                // On April Fools, allow sustainNotes and rarely ignoreNotes or non-empty noteTypes
                if (note.isSustainNote && Std.random(100) < 20) shouldIgnore = false; // 20% chance to allow sustainNotes
                if (note.ignoreNote && Std.random(100) < 10) shouldIgnore = false; // 10% chance to allow ignoreNotes
                if (!note.noteType.isEmpty() && Std.random(100) < 10) shouldIgnore = false; // 10% chance to allow non-empty noteTypes
            }

            if (shouldIgnore || randomIndices.contains(randomIndex)) continue; // Skip if the note should be ignored or already selected

            randomIndices.push(randomIndex);
        }

        for (i in 0...randomIndices.length) {
            var randomIndex = randomIndices[i];
            var noteData = flatNotes[randomIndex];
            var lane = noteData.lane;
            var index = noteData.index;
            var location:Int = locations[i % locations.length];

            // Replace the original note with the APNote
            @:privateAccess{
                notes[lane][index].finalize(); // Finalize the note to ensure no issues when finalizing at birth.
                notes[lane][index].isCheck = true;
                notes[lane][index].checkInfo = {note: notes[lane][index], loc: location};

                // Special handling for pixel stages to avoid crashes
                if (states.PlayState.isPixelStage) {
                    // For pixel stages, enable shader with colors but don't change texture
                    notes[lane][index].rgbShader.enabled = true;
                    notes[lane][index].rgbShader.r = 0xFF313131;
                    notes[lane][index].rgbShader.g = 0xFFFFFFFF;
                    notes[lane][index].rgbShader.b = 0xFFB4B4B4;

                    // Apply same shader colors to child notes
                    var children = notes[lane][index].childrenNotes;
                    for (child in children) {
                        child.rgbShader.enabled = true;
                        child.rgbShader.r = 0xFF313131;
                        child.rgbShader.g = 0xFFFFFFFF;
                        child.rgbShader.b = 0xFFB4B4B4;
                    }
                } else {
                    // For non-pixel stages, use normal AP note texture and disable shader
                    notes[lane][index].rgbShader.enabled = false;
                    notes[lane][index].rgbShader.r = 0xFF313131;
                    notes[lane][index].rgbShader.g = 0xFFFFFFFF;
                    notes[lane][index].rgbShader.b = 0xFFB4B4B4;
                    notes[lane][index].texture = 'noteSkins/ap_assets/AP_NOTE'; // Set the texture to the APNote texture

                    // Set child notes to the same texture
                    var children = notes[lane][index].childrenNotes;
                    for (child in children) {
                        child.texture = 'noteSkins/ap_assets/AP_NOTE';
                        child.rgbShader.enabled = false;
                        child.rgbShader.r = 0xFF313131;
                        child.rgbShader.g = 0xFFFFFFFF;
                        child.rgbShader.b = 0xFFB4B4B4;
                    }

                    // Set up lane-based animations like standard notes
                    // Create animations for each lane using the same 'ap' prefix since there's only one AP texture
                    for (j in 0...Note.gfxLetter.length) {
                        // Regular note animations for each lane (A, B, C, D, etc.)
                        notes[lane][index].animation.addByPrefix(Note.gfxLetter[j], 'ap0', 24, false);

                        // Sustain note animations if this is a sustain note
                        if (notes[lane][index].isSustainNote) {
                            notes[lane][index].animation.addByPrefix(Note.gfxLetter[j] + ' hold', 'ap hold piece0', 24, true);
                            notes[lane][index].animation.addByPrefix(Note.gfxLetter[j] + ' tail', 'ap hold end0', 24, false);
                        }
                    }

                    // Play the appropriate animation based on note data
                    var noteData = notes[lane][index].noteData;
                    if (noteData >= 0 && noteData < Note.gfxLetter.length) {
                        if (notes[lane][index].isSustainNote) {
                            if (notes[lane][index].prevNote != null && notes[lane][index].prevNote.isSustainNote) {
                                notes[lane][index].animation.play(Note.gfxLetter[noteData] + ' hold');
                            } else {
                                notes[lane][index].animation.play(Note.gfxLetter[noteData] + ' tail');
                            }
                        } else {
                            notes[lane][index].animation.play(Note.gfxLetter[noteData]);
                        }
                    } else {
                        // Fallback to first animation
                        if (notes[lane][index].isSustainNote) {
                            if (notes[lane][index].prevNote != null && notes[lane][index].prevNote.isSustainNote) {
                                notes[lane][index].animation.play(Note.gfxLetter[0] + ' hold');
                            } else {
                                notes[lane][index].animation.play(Note.gfxLetter[0] + ' tail');
                            }
                        } else {
                            notes[lane][index].animation.play(Note.gfxLetter[0]);
                        }
                    }
                }
            }
        }
        trace("Successfully generated [" + randomIndices.length + "] APNotes.");

        // Recolor other notes with the same note indexes as the new notes.
        for (noteData in flatNotes)
            for (note in newNotes)
            if (noteData.note.noteIndex == note.noteIndex) {
                notes[noteData.lane][noteData.index].rgbShader.r = 0xFF313131; // Reset the color of the original note
                notes[noteData.lane][noteData.index].rgbShader.g = 0xFFFFFFFF;
                notes[noteData.lane][noteData.index].rgbShader.b = 0xFFB4B4B4;
            }

        return newNotes; // Return the new notes
    }
}
