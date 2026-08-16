package games.uno.beta;

import archipelago.APInfo;
import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.uno.ColorChoiceSubstate;
import games.uno.HandSwapSubstate;
import games.uno.UnoOptionsSubState;
import games.uno.backend.UnoCPU.UnoDifficulty;
import games.uno.backend.UnoCPU;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoCard;
import games.uno.backend.UnoGame;
import games.uno.backend.UnoPlayer;
import games.uno.backend.UnoRules;
import states.MainMenuState;

class UnoBetaState extends MusicBeatState {
    public static var randomGenericNames:Array<String> = [
        "Ansley Conner",
        "Giovanni Duncan",
        "Levi Carroll",
        "Rory Winters",
        "Cory Coleman",
        "Jennifer Merritt",
        "Riley Horne",
        "Anika Gillespie",
        "Dorothy Barry",
        "Casen Fields",
        "Abby Reyna",
        "Nola Nixon",
        "Cleo Rivas",
        "Frankie Holt",
        "Adley Robinson",
        "Devon Corona",
        "Taylor Hanson",
        "Dario Xiong",
        "Maya Park",
        "Sloane West"
    ];

    private var tableBg:FlxSprite;
    private var topCardSprite:FlxSprite;
    private var drawPileSprite:FlxSprite;
    private var titleText:FlxText;
    private var statusText:FlxText;
    private var instructionText:FlxText;
    private var playerInfoText:FlxText;
    private var handGroup:FlxTypedGroup<FlxSprite>;
    private var drawPileButton:PsychUIButton;
    private var unoButton:PsychUIButton;
    private var cpuTimer:FlxTimer;
    private var currentHandSprites:Array<FlxSprite> = [];
    private var activeCardIndex:Int = -1;
    private var waitingForColorChoice:Bool = false;
    private var waitingForHandSwap:Bool = false;
    private var normalMus:FlxSound;
    private var lastcardMus:FlxSound;
    private var uiSyncQueued:Bool = false;
    private var isLastCardPulse:Bool = false;

    private var unoGame:UnoGame;

    override function create():Void {
        super.create();
        FlxG.camera.bgColor = FlxColor.fromRGB(16, 50, 35);

        playUnoMusic();
        setupScene();
        setupGame();
        updateUI();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (unoGame != null && unoGame.isRoundActive && unoGame.turnManager != null) {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer != null && !currentPlayer.isHuman && !waitingForColorChoice && !waitingForHandSwap) {
                if (cpuTimer == null || !cpuTimer.active) {
                    cpuTimer = new FlxTimer().start(0.8, function(_) {
                        processCpuTurn();
                    });
                }
            }
        }

        if (FlxG.keys.justPressed.R) {
            startNewGame();
        }

        if (FlxG.keys.justPressed.O) {
            openUnoOptions();
        }

