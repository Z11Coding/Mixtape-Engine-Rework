package objects;

import objects.Note;

class NoteManager
{
	public var activeNotes:FlxTypedGroup<Note>;
	public var notePool:Array<Note> = [];

    public function new()
    {
    	activeNotes = new FlxTypedGroup<Note>();
    }

    public function getNote(strumTime:Float, noteData:Int, ?prevNote:Note = null, ?sustainNote:Bool = false):Note
    {
        var note:Note;

        if (notePool.length > 0)
        {
					note = notePool.pop();
					note.strumTime = strumTime;
        }
        else
        {
          note = new Note(strumTime, noteData, prevNote, sustainNote);
        }

        // Reset common FlxSprite/FlxObject flags
        note.exists = true;
        note.active = true;
        note.visible = true;
        note.spawned = false;

        // Add to active notes for update/render management
        activeNotes.add(note);

        return note;
    }

    public function recycleNote(note:Note):Void
    {
    	note.kill(); // disables it
    	note.exists = false;
    	note.active = false;
    	note.visible = false;
    	notePool.push(note); // store for reuse
    }

	/**
	 * Used in generateSong or when creating chart notes.
	 */
	public function spawnNote(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustain:Bool = false, ?editor:Bool = false, ?createdFrom:Dynamic = null):Note
	{
		var note = getNote(strumTime, noteData, prevNote, sustain);
		//note.makeNote(strumTime, noteData, prevNote, sustain, editor, createdFrom);
		return note;
	}

	/**
	 * Call every frame from PlayState.update to hide notes offscreen.
	 */
	public function updateVisibility(scrollY:Float, cutoff:Float = 1800)
	{
		activeNotes.forEachAlive((note) -> {
			note.visible = Math.abs(note.y - scrollY) < cutoff;
		});
	}

	public function clearAllNotes()
	{
		activeNotes.forEachAlive((note) -> recycleNote(note));
	}
}
