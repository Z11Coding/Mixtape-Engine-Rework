package yutautil.games.uno;

import yutautil.games.uno.UnoTurnManager.TurnDirection;

/**
 * Game state information for UNO game decisions
 */
class UnoGameState {
    public var players:Array<UnoPlayer>;
    public var currentPlayer:UnoPlayer;
    public var direction:UnoTurnManager.TurnDirection;
    public var topCard:UnoCard;
    public var currentColor:UnoCard.UnoColor;
    public var cardsInDeck:Int;
    public var cardsInDiscard:Int;
    public var roundNumber:Int;
    public var gameWinner:UnoPlayer;
    
    public function new() {
        players = [];
        roundNumber = 1;
    }
    
    /**
     * Update the game state
     */
    public function update(players:Array<UnoPlayer>, currentPlayer:UnoPlayer, direction:UnoTurnManager.TurnDirection, 
                          topCard:UnoCard, currentColor:UnoCard.UnoColor, cardsInDeck:Int, cardsInDiscard:Int):Void {
        this.players = players;
        this.currentPlayer = currentPlayer;
        this.direction = direction;
        this.topCard = topCard;
        this.currentColor = currentColor;
        this.cardsInDeck = cardsInDeck;
        this.cardsInDiscard = cardsInDiscard;
    }
    
    /**
     * Get the next player in turn order
     */
    public function getNextPlayer():UnoPlayer {
        var currentIndex = players.indexOf(currentPlayer);
        var nextIndex = direction == CLOCKWISE ? 
            (currentIndex + 1) % players.length : 
            (currentIndex == 0 ? players.length - 1 : currentIndex - 1);
        return players[nextIndex];
    }
    
    /**
     * Get the previous player in turn order
     */
    public function getPreviousPlayer():UnoPlayer {
        var currentIndex = players.indexOf(currentPlayer);
        var prevIndex = direction == CLOCKWISE ? 
            (currentIndex == 0 ? players.length - 1 : currentIndex - 1) :
            (currentIndex + 1) % players.length;
        return players[prevIndex];
    }
    
    /**
     * Get players sorted by hand size (ascending)
     */
    public function getPlayersByHandSize():Array<UnoPlayer> {
        var sortedPlayers = players.copy();
        sortedPlayers.sort(function(a, b) return a.getHandSize() - b.getHandSize());
        return sortedPlayers;
    }
    
    /**
     * Get players sorted by score (descending)
     */
    public function getPlayersByScore():Array<UnoPlayer> {
        var sortedPlayers = players.copy();
        sortedPlayers.sort(function(a, b) return b.score - a.score);
        return sortedPlayers;
    }
    
    /**
     * Check if any player is close to winning (1-2 cards)
     */
    public function hasPlayerCloseToWinning():Bool {
        for (p in players) {
            if (p.getHandSize() <= 2) return true;
        }
        return false;
    }
    
    /**
     * Get players who are close to winning
     */
    public function getPlayersCloseToWinning():Array<UnoPlayer> {
        var result = [];
        for (p in players) {
            if (p.getHandSize() <= 2) {
                result.push(p);
            }
        }
        return result;
    }
    
    /**
     * Check if the game is in end-game state
     */
    public function isEndGame():Bool {
        return hasPlayerCloseToWinning() || cardsInDeck < 10;
    }
}

/**
 * Handles all special UNO rules and game logic
 */
class UnoRules {
    public static var STARTING_HAND_SIZE:Int = 7;
    public static var WINNING_SCORE:Int = 500;
    public static var UNO_PENALTY:Int = 2; // Cards to draw if caught not saying UNO
    public static var CHALLENGE_PENALTY:Int = 4; // Cards to draw if challenge fails
    
    // Special rule flags
    public static var ALLOW_STACKING:Bool = true; // Allow stacking draw cards
    public static var ALLOW_JUMP_IN:Bool = false; // Allow jumping in with exact match
    public static var FORCE_PLAY:Bool = false; // Must play if possible
    public static var PROGRESSIVE_UNO:Bool = false; // Must say UNO progressively
    public static var SEVEN_ZERO_RULE:Bool = false; // Special 7 and 0 rules
    public static var WILD_DRAW_FOUR_CHALLENGE:Bool = true; // Allow challenging wild draw four
    
    /**
     * Check if a Wild Draw Four was played legally
     */
    public static function isWildDrawFourLegal(player:UnoPlayer, previousTopCard:UnoCard):Bool {
        if (previousTopCard == null) return true;
        
        // Wild Draw Four is illegal if player has a card of the same color
        var sameColorCards = player.hand.getCardsByColor(previousTopCard.color);
        return sameColorCards.length == 0;
    }
    
