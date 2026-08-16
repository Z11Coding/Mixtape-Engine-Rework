package games.uno.beta;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoCard;

class UnoBetaTextures {
    public static inline var CARD_WIDTH:Int = 92;
    public static inline var CARD_HEIGHT:Int = 132;
    public static inline var TEXTURE_FOLDER:String = "uno/beta/cards";

    public static function textureKeyForCard(card:UnoCard):String {
        if (card == null) return TEXTURE_FOLDER + "/unknown";

        var colorKey = switch (card.color) {
            case RED: "red";
            case BLUE: "blue";
            case GREEN: "green";
            case YELLOW: "yellow";
            case WILD: "wild";
            case CUSTOM(_, name): sanitize(name != null ? name : "custom");
        };

        var typeKey = switch (card.type) {
            case NUMBER: Std.string(card.value);
            case SKIP: "skip";
            case REVERSE: "reverse";
            case DRAW_TWO: "draw_two";
            case WILD: "wild";
            case WILD_DRAW_FOUR: "wild_draw_four";
            case CUSTOM(name, _, _, _): sanitize(name != null ? name : "custom");
        };

        return TEXTURE_FOLDER + "/" + colorKey + "_" + typeKey;
    }

    public static function hasTexture(card:UnoCard):Bool {
        if (card == null) return false;
        return Paths.fileExists(textureKeyForCard(card), IMAGE);
    }

    public static function createCardSprite(card:UnoCard, x:Float, y:Float, ?w:Int = CARD_WIDTH, ?h:Int = CARD_HEIGHT):FlxSprite {
        var sprite = new FlxSprite(x, y);

        if (card == null) {
            sprite.makeGraphic(w, h, FlxColor.GRAY);
            return sprite;
        }

        if (hasTexture(card)) {
            sprite.loadGraphic(Paths.image(textureKeyForCard(card)), false, w, h);
            return sprite;
        }

        var panelColor = getPanelColor(card);
        sprite.makeGraphic(w, h, FlxColor.WHITE);

        var shadow = new FlxSprite();
        shadow.makeGraphic(w - 8, h - 8, FlxColor.fromRGB(16, 18, 24));
        sprite.stamp(shadow, 4, 4);

        var inner = new FlxSprite();
        inner.makeGraphic(w - 16, h - 16, panelColor);
        sprite.stamp(inner, 8, 8);

        var shield = new FlxSprite();
        shield.makeGraphic(w - 22, h - 22, FlxColor.fromRGBFloat(1, 1, 1, 0.18));
        sprite.stamp(shield, 11, 11);

        var label = new FlxText(0, 0, w, getDisplayText(card), 18);
        label.setFormat(Paths.font("vcr.ttf"), 28, getTextColor(card), CENTER);
        label.y = (h - label.height) * 0.5;
        sprite.stamp(label, 0, 0);

        var tinyLabel = new FlxText(0, h - 22, w, getMiniText(card), 12);
        tinyLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
        sprite.stamp(tinyLabel, 0, 0);

        return sprite;
    }

    public static function createDrawPileSprite(x:Float, y:Float, count:Int):FlxSprite {
        var sprite = new FlxSprite(x, y);

        sprite.makeGraphic(CARD_WIDTH, CARD_HEIGHT, FlxColor.fromRGB(22, 25, 33));

        var border = new FlxSprite();
        border.makeGraphic(CARD_WIDTH - 8, CARD_HEIGHT - 8, FlxColor.fromRGB(70, 76, 88));
        sprite.stamp(border, 4, 4);

        var center = new FlxSprite();
        center.makeGraphic(CARD_WIDTH - 18, CARD_HEIGHT - 18, FlxColor.fromRGB(42, 46, 58));
        sprite.stamp(center, 9, 9);

        var drawText = new FlxText(0, 12, CARD_WIDTH, "DRAW", 12);
        drawText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
        sprite.stamp(drawText, 0, 0);

        var countText = new FlxText(0, CARD_HEIGHT - 44, CARD_WIDTH, Std.string(count), 20);
        countText.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, CENTER);
        sprite.stamp(countText, 0, 0);

        return sprite;
    }

    private static function getPanelColor(card:UnoCard):FlxColor {
        return switch (card.color) {
            case RED: FlxColor.fromRGB(176, 23, 35);
            case BLUE: FlxColor.fromRGB(32, 82, 204);
            case GREEN: FlxColor.fromRGB(28, 146, 62);
            case YELLOW: FlxColor.fromRGB(208, 175, 24);
            case WILD: FlxColor.fromRGB(35, 35, 40);
            case CUSTOM(color, _): color;
        };
    }

    private static function getTextColor(card:UnoCard):FlxColor {
        var color = getPanelColor(card);
        if (card.color == UnoColor.YELLOW || color == FlxColor.fromRGB(208, 175, 24)) {
            return FlxColor.fromRGB(20, 20, 20);
        }
        return FlxColor.WHITE;
    }

    private static function getDisplayText(card:UnoCard):String {
        if (card == null) return "?";
        return switch(card.type) {
            case NUMBER: Std.string(card.value);
            case SKIP: "SKIP";
            case REVERSE: "REV";
            case DRAW_TWO: "+2";
            case WILD: "WILD";
            case WILD_DRAW_FOUR: "+4";
            case CUSTOM(name, _, _, _): name != null ? name.substr(0, 5).toUpperCase() : "CARD";
        };
    }

    private static function getMiniText(card:UnoCard):String {
        if (card == null) return "";
        return switch(card.type) {
            case NUMBER: card.getColorName();
            case SKIP: "SKIP";
            case REVERSE: "REV";
            case DRAW_TWO: "+2";
            case WILD: "WILD";
            case WILD_DRAW_FOUR: "DRAW 4";
            case CUSTOM(name, _, _, _): name != null ? name.substr(0, 6) : "CARD";
        };
    }

    private static function sanitize(value:String):String {
        var output = value.toLowerCase();
        output = StringTools.replace(output, " ", "_");
        output = StringTools.replace(output, "-", "_");
        return output;
    }
}
