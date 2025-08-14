package yutautil.games.uno;

import yutautil.games.uno.UnoCard.UnoColor;
import yutautil.games.uno.UnoTurnManager.TurnDirection;
import yutautil.games.uno.UnoRules.UnoGameState;

/**
 * Main UNO game controller that manages the complete game flow
 */
class UnoGame {
    public var deck:UnoDeck;
    public var turnManager:UnoTurnManager;
    public var gameState:UnoGameState;
    public var players:Array<UnoPlayer>;
    public var currentColor:UnoColor;
    public var isGameActive:Bool;
    public var isRoundActive:Bool;
    public var roundNumber:Int;
    public var drawStack:Int; // For stacking draw cards
    public var lastPlayedCard:UnoCard;
    public var customColors:Array<UnoColor>; // Optional custom colors for the deck
    public var customCards:Array<UnoCard>; // Optional custom cards for the deck
    
    // Events
    public var onGameStart:Void->Void;
    public var onGameEnd:UnoPlayer->Void;
    public var onRoundStart:Int->Void;
    public var onRoundEnd:UnoPlayer->Int->Void;
    public var onCardPlayed:UnoPlayer->UnoCard->Void;
    public var onPlayerDraw:UnoPlayer->Int->Void;
    public var onUnoCall:UnoPlayer->Void;
    public var onUnoPenalty:UnoPlayer->Void;
    public var onDirectionChange:TurnDirection->Void;
    public var onPlayerSkipped:UnoPlayer->Void;
    public var onWildColorChosen:UnoColor->Void;
    public var onChallenge:UnoPlayer->UnoPlayer->Bool->Void;
    
    public function new(?customColors:Array<UnoColor>, ?includeBaseColors:Bool = true, ?customCards:Array<UnoCard>) {
        deck = new UnoDeck();
        players = [];
        gameState = new UnoGameState();
        isGameActive = false;
        isRoundActive = false;
        roundNumber = 0;
        drawStack = 0;
        this.customColors = customColors;
        this.customCards = customCards != null ? customCards : [];
        if (includeBaseColors && this.customColors != null)
            this.customColors = this.customColors.concat(UnoCard.getStandardColors());
    }
    
    /**
     * Add a player to the game
     */
    public function addPlayer(player:UnoPlayer):Void {
        if (isGameActive) {
            throw "Cannot add players while game is active!";
        }
        
        players.push(player);
        
        // Set up player events
        player.onCardPlayed = (card) -> {
            if (onCardPlayed != null) onCardPlayed(player, card);
        };
        
        player.onUnoCall = () -> {
            if (onUnoCall != null) onUnoCall(player);
        };
    }
    
    /**
     * Set custom colors for the deck
     */
    public function setCustomColors(colors:Array<UnoColor>):Void {
        if (isGameActive) {
            throw "Cannot change colors while game is active!";
        }
        customColors = colors;
    }
    
    /**
     * Set custom cards for the deck
     */
    public function setCustomCards(cards:Array<UnoCard>):Void {
        if (isGameActive) {
            throw "Cannot change custom cards while game is active!";
        }
        customCards = cards != null ? cards : [];
    }
    
    /**
     * Add a custom card to the deck
     */
    public function addCustomCard(card:UnoCard):Void {
        if (isGameActive) {
            throw "Cannot add custom cards while game is active!";
        }
        if (customCards == null) {
            customCards = [];
        }
        customCards.push(card);
    }
    
    /**
     * Start a new game
     */
    public function startGame():Void {
        if (players.length < 2) {
            throw "Need at least 2 players to start!";
        }
        
        isGameActive = true;
        roundNumber = 0;
        
        // Reset all player scores
        for (player in players) {
            player.reset();
        }
        
        turnManager = new UnoTurnManager(players);
        setupTurnManagerEvents();
        
        if (onGameStart != null) onGameStart();
        
        startNewRound();
    }
    
    /**
     * Start a new round
     */
    public function startNewRound():Void {
        if (!isGameActive) return;
        
        roundNumber++;
        isRoundActive = true;
        drawStack = 0;
        
        // Reset deck and hands
        deck.reset(customColors, customCards);
        for (player in players) {
            player.resetForNewRound();
        }
        
        // Deal starting hands
        for (i in 0...UnoRules.getStartingHandSize()) {
            for (player in players) {
                player.drawCards(deck, 1);
            }
        }
        
        // Set initial top card (ensure it's not a special card)
        var topCard:UnoCard;
        do {
            topCard = deck.drawCard();
        } while (topCard.isActionCard());
        
        deck.discard(topCard);
        lastPlayedCard = topCard;
        currentColor = topCard.color;
        
        turnManager.reset();
        updateGameState();
        
        if (onRoundStart != null) onRoundStart(roundNumber);
    }
    
