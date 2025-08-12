package yutautil.games.uno;

/**
 * Represents a player in the UNO game
 */
class UnoPlayer {
    public var id:String;
    public var name:String;
    public var hand:UnoHand;
    public var isHuman:Bool;
    public var calledUno:Bool;
    public var score:Int;
    
    // Events that can be triggered
    public var onCardPlayed:UnoCard->Void;
    public var onCardDrawn:UnoCard->Void;
    public var onUnoCall:Void->Void;
    public var onPlayerWin:Void->Void;
    
    public function new(id:String, name:String, isHuman:Bool = true) {
        this.id = id;
        this.name = name;
        this.isHuman = isHuman;
        this.hand = new UnoHand();
        this.calledUno = false;
        this.score = 0;
    }
    
    /**
     * Draw cards from the deck
     */
    public function drawCards(deck:UnoDeck, count:Int):Void {
        var drawnCards = deck.drawCards(count);
        hand.addCards(drawnCards);
        
        if (onCardDrawn != null) {
            for (card in drawnCards) {
                onCardDrawn(card);
            }
        }
    }
    
    /**
     * Play a card from the hand
     */
    public function playCard(cardIndex:Int, deck:UnoDeck):UnoCard {
        if (cardIndex < 0 || cardIndex >= hand.getSize()) {
            throw "Invalid card index!";
        }
        
        var card = hand.removeCardAt(cardIndex);
        deck.discard(card);
        
        // Reset UNO call if player played a card but still has more than 1 card
        if (hand.getSize() > 1) {
            calledUno = false;
        }
        
        if (onCardPlayed != null) {
            onCardPlayed(card);
        }
        
        // Check for win condition
        if (hand.isEmpty() && onPlayerWin != null) {
            onPlayerWin();
        }
        
        return card;
    }
    
    /**
     * Call UNO when down to one card
     */
    public function callUno():Void {
        if (hand.isUno()) {
            calledUno = true;
            if (onUnoCall != null) {
                onUnoCall();
            }
        }
    }
    
    /**
     * Check if player needs to be penalized for not calling UNO
     */
    public function needsUnoPenalty():Bool {
        return hand.isUno() && !calledUno;
    }
    
    /**
     * Apply UNO penalty (draw 2 cards)
     */
    public function applyUnoPenalty(deck:UnoDeck):Void {
        drawCards(deck, 2);
        calledUno = false;
    }
    
    /**
     * Get playable cards for the current game state
     */
    public function getPlayableCards(topCard:UnoCard):Array<UnoCard> {
        return hand.getPlayableCards(topCard);
    }
    
    /**
     * Check if player has any playable cards
     */
    public function canPlay(topCard:UnoCard):Bool {
        return hand.hasPlayableCard(topCard);
    }
    
    /**
     * Add points to the player's score
     */
    public function addScore(points:Int):Void {
        score += points;
    }
    
    /**
     * Reset the player for a new round
     */
    public function resetForNewRound():Void {
        hand.clear();
        calledUno = false;
    }
    
    /**
     * Reset the player completely (including score)
     */
    public function reset():Void {
        resetForNewRound();
        score = 0;
    }
    
    /**
     * Get the current hand size
     */
    public function getHandSize():Int {
        return hand.getSize();
    }
    
    /**
     * Get the total points in hand (for scoring when someone wins)
     */
    public function getHandPoints():Int {
        return hand.getTotalPoints();
    }
    
    /**
     * Check if this player has won the round
     */
    public function hasWon():Bool {
        return hand.isEmpty();
    }
    
    /**
     * Get a string representation of the player
     */
    public function toString():String {
        var playerType = isHuman ? "Human" : "CPU";
        var unoStatus = calledUno ? " (UNO!)" : "";
        return '$name ($playerType) - ${hand.getSize()} cards - Score: $score$unoStatus';
    }
    
    /**
     * Get player status for game display
     */
    public function getStatus():String {
        var status = '$name: ${hand.getSize()} cards';
        if (hand.isUno() && calledUno) {
            status += " (UNO!)";
        }
        return status;
    }
}
