package yutautil.games.pong;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ui.PsychUIButton;

/**
 * Controls mapping substate for single-player Pong
 */
class PongControlsSubstate extends FlxSubState {
    private var bgSprite:FlxSprite;
    private var titleText:FlxText;
    private var instructionText:FlxText;
    private var closeButton:PsychUIButton;

    // Control mapping variables
    private var upKeyText:FlxText;
    private var downKeyText:FlxText;
    private var dashKeyText:FlxText;

    private var currentlyMapping:String = "";
    private var dashEnabled:Bool;

    // Current key mappings
    private var upKey:FlxKey = FlxKey.W;
    private var downKey:FlxKey = FlxKey.S;
    private var dashKey:FlxKey = FlxKey.A;

    public function new(dashEnabled:Bool = false) {
        super();
        this.dashEnabled = dashEnabled;

        // Load saved key mappings if they exist
        loadKeyMappings();
    }

    override function create():Void {
        super.create();

        // Semi-transparent background
        bgSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bgSprite.alpha = 0.7;
        add(bgSprite);

        // Title
        titleText = new FlxText(0, 50, FlxG.width, "Left Paddle Controls", 32);
        titleText.setFormat(null, 32, FlxColor.WHITE, CENTER);
        add(titleText);

        // Instructions
        var instructionStr = "Click on a control to remap it\nPress ESCAPE or click Close to exit";
        instructionText = new FlxText(0, 100, FlxG.width, instructionStr, 18);
        instructionText.setFormat(null, 18, FlxColor.GRAY, CENTER);
        add(instructionText);

        // Control mappings
        var startY = 180;
        var spacing = 60;

        // Up key
        var upLabel = new FlxText(FlxG.width * 0.3, startY, 200, "Move Up:", 20);
        upLabel.setFormat(null, 20, FlxColor.WHITE, LEFT);
        add(upLabel);

        upKeyText = new FlxText(FlxG.width * 0.5, startY, 200, getKeyName(upKey), 20);
        upKeyText.setFormat(null, 20, FlxColor.CYAN, LEFT);
        add(upKeyText);

        // Down key
        var downLabel = new FlxText(FlxG.width * 0.3, startY + spacing, 200, "Move Down:", 20);
        downLabel.setFormat(null, 20, FlxColor.WHITE, LEFT);
        add(downLabel);

        downKeyText = new FlxText(FlxG.width * 0.5, startY + spacing, 200, getKeyName(downKey), 20);
        downKeyText.setFormat(null, 20, FlxColor.CYAN, LEFT);
        add(downKeyText);

        // Dash key (only if enabled)
        if (dashEnabled) {
            var dashLabel = new FlxText(FlxG.width * 0.3, startY + spacing * 2, 200, "Dash:", 20);
            dashLabel.setFormat(null, 20, FlxColor.WHITE, LEFT);
            add(dashLabel);

            dashKeyText = new FlxText(FlxG.width * 0.5, startY + spacing * 2, 200, getKeyName(dashKey), 20);
            dashKeyText.setFormat(null, 20, FlxColor.CYAN, LEFT);
            add(dashKeyText);
        }

        // Close button
        closeButton = new PsychUIButton(FlxG.width * 0.5 - 50, FlxG.height - 100, "Close", function() {
            saveKeyMappings();
            close();
        }, 100, 40);
        add(closeButton);

        // Update paddle controls immediately
        updatePaddleControls();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle ESC key
        if (FlxG.keys.justPressed.ESCAPE && currentlyMapping == "") {
            saveKeyMappings();
            close();
        }

        // Handle key remapping
        if (currentlyMapping != "") {
            handleKeyMapping();
        } else {
            // Handle clicking on controls to remap them
            if (FlxG.mouse.justPressed) {
                var mouseY = FlxG.mouse.y;

                if (mouseY >= upKeyText.y && mouseY <= upKeyText.y + upKeyText.height) {
                    startMapping("up");
                } else if (mouseY >= downKeyText.y && mouseY <= downKeyText.y + downKeyText.height) {
                    startMapping("down");
                } else if (dashEnabled && dashKeyText != null && mouseY >= dashKeyText.y && mouseY <= dashKeyText.y + dashKeyText.height) {
                    startMapping("dash");
                }
            }
        }
    }

