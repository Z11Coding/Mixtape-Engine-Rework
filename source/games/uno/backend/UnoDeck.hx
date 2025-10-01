package games.uno.backend;

import games.uno.backend.UnoCard.UnoCardType;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoCard;

using Math;

/**
 * Represents a deck of UNO cards with shuffling and dealing capabilities
 */
class UnoDeck {
    public var cards:Array<UnoCard>;
    public var discardPile:Array<UnoCard>;

    public function new() {
        cards = [];
        discardPile = [];
        initializeDeck();
        shuffle();
    }

    /**
     * Initialize a standard UNO deck
     */
    private function initializeDeck():Void {
        initializeDeckWithColors(UnoCard.getStandardColors(), null);
    }

    /**
     * Initialize deck with custom colors and custom cards
     */
    public function initializeDeckWithColors(colors:Array<UnoColor>, ?customCards:Array<UnoCard>):Void {
        cards = [];

        // Add number cards (0-9 for each color, with 0 appearing once and 1-9 appearing twice)
        for (color in colors) {
            // Add one 0 card for each color
            cards.push(new UnoCard(color, NUMBER, 0));

            for (i in 1...10) {
                cards.push(new UnoCard(color, NUMBER, i));
                cards.push(new UnoCard(color, NUMBER, i));
            }

            // Add two of each action card for each color
            cards.push(new UnoCard(color, SKIP));
            cards.push(new UnoCard(color, SKIP));
            cards.push(new UnoCard(color, REVERSE));
            cards.push(new UnoCard(color, REVERSE));
            cards.push(new UnoCard(color, DRAW_TWO));
            cards.push(new UnoCard(color, DRAW_TWO));
        }

        // Add wild cards (4 of each)
        for (i in 0...4) {
            cards.push(new UnoCard(WILD, WILD));
            cards.push(new UnoCard(WILD, WILD_DRAW_FOUR));
        }

        while (cards.length < 108) {
            // Fill remaining cards with number cards to reach 108 cards
            // This is just to ensure the deck has 108 cards if colors are small.
            for (color in colors) {
                // Add one 0 card for each color
                cards.push(new UnoCard(color, NUMBER, 0));

                for (i in 1...10) {
                    cards.push(new UnoCard(color, NUMBER, i));
                    cards.push(new UnoCard(color, NUMBER, i));
                }
            }
        }

        // Add custom cards if provided
        if (customCards != null) {
            for (customCard in customCards) {
                cards.push(customCard.clone()); // Clone to avoid reference issues
            }
        }
    }


    /**
     * Shuffle the deck using Fisher-Yates algorithm
     */
    public function shuffle():Void {
        for (i in 0...cards.length) {
            var j = Math.floor(Math.random() * (i + 1));
            var temp = cards[i];
            cards[i] = cards[j];
            cards[j] = temp;
        }
    }

    /**
     * Draw a card from the deck
     */
    public function drawCard():UnoCard {
        if (cards.length == 0) {
            reshuffleFromDiscard();
        }

        if (cards.length == 0) {
            throw "No cards available to draw!";
        }

        return cards.pop();
    }

    /**
     * Draw multiple cards from the deck
     */
    public function drawCards(count:Int):Array<UnoCard> {
        var drawnCards = [];
        for (i in 0...count) {
            drawnCards.push(drawCard());
        }
        return drawnCards;
    }

    /**
     * Add a card to the discard pile
     */
    public function discard(card:UnoCard):Void {
        discardPile.push(card);
    }

    /**
     * Get the top card of the discard pile without removing it
     */
    public function getTopCard():UnoCard {
        if (discardPile.length == 0) {
            return null;
        }
        return discardPile[discardPile.length - 1];
    }

    /**
     * Reshuffle the discard pile back into the deck (keeping the top card)
     */
    private function reshuffleFromDiscard():Void {
        if (discardPile.length <= 1) {
            return; // Can't reshuffle if there's only the top card or no cards
        }

        // Keep the top card in the discard pile
        var topCard = discardPile.pop();

        // Move all other cards back to the deck
        cards = cards.concat(discardPile);
        discardPile = [topCard];

        // Reset wild card colors in the deck
        for (card in cards) {
            if (card.isWildCard()) {
                card.color = WILD;
            }
        }

        shuffle();
    }

    /**
     * Get the number of cards remaining in the deck
     */
    public function getRemainingCards():Int {
        return cards.length;
    }

    /**
     * Get the number of cards in the discard pile
     */
    public function getDiscardPileSize():Int {
        return discardPile.length;
    }

    /**
     * Reset the deck to its initial state
     */
    public function reset(?customColors:Array<UnoColor>, ?customCards:Array<UnoCard>):Void {
        if (customColors != null) {
            initializeDeckWithColors(customColors, customCards);
        } else {
            initializeDeck();
        }
        discardPile = [];
        shuffle();
    }
}
