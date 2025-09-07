package games.match3.backend;

import flixel.util.FlxColor;

/**
 * Represents a single piece on the Match 3 board
 */
class Match3Piece {
    public var type:Match3PieceType;
    public var color:FlxColor;
    public var x:Int;
    public var y:Int;
    public var isMatched:Bool = false;
    public var isProcessing:Bool = false;
    public var isSpecial:Bool = false;
    public var specialType:SpecialType = NONE;
    public var iconPath:String = null; // For character icons from mods

    public function new(type:Match3PieceType, x:Int, y:Int, ?color:FlxColor, ?iconPath:String) {
        this.type = type;
        this.x = x;
        this.y = y;
        this.color = color != null ? color : getDefaultColor();
        this.iconPath = iconPath;
    }

    /**
     * Get default color based on piece type
     */
    private function getDefaultColor():FlxColor {
        return switch(type) {
            case BASIC(basicType):
                switch(basicType) {
                    case RED: FlxColor.RED;
                    case BLUE: FlxColor.BLUE;
                    case GREEN: FlxColor.GREEN;
                    case YELLOW: FlxColor.YELLOW;
                    case PURPLE: FlxColor.PURPLE;
                    case ORANGE: FlxColor.ORANGE;
                }
            case ICON(_): FlxColor.WHITE;
            case OBSTACLE: FlxColor.GRAY;
            case POWER_UP(_, color): color;
        }
    }

    /**
     * Check if this piece can be matched with another piece
     */
    public function canMatchWith(other:Match3Piece):Bool {
        if (type == OBSTACLE || other.type == OBSTACLE) {
            return false;
        }

        return switch([type, other.type]) {
            case [BASIC(type1), BASIC(type2)]: type1 == type2;
            case [ICON(icon1), ICON(icon2)]: icon1 == icon2;
            case [POWER_UP(_, _), _] | [_, POWER_UP(_, _)]: true; // Power-ups can match with anything
            case _: false;
        }
    }

    /**
     * Create a power-up from this piece
     */
    public function createPowerUp(specialType:SpecialType):Match3Piece {
        var powerUp = clone();
        powerUp.isSpecial = true;
        powerUp.specialType = specialType;
        powerUp.type = POWER_UP(specialType, color);
        return powerUp;
    }

    /**
     * Clone this piece
     */
    public function clone():Match3Piece {
        var cloned = new Match3Piece(type, x, y, color, iconPath);
        cloned.isMatched = isMatched;
        cloned.isProcessing = isProcessing;
        cloned.isSpecial = isSpecial;
        cloned.specialType = specialType;
        return cloned;
    }

    /**
     * Get string representation
     */
    public function toString():String {
        var typeStr = switch(type) {
            case BASIC(basicType): 'Basic($basicType)';
            case ICON(iconName): 'Icon($iconName)';
            case OBSTACLE: 'Obstacle';
            case POWER_UP(special, _): 'PowerUp($special)';
        }
        return '$typeStr at ($x, $y)';
    }

    /**
     * Check if two piece types match
     */
    public static function typesMatch(type1:Match3PieceType, type2:Match3PieceType):Bool {
        return switch([type1, type2]) {
            case [BASIC(t1), BASIC(t2)]: t1 == t2;
            case [ICON(i1), ICON(i2)]: i1 == i2;
            case [OBSTACLE, OBSTACLE]: true;
            case [POWER_UP(s1, _), POWER_UP(s2, _)]: s1 == s2;
            case _: false;
        }
    }
}

/**
 * Types of Match 3 pieces
 */
enum Match3PieceType {
    BASIC(type:BasicPieceType);
    ICON(iconName:String); // Character icons from game/mods
    OBSTACLE; // Blocks that need to be cleared
    POWER_UP(specialType:SpecialType, color:FlxColor);
}

/**
 * Basic piece colors/types
 */
enum BasicPieceType {
    RED;
    BLUE;
    GREEN;
    YELLOW;
    PURPLE;
    ORANGE;
}

/**
 * Special power-up types
 */
enum SpecialType {
    NONE;
    HORIZONTAL_STRIPE; // Clears entire row
    VERTICAL_STRIPE;   // Clears entire column
    BOMB;             // Clears 3x3 area around it
    COLOR_BOMB;       // Clears all pieces of a color
    RAINBOW;          // Can match with any color
}