    private function startMapping(control:String):Void {
        currentlyMapping = control;

        switch (control) {
            case "up":
                upKeyText.text = "Press key...";
                upKeyText.color = FlxColor.YELLOW;
            case "down":
                downKeyText.text = "Press key...";
                downKeyText.color = FlxColor.YELLOW;
            case "dash":
                if (dashKeyText != null) {
                    dashKeyText.text = "Press key...";
                    dashKeyText.color = FlxColor.YELLOW;
                }
        }

        instructionText.text = "Press a key to map it, or ESC to cancel";
    }

    private function handleKeyMapping():Void {
        var pressedKey:FlxKey = FlxG.keys.firstJustPressed();

        if (pressedKey == FlxKey.ESCAPE) {
            // Cancel mapping
            cancelMapping();
            return;
        }

        if (pressedKey != FlxKey.NONE) {
            // Check if key is already used
            if ((pressedKey == upKey && currentlyMapping != "up") ||
                (pressedKey == downKey && currentlyMapping != "down") ||
                (pressedKey == dashKey && currentlyMapping != "dash")) {
                // Key already in use, show error briefly
                instructionText.text = "Key already in use! Choose another key.";
                instructionText.color = FlxColor.RED;

                new flixel.util.FlxTimer().start(1.5, function(timer) {
                    instructionText.text = "Click on a control to remap it\nPress ESCAPE or click Close to exit";
                    instructionText.color = FlxColor.GRAY;
                });
                return;
            }

            // Apply the new mapping
            switch (currentlyMapping) {
                case "up":
                    upKey = pressedKey;
                    upKeyText.text = getKeyName(upKey);
                    upKeyText.color = FlxColor.CYAN;
                case "down":
                    downKey = pressedKey;
                    downKeyText.text = getKeyName(downKey);
                    downKeyText.color = FlxColor.CYAN;
                case "dash":
                    dashKey = pressedKey;
                    if (dashKeyText != null) {
                        dashKeyText.text = getKeyName(dashKey);
                        dashKeyText.color = FlxColor.CYAN;
                    }
            }

            currentlyMapping = "";
            instructionText.text = "Click on a control to remap it\nPress ESCAPE or click Close to exit";
            instructionText.color = FlxColor.GRAY;

            // Update paddle controls immediately
            updatePaddleControls();
        }
    }

    private function cancelMapping():Void {
        switch (currentlyMapping) {
            case "up":
                upKeyText.text = getKeyName(upKey);
                upKeyText.color = FlxColor.CYAN;
            case "down":
                downKeyText.text = getKeyName(downKey);
                downKeyText.color = FlxColor.CYAN;
            case "dash":
                if (dashKeyText != null) {
                    dashKeyText.text = getKeyName(dashKey);
                    dashKeyText.color = FlxColor.CYAN;
                }
        }

        currentlyMapping = "";
        instructionText.text = "Click on a control to remap it\nPress ESCAPE or click Close to exit";
        instructionText.color = FlxColor.GRAY;
    }

    private function getKeyName(key:FlxKey):String {
        // Convert FlxKey enum to readable string
        return switch (key) {
            case FlxKey.W: "W";
            case FlxKey.A: "A";
            case FlxKey.S: "S";
            case FlxKey.D: "D";
            case FlxKey.UP: "UP";
            case FlxKey.DOWN: "DOWN";
            case FlxKey.LEFT: "LEFT";
            case FlxKey.RIGHT: "RIGHT";
            case FlxKey.SPACE: "SPACE";
            case FlxKey.SHIFT: "SHIFT";
            case FlxKey.CONTROL: "CTRL";
            case FlxKey.ALT: "ALT";
            case FlxKey.TAB: "TAB";
            case FlxKey.ENTER: "ENTER";
            default: Std.string(key);
        }
    }

    private function updatePaddleControls():Void {
        // This would update the actual paddle control mappings
        // For now, we'll store them in FlxG.save for persistence
        FlxG.save.data.pongLeftUpKey = upKey;
        FlxG.save.data.pongLeftDownKey = downKey;
        FlxG.save.data.pongLeftDashKey = dashKey;
        FlxG.save.flush();
    }

    private function loadKeyMappings():Void {
        if (FlxG.save.data.pongLeftUpKey != null) {
            upKey = FlxG.save.data.pongLeftUpKey;
        }
        if (FlxG.save.data.pongLeftDownKey != null) {
            downKey = FlxG.save.data.pongLeftDownKey;
        }
        if (FlxG.save.data.pongLeftDashKey != null) {
            dashKey = FlxG.save.data.pongLeftDashKey;
        }
    }

    private function saveKeyMappings():Void {
        updatePaddleControls();
    }
}
