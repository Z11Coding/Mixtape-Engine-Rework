package archipelago;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.Alphabet;

/**
 * Math Problem Trap Substate
 * Displays a math problem that the player must solve or take damage
 */
class APMathProblemSubstate extends MusicBeatSubstate {
    private var problemText:String;
    private var correctAnswer:Int;
    private var onComplete:Bool->Void;
    private var timeLimit:Float = 10.0; // Default 10 seconds to answer

    private var bg:FlxSprite;
    private var titleText:FlxText;
    private var problemDisplay:FlxText;
    private var answerText:FlxText;
    private var inputAnswer:String = "";
    private var timerText:FlxText;
    private var timeLeft:Float;
    private var countdownTimer:FlxTimer;

    private var instructionText:FlxText;
    private var submitted:Bool = false;

    public function new(problemText:String, correctAnswer:Int, onComplete:Bool->Void, ?timeLimit:Float = 10.0) {
        super();
        this.problemText = problemText;
        this.correctAnswer = correctAnswer;
        this.onComplete = onComplete;
        this.timeLimit = timeLimit;
        this.timeLeft = timeLimit;
    }

    override function create() {
        super.create();

        // Pause the game if we're in PlayState
        if (Std.is(FlxG.state, states.PlayState)) {
            var playState = cast(FlxG.state, states.PlayState);
            playState.paused = true;
            playState.vocals?.pause();
            // Pause any other sounds
            playState.gfVocals?.pause();
            playState.opponentVocals?.pause();

            if (FlxG.sound.music != null) {
                FlxG.sound.music.pause();
            }
        }

        // Semi-transparent background
        bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.8));
        add(bg);

        // Title
        titleText = new FlxText(0, 100, FlxG.width, "MATH PROBLEM TRAP!");
        titleText.setFormat(null, 32, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Problem display
        problemDisplay = new FlxText(0, 200, FlxG.width, problemText);
        problemDisplay.setFormat(null, 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        problemDisplay.borderSize = 2;
        add(problemDisplay);

        // Answer input display
        answerText = new FlxText(0, 300, FlxG.width, "Your Answer: _");
        answerText.setFormat(null, 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        answerText.borderSize = 2;
        add(answerText);

        // Timer display
        timerText = new FlxText(0, 400, FlxG.width, 'Time Left: ${Math.ceil(timeLeft)}s');
        timerText.setFormat(null, 20, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
        timerText.borderSize = 2;
        add(timerText);

        // Instructions
        instructionText = new FlxText(0, 500, FlxG.width, "Type your answer and press ENTER to submit\\nPress ESCAPE to give up (takes damage)");
        instructionText.setFormat(null, 16, FlxColor.LIME, CENTER, OUTLINE, FlxColor.BLACK);
        instructionText.borderSize = 1;
        add(instructionText);

        // Add some visual flair
        var warningText = new FlxText(0, 50, FlxG.width, "⚠ WARNING ⚠");
        warningText.setFormat(null, 24, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.RED);
        warningText.borderSize = 2;
        add(warningText);

        // Start countdown timer
        countdownTimer = new FlxTimer().start(0.1, updateTimer, Math.ceil(timeLimit * 10));
    }

    private function updateTimer(timer:FlxTimer):Void {
        if (submitted) return;

        timeLeft -= 0.1;
        timerText.text = 'Time Left: ${Math.ceil(timeLeft)}s';

        // Change color as time runs out
        if (timeLeft <= 3) {
            timerText.color = FlxColor.RED;
        } else if (timeLeft <= 5) {
            timerText.color = FlxColor.ORANGE;
        }

        if (timeLeft <= 0) {
            timeUp();
        }
    }

    private function timeUp():Void {
        if (submitted) return;
        submitted = true;

        // Time's up - wrong answer
        onComplete(false);
        close();
    }

    private function submitAnswer():Void {
        if (submitted) return;
        submitted = true;

        if (countdownTimer != null) {
            countdownTimer.cancel();
        }

        var playerAnswer = Std.parseInt(inputAnswer);
        var isCorrect = (playerAnswer == correctAnswer);

        onComplete(isCorrect);
        close();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (submitted) return;

        // Handle number input
        var pressedKey = FlxG.keys.firstJustPressed();
        if (pressedKey != FlxKey.NONE) {
            var keyName = FlxKey.toStringMap.get(pressedKey);

            // Handle number keys (0-9)
            if (keyName.length == 1 && keyName >= "0" && keyName <= "9") {
                if (inputAnswer.length < 6) { // Limit input length
                    inputAnswer += keyName;
                    updateAnswerDisplay();
                }
            }
            // Handle negative numbers (minus sign)
            else if (pressedKey == FlxKey.MINUS && inputAnswer.length == 0) {
                inputAnswer = "-";
                updateAnswerDisplay();
            }
            // Handle backspace
            else if (pressedKey == FlxKey.BACKSPACE && inputAnswer.length > 0) {
                inputAnswer = inputAnswer.substr(0, inputAnswer.length - 1);
                updateAnswerDisplay();
            }
        }

        // Submit answer
        if (FlxG.keys.justPressed.ENTER && inputAnswer.length > 0) {
            submitAnswer();
        }

        // Give up (take damage)
        if (FlxG.keys.justPressed.ESCAPE) {
            if (submitted) return;
            submitted = true;

            if (countdownTimer != null) {
                countdownTimer.cancel();
            }

            onComplete(false);
            close();
        }
    }

    private function updateAnswerDisplay():Void {
        answerText.text = "Your Answer: " + (inputAnswer.length > 0 ? inputAnswer : "_");
    }

    override function close():Void {
        // Resume the game if we were in PlayState
        if (Std.is(FlxG.state, states.PlayState)) {
            var playState = cast(FlxG.state, states.PlayState);
            playState.paused = false;
            playState.vocals?.resume();
            // Resume any other sounds
            playState.gfVocals?.resume();
            playState.opponentVocals?.resume();
            if (FlxG.sound.music != null) {
                FlxG.sound.music.resume();
            }
        }

        if (countdownTimer != null) {
            countdownTimer.cancel();
        }

        super.close();
    }
}
