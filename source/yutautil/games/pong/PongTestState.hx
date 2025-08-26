package yutautil.games.pong;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.MainMenuState;

/**
 * Simple test state for the Pong game
 * Useful for debugging and testing Pong functionality
 */
class PongTestState extends MusicBeatState {
    private var instructionText:FlxText;

    override function create() {
        super.create();

        var bg = new flixel.FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(20, 20, 30));
        add(bg);

        var titleText = new FlxText(0, FlxG.height * 0.3, FlxG.width, "PONG TEST MENU", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        add(titleText);

        instructionText = new FlxText(0, FlxG.height * 0.5, FlxG.width, "", 16);
        instructionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, CENTER);
        add(instructionText);

        updateInstructionText();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Testing Pong", "In Pong Test Menu");
        #end
    }

    private function updateInstructionText():Void {
        instructionText.text = "Press 1: Basic Pong | Press 2: Two Player | Press 3: AI vs AI\n" +
                              "Press 4: Hard AI | Press 5: Expert AI\n" +
                              "Press ENTER: Default Pong | ESCAPE: Back to Menu";
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.BACK) {
            FlxG.switchState(new MainMenuState());
        }

        if (controls.ACCEPT) {
            PongLauncher.launch();
        }

        if (FlxG.keys.justPressed.ONE) {
            PongLauncher.launchWithMode(PLAYER_VS_AI);
        }

        if (FlxG.keys.justPressed.TWO) {
            PongLauncher.launchTwoPlayer();
        }

        if (FlxG.keys.justPressed.THREE) {
            PongLauncher.launchAIDemo();
        }

        if (FlxG.keys.justPressed.FOUR) {
            PongLauncher.launchCustom(PLAYER_VS_AI, HARD);
        }

        if (FlxG.keys.justPressed.FIVE) {
            PongLauncher.launchCustom(PLAYER_VS_AI, EXPERT);
        }
    }
}
