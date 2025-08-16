package yutautil.games.uno;

import flixel.util.FlxColor;

// typedef CPUWeightFunc = (UnoGame) -> Int;

// abstract CPUWeight(CPUWeightFunc) {
//     public function new(value:CPUWeightFunc) {
//         this = value;
//     }

//     public function get():CPUWeightFunc {
//         if (Std.isOfType(this, Int)) {
//             return cast new CPUWeightFunc(this);
//         } else if (Reflect.isFunction(this)) {
//             return (cast this : CPUWeightFunc);
//         }
//         throw "Invalid CPUWeight type";
//     }

//     @:from static public function fromInt(value:Int):CPUWeight {
//         return new CPUWeightFunc((game) -> value);
//     }
//     @:from static public function fromFunc(value:CPUWeightFunc):CPUWeight {
//         return new CPUWeightFunc(value);
//     }
//     @:to public function toInt():Int {
//         return get()(null);
//     }
//     @:to public function toFunc():CPUWeightFunc {
//         return get();
//     }
// }


/**
 * Represents a single UNO card with color, type, and value
 */

class UnoCard {
    public var color:UnoColor;
    public var type:UnoCardType;
    public var value:Int; // Used for number cards and special card identification
    
    public function new(color:UnoColor, type:UnoCardType, value:Int = 0) {
        this.color = color;
        this.type = type;
        this.value = value;
    }
    
