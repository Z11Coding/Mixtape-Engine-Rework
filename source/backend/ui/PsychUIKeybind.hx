package backend.ui;

import flixel.input.keyboard.FlxKey;

class PsychUIKeybind extends FlxSpriteGroup
{
    public static final CLICK_EVENT = "keybind_click";
    public static final CHANGE_EVENT = "keybind_change";

    public var textDisplay:PsychUIInputText;
    public var setButton:PsychUIButton;
    public var variable:String;
    public var isWaitingForInput:Bool = false;

    public var onKeybindChange:String->Void;

    public function new(x:Float, y:Float, name:String, variable:String, ?width:Float = 200)
    {
        super(x, y);

        this.variable = variable;

        // Create text display (read-only by preventing focus)
        textDisplay = new PsychUIInputText(0, 0, Std.int(width * 0.7), getCurrentKeybind());
        textDisplay.bg.color = FlxColor.GRAY;
        add(textDisplay);

        // Create set button
        setButton = new PsychUIButton(textDisplay.width + 5, 0, "Set", function() {
            startWaitingForInput();
        });
        setButton.resize(Std.int(width * 0.25), Std.int(textDisplay.height));
        add(setButton);

        updateDisplay();
    }

    function getCurrentKeybind():String
    {
        var keybind = ClientPrefs.keyBinds.get(variable);
        if (keybind != null && keybind.length > 0) {
            return keybind[0].toString();
        }
        return 'NONE';
    }

    function updateDisplay()
    {
        var currentKey = getCurrentKeybind();
        if (isWaitingForInput) {
            textDisplay.text = '--';
            textDisplay.bg.color = FlxColor.YELLOW;
        } else {
            textDisplay.text = currentKey;
            textDisplay.bg.color = FlxColor.GRAY;
        }
    }

    override function update(elapsed:Float)
    {
        // Prevent text input from getting focus by checking mouse clicks
        if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(textDisplay, camera)) {
            // Redirect focus away from text input
            PsychUIInputText.focusOn = null;
        }

        super.update(elapsed);

        if (isWaitingForInput) {
            // Check for escape to cancel
            if (FlxG.keys.justPressed.ESCAPE) {
                cancelWaitingForInput();
                return;
            }

            // Check for any key input
            var newKey:FlxKey = FlxG.keys.firstJustPressed();

            // Only process if we have a valid key that's not escape
            if (newKey != FlxKey.NONE && newKey != FlxKey.ESCAPE) {
                setKeybind(newKey);
                isWaitingForInput = false;
                updateDisplay();

                // Close the blocking substate
                if (FlxG.state.subState != null) {
                    FlxG.state.closeSubState();
                }

                if (onKeybindChange != null) onKeybindChange(newKey.toString());
                PsychUIEventHandler.event(CHANGE_EVENT, this);
            }
        }
    }

    function startWaitingForInput()
    {
        isWaitingForInput = true;
        updateDisplay();

        // Create an invisible blocking substate to prevent other inputs
        FlxG.state.openSubState(new KeybindCaptureSubstate());

        PsychUIEventHandler.event(CLICK_EVENT, this);
    }

    function cancelWaitingForInput()
    {
        isWaitingForInput = false;
        updateDisplay();

        // Close the blocking substate
        if (FlxG.state.subState != null) {
            FlxG.state.closeSubState();
        }
    }

    function setKeybind(key:FlxKey)
    {
        var keybind = ClientPrefs.keyBinds.get(variable);
        if (keybind != null) {
            keybind[0] = key; // Replace first key
            ClientPrefs.keyBinds.set(variable, keybind);
            ClientPrefs.saveSettings();
        }
    }
}

/**
 * Invisible substate that captures input and prevents other interactions
 */
class KeybindCaptureSubstate extends MusicBeatSubstate
{
    override function create()
    {
        super.create();

        // Make completely transparent but still capture input
        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
        add(bg);
    }

    override function update(elapsed:Float)
    {
        // Don't call super.update to prevent other interactions

        // Close on escape
        if (FlxG.keys.justPressed.ESCAPE) {
            close();
        }
    }
}
