package yutautil.games.uno;

using Math;

import yutautil.games.uno.UnoRules.UnoGameState;
import yutautil.games.uno.UnoCard.UnoColor;

/**
 * AI player implementation for UNO with different difficulty levels
 */
class UnoCPU extends UnoPlayer {
    public var difficulty:UnoDifficulty;
    public var thinkingTime:Float; // Delay to simulate thinking
    
    public function new(id:String, name:String, difficulty:UnoDifficulty = NORMAL) {
        super(id, name, false);
        this.difficulty = difficulty;
        this.thinkingTime = getDifficultyThinkingTime(difficulty);
    }
    
    /**
     * Get thinking time based on difficulty
     */
    private function getDifficultyThinkingTime(diff:UnoDifficulty):Float {
        return switch(diff) {
            case EASY: 5.0;
            case NORMAL: 4.5;
            case HARD: 3.0;
            case EXPERT: 2.5;
        }
    }
    
    /**
     * CPU chooses a card to play
     */
    public function chooseCard(topCard:UnoCard, gameState:UnoGameState):Int {
        var playableCards = getPlayableCards(topCard);
        
        if (playableCards.length == 0) {
            return -1; // No playable cardsdr
        }
        
        return switch(difficulty) {
            case EASY: chooseCardEasy(playableCards, topCard, gameState);
            case NORMAL: chooseCardNormal(playableCards, topCard, gameState);
            case HARD: chooseCardHard(playableCards, topCard, gameState);
            case EXPERT: chooseCardExpert(playableCards, topCard, gameState);
        }
    }
    
    /**
     * Easy AI - Random card selection
     */
    private function chooseCardEasy(playableCards:Array<UnoCard>, topCard:UnoCard, gameState:UnoGameState):Int {
        var randomCard = playableCards[Math.floor(Math.random() * playableCards.length)];
        return hand.cards.indexOf(randomCard);
    }
    
    /**
     * Normal AI - Basic strategy
     */
    private function chooseCardNormal(playableCards:Array<UnoCard>, topCard:UnoCard, gameState:UnoGameState):Int {
        // Prefer action cards when possible
        for (card in playableCards) {
            if (card.isActionCard() && !card.isWildCard()) {
                return hand.cards.indexOf(card);
            }
        }
        
        // Then number cards
        for (card in playableCards) {
            if (card.type == NUMBER) {
                return hand.cards.indexOf(card);
            }
        }
        
        // Finally wild cards
        return hand.cards.indexOf(playableCards[0]);
    }
    
    /**
     * Hard AI - Strategic play
     */
    private function chooseCardHard(playableCards:Array<UnoCard>, topCard:UnoCard, gameState:UnoGameState):Int {
        var nextPlayer = gameState.getNextPlayer();
        var isNextPlayerClose = nextPlayer.getHandSize() <= 3;
        
        // If next player is close to winning, try to disrupt them
        if (isNextPlayerClose) {
            // Use action cards to disrupt
            for (card in playableCards) {
                if (card.type == DRAW_TWO || card.type == SKIP || card.type == WILD_DRAW_FOUR) {
                    return hand.cards.indexOf(card);
                }
            }
        }
        
        // Save wild cards for later unless necessary
        var nonWildCards = [];
        for (card in playableCards) {
            if (!card.isWildCard()) {
                nonWildCards.push(card);
            }
        }
        if (nonWildCards.length > 0) {
            // Prefer action cards
            for (card in nonWildCards) {
                if (card.isActionCard()) {
                    return hand.cards.indexOf(card);
                }
            }
            
            // Then highest value number cards
            nonWildCards.sort(function(a, b) return b.value - a.value);
            return hand.cards.indexOf(nonWildCards[0]);
        }
        
        return hand.cards.indexOf(playableCards[0]);
    }
    
    /**
     * Expert AI - Advanced strategy
     */
    private function chooseCardExpert(playableCards:Array<UnoCard>, topCard:UnoCard, gameState:UnoGameState):Int {
        var cardScores = [];
        
        for (card in playableCards) {
            var score = evaluateCardPlay(card, topCard, gameState);
            cardScores.push({card: card, score: score});
        }
        
        // Sort by score (highest first)
        cardScores.sort(function(a, b) return Math.round(b.score - a.score));
        
        return hand.cards.indexOf(cardScores[0].card);
    }
    
