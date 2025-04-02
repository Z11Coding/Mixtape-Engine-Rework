package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxTypedGroup;
import objects.PlayField;
import backend.Song;
import backend.Conductor;

class PlaySubState extends MusicBeatSubstate {
    private var bg:FlxSprite;
    private var pausedText:FlxText;
    private var song:Song.SwagSong;
    private var playfields:FlxTypedGroup<PlayField>;
    private var isPaused:Bool = false;

    // Template for later.

    public function new(songData:SwagSong) {
        super();
        this.song = songData;
    }

    override public function create() {
        // Dim background
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        add(bg);

        // Generate playfields
        playfields = new FlxTypedGroup<PlayField>();
        generatePlayfields();
        add(playfields);

        // Generate song
        generateSong();

        // Add paused text (hidden initially)
        pausedText = new FlxText(0, FlxG.height / 2 - 50, FlxG.width, "PAUSED");
        pausedText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER);
        pausedText.visible = false;
        add(pausedText);

        super.create();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (isPaused) return;

        // Handle pausing
        if (FlxG.keys.justPressed.ENTER) {
            togglePause();
        }

        // End song and close substate
        if (Conductor.songPosition >= song.length) {
            close();
        }
    }

    private function togglePause() {
        isPaused = !isPaused;
        pausedText.visible = isPaused;

        if (isPaused) {
            FlxG.sound.music.pause();
        } else {
            FlxG.sound.music.resume();
        }
    }

    private function generatePlayfields() {
        for (i in 0...2) { // Example: 2 playfields
            var playfield = new PlayField();
            playfield.playerId = i;
            playfields.add(playfield);
        }
    }

    private function generateSong() {
        Conductor.mapBPMChanges(song);
        Conductor.bpm = song.bpm;

        FlxG.sound.playMusic(Paths.inst(song.song), 1, false);
        FlxG.sound.music.onComplete = function() {
            close();
        };
    }

    override public function close() {
        FlxG.sound.music.stop();
        super.close();
    }
}
