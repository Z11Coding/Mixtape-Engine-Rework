package yutautil.games.uno;

/**
 * Manages the turn order and player actions in UNO
 */
class UnoTurnManager {
    public var players:Array<UnoPlayer>;
    public var currentPlayerIndex:Int;
    public var direction:TurnDirection;
    public var skipNextTurn:Bool;
    
    // Events
    public var onTurnStart:UnoPlayer->Void;
    public var onTurnEnd:UnoPlayer->Void;
    public var onDirectionChange:TurnDirection->Void;
    public var onPlayerSkipped:UnoPlayer->Void;
    
    public function new(players:Array<UnoPlayer>) {
        this.players = players;
        this.currentPlayerIndex = 0;
        this.direction = CLOCKWISE;
        this.skipNextTurn = false;
    }
    
    /**
     * Get the current player
     */
    public function getCurrentPlayer():UnoPlayer {
        return players[currentPlayerIndex];
    }
    
    /**
     * Get the next player in turn order
     */
    public function getNextPlayer():UnoPlayer {
        var nextIndex = getNextPlayerIndex();
        return players[nextIndex];
    }
    
    /**
     * Get the previous player in turn order
     */
    public function getPreviousPlayer():UnoPlayer {
        var prevIndex = getPreviousPlayerIndex();
        return players[prevIndex];
    }
    
    /**
     * Calculate the next player index based on direction
     */
    private function getNextPlayerIndex():Int {
        if (direction == CLOCKWISE) {
            return (currentPlayerIndex + 1) % players.length;
        } else {
            return currentPlayerIndex == 0 ? players.length - 1 : currentPlayerIndex - 1;
        }
    }
    
    /**
     * Calculate the previous player index based on direction
     */
    private function getPreviousPlayerIndex():Int {
        if (direction == CLOCKWISE) {
            return currentPlayerIndex == 0 ? players.length - 1 : currentPlayerIndex - 1;
        } else {
            return (currentPlayerIndex + 1) % players.length;
        }
    }
    
    /**
     * Advance to the next turn
     */
    public function nextTurn():Void {
        var currentPlayer = getCurrentPlayer();
        
        if (onTurnEnd != null) {
            onTurnEnd(currentPlayer);
        }
        
        // Handle skip
        if (skipNextTurn) {
            skipNextTurn = false;
            var skippedPlayer = getNextPlayer();
            currentPlayerIndex = getNextPlayerIndex();
            
            if (onPlayerSkipped != null) {
                onPlayerSkipped(skippedPlayer);
            }
        }
        
        currentPlayerIndex = getNextPlayerIndex();
        
        var newCurrentPlayer = getCurrentPlayer();
        if (onTurnStart != null) {
            onTurnStart(newCurrentPlayer);
        }
    }
    
    /**
     * Reverse the turn direction
     */
    public function reverseTurn():Void {
        direction = (direction == CLOCKWISE) ? COUNTER_CLOCKWISE : CLOCKWISE;
        
        if (onDirectionChange != null) {
            onDirectionChange(direction);
        }
        
        // In a 2-player game, reverse acts like skip
        if (players.length == 2) {
            skipNextTurn = true;
        }
    }
    
    /**
     * Skip the next player's turn
     */
    public function skipNextPlayer():Void {
        skipNextTurn = true;
    }
    
    /**
     * Get all players in current turn order starting from current player
     */
    public function getPlayersInTurnOrder():Array<UnoPlayer> {
        var orderedPlayers = [];
        var index = currentPlayerIndex;
        
        for (i in 0...players.length) {
            orderedPlayers.push(players[index]);
            index = direction == CLOCKWISE ? 
                (index + 1) % players.length : 
                (index == 0 ? players.length - 1 : index - 1);
        }
        
        return orderedPlayers;
    }
    
    /**
     * Get the player at a specific offset from current player
     */
    public function getPlayerAtOffset(offset:Int):UnoPlayer {
        var targetIndex = currentPlayerIndex;
        
        if (direction == CLOCKWISE) {
            targetIndex = (currentPlayerIndex + offset) % players.length;
        } else {
            targetIndex = currentPlayerIndex - offset;
            while (targetIndex < 0) {
                targetIndex += players.length;
            }
        }
        
        return players[targetIndex];
    }
    
    /**
     * Set the current player by player object
     */
    public function setCurrentPlayer(player:UnoPlayer):Bool {
        for (i in 0...players.length) {
            if (players[i] == player) {
                currentPlayerIndex = i;
                return true;
            }
        }
        return false;
    }
    
    /**
     * Set the current player by index
     */
    public function setCurrentPlayerIndex(index:Int):Bool {
        if (index >= 0 && index < players.length) {
            currentPlayerIndex = index;
            return true;
        }
        return false;
    }
    
    /**
     * Add a player to the game
     */
    public function addPlayer(player:UnoPlayer):Void {
        players.push(player);
    }
    
    /**
     * Remove a player from the game
     */
    public function removePlayer(player:UnoPlayer):Bool {
        var index = players.indexOf(player);
        if (index != -1) {
            players.splice(index, 1);
            
            // Adjust current player index if necessary
            if (currentPlayerIndex >= players.length) {
                currentPlayerIndex = 0;
            } else if (index < currentPlayerIndex) {
                currentPlayerIndex--;
            }
            
            return true;
        }
        return false;
    }
    
    /**
     * Reset the turn manager for a new game
     */
    public function reset():Void {
        currentPlayerIndex = 0;
        direction = CLOCKWISE;
        skipNextTurn = false;
    }
    
    /**
     * Get the number of players
     */
    public function getPlayerCount():Int {
        return players.length;
    }
    
    /**
     * Check if there's a next turn (game hasn't ended)
     */
    public function hasNextTurn():Bool {
        if (players.length <= 1) return false;
        
        for (p in players) {
            if (p.hasWon()) return false;
        }
        return true;
    }
    
    /**
     * Get turn information string
     */
    public function getTurnInfo():String {
        var dirStr = direction == CLOCKWISE ? "Clockwise" : "Counter-clockwise";
        var skipStr = skipNextTurn ? " (Next player will be skipped)" : "";
        return 'Current: ${getCurrentPlayer().name}, Direction: $dirStr$skipStr';
    }
    
    /**
     * Get a list of all players with their turn position
     */
    public function getPlayerTurnStatus():Array<String> {
        var status = [];
        var orderedPlayers = getPlayersInTurnOrder();
        
        for (i in 0...orderedPlayers.length) {
            var player = orderedPlayers[i];
            var position = i == 0 ? "Current" : 'Next +$i';
            status.push('$position: ${player.getStatus()}');
        }
        
        return status;
    }
}

/**
 * Turn direction enumeration
 */
enum TurnDirection {
    CLOCKWISE;
    COUNTER_CLOCKWISE;
}
