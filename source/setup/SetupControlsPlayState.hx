package setup;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import states.PlayState;
import objects.Note;
import objects.playfields.PlayField;

/**
 * Enhanced PlayState specifically designed for control testing during setup
 * Extends PlayState to provide a controlled environment for testing gameplay controls
 */
class SetupControlsPlayState extends PlayState {
    public var testModeUI:FlxSprite;
    public var testInstructions:FlxText;
    public var backButton:FlxText;
    public var testTimer:Float = 0;
    public var notesHit:Int = 0;
    public var notesMissed:Int = 0;
    public var readyToStart:Bool = false;

    override function create() {
        super.create();

        // Add test mode overlay
        createTestModeUI();

        // Disable normal pause functionality
        canPause = false;

        // Show initial instructions
        showInstructions();
    }

    function createTestModeUI() {
        // Semi-transparent overlay for test info
        testModeUI = new FlxSprite(0, 0);
        testModeUI.makeGraphic(FlxG.width, 120, FlxColor.fromRGB(0, 0, 0, 150));
        testModeUI.scrollFactor.set();
        add(testModeUI);

        // Test instructions
        testInstructions = new FlxText(20, 20, FlxG.width - 40,
            "CONTROL TEST MODE - Press SPACE to start, ESC to return to setup", 16);
        testInstructions.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        testInstructions.borderSize = 1;
        testInstructions.scrollFactor.set();
        add(testInstructions);

        // Back button indicator
        backButton = new FlxText(20, FlxG.height - 60, 0, "← ESC: Back to Setup");
        backButton.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        backButton.borderSize = 1;
        backButton.scrollFactor.set();
        add(backButton);

        // Stats display
        var statsText = new FlxText(FlxG.width - 300, FlxG.height - 60, 280, "");
        statsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.CYAN, RIGHT, OUTLINE, FlxColor.BLACK);
        statsText.borderSize = 1;
        statsText.scrollFactor.set();
        add(statsText);
    }

    public function showInstructions() {
        testInstructions.text = "🎮 CONTROL TEST MODE\\n" +
            "This will play a song to test your controls in action.\\n" +
            "Press SPACE to start playing, ESC to return to setup.";
        testInstructions.color = FlxColor.YELLOW;
    }

    override function update(elapsed:Float) {
        // Handle test mode controls
        if (FlxG.keys.justPressed.ESCAPE) {
            returnToSetup();
            return;
        }

        if (FlxG.keys.justPressed.SPACE && !readyToStart) {
            startTest();
        }

        // Update test timer
        if (startedCountdown && Conductor.songPosition > 0) {
            testTimer += elapsed;
            updateTestStats();
        }

        // Let the song play through naturally - no time limits

        super.update(elapsed);
    }

    function startTest() {
        // Set ready to start and begin countdown
        readyToStart = true;
        super.startCountdown();

        testInstructions.text = "🎵 Now playing! Test your controls by hitting the notes.\\n" +
            "The song will end automatically, or press ESC to return early.";
        testInstructions.color = FlxColor.LIME;
        testTimer = 0;
    }

    function updateTestStats() {
        // Update the stats display
        var statsText = members[members.length - 1]; // Get the stats text we added
        if (Std.isOfType(statsText, FlxText)) {
            var stats:FlxText = cast statsText;
            var accuracy = notesHit + notesMissed > 0 ? Math.round((notesHit / (notesHit + notesMissed)) * 100) : 0;
            stats.text = 'Time: ${Math.floor(testTimer)}s\\nHits: $notesHit\\nMisses: $notesMissed\\nAccuracy: $accuracy%';
        }
    }

    override function goodNoteHit(note:Note, field:PlayField) {
        super.goodNoteHit(note, field);
        notesHit++;
    }

    override function noteMiss(daNote:Note, field:PlayField) {
        super.noteMiss(daNote, field);
        notesMissed++;
    }



    function returnToSetup() {
        // Stop music
        if (FlxG.sound.music != null) {
            FlxG.sound.music.stop();
        }

        // Return to appropriate setup state
        FlxG.sound.play(Paths.sound('cancelMenu'));

        if (ClientPrefs.data.setupArchipelagoMode) {
            MusicBeatState.switchState(new ArchipelagoSetupState());
        } else {
            MusicBeatState.switchState(new BasicSettingsSetup());
        }
    }

    // Override startCountdown to control when it can actually begin
    override function startCountdown():Bool {
        if (!readyToStart) {
            return false; // Don't start countdown until user is ready
        }
        return super.startCountdown();
    }

    // Disable some PlayState features that aren't needed for testing
    override function openPauseMenu() {
        // Show custom pause menu or just return to setup
        returnToSetup();
    }

    override function finishSong(?isFromGameOverMenu:Bool = false):Void {
        // Show custom test results substate instead of normal ranking
        openSubState(new SetupControlsResultSubstate(notesHit, notesMissed, testTimer));
    }
}

