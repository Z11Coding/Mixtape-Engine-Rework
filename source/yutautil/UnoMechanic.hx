package yutautil;

import games.uno.backend.UnoCard;
import games.uno.backend.UnoDeck;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoCard.UnoCardType;
import objects.Note;
import flixel.FlxG;
import flixel.math.FlxMath;

/**
 * Handles UNO mechanics for individual notes in chart generation
 * This class processes a single note and determines its UNO card properties
 */
class UnoMechanic {
    public var deck:UnoDeck;
    public var currentCard:UnoCard;
    public var lastPlayedCard:UnoCard;
    public var preCalculatedWildColors:Array<UnoColor>; // For wild cards to maintain compatibility
    public var wildIndex:Int = 0;
    public var currentColor:UnoColor; // Track current color for display
    public var colorChangeCallback:Int->Void; // Callback to update UI
    
    public function new() {
        deck = new UnoDeck();
        currentCard = null;
        lastPlayedCard = null;
        preCalculatedWildColors = [];
        currentColor = UnoColor.RED; // Start with red
        colorChangeCallback = null;
        generateWildColors();
    }
    
    /**
     * Pre-calculate wild card colors to maintain note compatibility
     */
    private function generateWildColors():Void {
        var colors = [UnoColor.RED, UnoColor.BLUE, UnoColor.GREEN, UnoColor.YELLOW];
        for (i in 0...50) { // Generate 50 pre-calculated colors
            preCalculatedWildColors.push(colors[FlxG.random.int(0, colors.length - 1)]);
        }
    }
    
    /**
     * Process a note and assign UNO card properties
     * @param note The note to process
     * @param mania Current mania (number of lanes)
     * @param strumTime The note's strum time
     * @param mustPress Whether it's a player note
     */
    public function processNote(note:Note, mania:Int, strumTime:Float, mustPress:Bool):Void {
        if (note.extraData == null) {
            note.extraData = new Map<String, Dynamic>();
        }
        
        // Generate a card for this note (both player and opponent)
        var card = generateCardForNote(strumTime, mania);
        
        // Store card data in note's extra data
        note.extraData.set("unoColor", getColorName(card.color));
        note.extraData.set("unoType", getTypeName(card.type));
        note.extraData.set("unoValue", card.value);
        note.extraData.set("unoCard", card);
        note.extraData.set("isWrongCard", false);
        note.extraData.set("isSkipCard", false);
        note.extraData.set("isPlusCard", false);
        note.extraData.set("plusCardCount", 0);
        
        // Update visual appearance
        updateNoteAppearance(note, card);
        
        // Update current color and notify UI
        updateCurrentColor(card.color);
        
        lastPlayedCard = card;
    }
    
    /**
     * Generate additional notes for special UNO mechanics
     */
    public function generateSpecialNotes(baseNote:Note, mania:Int, allNotes:Array<Note>):Array<Note> {
        var specialNotes:Array<Note> = [];
        
        if (baseNote.extraData == null) return specialNotes;
        
        var card:UnoCard = cast baseNote.extraData.get("unoCard");
        if (card == null) return specialNotes;
        
        // Only generate bad notes (skip, wrong) for player notes
        if (baseNote.mustPress) {
            // Generate skip notes (bad notes to avoid)
            if (FlxG.random.float(0, 1) < 0.15) { // 15% chance
                var skipNote = createSpecialNote(baseNote, mania, "skip");
                if (skipNote != null) specialNotes.push(skipNote);
            }
            
            // Generate wrong color notes (bad notes)
            if (FlxG.random.float(0, 1) < 0.1) { // 10% chance
                var wrongNote = createWrongColorNote(baseNote, mania);
                if (wrongNote != null) specialNotes.push(wrongNote);
            }
        }
        
        // Handle +2 and Wild +4 cards (for both player and opponent)
        switch (card.type) {
            case DRAW_TWO:
                var plusNotes = createPlusNotes(baseNote, mania, 2);
                specialNotes = specialNotes.concat(plusNotes);
            case WILD_DRAW_FOUR:
                var plusNotes = createPlusNotes(baseNote, mania, 4);
                specialNotes = specialNotes.concat(plusNotes);
            default:
                // Regular cards don't generate extra notes
        }
        
        return specialNotes;
    }
    
    /**
     * Update the current color and notify the UI
     */
    private function updateCurrentColor(newColor:UnoColor):Void {
        currentColor = newColor;
        
        if (colorChangeCallback != null) {
            var colorInt = switch(newColor) {
                case RED: 0xFFFF0000;
                case BLUE: 0xFF0000FF;
                case GREEN: 0xFF00FF00;
                case YELLOW: 0xFFFFFF00;
                case WILD: this.currentCard.getFlxColor();
                case CUSTOM(color, _): color;
            };
            colorChangeCallback(colorInt);
        }
    }
    
