package games.uno.backend;

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
     * Check if this is a wild card
     */
    public function isWildCard():Bool {
        return type == WILD || type == WILD_DRAW_FOUR || (switch(type) {
            case CUSTOM(_, _, _, _): true;
            case _: false;
        });
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
            case WILD: FlxColor.WHITE;
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
            case [RED, RED] | [BLUE, BLUE] | [GREEN, GREEN] | [YELLOW, YELLOW] | [WILD, WILD]: true;
            case [CUSTOM(c1, _), CUSTOM(c2, _)]: c1 == c2;
            case _: false;
        }
    }
    
    /**
     * Create a custom action card
     */
    public static function createCustomActionCard(name:String, color:UnoColor, points:Int = 50, cpuImportance:Int = 5, ?action:UnoGame->Void):UnoCard {
        return new UnoCard(color, CUSTOM(name, points, cpuImportance, action));
    }
    
    /**
     * Create multiple copies of a custom action card
     */
    public static function createCustomActionCards(name:String, color:UnoColor, count:Int = 1, points:Int = 50, cpuImportance:Int = 5, ?action:UnoGame->Void):Array<UnoCard> {
        var cards = [];
        for (i in 0...count) {
            cards.push(createCustomActionCard(name, color, points, cpuImportance, action));
        }
        return cards;
    }
}


/**
 * UNO card colors
 */
enum UnoColor {
    RED;
    BLUE;
    GREEN;
    YELLOW;
    WILD; // For wild cards
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
    CUSTOM(name:String, points:Int, cpuImportance:Int, ?action:UnoGame->Void);
}
