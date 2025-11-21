package backend.ui;

import flixel.input.keyboard.FlxKey;

class PsychUIKeybindButton extends FlxSpriteGroup
{
    public static final CLICK_EVENT = "keybind_click";
    public static final CHANGE_EVENT = "keybind_change";

    public var bg:FlxSprite;
    public var text:FlxText;
    public var variable:String;
    public var isWaitingForInput:Bool = false;

    public var onKeybindChange:String->Void;

    public function new(x:Float, y:Float, name:String, variable:String)
    {
        super(x, y);

        this.variable = variable;

        bg = new FlxSprite().makeGraphic(120, 20, FlxColor.WHITE);
        bg.color = FlxColor.BLACK;
        bg.alpha = 0.6;
        add(bg);

        text = new FlxText(2, 2, bg.width - 4, name + ': ' + getCurrentKeybind());
        text.color = FlxColor.WHITE;
        text.alignment = CENTER;
        add(text);

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
            text.text = text.text.split(':')[0] + ': --';
            bg.color = FlxColor.YELLOW;
        } else {
            text.text = text.text.split(':')[0] + ': ' + currentKey;
            bg.color = FlxColor.BLACK;
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg, camera)) {
            if (!isWaitingForInput) {
                startWaitingForInput();
            }
        }

        if (isWaitingForInput) {
            // Check for escape to cancel
            if (FlxG.keys.justPressed.ESCAPE) {
                cancelWaitingForInput();
                return;
            }

            // Check for any key input
            var newKey:FlxKey = null;

            // Check for keyboard input
            for (key in FlxG.keys.getIsDown()) {
                if (key != FlxKey.ESCAPE) {
                    newKey = key;
                    break;
                }
            }

            if (newKey != null) {
                setKeybind(newKey);
                isWaitingForInput = false;
                updateDisplay();

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
