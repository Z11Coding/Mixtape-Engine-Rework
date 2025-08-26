package archipelago.traps.games;

import archipelago.traps.TrapDeathHandler;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.uno.UnoTestState;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoCard;
import games.uno.backend.UnoGame;
import games.uno.backend.UnoPlayer;
import games.uno.backend.UnoRules;

/**
 * Archipelago UNO Trap State
 * Extends UnoTestState and modifies behavior for trap functionality
 * Player must win the round to survive, losing results in forced death
 * Features randomized UNO rules for extra challenge
 */
class APUnoTrapState extends UnoTestState {

    // Trap-specific properties
    private var previousState:MusicBeatState;
    private var trapInfoText:FlxText;

    public function new(?previousState:MusicBeatState = null) {
        this.previousState = previousState;
        super();
    }

    override function create() {
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

            // Create UNO game with custom cards
            unoGame = new UnoGame(null, true, customCards.length > 0 ? customCards : null);

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
                            if (previousState != null) {
                                MusicBeatState.switchState(previousState);
                            } else {
                                MusicBeatState.switchState(new states.MainMenuState());
                            }
                        });
                    } else {
                        // Player lost - force death
                        updateInstructionText("AI WINS UNO! PREPARE TO DIE!");
                        new FlxTimer().start(2.0, function(timer) {
                            TrapDeathHandler.forceDeath(null, previousState);
                        });
                    }
                };
            }

            trace("AP UNO trap game initialized successfully with randomized rules");
        } catch (e:Dynamic) {
            trace("Error initializing AP UNO trap game: " + e);
            updateInstructionText("Error initializing trap game: " + Std.string(e));
        }
    }

    private function randomizeUnoRules():Void {
        // Randomly enable/disable various UNO rules for challenge
        UnoRules.ALLOW_STACKING = FlxG.random.bool(60); // 60% chance for stacking
        UnoRules.ALLOW_JUMP_IN = FlxG.random.bool(30); // 30% chance for jump-in
        UnoRules.DRAW_UNTIL_PLAYABLE = FlxG.random.bool(70); // 70% chance must play if possible
        UnoRules.PROGRESSIVE_UNO = FlxG.random.bool(20); // 20% chance for progressive UNO
        UnoRules.SEVEN_ZERO_RULE = FlxG.random.bool(40); // 40% chance for 7-0 rule
        UnoRules.WILD_DRAW_FOUR_CHALLENGE = FlxG.random.bool(80); // 80% chance for challenges
        UnoRules.ALLOW_ANY_PLUS_STACK = FlxG.random.bool(50); // 50% chance for any plus stacking

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
            bgSprite.color = FlxColor.fromRGB(25, 15, 15); // Dark red tint
        }
    }

    private function startTrapGame():Void {
        if (unoGame != null) {
            // Start the UNO game immediately
            unoGame.startGame();
            updateInstructionText("TRAP ACTIVE! Win this round with randomized rules or die!");
        }
    }
}