    /**
     * Check if this card can be played on top of another card
     */
    public function canPlayOn(otherCard:UnoCard):Bool {
        // Wild cards can be played on anything
        if (type == WILD || type == WILD_DRAW_FOUR) {
            return true;
        }
        
        // Colorless (NONE) action cards can be played on anything, like wild cards
        if (color == NONE && type != NUMBER) {
            return true;
        }
        
        // Same color match (including custom colors)
        if (UnoCard.colorsMatch(color, otherCard.color)) {
            return true;
        }
        
        // Same type match (but only for action cards, not numbers)
        if (type == otherCard.type && type != NUMBER) {
            return true;
        }
        
        // Same number value (only for number cards)
        if (type == NUMBER && otherCard.type == NUMBER && value == otherCard.value) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Check if this is a special action card
     */
    public function isActionCard():Bool {
        return type != NUMBER;
    }
    
    /**
     * Check if this card has a specific color (not wild, none, or all)
     */
    public function isColored():Bool {
        return switch(color) {
            case RED | BLUE | GREEN | YELLOW | CUSTOM(_, _): true;
            case WILD | NONE | ALL: false;
        }
    }
    
    /**
     * Check if this is a wild card (can be played on any card and allows color choice)
     */
    public function isWildCard():Bool {
        return switch(type) {
            case WILD | WILD_DRAW_FOUR: true;
            case CUSTOM(_, _, _, _, isWild): isWild == true;
            case _: false;
        }
    }
    
    /**
     * Check if this card is colorless (acts like wild for color matching but not for effects)
     */
    public function isColorless():Bool {
        return color == WILD || color == NONE || color == ALL;
    }
    
    /**
     * Make a NONE card inherit the color from the card it was played on
     * This should be called after a NONE card is played
     */
    public function inheritColor(fromCard:UnoCard):Void {
        if (color == NONE && fromCard != null) {
            // Inherit the color from the card it was played on
            switch(fromCard.color) {
                case RED | BLUE | GREEN | YELLOW | CUSTOM(_, _):
                    this.color = fromCard.color;
                case WILD | NONE | ALL:
                    // If playing on another colorless card, don't change color
                    // (this should be handled by game logic - use current game color)
            }
        }
    }
    
    /**
     * Get the point value of this card for scoring
     */
    public function getPointValue():Int {
        return switch(type) {
            case NUMBER: value;
            case SKIP | REVERSE | DRAW_TWO: 20;
            case WILD | WILD_DRAW_FOUR: 50;
            case CUSTOM(name, points, cpuImportance, action): points;
        }
    }
    
    /**
     * Get the FlxColor representation of this card's color
     */
    public function getFlxColor():FlxColor {
        return switch(color) {
            case RED: FlxColor.RED;
            case BLUE: FlxColor.BLUE;
            case GREEN: FlxColor.GREEN;
            case YELLOW: FlxColor.YELLOW;
            case WILD | NONE | ALL: FlxColor.BLACK; // NONE, ALL, and WILD cards get black color
            case CUSTOM(color, name): color;
        }
    }
    
    /**
     * Get the display name of this card's color
     */
    public function getColorName():String {
        return switch(color) {
            case RED: "Red";
            case BLUE: "Blue";
            case GREEN: "Green";
            case YELLOW: "Yellow";
            case WILD: "Wild";
            case NONE: "Colorless";
            case ALL: "All Colors";
            case CUSTOM(color, name): name != null ? '$name' : 'Custom (#${StringTools.hex(color, 6)})';
        }
    }
    
    /**
     * Get a string representation of the card
     */
    public function toString():String {
        var colorStr = getColorName();
        
        var typeStr = switch(type) {
            case NUMBER: Std.string(value);
            case SKIP: "Skip";
            case REVERSE: "Reverse";
            case DRAW_TWO: "Draw Two";
            case WILD: "Wild";
            case WILD_DRAW_FOUR: "Wild Draw Four";
            case CUSTOM(name, points, cpuImportance, action): '$name';
        }
        
        if (isWildCard()) {
            return typeStr;
        }
        
        return '$colorStr $typeStr';
    }
    
    /**
     * Create a copy of this card
     */
    public function clone():UnoCard {
        return new UnoCard(color, type, value);
    }
    
    /**
     * Create custom color variants from an array of FlxColors
     */
    public static function createCustomColors(colors:Array<FlxColor>, ?names:Array<String>):Array<UnoColor> {
        var customColors = [];
        for (i in 0...colors.length) {
            var name = (names != null && i < names.length) ? names[i] : 'Custom ${i + 1}';
            customColors.push(UnoColor.CUSTOM(colors[i], name));
        }
        return customColors;
    }

    public static function createCustomColorsFromObjects(colors:Array<{color:FlxColor, ?name:String}>):Array<UnoColor> {
        var customColors = [];
        for (obj in colors) {
            var name = obj.name != null ? obj.name : 'Custom';
            customColors.push(UnoColor.CUSTOM(obj.color, name));
        }
        return customColors;
    }

    /**
     * Get standard UNO colors (Red, Blue, Green, Yellow)
     */
    public static function getStandardColors():Array<UnoColor> {
        return [UnoColor.RED, UnoColor.BLUE, UnoColor.GREEN, UnoColor.YELLOW];
    }
    
    /**
     * Check if two colors match (including custom colors)
     */
    public static function colorsMatch(color1:UnoColor, color2:UnoColor):Bool {
        return switch([color1, color2]) {
            case [RED, RED] | [BLUE, BLUE] | [GREEN, GREEN] | [YELLOW, YELLOW] | [WILD, WILD] | [NONE, NONE]: true;
            case [CUSTOM(c1, _), CUSTOM(c2, _)]: c1 == c2;
            case _: false;
        }
    }
    
    /**
     * Create action cards - unified function for creating action cards
     * @param name Name of the action card
     * @param color Color(s) for the card - use ALL to create cards for all standard colors
     * @param count Number of cards to create per color (default: 1)
     * @param points Point value of the card (default: 50)
     * @param cpuImportance CPU importance rating (default: 5)
     * @param action Optional action function to execute when played
     * @param isWild Whether this card should be considered a wild card (default: false)
     * @return Array of created cards
     */
    public static function createActionCards(name:String, color:UnoColor, count:Int = 1, points:Int = 50, cpuImportance:Int = 5, ?action:UnoGame->Void, ?isWild:Bool):Array<UnoCard> {
        var cards = [];
        
        if (color == ALL) {
            // Create cards for all standard colors
            var standardColors = getStandardColors();
            for (standardColor in standardColors) {
                for (i in 0...count) {
                    cards.push(new UnoCard(standardColor, CUSTOM(name, points, cpuImportance, action, isWild)));
                }
            }
        } else {
            // Create cards for the specified color
            for (i in 0...count) {
                cards.push(new UnoCard(color, CUSTOM(name, points, cpuImportance, action, isWild)));
            }
        }
        
        return cards;
    }
    
    /**
     * Create a single action card (convenience method)
     */
    public static function createActionCard(name:String, color:UnoColor, points:Int = 50, cpuImportance:Int = 5, ?action:UnoGame->Void, ?isWild:Bool):UnoCard {
        var cards = createActionCards(name, color, 1, points, cpuImportance, action, isWild);
        return cards[0];
    }
    
    /**
     * Create action cards of all standard colors
     */
    public static function createActionCardsAllColors(name:String, points:Int = 50, cpuImportance:Int = 5, ?action:UnoGame->Void, ?isWild:Bool):Array<UnoCard> {
        var cards = [];
        var colors = getStandardColors();
        for (color in colors) {
            cards.push(createCustomActionCard(name, color, points, cpuImportance, action, isWild));
        }
        return cards;
    }
    
    /**
     * Create action cards of specified colors
     */
    public static function createActionCardsOfColors(name:String, colors:Array<UnoColor>, points:Int = 50, cpuImportance:Int = 5, ?action:UnoGame->Void, ?isWild:Bool):Array<UnoCard> {
        var cards = [];
        for (color in colors) {
            cards.push(createCustomActionCard(name, color, points, cpuImportance, action, isWild));
        }
        return cards;
    }
}

    public static function createSimpleCustomActionCards(name:String, count:Int = 1, points:Int = 50, cpuImportance:Int = 5, ?action:UnoGame->Void, ?isWild:Bool):Array<UnoCard> {
        var cards = [];
        for (i in 0...count) {
            var color = (isWild == true) ? UnoColor.WILD : UnoColor.NONE;
            cards.push(createCustomActionCard(name, color, points, cpuImportance, action, isWild));
        }
        return cards;
    }


/**
 * UNO card colors
 */
enum UnoColor {
    RED;
    BLUE;
    GREEN;
    YELLOW;
    WILD; // For wild cards that allow color choice
    NONE; // For colorless cards that inherit the current color after being played
    ALL; // Special marker for deck generation - create this card in all standard colors
    CUSTOM(color:FlxColor, ?name:String);
}

/**
 * UNO card types
 */
enum UnoCardType {
    NUMBER;
    SKIP;
    REVERSE;
    DRAW_TWO;
    WILD;
    WILD_DRAW_FOUR;
    CUSTOM(name:String, points:Int, cpuImportance:Int, ?action:UnoGame->Void, ?isWild:Bool);
}
