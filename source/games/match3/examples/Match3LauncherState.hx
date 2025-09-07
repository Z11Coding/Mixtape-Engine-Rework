/**
 * Example Integration for Match 3 Game
 *
 * This file shows how to integrate the Match 3 game into the Mixtape Engine.
 *
 * METHOD 1: Add to Main Menu (requires modifying MainMenuState.hx)
 *
 * 1. Add 'match3' to the optionShit array in MainMenuState.hx:
 *    var optionShit:Array<String> = [
 *        'story_mode',
 *        'freeplay',
 *        'match3',        // Add this line
 *        #if MODS_ALLOWED 'mods', #end
 *        'credits'
 *    ];
 *
 * 2. Add the case to the switch statement in MainMenuState.hx:
 *    switch (option) {
 *        case 'story_mode':
 *            MusicBeatState.switchState(new StoryMenuState());
 *        case 'freeplay':
 *            MusicBeatState.switchState(new CategoryState());
 *        case 'match3':
 *            MusicBeatState.switchState(new games.match3.Match3TestState());
 *        // ... rest of cases
 *    }
 *
 * 3. Create menu sprite assets:
 *    - assets/images/mainmenu/menu_match3.png (with idle and selected animations)
 *    - assets/images/mainmenu/menu_match3_dark.png (for dark theme)
 *
 * METHOD 2: Add to Freeplay Menu (easier integration)
 *
 * You can add Match 3 as a "song" in the freeplay menu by modifying the song list.
 * This might be easier and less intrusive than modifying the main menu.
 *
 * METHOD 3: Debug Menu Integration (recommended for testing)
 *
 * Add to DebugStateMenu.hx for easy access during development:
 *
 * var debugMenuOptions = [
 *     // ... existing options
 *     'Match 3 Game'
 * ];
 *
 * And in the switch statement:
 * case 'Match 3 Game':
 *     MusicBeatState.switchState(new games.match3.Match3TestState());
 *
 * METHOD 4: Standalone Launch (simplest)
 *
 * Create a simple button anywhere in your game that calls:
 * games.match3.Match3Integration.launchGame();
 */

package games.match3.examples;

import backend.MusicBeatState;
import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import games.match3.Match3Integration;
import games.match3.backend.Match3Game.GameMode;
import states.MainMenuState;

/**
 * Example state showing how to create a Match 3 launcher menu
 */
class Match3LauncherState extends MusicBeatState {

    override public function create():Void {
        super.create();

        // Background
        var bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(25, 25, 40));
        add(bg);

        // Title
        var title = new FlxText(0, 50, FlxG.width, "Match 3 Game Modes");
        title.setFormat(null, 32, FlxColor.WHITE, CENTER);
        add(title);

        // Game mode buttons
        var buttonY = 150;
        var buttonSpacing = 60;

        var classicButton = new PsychUIButton(FlxG.width / 2 - 100, buttonY, "Classic Mode", function() {
            Match3Integration.launchGameMode(CLASSIC);
        });
        classicButton.resize(200, 40);
        add(classicButton);

        var vsButton = new PsychUIButton(FlxG.width / 2 - 100, buttonY + buttonSpacing, "VS Computer", function() {
            Match3Integration.launchGameMode(VS_CPU);
        });
        vsButton.resize(200, 40);
        add(vsButton);

        var timedButton = new PsychUIButton(FlxG.width / 2 - 100, buttonY + buttonSpacing * 2, "Time Attack", function() {
            Match3Integration.launchGameMode(TIMED);
        });
        timedButton.resize(200, 40);
        add(timedButton);

        var obstacleButton = new PsychUIButton(FlxG.width / 2 - 100, buttonY + buttonSpacing * 3, "Clear Obstacles", function() {
            Match3Integration.launchGameMode(OBSTACLES);
        });
        obstacleButton.resize(200, 40);
        add(obstacleButton);

        var puzzleButton = new PsychUIButton(FlxG.width / 2 - 100, buttonY + buttonSpacing * 4, "Puzzle Mode", function() {
            Match3Integration.launchGameMode(MOVES_LIMITED);
        });
        puzzleButton.resize(200, 40);
        add(puzzleButton);

        // Back button
        var backButton = new PsychUIButton(50, FlxG.height - 80, "Back", function() {
            FlxG.switchState(new MainMenuState());
        });
        backButton.resize(100, 40);
        add(backButton);

        // Instructions
        var instructions = new FlxText(20, FlxG.height - 150, FlxG.width - 40,
            "Match 3 or more pieces to score points!\n" +
            "Create special pieces by matching 4+ pieces.\n" +
            "Complete objectives to win!");
        instructions.setFormat(null, 14, FlxColor.GRAY, CENTER);
        add(instructions);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (controls.BACK) {
            FlxG.switchState(new MainMenuState());
        }
    }
}
