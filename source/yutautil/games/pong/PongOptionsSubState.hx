package yutautil.games.pong;

import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import substates.MusicBeatSubstate;
import yutautil.games.pong.backend.PongGame.PongGameMode;
import yutautil.games.pong.backend.PongPaddle.PongAIDifficulty;

/**
 * Options/Settings substate for Pong game
 */
class PongOptionsSubState extends MusicBeatSubstate {
    // UI elements
    private var bgSprite:FlxSprite;
    private var titleText:FlxText;
    private var optionTexts:FlxTypedGroup<FlxText>;
    private var buttons:FlxTypedGroup<PsychUIButton>;

    // Settings
    public var gameMode:PongGameMode = PLAYER_VS_AI;
    public var aiDifficulty:PongAIDifficulty = NORMAL;
    public var maxScore:Int = 10;
    public var ballSpeed:Float = 200;
    public var paddleSpeed:Float = 350;
    public var gameSpeed:Float = 1.0;
    public var soundEnabled:Bool = true;

    // GOD mode unlock status
    public var godModeUnlocked:Bool = true;

    // Callbacks
    public var onSettingsChanged:Void->Void;
    public var onGameModeChanged:PongGameMode->Void;
    public var onAIDifficultyChanged:PongAIDifficulty->Void;

    // Current selection
    private var selectedOption:Int = 0;
    private var maxOptions:Int = 8;

    override function create() {
        super.create();

        setupBackground();
        setupUI();
    }

