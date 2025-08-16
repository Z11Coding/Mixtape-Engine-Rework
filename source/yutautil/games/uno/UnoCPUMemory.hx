package yutautil.games.uno;

import yutautil.games.uno.UnoCard;
import yutautil.games.uno.UnoPlayer;

/**
 * Represents a CPU player's memory of cards and game state
 * Used to make smarter AI decisions based on observed card movements
 */
class UnoCPUMemory {
    // Memory of what cards each player might have
    public var playerPossibleCards:Map<Int, Array<UnoCard>>;
    
    // Memory of what cards each player definitely doesn't have anymore
    public var playerDiscardedCards:Map<Int, Array<UnoCard>>;
    
    // Memory of card swaps and movements
    public var cardSwapHistory:Array<CardSwapRecord>;
    
    // Memory of previous hand states
    public var previousHandStates:Array<HandState>;
    
    // Confidence levels for card predictions (0.0 to 1.0)
    public var cardConfidence:Map<String, Float>;
    
    // Remember which players are close to winning
    public var threatLevels:Map<Int, Float>;
    
    // Remember custom rule effects and their impact
    public var ruleMemory:Map<String, RuleMemory>;
    
    private var ownerPlayerId:Int;
    private var maxHistorySize:Int;
    
    public function new(playerId:Int, maxHistorySize:Int = 50) {
        this.ownerPlayerId = playerId;
        this.maxHistorySize = maxHistorySize;
        
        playerPossibleCards = new Map<Int, Array<UnoCard>>();
        playerDiscardedCards = new Map<Int, Array<UnoCard>>();
        cardSwapHistory = [];
        previousHandStates = [];
        cardConfidence = new Map<String, Float>();
        threatLevels = new Map<Int, Float>();
        ruleMemory = new Map<String, RuleMemory>();
    }
    
    /**
     * Record a card being played by a player
     */
    public function recordCardPlayed(playerId:Int, card:UnoCard):Void {
        // Remove this card from possible cards for this player
        var possible = playerPossibleCards.get(playerId);
        if (possible == null) possible = [];
        
        // Remove the card if we thought they had it
        for (i in 0...possible.length) {
            if (possible[i].equals(card)) {
                possible.splice(i, 1);
                break;
            }
        }
        playerPossibleCards.set(playerId, possible);
        
        // Add to discarded cards
        var discarded = playerDiscardedCards.get(playerId);
        if (discarded == null) discarded = [];
        discarded.push(card.clone());
        playerDiscardedCards.set(playerId, discarded);
        
        // Update confidence that this player no longer has this exact card
        updateCardConfidence(playerId, card, 0.0);
    }
    
    /**
     * Record a card swap between players
     */
    public function recordCardSwap(fromPlayer:Int, toPlayer:Int, cardCount:Int, ?knownCards:Array<UnoCard>):Void {
        var swapRecord = new CardSwapRecord();
        swapRecord.fromPlayer = fromPlayer;
        swapRecord.toPlayer = toPlayer;
        swapRecord.cardCount = cardCount;
        swapRecord.knownCards = knownCards != null ? knownCards : [];
        swapRecord.timestamp = Date.now().getTime();
        
        cardSwapHistory.push(swapRecord);
        
        // Limit history size
        while (cardSwapHistory.length > maxHistorySize) {
            cardSwapHistory.shift();
        }
        
        // Update possible cards based on the swap
        if (knownCards != null) {
            var fromPossible = playerPossibleCards.get(fromPlayer);
            var toPossible = playerPossibleCards.get(toPlayer);
            
            if (fromPossible == null) fromPossible = [];
            if (toPossible == null) toPossible = [];
            
            for (card in knownCards) {
                // Remove from 'from' player
                for (i in 0...fromPossible.length) {
                    if (fromPossible[i].equals(card)) {
                        fromPossible.splice(i, 1);
                        break;
                    }
                }
                // Add to 'to' player
                toPossible.push(card.clone());
            }
            
            playerPossibleCards.set(fromPlayer, fromPossible);
            playerPossibleCards.set(toPlayer, toPossible);
        }
    }
    
    /**
     * Record the current hand state for comparison later
     */
    public function recordHandState(playerId:Int, hand:Array<UnoCard>):Void {
        if (playerId != ownerPlayerId) return; // Only record own hand states
        
        var handState = new HandState();
        handState.playerId = playerId;
        handState.cards = [];
        for (card in hand) {
            handState.cards.push(card.clone());
        }
        handState.timestamp = Date.now().getTime();
        
        previousHandStates.push(handState);
        
        // Limit history size
        while (previousHandStates.length > maxHistorySize) {
            previousHandStates.shift();
        }
    }
    
    /**
     * Update confidence level for a card prediction
     */
    public function updateCardConfidence(playerId:Int, card:UnoCard, confidence:Float):Void {
        var key = '${playerId}_${card.color}_${card.type}_${card.number}';
        cardConfidence.set(key, Math.max(0.0, Math.min(1.0, confidence)));
    }
    
