package games.uno.backend;

/**
 * Represents a player's hand of UNO cards
 */
class UnoHand {
    public var cards:Array<UnoCard>;
    public var maxHandSize:Int; // 0 = infinite capacity
    
    public function new(maxHandSize:Int = 0) {
        this.cards = [];
        this.maxHandSize = maxHandSize;
    }
    
    /**
     * Add a card to the hand
     */
    public function addCard(card:UnoCard):Void {
        // Allow infinite cards if maxHandSize is 0
        if (maxHandSize > 0 && cards.length >= maxHandSize) {
            throw "Hand is at maximum capacity!";
        }
        cards.push(card);
        sortHand();
    }
    
    /**
     * Add multiple cards to the hand
     */
    public function addCards(newCards:Array<UnoCard>):Void {
        for (card in newCards) {
            addCard(card);
        }
    }
    
    /**
     * Remove a card from the hand by index
     */
    public function removeCardAt(index:Int):UnoCard {
        if (index < 0 || index >= cards.length) {
            throw "Invalid card index!";
        }
        return cards.splice(index, 1)[0];
    }
    
    /**
     * Remove a specific card from the hand
     */
    public function removeCard(card:UnoCard):Bool {
        for (i in 0...cards.length) {
            if (cards[i] == card) {
                cards.splice(i, 1);
                return true;
            }
        }
        return false;
    }
    
    /**
     * Get playable cards based on the current top card
     */
    public function getPlayableCards(topCard:UnoCard):Array<UnoCard> {
        var playableCards = [];
        for (card in cards) {
            if (card.canPlayOn(topCard)) {
                playableCards.push(card);
            }
        }
        return playableCards;
    }
    
    /**
     * Check if the hand has any playable cards
     */
    public function hasPlayableCard(topCard:UnoCard):Bool {
        return getPlayableCards(topCard).length > 0;
    }
    
    /**
     * Get cards of a specific color
     */
    public function getCardsByColor(color:UnoCard.UnoColor):Array<UnoCard> {
        var result = [];
        for (card in cards) {
            if (card.color == color) {
                result.push(card);
            }
        }
        return result;
    }
    
    /**
     * Get cards of a specific type
     */
    public function getCardsByType(type:UnoCard.UnoCardType):Array<UnoCard> {
        var result = [];
        for (card in cards) {
            if (card.type == type) {
                result.push(card);
            }
        }
        return result;
    }
    
    /**
     * Get the number of cards in the hand
     */
    public function getSize():Int {
        return cards.length;
    }
    
    /**
     * Check if the hand is empty
     */
    public function isEmpty():Bool {
        return cards.length == 0;
    }
    
    /**
     * Check if this is the last card (UNO condition)
     */
    public function isUno():Bool {
        return cards.length == 1;
    }
    
    /**
     * Get the total point value of all cards in the hand
     */
    public function getTotalPoints():Int {
        var total = 0;
        for (card in cards) {
            total += card.getPointValue();
        }
        return total;
    }
    
    /**
     * Sort the hand by color and then by type/value
     */
    public function sortHand():Void {
        cards.sort(function(a:UnoCard, b:UnoCard):Int {
            // First sort by color
            var colorA = getColorOrder(a.color);
            var colorB = getColorOrder(b.color);
            
            if (colorA != colorB) {
                return colorA - colorB;
            }
            
            // Then sort by type
            var typeA = getTypeOrder(a.type);
            var typeB = getTypeOrder(b.type);
            
            if (typeA != typeB) {
                return typeA - typeB;
            }
            
            // Finally sort by value for number cards
            return a.value - b.value;
        });
    }
    
    /**
     * Get the sorting order for colors
     */
    private function getColorOrder(color:UnoCard.UnoColor):Int {
        return switch(color) {
            case RED: 0;
            case YELLOW: 1;
            case GREEN: 2;
            case BLUE: 3;
            case WILD: 4;
            case CUSTOM(color, name): 5; // Custom colors come last. Will sort better later.
        }
    }
    
    /**
     * Get the sorting order for card types
     */
    private function getTypeOrder(type:UnoCard.UnoCardType):Int {
        return switch(type) {
            case NUMBER: 0;
            case SKIP: 1;
            case REVERSE: 2;
            case DRAW_TWO: 3;
            case WILD: 4;
            case WILD_DRAW_FOUR: 5;
            case CUSTOM(name, points, cpuImportance, action): 6;
        }
    }
    
    /**
     * Clear all cards from the hand
     */
    public function clear():Void {
        cards = [];
    }
    
    /**
     * Get a copy of all cards in the hand
     */
    public function getCards():Array<UnoCard> {
        return cards.copy();
    }
    
    /**
     * Get a string representation of the hand
     */
    public function toString():String {
        var result = "Hand (" + cards.length + " cards): ";
        for (i in 0...cards.length) {
            result += cards[i].toString();
            if (i < cards.length - 1) {
                result += ", ";
            }
        }
        return result;
    }
}