        if (FlxG.keys.justPressed.D && unoGame != null && unoGame.turnManager != null) {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer != null && currentPlayer.isHuman) {
                unoGame.drawCards(currentPlayer, 1);
                queueUISync();
            }
        }

        if (FlxG.keys.justPressed.U && unoGame != null && unoGame.turnManager != null) {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer != null && currentPlayer.isHuman) {
                if (currentPlayer.hand.getSize() == 1) {
                    unoGame.callUno(currentPlayer);
                    queueUISync();
                }
            }
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new MainMenuState());
        }

        updateMouseCardSelection();
    }

    private function setupScene():Void {
        tableBg = new FlxSprite();
        tableBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(16, 50, 35));
        add(tableBg);

        var vignette = new FlxSprite();
        vignette.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.18));
        add(vignette);

        titleText = new FlxText(0, 24, FlxG.width, "UNO BETA", 28);
        titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.fromRGB(250, 220, 90), CENTER);
        add(titleText);

        statusText = new FlxText(30, 70, FlxG.width - 60, "Ready", 18);
        statusText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
        add(statusText);

        instructionText = new FlxText(30, FlxG.height - 110, FlxG.width - 60, "Click a card to play or press the draw pile.", 14);
        instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.fromRGB(220, 220, 220), LEFT);
        add(instructionText);

        playerInfoText = new FlxText(FlxG.width - 260, 80, 220, "", 14);
        playerInfoText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.fromRGB(230, 230, 255), LEFT);
        add(playerInfoText);

        handGroup = new FlxTypedGroup<FlxSprite>();
        add(handGroup);

        topCardSprite = new FlxSprite(FlxG.width * 0.5 - 46, 150);
        add(topCardSprite);

        drawPileSprite = UnoBetaTextures.createDrawPileSprite(FlxG.width - 210, 150, 0);
        add(drawPileSprite);

        drawPileButton = new PsychUIButton(FlxG.width - 220, 150, "DRAW", function() {
            if (unoGame == null || unoGame.turnManager == null) return;
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer != null && currentPlayer.isHuman) {
                unoGame.drawCards(currentPlayer, 1);
                updateUI();
            }
        });
        drawPileButton.resize(140, 180);
        drawPileButton.normalStyle.bgColor = FlxColor.fromRGB(22, 25, 33);
        drawPileButton.hoverStyle.bgColor = FlxColor.fromRGB(38, 42, 56);
        drawPileButton.clickStyle.bgColor = FlxColor.fromRGB(18, 20, 24);
        drawPileButton.text.alignment = CENTER;
        drawPileButton.text.text = "DRAW\n0";
        drawPileButton.alpha = 0;
        add(drawPileButton);

        unoButton = new PsychUIButton(FlxG.width - 220, FlxG.height - 90, "UNO!", function() {
            if (unoGame == null || unoGame.turnManager == null) return;
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer == null || !currentPlayer.isHuman) return;

            if (currentPlayer.hand.getSize() != 1) {
                instructionText.text = "You need exactly one card left before calling UNO.";
                return;
            }

            if (unoGame.callUno(currentPlayer)) {
                instructionText.text = "UNO called!";
            }
            updateUI();
        });
        unoButton.resize(140, 54);
        unoButton.normalStyle.bgColor = FlxColor.fromRGB(135, 22, 22);
        unoButton.hoverStyle.bgColor = FlxColor.fromRGB(180, 28, 28);
        unoButton.clickStyle.bgColor = FlxColor.fromRGB(90, 0, 0);
        add(unoButton);
    }

    private function setupGame():Void {
        var customColors:Array<UnoColor> = buildCustomColors();
        unoGame = new UnoGame(customColors, true, null);
        unoGame.onGameStart = () -> {
            updateUI();
        };

        unoGame.onCardPlayed = function(player:UnoPlayer, card:UnoCard) {
            if (card != null) {
                var label = player != null ? player.name : "Someone";
                instructionText.text = '$label played ${card.toString()}';
            }
            updateUI();
        };

        unoGame.onPlayerDraw = function(player:UnoPlayer, count:Int) {
            if (player != null) {
                instructionText.text = '${player.name} drew $count card(s).';
            }
            updateUI();
        };

        unoGame.onWildColorChosen = function(color:UnoColor) {
            waitingForColorChoice = false;
            updateUI();
        };

        unoGame.onSevenRuleHandSwap = function(currentPlayer:UnoPlayer, availablePlayers:Array<UnoPlayer>, onSelected:UnoPlayer->Void):Void {
            if (waitingForHandSwap) return;
            waitingForHandSwap = true;
            openSubState(new HandSwapSubstate(currentPlayer, availablePlayers, function(selectedPlayer:UnoPlayer) {
                waitingForHandSwap = false;
                if (selectedPlayer != null) {
                    onSelected(selectedPlayer);
                }
                updateUI();
            }));
        };

        unoGame.onGameEnd = function(winner:UnoPlayer) {
            if (winner != null) {
                instructionText.text = '${winner.name} wins the round! Press R to restart.';
            }
            updateUI();
        };

        startNewGame();
    }

    private function startNewGame():Void {
        if (unoGame == null) {
            setupGame();
            return;
        }

        unoGame.players = [];

        var human = new UnoPlayer("human", "You", true);
        unoGame.addPlayer(human);

        var difficulties:Array<UnoDifficulty> = [EASY, NORMAL, HARD, EXPERT];
        for (i in 1...4) {
            var diff = difficulties[(i - 1) % difficulties.length];
            var name = randomGenericNames[FlxG.random.int(0, randomGenericNames.length - 1)];
            unoGame.addPlayer(new UnoCPU('cpu$i', name, diff));
        }

        unoGame.startGame();
        waitingForColorChoice = false;
        waitingForHandSwap = false;
        updateUI();
    }

    private function updateUI():Void {
        if (unoGame == null) return;

        if (unoGame.turnManager != null && unoGame.turnManager.getCurrentPlayer() != null) {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer.isHuman) {
                statusText.text = 'Current turn: ${currentPlayer.name}';
                instructionText.text = 'Select a card or draw from the pile.';
            } else {
                statusText.text = 'Current turn: ${currentPlayer.name}';
                instructionText.text = '${currentPlayer.name} is thinking...';
            }
        }

        queueUISync();
        updateLastCardMusicPulse();
    }

    private function queueUISync():Void {
        if (uiSyncQueued) return;
        uiSyncQueued = true;
        new FlxTimer().start(0.07, function(_) {
            uiSyncQueued = false;
            if (unoGame == null) return;
            refreshPlayerHand();
            refreshOpponentInfo();
            refreshTopCard();
            refreshDrawPile();
            refreshButtons();
            updateLastCardMusicPulse();
        });
    }

    private function refreshPlayerHand():Void {
        if (unoGame == null || unoGame.players.length == 0) return;

        var humanPlayer = unoGame.players[0];
        if (humanPlayer == null || humanPlayer.hand == null) return;

        var cards = humanPlayer.hand.cards.copy();
        var startX = 52;
        var yPos = FlxG.height - 170;
        var spacing = 58;
        var maxWidth = FlxG.width - 260;
        if (cards.length * spacing > maxWidth) {
            spacing = (maxWidth / Math.max(1, cards.length)).toNum();
        }

        var existingMap:Map<UnoCard, FlxSprite> = new Map();
        for (sprite in currentHandSprites) {
            if (sprite == null) continue;
            var matched:Bool = false;
            for (i in 0...cards.length) {
                if (i < currentHandSprites.length && currentHandSprites[i] == sprite && currentHandSprites[i] != null) {
                    // no-op; sprite ownership is handled by the card order below
                }
            }
            for (card in cards) {
                if (sprite == null) break;
            }
            if (sprite != null && sprite.exists) {
                handGroup.remove(sprite, true);
                sprite.destroy();
            }
        }
        currentHandSprites = [];

        for (i in 0...cards.length) {
            var card = cards[i];
            var sprite = UnoBetaTextures.createCardSprite(card, startX + i * spacing, yPos);
            sprite.scale.set(1, 1);
            sprite.alpha = 1;
            sprite.setGraphicSize(92, 132);
            sprite.updateHitbox();
            handGroup.add(sprite);
            currentHandSprites.push(sprite);

            if (i == cards.length - 1) {
                FlxTween.tween(sprite, {x: startX + i * spacing, y: yPos}, 0.18, {ease: FlxEase.sineOut});
            }
        }
    }

    private function refreshOpponentInfo():Void {
        if (unoGame == null || unoGame.players == null) return;

        var lines:Array<String> = [];
        for (i in 1...unoGame.players.length) {
            var player = unoGame.players[i];
            if (player == null) continue;
            var prefix = (unoGame.turnManager != null && unoGame.turnManager.getCurrentPlayer() == player) ? "▶ " : "  ";
            lines.push('$prefix${player.name}: ${player.getHandSize()} cards');
        }
        playerInfoText.text = lines.join("\n");
    }

    private function refreshTopCard():Void {
        if (unoGame == null || unoGame.deck == null) return;
        var card = unoGame.deck.getTopCard();
        if (card == null) return;

        if (topCardSprite != null) {
            remove(topCardSprite, true);
        }

        topCardSprite = UnoBetaTextures.createCardSprite(card, FlxG.width * 0.5 - 46, 150);
        add(topCardSprite);
    }

    private function refreshDrawPile():Void {
        if (unoGame == null || drawPileSprite == null) return;

        var count = (unoGame.deck != null) ? unoGame.deck.getRemainingCards() : 0;
        if (drawPileSprite != null) {
            remove(drawPileSprite, true);
        }
        drawPileSprite = UnoBetaTextures.createDrawPileSprite(FlxG.width - 210, 150, count);
        add(drawPileSprite);

        if (drawPileButton != null) {
            drawPileButton.text.text = 'DRAW\n${count}';
        }
    }

    private function refreshButtons():Void {
        if (unoGame == null || unoGame.turnManager == null) return;
        var currentPlayer = unoGame.turnManager.getCurrentPlayer();
        if (unoButton != null) {
            unoButton.alpha = (currentPlayer != null && currentPlayer.isHuman) ? 1 : 0.6;
            if (currentPlayer != null && currentPlayer.isHuman && currentPlayer.hand.getSize() == 1) {
                unoButton.label = "UNO!";
            } else {
                unoButton.label = "UNO!";
            }
        }
    }

    private function updateMouseCardSelection():Void {
        if (unoGame == null || !unoGame.isRoundActive || unoGame.turnManager == null) return;
        var currentPlayer = unoGame.turnManager.getCurrentPlayer();
        if (currentPlayer == null || !currentPlayer.isHuman) return;

        if (FlxG.mouse.justPressed) {
            for (i in 0...currentHandSprites.length) {
                var sprite = currentHandSprites[i];
                if (sprite != null && FlxG.mouse.overlaps(sprite, camera)) {
                    handleCardClick(i);
                    return;
                }
            }
        }
    }

    private function handleCardClick(index:Int):Void {
        if (unoGame == null || unoGame.turnManager == null) return;
        var currentPlayer = unoGame.turnManager.getCurrentPlayer();
        if (currentPlayer == null || !currentPlayer.isHuman) return;

        if (index < 0 || index >= currentPlayer.hand.cards.length) return;

        var card = currentPlayer.hand.cards[index];
        if (card == null) return;
        var topCard = unoGame.deck.getTopCard();
        if (topCard == null) return;

        if (!card.canPlayOn(topCard)) {
            instructionText.text = "That card can't be played right now.";
            animateInvalidCard(index);
            return;
        }

        activeCardIndex = index;
        if (card.isWildCard()) {
            waitingForColorChoice = true;
            openSubState(new ColorChoiceSubstate(currentPlayer, getSelectableColors(), function(chosenColor:UnoColor) {
                waitingForColorChoice = false;
                if (unoGame != null) {
                    var safeIndex = activeCardIndex;
                    if (safeIndex >= 0 && safeIndex < currentPlayer.hand.cards.length) {
                        var played = currentPlayer.hand.cards[safeIndex];
                        if (played != null && played.isWildCard()) {
                            if (!unoGame.playCard(currentPlayer, safeIndex, chosenColor)) {
                                instructionText.text = "The wild card could not be played.";
                            }
                        }
                    }
                }
                updateUI();
            }));
            return;
        }

        if (!unoGame.playCard(currentPlayer, index)) {
            instructionText.text = "That move failed.";
        }
        updateUI();
    }

    private function animateInvalidCard(index:Int):Void {
        if (index < 0 || index >= currentHandSprites.length) return;
        var sprite = currentHandSprites[index];
        if (sprite == null) return;

        FlxTween.tween(sprite, {x: sprite.x - 8}, 0.05, {type: PINGPONG, ease: FlxEase.sineInOut, onComplete: function(_) {
            sprite.x += 8;
        }});
    }

    private function processCpuTurn():Void {
        if (unoGame == null || unoGame.turnManager == null) return;
        var currentPlayer = unoGame.turnManager.getCurrentPlayer();
        if (currentPlayer == null || currentPlayer.isHuman || !Std.isOfType(currentPlayer, UnoCPU)) return;

        var cpu = cast(currentPlayer, UnoCPU);
        var topCard = unoGame.deck.getTopCard();
        var playable = cpu.getPlayableCards(topCard);

        if (playable.length == 0) {
            unoGame.drawCards(currentPlayer, 1);
            updateUI();
            return;
        }

        var chosenIndex = cpu.chooseCard(topCard, unoGame.gameState);
        if (chosenIndex < 0 || chosenIndex >= currentPlayer.hand.cards.length) {
            unoGame.drawCards(currentPlayer, 1);
            updateUI();
            return;
        }

        var card = currentPlayer.hand.cards[chosenIndex];
        var chosenColor:UnoColor = null;
        if (card != null && card.isWildCard()) {
            chosenColor = cpu.chooseWildColor(getSelectableColors());
        }

        if (!unoGame.playCard(currentPlayer, chosenIndex, chosenColor)) {
            unoGame.drawCards(currentPlayer, 1);
        }

        updateUI();
    }

    private function getSelectableColors():Array<UnoColor> {
        var colors = buildCustomColors();
        if (colors.length == 0) {
            colors.push(RED);
            colors.push(BLUE);
            colors.push(GREEN);
            colors.push(YELLOW);
        }
        return colors;
    }

    private function buildCustomColors():Array<UnoColor> {
        var colors:Array<UnoColor> = [];
        if (ClientPrefs.data != null && ClientPrefs.data.arrowRGBExtra != null && ClientPrefs.data.arrowRGBExtra.length > 0) {
            for (i in 0...ClientPrefs.data.arrowRGBExtra.length) {
                var extras:Array<Int> = ClientPrefs.data.arrowRGBExtra[i];
                if (extras != null && extras.length > 0) {
                    var name:String = switch (i) {
                        case 0: "Red";
                        case 1: "Blue";
                        case 2: "Green";
                        case 3: "Yellow";
                        default: "Custom" + (i + 1);
                    };
                    colors.push(UnoColor.CUSTOM(FlxColor.fromInt(extras[0]), name));
                }
            }
        }
        if (colors.length == 0) {
            colors = [
                UnoColor.CUSTOM(FlxColor.PURPLE, "Purple"),
                UnoColor.CUSTOM(FlxColor.PINK, "Pink"),
                UnoColor.CUSTOM(FlxColor.ORANGE, "Orange"),
                UnoColor.CUSTOM(FlxColor.CYAN, "Cyan")
            ];
        }
        return colors;
    }

    private function openUnoOptions():Void {
        var optionsSubState = new UnoOptionsSubState();
        optionsSubState.onColorsChanged = function(newColors:Array<UnoColor>) {
            if (unoGame != null) {
                unoGame.customColors = newColors;
                if (unoGame.players != null && unoGame.players.length > 0) {
                    var currentPlayer = unoGame.turnManager != null ? unoGame.turnManager.getCurrentPlayer() : null;
                    if (currentPlayer != null) {
                        queueUISync();
                    }
                }
            }
        };
        optionsSubState.onRulesChanged = function() {
            if (unoGame != null) {
                queueUISync();
            }
        };
        openSubState(optionsSubState);
    }

    private function playUnoMusic():Void {
        var allowRip:Bool = (FlxG.random.bool(27) && !APInfo.inArchipelagoMode);
        normalMus = new FlxSound().loadEmbedded(Paths.music('gameMusic/Heart of the Cards${(allowRip ? ' (Mountain Man Mix)' : '')}'));
        lastcardMus = new FlxSound().loadEmbedded(Paths.music('gameMusic/Heart of the Cards${(allowRip ? ' (Mountain Man Mix)' : '')} (Last Card Mix)'));
        normalMus.play();
        lastcardMus.play();
        lastcardMus.volume = 0;
        lastcardMus.looped = true;
        normalMus.looped = true;
        FlxG.sound.list.add(normalMus);
        FlxG.sound.list.add(lastcardMus);
        if (FlxG.sound.music != null && FlxG.sound.music.playing) {
            FlxG.sound.music.pause();
        }
    }

    private function updateLastCardMusicPulse():Void {
        if (unoGame == null || normalMus == null || lastcardMus == null) return;

        var playersCloseToWinning = 0;
        if (unoGame.gameState != null && unoGame.gameState.hasPlayerCloseToWinning()) {
            playersCloseToWinning++;
        }

        if (playersCloseToWinning > 0 && !isLastCardPulse) {
            FlxTween.num(1, 0, 1, {ease: FlxEase.sineInOut}, function(value:Float) {
                if (normalMus != null) normalMus.volume = value;
            });
            FlxTween.num(0, 1, 1, {ease: FlxEase.sineInOut}, function(value:Float) {
                if (lastcardMus != null) lastcardMus.volume = value;
            });
            isLastCardPulse = true;
        } else if (playersCloseToWinning == 0 && isLastCardPulse) {
            FlxTween.num(0, 1, 1, {ease: FlxEase.sineInOut}, function(value:Float) {
                if (normalMus != null) normalMus.volume = value;
            });
            FlxTween.num(1, 0, 1, {ease: FlxEase.sineInOut}, function(value:Float) {
                if (lastcardMus != null) lastcardMus.volume = value;
            });
            isLastCardPulse = false;
        }
    }
}
