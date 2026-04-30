package setup;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.Note;
import objects.StrumNote;
import states.PlayState;

/**
 * Setup-specific control testing state
 * Simplified PlayState for testing controls without full gameplay
 */
class SetupControlsTest extends MusicBeatState {
    private var strumNotes:Array<StrumNote> = [];
    private var testNotes:Array<Note> = [];
    private var instructionText:FlxText;
    private var resultText:FlxText;
    private var backButton:FlxText;

    private var keysPressed:Array<Bool> = [false, false, false, false];
    private var testComplete:Bool = false;
    private var testTimer:Float = 0;

    override function create() {
        super.create();

        // Background
        var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = FlxColor.fromRGB(50, 50, 80);
        bg.scrollFactor.set();
        add(bg);

        // Title
        var titleText = new FlxText(0, 50, FlxG.width, "Control Test");
        titleText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
        titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        add(titleText);

        // Instructions
        instructionText = new FlxText(50, 120, FlxG.width - 100,
            "Test your controls by pressing the arrow keys or WASD.\nTry pressing each direction to make sure they work correctly.");
        instructionText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER);
        instructionText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        instructionText.wordWrap = true;
        add(instructionText);

        // Result text
        resultText = new FlxText(50, 200, FlxG.width - 100, "");
        resultText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.YELLOW, CENTER);
        resultText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        resultText.wordWrap = true;
        add(resultText);

        // Create strum notes for visual feedback
        createStrumNotes();

        // Back button
        backButton = new FlxText(50, FlxG.height - 80, 0, "← Back to Setup");
        backButton.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, LEFT);
        backButton.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        add(backButton);

        // Controls button
        var controlsButton = new FlxText(0, FlxG.height - 80, FlxG.width - 50, "Change Controls →");
        controlsButton.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, RIGHT);
        controlsButton.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        add(controlsButton);

        FlxG.mouse.visible = true;
    }

    function createStrumNotes() {
        var noteSize = 112;
        var startX = (FlxG.width - (noteSize * 4)) / 2;
        var noteY = 300;

        for (i in 0...4) {
            var strum = new StrumNote(startX + i * noteSize, noteY, i, null);
            strum.playAnim('static');
            add(strum);
            strumNotes.push(strum);
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        testTimer += elapsed;

        // Handle control inputs
        handleControlInputs();

        // Handle UI
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            goBack();
        }

        // Mouse interactions
        if (FlxG.mouse.justPressed) {
            if (FlxG.mouse.overlaps(backButton)) {
                goBack();
            }
        }

        // Update instructions based on test progress
        updateInstructions();
    }

    function handleControlInputs() {
        var currentPressed = [
            controls.NOTE_LEFT,
            controls.NOTE_DOWN,
            controls.NOTE_UP,
            controls.NOTE_RIGHT
        ];

        var justPressed = [
            controls.NOTE_LEFT_P,
            controls.NOTE_DOWN_P,
            controls.NOTE_UP_P,
            controls.NOTE_RIGHT_P
        ];

        // Visual feedback on strum notes
        for (i in 0...4) {
            if (justPressed[i]) {
                strumNotes[i].playAnim('confirm', true);
                keysPressed[i] = true;
                FlxG.sound.play(Paths.sound('hitsound'));
            } else if (currentPressed[i]) {
                if (strumNotes[i].animation.curAnim.name != 'confirm') {
                    strumNotes[i].playAnim('pressed');
                }
            } else {
                strumNotes[i].playAnim('static');
            }
        }
    }

    function updateInstructions() {
        var allPressed = true;
        var pressedCount = 0;

        for (pressed in keysPressed) {
            if (pressed) pressedCount++;
            else allPressed = false;
        }

        if (allPressed && !testComplete) {
            testComplete = true;
            resultText.text = "Great! All controls are working.\nYou can now change controls if needed or continue with setup.";
            resultText.color = FlxColor.LIME;
        } else if (pressedCount > 0) {
            var directions = ["Left", "Down", "Up", "Right"];
            var remaining = [];

            for (i in 0...keysPressed.length) {
                if (!keysPressed[i]) {
                    remaining.push(directions[i]);
                }
            }

            resultText.text = "Good! Still need to test: " + remaining.join(", ");
            resultText.color = FlxColor.YELLOW;
        } else if (testTimer > 3) {
            resultText.text = "Try pressing the arrow keys or WASD to test your controls.";
            resultText.color = FlxColor.WHITE;
        }
    }

    function goBack() {
        FlxG.sound.play(Paths.sound('cancelMenu'));

        // Return to the appropriate setup based on user's choice
        if (ClientPrefs.data.setupArchipelagoMode) {
            MusicBeatState.switchState(new ArchipelagoSetupState());
        } else {
            MusicBeatState.switchState(new BasicSettingsSetup());
        }
    }

    function startFullControlTest() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Try to load "Performance" song first, fallback to "Test"
        try {
            PlayfieldManager.SONG = Song.loadFromJson('tutorial');
            if (PlayfieldManager.SONG != null) {
                PlayState.isStoryMode = false;
                PlayState.storyDifficulty = 1;
                MusicBeatState.switchState(new SetupControlsPlayState());
                return;
            }
        } catch (e:Dynamic) {
            trace('Performance song not found: $e');
        }

        // Fallback to Test song
        try {
            PlayfieldManager.SONG = Song.loadFromJson('test');
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = 1;
            MusicBeatState.switchState(new SetupControlsPlayState());
        } catch (e:Dynamic) {
            trace('Test song not found either: $e');
            // Show error and return to setup
            goBack();
        }
    }
}