    /**
     * Evaluate the strategic value of playing a card
     */
    private function evaluateCardPlay(card:UnoCard, topCard:UnoCard, gameState:UnoGameState):Float {
        var score = 0.0;
        var nextPlayer = gameState.getNextPlayer();
        var isNextPlayerClose = nextPlayer.getHandSize() <= 3;
        
        // Basic card value
        score += card.getPointValue() * 0.1;
        
        // Action card bonuses
        switch(card.type) {
            case SKIP:
                score += isNextPlayerClose ? 30 : 15;
            case REVERSE:
                score += gameState.players.length == 2 ? 25 : 10;
            case DRAW_TWO:
                score += isNextPlayerClose ? 35 : 20;
            case WILD:
                score += 25;
                score -= hand.getSize() > 3 ? 10 : 0; // Penalty for using wild early
            case WILD_DRAW_FOUR:
                score += isNextPlayerClose ? 50 : 30;
                score -= hand.getSize() > 3 ? 15 : 0; // Penalty for using wild draw four early
            case NUMBER:
                score += 5;
            case CUSTOM(name, points, cpuImportance, action):
                score += cpuImportance;
        }
        
        // Color strategy (including custom colors)
        var colorCount = hand.getCardsByColor(card.color).length;
        if (!card.isWildCard()) {
            score += colorCount * 2; // Prefer playing colors we have more of
        }
        
        // Custom color bonus - slightly prefer custom colors if we have many
        switch(card.color) {
            case CUSTOM(color, name):
                score += colorCount > 2 ? 3 : 1; // Small bonus for custom colors
            case _: // Standard colors get no bonus
        }
        
        // End game strategy
        if (hand.getSize() <= 2) {
            // Prioritize getting rid of high-value cards
            score += card.getPointValue() * 0.5;
        }
        
        return score;
    }
    
    /**
     * CPU chooses a color for wild cards (including custom colors)
     */
    public function chooseWildColor(?availableColors:Array<UnoColor>):UnoColor {
        // If no colors are specified, use standard colors plus any custom colors found in hand
        if (availableColors == null) {
            availableColors = UnoCard.getStandardColors();
            
            // Add any custom colors found in the hand
            for (card in hand.cards) {
                switch(card.color) {
                    case CUSTOM(color, name):
                        var found = false;
                        for (availColor in availableColors) {
                            if (UnoCard.colorsMatch(card.color, availColor)) {
                                found = true;
                                break;
                            }
                        }
                        if (!found) {
                            availableColors.push(card.color);
                        }
                    case _: // Standard colors already included
                }
            }
        }
        
        var colorCounts = [];
        for (color in availableColors) {
            if (color != WILD) { // Don't count wild as a choosable color
                colorCounts.push({
                    color: color,
                    count: hand.getCardsByColor(color).length
                });
            }
        }
        
        // Sort by count (highest first)
        colorCounts.sort(function(a, b) return b.count - a.count);
        
        // Add some randomness for lower difficulties
        var randomFactor = switch(difficulty) {
            case EASY: Math.random() < 0.5;
            case NORMAL: Math.random() < 0.3;
            case HARD: Math.random() < 0.1;
            case EXPERT: false;
        }
        
        if (randomFactor && colorCounts.length > 1) {
            return colorCounts[1].color; // Choose second best sometimes
        }
        
        // Return the color with the most cards, or a random standard color if no cards
        return colorCounts.length > 0 ? colorCounts[0].color : UnoColor.RED;
    }
    
    /**
     * CPU decides whether to challenge a Wild Draw Four
     */
    public function shouldChallenge(previousPlayer:UnoPlayer, topCard:UnoCard):Bool {
        if (difficulty == EASY) {
            return Math.random() < 0.1; // 10% chance
        }
        
        if (difficulty == NORMAL) {
            return Math.random() < 0.3; // 30% chance
        }
        
        // Hard and Expert: Strategic decision based on game state
        var handSize = previousPlayer.getHandSize();
        var challengeProbability = handSize <= 2 ? 0.7 : 0.4; // More likely to challenge if they're close to winning
        
        return Math.random() < challengeProbability;
    }
    
    /**
     * CPU automatically calls UNO when appropriate
     */
    public function autoCallUno():Void {
        if (hand.isUno() && !calledUno) {
            var callProbability = switch(difficulty) {
                case EASY: 0.7; // Sometimes forgets
                case NORMAL: 0.9;
                case HARD: 0.95;
                case EXPERT: 1.0; // Never forgets
            }
            
            if (Math.random() < callProbability) {
                callUno();
            }
        }
    }
}

/**
 * CPU difficulty levels
 */
enum UnoDifficulty {
    EASY;
    NORMAL;
    HARD;
    EXPERT;
}