    private function setupBackground():Void {
        bgSprite = new FlxSprite();
        bgSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.7));
        add(bgSprite);
    }

    private function setupUI():Void {
        // Title
        titleText = new FlxText(0, 50, FlxG.width, "PONG OPTIONS", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        add(titleText);

        // Options
        optionTexts = new FlxTypedGroup<FlxText>();
        buttons = new FlxTypedGroup<PsychUIButton>();

        var startY = 150;
        var ySpacing = 60;

        // Game Mode
        createOptionRow("Game Mode:", getGameModeName(gameMode), 0, startY + 0 * ySpacing,
            function() { cycleGameMode(); });

        // AI Difficulty
        createOptionRow("AI Difficulty:", getDifficultyName(aiDifficulty), 1, startY + 1 * ySpacing,
            function() { cycleAIDifficulty(); });

        // Max Score
        createOptionRow("Max Score:", Std.string(maxScore), 2, startY + 2 * ySpacing,
            function() { cycleMaxScore(); });

        // Ball Speed
        createOptionRow("Ball Speed:", getSpeedName(ballSpeed), 3, startY + 3 * ySpacing,
            function() { cycleBallSpeed(); });

        // Paddle Speed
        createOptionRow("Paddle Speed:", getSpeedName(paddleSpeed), 4, startY + 4 * ySpacing,
            function() { cyclePaddleSpeed(); });

        // Game Speed
        createOptionRow("Game Speed:", getGameSpeedName(gameSpeed), 5, startY + 5 * ySpacing,
            function() { cycleGameSpeed(); });

        // Sound
        createOptionRow("Sound Effects:", soundEnabled ? "ON" : "OFF", 6, startY + 6 * ySpacing,
            function() { soundEnabled = !soundEnabled; updateOptionText(6, soundEnabled ? "ON" : "OFF"); });

        // Controls info
        var controlsText = new FlxText(0, startY + 7 * ySpacing, FlxG.width, "Controls: Left: W/S | Right: Arrow Keys | P: Pause", 16);
        controlsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, CENTER);
        add(controlsText);

        add(optionTexts);
        add(buttons);

        updateSelection();
    }

    private function createOptionRow(label:String, value:String, index:Int, y:Float, onClick:Void->Void):Void {
        var labelText = new FlxText(FlxG.width * 0.25, y, 300, label, 20);
        labelText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
        optionTexts.add(labelText);

        var valueText = new FlxText(FlxG.width * 0.55, y, 300, value, 20);
        valueText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.YELLOW, LEFT);
        optionTexts.add(valueText);

        var button = new PsychUIButton(FlxG.width * 0.75, y - 5, "Change", onClick);
        button.resize(100, 30);
        buttons.add(button);
    }

    private function updateOptionText(optionIndex:Int, newValue:String):Void {
        var textIndex = (optionIndex * 2) + 1; // Each option has label + value
        if (textIndex < optionTexts.length && optionTexts.members[textIndex] != null) {
            optionTexts.members[textIndex].text = newValue;
        }
    }

    private function cycleGameMode():Void {
        gameMode = switch (gameMode) {
            case PLAYER_VS_AI: TWO_PLAYER;
            case TWO_PLAYER: AI_VS_AI;
            case AI_VS_AI: PLAYER_VS_AI;
        };
        updateOptionText(0, getGameModeName(gameMode));

        if (onGameModeChanged != null) {
            onGameModeChanged(gameMode);
        }
    }

    private function cycleAIDifficulty():Void {
        aiDifficulty = switch (aiDifficulty) {
            case EASY: NORMAL;
            case NORMAL: HARD;
            case HARD: EXPERT;
            case EXPERT: YES;
            case YES:
                if (godModeUnlocked) {
                    GOD;
                } else {
                    EASY; // Skip GOD if not unlocked, go back to EASY
                }
            case GOD: EASY;
        };
        updateOptionText(1, getDifficultyName(aiDifficulty));

        if (onAIDifficultyChanged != null) {
            onAIDifficultyChanged(aiDifficulty);
        }
    }

    private function cycleMaxScore():Void {
        var scores = [5, 10, 15, 21];
        var currentIndex = scores.indexOf(maxScore);
        maxScore = scores[(currentIndex + 1) % scores.length];
        updateOptionText(2, Std.string(maxScore));
    }

    private function cycleBallSpeed():Void {
        var speeds = [150.0, 200.0, 250.0, 300.0, 400.0];
        var currentIndex = speeds.indexOf(ballSpeed);
        ballSpeed = speeds[(currentIndex + 1) % speeds.length];
        updateOptionText(3, getSpeedName(ballSpeed));
    }

    private function cyclePaddleSpeed():Void {
        var speeds = [250.0, 300.0, 350.0, 400.0, 500.0];
        var currentIndex = speeds.indexOf(paddleSpeed);
        paddleSpeed = speeds[(currentIndex + 1) % speeds.length];
        updateOptionText(4, getSpeedName(paddleSpeed));
    }

    private function cycleGameSpeed():Void {
        var speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
        var currentIndex = speeds.indexOf(gameSpeed);
        gameSpeed = speeds[(currentIndex + 1) % speeds.length];
        updateOptionText(5, getGameSpeedName(gameSpeed));
    }

    private function getGameModeName(mode:PongGameMode):String {
        return switch (mode) {
            case PLAYER_VS_AI: "Player vs AI";
            case TWO_PLAYER: "Two Player";
            case AI_VS_AI: "AI vs AI";
        };
    }

    private function getDifficultyName(difficulty:PongAIDifficulty):String {
        return switch (difficulty) {
            case EASY: "Easy";
            case NORMAL: "Normal";
            case HARD: "Hard";
            case EXPERT: "Expert";
            case YES: "Yes (Advanced)";
            case GOD:
                if (godModeUnlocked) {
                    "GOD MODE";
                } else {
                    "??? (LOCKED)";
                }
        };
    }

    private function getSpeedName(speed:Float):String {
        if (speed <= 150) return "Very Slow";
        if (speed <= 200) return "Slow";
        if (speed <= 250) return "Normal";
        if (speed <= 300) return "Fast";
        if (speed <= 400) return "Very Fast";
        return "Extreme";
    }

    private function getGameSpeedName(speed:Float):String {
        if (speed <= 0.5) return "Half Speed";
        if (speed <= 0.75) return "Slow";
        if (speed <= 1.0) return "Normal";
        if (speed <= 1.25) return "Fast";
        if (speed <= 1.5) return "Very Fast";
        return "Double Speed";
    }

    private function updateSelection():Void {
        // Could add visual selection indicator here if needed
        // For now, buttons handle their own hover states
    }

    private function applySettings():Void {
        if (onSettingsChanged != null) {
            onSettingsChanged();
        }
        close();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle keyboard navigation
        if (controls.UI_UP_P) {
            selectedOption = selectedOption > 0 ? selectedOption - 1 : maxOptions - 1;
            updateSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        }

        if (controls.UI_DOWN_P) {
            selectedOption = selectedOption < maxOptions - 1 ? selectedOption + 1 : 0;
            updateSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        }

        if (controls.ACCEPT) {
            // Trigger the selected option's function
            var buttonIndex = selectedOption < buttons.length ? selectedOption : -1;
            if (buttonIndex >= 0 && buttons.members[buttonIndex] != null) {
                buttons.members[buttonIndex].onClicked();
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
            }
        }

        if (controls.BACK) {
            applySettings();
            FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
        }
    }
}
