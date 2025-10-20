package archipelago.traps.games;

import archipelago.substates.InfoPanelSubstate;
import archipelago.traps.TrapDeathHandler;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.uno.UnoTestState;
import games.uno.backend.*;
import games.uno.backend.UnoCPU.UnoDifficulty;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoCard;
import games.uno.backend.UnoGame;
import games.uno.backend.UnoPlayer;
import games.uno.backend.UnoRules;
import stages.StageData;

/**
 * Archipelago UNO Trap State
 * Extends UnoTestState and modifies behavior for trap functionality
 * Player must win the round to survive, losing results in forced death
 * Features randomized UNO rules for extra challenge
 */
class APUnoTrapState extends UnoTestState {

    // Trap-specific properties
    private var previousState:Class<MusicBeatState>;
    private var trapInfoText:FlxText;

    public function new(?previousState:MusicBeatState = null) {
        this.previousState = Type.getClass(previousState);
        super();
    }

    override function create() {

        if (!archipelago.APEntryState.inArchipelagoMode)
            throw "Error: APUnoTrapState can only be used in Archipelago mode!";

        super.create();

        // Add trap warning UI
        addTrapWarningUI();

        // Start the game immediately
        startTrapGame();
    }

    override function setupGame():Void {
        try {
            // Create custom Pong-UNO cards (10% chance to include them)
            var customCards:Array<UnoCard> = [];
            if (FlxG.random.bool(10)) { // 10% chance
                // Create 4 Pong-UNO cards as wild cards
                for (i in 0...4) {
                    var pongCard = UnoCard.createCustomActionCard(
                        "Pong Battle",
                        UnoColor.WILD,
                        75,
                        8,
                        triggerPongBattle
                    );
                    customCards.push(pongCard);
                }
                trace("Added 4 Pong-UNO cards to AP trap deck!");
            }

            // Get any custom UNO colors from AP slot data
            var unoColors = APItem.unoColorsUnlocked;

            var unoColorsWithInt = [for (colorInfo in unoColors) {
                var colorInt = FlxColor.fromString('#${colorInfo.color_code}');
                {name: colorInfo.name, color: colorInt};
            }];
            var usableColors:Array<UnoColor> = [];


            usableColors = (UnoCard.createCustomColorsFromObjects(unoColorsWithInt));

            // If none unlocked, use gray.
            if (usableColors.length == 0) {
                usableColors = [UnoColor.CUSTOM(FlxColor.GRAY, "Gray")];
            }

            // Create UNO game with custom cards
            unoGame = new UnoGame(usableColors, false, customCards.length > 0 ? customCards : null);

            // Randomize UNO rules for the trap
            randomizeUnoRules();

            setupGameEvents();

            // Override the game end callback for trap behavior
            if (unoGame != null) {
                unoGame.onGameEnd = (winner:UnoPlayer) -> {
                    isGameStarted = false;
                    if (winner.isHuman) {
                        // Player won - return to previous state
                        updateInstructionText("YOU WON THE UNO TRAP! Returning to game...");
                        new FlxTimer().start(2.0, function(timer) {
                            archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.None;
                            // Save AP Data.
                                APEntryState.apGame.updateSaveData();
                            if (previousState != null) {
                                LoadingState.loadAndSwitchState(Type.createInstance(previousState, []));
                            } else {
                                StageData.loadDirectory(PlayState.SONG);
							    LoadingState.loadAndSwitchState(new archipelago.APPlayState());
                            }
                        });
                    } else {
                        // Player lost - force death
                        updateInstructionText("AI WINS UNO! PREPARE TO DIE!");
                        new FlxTimer().start(2.0, function(timer) {
                            archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.None;
                            // Save AP Data.
                                APEntryState.apGame.updateSaveData();
                            TrapDeathHandler.forceDeath("Lost UNO Challenge");
                        });
                    }
                };
            }

            trace("AP UNO trap game initialized successfully with randomized rules");

            // Show rules info after setup is complete
            showRulesInfoPanel();

        } catch (e:Dynamic) {
            trace("Error initializing AP UNO trap game: " + e);
            updateInstructionText("Error initializing trap game: " + Std.string(e));
        }
    }

    private function randomizeUnoRules():Void {
        // Randomly enable/disable various UNO rules for challenge
        UnoRules.ALLOW_STACKING = FlxG.random.bool(60); // 60% chance for stacking
        UnoRules.ALLOW_JUMP_IN = FlxG.random.bool(30); // 30% chance for jump-in
        UnoRules.DRAW_UNTIL_PLAYABLE = FlxG.random.bool(1); // 1% chance because OH MY GOD is this awful sometimes
        UnoRules.PROGRESSIVE_UNO = FlxG.random.bool(20); // 20% chance for progressive UNO
        UnoRules.SEVEN_ZERO_RULE = FlxG.random.bool(0); // 0% chance for 7-0 rule, as it's currently  broken.
        UnoRules.WILD_DRAW_FOUR_CHALLENGE = FlxG.random.bool(80); // 80% chance for challenges
        UnoRules.ALLOW_ANY_PLUS_STACK = FlxG.random.bool(50); // 50% chance for any plus stacking
        UnoRules.WINNING_SCORE = 1; // First to get any amount of points wins

        trace("APUnoTrap: Randomized rules - Stacking:" + UnoRules.ALLOW_STACKING +
              " JumpIn:" + UnoRules.ALLOW_JUMP_IN +
              " DrawUntilPlayable:" + UnoRules.DRAW_UNTIL_PLAYABLE +
              " SevenZero:" + UnoRules.SEVEN_ZERO_RULE);
    }

