package yutautil.games.uno;

import yutautil.games.uno.UnoCard;
import yutautil.games.uno.UnoPlayer;
import yutautil.games.uno.UnoCPUMemory;
import yutautil.games.uno.UnoGame;
import yutautil.games.uno.UnoTurnManager.TurnDirection;

/**
 * Enhanced CPU strategy system that considers custom rules, memory, and cooperative play
 */
class UnoCPUStrategy {
    private var memory:UnoCPUMemory;
    private var playerId:Int;
    private var difficulty:Float; // 0.0 = easiest, 1.0 = hardest
    
    public function new(playerId:Int, difficulty:Float = 0.7) {
        this.playerId = playerId;
        this.difficulty = Math.max(0.0, Math.min(1.0, difficulty));
        this.memory = new UnoCPUMemory(playerId);
    }
    
    /**
     * Choose the best card to play considering all factors
     */
    public function chooseBestCard(hand:Array<UnoCard>, topCard:UnoCard, gameState:SmartUnoGameState):UnoCard {
        var playableCards = getPlayableCards(hand, topCard);
        
        if (playableCards.length == 0) {
            return null; // No playable cards
        }
        
        if (playableCards.length == 1) {
            return playableCards[0]; // Only one option
        }
        
        // Record current hand state
        memory.recordHandState(playerId, hand);
        
        // Score each playable card
        var cardScores:Array<CardScore> = [];
        
        for (card in playableCards) {
            var score = scoreCard(card, hand, topCard, gameState);
            cardScores.push({card: card, score: score});
        }
        
        // Sort by score (highest first)
        cardScores.sort(function(a, b) {
            return b.score > a.score ? 1 : (a.score > b.score ? -1 : 0);
        });
        
        // Add some randomness based on difficulty
        var randomFactor = (1.0 - difficulty) * 0.3;
        if (Math.random() < randomFactor && cardScores.length > 1) {
            // Sometimes pick a suboptimal card to simulate human-like play
            var randomIndex = Math.floor(Math.random() * Math.min(3, cardScores.length));
            return cardScores[randomIndex].card;
        }
        
        return cardScores[0].card;
    }
    
    /**
     * Get all cards that can be played on the top card
     */
    private function getPlayableCards(hand:Array<UnoCard>, topCard:UnoCard):Array<UnoCard> {
        var playableCards:Array<UnoCard> = [];
        
        for (card in hand) {
            if (card.canPlayOn(topCard)) {
                playableCards.push(card);
            }
        }
        
        return playableCards;
    }
    
    /**
     * Score a card based on multiple factors
     */
    private function scoreCard(card:UnoCard, hand:Array<UnoCard>, topCard:UnoCard, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        // Base score factors
        score += scoreByCardType(card, gameState);
        score += scoreByColor(card, hand, gameState);
        score += scoreByNumber(card, hand, gameState);
        score += scoreByRuleConsideration(card, gameState);
        score += scoreByThreatAssessment(card, gameState);
        score += scoreByCooperativePlay(card, gameState);
        score += scoreByMemoryInsights(card, gameState);
        
        return score;
    }
    
    /**
     * Score based on card type (action cards, numbers, wilds)
     */
    private function scoreByCardType(card:UnoCard, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        switch (card.type) {
            case NUMBER:
                score += 1.0; // Base score for number cards
                
            case SKIP:
                // Higher score if skipping a threatening player
                var nextPlayer = gameState.getNextPlayer();
                if (nextPlayer != null) {
                    var threat = memory.threatLevels.get(nextPlayer.id);
                    if (threat != null) {
                        score += threat * 5.0; // Skip threatening players
                    }
                }
                score += 3.0; // Base skip value
                
            case REVERSE:
                // Good if it changes direction to skip threatening players
                var previousPlayer = gameState.getPreviousPlayer();
                if (previousPlayer != null) {
                    var threat = memory.threatLevels.get(previousPlayer.id);
                    if (threat != null) {
                        score += threat * 4.0;
                    }
                }
                score += 2.5; // Base reverse value
                
            case DRAW_TWO:
                // High value for making next player draw
                var nextPlayer = gameState.getNextPlayer();
                if (nextPlayer != null) {
                    var threat = memory.threatLevels.get(nextPlayer.id);
                    if (threat != null) {
                        score += threat * 6.0; // Especially good against threatening players
                    }
                }
                score += 4.0; // Base draw two value
                
            case WILD:
                score += 8.0; // Wild cards are very valuable
                
            case WILD_DRAW_FOUR:
                // Only play if it's beneficial or necessary
                var canPlayOther = hasOtherPlayableCard(card, gameState.topCard, gameState.currentHand);
                if (!canPlayOther) {
                    score += 10.0; // Legal to play
                } else {
                    score += 3.0; // Risky to play illegally
                }
                
            default:
                score += 2.0; // Custom action cards
        }
        
        return score;
    }
    
