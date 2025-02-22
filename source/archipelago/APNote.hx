package archipelago;

import archipelago.PacketTypes.NetworkItem;

class APNote extends objects.Note {


    var APItem:NetworkItem;

    public function new(note:Note, item:NetworkItem = null) {
        super(note.strumTime, note.noteData, note.prevNote, note.isSustainNote);
        note.destroy();
    }
}