    /**
     * Setup turn manager event handlers
     */
    private function setupTurnManagerEvents():Void {
        turnManager.onDirectionChange = (direction) -> {
            if (onDirectionChange != null) onDirectionChange(direction);
        };
        
        turnManager.onPlayerSkipped = (player) -> {
            if (onPlayerSkipped != null) onPlayerSkipped(player);
        };
    }
    
    /**
     * Player attempts to play a card
     */
    public function playCard(player:UnoPlayer, cardIndex:Int, chosenColor:UnoColor = null):Bool {
        if (!isRoundActive || turnManager.getCurrentPlayer() != player) {
            return false;
        }
        
        var card = player.hand.cards[cardIndex];
        
        // Check if card can be played
        if (!UnoRules.canPlayCard(card, deck.getTopCard(), currentColor)) {
            return false;
        }
        
        // Handle draw stack
        if (drawStack > 0 && !canDefendAgainstDraw(card)) {
            return false; // Must draw or defend with appropriate card
        }
        
        // Play the card
        var playedCard = player.playCard(cardIndex, deck);
        lastPlayedCard = playedCard;
        
        // Handle wild cards
        if (playedCard.isWildCard()) {
            if (chosenColor == null) {
                // For CPU players, auto-choose color
                if (!player.isHuman && Std.isOfType(player, UnoCPU)) {
                    var availableColors = customColors != null ? customColors.concat(UnoCard.getStandardColors()) : UnoCard.getStandardColors();
                    chosenColor = cast(player, UnoCPU).chooseWildColor(availableColors);
                } else {
                    throw "Must choose a color for wild cards!";
                }
            }
            currentColor = chosenColor;
            playedCard.color = chosenColor; // Set the chosen color
            
            if (onWildColorChosen != null) onWildColorChosen(chosenColor);
        } else {
            currentColor = playedCard.color;
        }
        
        // Apply card effects
        applyCardEffect(playedCard, player);
        
        // Check for UNO
        if (player.hand.isUno() && !player.calledUno) {
            // Auto-call UNO for CPU players
            if (!player.isHuman && Std.isOfType(player, UnoCPU)) {
                cast(player, UnoCPU).autoCallUno();
            }
        }
        
        // Check for round win
        if (player.hasWon()) {
            endRound(player);
            return true;
        }
        
        // Next turn
        turnManager.nextTurn();
        updateGameState();
        
        return true;
    }
    
    /**
     * Check if a card can defend against draw cards
     */
    private function canDefendAgainstDraw(card:UnoCard):Bool {
        if (!UnoRules.ALLOW_STACKING) return false;
        
        var topCard = deck.getTopCard();
        return UnoRules.canStackCards(topCard, card);
    }
    
    /**
     * Apply the effect of a played card
     */
    private function applyCardEffect(card:UnoCard, player:UnoPlayer):Void {
        switch(card.type) {
            case SKIP:
                turnManager.skipNextPlayer();
                
            case REVERSE:
                turnManager.reverseTurn();
                
            case DRAW_TWO:
                if (UnoRules.ALLOW_STACKING && drawStack > 0) {
                    drawStack += 2;
                } else {
                    drawStack = 2;
                }
                
            case WILD_DRAW_FOUR:
                if (UnoRules.ALLOW_STACKING && drawStack > 0) {
                    drawStack += 4;
                } else {
                    drawStack = 4;
                }
                
            case NUMBER:
                UnoRules.applySevenZeroRule(card, players, turnManager.currentPlayerIndex);
                
            case WILD:
                // No additional effect beyond color change
            case CUSTOM(name, points, cpuImportance, action):
                if (action != null) {
                    action(this);
                }
        }
    }
    
    /**
     * Player draws cards (voluntarily or forced)
     */
    public function drawCards(player:UnoPlayer, count:Int = 1):Void {
        if (!isRoundActive) return;
        
        // Handle draw stack
        if (drawStack > 0 && turnManager.getCurrentPlayer() == player) {
            count = drawStack;
            drawStack = 0;
        }
        
        player.drawCards(deck, count);
        
        if (onPlayerDraw != null) onPlayerDraw(player, count);
        
        // If player drew due to no playable cards, advance turn
        if (turnManager.getCurrentPlayer() == player && !UnoRules.mustPlayIfPossible()) {
            turnManager.nextTurn();
            updateGameState();
        }
    }
    
    /**
     * Player calls UNO
     */
    public function callUno(player:UnoPlayer):Bool {
        if (player.hand.isUno()) {
            player.callUno();
            return true;
        }
        return false;
    }
    
