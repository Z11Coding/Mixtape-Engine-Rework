package games.uno.beta;

import archipelago.APInfo;
import backend.MusicBeatState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import games.uno.backend.UnoRules;

class APUnoBetaTrapState extends UnoBetaState {
    private var trapBanner:FlxText;
    private var previousState:Class<MusicBeatState>;

    public function new(?previousState:MusicBeatState = null) {
        this.previousState = previousState != null ? Type.getClass(previousState) : null;
        super();
    }

    override function create():Void {
        if (!APInfo.inArchipelagoMode) {
            throw "Error: APUnoBetaTrapState can only be used in Archipelago mode!";
        }

        super.create();

        trapBanner = new FlxText(20, 20, FlxG.width - 40, "ARCHIPELAGO UNO TRAP", 20);
        trapBanner.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(255, 200, 90), CENTER);
        add(trapBanner);

        statusText.text = "Trap active — win this round or lose everything.";
        instructionText.text = "You must finish the round in Archipelago mode. Press R to restart.";

        UnoRules.ALLOW_STACKING = true;
        UnoRules.ALLOW_JUMP_IN = true;
        UnoRules.DRAW_UNTIL_PLAYABLE = false;
        UnoRules.PROGRESSIVE_UNO = false;
        UnoRules.SEVEN_ZERO_RULE = true;
        UnoRules.WILD_DRAW_FOUR_CHALLENGE = true;
        UnoRules.ALLOW_ANY_PLUS_STACK = true;
    }
}