    private function addTrapWarningUI():Void {
        // Add prominent trap warning at the top
        trapInfoText = new FlxText(10, 10, FlxG.width - 20, "⚠️ ARCHIPELAGO TRAP ⚠️\nWin this UNO round to survive! Losing means DEATH!\nRules have been randomized!", 18);
        trapInfoText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.RED, CENTER);
        add(trapInfoText);

        // Modify existing UI colors to warning theme
        if (bgSprite != null) {
            bgSprite.color = FlxColor.fromRGB(75, 15, 15); // Dark red tint
        }
    }

    private function startTrapGame():Void {
        if (unoGame != null) {

            // Add human player
            var humanPlayer = new UnoPlayer("human", '${APEntryState.ap.slot} (You)', true);
            unoGame.addPlayer(humanPlayer);

            var diffArray = [UnoDifficulty.EASY, UnoDifficulty.NORMAL, UnoDifficulty.HARD, UnoDifficulty.EXPERT];

            // Add CPU players with proper difficulty distribution
            var difficulties = [diffArray[FlxG.random.int(0, diffArray.length-1)], diffArray[FlxG.random.int(0, diffArray.length-1)], diffArray[FlxG.random.int(0, diffArray.length-1)]];
            for (i in 1...4) { // Add 3 CPU players
                var difficulty = difficulties[(i - 1) % difficulties.length];
                var diffName = switch (difficulty) {
                    case EASY: "Easy";
                    case NORMAL: "Normal";
                    case HARD: "Hard";
                    case EXPERT: "Expert";
                }
                var cpu = new UnoCPU('cpu$i', UnoTestState.randomGenericNames[FlxG.random.int(0, UnoTestState.randomGenericNames.length)], difficulty);
                unoGame.addPlayer(cpu);
            }
            // Start the UNO game immediately
            unoGame.startGame();
            selectedCardIndex = -1;
            isFirstCardPlayed = false; // Reset first card animation
            resetCardSelection(); // Clear any card selection
            previousHandCards = []; // Reset hand tracking
            isPlayingCard = false; // Reset animation state
            updateDisplay();
            updateInstructionText("TRAP ACTIVE! Win this round with randomized rules or die!");
        }
    }

    private function showRulesInfoPanel():Void {
        // Build rules information string
        var rulesInfo = "RANDOMIZED UNO RULES FOR THIS TRAP:\n\n";

        rulesInfo += "• Stacking: " + (UnoRules.ALLOW_STACKING ? "ENABLED" : "DISABLED") + "\n";
        rulesInfo += "  (Play stacking force draw cards.)\n\n";

        rulesInfo += "• Jump-In: " + (UnoRules.ALLOW_JUMP_IN ? "ENABLED" : "DISABLED") + "\n";
        rulesInfo += "  (Play identical card out of turn)\n\n";

        rulesInfo += "• Draw Until Playable: " + (UnoRules.DRAW_UNTIL_PLAYABLE ? "ENABLED" : "DISABLED") + "\n";
        rulesInfo += "  (Keep drawing until you can play)\n\n";

        rulesInfo += "• Progressive UNO: " + (UnoRules.PROGRESSIVE_UNO ? "ENABLED" : "DISABLED") + "\n";
        rulesInfo += "  (Must keep saying 'UNO' when down to one card)\n\n";

        rulesInfo += "• Seven-Zero Rule: " + (UnoRules.SEVEN_ZERO_RULE ? "ENABLED" : "DISABLED") + "\n";
        rulesInfo += "  (7=swap hands, 0=rotate hands)\n\n";

        rulesInfo += "• Wild Draw Four Challenge: " + (UnoRules.WILD_DRAW_FOUR_CHALLENGE ? "ENABLED" : "DISABLED") + "\n";
        rulesInfo += "  (Challenge illegal Wild Draw Four plays)\n\n";

        rulesInfo += "• Any Plus Stacking: " + (UnoRules.ALLOW_ANY_PLUS_STACK ? "ENABLED" : "DISABLED") + "\n";
        rulesInfo += "  (Stack any draw cards together)\n\n";

        rulesInfo += "Winning Score: " + UnoRules.WINNING_SCORE + " points\n\n";
        rulesInfo += "Remember: You MUST win to survive this trap!";

        // Create and open the info panel
        var infoPanel = new InfoPanelSubstate("UNO TRAP RULES", rulesInfo, FlxColor.RED);
        openSubState(infoPanel);
    }
}