/**
 * Custom substate for showing control test results
 * Replaces the normal RankingSubstate for setup testing
 */
class SetupControlsResultSubstate extends MusicBeatSubstate {
    var notesHit:Int;
    var notesMissed:Int;
    var testTime:Float;
    var bg:FlxSprite;
    var resultsText:FlxText;
    var continueText:FlxText;

    public function new(hits:Int, misses:Int, time:Float) {
        super();
        this.notesHit = hits;
        this.notesMissed = misses;
        this.testTime = time;
    }

    override function create() {
        super.create();

        // Create gradient background
        bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF0066CC, 0xFF003366]);
        bg.alpha = 0.9;
        add(bg);

        // Calculate stats
        var totalNotes = notesHit + notesMissed;
        var accuracy = totalNotes > 0 ? Math.round((notesHit / totalNotes) * 100) : 0;
        var timeStr = '${Math.floor(testTime / 60)}:${StringTools.lpad(Std.string(Math.floor(testTime % 60)), "0", 2)}';

        // Results title
        var titleText = new FlxText(0, 100, FlxG.width, "🎮 CONTROL TEST COMPLETE! 🎮");
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Results display
        var resultStr = '✅ Test Results:\\n\\n' +
            '🎯 Notes Hit: $notesHit\\n' +
            '❌ Notes Missed: $notesMissed\\n' +
            '📊 Accuracy: $accuracy%\\n' +
            '⏱️ Test Duration: $timeStr\\n\\n';

        if (accuracy >= 90) {
            resultStr += '🌟 EXCELLENT! Your controls are working perfectly!';
        } else if (accuracy >= 70) {
            resultStr += '👍 GOOD! Your controls are working well!';
        } else if (accuracy >= 50) {
            resultStr += '⚠️ OKAY - You might want to check your control settings.';
        } else {
            resultStr += '🔧 Consider reviewing your control configuration.';
        }

        resultsText = new FlxText(100, 200, FlxG.width - 200, resultStr);
        resultsText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        resultsText.borderSize = 1;
        add(resultsText);

        // Continue instructions
        continueText = new FlxText(0, FlxG.height - 100, FlxG.width,
            "Press ENTER to return to setup | Press SPACE to test again");
        continueText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
        continueText.borderSize = 1;
        add(continueText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE) {
            returnToSetup();
        }

        if (FlxG.keys.justPressed.SPACE) {
            testAgain();
        }
    }

    function returnToSetup() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        if (ClientPrefs.data.setupArchipelagoMode) {
            MusicBeatState.switchState(new ArchipelagoSetupState());
        } else {
            MusicBeatState.switchState(new BasicSettingsSetup());
        }
    }

    function testAgain() {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        close();

        // Reset the test state
        var setupState = cast(FlxG.state, SetupControlsPlayState);
        setupState.readyToStart = false;
        setupState.notesHit = 0;
        setupState.notesMissed = 0;
        setupState.testTimer = 0;

        // Reset song position
        FlxG.sound.music.stop();
        setupState.showInstructions();
    }
}