    /**
     * Score based on color strategy
     */
    private function scoreByColor(card:UnoCard, hand:Array<UnoCard>, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        if (card.color == WILD || card.color == NONE) {
            return 0.0; // Wild cards don't have color considerations
        }
        
        // Count cards of this color in hand
        var colorCount = 0;
        for (handCard in hand) {
            if (handCard.color == card.color) {
                colorCount++;
            }
        }
        
        // Prefer colors we have more of
        score += colorCount * 1.5;
        
        // Consider what colors other players might not have
        for (playerId => player in gameState.players) {
            if (playerId == this.playerId) continue;
            
            var discarded = memory.playerDiscardedCards.get(playerId);
            if (discarded != null) {
                var hasColor = false;
                for (discardedCard in discarded) {
                    if (discardedCard.color == card.color) {
                        hasColor = true;
                        break;
                    }
                }
                if (!hasColor) {
                    score += 1.0; // They might not have this color
                }
            }
        }
        
        return score;
    }
    
    /**
     * Score based on number considerations
     */
    private function scoreByNumber(card:UnoCard, hand:Array<UnoCard>, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        if (card.type != NUMBER) {
            return 0.0;
        }
        
        // Consider custom rules for specific numbers
        if (gameState.customRules.zeroAndSevenRule && (card.value == 0 || card.value == 7)) {
            score += scoreZeroSevenRule(card, gameState);
        }
        
        // Prefer higher numbers when hand is small (save low numbers)
        if (hand.length <= 3) {
            score += (card.value * 0.5);
        } else {
            // When hand is large, low numbers are fine
            score += (10 - card.value) * 0.2;
        }
        
        return score;
    }
    
    /**
     * Score based on Zero and Seven rule considerations
     */
    private function scoreZeroSevenRule(card:UnoCard, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        if (card.value == 0) {
            // Playing 0 swaps hands with next player
            var nextPlayer = gameState.getNextPlayer();
            if (nextPlayer != null) {
                var myHandValue = calculateHandValue(gameState.currentHand);
                var estimatedTheirHandValue = estimatePlayerHandValue(nextPlayer.id, gameState);
                
                if (estimatedTheirHandValue < myHandValue) {
                    score += 5.0; // Good trade
                } else {
                    score -= 3.0; // Bad trade
                }
                
                // Consider their threat level
                var threat = memory.threatLevels.get(nextPlayer.id);
                if (threat != null && threat > 0.7) {
                    score -= 5.0; // Don't swap with someone close to winning
                }
            }
        } else if (card.value == 7) {
            // Playing 7 allows choosing who to swap with
            var bestSwapScore:Float = -10.0;
            var myHandValue = calculateHandValue(gameState.currentHand);
            
            for (playerId => player in gameState.players) {
                if (playerId == this.playerId) continue;
                
                var estimatedHandValue = estimatePlayerHandValue(playerId, gameState);
                var swapBenefit = myHandValue - estimatedHandValue;
                
                if (swapBenefit > bestSwapScore) {
                    bestSwapScore = swapBenefit;
                }
            }
            
            score += bestSwapScore * 0.5;
        }
        
        return score;
    }
    
    /**
     * Score based on custom rule considerations
     */
    private function scoreByRuleConsideration(card:UnoCard, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        // Consider each active custom rule
        for (ruleName in gameState.activeCustomRules) {
            var ruleImpact = memory.getPredictedRuleImpact(ruleName, playerId);
            
            // Adjust score based on learned rule effects
            if (ruleImpact > 0) {
                score += 1.0; // This rule tends to benefit us
            } else if (ruleImpact < 0) {
                score -= 0.5; // This rule tends to hurt us
            }
        }
        
        return score;
    }
    