    /**
     * Set the callback for when color changes
     */
    public function setColorChangeCallback(callback:Int->Void):Void {
        colorChangeCallback = callback;
    }
    
    /**
     * Generate a UNO card for a specific note
     */
    private function generateCardForNote(strumTime:Float, mania:Int):UnoCard {
        var colors = [UnoColor.RED, UnoColor.BLUE, UnoColor.GREEN, UnoColor.YELLOW];
        var currentColor = lastPlayedCard != null ? lastPlayedCard.color : colors[FlxG.random.int(0, colors.length - 1)];
        
        // Determine card type weights (numbered cards more likely)
        var typeRoll = FlxG.random.float(0, 1);
        
        if (typeRoll < 0.7) { // 70% chance for number cards
            var value = FlxG.random.int(0, 9);
            return new UnoCard(currentColor, NUMBER, value);
        } else if (typeRoll < 0.85) { // 15% chance for action cards
            var actionType = switch(FlxG.random.int(0, 2)) {
                case 0: SKIP;
                case 1: REVERSE;
                case 2: DRAW_TWO;
                default: SKIP;
            }
            return new UnoCard(currentColor, actionType);
        } else { // 15% chance for wild cards
            var wildType = FlxG.random.bool(30) ? WILD_DRAW_FOUR : WILD;
            var wildColor = getNextWildColor();
            return new UnoCard(wildColor, wildType);
        }
    }
    
    /**
     * Create a special note (skip, wrong, etc.)
     */
    private function createSpecialNote(baseNote:Note, mania:Int, type:String):Note {
        var specialNote = new Note(baseNote.strumTime + FlxG.random.float(50, 200), 
                                  getAlternateColumn(baseNote.noteData, mania), 
                                  null, false);
        specialNote.mustPress = true;
        
        if (specialNote.extraData == null) {
            specialNote.extraData = new Map<String, Dynamic>();
        }
        
        switch (type) {
            case "skip":
                specialNote.extraData.set("unoType", "Skip");
                specialNote.extraData.set("unoColor", "Any");
                specialNote.extraData.set("isSkipCard", true);
                specialNote.extraData.set("isWrongCard", true);
                updateNoteAppearanceForSkip(specialNote);
                specialNote.ignoreNote = true;
            default:
                // Handle other special types
        }
        
        return specialNote;
    }
    
    /**
     * Create a wrong color note
     */
    private function createWrongColorNote(baseNote:Note, mania:Int):Note {
        var wrongNote = new Note(baseNote.strumTime + FlxG.random.float(25, 150), 
                                getAlternateColumn(baseNote.noteData, mania), 
                                null, false);
        wrongNote.mustPress = true;
        
        if (wrongNote.extraData == null) {
            wrongNote.extraData = new Map<String, Dynamic>();
        }
        
        // Generate incompatible card
        var wrongColors = [UnoColor.RED, UnoColor.BLUE, UnoColor.GREEN, UnoColor.YELLOW];
        if (lastPlayedCard != null && lastPlayedCard.color != WILD) {
            wrongColors.remove(lastPlayedCard.color);
        }
        
        var wrongColor = wrongColors[FlxG.random.int(0, wrongColors.length - 1)];
        var wrongCard = new UnoCard(wrongColor, NUMBER, FlxG.random.int(0, 9));
        
        wrongNote.extraData.set("unoColor", getColorName(wrongCard.color));
        wrongNote.extraData.set("unoType", getTypeName(wrongCard.type));
        wrongNote.extraData.set("unoValue", wrongCard.value);
        wrongNote.extraData.set("unoCard", wrongCard);
        wrongNote.extraData.set("isWrongCard", true);
        wrongNote.ignoreNote = true;
        
        updateNoteAppearance(wrongNote, wrongCard);
        
        return wrongNote;
    }
    
