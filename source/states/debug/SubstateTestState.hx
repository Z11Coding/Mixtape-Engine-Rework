package states.debug;

import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.Alphabet;
import states.DebugStateMenu;

/**
 * Special state for testing MusicBeatSubstates safely
 * Handles errors gracefully and returns to debug menu when substates close
 */
class SubstateTestState extends MusicBeatState {
    private var substateName:String;
    private var substateClass:Class<MusicBeatSubstate>;
    private var statusText:FlxText;
    private var instructionText:FlxText;
    private var errorText:FlxText;
    private var substateActive:Bool = false;
    private var autoCloseTimer:FlxTimer;

    public function new(substateName:String, substateClass:Class<MusicBeatSubstate>) {
        super();
        this.substateName = substateName;
        this.substateClass = substateClass;
    }

    override function create() {
        super.create();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Testing Substate", substateName);
        #end

        setupBackground();
        setupUI();
        attemptToOpenSubstate();
    }

    private function setupBackground():Void {
        // Dark background with slight tint to distinguish from normal states
        var bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(15, 20, 25));
        add(bg);

        // Add subtle pattern to show this is a test environment
        for (i in 0...10) {
            var line = new FlxSprite(0, i * (FlxG.height / 10));
            line.makeGraphic(FlxG.width, 1, FlxColor.fromRGBFloat(1, 1, 1, 0.05));
            add(line);
        }
    }

    private function setupUI():Void {
        // Title
        var titleText = new FlxText(0, 20, FlxG.width, "SUBSTATE TEST ENVIRONMENT", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER);
        add(titleText);

        // Status
        statusText = new FlxText(0, 60, FlxG.width, "Testing: " + substateName, 18);
        statusText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
        add(statusText);

        // Instructions
        instructionText = new FlxText(0, FlxG.height - 100, FlxG.width,
            "The substate will open automatically.\nPress ESC to return to Debug Menu if substate doesn't open.", 14);
        instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.YELLOW, CENTER);
        add(instructionText);

        // Error text (initially hidden)
        errorText = new FlxText(20, FlxG.height / 2, FlxG.width - 40, "", 16);
        errorText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, CENTER);
        errorText.visible = false;
        add(errorText);
    }

    private function attemptToOpenSubstate():Void {
        statusText.text = "Opening substate: " + substateName;

        try {
            // Attempt to create the substate instance
            var substateInstance = Type.createInstance(substateClass, []);

            if (substateInstance != null && Std.isOfType(substateInstance, MusicBeatSubstate)) {
                substateActive = true;
                statusText.text = "Substate opened successfully";
                instructionText.text = "Substate is active. It will close automatically or you can interact with it normally.";

                // Setup auto-close timer as safety measure
                autoCloseTimer = new FlxTimer();
                autoCloseTimer.start(30.0, function(timer) {
                    if (substateActive) {
                        closeSubState();
                        showAutoCloseMessage();
                    }
                });

                openSubState(cast substateInstance);
            } else {
                showError("Failed to create substate instance or instance is not a MusicBeatSubstate");
            }
        } catch (e:Dynamic) {
            showError("Exception while creating substate: " + Std.string(e));
        }
    }

    private function showError(message:String):Void {
        statusText.text = "ERROR: Failed to open substate";
        errorText.text = "Error Details:\n" + message + "\n\nPress ESC to return to Debug Menu";
        errorText.visible = true;
        instructionText.visible = false;
    }

    private function showAutoCloseMessage():Void {
        statusText.text = "Substate auto-closed (30s timeout)";
        instructionText.text = "Substate was automatically closed after 30 seconds.\nPress ESC to return to Debug Menu.";
        substateActive = false;
    }

    override function closeSubState():Void {
        super.closeSubState();
        substateActive = false;

        if (autoCloseTimer != null) {
            autoCloseTimer.cancel();
            autoCloseTimer = null;
        }

        statusText.text = "Substate closed";
        instructionText.text = "Substate has been closed.\nPress ESC to return to Debug Menu or ENTER to test again.";
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Only handle input if no substate is active
        if (!substateActive) {
            if (controls.BACK) {
                returnToDebugMenu();
            }

            if (controls.ACCEPT && !errorText.visible) {
                // Try to open the substate again
                attemptToOpenSubstate();
            }
        }
    }

    private function returnToDebugMenu():Void {
        if (autoCloseTimer != null) {
            autoCloseTimer.cancel();
            autoCloseTimer = null;
        }

        MusicBeatState.switchState(new DebugStateMenu());
    }

    override function destroy() {
        if (autoCloseTimer != null) {
            autoCloseTimer.cancel();
            autoCloseTimer = null;
        }
        super.destroy();
    }
}