    /**
     * Get confidence level for a card prediction
     */
    public function getCardConfidence(playerId:Int, card:UnoCard):Float {
        var key = '${playerId}_${card.color}_${card.type}_${card.number}';
        return cardConfidence.exists(key) ? cardConfidence.get(key) : 0.5;
    }
    
    /**
     * Update threat level for a player (how close they are to winning)
     */
    public function updateThreatLevel(playerId:Int, cardCount:Int, hasPlayableCard:Bool):Void {
        var threat:Float = 0.0;
        
        if (cardCount == 1) threat = 1.0; // UNO - highest threat
        else if (cardCount == 2) threat = 0.8; // Very high threat
        else if (cardCount <= 3) threat = 0.6; // High threat
        else if (cardCount <= 5) threat = 0.4; // Medium threat
        else threat = 0.2; // Low threat
        
        // Adjust based on whether they have a playable card
        if (!hasPlayableCard && cardCount > 1) {
            threat *= 0.5; // Reduce threat if they can't play
        }
        
        threatLevels.set(playerId, threat);
    }
    
    /**
     * Record memory about a custom rule's effect
     */
    public function recordRuleEffect(ruleName:String, playerId:Int, beneficialEffect:Bool, impact:Float):Void {
        var ruleMemory = this.ruleMemory.get(ruleName);
        if (ruleMemory == null) {
            ruleMemory = new RuleMemory();
            ruleMemory.ruleName = ruleName;
            ruleMemory.playerEffects = new Map<Int, RuleEffect>();
        }
        
        var effect = ruleMemory.playerEffects.get(playerId);
        if (effect == null) {
            effect = new RuleEffect();
            effect.timesAffected = 0;
            effect.totalImpact = 0.0;
            effect.beneficialCount = 0;
        }
        
        effect.timesAffected++;
        effect.totalImpact += impact;
        if (beneficialEffect) effect.beneficialCount++;
        
        ruleMemory.playerEffects.set(playerId, effect);
        this.ruleMemory.set(ruleName, ruleMemory);
    }
    
    /**
     * Get the predicted impact of a rule on a player
     */
    public function getPredictedRuleImpact(ruleName:String, playerId:Int):Float {
        var ruleMemory = this.ruleMemory.get(ruleName);
        if (ruleMemory == null) return 0.0;
        
        var effect = ruleMemory.playerEffects.get(playerId);
        if (effect == null || effect.timesAffected == 0) return 0.0;
        
        return effect.totalImpact / effect.timesAffected;
    }
    
    /**
     * Check if a player likely has a card that can prevent another player from winning
     */
    public function canPlayerLikelyPreventWin(playerId:Int, topCard:UnoCard, winningPlayerId:Int):Float {
        var confidence:Float = 0.0;
        
        // Check if they have cards that match the top card
        var possible = playerPossibleCards.get(playerId);
        if (possible != null) {
            for (card in possible) {
                if (card.canPlayOn(topCard)) {
                    confidence += getCardConfidence(playerId, card);
                }
            }
        }
        
        // Consider recent swaps - if they got cards from a player who could prevent the win
        for (swap in cardSwapHistory) {
            if (swap.toPlayer == playerId) {
                // They might have gotten useful cards
                confidence += 0.2;
            }
        }
        
        return Math.min(1.0, confidence);
    }
    
    /**
     * Clear old memory to prevent memory leaks
     */
    public function clearOldMemory():Void {
        var currentTime = Date.now().getTime();
        var maxAge = 5 * 60 * 1000; // 5 minutes
        
        // Clear old swap history
        cardSwapHistory = cardSwapHistory.filter(function(swap) {
            return (currentTime - swap.timestamp) < maxAge;
        });
        
        // Clear old hand states
        previousHandStates = previousHandStates.filter(function(state) {
            return (currentTime - state.timestamp) < maxAge;
        });
    }
    
    /**
     * Reset all memory (useful when starting a new game)
     */
    public function reset():Void {
        playerPossibleCards.clear();
        playerDiscardedCards.clear();
        cardSwapHistory = [];
        previousHandStates = [];
        cardConfidence.clear();
        threatLevels.clear();
        ruleMemory.clear();
    }
}

/**
 * Record of a card swap between players
 */
class CardSwapRecord {
    public var fromPlayer:Int;
    public var toPlayer:Int;
    public var cardCount:Int;
    public var knownCards:Array<UnoCard>;
    public var timestamp:Float;
    
    public function new() {
        knownCards = [];
    }
}

/**
 * Record of a player's hand state at a point in time
 */
class HandState {
    public var playerId:Int;
    public var cards:Array<UnoCard>;
    public var timestamp:Float;
    
    public function new() {
        cards = [];
    }
}

/**
 * Memory about how a custom rule affects players
 */
class RuleMemory {
    public var ruleName:String;
    public var playerEffects:Map<Int, RuleEffect>;
    
    public function new() {
        playerEffects = new Map<Int, RuleEffect>();
    }
}

/**
 * Effect of a rule on a specific player
 */
class RuleEffect {
    public var timesAffected:Int;
    public var totalImpact:Float;
    public var beneficialCount:Int;
    
    public function new() {
        timesAffected = 0;
        totalImpact = 0.0;
        beneficialCount = 0;
    }
}