    /**
     * Check if cards can be stacked (same type draw cards)
     */
    public static function canStackCards(card1:UnoCard, card2:UnoCard):Bool {
        if (!ALLOW_STACKING) return false;
        
        return (card1.type == DRAW_TWO && card2.type == DRAW_TWO) ||
               (card1.type == WILD_DRAW_FOUR && card2.type == WILD_DRAW_FOUR);
    }
    
    /**
     * Check if a player can jump in with their card
     */
    public static function canJumpIn(playerCard:UnoCard, topCard:UnoCard):Bool {
        if (!ALLOW_JUMP_IN) return false;
        
        // Can jump in with exact match (same color and type/value)
        return playerCard.color == topCard.color && 
               playerCard.type == topCard.type &&
               (playerCard.type != NUMBER || playerCard.value == topCard.value);
    }
    
    /**
     * Apply seven-zero rule effects
     */
    public static function applySevenZeroRule(card:UnoCard, players:Array<UnoPlayer>, currentPlayerIndex:Int):Void {
        if (!SEVEN_ZERO_RULE || card.type != NUMBER) return;
        
        if (card.value == 7) {
            // Player who played 7 swaps hands with another player of their choice
            // This would need to be handled by the game logic with user input
        } else if (card.value == 0) {
            // All players pass their hands in the direction of play
            var hands = [];
            for (player in players) {
                hands.push(player.hand.getCards());
            }
            
            for (i in 0...players.length) {
                var nextIndex = (i + 1) % players.length;
                players[i].hand.clear();
                players[i].hand.addCards(hands[nextIndex]);
            }
        }
    }
    
    /**
     * Calculate penalty for not calling UNO
     */
    public static function getUnoPenalty():Int {
        return UNO_PENALTY;
    }
    
    /**
     * Calculate cards to draw for failed challenge
     */
    public static function getChallengePenalty():Int {
        return CHALLENGE_PENALTY;
    }
    
    /**
     * Check if game has been won (player reached winning score)
     */
    public static function hasGameWinner(players:Array<UnoPlayer>):UnoPlayer {
        for (player in players) {
            if (player.score >= WINNING_SCORE) {
                return player;
            }
        }
        return null;
    }
    
    /**
     * Calculate round points (sum of all other players' hands)
     */
    public static function calculateRoundPoints(players:Array<UnoPlayer>, winner:UnoPlayer):Int {
        var points = 0;
        for (player in players) {
            if (player != winner) {
                points += player.getHandPoints();
            }
        }
        return points;
    }
    
    /**
     * Validate if a card can be played
     */
    public static function canPlayCard(card:UnoCard, topCard:UnoCard, currentColor:UnoCard.UnoColor):Bool {
        // Wild cards can always be played
        if (card.isWildCard()) {
            return true;
        }
        
        // Same color match (use current color, not top card color for wild card situations)
        if (UnoCard.colorsMatch(card.color, currentColor)) {
            return true;
        }
        
        // Same type match (but only for action cards, not numbers)
        if (card.type == topCard.type && card.type != NUMBER) {
            return true;
        }
        
        // Same number value (only for number cards)
        if (card.type == NUMBER && topCard.type == NUMBER && card.value == topCard.value) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Get the cards a player must draw for a draw card
     */
    public static function getDrawAmount(card:UnoCard):Int {
        return switch(card.type) {
            case DRAW_TWO: 2;
            case WILD_DRAW_FOUR: 4;
            default: 0;
        }
    }
    
    /**
     * Check if force play rule applies
     */
    public static function mustPlayIfPossible():Bool {
        return FORCE_PLAY;
    }
    
    /**
     * Get starting hand size for new round
     */
    public static function getStartingHandSize():Int {
        return STARTING_HAND_SIZE;
    }
    
    /**
     * Set custom rules
     */
    public static function setCustomRules(stacking:Bool = true, jumpIn:Bool = false, 
                                        forcePlay:Bool = false, sevenZero:Bool = false,
                                        wildChallenge:Bool = true, winningScore:Int = 500):Void {
        ALLOW_STACKING = stacking;
        ALLOW_JUMP_IN = jumpIn;
        FORCE_PLAY = forcePlay;
        SEVEN_ZERO_RULE = sevenZero;
        WILD_DRAW_FOUR_CHALLENGE = wildChallenge;
        WINNING_SCORE = winningScore;
    }
}