    /**
     * Score based on threat assessment of other players
     */
    private function scoreByThreatAssessment(card:UnoCard, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        // Find the most threatening player
        var maxThreat:Float = 0.0;
        var mostThreateningPlayer:Int = -1;
        
        for (playerId => threat in memory.threatLevels) {
            if (threat > maxThreat) {
                maxThreat = threat;
                mostThreateningPlayer = playerId;
            }
        }
        
        // If this card can hinder the most threatening player
        if (mostThreateningPlayer != -1) {
            var nextPlayerId = gameState.getNextPlayerId();
            
            switch (card.type) {
                case SKIP:
                    if (nextPlayerId == mostThreateningPlayer) {
                        score += maxThreat * 4.0;
                    }
                    
                case DRAW_TWO:
                    if (nextPlayerId == mostThreateningPlayer) {
                        score += maxThreat * 5.0;
                    }
                    
                case REVERSE:
                    var prevPlayerId = gameState.getPreviousPlayerId();
                    if (prevPlayerId == mostThreateningPlayer) {
                        score += maxThreat * 3.0;
                    }
                    
                case WILD_DRAW_FOUR:
                    if (nextPlayerId == mostThreateningPlayer) {
                        score += maxThreat * 6.0;
                    }
                    
                default:
                    // No specific threat mitigation
            }
        }
        
        return score;
    }
    
    /**
     * Score based on cooperative play considerations
     */
    private function scoreByCooperativePlay(card:UnoCard, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        if (gameState.players.keys().length <= 2) {
            return 0.0; // No cooperation in 2-player games
        }
        
        // Find players who might help prevent the most threatening player from winning
        var mostThreatening = getMostThreateningPlayer(gameState);
        if (mostThreatening == -1) return 0.0;
        
        var nextPlayerId = gameState.getNextPlayerId();
        
        // If next player might be able to stop the threatening player
        if (nextPlayerId != mostThreatening) {
            var canPrevent = memory.canPlayerLikelyPreventWin(nextPlayerId, gameState.topCard, mostThreatening);
            
            if (canPrevent > 0.5) {
                // Don't skip or harm a player who might help us
                switch (card.type) {
                    case SKIP:
                        score -= 2.0; // Avoid skipping helpful players
                    case DRAW_TWO:
                        score -= 1.5; // Avoid making helpful players draw
                    default:
                        // Other cards are fine
                }
            }
        }
        
        return score;
    }
    
    /**
     * Score based on memory insights
     */
    private function scoreByMemoryInsights(card:UnoCard, gameState:SmartUnoGameState):Float {
        var score:Float = 0.0;
        
        // Consider recent card swaps
        for (swap in memory.cardSwapHistory) {
            if (swap.toPlayer == playerId) {
                // We received cards from someone - they might be good
                for (knownCard in swap.knownCards) {
                    if (knownCard.equals(card)) {
                        score += 1.0; // This card came from a swap, might be strategic
                    }
                }
            }
        }
        
        // Consider confidence in our predictions about other players
        for (playerId => threat in memory.threatLevels) {
            if (threat > 0.7) { // High threat player
                var confidence = memory.getCardConfidence(playerId, card);
                if (confidence < 0.3) {
                    score += 1.0; // They likely don't have this card
                }
            }
        }
        
        return score;
    }
    
    /**
     * Helper methods
     */
    private function hasOtherPlayableCard(wildCard:UnoCard, topCard:UnoCard, hand:Array<UnoCard>):Bool {
        for (card in hand) {
            if (card != wildCard && card.canPlayOn(topCard)) {
                return true;
            }
        }
        return false;
    }
    
    private function calculateHandValue(hand:Array<UnoCard>):Float {
        var value:Float = 0.0;
        for (card in hand) {
            value += card.getPointValue();
        }
        return value;
    }
    
    private function estimatePlayerHandValue(playerId:Int, gameState:SmartUnoGameState):Float {
        var player = gameState.players.get(playerId);
        if (player == null) return 0.0;
        
        // Rough estimate based on hand size and known information
        var baseValue = player.getHandSize() * 7.5; // Average card value
        
        // Adjust based on memory
        var possible = memory.playerPossibleCards.get(playerId);
        if (possible != null) {
            var knownValue:Float = 0.0;
            for (card in possible) {
                knownValue += card.getPointValue();
            }
            var confidence = possible.length / Math.max(1, player.getHandSize());
            baseValue = (baseValue * (1.0 - confidence)) + (knownValue * confidence);
        }
        
        return baseValue;
    }
    