    /**
     * Create +2 or +4 additional notes
     */
    private function createPlusNotes(baseNote:Note, mania:Int, count:Int):Array<Note> {
        var plusNotes:Array<Note> = [];
        var usedColumns:Array<Int> = [baseNote.noteData];
        
        // Mark original note as plus card
        baseNote.extraData.set("isPlusCard", true);
        baseNote.extraData.set("plusCardCount", count);
        
        var card:UnoCard = cast baseNote.extraData.get("unoCard");
        var newColor = (card.type == WILD_DRAW_FOUR) ? getNextWildColor() : card.color;
        
        for (i in 0...count-1) { // -1 because original note is one of them
            var availableColumns:Array<Int> = [];
            for (col in 0...mania) {
                if (usedColumns.indexOf(col) == -1) {
                    availableColumns.push(col);
                }
            }
            
            if (availableColumns.length == 0) break;
            
            var newColumn = availableColumns[FlxG.random.int(0, availableColumns.length - 1)];
            usedColumns.push(newColumn);
            
            var plusNote = new Note(baseNote.strumTime, newColumn, null, false);
            plusNote.mustPress = baseNote.mustPress; // Use same mustPress as base note
            
            if (plusNote.extraData == null) {
                plusNote.extraData = new Map<String, Dynamic>();
            }
            
            // Create compatible card for plus note
            var compatibleCard = new UnoCard(newColor, NUMBER, FlxG.random.int(0, 9));
            
            plusNote.extraData.set("unoColor", getColorName(compatibleCard.color));
            plusNote.extraData.set("unoType", getTypeName(compatibleCard.type));
            plusNote.extraData.set("unoValue", compatibleCard.value);
            plusNote.extraData.set("unoCard", compatibleCard);
            plusNote.extraData.set("isPlusCard", true);
            plusNote.extraData.set("isSecondaryPlusCard", true);
            
            // Add tween data for visual effect
            plusNote.extraData.set("originalX", baseNote.x);
            plusNote.extraData.set("targetColumn", newColumn);
            
            updateNoteAppearance(plusNote, compatibleCard);
            plusNotes.push(plusNote);
        }
        
        return plusNotes;
    }
    
    /**
     * Get an alternate column for special notes
     */
    private function getAlternateColumn(originalColumn:Int, mania:Int):Int {
        var newColumn:Int;
        do {
            newColumn = FlxG.random.int(0, mania - 1);
        } while (newColumn == originalColumn && mania > 1);
        return newColumn;
    }
    
    /**
     * Get the next pre-calculated wild color
     */
    private function getNextWildColor():UnoColor {
        if (wildIndex >= preCalculatedWildColors.length) {
            generateWildColors(); // Regenerate if we run out
            wildIndex = 0;
        }
        return preCalculatedWildColors[wildIndex++];
    }
    
    /**
     * Update note's visual appearance based on UNO card
     */
    private function updateNoteAppearance(note:Note, card:UnoCard):Void {
        // Store visual info for rendering
        note.extraData.set("unoDisplayText", getCardDisplayText(card));
        note.extraData.set("unoColorHex", card.getFlxColor());
        
        // Set the note's RGB red channel to match the card color
        if (note.rgbShader != null) {
            note.rgbShader.r = card.getFlxColor();
        }
    }
    
    /**
     * Update note appearance specifically for skip cards
     */
    private function updateNoteAppearanceForSkip(note:Note):Void {
        note.extraData.set("unoDisplayText", "SKIP"); // Text fallback, but will be drawn as icon
        note.extraData.set("unoColorHex", 0xFF888888);
        
        // Set note's RGB to gray for skip cards
        if (note.rgbShader != null) {
            note.rgbShader.r = 0xFF888888;
        }
    }
    
    /**
     * Get display text for a card
     */
    private function getCardDisplayText(card:UnoCard):String {
        return switch (card.type) {
            case NUMBER: Std.string(card.value);
            case SKIP: "SKIP"; // Will be drawn as custom graphic
            case REVERSE: "REV"; // Text instead of arrow symbol
            case DRAW_TWO: "+2";
            case WILD: "WILD";
            case WILD_DRAW_FOUR: "+4";
            default: "?";
        }
    }
    
    /**
     * Get color name as string
     */
    private function getColorName(color:UnoColor):String {
        return switch (color) {
            case RED: "Red";
            case BLUE: "Blue";
            case GREEN: "Green";
            case YELLOW: "Yellow";
            case WILD: "Wild";
            case CUSTOM(_, name): name != null ? name : "Custom";
        }
    }
    
    /**
     * Get type name as string
     */
    private function getTypeName(type:UnoCardType):String {
        return switch (type) {
            case NUMBER: "Number";
            case SKIP: "Skip";
            case REVERSE: "Reverse";
            case DRAW_TWO: "DrawTwo";
            case WILD: "Wild";
            case WILD_DRAW_FOUR: "WildDrawFour";
            case CUSTOM(name, _, _, _): name;
        }
    }
    
    /**
     * Check if two cards are compatible
     */
    public function areCardsCompatible(card1:UnoCard, card2:UnoCard):Bool {
        if (card1 == null || card2 == null) return false;
        return card2.canPlayOn(card1);
    }
    
    /**
     * Validate if a played card is correct
     */
    public function validateCardPlay(playedCard:UnoCard, expectedCard:UnoCard):Bool {
        if (playedCard == null || expectedCard == null) return false;
        return playedCard.canPlayOn(expectedCard);
    }
}