    /**
     * Challenge a Wild Draw Four card
     */
    public function challengeWildDrawFour(challenger:UnoPlayer):Bool {
        if (!UnoRules.WILD_DRAW_FOUR_CHALLENGE) return false;
        
        var previousPlayer = turnManager.getPreviousPlayer();
        var topCard = deck.getTopCard();
        
        if (topCard.type != WILD_DRAW_FOUR) return false;
        
        // Check if the Wild Draw Four was played legally
        var wasLegal = UnoRules.isWildDrawFourLegal(previousPlayer, lastPlayedCard);
        
        if (wasLegal) {
            // Challenge failed - challenger draws extra cards
            challenger.drawCards(deck, UnoRules.getChallengePenalty() + UnoRules.getDrawAmount(topCard));
            if (onChallenge != null) onChallenge(challenger, previousPlayer, false);
        } else {
            // Challenge succeeded - previous player draws cards instead
            previousPlayer.drawCards(deck, UnoRules.getDrawAmount(topCard));
            if (onChallenge != null) onChallenge(challenger, previousPlayer, true);
        }
        
        drawStack = 0; // Clear the draw stack
        return true;
    }
    
    /**
     * Apply UNO penalty to a player
     */
    public function applyUnoPenalty(player:UnoPlayer):Void {
        if (player.needsUnoPenalty()) {
            player.applyUnoPenalty(deck);
            if (onUnoPenalty != null) onUnoPenalty(player);
        }
    }
    
    /**
     * Check for UNO penalties on all players
     */
    public function checkUnoPenalties():Void {
        for (player in players) {
            if (player.needsUnoPenalty()) {
                applyUnoPenalty(player);
            }
        }
    }
    
    /**
     * End the current round
     */
    private function endRound(winner:UnoPlayer):Void {
        isRoundActive = false;
        
        var points = UnoRules.calculateRoundPoints(players, winner);
        winner.addScore(points);
        
        if (onRoundEnd != null) onRoundEnd(winner, points);
        
        // Check for game winner
        var gameWinner = UnoRules.hasGameWinner(players);
        if (gameWinner != null) {
            endGame(gameWinner);
        } else {
            // Start next round after a delay
            startNewRound();
        }
    }
    
    /**
     * End the game
     */
    private function endGame(winner:UnoPlayer):Void {
        isGameActive = false;
        isRoundActive = false;
        gameState.gameWinner = winner;
        
        if (onGameEnd != null) onGameEnd(winner);
    }
    
    /**
     * Update the game state
     */
    private function updateGameState():Void {
        gameState.update(
            players,
            turnManager.getCurrentPlayer(),
            turnManager.direction,
            deck.getTopCard(),
            currentColor,
            deck.getRemainingCards(),
            deck.getDiscardPileSize()
        );
        gameState.roundNumber = roundNumber;
    }
    
    /**
     * Get current game status
     */
    public function getGameStatus():String {
        if (!isGameActive) return "Game not started";
        if (!isRoundActive || turnManager == null || deck == null) return "Initializing game...";
        
        var status = 'Round $roundNumber - ${turnManager.getCurrentPlayer().name}\'s turn\n';
        
        var topCard = deck.getTopCard();
        if (topCard != null) {
            status += 'Top card: ${topCard.toString()}\n';
        } else {
            status += 'Top card: None\n';
        }
        
        status += 'Current color: $currentColor\n';
        
        if (drawStack > 0) {
            status += 'Draw stack: $drawStack cards\n';
        }
        
        status += 'Players:\n';
        for (player in players) {
            status += '  ${player.toString()}\n';
        }
        
        return status;
    }
    
    /**
     * Get playable cards for current player
     */
    public function getCurrentPlayerPlayableCards():Array<UnoCard> {
        if (!isRoundActive) return [];
        
        var currentPlayer = turnManager.getCurrentPlayer();
        return currentPlayer.getPlayableCards(deck.getTopCard());
    }
    
    /**
     * Check if current player can play
     */
    public function canCurrentPlayerPlay():Bool {
        if (!isRoundActive) return false;
        
        var currentPlayer = turnManager.getCurrentPlayer();
        return currentPlayer.canPlay(deck.getTopCard()) || drawStack == 0;
    }
    
    /**
     * Force end the game
     */
    public function forceEndGame():Void {
        isGameActive = false;
        isRoundActive = false;
    }
    
    /**
     * Get game statistics
     */
    public function getGameStats():Dynamic {
        return {
            roundNumber: roundNumber,
            totalCardsPlayed: deck.getDiscardPileSize(),
            cardsRemaining: deck.getRemainingCards(),
            playerStats: players.map(p -> {
                name: p.name,
                score: p.score,
                handSize: p.getHandSize(),
                isHuman: p.isHuman
            })
        };
    }
    
    /**
     * Create a new UnoGame with custom action cards
     */
    public static function createWithCustomActions(customActionCards:Array<UnoCard>, ?customColors:Array<UnoColor>, ?includeBaseColors:Bool = true):UnoGame {
        return new UnoGame(customColors, includeBaseColors, customActionCards);
    }
    
    /**
     * Create a UnoGame with custom colors and actions
     */
    public static function createCustomGame(setup:{
        ?customColors:Array<UnoColor>,
        ?customCards:Array<UnoCard>,
        ?includeBaseColors:Bool
    }):UnoGame {
        var includeBase = setup.includeBaseColors != null ? setup.includeBaseColors : true;
        return new UnoGame(setup.customColors, includeBase, setup.customCards);
    }
}