    private function getMostThreateningPlayer(gameState:SmartUnoGameState):Int {
        var maxThreat:Float = 0.0;
        var mostThreatening:Int = -1;
        
        for (playerId => threat in memory.threatLevels) {
            if (threat > maxThreat) {
                maxThreat = threat;
                mostThreatening = playerId;
            }
        }
        
        return mostThreatening;
    }
    
    /**
     * Update memory based on game events
     */
    public function updateMemory(gameState:SmartUnoGameState):Void {
        // Update threat levels for all players
        for (playerId => player in gameState.players) {
            var hasPlayable = false; // This would need to be calculated based on game state
            memory.updateThreatLevel(playerId, player.getHandSize(), hasPlayable);
        }
        
        // Clear old memory periodically
        memory.clearOldMemory();
    }
    
    /**
     * Record a card being played for memory
     */
    public function recordCardPlayed(playerId:Int, card:UnoCard):Void {
        memory.recordCardPlayed(playerId, card);
    }
    
    /**
     * Record a card swap for memory
     */
    public function recordCardSwap(fromPlayer:Int, toPlayer:Int, cardCount:Int, ?knownCards:Array<UnoCard>):Void {
        memory.recordCardSwap(fromPlayer, toPlayer, cardCount, knownCards);
    }
    
    /**
     * Record a custom rule effect
     */
    public function recordRuleEffect(ruleName:String, playerId:Int, beneficial:Bool, impact:Float):Void {
        memory.recordRuleEffect(ruleName, playerId, beneficial, impact);
    }
    
    /**
     * Choose best color for wild cards
     */
    public function chooseBestWildColor(hand:Array<UnoCard>, gameState:SmartUnoGameState):UnoColor {
        var colorCounts:Map<UnoColor, Int> = new Map();
        var standardColors = UnoCard.getStandardColors();
        
        // Count colors in hand
        for (color in standardColors) {
            colorCounts.set(color, 0);
        }
        
        for (card in hand) {
            if (card.color != WILD && card.color != NONE) {
                var count = colorCounts.get(card.color);
                if (count != null) {
                    colorCounts.set(card.color, count + 1);
                }
            }
        }
        
        // Find color with most cards
        var bestColor:UnoColor = RED;
        var maxCount:Int = 0;
        
        for (color => count in colorCounts) {
            if (count > maxCount) {
                maxCount = count;
                bestColor = color;
            }
        }
        
        return bestColor;
    }
    
    /**
     * Reset strategy for new game
     */
    public function reset():Void {
        memory.reset();
    }
}

/**
 * Game state information needed for AI decision making
 */
class SmartUnoGameState {
    public var players:Map<Int, UnoPlayer>;
    public var currentHand:Array<UnoCard>;
    public var topCard:UnoCard;
    public var currentPlayerId:Int;
    public var direction:UnoTurnManager.TurnDirection; // 1 for forward, -1 for reverse
    public var customRules:Dynamic; // Custom rule settings
    public var activeCustomRules:Array<String>;
    
    public function new() {
        players = new Map();
        currentHand = [];
        activeCustomRules = [];
    }
    
    public function getNextPlayer():UnoPlayer {
        return players.get(getNextPlayerId());
    }
    
    public function getPreviousPlayer():UnoPlayer {
        return players.get(getPreviousPlayerId());
    }
    
    public function getNextPlayerId():Int {
        var playerIds = [];
        for (id in players.keys()) {
            playerIds.push(id);
        }
        playerIds.sort(Reflect.compare);
        
        var currentIndex = playerIds.indexOf(currentPlayerId);
        if (currentIndex == -1) return playerIds[0];
        
        var nextIndex = (currentIndex + direction + playerIds.length) % playerIds.length;
        return playerIds[nextIndex];
    }
    
    public function getPreviousPlayerId():Int {
        var playerIds = [];
        for (id in players.keys()) {
            playerIds.push(id);
        }
        playerIds.sort(Reflect.compare);
        
        var currentIndex = playerIds.indexOf(currentPlayerId);
        if (currentIndex == -1) return playerIds[0];
        
        var prevIndex = (currentIndex - direction + playerIds.length) % playerIds.length;
        return playerIds[prevIndex];
    }
}

/**
 * Card with its calculated score for decision making
 */
typedef CardScore = {
    var card:UnoCard;
    var score:Float;
}
